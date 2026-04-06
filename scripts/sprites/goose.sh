#!/bin/bash
# GOOSE — 2 frames × 4 moods, 5 lines x 12 chars

goose_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local YELLOW='\033[33m'
  local WHITE='\033[97m'
  local ORANGE='\033[38;5;208m'
  local R='\033[0m'

  local EYE
  case "$mood" in
    happy)   EYE="★" ;;
    normal)  EYE="o" ;;
    worried) EYE=";" ;;
    panic)   EYE="X" ;;
  esac

  local EYE_COLOR="${ORANGE}"
  [ "$mood" = "panic" ] && EYE_COLOR='\033[31m'

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "             "
    printf '%b\n' "   ${WHITE}(${EYE_COLOR}${EYE}${WHITE}>)${R}     "
    printf '%b\n' "   ${WHITE}(__)${R}      "
    printf '%b\n' "${WHITE}/)/) ${WHITE}||${R}     "
    printf '%b\n' "${YELLOW}^^${R}  ${YELLOW}^^${R}      "
  else
    printf '%b\n' "             "
    printf '%b\n' "   ${WHITE}(${EYE_COLOR}${EYE}${WHITE}>)${R}     "
    printf '%b\n' "  ${WHITE}~(__)${R}     "
    printf '%b\n' "${WHITE}/)/) ${WHITE}||${R}     "
    printf '%b\n' " ${YELLOW}^^${R}${YELLOW}^^${R}       "
  fi
}
