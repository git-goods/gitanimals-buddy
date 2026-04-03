#!/bin/bash
# GitAnimals Buddy — JSONL 기반 세션 사용량 계산
# Claude Code가 자동 생성하는 로컬 JSONL 로그를 파싱하여 사용량 산출
# 참고: https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor
set -euo pipefail

CACHE_DIR="${HOME}/.cache/gitanimals"
USAGE_CACHE="${CACHE_DIR}/usage-cache.txt"
PROJECTS_DIR="${HOME}/.claude/projects"

# 5시간 = 18000초 (Claude 세션 리셋 주기)
WINDOW=18000

# 플랜별 output token 한도 추정 (5시간 기준)
# Pro: ~44K, Max5: ~88K, Max20: ~220K
# 설정 가능: ~/.claude/gitanimals.json 의 token_limit
CONFIG_FILE="${HOME}/.claude/gitanimals.json"
DEFAULT_LIMIT=80000

get_token_limit() {
  if [ -f "$CONFIG_FILE" ]; then
    local limit
    limit=$(jq -r '.token_limit // empty' "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$limit" ]; then
      echo "$limit"
      return
    fi
  fi
  echo "$DEFAULT_LIMIT"
}

TOKEN_LIMIT=$(get_token_limit)

mkdir -p "$CACHE_DIR"

# Check if projects dir exists
if [ ! -d "$PROJECTS_DIR" ]; then
  cat > "$USAGE_CACHE" <<EOF
UTILIZATION=0
OUTPUT_TOKENS=0
RESETS_AT=
TIMESTAMP=$(date +%s)
EOF
  exit 0
fi

NOW=$(date +%s)
FIVE_HOURS_AGO=$(( NOW - WINDOW ))

# macOS date format
if [ "$(uname)" = "Darwin" ]; then
  CUTOFF=$(date -u -r "$FIVE_HOURS_AGO" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
else
  CUTOFF=$(date -u -d "@$FIVE_HOURS_AGO" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
fi

# Collect output tokens and timestamps from recent JSONL entries
TMPFILE=$(mktemp)
find "$PROJECTS_DIR" -name "*.jsonl" -maxdepth 3 2>/dev/null | while read -r f; do
  jq -r --arg cutoff "$CUTOFF" '
    select(.message.usage.output_tokens != null and .timestamp != null and .timestamp > $cutoff)
    | "\(.message.usage.output_tokens) \(.timestamp)"
  ' "$f" 2>/dev/null
done > "$TMPFILE"

# Sum output tokens
TOTAL_OUTPUT=$(awk '{s+=$1} END {print s+0}' "$TMPFILE")

# Find oldest timestamp in window (for reset time estimation)
OLDEST_TS=$(awk '{print $2}' "$TMPFILE" | sort | head -1)

rm -f "$TMPFILE"

# Calculate utilization
if [ "$TOKEN_LIMIT" -gt 0 ]; then
  UTILIZATION=$(( TOTAL_OUTPUT * 100 / TOKEN_LIMIT ))
  [ "$UTILIZATION" -gt 100 ] && UTILIZATION=100
else
  UTILIZATION=0
fi

# Estimate reset time: oldest entry in window + 5 hours
RESETS_AT=""
if [ -n "$OLDEST_TS" ]; then
  # Strip fractional seconds and Z for parsing
  CLEAN_TS=$(echo "$OLDEST_TS" | sed 's/\.[0-9]*Z$//' | sed 's/Z$//')
  if [ "$(uname)" = "Darwin" ]; then
    OLDEST_EPOCH=$(date -juf "%Y-%m-%dT%H:%M:%S" "$CLEAN_TS" +%s 2>/dev/null || echo "")
  else
    OLDEST_EPOCH=$(date -u -d "$CLEAN_TS" +%s 2>/dev/null || echo "")
  fi
  if [ -n "$OLDEST_EPOCH" ]; then
    RESET_EPOCH=$(( OLDEST_EPOCH + WINDOW ))
    if [ "$(uname)" = "Darwin" ]; then
      RESETS_AT=$(date -u -r "$RESET_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
    else
      RESETS_AT=$(date -u -d "@$RESET_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
    fi
  fi
fi

# Write cache
cat > "$USAGE_CACHE" <<EOF
UTILIZATION=$UTILIZATION
OUTPUT_TOKENS=$TOTAL_OUTPUT
RESETS_AT=$RESETS_AT
TIMESTAMP=$(date +%s)
EOF
