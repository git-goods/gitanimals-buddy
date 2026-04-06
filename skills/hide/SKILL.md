---
name: hide
description: statusLine에서 펫 숨기기
---

statusLine에서 펫을 숨깁니다.

## Implementation

```bash
CONFIG="$HOME/.claude/gitanimals.json"
jq '.hidden = true' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "🐾 Pet hidden from statusLine."
```
