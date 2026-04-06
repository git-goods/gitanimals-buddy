# Contributing to GitAnimals Buddy

GitAnimals Buddy에 기여해주셔서 감사합니다! 모든 기여를 환영합니다.

> [English version below](#contributing-english)

## 시작하기

### 1. Fork & Clone

```bash
# 1. GitHub에서 fork
# 2. fork한 레포 클론
git clone https://github.com/<your-username>/gitanimals-buddy.git
cd gitanimals-buddy

# 3. upstream 등록
git remote add upstream https://github.com/git-goods/gitanimals-buddy.git
```

### 2. 로컬 개발 환경

```bash
# Claude Code에서 로컬 플러그인으로 실행
claude --plugin-dir ./

# 코드 수정 후 리로드 (재시작 없이 반영)
/reload-plugins
```

### 3. 테스트

```bash
bash tests/test-mood.sh           # mood 시스템 테스트
bash tests/test-bubble.sh         # 대사 엔진 테스트
bash tests/test-sprite-renderer.sh # 스프라이트 렌더러 테스트
bash scripts/quick-test.sh         # 통합 테스트
```

## 기여 방법

### PR 프로세스

1. `main`에서 feature 브랜치 생성
2. 작업 후 fork에 push
3. `git-goods/gitanimals-buddy`의 `main`으로 PR 생성
4. 리뷰 후 머지

### 커밋 컨벤션

[Conventional Commits](https://www.conventionalcommits.org/) + 한글 허용

```
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 변경
refactor: 리팩토링
test: 테스트 추가/수정
```

예시:
```
feat: hamster 스프라이트 추가
fix: compact 모드에서 토끼 표정 깨지는 문제 수정
docs: README에 새 펫 추가
```

### 테스트

테스트 통과를 권장합니다. 리소스(스프라이트/대사)만 추가하는 경우 테스트 면제 가능.

## 기여할 수 있는 것들

### 새 펫 스프라이트 추가

가장 쉬운 기여! `resources/sprites/` 에 `.sprite` 파일을 추가하세요.

1. 기존 `.sprite` 파일을 참고 (예: `resources/sprites/rabbit.sprite`)
2. 새 파일 생성: `resources/sprites/<pet_name>.sprite`
3. mood별 compact face 추가: `scripts/mood.sh`의 `get_mood_compact_face`에 case 추가

`.sprite` 포맷:
```ini
# 색상 정의
body_color=97          # ANSI 코드
eye_color=38;5;217     # 256 color
c1=35                  # 추가 색상 → 프레임에서 {1}로 참조

# mood별 눈 (좌우 동일이면 1개, 다르면 "L R" 공백 구분)
eyes_happy=★
eyes_normal=•
eyes_worried=;
eyes_panic=X

# 프레임 (5줄)
# {L},{R}=눈, {1}=추가색, {/}=body_color 복귀
[frame:0]
 (\/) (\/)
 ( {L}.{R} )
 / > {1}<3{/}
(__\_\_)
 .

[frame:1]
 (\/) (\/)
 ( {L}.{R} )
 / >  <\
(__\_\_)
 .
```

프리뷰로 확인:
```bash
bash scripts/sprite-renderer.sh resources/sprites/<pet_name>.sprite 0 happy
bash scripts/sprite-renderer.sh resources/sprites/<pet_name>.sprite 0 panic
```

### 대사 추가

`resources/bubbles/ko.txt`에 새 대사를 추가하세요.

```
태그 | 대사 내용
```

태그 종류:
- `mood:happy`, `mood:normal`, `mood:worried`, `mood:panic`
- `time:morning`, `time:afternoon`, `time:evening`, `time:dawn`
- `habit:long_session`, `habit:weekend`
- `event:ctx_half`, `event:ctx_high`, `event:cost_1usd`

### 버그 수정 & 기능 개발

모든 영역에 기여 가능합니다. 큰 기능은 이슈로 먼저 논의해주세요.

## 프로젝트 구조

```
scripts/
├── statusline.sh        # 메인 렌더러 (stdin JSON → stdout ANSI)
├── mood.sh              # usage % → mood 매핑 + compact face
├── bubble.sh            # 컨텍스트 인식 대사 엔진
├── sprite-renderer.sh   # .sprite 파싱 + ANSI 렌더링
├── fetch-pet.sh         # GitAnimals API fetcher (SessionStart hook)
├── fetch-usage.sh       # Usage 모니터링
├── preview.sh           # 인터랙티브 스프라이트 프리뷰
└── quick-test.sh        # 통합 테스트

resources/
├── sprites/*.sprite     # 펫 ASCII 아트 데이터
└── bubbles/ko.txt       # 한글 대사 데이터

skills/                  # /gitanimals-buddy:<name> 커맨드
tests/                   # 테스트 스크립트
```

## 제약사항

- **Bash only** — Node.js, Python 등 외부 런타임 의존 없음
- **300ms 이내** — statusline.sh 실행 시간 제한 (Claude Code throttle)
- **5줄 × 12글자** — 스프라이트 포맷
- **ANSI 256 color** — true color 선택적

---

# Contributing (English)

Thank you for your interest in GitAnimals Buddy! All contributions are welcome.

## Getting Started

### 1. Fork & Clone

```bash
git clone https://github.com/<your-username>/gitanimals-buddy.git
cd gitanimals-buddy
git remote add upstream https://github.com/git-goods/gitanimals-buddy.git
```

### 2. Local Development

```bash
# Run Claude Code with local plugin
claude --plugin-dir ./

# Reload after changes (no restart needed)
/reload-plugins
```

### 3. Tests

```bash
bash tests/test-mood.sh            # Mood system
bash tests/test-bubble.sh          # Dialogue engine
bash tests/test-sprite-renderer.sh # Sprite renderer
bash scripts/quick-test.sh          # Integration test
```

## How to Contribute

### PR Process

1. Create a feature branch from `main`
2. Push to your fork
3. Open a PR to `git-goods/gitanimals-buddy` `main`
4. Review & merge

### Commit Convention

[Conventional Commits](https://www.conventionalcommits.org/) — Korean and English both OK.

```
feat: add hamster sprite
fix: fix rabbit face in compact mode
docs: update README with new pet
```

### Tests

Passing tests is recommended. Resource-only PRs (sprites/dialogues) are exempt.

## What You Can Contribute

### Add a New Pet Sprite

The easiest contribution! Add a `.sprite` file to `resources/sprites/`.

1. Reference an existing file (e.g., `resources/sprites/rabbit.sprite`)
2. Create: `resources/sprites/<pet_name>.sprite`
3. Add compact face in `scripts/mood.sh` → `get_mood_compact_face`

`.sprite` format:
```ini
body_color=97
eye_color=38;5;217
c1=35

eyes_happy=★
eyes_normal=•
eyes_worried=;
eyes_panic=X

[frame:0]
 (\/) (\/)
 ( {L}.{R} )
 / > {1}<3{/}
(__\_\_)
 .

[frame:1]
 (\/) (\/)
 ( {L}.{R} )
 / >  <\
(__\_\_)
 .
```

Preview:
```bash
bash scripts/sprite-renderer.sh resources/sprites/<pet_name>.sprite 0 happy
bash scripts/sprite-renderer.sh resources/sprites/<pet_name>.sprite 0 panic
```

### Add Dialogues

Add lines to `resources/bubbles/ko.txt`:

```
tag | dialogue text
```

Tags: `mood:happy`, `mood:panic`, `time:morning`, `time:dawn`, `habit:long_session`, `habit:weekend`, `event:ctx_half`, `event:ctx_high`, `event:cost_1usd`

### Bug Fixes & Features

All areas are open. For large features, please open an issue first to discuss.

## Constraints

- **Bash only** — No Node.js, Python, or other runtimes
- **< 300ms** — statusline.sh must complete within 300ms
- **5 lines × 12 chars** — Sprite format
- **ANSI 256 color** — True color optional
