# /animals

GitAnimals 펫 companion 관리 커맨드

## Usage

- `/animals` — 현재 활성 펫 표시
- `/animals login <username>` — GitAnimals 유저네임 설정
- `/animals list` — 보유 펫 목록 조회
- `/animals select <pet_type>` — 활성 펫 변경
- `/animals card` — 현재 펫 상세 정보
- `/animals setup <session_key>` — Usage 모니터링용 claude.ai 세션 키 설정
- `/animals hide` — statusLine에서 펫 숨기기
- `/animals show` — 펫 다시 표시

## Implementation

When the user types `/animals`, run the corresponding script based on the subcommand:

### /animals (no args)
Show the current active pet info. Read from `~/.claude/gitanimals.json` and `~/.cache/gitanimals/pet-cache.json`.

```bash
CONFIG="$HOME/.claude/gitanimals.json"
if [ ! -f "$CONFIG" ]; then
  echo "🐾 GitAnimals: No account linked yet."
  echo "   Run: /animals login <your-github-username>"
  exit 0
fi
USERNAME=$(jq -r '.username' "$CONFIG")
ACTIVE=$(jq -r '.active_pet // "auto"' "$CONFIG")
echo "🐾 GitAnimals Buddy"
echo "   User: $USERNAME"
echo "   Active pet: $ACTIVE"
echo "   Pet is displayed in the statusLine footer."
```

### /animals login <username>
Save the GitHub username to config.

```bash
USERNAME="$1"
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/gitanimals.json" ]; then
  jq --arg u "$USERNAME" '.username = $u' "$HOME/.claude/gitanimals.json" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$HOME/.claude/gitanimals.json"
else
  echo "{\"username\": \"$USERNAME\", \"hidden\": false}" > "$HOME/.claude/gitanimals.json"
fi
echo "✅ GitAnimals username set to: $USERNAME"
echo "   Your top pet will appear in the statusLine."
echo "   Fetching pet data..."
bash "$(dirname "$0")/../scripts/fetch-pet.sh"
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

```bash
PET_TYPE="$1"
CONFIG="$HOME/.claude/gitanimals.json"
jq --arg p "$PET_TYPE" '.active_pet = $p' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
echo "✅ Active pet set to: $PET_TYPE"
```

### /animals setup <session_key>
Set up claude.ai session key for accurate Usage monitoring. Without this, Usage falls back to local JSONL parsing (less accurate).

```bash
SESSION_KEY="$1"
CONFIG="$HOME/.claude/gitanimals.json"
mkdir -p "$HOME/.claude"

if [ -z "$SESSION_KEY" ]; then
  echo "📊 Usage 모니터링 설정"
  echo ""
  echo "   정확한 Usage %를 표시하려면 claude.ai 세션 키가 필요합니다."
  echo ""
  echo "   세션 키 얻는 방법:"
  echo "   1. 브라우저에서 https://claude.ai 접속 (로그인 상태)"
  echo "   2. DevTools (F12) → Application → Cookies → claude.ai"
  echo "   3. sessionKey 값 복사"
  echo ""
  echo "   사용법: /animals setup <session_key>"
  echo ""
  echo "   ⚠️  세션 키 없이도 동작합니다 (로컬 JSONL 기반 추정치 사용)"
  exit 0
fi

# Save session key
if [ -f "$CONFIG" ]; then
  jq --arg k "$SESSION_KEY" '.claude_session_key = $k' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
else
  echo "{\"claude_session_key\": \"$SESSION_KEY\", \"hidden\": false}" > "$CONFIG"
fi

# Auto-detect org ID
ORG_ID=$(curl -s --max-time 5 \
  "https://claude.ai/api/organizations" \
  -H "Cookie: sessionKey=${SESSION_KEY}" \
  -H "Accept: application/json" 2>/dev/null \
  | jq -r '.[0].uuid // empty' 2>/dev/null)

if [ -n "$ORG_ID" ]; then
  jq --arg id "$ORG_ID" '.claude_org_id = $id' "$CONFIG" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$CONFIG"
  echo "✅ Usage 모니터링 설정 완료"
  echo "   Organization: $ORG_ID"
  # Verify by fetching usage
  bash "$(dirname "$0")/../scripts/fetch-usage.sh" 2>/dev/null
  if [ -f "$HOME/.cache/gitanimals/usage-cache.txt" ]; then
    UTIL=$(grep "^UTILIZATION=" "$HOME/.cache/gitanimals/usage-cache.txt" | cut -d= -f2)
    echo "   Current usage: ${UTIL}%"
  fi
else
  echo "❌ 세션 키가 유효하지 않거나 만료되었습니다."
  echo "   브라우저에서 claude.ai에 로그인 후 세션 키를 다시 확인해주세요."
fi
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
