#!/bin/bash
# PENGUIN — 2 frames × 4 moods, 5 lines x 12 chars

penguin_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local BLACK='\033[90m'
  local WHITE='\033[97m'
  local YELLOW='\033[93m'
  local R='\033[0m'
  local BS='\\'

  local FACE
  case "$mood" in
    happy)   FACE="^^" ;;
    normal)  FACE="^^" ;;
    worried) FACE=";;" ;;
    panic)   FACE="XX" ;;
  esac

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' " ${BLACK}(${FACE})${R}     "
    printf '%b\n' "${BLACK}/${WHITE}(  )${BLACK}${BS}${R}   "
    printf '%b\n' "${BLACK}|${WHITE}(  )${BLACK}|${R}   "
    printf '%b\n' " ${BLACK}${BS}  /${R}     "
    printf '%b\n' " ${YELLOW}/${BS} /${BS}${R}    "
  else
    printf '%b\n' " ${BLACK}(${FACE})${R}     "
    printf '%b\n' "${BLACK}~/${WHITE}(  )${BLACK}${BS}${R}   "
    printf '%b\n' "${BLACK}|${WHITE}(  )${BLACK}|~${R}  "
    printf '%b\n' " ${BLACK}${BS}  /${R}     "
    printf '%b\n' " ${YELLOW}/${BS} /${BS}${R}    "
  fi
}
