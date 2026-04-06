#!/bin/bash
# preview.sh — 인터랙티브 .sprite 미리보기
# Usage: bash scripts/preview.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_DIR="${SCRIPT_DIR}/../resources/sprites"
RENDERER="${SCRIPT_DIR}/sprite-renderer.sh"
source "$SCRIPT_DIR/mood.sh"

# === Colors ===
R='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'

mood_color() {
  case "$1" in
    happy) echo "$GREEN" ;; normal) echo "$CYAN" ;;
    worried) echo "$YELLOW" ;; panic) echo "$RED" ;;
  esac
}

# === Collect available pets ===
PETS=()
for f in "$RESOURCE_DIR"/*.sprite; do
  PETS+=("$(basename "$f" .sprite)")
done

MOODS=(happy normal worried panic)

# === Helpers ===
clear_screen() { printf '\033[2J\033[H'; }

render_sprite_preview() {
  local pet="$1" mood="$2"
  local sprite_file="${RESOURCE_DIR}/${pet}.sprite"
  [ ! -f "$sprite_file" ] && sprite_file="${RESOURCE_DIR}/fallback.sprite"
  bash "$RENDERER" "$sprite_file" 0 "$mood"
}

show_pet_menu() {
  clear_screen
  printf '%b\n' "${BOLD}🐾 GitAnimals Buddy — Sprite Preview${R}"
  printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo ""
  printf '%b\n' "${BOLD}펫을 선택하세요:${R}"
  echo ""

  local i=1
  for pet in "${PETS[@]}"; do
    local face
    face=$(get_mood_compact_face "$pet" "happy")
    local display
    display=$(echo "$pet" | tr '[:lower:]' '[:upper:]')
    printf '  %b%d%b) %b%-15s%b %s\n' "$CYAN" "$i" "$R" "$BOLD" "$display" "$R" "$face"
    i=$((i+1))
  done

  echo ""
  printf '  %b0%b) 전체 보기\n' "$YELLOW" "$R"
  printf '  %bq%b) 종료\n' "$DIM" "$R"
  echo ""
  printf '%b' "${BOLD}> ${R}"
}

show_mood_menu() {
  local pet="$1"
  local display
  display=$(echo "$pet" | tr '[:lower:]' '[:upper:]')

  clear_screen
  printf '%b\n' "${BOLD}🐾 ${MAGENTA}${display}${R}${BOLD} — mood 선택${R}"
  printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
  echo ""

  local i=1
  for mood in "${MOODS[@]}"; do
    local mc face
    mc=$(mood_color "$mood")
    face=$(get_mood_compact_face "$pet" "$mood")
    printf '  %b%d%b) %b%-10s%b %s\n' "$CYAN" "$i" "$R" "$mc" "$mood" "$R" "$face"
    i=$((i+1))
  done

  echo ""
  printf '  %b0%b) 전체 mood 보기\n' "$YELLOW" "$R"
  printf '  %bb%b) 뒤로\n' "$DIM" "$R"
  echo ""
  printf '%b' "${BOLD}> ${R}"
}

show_sprite() {
  local pet="$1" mood="$2"
  local display mc face
  display=$(echo "$pet" | tr '[:lower:]' '[:upper:]')
  mc=$(mood_color "$mood")
  face=$(get_mood_compact_face "$pet" "$mood")

  echo ""
  printf '%b\n' "  ${BOLD}${MAGENTA}${display}${R} ${mc}[${mood}]${R} compact: ${MAGENTA}${face}${R}"
  echo ""

  while IFS= read -r line; do
    printf '    %s\n' "$line"
  done < <(render_sprite_preview "$pet" "$mood")

  echo ""
}

show_all_moods() {
  local pet="$1"
  local display
  display=$(echo "$pet" | tr '[:lower:]' '[:upper:]')

  clear_screen
  printf '%b\n' "${BOLD}🐾 ${MAGENTA}${display}${R}${BOLD} — 전체 mood${R}"
  printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"

  for mood in "${MOODS[@]}"; do
    show_sprite "$pet" "$mood"
  done

  printf '%b\n' "${DIM}───────────────────────────────────────${R}"
}

show_all_pets() {
  clear_screen
  printf '%b\n' "${BOLD}🐾 GitAnimals Buddy — 전체 펫 미리보기${R}"
  printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"

  for pet in "${PETS[@]}"; do
    local display
    display=$(echo "$pet" | tr '[:lower:]' '[:upper:]')
    printf '\n%b\n' "${BOLD}${MAGENTA}▸ ${display}${R}"

    for mood in "${MOODS[@]}"; do
      local mc face
      mc=$(mood_color "$mood")
      face=$(get_mood_compact_face "$pet" "$mood")
      printf '  %b%-10s%b %s  ' "$mc" "$mood" "$R" "$face"
    done
    echo ""

    # Show normal mood sprite as representative
    echo ""
    while IFS= read -r line; do
      printf '    %s\n' "$line"
    done < <(render_sprite_preview "$pet" "normal")
    echo ""
  done

  printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
}

wait_for_key() {
  echo ""
  printf '%b' "${DIM}아무 키나 누르세요...${R}"
  read -rsn1 </dev/tty
}

# === Main Loop ===
while true; do
  show_pet_menu
  read -rsn1 choice </dev/tty
  echo "$choice"

  case "$choice" in
    q|Q) echo ""; printf '%b\n' "${DIM}Bye! 🐾${R}"; exit 0 ;;
    0)
      show_all_pets
      wait_for_key
      continue
      ;;
    [1-9])
      idx=$((choice - 1))
      if [ "$idx" -ge "${#PETS[@]}" ]; then
        continue
      fi
      selected_pet="${PETS[$idx]}"

      # Mood submenu loop
      while true; do
        show_mood_menu "$selected_pet"
        read -rsn1 mchoice </dev/tty
        echo "$mchoice"

        case "$mchoice" in
          b|B) break ;;
          0)
            show_all_moods "$selected_pet"
            wait_for_key
            ;;
          [1-4])
            midx=$((mchoice - 1))
            selected_mood="${MOODS[$midx]}"
            clear_screen
            printf '%b\n' "${BOLD}🐾 Sprite Preview${R}"
            printf '%b\n' "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${R}"
            show_sprite "$selected_pet" "$selected_mood"
            wait_for_key
            ;;
        esac
      done
      ;;
  esac
done
