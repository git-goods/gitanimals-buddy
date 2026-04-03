#!/bin/bash
# Preview script — test statusline rendering with mock data
# Usage: bash scripts/preview.sh [pet_type] [level]
#   e.g.: bash scripts/preview.sh goose 5
#         bash scripts/preview.sh penguin 12
#         bash scripts/preview.sh all
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PET_TYPE="${1:-goose}"
PET_LEVEL="${2:-5}"

# Create temp config for preview
PREVIEW_CONFIG=$(mktemp)
echo "{\"username\":\"preview\",\"hidden\":false,\"active_pet\":\"\"}" > "$PREVIEW_CONFIG"

# Create temp cache
PREVIEW_CACHE=$(mktemp)

# Mock Claude Code session JSON
MOCK_SESSION='{
  "model": {"id": "claude-opus-4-6", "display_name": "Opus 4.6"},
  "context_window": {"used_percentage": 23, "remaining_percentage": 77, "context_window_size": 200000},
  "cost": {"total_cost_usd": 0.0542},
  "workspace": {"current_dir": "/home/user/project"},
  "version": "2.1.90"
}'

preview_pet() {
  local pet="$1"
  local level="$2"

  # Create mock pet cache
  cat > "$PREVIEW_CACHE" <<EOF
{"pets":[{"type":"${pet^^}","name":"${pet^}","level":${level},"visible":true}]}
EOF

  # Override config/cache paths by setting env vars
  export HOME_OVERRIDE="/tmp/gitanimals-preview-$$"
  mkdir -p "$HOME_OVERRIDE/.claude" "$HOME_OVERRIDE/.cache/gitanimals"
  cp "$PREVIEW_CONFIG" "$HOME_OVERRIDE/.claude/gitanimals.json"
  cp "$PREVIEW_CACHE" "$HOME_OVERRIDE/.cache/gitanimals/pet-cache.json"

  echo ""
  echo "━━━ ${pet^^} Lv.${level} ━━━"
  echo ""

  # Run statusline with mock data (override HOME)
  HOME="$HOME_OVERRIDE" echo "$MOCK_SESSION" | bash "$SCRIPT_DIR/statusline.sh" 2>/dev/null || {
    # If main script fails, just render sprite directly
    source "$SCRIPT_DIR/sprites/${pet}.sh" 2>/dev/null || source "$SCRIPT_DIR/sprites/fallback.sh"
    "${pet}_frame" 0 2>/dev/null || fallback_frame 0
    echo "  ${pet^^} Lv.${level}"
  }

  # Cleanup
  rm -rf "$HOME_OVERRIDE"
}

if [ "$PET_TYPE" = "all" ]; then
  echo "🐾 GitAnimals Buddy — All Phase 1 Pets Preview"
  echo "================================================"
  for pet in goose little_chick penguin cat capybara; do
    preview_pet "$pet" "$PET_LEVEL"
  done
  echo ""
  echo "━━━ FALLBACK (unsupported pet) ━━━"
  echo ""
  preview_pet "unknown_pet" "$PET_LEVEL"
else
  echo "🐾 GitAnimals Buddy — Preview: ${PET_TYPE^^}"
  echo "================================================"
  preview_pet "$PET_TYPE" "$PET_LEVEL"
fi

# Cleanup
rm -f "$PREVIEW_CONFIG" "$PREVIEW_CACHE"

echo ""
echo "================================================"
echo "To install: Add to ~/.claude/settings.json:"
echo '  "statusLine": {'
echo '    "type": "command",'
echo "    \"command\": \"bash $(cd "$SCRIPT_DIR/.." && pwd)/scripts/statusline.sh\""
echo '  }'
