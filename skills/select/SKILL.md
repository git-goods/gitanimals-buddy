---
name: select
description: 활성 펫 변경
---

statusLine에 표시할 펫을 변경합니다.

## Usage
`/gitanimals-buddy:select <pet_type>`

## Implementation

```bash
PET_TYPE="$ARGUMENTS"
if [ -z "$PET_TYPE" ]; then
  echo "❌ 펫 타입을 입력해주세요: /gitanimals-buddy:select <pet_type>"
  echo "   /gitanimals-buddy:list 로 보유 펫을 확인하세요."
  exit 0
fi
CONFIG="$HOME/.claude/gitanimals.json"
jq --arg p "$PET_TYPE" '.active_pet = $p' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "✅ Active pet set to: $PET_TYPE"
```
