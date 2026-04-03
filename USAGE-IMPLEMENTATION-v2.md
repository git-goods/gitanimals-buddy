# Usage 모니터링 구현 계획

## 배경

### 문제

현재 `fetch-usage.sh`는 로컬 JSONL 파싱으로 사용량을 계산하지만 부정확하다.

- 우리 계산: **100%** (output tokens 241K / 한도 80K)
- 실제 값: **84%** (claude.ai API 기준)
- 원인: 플랜별 토큰 한도를 추정해야 하고, Claude의 실제 사용량 계산은 단순 토큰 합산이 아님

### 해결 방향

"Claude Usage" macOS 앱의 Swift 스크립트가 검증한 방식 — `claude.ai/api/organizations/{orgId}/usage` API를 직접 호출하여 정확한 utilization %와 reset 시간을 가져온다. 이를 bash + curl로 포팅.

### 참고 자료

- **Claude-Code-Usage-Monitor** ([GitHub](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)): Python 기반 로컬 JSONL 파싱 모니터. 동일한 정확도 문제가 있어 P90 추정치 사용.
- **Claude Usage macOS 앱**: Swift로 claude.ai API 직접 호출. `~/.claude/fetch-claude-usage.swift` 에서 로직 확인됨.

## API 분석

### 엔드포인트

```
GET https://claude.ai/api/organizations/{orgId}/usage
```

### 인증

```
Cookie: sessionKey={session_key}
```

### 응답 구조

```json
{
  "five_hour": {
    "utilization": 84,
    "resets_at": "2026-04-03T10:00:00Z"
  }
}
```

### Organization ID 자동 탐지

```
GET https://claude.ai/api/organizations
Cookie: sessionKey={session_key}

→ [{"uuid": "9c6b6c9f-...", "name": "...", ...}]
→ 첫 번째 org의 uuid 사용
```

## 구현 계획

### 수정 대상 파일

| 파일 | 변경 내용 |
|------|-----------|
| `scripts/fetch-usage.sh` | claude.ai API 호출 방식으로 전면 교체 |
| `commands/animals.md` | `/animals setup` 커맨드 추가 (세션 키 설정) |
| `README.md` | Usage 설정 섹션 추가 |
| `CLAUDE.md` | 변경 반영 |

### Task 1: fetch-usage.sh 교체

기존 JSONL 파싱 → claude.ai API 호출 (bash + curl)

```bash
#!/bin/bash
# 핵심 로직

CONFIG_FILE="$HOME/.claude/gitanimals.json"
SESSION_KEY=$(jq -r '.claude_session_key // empty' "$CONFIG_FILE")
ORG_ID=$(jq -r '.claude_org_id // empty' "$CONFIG_FILE")

# API 호출
RESPONSE=$(curl -s --max-time 5 \
  "https://claude.ai/api/organizations/${ORG_ID}/usage" \
  -H "Cookie: sessionKey=${SESSION_KEY}" \
  -H "Accept: application/json")

# 파싱
UTILIZATION=$(echo "$RESPONSE" | jq -r '.five_hour.utilization // 0')
RESETS_AT=$(echo "$RESPONSE" | jq -r '.five_hour.resets_at // empty')

# 캐시에 쓰기
cat > "$USAGE_CACHE" <<EOF
UTILIZATION=$UTILIZATION
RESETS_AT=$RESETS_AT
TIMESTAMP=$(date +%s)
EOF
```

설정값:
- `claude_session_key`: claude.ai 브라우저 쿠키의 `sessionKey` 값
- `claude_org_id`: organization UUID (자동 탐지 가능)

캐시:
- 파일: `~/.cache/gitanimals/usage-cache.txt`
- TTL: 60초 (API는 가벼우므로 자주 갱신)
- 형식: 기존과 동일 (UTILIZATION, RESETS_AT, TIMESTAMP)

### Task 2: `/animals setup` 커맨드

세션 키 설정을 안내하는 커맨드. `commands/animals.md`에 추가.

```
/animals setup <session_key>
```

동작:
1. 세션 키를 `~/.claude/gitanimals.json`에 저장
2. Organization ID 자동 탐지 (`/api/organizations` 호출)
3. 결과를 config에 저장
4. 즉시 사용량 fetch 실행하여 동작 확인

세션 키 얻는 방법 안내:
1. 브라우저에서 https://claude.ai 접속 (로그인 상태)
2. DevTools (F12) → Application → Cookies → claude.ai
3. `sessionKey` 값 복사

### Task 3: statusline.sh 수정

변경 최소:
- usage 캐시 파일 경로/형식이 동일하므로 읽기 로직 변경 없음
- 캐시 만료 시 백그라운드 fetch-usage.sh 호출 (이미 구현됨)

### Task 4: README + CLAUDE.md 업데이트

README에 Usage 설정 섹션 추가:
- 세션 키 설정 방법
- `/animals setup` 사용법
- 세션 키 없이도 동작한다는 안내 (JSONL fallback)

CLAUDE.md:
- README 동기화 필수 규칙에 Usage 관련 항목 추가

## Fallback 전략

우선순위:
1. **세션 키 있음 + API 성공** → 정확한 utilization 사용 (추천)
2. **세션 키 있음 + API 실패** → 캐시된 이전 값 사용
3. **세션 키 없음** → JSONL 파싱 fallback (부정확하지만 없는 것보다 나음)
4. **JSONL도 없음** → Usage 표시 안 함

JSONL fallback 시 Claude-Code-Usage-Monitor 방식 참고:
- 플랜별 한도: pro=19K, max5=88K, max20=220K output tokens
- 5시간 세션 블록 기준
- 기본값: 19K (Pro 플랜)

## 검증 계획

1. `bash scripts/fetch-usage.sh` 실행 → `~/.cache/gitanimals/usage-cache.txt` 값 확인
2. 기존 Swift 캐시(`~/.claude/.statusline-usage-cache`)와 비교하여 값 일치 확인
3. statusline 렌더링 테스트 (mock + 실제 데이터)
4. 세션 키 없을 때 JSONL fallback 동작 확인
5. API 타임아웃 시 기존 캐시 사용 확인

## 보안 고려사항

- 세션 키는 `~/.claude/gitanimals.json`에 로컬 저장 (git에 커밋되지 않음)
- API 호출은 claude.ai만 대상 (외부 서버로 키 전송 없음)
- 세션 키 만료 시 자동 감지 (HTTP 401) → 사용자에게 재설정 안내
