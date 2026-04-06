#!/bin/bash
# LITTLE_CHICK — 2 frames × 4 moods, 5 lines x 12 chars

little_chick_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local YELLOW='\033[93m'
  local ORANGE='\033[38;5;208m'
  local R='\033[0m'

  local FACE
  case "$mood" in
    happy)   FACE="°v°" ;;
    normal)  FACE="°v°" ;;
    worried) FACE="°~°" ;;
    panic)   FACE="°Д°" ;;
  esac

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "             "
    printf '%b\n' "${YELLOW}(${FACE})${R}    "
    printf '%b\n' "${YELLOW}/)_)${R}     "
    printf '%b\n' "${ORANGE}_| |_${R}    "
    printf '%b\n' "             "
  else
    printf '%b\n' "             "
    printf '%b\n' "${YELLOW}(${FACE})${R}    "
    printf '%b\n' "${YELLOW}~/)_)${R}    "
    printf '%b\n' "${ORANGE}_| |_${R}    "
    printf '%b\n' "             "
  fi
}
