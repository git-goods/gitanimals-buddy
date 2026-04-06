# Claude Code 플러그인 배포 가이드

> gitanimals-buddy 배포를 위해 조사한 Claude Code 플러그인 시스템 정리

## 플러그인 디렉토리 구조

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json           # 필수: 플러그인 메타데이터
├── skills/                   # 슬래시 커맨드 (자동 등록)
│   └── my-skill/
│       └── SKILL.md
├── commands/                 # 레거시 커맨드 (자동 등록)
├── agents/                   # 커스텀 에이전트
├── hooks/                    # 이벤트 훅 (자동 등록)
│   └── hooks.json
├── bin/                      # $PATH에 추가되는 실행 파일
├── .mcp.json                 # MCP 서버 설정
├── .lsp.json                 # LSP 서버 설정
├── settings.json             # 기본 설정 (agent 키만 지원)
└── README.md
```

**주의**: `plugin.json`만 `.claude-plugin/` 안에 위치. 나머지는 모두 플러그인 루트에.

## plugin.json 스키마

```json
{
  "name": "gitanimals-buddy",
  "version": "0.2.0",
  "description": "GitAnimals pet companion for Claude Code",
  "author": {
    "name": "git-goods",
    "email": "optional@example.com"
  },
  "homepage": "https://github.com/git-goods/gitanimals-buddy",
  "repository": "https://github.com/git-goods/gitanimals-buddy",
  "license": "MIT",
  "keywords": ["pet", "statusline", "ascii-art"],

  // 컴포넌트 경로 (기본값 대체)
  "commands": ["./commands/animals.md"],
  "hooks": "./hooks/hooks.json",

  // 설치 시 사용자 입력 받기
  "userConfig": {
    "github_username": {
      "description": "GitAnimals GitHub 유저네임",
      "sensitive": false
    }
  }
}
```

### 환경 변수

- `${CLAUDE_PLUGIN_ROOT}` — 플러그인 디렉토리 절대 경로 (업데이트 시 변경됨)
- `${CLAUDE_PLUGIN_DATA}` — 영구 데이터 디렉토리 (`~/.claude/plugins/data/{id}/`)

## 마켓플레이스 구조

### marketplace.json

```json
{
  "name": "gitanimals-buddy",
  "owner": {
    "name": "git-goods"
  },
  "metadata": {
    "description": "GitAnimals plugins"
  },
  "plugins": [
    {
      "name": "gitanimals-buddy",
      "source": "./",
      "description": "ASCII art statusline plugin",
      "version": "0.2.0"
    }
  ]
}
```

### source 타입

| 타입 | 형식 | 설명 |
|------|------|------|
| 상대 경로 | `"./path"` | 같은 레포 내 (git 기반만) |
| GitHub | `{ "source": "github", "repo": "owner/repo", "ref": "v1.0" }` | 브랜치/태그 지정 가능 |
| Git URL | `{ "source": "url", "url": "https://..." }` | GitLab 등 지원 |
| Git 서브디렉토리 | `{ "source": "git-subdir", "url": "...", "path": "subdir" }` | 모노레포용 |
| npm | `{ "source": "npm", "package": "@org/plugin" }` | npm 패키지 |

## 사용자 설치 흐름

```bash
# 1. 마켓플레이스 추가 (GitHub shorthand)
/plugin marketplace add git-goods/gitanimals-buddy

# 2. 플러그인 설치
/plugin install gitanimals-buddy@gitanimals-buddy

# 또는 /plugin UI의 Discover 탭에서 탐색 후 클릭 설치
```

### 설치 시 내부 동작

1. 마켓플레이스 레포를 클론/fetch
2. `.claude-plugin/marketplace.json` 파싱
3. `~/.claude/plugins/known_marketplaces.json`에 등록
4. `/plugin install` 시 source에서 플러그인 다운로드
5. `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`에 복사
6. `settings.json`의 `enabledPlugins`에 추가

### 설치 스코프

| 스코프 | 파일 | 공유 |
|--------|------|------|
| `user` (기본) | `~/.claude/settings.json` | 개인용 |
| `project` | `.claude/settings.json` | 팀 공유 (git) |
| `local` | `.claude/settings.local.json` | 프로젝트 전용 (gitignore) |

## statusLine 플러그인

**플러그인이 직접 statusLine을 선언하는 메커니즘은 없음.** 사용자가 설치 후 수동으로 설정하거나, install.sh가 자동 설정.

```json
// ~/.claude/settings.json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/cache/.../scripts/statusline.sh",
    "padding": 7
  }
}
```

statusline.sh가 stdin으로 받는 JSON:

```json
{
  "model": { "id": "claude-opus-4-6", "display_name": "Opus" },
  "context_window": { "used_percentage": 25 },
  "cost": { "total_cost_usd": 0.05 },
  "workspace": { "current_dir": "/path" },
  "session_id": "abc123"
}
```

## Hooks 자동 등록

`hooks/hooks.json`은 플러그인 설치 시 자동 등록됨.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-pet.sh"
          }
        ]
      }
    ]
  }
}
```

## 업데이트

```bash
/plugin update gitanimals-buddy@gitanimals-buddy
```

- 공식 마켓플레이스: 자동 업데이트 기본 활성화
- 서드파티 마켓플레이스: 자동 업데이트 기본 비활성화
- **버전 번호를 올려야** 업데이트가 감지됨

## 로컬 개발 vs 마켓 플러그인 전환

### 로컬 개발 모드

코드를 수정하면서 바로 테스트할 때 사용. 마켓에서 설치된 버전 대신 **로컬 코드가 우선** 적용됨.

```bash
# 로컬 플러그인 디렉토리를 지정하여 Claude Code 실행
claude --plugin-dir /path/to/gitanimals-buddy

# 코드 수정 후 리로드 (재시작 없이 반영)
/reload-plugins
```

### 마켓 플러그인 업데이트 테스트

main에 push한 뒤, 마켓에서 설치된 플러그인을 최신으로 업데이트.

```bash
# 1. 마켓플레이스 메타데이터 갱신
/plugin marketplace update gitanimals-buddy

# 2. 플러그인 업데이트 (새 버전이 있을 때)
/plugin update gitanimals-buddy@gitanimals-buddy

# 3. 리로드
/reload-plugins
```

### 전환 방법

| 상황 | 방법 |
|------|------|
| 로컬 코드 테스트 | `claude --plugin-dir ./` 로 실행 |
| 마켓 버전 테스트 | 일반 `claude` 로 실행 (캐시된 마켓 버전 사용) |
| 마켓 → 로컬 전환 | `/plugin disable gitanimals-buddy@gitanimals-buddy` 후 `--plugin-dir` 사용 |
| 로컬 → 마켓 복귀 | `--plugin-dir` 없이 실행 + `/plugin enable gitanimals-buddy@gitanimals-buddy` |

> **주의**: `--plugin-dir`로 실행하면 같은 이름의 마켓 플러그인보다 로컬이 우선됨. 마켓 버전을 테스트하려면 `--plugin-dir` 없이 실행해야 함.

## 공식 마켓플레이스 제출

두 곳에서 제출 가능:
- https://claude.ai/settings/plugins/submit
- https://platform.claude.com/plugins/submit

### 제출 체크리스트

- [ ] `.claude-plugin/plugin.json` 필수 필드 (name, description, version)
- [ ] README.md 문서화
- [ ] 시맨틱 버저닝 (1.0.0부터)
- [ ] 라이선스 명시
- [ ] homepage/repository URL
- [ ] 하드코딩된 자격증명 없음
- [ ] 훅에서 `${CLAUDE_PLUGIN_ROOT}` 사용
- [ ] 스크립트 실행 권한 (chmod +x)

## gitanimals-buddy 배포 TODO

- [x] `.claude-plugin/plugin.json` 존재
- [x] `.claude-plugin/marketplace.json` 존재
- [x] hooks/hooks.json에서 `${CLAUDE_PLUGIN_ROOT}` 경로 사용
- [x] install.sh에서 스크립트 위치 기반 경로 대응
- [x] 개별 skill 커맨드 분리 (`/gitanimals-buddy:<name>`)
