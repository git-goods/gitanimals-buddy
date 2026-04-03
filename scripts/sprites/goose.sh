#!/bin/bash
# GOOSE — 2 frames, 5 lines x 12 chars
# Usage: source this file, then call goose_frame <0|1>

goose_frame() {
  local frame="${1:-0}"
  local YELLOW='\033[33m'
  local WHITE='\033[97m'
  local ORANGE='\033[38;5;208m'
  local R='\033[0m'

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "             "
    printf '%b\n' "    ${WHITE}(${ORANGE}o${WHITE}>)${R}     "
    printf '%b\n' "    ${WHITE}(__)${R}      "
    printf '%b\n' " ${WHITE}/)/) ${WHITE}||${R}     "
    printf '%b\n' " ${YELLOW}^^${R}  ${YELLOW}^^${R}      "
  else
    printf '%b\n' "             "
    printf '%b\n' "    ${WHITE}(${ORANGE}o${WHITE}>)${R}     "
    printf '%b\n' "   ${WHITE}~(__)${R}     "
    printf '%b\n' " ${WHITE}/)/) ${WHITE}||${R}     "
    printf '%b\n' "  ${YELLOW}^^${R}${YELLOW}^^${R}       "
  fi
}
