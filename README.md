# 🐾 GitAnimals Buddy for Claude Code

GitAnimals의 펫을 Claude Code 터미널 statusLine에서 함께 키우는 companion 플러그인.

## 설치

### 1. 클론

```bash
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy
```

### 2. 스크립트 권한 부여

```bash
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/*.sh
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/sprites/*.sh
```

### 3. Claude Code 설정에 statusLine 추가

`~/.claude/settings.json`에 다음을 추가:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/plugins/gitanimals-buddy/scripts/statusline.sh",
    "padding": 1
  }
}
```

### 4. GitAnimals 유저네임 설정

```bash
mkdir -p ~/.claude
echo '{"username": "YOUR_GITHUB_USERNAME", "hidden": false}' > ~/.claude/gitanimals.json
```

또는 Claude Code 내에서:
```
/animals login YOUR_GITHUB_USERNAME
```

## 사용법

| 커맨드 | 설명 |
|--------|------|
| `/animals` | 현재 활성 펫 표시 |
| `/animals login <username>` | 유저네임 설정 |
| `/animals list` | 보유 펫 목록 |
| `/animals select <pet_type>` | 활성 펫 변경 |
| `/animals hide` | 펫 숨기기 |
| `/animals show` | 펫 다시 표시 |

## 프리뷰

설치 전에 어떻게 보이는지 확인:

```bash
# 모든 펫 미리보기
bash scripts/preview.sh all

# 특정 펫 미리보기
bash scripts/preview.sh goose 5
bash scripts/preview.sh cat 12
```

## 지원 펫 (Phase 1)

| 펫 | ASCII |
|-----|-------|
| Goose | `(o>` |
| Little Chick | `(°v°)` |
| Penguin | `(^^)` |
| Cat | `/\_/\` |
| Capybara | `(*_*)` |

미지원 펫은 generic fallback으로 표시됩니다.

## 레이아웃

**Full 모드** (터미널 폭 ≥ 100):
```
─── Opus 4.6 │ Ctx: ██░░░░░░░░ 23% │ $0.05 ───
                                         (o>
                                         (__)  💬 Nice commit!
                                      /)/) ||
                                      GOOSE Lv.5 ★☆☆☆☆
```

**Compact 모드** (터미널 폭 < 100):
```
─── Opus 4.6 │ Ctx: ██░░░░░░░░ 23% │ $0.05 ───
─── Goose Lv.5 ★☆☆☆☆ │ Let's code! ───
```

## 의존성

- `jq` (JSON 파싱)
- `curl` (API 호출)
- `git` (contribution 감지)
- bash 4.0+

## 구조

```
gitanimals-buddy/
├── .claude-plugin/plugin.json    # 플러그인 메타
├── commands/animals.md           # /animals 커맨드
├── hooks/hooks.json              # SessionStart hook
├── scripts/
│   ├── statusline.sh             # 메인 렌더러
│   ├── fetch-pet.sh              # API fetcher
│   ├── preview.sh                # 프리뷰 도구
│   └── sprites/                  # ASCII 스프라이트
│       ├── goose.sh
│       ├── little_chick.sh
│       ├── penguin.sh
│       ├── cat.sh
│       ├── capybara.sh
│       └── fallback.sh
└── README.md
```

## 라이선스

MIT
