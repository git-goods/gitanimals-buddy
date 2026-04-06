---
name: usage
description: Usage 모니터링 상태 확인
---

현재 API Usage 모니터링 상태를 표시합니다.

## Implementation

```bash
CACHE="$HOME/.cache/gitanimals/usage-cache.txt"

echo "📊 Usage 모니터링"
echo ""

if [ -f "$CACHE" ]; then
  UTIL=$(grep "^UTILIZATION=" "$CACHE" | cut -d= -f2)
  SOURCE=$(grep "^SOURCE=" "$CACHE" | cut -d= -f2)
  RESETS=$(grep "^RESETS_AT=" "$CACHE" | cut -d= -f2)
  TS=$(grep "^TIMESTAMP=" "$CACHE" | cut -d= -f2)
  AGE=$(( $(date +%s) - TS ))

  echo "   Usage: ${UTIL}%"
  echo "   Source: ${SOURCE}"
  [ -n "$RESETS" ] && echo "   Resets at: ${RESETS}"
  echo "   Cache age: ${AGE}s"
else
  echo "   캐시 없음. 세션 시작 시 자동으로 데이터를 가져옵니다."
fi

echo ""
echo "   데이터 소스 우선순위:"
echo "   1. oauth — Claude Code 로그인 자격증명 자동 사용 (추천)"
echo "   2. jsonl — 로컬 JSONL 로그 파싱 (추정치)"
```
