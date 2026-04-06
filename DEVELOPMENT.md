# 개발 가이드

GitAnimals Buddy 개발 및 릴리즈 사용을 위한 세팅 가이드입니다.

## 사전 요구사항

- bash 4.0+
- `jq`, `curl`, `git`
- Claude Code 설치 완료

## 릴리즈 버전 사용 (일반 사용자)

GitHub에서 플러그인을 설치하여 사용합니다.

```bash
# 1. 플러그인 설치
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy

# 2. 설치 스크립트 실행 (권한 설정, 유저네임 입력, settings.json 자동 구성)
bash ~/.claude/plugins/gitanimals-buddy/install.sh
```

설치가 완료되면 Claude Code를 재시작합니다.

### 설치 후 구조

```
~/.claude/
├── settings.json              # statusLine 설정 (자동 추가됨)
├── gitanimals.json            # 유저 설정 (username, active_pet 등)
└── plugins/
    └── gitanimals-buddy/      # 설치된 플러그인

~/.cache/gitanimals/
├── pet-cache.json             # API 응답 캐시
└── usage-cache.txt            # 사용량 캐시
```

## 개발 모드 세팅 (개발자)

로컬 레포의 코드 변경이 즉시 statusline에 반영되도록 합니다.

### 초기 세팅

```bash
# 1. 레포 클론 (원하는 위치에)
git clone https://github.com/git-goods/gitanimals-buddy.git <원하는 경로>
cd <원하는 경로>

# 2. 개발 모드로 전환 (플러그인 디렉토리를 레포로 심볼릭 링크)
bash scripts/toggle-dev.sh

# 3. 설치 스크립트 실행 (최초 1회 — settings.json, 유저네임 설정)
bash ~/.claude/plugins/gitanimals-buddy/install.sh
```

### 동작 원리

`~/.claude/settings.json`의 statusLine은 항상 플러그인 경로를 가리킵니다:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/gitanimals-buddy/scripts/statusline.sh",
    "padding": 7
  }
}
```

개발 모드에서는 이 경로가 로컬 레포로의 심볼릭 링크이므로, 레포 코드 수정이 곧바로 반영됩니다.

### 개발 모드 ↔ 릴리즈 모드 전환

레포 디렉토리에서 토글 스크립트를 실행합니다:

```bash
bash scripts/toggle-dev.sh
```

실행할 때마다 모드가 토글됩니다.

| 모드 | `~/.claude/plugins/gitanimals-buddy` | 특징 |
|------|--------------------------------------|------|
| **DEV** | 심볼릭 링크 → 로컬 레포 | 코드 수정 즉시 반영 |
| **RELEASE** | GitHub에서 clone한 독립 복사본 | 안정 버전 사용 |

현재 모드 확인:

```bash
ls -la ~/.claude/plugins/gitanimals-buddy
# 심볼릭 링크(→)면 DEV, 일반 디렉토리면 RELEASE
```

### 로컬 테스트

```bash
# 전체 테스트
bash scripts/quick-test.sh

# 특정 펫 프리뷰
bash scripts/preview.sh goose 5
bash scripts/preview.sh all

# statusline 직접 테스트 (mock 데이터)
echo '{"model":{"display_name":"Opus 4.6"},"context_window":{"used_percentage":23}}' \
  | bash scripts/statusline.sh
```
