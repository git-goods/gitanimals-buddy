#!/bin/bash
# FALLBACK — generic silhouette for unsupported pets

fallback_frame() {
  local frame="${1:-0}"
  local DIM='\033[2m'
  local R='\033[0m'

  if [ "$frame" -eq 0 ]; then
    printf '%b\n' "${DIM}┌───────┐${R} "
    printf '%b\n' "${DIM}│  ◦ ◦  │${R} "
    printf '%b\n' "${DIM}│  ???  │${R} "
    printf '%b\n' "${DIM}└───────┘${R} "
    printf '%b\n' "             "
  else
    printf '%b\n' "${DIM}┌───────┐${R} "
    printf '%b\n' "${DIM}│  • •  │${R} "
    printf '%b\n' "${DIM}│  ???  │${R} "
    printf '%b\n' "${DIM}└───────┘${R} "
    printf '%b\n' "             "
  fi
}
