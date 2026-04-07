---
name: login
description: GitAnimals 유저네임 설정
---

GitAnimals GitHub 유저네임을 설정합니다.

## Usage
- `/gitanimals-buddy:login` — 브라우저에서 gitanimals.org로 이동하여 username 확인
- `/gitanimals-buddy:login <username>` — username 검증 후 바로 설정

## Implementation

```bash
USERNAME="$ARGUMENTS"

if [ -z "$USERNAME" ]; then
  echo "🌐 GitAnimals 웹에서 로그인 후 username을 확인하세요."
  open "https://www.gitanimals.org/en_US/auth/claude-code" 2>/dev/null || \
    xdg-open "https://www.gitanimals.org/en_US/auth/claude-code" 2>/dev/null || \
    echo "   👉 https://www.gitanimals.org/en_US/auth/claude-code"
  echo ""
  echo "   확인 후 아래 명령어를 실행하세요:"
  echo "   /gitanimals-buddy:login <your-username>"
  exit 0
fi

# Username 검증
RESPONSE=$(curl -s --max-time 5 "https://render.gitanimals.org/users/${USERNAME}" 2>/dev/null)
if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | jq -e '.personas' >/dev/null 2>&1; then
  echo "❌ '${USERNAME}' 유저를 찾을 수 없습니다."
  echo "   GitAnimals에 가입된 GitHub username인지 확인해주세요."
  echo "   👉 https://www.gitanimals.org"
  exit 0
fi

# Config 저장
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/gitanimals.json" ]; then
  jq --arg u "$USERNAME" '.username = $u' "$HOME/.claude/gitanimals.json" > /tmp/ga-tmp.json && \
    mv /tmp/ga-tmp.json "$HOME/.claude/gitanimals.json"
else
  echo "{\"username\": \"$USERNAME\", \"hidden\": false}" > "$HOME/.claude/gitanimals.json"
fi

PET_COUNT=$(echo "$RESPONSE" | jq '[.personas[]? | select(.type != null)] | length' 2>/dev/null)
echo "✅ GitAnimals 로그인 완료: ${USERNAME}"
echo "   보유 펫: ${PET_COUNT}마리"
echo "   Your top pet will appear in the statusLine."

bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-pet.sh" 2>/dev/null &
```
