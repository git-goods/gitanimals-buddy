#!/bin/bash
# GitAnimals Buddy — integrated statusLine renderer for Claude Code
# Pet left, status info stacked vertically beside sprite lines
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="${HOME}/.cache/gitanimals"
CACHE_FILE="${CACHE_DIR}/pet-cache.json"
CONFIG_FILE="${HOME}/.claude/gitanimals.json"
CACHE_TTL=300

# === Color Constants ===
DIM='\033[2m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
GRAY='\033[90m'
BLUE='\033[34m'
R='\033[0m'

# === Read stdin once ===
INPUT=$(cat)

# === Terminal size — compact if too small ===
TERM_WIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 120)}"
TERM_HEIGHT="${LINES:-$(tput lines 2>/dev/null || echo 24)}"
RENDER_MODE="full"
if [ "$TERM_HEIGHT" -lt 8 ] || [ "$TERM_WIDTH" -lt 40 ]; then
  RENDER_MODE="micro"
elif [ "$TERM_HEIGHT" -lt 15 ] || [ "$TERM_WIDTH" -lt 50 ]; then
  RENDER_MODE="compact"
fi

# === Parse session data ===
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "—"' 2>/dev/null)
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | cut -d. -f1)

# Context color
ctx_color="${CYAN}"
[ "$CTX_PCT" -ge 70 ] && ctx_color="${YELLOW}"
[ "$CTX_PCT" -ge 90 ] && ctx_color='\033[31m'

# Dir + branch
current_dir=$(echo "$INPUT" | jq -r '.workspace.current_dir // ""' 2>/dev/null)
current_dir=$(basename "$current_dir" 2>/dev/null || echo "")
branch=$(git branch --show-current 2>/dev/null || echo "")

# Usage (from self-contained JSONL-based cache)
usage_text=""
u_color="${GREEN}"
usage_cache_file="$HOME/.cache/gitanimals/usage-cache.txt"
if [ -f "$usage_cache_file" ]; then
  u_cache_ts=$(grep "^TIMESTAMP=" "$usage_cache_file" 2>/dev/null | cut -d= -f2)
  now_ts=$(date +%s)
  if [ -n "$u_cache_ts" ] && [ $(( now_ts - u_cache_ts )) -lt 300 ]; then
    cache_util=$(grep "^UTILIZATION=" "$usage_cache_file" | cut -d= -f2)
    resets_at=$(grep "^RESETS_AT=" "$usage_cache_file" | cut -d= -f2)
    if [ -n "$cache_util" ]; then
      u_color="${GREEN}"
      [ "$cache_util" -ge 40 ] && u_color="${YELLOW}"
      [ "$cache_util" -ge 70 ] && u_color='\033[38;5;208m'
      [ "$cache_util" -ge 90 ] && u_color='\033[31m'
      # Mini bar
      filled=$(( cache_util / 10 ))
      empty=$(( 10 - filled ))
      bar=""
      for ((i=0; i<filled; i++)); do bar+="▓"; done
      for ((i=0; i<empty; i++)); do bar+="░"; done
      # Reset time
      reset_display=""
      if [ -n "$resets_at" ]; then
        clean_ts=$(echo "$resets_at" | sed 's/\.[0-9]*Z$//' | sed 's/Z$//')
        if [ "$(uname)" = "Darwin" ]; then
          reset_epoch=$(date -juf "%Y-%m-%dT%H:%M:%S" "$clean_ts" +%s 2>/dev/null || echo "")
        else
          reset_epoch=$(date -u -d "$clean_ts" +%s 2>/dev/null || echo "")
        fi
        if [ -n "$reset_epoch" ]; then
          if [ "$(uname)" = "Darwin" ]; then
            reset_time=$(date -r "$reset_epoch" "+%I:%M %p" 2>/dev/null)
          else
            reset_time=$(date -d "@$reset_epoch" "+%I:%M %p" 2>/dev/null)
          fi
          [ -n "$reset_time" ] && reset_display=" → ${reset_time}"
        fi
      fi
      usage_text=$(printf '%b' "${u_color}Usage: ${cache_util}% ${bar}${reset_display}${R}")
    fi
  else
    # Cache stale — trigger background refresh
    bash "$SCRIPT_DIR/fetch-usage.sh" &>/dev/null &
  fi
fi

# === Helpers ===

get_config_value() {
  local key="$1" default="${2:-}"
  if [ -f "$CONFIG_FILE" ]; then
    jq -r ".$key // \"$default\"" "$CONFIG_FILE" 2>/dev/null || echo "$default"
  else
    echo "$default"
  fi
}

get_pet_data() {
  if [ -f "$CACHE_FILE" ]; then
    local cache_age=0
    if [ "$(uname)" = "Darwin" ]; then
      cache_age=$(( $(date +%s) - $(stat -f%m "$CACHE_FILE") ))
    else
      cache_age=$(( $(date +%s) - $(stat -c%Y "$CACHE_FILE") ))
    fi
    if [ "$cache_age" -lt "$CACHE_TTL" ]; then
      cat "$CACHE_FILE"
      return 0
    fi
  fi
  if [ -f "$CACHE_FILE" ]; then
    local username
    username=$(get_config_value "username" "")
    [ -z "$username" ] && username=$(git config --global user.name 2>/dev/null || echo "")
    if [ -n "$username" ]; then
      mkdir -p "$CACHE_DIR"
      (curl -s --max-time 3 "https://render.gitanimals.org/users/${username}" 2>/dev/null | jq . > "$CACHE_FILE.tmp" 2>/dev/null && mv "$CACHE_FILE.tmp" "$CACHE_FILE") &
    fi
    cat "$CACHE_FILE"
    return 0
  fi
  echo '{"_loading":true}'
}

get_active_pet() {
  local data="$1"
  local selected
  selected=$(get_config_value "active_pet" "")
  if [ -n "$selected" ]; then echo "$selected"; return; fi
  echo "$data" | jq -r '
    [.personas[]? | select(.type != null)]
    | sort_by(-(.level | tonumber))
    | .[0]
    | {type: .type, level: (.level | tonumber), name: .type}
    | @json
  ' 2>/dev/null || echo '{"type":"GOOSE","level":1,"name":"Goose"}'
}

render_sprite() {
  local pet_type="$1" frame="$2"
  local pet_lower=$(echo "$pet_type" | tr '[:upper:]' '[:lower:]')
  local sprite_file="${SCRIPT_DIR}/sprites/${pet_lower}.sh"
  if [ -f "$sprite_file" ]; then
    source "$sprite_file"
    "${pet_lower}_frame" "$frame"
  else
    source "${SCRIPT_DIR}/sprites/fallback.sh"
    fallback_frame "$frame"
  fi
}

# Compact face per pet type
get_compact_face() {
  local pet_type="$1"
  case "$(echo "$pet_type" | tr '[:upper:]' '[:lower:]')" in
    goose)        echo "(o>)"   ;;
    little_chick) echo "(°v°)"  ;;
    penguin)      echo "(^^)"   ;;
    cat)          echo "(·.·)"  ;;
    capybara)     echo "(*_*)"  ;;
    rabbit)       echo "(°..°)" ;;
    pig)          echo "(ꈍ.ꈍ)" ;;
    slime)        echo "(~.~)"  ;;
    hamster)      echo "(•ᴥ•)"  ;;
    sloth)        echo "(-_-)"  ;;
    *)            echo "(◦◦)"   ;;
  esac
}

get_bubble_text() {
  local ctx_pct="${1:-0}"
  if [ "$ctx_pct" -ge 90 ]; then
    local msgs=("Running low..." "Almost full!" "Save context!")
  elif [ "$ctx_pct" -ge 70 ]; then
    local msgs=("Getting busy!" "Keep going~" "Focus time!")
  else
    local msgs=("Let's code!" "Nice work~" "I'm here!" "Go go go!" "Ship it!" "You got this!")
  fi
  echo "${msgs[$(( $(date +%S) % ${#msgs[@]} ))]}"
}

level_stars() {
  local level="${1:-1}" stars="" filled=$(( ${1:-1} / 3 ))
  [ "$filled" -gt 5 ] && filled=5
  for ((i=0; i<filled; i++)); do stars+="★"; done
  for ((i=filled; i<5; i++)); do stars+="☆"; done
  echo "$stars"
}

# === Check hidden ===
hidden=$(get_config_value "hidden" "false")
if [ "$hidden" = "true" ]; then
  # Just show dir | branch
  printf '%b\n' "${BLUE}${current_dir}${R} ${GRAY}│${R} ${GREEN}⎇ ${branch}${R}"
  exit 0
fi

# === Pet data ===
pet_data=$(get_pet_data)
is_loading=$(echo "$pet_data" | jq -r '._loading // false' 2>/dev/null)

if [ "$is_loading" = "true" ]; then
  printf '%b\n' "${BLUE}${current_dir}${R} ${GRAY}│${R} ${GREEN}⎇ ${branch}${R}"
  dots=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  printf '%b\n' "${DIM}${dots[$(( $(date +%S) % 10 ))]} Loading pet data...${R}"
  exit 0
fi

active_pet=$(get_active_pet "$pet_data")
pet_type=$(echo "$active_pet" | jq -r '.type // "GOOSE"' 2>/dev/null)
pet_level=$(echo "$active_pet" | jq -r '.level // 1' 2>/dev/null)
pet_name=$(echo "$active_pet" | jq -r '.name // .type' 2>/dev/null)
frame=$(( $(date +%s) % 2 ))
bubble=$(get_bubble_text "$CTX_PCT")
stars=$(level_stars "$pet_level")

# === Build status info lines (vertical) ===
# Line 0: dir │ branch  (beside sprite top)
info_0="${BLUE}${current_dir}${R} ${GRAY}│${R} ${GREEN}⎇ ${branch}${R}"

# Line 1: (beside bubble — left empty, bubble is enough)

# Line 2: model │ ctx
info_2="${YELLOW}${MODEL}${R} ${GRAY}│${R} ${ctx_color}Ctx: ${CTX_PCT}%${R}"

# Line 3: usage
info_3="$usage_text"

# === Micro mode: 1 line when terminal very small ===
if [ "$RENDER_MODE" = "micro" ]; then
  face=$(get_compact_face "$pet_type")
  u_short=""
  if [ -n "$usage_text" ] && [ -n "${cache_util:-}" ]; then
    u_short=" U:${cache_util}%"
  fi
  printf '%b\n' "${MAGENTA}${face}${R} ${YELLOW}${MODEL}${R} ${ctx_color}C:${CTX_PCT}%${R}${u_short:+ ${u_color}${u_short}${R}}"
  exit 0
fi

# === Compact mode: 2 lines when terminal too short ===
if [ "$RENDER_MODE" = "compact" ]; then
  face=$(get_compact_face "$pet_type")
  printf '%b\n' "${BLUE}${current_dir}${R} ${GRAY}│${R} ${GREEN}⎇ ${branch}${R} ${GRAY}│${R} ${YELLOW}${MODEL}${R} ${GRAY}│${R} ${ctx_color}Ctx: ${CTX_PCT}%${R}"
  printf '%b\n' "${MAGENTA}${face}${R} ${BOLD}${pet_name}${R} Lv.${pet_level} ${YELLOW}${stars}${R} ${GRAY}│${R} ${CYAN}${bubble}${R}"
  exit 0
fi

# === Sprite ===
sprite_lines=()
while IFS= read -r line; do sprite_lines+=("$line"); done < <(render_sprite "$pet_type" "$frame")

gap="   "

# === Render ===
for i in "${!sprite_lines[@]}"; do
  line="${sprite_lines[$i]}"
  # Ensure no empty lines (Claude Code strips them via flatMap)
  [ -z "$(echo "$line" | tr -d '[:space:]')" ] && line=" ."
  if [ "$i" -eq 0 ]; then
    printf '%s%s%b\n' "$line" "$gap" "$info_0"
  elif [ "$i" -eq 1 ]; then
    printf '%s %b\n' "$line" "${DIM}💬${R} ${CYAN}${bubble}${R}"
  elif [ "$i" -eq 2 ]; then
    printf '%s%s%b\n' "$line" "$gap" "$info_2"
  elif [ "$i" -eq 3 ]; then
    if [ -n "$info_3" ]; then
      printf '%s%s%b\n' "$line" "$gap" "$info_3"
    else
      printf '%s\n' "$line"
    fi
  elif [ "$i" -eq "$(( ${#sprite_lines[@]} - 1 ))" ]; then
    continue
  else
    printf '%s\n' "$line"
  fi
done

printf ' %b\n' "${BOLD}${MAGENTA}${pet_name}${R} Lv.${pet_level} ${YELLOW}${stars}${R}"
