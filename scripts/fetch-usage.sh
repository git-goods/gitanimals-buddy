#!/bin/bash
# GitAnimals Buddy — Usage fetcher
# Priority: claude.ai API → JSONL fallback
set -euo pipefail

CACHE_DIR="${HOME}/.cache/gitanimals"
USAGE_CACHE="${CACHE_DIR}/usage-cache.txt"
CONFIG_FILE="${HOME}/.claude/gitanimals.json"

mkdir -p "$CACHE_DIR"

# === Helper ===
get_config() {
  local key="$1" default="${2:-}"
  if [ -f "$CONFIG_FILE" ]; then
    jq -r ".$key // \"$default\"" "$CONFIG_FILE" 2>/dev/null || echo "$default"
  else
    echo "$default"
  fi
}

write_cache() {
  local util="$1" resets="${2:-}" source="${3:-unknown}"
  cat > "$USAGE_CACHE" <<EOF
UTILIZATION=$util
RESETS_AT=$resets
SOURCE=$source
TIMESTAMP=$(date +%s)
EOF
}

# === 1. Try claude.ai API ===
try_api() {
  local session_key org_id response util resets_at

  session_key=$(get_config "claude_session_key" "")
  [ -z "$session_key" ] && return 1

  org_id=$(get_config "claude_org_id" "")

  # Auto-detect org ID if not set
  if [ -z "$org_id" ]; then
    org_id=$(curl -s --max-time 5 \
      "https://claude.ai/api/organizations" \
      -H "Cookie: sessionKey=${session_key}" \
      -H "Accept: application/json" 2>/dev/null \
      | jq -r '.[0].uuid // empty' 2>/dev/null)

    [ -z "$org_id" ] && return 1

    # Save org_id for next time
    if [ -f "$CONFIG_FILE" ]; then
      local tmp
      tmp=$(mktemp)
      jq --arg id "$org_id" '.claude_org_id = $id' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    fi
  fi

  response=$(curl -s --max-time 5 \
    "https://claude.ai/api/organizations/${org_id}/usage" \
    -H "Cookie: sessionKey=${session_key}" \
    -H "Accept: application/json" 2>/dev/null)

  util=$(echo "$response" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  [ -z "$util" ] && return 1

  resets_at=$(echo "$response" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)

  write_cache "$util" "$resets_at" "api"
  return 0
}

# === 2. JSONL Fallback ===
try_jsonl() {
  local projects_dir="${HOME}/.claude/projects"

  if [ ! -d "$projects_dir" ]; then
    write_cache "0" "" "jsonl"
    return 0
  fi

  local token_limit
  token_limit=$(get_config "token_limit" "80000")

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

# === Main: API first, then JSONL fallback ===
try_api || try_jsonl
