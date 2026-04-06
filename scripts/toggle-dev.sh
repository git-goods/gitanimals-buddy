#!/bin/bash
# Toggle between dev (symlink) and release (installed copy) mode
set -euo pipefail

PLUGIN_PATH="$HOME/.claude/plugins/gitanimals-buddy"
# Resolve repo path from this script's location (scripts/ 디렉토리의 상위)
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -L "$PLUGIN_PATH" ]; then
  # Currently dev → switch to release
  rm "$PLUGIN_PATH"
  git clone --depth 1 https://github.com/git-goods/gitanimals-buddy.git "$PLUGIN_PATH" 2>/dev/null
  echo "✅ Switched to RELEASE mode (installed copy)"
else
  # Currently release → switch to dev
  rm -rf "$PLUGIN_PATH"
  ln -s "$REPO_PATH" "$PLUGIN_PATH"
  echo "✅ Switched to DEV mode (symlink → repo)"
fi

# Show current state
if [ -L "$PLUGIN_PATH" ]; then
  echo "   📂 $PLUGIN_PATH → $(readlink "$PLUGIN_PATH")"
else
  echo "   📦 $PLUGIN_PATH (standalone)"
fi
