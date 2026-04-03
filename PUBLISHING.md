# GitAnimals Buddy — 마켓플레이스 등록 가이드

## 사전 준비

### 1. GitHub 레포 생성

`git-goods/gitanimals-buddy` 레포를 생성하고 플러그인 파일을 push한다.

```bash
cd gitanimals-buddy
git init
git remote add origin git@github.com:git-goods/gitanimals-buddy.git
git add .
git commit -m "feat: GitAnimals Buddy for Claude Code"
git push -u origin main
```

### 2. 필수 파일 확인

```
gitanimals-buddy/
├── .claude-plugin/
│   ├── plugin.json          # 플러그인 메타데이터
│   └── marketplace.json     # 마켓플레이스 레지스트리
├── commands/animals.md      # /animals 슬래시 커맨드
├── hooks/hooks.json         # SessionStart hook
├── scripts/
│   ├── statusline.sh        # 메인 렌더러
│   ├── fetch-pet.sh         # API fetcher
│   └── sprites/             # ASCII 스프라이트
├── install.sh               # 원스텝 설치 스크립트
└── README.md
```

## 사용자 설치 방법

### 방법 1: 마켓플레이스 (추천)

```bash
# Claude Code 내에서 실행

# 1. 마켓플레이스 등록
/plugin marketplace add git-goods/gitanimals-buddy

# 2. 플러그인 설치
/plugin install gitanimals-buddy
```

### 방법 2: 수동 설치

```bash
# 1. 클론
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy

# 2. 설치 스크립트 실행
bash ~/.claude/plugins/gitanimals-buddy/install.sh
```

### 방법 3: 최소 설치

```bash
# 1. 클론
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy

# 2. 권한 부여
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/*.sh
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/sprites/*.sh

# 3. settings.json에 statusLine 추가
# ~/.claude/settings.json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/gitanimals-buddy/scripts/statusline.sh",
    "padding": 7
  }
}

# 4. 유저네임 설정
echo '{"username": "YOUR_GITHUB_USERNAME", "hidden": false}' > ~/.claude/gitanimals.json
```

## 마켓플레이스 구조

### plugin.json

플러그인 자체의 메타데이터. Claude Code가 플러그인을 인식하는 데 사용.

### marketplace.json

마켓플레이스 레지스트리. `/plugin marketplace add` 시 이 파일을 읽어서 설치 가능한 플러그인 목록을 파악.

주요 필드:
- `name`: 마켓플레이스 식별자
- `plugins[].name`: 플러그인 이름 (`/plugin install <name>`)
- `plugins[].source`: 플러그인 소스 경로 (레포 루트 기준)
- `plugins[].category`: 카테고리
- `plugins[].tags`: 검색 태그

## 버전 업데이트

1. `plugin.json`과 `marketplace.json`의 `version` 동시 업데이트
2. git tag 생성: `git tag v0.2.0 && git push --tags`
3. 사용자는 `/plugin update gitanimals-buddy`로 업데이트
