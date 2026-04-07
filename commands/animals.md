---
name: animals
description: GitAnimals 펫 companion 관리 커맨드
user-invocable: true
allowed-tools:
  - Bash
---

# /animals

GitAnimals 펫 companion 관리 커맨드

## Usage

- `/animals` — 현재 활성 펫 표시
- `/animals help` — 사용 가능한 명령어 목록 표시
- `/animals login` — GitAnimals 웹에서 로그인 후 username 확인
- `/animals login <username>` — GitAnimals 유저네임 검증 후 설정
- `/animals list` — 보유 펫 목록 조회
- `/animals select <pet_type>` — 활성 펫 변경
- `/animals card` — 현재 펫 상세 정보
- `/animals usage` — Usage 모니터링 상태 확인
- `/animals hide` — statusLine에서 펫 숨기기
- `/animals show` — 펫 다시 표시
- `/animals-link` — 현재 repo를 플러그인에 symlink 연결
- `/animals-link status` — symlink 연결 상태 확인

## Implementation

When the user types `/animals`, run the corresponding script based on the subcommand:

### /animals help
Show all available commands.

```bash
echo "🐾 GitAnimals Buddy — 사용 가능한 명령어"
echo ""
echo "  /animals              현재 활성 펫 표시"
echo "  /animals help         이 도움말 표시"
echo "  /animals login        GitAnimals 웹에서 로그인 후 username 확인"
echo "  /animals login <id>   유저네임 검증 후 설정"
echo "  /animals list         보유 펫 목록 조회"
echo "  /animals select <id>  활성 펫 변경"
echo "  /animals card         현재 펫 상세 정보"
echo "  /animals usage        Usage 모니터링 상태 확인"
echo "  /animals hide         statusLine에서 펫 숨기기"
echo "  /animals show         펫 다시 표시"
```

### /animals (no args)
Show the current active pet info. Read from `~/.claude/gitanimals.json` and `~/.cache/gitanimals/pet-cache.json`.

```bash
CONFIG="$HOME/.claude/gitanimals.json"
if [ ! -f "$CONFIG" ]; then
  echo "🐾 GitAnimals: No account linked yet."
  echo "   Run: /animals login <your-github-username>"
  exit 0
fi
GA_USER=$(jq -r '.username' "$CONFIG")
ACTIVE=$(jq -r '.active_pet // "auto"' "$CONFIG")
echo "🐾 GitAnimals Buddy"
echo "   User: $GA_USER"
echo "   Active pet: $ACTIVE"
echo "   Pet is displayed in the statusLine footer."
```

### /animals login [username]
브라우저로 gitanimals.org 연결하거나 username 검증 후 config 저장.
When running this section, set GA_USER to the username argument provided by the user (the word after "login").

```bash
GA_USER="$ARGUMENTS"

if [ -z "$GA_USER" ]; then
  echo "🌐 GitAnimals 웹에서 로그인 후 username을 확인하세요."
  open "https://www.gitanimals.org/en_US/auth/claude-code" 2>/dev/null || \
    xdg-open "https://www.gitanimals.org/en_US/auth/claude-code" 2>/dev/null || \
    echo "   👉 https://www.gitanimals.org/en_US/auth/claude-code"
  echo ""
  echo "   확인 후 아래 명령어를 실행하세요:"
  echo "   /animals login <your-username>"
  exit 0
fi

# Username 검증
RESPONSE=$(curl -s --max-time 5 "https://render.gitanimals.org/users/${GA_USER}" 2>/dev/null)
if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | jq -e '.personas' >/dev/null 2>&1; then
  echo "❌ '${GA_USER}' 유저를 찾을 수 없습니다."
  echo "   GitAnimals에 가입된 GitHub username인지 확인해주세요."
  echo "   👉 https://www.gitanimals.org"
  exit 0
fi

mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/gitanimals.json" ]; then
  jq --arg u "$GA_USER" '.username = $u' "$HOME/.claude/gitanimals.json" > /tmp/ga-tmp.json && \
    mv /tmp/ga-tmp.json "$HOME/.claude/gitanimals.json"
else
  echo "{\"username\": \"$GA_USER\", \"hidden\": false}" > "$HOME/.claude/gitanimals.json"
fi

PET_COUNT=$(echo "$RESPONSE" | jq '[.personas[]? | select(.type != null)] | length' 2>/dev/null)
echo "✅ GitAnimals 로그인 완료: ${GA_USER}"
echo "   보유 펫: ${PET_COUNT}마리"
echo "   Your top pet will appear in the statusLine."
bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-pet.sh" 2>/dev/null &
```

### /animals list
List pets from cached data.

```bash
CACHE="$HOME/.cache/gitanimals/pet-cache.json"
if [ ! -f "$CACHE" ]; then
  echo "No cached pet data. Make sure you've run /animals login first."
  exit 0
fi
echo "🐾 Your GitAnimals pets:"
jq -r '[.personas[]? | select(.type != null)] | sort_by(-(.level | tonumber)) | .[] | "   \(.type) Lv.\(.level)"' "$CACHE" 2>/dev/null
```

### /animals select <pet_type>
Set active pet.

When running this section, set PET_TYPE to the pet type argument provided by the user (the word after "select").

```bash
PET_TYPE="$ARGUMENTS"
CONFIG="$HOME/.claude/gitanimals.json"
jq --arg p "$PET_TYPE" '.active_pet = $p' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "✅ Active pet set to: $PET_TYPE"
```

### /animals usage
Show current Usage monitoring status. Usage is automatically fetched from Claude Code's OAuth credentials (no manual setup needed).

```bash
CONFIG="$HOME/.claude/gitanimals.json"
CACHE="$HOME/.cache/gitanimals/usage-cache.txt"

echo "📊 Usage 모니터링"
echo ""

# Check if cached data exists
if [ -f "$CACHE" ]; then
  UTIL=$(grep "^UTILIZATION=" "$CACHE" | cut -d= -f2)
  SOURCE=$(grep "^SOURCE=" "$CACHE" | cut -d= -f2)
  RESETS=$(grep "^RESETS_AT=" "$CACHE" | cut -d= -f2)
  TS=$(grep "^TIMESTAMP=" "$CACHE" | cut -d= -f2)
  AGE=$(( $(date +%s) - TS ))

  echo "   Usage: ${UTIL}%"
  echo "   Source: ${SOURCE}"
  [ -n "$RESETS" ] && echo "   Resets at: ${RESETS}"
  echo "   Cache age: ${AGE}s"
else
  echo "   캐시 없음. fetch-usage.sh가 실행되면 자동으로 데이터를 가져옵니다."
fi

echo ""
echo "   데이터 소스 우선순위:"
echo "   1. oauth — Claude Code 로그인 자격증명 자동 사용 (추천)"
echo "   2. jsonl — 로컬 JSONL 로그 파싱 (추정치)"
echo ""
echo "   ℹ️  Claude Code에 로그인되어 있으면 자동으로 동작합니다."
```

### /animals hide / show
Toggle pet visibility.

```bash
# hide
CONFIG="$HOME/.claude/gitanimals.json"
jq '.hidden = true' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "🐾 Pet hidden from statusLine."

# show
jq '.hidden = false' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "🐾 Pet visible again!"
```
