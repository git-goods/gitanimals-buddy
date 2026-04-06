#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
source "$SCRIPT_DIR/bubble.sh"

PASS=0
FAIL=0

assert_not_empty() {
  local label="$1" actual="$2"
  if [ -n "$actual" ]; then
    echo "  ✅ $label → '$actual'"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label → empty"
    FAIL=$((FAIL+1))
  fi
}

echo "🧪 Contextual Bubble Tests"
echo "=========================="

echo ""
echo "[1] get_contextual_bubble — mood별 대사 반환"
for mood in happy normal worried panic; do
  result=$(get_contextual_bubble "$mood" 20 0.01)
  assert_not_empty "mood=$mood" "$result"
done

echo ""
echo "[2] 한글 대사 확인"
found_korean=false
for i in $(seq 1 10); do
  result=$(get_contextual_bubble "happy" 20 0.01)
  if echo "$result" | grep -q '[가-힣]' 2>/dev/null; then
    found_korean=true
    break
  fi
done
if $found_korean; then
  echo "  ✅ 한글 대사 확인됨"
  PASS=$((PASS+1))
else
  echo "  ❌ 한글 대사 없음"
  FAIL=$((FAIL+1))
fi

echo ""
echo "[3] get_time_tag — 시간대 태그"
for pair in "7:time:morning" "14:time:afternoon" "20:time:evening" "2:time:dawn"; do
  hour="${pair%%:*}"
  expected="${pair#*:}"
  actual=$(get_time_tag "$hour")
  if [ "$expected" = "$actual" ]; then
    echo "  ✅ hour=$hour → $actual"
    PASS=$((PASS+1))
  else
    echo "  ❌ hour=$hour → expected '$expected', got '$actual'"
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "[4] collect_tags — mood 태그 포함"
tags=$(collect_tags "happy" 55 0.01)
if echo "$tags" | grep -q "mood:happy"; then
  echo "  ✅ mood:happy 포함"
  PASS=$((PASS+1))
else
  echo "  ❌ mood:happy 누락"
  FAIL=$((FAIL+1))
fi

echo ""
echo "[5] collect_tags — ctx 55% → event:ctx_half"
if echo "$tags" | grep -q "event:ctx_half"; then
  echo "  ✅ event:ctx_half 포함"
  PASS=$((PASS+1))
else
  echo "  ❌ event:ctx_half 누락"
  FAIL=$((FAIL+1))
fi

echo ""
echo "[6] collect_tags — ctx 85% → event:ctx_high (not ctx_half)"
tags_high=$(collect_tags "normal" 85 0.5)
if echo "$tags_high" | grep -q "event:ctx_high"; then
  echo "  ✅ event:ctx_high 포함"
  PASS=$((PASS+1))
else
  echo "  ❌ event:ctx_high 누락"
  FAIL=$((FAIL+1))
fi
if ! echo "$tags_high" | grep -q "event:ctx_half"; then
  echo "  ✅ event:ctx_half 미포함 (대체됨)"
  PASS=$((PASS+1))
else
  echo "  ❌ event:ctx_half 중복"
  FAIL=$((FAIL+1))
fi

echo ""
echo "[7] collect_tags — cost >= 1.0 → cost_1usd"
tags_cost=$(collect_tags "happy" 20 1.5)
if echo "$tags_cost" | grep -q "event:cost_1usd"; then
  echo "  ✅ event:cost_1usd 포함"
  PASS=$((PASS+1))
else
  echo "  ❌ event:cost_1usd 누락"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=========================="
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All tests passed!" || exit 1
