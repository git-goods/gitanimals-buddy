#!/bin/bash
# FALLBACK — generic silhouette, mood-aware

fallback_frame() {
  local frame="${1:-0}" mood="${2:-normal}"
  local DIM='\033[2m'
  local R='\033[0m'

  local EYES
  case "$mood" in
    happy)   EYES="◦ ◦" ;;
    normal)  EYES="◦ ◦" ;;
    worried) EYES="; ;" ;;
    panic)   EYES="X X" ;;
  esac

  printf '%b\n' "${DIM}┌───────┐${R} "
  printf '%b\n' "${DIM}│  ${EYES}  │${R} "
  printf '%b\n' "${DIM}│  ???  │${R} "
  printf '%b\n' "${DIM}└───────┘${R} "
  printf '%b\n' "             "
}
