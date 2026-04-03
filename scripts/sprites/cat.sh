#!/bin/bash
# CAT — 2 frames, 5 lines x 12 chars

cat_frame() {
  local frame="${1:-0}"
  local GRAY='\033[37m'
  local PINK='\033[35m'
  local GREEN='\033[32m'
  local R='\033[0m'
  local BS='\\'  # literal backslash for printf %b

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "   ${GRAY}/${BS}_/${BS}${R}     "
    printf '%b\n' "  ${GRAY}( ${GREEN}o${GRAY}.${GREEN}o${GRAY} )${R}    "
    printf '%b\n' "   ${GRAY}> ^ <${R}     "
    printf '%b\n' "  ${GRAY}/|   |${BS}${R}   "
    printf '%b\n' "  ${GRAY}(_${PINK}~${GRAY}_${PINK}~${GRAY}_)${R}   "
  else
    printf '%b\n' "   ${GRAY}/${BS}_/${BS}${R}     "
    printf '%b\n' "  ${GRAY}( ${GREEN}-${GRAY}.${GREEN}-${GRAY} )${R}    "
    printf '%b\n' "   ${GRAY}> ^ <${R}     "
    printf '%b\n' "  ${GRAY}/|   |${BS}${R}   "
    printf '%b\n' "  ${GRAY}(_${PINK}~${GRAY}_${PINK}~${GRAY}_)${R}   "
  fi
}
