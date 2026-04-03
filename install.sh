#!/bin/bash
# GitAnimals Buddy — One-step installer for Claude Code
set -euo pipefail

PLUGIN_DIR="$HOME/.claude/plugins/gitanimals-buddy"
CONFIG_FILE="$HOME/.claude/gitanimals.json"
SETTINGS_FILE="$HOME/.claude/settings.json"
STATUSLINE_CMD="bash $PLUGIN_DIR/scripts/statusline.sh"

echo ""
echo "  GitAnimals Buddy Installer"
echo "  =========================="
echo ""

# Step 1: Check dependencies
echo "[1/4] Checking dependencies..."
for cmd in jq curl git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "  ERROR: '$cmd' is required but not installed."
    exit 1
  fi
done
echo "  OK"

# Step 2: Set permissions
echo "[2/4] Setting script permissions..."
chmod +x "$PLUGIN_DIR/scripts/"*.sh
chmod +x "$PLUGIN_DIR/scripts/sprites/"*.sh
echo "  OK"

# Step 3: Configure username
echo "[3/4] Configuring GitAnimals account..."
if [ -f "$CONFIG_FILE" ]; then
  existing=$(jq -r '.username // ""' "$CONFIG_FILE" 2>/dev/null)
  if [ -n "$existing" ]; then
    echo "  Already configured: $existing"
  fi
else
  # Try git username as default
  git_user=$(git config --global user.name 2>/dev/null || echo "")
  if [ -n "$git_user" ]; then
    read -rp "  GitHub username [$git_user]: " input_user
    username="${input_user:-$git_user}"
  else
    read -rp "  GitHub username: " username
  fi
  mkdir -p "$HOME/.claude"
  echo "{\"username\": \"$username\", \"hidden\": false}" > "$CONFIG_FILE"
  echo "  Saved: $username"
fi

# Step 4: Update settings.json
echo "[4/4] Updating Claude Code settings..."
if [ -f "$SETTINGS_FILE" ]; then
  # Check if statusLine already points to our script
  current=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null)
  if [[ "$current" == *"gitanimals-buddy"* ]]; then
    echo "  Already configured!"
  else
    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
    echo "  Backed up: $SETTINGS_FILE.bak"

    # Update statusLine
    jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {"type": "command", "command": $cmd, "padding": 7}' \
      "$SETTINGS_FILE" > /tmp/ga-settings.json && mv /tmp/ga-settings.json "$SETTINGS_FILE"
    echo "  statusLine updated!"
  fi
else
  mkdir -p "$HOME/.claude"
  cat > "$SETTINGS_FILE" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "$STATUSLINE_CMD",
    "padding": 7
  }
}
EOF
  echo "  Created settings.json"
fi

# Prefetch pet data
echo ""
echo "  Fetching pet data..."
bash "$PLUGIN_DIR/scripts/fetch-pet.sh" 2>/dev/null || echo "  (fetch skipped — will retry on session start)"

echo ""
echo "  Installation complete!"
echo "  Restart Claude Code to see your pet."
echo ""
