# CLAUDE.md

## Project Overview

GitAnimals Buddy — Claude Code용 statusLine 플러그인. GitAnimals 펫을 ASCII 아트로 터미널에 표시.

## Key Rules

- **README.md 동기화 필수**: 기능 추가/변경/삭제 시 반드시 README.md에 반영할 것
  - 새 펫 추가 → 지원 펫 테이블 업데이트
  - 레이아웃 변경 → 미리보기 섹션 업데이트
  - 커맨드 추가 → 사용법 테이블 업데이트
  - 설정 변경 → 설치 섹션 업데이트
- statusline.sh는 300ms 이내에 실행 완료되어야 함 (Claude Code throttle 제한)
- API 호출은 statusline 실행 시 직접 하지 않고 캐시에서 읽기만 할 것
- 모든 스프라이트는 5줄 × 12글자 포맷 유지

## Architecture

```
scripts/statusline.sh    # 메인 진입점 — stdin으로 세션 JSON 받아서 stdout으로 렌더링
scripts/fetch-pet.sh     # SessionStart hook에서 백그라운드 실행
scripts/mood.sh          # usage % → mood 매핑, mood별 표정/대사
scripts/sprite-renderer.sh  # .sprite 파일 파싱 + ANSI 렌더링 엔진
resources/sprites/*.sprite  # 각 펫의 ASCII 아트 데이터 (.sprite 포맷)
commands/animals.md      # /animals 슬래시 커맨드 정의
```

## Development

```bash
# 로컬 테스트
bash scripts/quick-test.sh

# 특정 펫 프리뷰
bash scripts/preview.sh goose 5
bash scripts/preview.sh all

# statusline 직접 테스트 (mock 데이터)
echo '{"model":{"display_name":"Opus 4.6"},"context_window":{"used_percentage":23},"cost":{"total_cost_usd":0.05}}' | bash scripts/statusline.sh
```

## Conventions

- 스크립트는 bash only (Node.js, Python 등 외부 런타임 의존 없음)
- ANSI 색상은 256 color 기본, true color 선택적
- 캐시 파일: `~/.cache/gitanimals/`
- 설정 파일: `~/.claude/gitanimals.json`
