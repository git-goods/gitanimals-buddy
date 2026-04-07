---
name: animals-link
description: 현재 repo를 GitAnimals Buddy 플러그인에 symlink 연결
user-invocable: true
allowed-tools:
  - Bash
---

# /animals-link

GitAnimals Buddy 플러그인을 현재 디렉토리에 symlink로 연결합니다.
repo를 다른 폴더로 이동했을 때 재연결하는 용도로 사용하세요.

## Usage
- `/animals-link` — 현재 디렉토리를 플러그인 경로에 symlink 연결
- `/animals-link status` — 현재 연결 상태 확인

## Implementation

```bash
PLUGIN_PATH="$HOME/.claude/plugins/marketplaces/gitanimals-buddy"
SUBCOMMAND="$ARGUMENTS"

if [ "$SUBCOMMAND" = "status" ]; then
  if [ -L "$PLUGIN_PATH" ]; then
    TARGET=$(readlink "$PLUGIN_PATH")
    echo "🔗 Symlink 연결됨"
    echo "   $PLUGIN_PATH"
    echo "   → $TARGET"
    if [ -d "$TARGET" ]; then
      echo "   ✅ 대상 경로 유효"
    else
      echo "   ❌ 대상 경로 없음 (이동 또는 삭제됨)"
    fi
  elif [ -d "$PLUGIN_PATH" ]; then
    echo "📁 일반 디렉토리 (symlink 아님)"
    echo "   $PLUGIN_PATH"
    echo "   /animals-link 으로 현재 repo에 연결할 수 있습니다."
  else
    echo "❌ 플러그인 경로 없음: $PLUGIN_PATH"
  fi
  exit 0
fi

# symlink 연결
CURRENT_DIR="$(pwd)"

# gitanimals-buddy repo인지 확인
if [ ! -f "$CURRENT_DIR/.claude-plugin/plugin.json" ] && [ ! -f "$CURRENT_DIR/scripts/statusline.sh" ]; then
  echo "❌ 현재 디렉토리가 gitanimals-buddy repo가 아닙니다."
  echo "   gitanimals-buddy repo 디렉토리에서 실행하세요."
  exit 1
fi

# 기존 경로 제거
if [ -L "$PLUGIN_PATH" ]; then
  rm "$PLUGIN_PATH"
elif [ -d "$PLUGIN_PATH" ]; then
  BACKUP="${PLUGIN_PATH}.backup.$(date +%s)"
  mv "$PLUGIN_PATH" "$BACKUP"
  echo "📦 기존 디렉토리 백업: $BACKUP"
fi

# symlink 생성
ln -s "$CURRENT_DIR" "$PLUGIN_PATH"
echo "🔗 Symlink 연결 완료"
echo "   $PLUGIN_PATH"
echo "   → $CURRENT_DIR"

# 슬래시 커맨드 동기화
echo ""
echo "📋 슬래시 커맨드 동기화..."
mkdir -p "$HOME/.claude/commands"
for cmd_file in "$CURRENT_DIR/commands/"*.md; do
  fname=$(basename "$cmd_file")
  target="$HOME/.claude/commands/$fname"
  rm -f "$target"
  ln -s "$cmd_file" "$target"
  echo "   ✅ $fname"
done

echo ""
echo "   /reload-plugins 로 적용하세요."
```
