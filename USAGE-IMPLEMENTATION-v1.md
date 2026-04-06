# Usage 모니터링 자체 내장 구현 방식

## 개요

외부 의존성 없이 Claude Code가 자동 생성하는 로컬 JSONL 로그 파일을 파싱하여 세션 사용량을 표시한다.

참고: [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) 가 동일한 방식으로 로컬 JSONL을 파싱한다.

## 데이터 소스

```
~/.claude/projects/**/*.jsonl
```

Claude Code가 세션마다 자동으로 JSONL 파일을 생성한다. 각 줄은 JSON 객체이며, assistant 메시지에 `usage` 필드가 포함된다.

### JSONL 레코드 구조 (assistant 메시지)

```json
{
  "timestamp": "2026-04-03T06:30:00.000Z",
  "sessionId": "uuid",
  "message": {
    "model": "claude-opus-4-6",
    "role": "assistant",
    "usage": {
      "input_tokens": 3,
      "output_tokens": 981,
      "cache_creation_input_tokens": 18617,
      "cache_read_input_tokens": 9753
    }
  }
}
```

## 필요한 정보와 추출 방법

| 정보 | 출처 | 추출 방법 |
|------|------|-----------|
| **모델명** | statusline stdin JSON | `jq '.model.display_name'` (이미 구현됨) |
| **Context 사용량** | statusline stdin JSON | `jq '.context_window.used_percentage'` (이미 구현됨) |
| **세션 사용량 (%)** | 로컬 JSONL | 최근 5시간 토큰 합산 / 플랜 한도 |
| **리셋 시간** | 로컬 JSONL | 가장 오래된 5시간 블록 시작 + 5시간 |

## 구현 아키텍처

### 1. fetch-usage.sh — 백그라운드 사용량 계산 스크립트

SessionStart hook에서 실행. 캐시 파일에 결과를 쓴다.

```bash
#!/bin/bash
# scripts/fetch-usage.sh — JSONL 기반 세션 사용량 계산
CACHE_DIR="$HOME/.cache/gitanimals"
USAGE_CACHE="$CACHE_DIR/usage-cache.txt"
PROJECTS_DIR="$HOME/.claude/projects"

# 플랜별 토큰 한도 (5시간 기준)
# Pro: ~44K output tokens, Max5: ~88K, Max20: ~220K
# 실제로는 input+output+cache 합산 기준이 아닌 output 기준이지만
# 정확한 한도는 공개되지 않으므로 output 토큰 기준으로 추정
TOKEN_LIMIT=${GITANIMALS_TOKEN_LIMIT:-80000}  # 기본: output 기준 80K

NOW=$(date +%s)
FIVE_HOURS_AGO=$(( NOW - 18000 ))
CUTOFF=$(date -u -r $FIVE_HOURS_AGO +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)

# 최근 5시간 JSONL에서 output_tokens 합산
TOTAL_OUTPUT=$(
  find "$PROJECTS_DIR" -name "*.jsonl" -maxdepth 3 2>/dev/null | while read f; do
    jq -r --arg cutoff "$CUTOFF" '
      select(.message.usage.output_tokens != null and .timestamp > $cutoff)
      | .message.usage.output_tokens
    ' "$f" 2>/dev/null
  done | awk '{s+=$1} END {print s+0}'
)

# 사용률 계산
UTILIZATION=$(( TOTAL_OUTPUT * 100 / TOKEN_LIMIT ))
[ "$UTILIZATION" -gt 100 ] && UTILIZATION=100

# 리셋 시간 추정: 가장 오래된 5시간 내 메시지 + 5시간
OLDEST_TS=$(
  find "$PROJECTS_DIR" -name "*.jsonl" -maxdepth 3 2>/dev/null | while read f; do
    jq -r --arg cutoff "$CUTOFF" '
      select(.message.usage != null and .timestamp > $cutoff)
      | .timestamp
    ' "$f" 2>/dev/null
  done | sort | head -1
)

RESETS_AT=""
if [ -n "$OLDEST_TS" ]; then
  # ISO timestamp → epoch → +5h → ISO
  OLDEST_EPOCH=$(date -jf "%Y-%m-%dT%H:%M:%S" "${OLDEST_TS%%.*}" +%s 2>/dev/null)
  if [ -n "$OLDEST_EPOCH" ]; then
    RESET_EPOCH=$(( OLDEST_EPOCH + 18000 ))
    RESETS_AT=$(date -u -r "$RESET_EPOCH" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)
  fi
fi

# 캐시에 쓰기
mkdir -p "$CACHE_DIR"
cat > "$USAGE_CACHE" <<EOF
UTILIZATION=$UTILIZATION
OUTPUT_TOKENS=$TOTAL_OUTPUT
RESETS_AT=$RESETS_AT
TIMESTAMP=$(date +%s)
EOF
```

### 2. statusline.sh — 캐시에서 읽기

statusline 실행 시에는 캐시 파일만 읽는다 (300ms 제한 준수).

```bash
# statusline.sh 내 usage 읽기 부분
USAGE_CACHE="$HOME/.cache/gitanimals/usage-cache.txt"
usage_text=""
if [ -f "$USAGE_CACHE" ]; then
  cache_ts=$(grep "^TIMESTAMP=" "$USAGE_CACHE" | cut -d= -f2)
  now_ts=$(date +%s)
  # 캐시가 5분 이내면 사용
  if [ -n "$cache_ts" ] && [ $(( now_ts - cache_ts )) -lt 300 ]; then
    util=$(grep "^UTILIZATION=" "$USAGE_CACHE" | cut -d= -f2)
    resets=$(grep "^RESETS_AT=" "$USAGE_CACHE" | cut -d= -f2)
    # ... 렌더링
  fi
fi
```

### 3. hooks.json — SessionStart에서 fetch

```json
{
  "hooks": [
    {
      "event": "SessionStart",
      "command": "bash ./scripts/fetch-pet.sh && bash ./scripts/fetch-usage.sh",
      "description": "Fetch pet data and usage on session start"
    }
  ]
}
```

### 4. 주기적 갱신

statusline.sh에서 캐시가 만료(5분)되면 백그라운드로 fetch-usage.sh를 재실행:

```bash
if [ "$cache_age" -ge 300 ]; then
  bash "$SCRIPT_DIR/fetch-usage.sh" &
fi
```

## 장점

- **외부 의존성 제로**: bash + jq만 사용 (이미 필수 의존성)
- **API 호출 없음**: 로컬 파일만 읽음, 세션 키/쿠키 불필요
- **Claude Code 자동 생성**: 사용자 설정 없이 즉시 동작
- **성능**: statusline에서는 캐시만 읽음 (< 1ms)
- **프라이버시**: 외부로 데이터가 나가지 않음

## 한계

- **토큰 한도 추정**: Claude 플랜별 정확한 한도가 공개되지 않아 추정치 사용
- **리셋 시간 추정**: 5시간 rolling window 기반 추정
- **JSONL 구조 변경 가능성**: Claude Code 업데이트 시 호환성 깨질 수 있음
- **대량 파일**: 프로젝트가 많으면 전체 스캔에 시간이 걸릴 수 있음 (→ find depth 제한으로 완화)

## 참고

- [Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor): Python 기반 풀 TUI 모니터, 동일한 JSONL 파싱 방식
- Claude Code 로컬 로그 경로: `~/.claude/projects/{project-path-encoded}/{session-uuid}.jsonl`
- 5시간 세션 블록: Claude Pro/Max 플랜의 usage 리셋 주기
