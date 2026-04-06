---
name: list
description: 보유 펫 목록 조회
---

GitAnimals에서 보유한 펫 목록을 표시합니다.

## Implementation

```bash
CACHE="$HOME/.cache/gitanimals/pet-cache.json"
if [ ! -f "$CACHE" ]; then
  echo "❌ 캐시된 펫 데이터가 없습니다. /gitanimals-buddy:login을 먼저 실행해주세요."
  exit 0
fi
echo "🐾 Your GitAnimals pets:"
jq -r '[.personas[]? | select(.type != null)] | sort_by(-(.level | tonumber)) | .[] | "   \(.type) Lv.\(.level)"' "$CACHE" 2>/dev/null
```
