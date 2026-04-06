#!/bin/bash
# RABBIT — 2 frames, 5 lines x 12 chars

rabbit_frame() {
  local frame="${1:-0}"
  local WHITE='\033[97m'
  local PINK='\033[38;5;217m'
  local R='\033[0m'
  local BS='\\'

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' " ${WHITE}(\\/) (\\/)${R} "
    printf '%b\n' " ${WHITE}( ${PINK}•${WHITE}.${PINK}•${WHITE} )${R}  "
    printf '%b\n' " ${WHITE}/ > ${PINK}<3${R}    "
    printf '%b\n' "${WHITE}(__${BS}_${BS}_)${R}   "
    printf '%b\n' "             "
  else
    printf '%b\n' " ${WHITE}(\\/) (\\/)${R} "
    printf '%b\n' " ${WHITE}( ${PINK}^${WHITE}.${PINK}^${WHITE} )${R}  "
    printf '%b\n' " ${WHITE}/ >  <${BS}${R}   "
    printf '%b\n' "${WHITE}(__${BS}_${BS}_)${R}   "
    printf '%b\n' "             "
  fi
}
