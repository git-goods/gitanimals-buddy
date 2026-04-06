#!/bin/bash
# GitAnimals — Background pet data fetcher (runs on SessionStart hook)
# Fetches pet data from GitAnimals API and caches locally
set -euo pipefail

CACHE_DIR="${HOME}/.cache/gitanimals"
CACHE_FILE="${CACHE_DIR}/pet-cache.json"
CONFIG_FILE="${HOME}/.claude/gitanimals.json"

mkdir -p "$CACHE_DIR"

# 세션 시작 시간 기록 (bubble.sh의 장시간 코딩 감지에 사용)
echo "$(date +%s)" > "${CACHE_DIR}/session-start.txt"

# Get username from config or git
get_username() {
  if [ -f "$CONFIG_FILE" ]; then
    local username
    username=$(jq -r '.username // empty' "$CONFIG_FILE" 2>/dev/null)
    if [ -n "$username" ]; then
      echo "$username"
      return
    fi
  fi
  # Fallback to git config
  git config --global user.name 2>/dev/null || echo ""
}

USERNAME=$(get_username)

if [ -z "$USERNAME" ]; then
  echo '{"error": "No username configured. Run /animals login or set username in ~/.claude/gitanimals.json"}'
  exit 0
fi

# Fetch in background (don't block session start)
(
  RESPONSE=$(curl -s --max-time 5 "https://render.gitanimals.org/users/${USERNAME}" 2>/dev/null || echo "")

  if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq . >/dev/null 2>&1; then
    echo "$RESPONSE" > "$CACHE_FILE"
    # Store fetch timestamp
    jq -n --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{last_sync: $ts}' > "${CACHE_DIR}/sync-meta.json"
  fi
) &

echo "GitAnimals: Pet data sync started for ${USERNAME}"
