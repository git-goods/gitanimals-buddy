---
name: card
description: 현재 펫 상세 정보
---

현재 활성 펫의 상세 정보를 표시합니다.

## Implementation

```bash
CONFIG="$HOME/.claude/gitanimals.json"
CACHE="$HOME/.cache/gitanimals/pet-cache.json"

if [ ! -f "$CONFIG" ]; then
  echo "❌ /gitanimals-buddy:login을 먼저 실행해주세요."
  exit 0
fi

USERNAME=$(jq -r '.username' "$CONFIG")
ACTIVE=$(jq -r '.active_pet // ""' "$CONFIG")

echo "🐾 GitAnimals Buddy"
echo "━━━━━━━━━━━━━━━━━━━"
echo "   User: $USERNAME"

if [ -f "$CACHE" ]; then
  if [ -n "$ACTIVE" ]; then
    PET_INFO=$(jq -r --arg t "$ACTIVE" '[.personas[]? | select(.type == $t)] | .[0] | "   Type: \(.type)\n   Level: \(.level)\n   Grade: \(.grade // "?")"' "$CACHE" 2>/dev/null)
  else
    PET_INFO=$(jq -r '[.personas[]? | select(.type != null)] | sort_by(-(.level | tonumber)) | .[0] | "   Type: \(.type)\n   Level: \(.level)\n   Grade: \(.grade // "?")"' "$CACHE" 2>/dev/null)
  fi
  echo -e "$PET_INFO"
fi

echo "━━━━━━━━━━━━━━━━━━━"

# Show sprite preview
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/sprite-renderer.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/mood.sh"
  source "${CLAUDE_PLUGIN_ROOT}/scripts/bubble.sh"
  PET_TYPE=$(jq -r '.active_pet // ""' "$CONFIG")
  [ -z "$PET_TYPE" ] && PET_TYPE=$(jq -r '[.personas[]? | select(.type != null)] | sort_by(-(.level | tonumber)) | .[0].type // "GOOSE"' "$CACHE" 2>/dev/null)
  PET_LOWER=$(echo "$PET_TYPE" | tr '[:upper:]' '[:lower:]')
  SPRITE="${CLAUDE_PLUGIN_ROOT}/resources/sprites/${PET_LOWER}.sprite"
  [ ! -f "$SPRITE" ] && SPRITE="${CLAUDE_PLUGIN_ROOT}/resources/sprites/fallback.sprite"
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/sprite-renderer.sh" "$SPRITE" 0 happy
fi
```
