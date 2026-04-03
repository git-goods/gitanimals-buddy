# /animals

GitAnimals 펫 companion 관리 커맨드

## Usage

- `/animals` — 현재 활성 펫 표시
- `/animals login <username>` — GitAnimals 유저네임 설정
- `/animals list` — 보유 펫 목록 조회
- `/animals select <pet_type>` — 활성 펫 변경
- `/animals card` — 현재 펫 상세 정보
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
