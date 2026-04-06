# GitAnimals Buddy for Claude Code

> GitAnimals의 펫을 Claude Code 터미널에서 함께 키우는 companion 플러그인

GitHub 활동으로 키운 펫이 코딩 세션을 함께합니다. ASCII 아트로 렌더링되고, 말풍선으로 반응하며, 터미널 크기에 맞게 자동 적응합니다.

## 미리보기

**Full 모드** (터미널 높이 ≥ 15, 너비 ≥ 50):
```
   (\/) (\/)    my-project │ ⎇ main
   ( ^.^ )  💬 Ship it!
   / >  <\     Opus 4.6 │ Ctx: 23%
  (__\_\_)     Usage: 40% ▓▓▓▓░░░░░░
 RABBIT Lv.106 ★★★★★
```

**Compact 모드** (작은 터미널):
```
my-project │ ⎇ main │ Opus 4.6 │ Ctx: 23%
(°..°) RABBIT Lv.106 ★★★★★ │ Ship it!
```

**Micro 모드** (터미널 매우 작을 때):
```
(°..°) Opus 4.6 C:23% U:10%
```

## 설치

### 방법 1: 마켓플레이스 (추천)

Claude Code 내에서:
```
/plugin marketplace add git-goods/gitanimals-buddy
/plugin install gitanimals-buddy
```

### 방법 2: 원스텝 설치

```bash
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy
bash ~/.claude/plugins/gitanimals-buddy/install.sh
```

### 방법 3: 수동 설치

```bash
# 1. 클론
git clone https://github.com/git-goods/gitanimals-buddy.git ~/.claude/plugins/gitanimals-buddy

# 2. 권한 부여
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/*.sh
chmod +x ~/.claude/plugins/gitanimals-buddy/scripts/sprite-renderer.sh

# 3. ~/.claude/settings.json에 statusLine 추가
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

## 사용법

| 커맨드 | 설명 |
|--------|------|
| `/animals` | 현재 활성 펫 표시 |
| `/animals login <username>` | GitAnimals 유저네임 설정 |
| `/animals list` | 보유 펫 목록 조회 |
| `/animals select <pet_type>` | 활성 펫 변경 |
| `/animals usage` | Usage 모니터링 상태 확인 |
| `/animals hide` | statusLine에서 펫 숨기기 |
| `/animals show` | 펫 다시 표시 |

## 지원 펫

### Phase 1 — ASCII 스프라이트

| 펫 | Full 모드 | Compact |
|-----|-----------|---------|
| Goose | `(o>)` | `(o>)` |
| Little Chick | 병아리 | `(°v°)` |
| Penguin | 펭귄 | `(^^)` |
| Cat | 고양이 | `(·.·)` |
| Capybara | 카피바라 | `(*_*)` |
| Rabbit | 토끼 | `(°..°)` |

미지원 펫은 generic fallback `(◦◦)`으로 표시됩니다.

### Compact 표정 (추가)

Pig `(ꈍ.ꈍ)` · Slime `(~.~)` · Hamster `(•ᴥ•)` · Sloth `(-_-)`

## 레이아웃 시스템

터미널 크기에 따라 자동으로 레이아웃이 전환됩니다:

| 조건 | 모드 | 줄 수 |
|------|------|-------|
| 높이 ≥ 15 & 너비 ≥ 90 | **Full** — ASCII 스프라이트 + 말풍선 + status | 5줄 |
| 높이 ≥ 8 & 너비 ≥ 40 | **Compact** — 표정 이모지 + 한줄 info | 2줄 |
| 높이 < 8 or 너비 < 40 | **Micro** — 펫 표정 + 핵심 정보 | 1줄 |

### 표시 정보

- **프로젝트명** — 현재 디렉토리
- **브랜치** — git 현재 브랜치
- **모델** — Claude 모델명
- **Context** — 컨텍스트 사용률 (색상: 초록 → 노랑 → 빨강)
- **Usage** — API 사용률 + 프로그레스 바 (캐시 기반)
- **펫 레벨** — ★ 기반 표시 (Lv/3, 최대 5개)
- **말풍선** — 컨텍스트 사용률에 따른 반응 메시지

### Mood 시스템

API Usage %에 따라 펫의 표정이 변합니다:

| Usage | Mood | 표정 |
|-------|------|------|
| 0–39% | Happy | ★눈, 밝은 표정 |
| 40–69% | Normal | 기본 표정 |
| 70–89% | Worried | ;눈, 불안한 표정 |
| 90–100% | Panic | X눈, 급박한 표정 |

### 컨텍스트 대사

펫의 말풍선은 여러 상황을 조합하여 한글로 표시됩니다:

| 조건 | 감지 방법 | 대사 예시 |
|------|----------|----------|
| Mood | API Usage % | "코딩 고고!", "살려줘!!" |
| 시간대 | 현재 시각 | "좋은 아침~", "새벽이잖아..." |
| 코딩 습관 | 세션 시간/요일 | "슬슬 쉬어가자!", "주말에도 코딩?!" |
| 이벤트 | Context %, Cost | "컨텍스트 반 썼다!", "$1 돌파!" |

대사 데이터: `resources/bubbles/ko.txt`

## Usage 모니터링

statusLine에 Claude API 사용률(%)과 리셋 시간을 표시합니다.

### 자동 Usage (추천)

**별도 설정 없이** Claude Code에 로그인만 되어 있으면 자동으로 동작합니다.

Claude Code의 OAuth 자격증명(macOS Keychain)을 읽어 `api.anthropic.com`의 rate limit 헤더에서 정확한 사용률을 가져옵니다. 이 방식은 [Claude-Usage-Tracker](https://github.com/hamed-elfayome/Claude-Usage-Tracker)의 CLI Account Sync 구현을 참고했습니다.

### Fallback

OAuth 토큰을 사용할 수 없는 환경에서는 Claude Code가 생성하는 로컬 JSONL 로그를 파싱하여 추정치를 표시합니다. 다만 플랜별 토큰 한도가 추정치이므로 실제와 다를 수 있습니다.

## 동작 방식

- **펫 API**: `https://render.gitanimals.org/users/{username}`에서 펫 데이터 조회
- **Usage**: CLI OAuth + rate limit 헤더 (정확) 또는 로컬 JSONL 파싱 (추정)
- **캐시**: 300초 TTL, 만료 시 백그라운드 갱신 (statusLine 블로킹 없음)
- **자동 선택**: 가장 레벨 높은 펫을 자동 표시 (수동 선택 가능)
- **로딩 상태**: 캐시 없을 때 스피너 애니메이션 표시

## 구조

```
gitanimals-buddy/
├── .claude-plugin/
│   ├── plugin.json          # 플러그인 메타데이터
│   └── marketplace.json     # 마켓플레이스 레지스트리
├── commands/animals.md      # /animals 슬래시 커맨드
├── hooks/hooks.json         # SessionStart hook (펫 데이터 prefetch)
├── config/
│   ├── gitanimals.json      # 설정 예시
│   └── settings-example.json
├── scripts/
│   ├── statusline.sh        # 메인 렌더러 (adaptive layout)
│   ├── fetch-pet.sh         # API fetcher (백그라운드)
│   ├── preview.sh           # 로컬 프리뷰
│   ├── quick-test.sh        # 테스트 도구
│   ├── mood.sh              # usage% → mood 매핑 + 표정/대사
│   └── sprite-renderer.sh  # .sprite 파싱 + ANSI 렌더링 엔진
├── resources/
│   └── sprites/             # ASCII 아트 데이터 (.sprite 포맷)
│       ├── rabbit.sprite
│       ├── goose.sprite
│       ├── cat.sprite
│       ├── penguin.sprite
│       ├── little_chick.sprite
│       ├── capybara.sprite
│       └── fallback.sprite
├── install.sh               # 원스텝 설치
├── PUBLISHING.md            # 마켓플레이스 등록 가이드
└── README.md
```

## 의존성

- `jq` — JSON 파싱
- `curl` — API 호출
- `git` — 브랜치 감지
- bash 4.0+

## Contributing

기여를 환영합니다! 새 펫 스프라이트, 대사 추가, 버그 수정, 기능 개발 등 모든 영역에 자유롭게 기여할 수 있습니다.

**가장 쉬운 기여:**
- `resources/sprites/` 에 `.sprite` 파일 추가 (새 펫)
- `resources/bubbles/ko.txt` 에 대사 추가

자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고해주세요.

> Contributions welcome! Add new pet sprites, dialogues, bug fixes, or features. See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## GitAnimals

[GitAnimals](https://gitanimals.org)는 GitHub 활동으로 펫을 수집하고 성장시키는 서비스입니다.

- 커밋 30회마다 새 펫 뽑기
- contribution이 펫 레벨을 올림
- 50종 이상의 펫 (희귀도별)
- GitHub README에 SVG로 표시

## License

MIT

## 라이선스

MIT
