#!/bin/bash
# LITTLE_CHICK — 2 frames, 5 lines x 12 chars

little_chick_frame() {
  local frame="${1:-0}"
  local YELLOW='\033[93m'
  local ORANGE='\033[38;5;208m'
  local R='\033[0m'

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "             "
    printf '%b\n' "${YELLOW}(°v°)${R}    "
    printf '%b\n' "${YELLOW}/)_)${R}     "
    printf '%b\n' "${ORANGE}_| |_${R}    "
    printf '%b\n' "             "
  else
    printf '%b\n' "             "
    printf '%b\n' "${YELLOW}(°v°)${R}    "
    printf '%b\n' "${YELLOW}~/)_)${R}    "
    printf '%b\n' "${ORANGE}_| |_${R}    "
    printf '%b\n' "             "
  fi
}
