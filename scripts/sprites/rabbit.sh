#!/bin/bash
# RABBIT — 2 frames × 4 moods, 5 lines x 12 chars

rabbit_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local WHITE='\033[97m'
  local PINK='\033[38;5;217m'
  local R='\033[0m'
  local BS='\\'

  # mood별 눈
  local L_EYE R_EYE
  case "$mood" in
    happy)   L_EYE="★"; R_EYE="★" ;;
    normal)  L_EYE="•"; R_EYE="•" ;;
    worried) L_EYE=";"; R_EYE=";" ;;
    panic)   L_EYE="X"; R_EYE="X" ;;
  esac

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' " ${WHITE}(\\/) (\\/)${R} "
    printf '%b\n' " ${WHITE}( ${PINK}${L_EYE}${WHITE}.${PINK}${R_EYE}${WHITE} )${R}  "
    printf '%b\n' " ${WHITE}/ > ${PINK}<3${R}    "
    printf '%b\n' "${WHITE}(__${BS}_${BS}_)${R}   "
    printf '%b\n' "             "
  else
    printf '%b\n' " ${WHITE}(\\/) (\\/)${R} "
    printf '%b\n' " ${WHITE}( ${PINK}${L_EYE}${WHITE}.${PINK}${R_EYE}${WHITE} )${R}  "
    printf '%b\n' " ${WHITE}/ >  <${BS}${R}   "
    printf '%b\n' "${WHITE}(__${BS}_${BS}_)${R}   "
    printf '%b\n' "             "
  fi
}
