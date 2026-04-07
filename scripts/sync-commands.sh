#!/bin/bash
# Sync commands/*.md → ~/.claude/commands/ via symlink
# Runs on SessionStart hook

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CMD_DIR="$PLUGIN_DIR/commands"
TARGET_DIR="$HOME/.claude/commands"

[ ! -d "$CMD_DIR" ] && exit 0

mkdir -p "$TARGET_DIR"

for cmd_file in "$CMD_DIR/"*.md; do
  [ ! -f "$cmd_file" ] && continue
  fname=$(basename "$cmd_file")
  target="$TARGET_DIR/$fname"
  # Skip if already correctly linked
  [ -L "$target" ] && [ "$(readlink "$target")" = "$cmd_file" ] && continue
  rm -f "$target"
  ln -s "$cmd_file" "$target"
done
