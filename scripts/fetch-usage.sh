#!/bin/bash
# GitAnimals Buddy — Usage fetcher
# Priority: CLI OAuth (rate limit headers) → JSONL fallback
set -euo pipefail

CACHE_DIR="${HOME}/.cache/gitanimals"
USAGE_CACHE="${CACHE_DIR}/usage-cache.txt"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "$CACHE_DIR"

# === Helper ===
write_cache() {
  local util="$1" resets="${2:-}" source="${3:-unknown}"
  cat > "$USAGE_CACHE" <<EOF
UTILIZATION=$util
RESETS_AT=$resets
SOURCE=$source
TIMESTAMP=$(date +%s)
EOF
}

# === 1. CLI OAuth — read token, call Messages API, parse rate limit headers ===
try_cli_oauth() {
  local token=""

  # 1a. Try credentials file first (most reliable)
  local cred_file=""
  for f in "${CLAUDE_DIR}/.credentials.json" "${CLAUDE_DIR}/credentials.json"; do
    if [ -f "$f" ]; then
      cred_file="$f"
      break
    fi
  done

  if [ -n "$cred_file" ]; then
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$cred_file" 2>/dev/null)
  fi

  # 1b. Keychain fallback
  if [ -z "$token" ]; then
    local raw=""
    # Try legacy service name
    raw=$(security find-generic-password -s "Claude Code-credentials" -a "$(whoami)" -w 2>/dev/null || true)

    # Try hashed service name if legacy not found
    if [ -z "$raw" ]; then
      local svc=""
      svc=$(security dump-keychain 2>/dev/null \
        | grep '"svce"' \
        | grep 'Claude Code-credentials-' \
        | head -1 \
        | sed 's/.*="\(.*\)"/\1/' || true)
      if [ -n "$svc" ]; then
        raw=$(security find-generic-password -s "$svc" -a "$(whoami)" -w 2>/dev/null || true)
      fi
    fi

    if [ -n "$raw" ]; then
      token=$(echo "$raw" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)
      # Regex fallback for truncated JSON
      if [ -z "$token" ]; then
        token=$(echo "$raw" | grep -oE '"accessToken"\s*:\s*"([^"]+)"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)
      fi
    fi
  fi

  [ -z "$token" ] && return 1

  # 2. Minimal Messages API call to get rate limit headers
  local header_file
  header_file=$(mktemp)
  trap "rm -f '$header_file'" RETURN

  local http_code
  http_code=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" \
    -D "$header_file" \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -H "anthropic-version: 2023-06-01" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "User-Agent: claude-code/2.1.5" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}' \
    2>/dev/null)

  [ "$http_code" != "200" ] && return 1

  # 3. Parse rate limit headers
  local util_raw reset_raw
  util_raw=$(grep -i 'anthropic-ratelimit-unified-5h-utilization' "$header_file" | tr -d '\r' | awk '{print $2}' || true)
  reset_raw=$(grep -i 'anthropic-ratelimit-unified-5h-reset' "$header_file" | tr -d '\r' | awk '{print $2}' || true)

  [ -z "$util_raw" ] && return 1

  # Convert 0.0-1.0 to 0-100 percentage
  local util
  util=$(awk "BEGIN {printf \"%d\", ${util_raw} * 100}")

  # Convert unix timestamp to ISO8601
  local resets_at=""
  if [ -n "$reset_raw" ]; then
    local reset_int
    reset_int=$(awk "BEGIN {printf \"%d\", ${reset_raw}}")
    if [ "$(uname)" = "Darwin" ]; then
      resets_at=$(date -u -r "$reset_int" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
    else
      resets_at=$(date -u -d "@$reset_int" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || true)
    fi
  fi

  write_cache "$util" "$resets_at" "oauth"
  return 0
}

# === 2. JSONL Fallback ===
try_jsonl() {
  local projects_dir="${CLAUDE_DIR}/projects"

  if [ ! -d "$projects_dir" ]; then
    write_cache "0" "" "jsonl"
    return 0
  fi

  local config_file="${HOME}/.claude/gitanimals.json"
  local token_limit=80000
  if [ -f "$config_file" ]; then
    token_limit=$(jq -r '.token_limit // "80000"' "$config_file" 2>/dev/null || echo "80000")
  fi

  local now five_hours_ago cutoff
  now=$(date +%s)
  five_hours_ago=$(( now - 18000 ))

  if [ "$(uname)" = "Darwin" ]; then
    cutoff=$(date -u -r "$five_hours_ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
  else
    cutoff=$(date -u -d "@$five_hours_ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
  fi

  local tmpfile
  tmpfile=$(mktemp)
  find "$projects_dir" -name "*.jsonl" -maxdepth 3 2>/dev/null | while read -r f; do
    jq -r --arg cutoff "$cutoff" '
      select(.message.usage.output_tokens != null and .timestamp != null and .timestamp > $cutoff)
      | "\(.message.usage.output_tokens) \(.timestamp)"
    ' "$f" 2>/dev/null
  done > "$tmpfile"

  local total_output oldest_ts
  total_output=$(awk '{s+=$1} END {print s+0}' "$tmpfile")
  oldest_ts=$(awk '{print $2}' "$tmpfile" | sort | head -1)
  rm -f "$tmpfile"

  local util=0
  if [ "$token_limit" -gt 0 ]; then
    util=$(( total_output * 100 / token_limit ))
    [ "$util" -gt 100 ] && util=100
  fi

  local resets_at=""
  if [ -n "$oldest_ts" ]; then
    local clean_ts oldest_epoch reset_epoch
    clean_ts=$(echo "$oldest_ts" | sed 's/\.[0-9]*Z$//' | sed 's/Z$//')
    if [ "$(uname)" = "Darwin" ]; then
      oldest_epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$clean_ts" +%s 2>/dev/null || echo "")
    else
      oldest_epoch=$(date -u -d "$clean_ts" +%s 2>/dev/null || echo "")
    fi
    if [ -n "$oldest_epoch" ]; then
      reset_epoch=$(( oldest_epoch + 18000 ))
      if [ "$(uname)" = "Darwin" ]; then
        resets_at=$(date -u -r "$reset_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
      else
        resets_at=$(date -u -d "@$reset_epoch" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
      fi
    fi
  fi

  write_cache "$util" "$resets_at" "jsonl"
}

# === Main: OAuth first, then JSONL fallback ===
try_cli_oauth || try_jsonl
