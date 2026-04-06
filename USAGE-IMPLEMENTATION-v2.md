# Usage 모니터링 구현 — v2 (CLI OAuth)

## 배경

### v1의 문제

v1은 claude.ai 웹 세션 키(`sessionKey` 쿠키)를 수동으로 설정해야 했다:
- 브라우저 DevTools에서 쿠키를 복사하는 번거로운 과정
- Cloudflare 챌린지로 인해 curl로 claude.ai API 직접 호출 불가
- 세션 키 만료 시 재설정 필요

### v2 해결

Claude Code CLI가 macOS Keychain에 저장하는 OAuth 토큰을 자동으로 읽어,
`api.anthropic.com`의 Messages API rate limit 헤더에서 정확한 사용률을 가져온다.

**별도 설정 불필요** — Claude Code에 로그인만 되어 있으면 자동 동작.

### 참고

- **[Claude-Usage-Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker)**: macOS 메뉴바 앱. CLI Account Sync 기능에서 OAuth 토큰 읽기 + rate limit 헤더 파싱 방식을 참고.
- **[Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)**: Python 기반 로컬 JSONL 파싱 모니터.

## 인증 흐름

### OAuth 토큰 읽기 (Fallback Chain)

1. **`~/.claude/.credentials.json`** — 파일이 있으면 가장 신뢰도 높음
2. **macOS Keychain** — `Claude Code-credentials` 서비스명으로 조회
3. **Hashed Keychain** — Claude Code v2.1.52+는 `Claude Code-credentials-HASH` 형식
4. **Regex fallback** — Keychain 데이터가 잘린 경우 `accessToken` 정규식 추출

### API 호출

```
POST https://api.anthropic.com/v1/messages

Headers:
  Authorization: Bearer {accessToken}
  Content-Type: application/json
  anthropic-version: 2023-06-01
  anthropic-beta: oauth-2025-04-20
  User-Agent: claude-code/2.1.5

Body:
  {"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}
```

최소 비용의 요청을 보내고, **응답 헤더**에서 사용률을 파싱:

| 헤더 | 설명 | 값 범위 |
|------|------|---------|
| `anthropic-ratelimit-unified-5h-utilization` | 5시간 세션 사용률 | 0.0 ~ 1.0 |
| `anthropic-ratelimit-unified-5h-reset` | 리셋 시각 (Unix timestamp) | epoch |
| `anthropic-ratelimit-unified-7d-utilization` | 7일 주간 사용률 | 0.0 ~ 1.0 |
| `anthropic-ratelimit-unified-7d-reset` | 주간 리셋 시각 | epoch |

## Fallback 전략

우선순위:
1. **OAuth 성공** → rate limit 헤더에서 정확한 utilization (추천)
2. **OAuth 실패** → JSONL 파싱 fallback (추정치)
3. **JSONL도 없음** → Usage 표시 안 함

## 변경 파일

| 파일 | 변경 내용 |
|------|-----------|
| `scripts/fetch-usage.sh` | claude.ai API → CLI OAuth + rate limit 헤더 방식으로 전면 교체 |
| `commands/animals.md` | `/animals setup` 제거 → `/animals usage` (상태 확인) |
| `README.md` | Usage 섹션 — 자동 OAuth 방식 설명, 세션 키 안내 제거 |
