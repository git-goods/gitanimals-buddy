#!/bin/bash
# quick-test.sh — 로컬에서 바로 실행하는 원스텝 테스트
# 사용법: bash scripts/quick-test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERNAME="sumi-0011"

echo "🐾 GitAnimals Buddy — Quick Test"
echo "================================="
echo ""

# Step 1: API 호출 테스트
echo "[1/3] API 호출 테스트 (${USERNAME})..."
RESPONSE=$(curl -s --max-time 5 "https://render.gitanimals.org/users/${USERNAME}" 2>/dev/null || echo "FAIL")

if [ "$RESPONSE" = "FAIL" ] || [ -z "$RESPONSE" ]; then
  echo "  ❌ API 연결 실패. 네트워크를 확인해주세요."
  echo "  수동 확인: curl https://render.gitanimals.org/users/${USERNAME}"
  echo ""
  echo "  → 목 데이터로 계속 진행합니다..."
  RESPONSE='{"pets":[{"type":"GOOSE","name":"Goose","level":5,"visible":true}]}'
  USE_MOCK=true
else
  USE_MOCK=false
  echo "  ✅ API 응답 수신!"
  echo ""
  echo "  === 원본 응답 (처음 500자) ==="
  echo "$RESPONSE" | head -c 500
  echo ""
  echo "  =============================="
  echo ""

  # 펫 목록 출력
  echo "  보유 펫 목록:"
  echo "$RESPONSE" | jq -r '
    [.personas[]? | select(.type != null)]
    | sort_by(-(.level | tonumber))
    | .[]
    | "   \(.type) Lv.\(.level) [\(.grade // "?")]"
  ' 2>/dev/null || echo "  (파싱 실패 — API 응답 구조가 다를 수 있음)"
fi

echo ""

# Step 2: 캐시 저장
echo "[2/3] 캐시 저장..."
mkdir -p "$HOME/.cache/gitanimals"
echo "$RESPONSE" > "$HOME/.cache/gitanimals/pet-cache.json"
echo "  ✅ $HOME/.cache/gitanimals/pet-cache.json"

# Config 설정
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude/gitanimals.json" ]; then
  echo "{\"username\": \"${USERNAME}\", \"hidden\": false}" > "$HOME/.claude/gitanimals.json"
  echo "  ✅ $HOME/.claude/gitanimals.json 생성"
else
  echo "  ℹ️  $HOME/.claude/gitanimals.json 이미 존재 (스킵)"
fi

echo ""

# Step 3: statusLine 렌더링 테스트
echo "[3/3] statusLine 렌더링 테스트..."
echo ""

MOCK_SESSION='{
  "model": {"id": "claude-opus-4-6", "display_name": "Opus 4.6"},
  "context_window": {"used_percentage": 23, "remaining_percentage": 77},
  "cost": {"total_cost_usd": 0.0542}
}'

echo "  === Full 모드 (120열) ==="
echo "$MOCK_SESSION" | COLUMNS=120 bash "$SCRIPT_DIR/statusline.sh" 2>/dev/null || echo "  ❌ 렌더링 실패"

echo ""
echo "  === Compact 모드 (80열) ==="
echo "$MOCK_SESSION" | COLUMNS=80 bash "$SCRIPT_DIR/statusline.sh" 2>/dev/null || echo "  ❌ 렌더링 실패"

echo ""
echo "================================="

if [ "$USE_MOCK" = true ]; then
  echo "⚠️  목 데이터로 테스트했습니다."
  echo "   실제 데이터 확인: curl https://render.gitanimals.org/users/${USERNAME} | jq ."
else
  echo "✅ 실제 데이터로 테스트 완료!"
fi

echo ""
echo "📋 다음 단계: Claude Code에 설치하려면"
echo ""
echo "   ~/.claude/settings.json 에 추가:"
echo '   {'
echo '     "statusLine": {'
echo '       "type": "command",'
echo "       \"command\": \"bash ${SCRIPT_DIR}/statusline.sh\""
echo '     }'
echo '   }'
echo ""
