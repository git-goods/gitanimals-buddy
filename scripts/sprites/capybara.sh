#!/bin/bash
# CAPYBARA — 2 frames × 4 moods, 5 lines x 12 chars

capybara_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local BROWN='\033[38;5;130m'
  local DARK='\033[38;5;94m'
  local PINK='\033[38;5;217m'
  local R='\033[0m'
  local BS='\\'

  local L_EYE R_EYE
  case "$mood" in
    happy)   L_EYE="*"; R_EYE="*" ;;
    normal)  L_EYE="*"; R_EYE="*" ;;
    worried) L_EYE=";"; R_EYE=";" ;;
    panic)   L_EYE="X"; R_EYE="X" ;;
  esac

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "  ${BROWN}___${R}       "
    printf '%b\n' " ${BROWN}(${DARK}${L_EYE}${BROWN}_${DARK}${R_EYE}${BROWN})${R}     "
    printf '%b\n' " ${BROWN}/${PINK}~${BROWN}===${BS}${R}    "
    printf '%b\n' "${BROWN}|      |${R}   "
    printf '%b\n' "${BROWN}d|    |b${R}   "
  else
    printf '%b\n' "  ${BROWN}___${R}       "
    printf '%b\n' " ${BROWN}(${DARK}${L_EYE}${BROWN}_${DARK}${R_EYE}${BROWN})~${R}    "
    printf '%b\n' " ${BROWN}/${PINK}~${BROWN}===${BS}${R}    "
    printf '%b\n' "${BROWN}|      |${R}   "
    printf '%b\n' "${BROWN}d|    |b${R}   "
  fi
}
