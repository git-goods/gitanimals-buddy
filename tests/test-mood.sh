#!/bin/bash
# tests/test-mood.sh — mood 시스템 테스트
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
source "$SCRIPT_DIR/mood.sh"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label: expected='$expected' actual='$actual'"
    FAIL=$((FAIL+1))
  fi
}

echo "🧪 Mood System Tests"
echo "===================="

# get_mood tests
echo ""
echo "[1] get_mood — usage % → mood 매핑"
assert_eq "0% → happy"    "happy"   "$(get_mood 0)"
assert_eq "20% → happy"   "happy"   "$(get_mood 20)"
assert_eq "39% → happy"   "happy"   "$(get_mood 39)"
assert_eq "40% → normal"  "normal"  "$(get_mood 40)"
assert_eq "69% → normal"  "normal"  "$(get_mood 69)"
assert_eq "70% → worried" "worried" "$(get_mood 70)"
assert_eq "89% → worried" "worried" "$(get_mood 89)"
assert_eq "90% → panic"   "panic"   "$(get_mood 90)"
assert_eq "100% → panic"  "panic"   "$(get_mood 100)"
assert_eq "빈값 → normal" "normal"  "$(get_mood "")"

# get_mood_bubble tests
echo ""
echo "[2] get_mood_bubble — mood별 대사 존재 확인"
for mood in happy normal worried panic; do
  result=$(get_mood_bubble "$mood")
  if [ -n "$result" ]; then
    echo "  ✅ $mood → '$result'"
    PASS=$((PASS+1))
  else
    echo "  ❌ $mood → 빈 문자열"
    FAIL=$((FAIL+1))
  fi
done

# get_mood_compact_face tests
echo ""
echo "[3] get_mood_compact_face — mood별 표정 변화"
for pet in rabbit goose cat penguin little_chick capybara pig slime hamster sloth unknown; do
  happy_face=$(get_mood_compact_face "$pet" "happy")
  panic_face=$(get_mood_compact_face "$pet" "panic")
  if [ "$happy_face" != "$panic_face" ]; then
    echo "  ✅ $pet: happy='$happy_face' ≠ panic='$panic_face'"
    PASS=$((PASS+1))
  else
    echo "  ❌ $pet: happy와 panic이 동일 '$happy_face'"
    FAIL=$((FAIL+1))
  fi
done

echo ""
echo "===================="
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All tests passed!" || exit 1
