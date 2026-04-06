---
name: login
description: GitAnimals 유저네임 설정
---

GitAnimals GitHub 유저네임을 설정합니다.

## Usage
`/gitanimals-buddy:login <username>`

## Implementation

사용자가 제공한 username으로 `~/.claude/gitanimals.json`을 설정하고, pet 데이터를 fetch합니다.

```bash
USERNAME="$ARGUMENTS"
if [ -z "$USERNAME" ]; then
  echo "❌ 유저네임을 입력해주세요: /gitanimals-buddy:login <username>"
  exit 0
fi
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/gitanimals.json" ]; then
  jq --arg u "$USERNAME" '.username = $u' "$HOME/.claude/gitanimals.json" > /tmp/ga-tmp.json && mv /tmp/ga-tmp.json "$HOME/.claude/gitanimals.json"
else
  echo "{\"username\": \"$USERNAME\", \"hidden\": false}" > "$HOME/.claude/gitanimals.json"
fi
echo "✅ GitAnimals username set to: $USERNAME"
echo "   Your top pet will appear in the statusLine."
bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-pet.sh" 2>/dev/null &
```
