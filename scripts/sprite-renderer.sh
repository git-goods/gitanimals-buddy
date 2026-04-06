#!/bin/bash
# sprite-renderer.sh — .sprite 파일을 읽어 ANSI 컬러 적용된 5줄 출력
# Usage: bash sprite-renderer.sh <sprite_file> <frame> <mood>
# Compatible with bash 3.2+
set -euo pipefail

SPRITE_FILE="${1:?Usage: sprite-renderer.sh <file> <frame> <mood>}"
FRAME="${2:-0}"
MOOD="${3:-normal}"

# === Parse metadata ===
body_color=""
eye_color=""
panic_eye_color=""
# Store colors as c1_val, c2_val, etc. via eval
# Store eyes as eyes_happy_val, etc. via eval

while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^\[frame: ]] && break
  if [[ "$line" =~ ^([a-z_][a-z_0-9]*)=(.*)$ ]]; then
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    case "$key" in
      body_color) body_color="$val" ;;
      eye_color) eye_color="$val" ;;
      panic_eye_color) panic_eye_color="$val" ;;
      c[0-9]*)
        varname="color_${key}"
        eval "${varname}=\$val"
        ;;
      eyes_*)
        mood_name="${key#eyes_}"
        varname="eye_mood_${mood_name}"
        eval "${varname}=\$val"
        ;;
    esac
  fi
done < "$SPRITE_FILE"

# === Resolve eyes ===
eye_var="eye_mood_${MOOD}"
eye_str="${!eye_var:-}"
if [ -z "$eye_str" ]; then
  eye_str="${eye_mood_normal:-o}"
fi

if [[ "$eye_str" == *" "* ]]; then
  L_EYE="${eye_str%% *}"
  R_EYE="${eye_str##* }"
else
  L_EYE="$eye_str"
  R_EYE="$eye_str"
fi

# === Resolve eye color ===
active_eye_color="$eye_color"
if [ "$MOOD" = "panic" ] && [ -n "$panic_eye_color" ]; then
  active_eye_color="$panic_eye_color"
fi

# === ANSI codes ===
RST='\033[0m'
BODY="\033[${body_color}m"
EYE="\033[${active_eye_color}m"

# === Extract frame block ===
in_frame=false
frame_lines=()

while IFS= read -r line; do
  if [[ "$line" == "[frame:${FRAME}]" ]]; then
    in_frame=true
    continue
  fi
  if $in_frame; then
    [[ "$line" =~ ^\[frame: ]] && break
    frame_lines+=("$line")
  fi
done < "$SPRITE_FILE"

# === Trim trailing empty lines from frame ===
while [ "${#frame_lines[@]}" -gt 0 ]; do
  last="${frame_lines[${#frame_lines[@]}-1]}"
  if [[ -z "$last" ]]; then
    unset 'frame_lines[${#frame_lines[@]}-1]'
  else
    break
  fi
done

# === Render ===
for line in "${frame_lines[@]}"; do
  line="${line//\{L\}/${EYE}${L_EYE}${BODY}}"
  line="${line//\{R\}/${EYE}${R_EYE}${BODY}}"
  # Replace {1}, {2}, etc. with corresponding color codes
  for i in 1 2 3 4 5 6 7 8 9; do
    cvar="color_c${i}"
    cval="${!cvar:-}"
    if [ -n "$cval" ]; then
      line="${line//\{${i}\}/\\033[${cval}m}"
    fi
  done
  line="${line//\{\/\}/${BODY}}"
  printf '%b\n' "${BODY}${line}${RST}"
done
