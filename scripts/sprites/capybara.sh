#!/bin/bash
# CAPYBARA — 2 frames, 5 lines x 12 chars

capybara_frame() {
  local frame="${1:-0}"
  local BROWN='\033[38;5;130m'
  local DARK='\033[38;5;94m'
  local PINK='\033[38;5;217m'
  local R='\033[0m'
  local BS='\\'  # literal backslash for printf %b

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "  ${BROWN}___${R}       "
    printf '%b\n' " ${BROWN}(${DARK}*${BROWN}_${DARK}*${BROWN})${R}     "
    printf '%b\n' " ${BROWN}/${PINK}~${BROWN}===${BS}${R}    "
    printf '%b\n' "${BROWN}|      |${R}   "
    printf '%b\n' "${BROWN}d|    |b${R}   "
  else
    printf '%b\n' "  ${BROWN}___${R}       "
    printf '%b\n' " ${BROWN}(${DARK}*${BROWN}_${DARK}*${BROWN})~${R}    "
    printf '%b\n' " ${BROWN}/${PINK}~${BROWN}===${BS}${R}    "
    printf '%b\n' "${BROWN}|      |${R}   "
    printf '%b\n' "${BROWN}d|    |b${R}   "
  fi
}
