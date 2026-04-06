#!/bin/bash
# CAT — 2 frames × 4 moods, 5 lines x 12 chars

cat_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local GRAY='\033[37m'
  local PINK='\033[35m'
  local GREEN='\033[32m'
  local R='\033[0m'
  local BS='\\'

  local L_EYE R_EYE
  case "$mood" in
    happy)   L_EYE="^"; R_EYE="^" ;;
    normal)  L_EYE="o"; R_EYE="o" ;;
    worried) L_EYE=";"; R_EYE=";" ;;
    panic)   L_EYE=">"; R_EYE="<" ;;
  esac

  local EYE_COLOR="${GREEN}"
  [ "$mood" = "panic" ] && EYE_COLOR='\033[31m'

  printf '%b\n' " ${GRAY}/${BS}_/${BS}${R}     "
  printf '%b\n' "${GRAY}( ${EYE_COLOR}${L_EYE}${GRAY}.${EYE_COLOR}${R_EYE}${GRAY} )${R}    "
  printf '%b\n' " ${GRAY}> ^ <${R}     "
  printf '%b\n' "${GRAY}/|   |${BS}${R}   "
  printf '%b\n' "${GRAY}(_${PINK}~${GRAY}_${PINK}~${GRAY}_)${R}   "
}
