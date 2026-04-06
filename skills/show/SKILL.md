---
name: show
description: 숨긴 펫 다시 표시
---

statusLine에 펫을 다시 표시합니다.

## Implementation

```bash
CONFIG="$HOME/.claude/gitanimals.json"
jq '.hidden = false' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "🐾 Pet visible again!"
```
