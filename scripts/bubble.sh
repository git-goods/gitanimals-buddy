#!/bin/bash
# bubble.sh — 컨텍스트 인식 대사 엔진
# Usage: source this file, then call get_contextual_bubble <mood> <ctx_pct> <cost_usd>

BUBBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../resources/bubbles" && pwd)"
BUBBLE_FILE="${BUBBLE_DIR}/ko.txt"
CACHE_DIR="${HOME}/.cache/gitanimals"

# 시간대 태그
get_time_tag() {
  local hour="${1:-$(date +%H)}"
  hour=$((10#$hour))
  if [ "$hour" -ge 6 ] && [ "$hour" -lt 12 ]; then
    echo "time:morning"
  elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
    echo "time:afternoon"
  elif [ "$hour" -ge 18 ] && [ "$hour" -lt 23 ]; then
    echo "time:evening"
  else
    echo "time:dawn"
  fi
}

# 매칭 태그 수집 — outputs newline-separated tags
collect_tags() {
  local mood="${1:-normal}" ctx_pct="${2:-0}" cost_usd="${3:-0}"
  local tags=""

  # mood (always)
  tags="mood:${mood}"

  # time
  tags="${tags}
$(get_time_tag)"

  # weekend (Sat=6, Sun=7)
  local dow
  dow=$(date +%u)
  if [ "$dow" -ge 6 ]; then
    tags="${tags}
habit:weekend"
  fi

  # long session (2h+)
  local session_file="${CACHE_DIR}/session-start.txt"
  if [ -f "$session_file" ]; then
    local start_ts now_ts
    start_ts=$(cat "$session_file" 2>/dev/null | tr -d '[:space:]')
    now_ts=$(date +%s)
    if [ -n "$start_ts" ] && [ "$((now_ts - start_ts))" -ge 7200 ] 2>/dev/null; then
      tags="${tags}
habit:long_session"
    fi
  fi

  # context events (ctx_high replaces ctx_half, not both)
  local ctx_num
  ctx_num=$((10#${ctx_pct:-0})) 2>/dev/null || ctx_num=0
  if [ "$ctx_num" -ge 80 ] 2>/dev/null; then
    tags="${tags}
event:ctx_high"
  elif [ "$ctx_num" -ge 50 ] 2>/dev/null; then
    tags="${tags}
event:ctx_half"
  fi

  # cost event
  local cost_cents
  cost_cents=$(echo "$cost_usd" | awk '{printf "%d", $1 * 100}' 2>/dev/null || echo "0")
  if [ "$cost_cents" -ge 100 ] 2>/dev/null; then
    tags="${tags}
event:cost_1usd"
  fi

  echo "$tags"
}

# 대사 선택
get_contextual_bubble() {
  local mood="${1:-normal}" ctx_pct="${2:-0}" cost_usd="${3:-0}"

  if [ ! -f "$BUBBLE_FILE" ]; then
    echo "..."
    return
  fi

  # collect matching tags
  local tags_str
  tags_str=$(collect_tags "$mood" "$ctx_pct" "$cost_usd")

  # gather messages from all matching tags
  local pool=()
  while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    while IFS='|' read -r _tag msg; do
      msg=$(echo "$msg" | sed 's/^ *//;s/ *$//')
      [ -n "$msg" ] && pool+=("$msg")
    done < <(grep "^${tag} |" "$BUBBLE_FILE")
  done <<< "$tags_str"

  # worried/panic: double mood messages for higher weight
  if [ "$mood" = "worried" ] || [ "$mood" = "panic" ]; then
    while IFS='|' read -r _tag msg; do
      msg=$(echo "$msg" | sed 's/^ *//;s/ *$//')
      [ -n "$msg" ] && pool+=("$msg")
    done < <(grep "^mood:${mood} |" "$BUBBLE_FILE")
  fi

  # fallback
  if [ "${#pool[@]}" -eq 0 ]; then
    echo "..."
    return
  fi

  # random selection
  local idx=$(( $(date +%s%N 2>/dev/null || date +%s) % ${#pool[@]} ))
  echo "${pool[$idx]}"
}
