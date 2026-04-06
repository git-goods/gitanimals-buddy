#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"

PASS=0
FAIL=0

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label: '$needle' not found"
    FAIL=$((FAIL+1))
  fi
}

echo "🧪 Sprite Renderer Tests"
echo "========================"

# Create test .sprite
TEST_SPRITE=$(mktemp /tmp/test-XXXX.sprite)
cat > "$TEST_SPRITE" <<'SPRITE'
body_color=97
eye_color=32
panic_eye_color=31
c1=35

eyes_happy=★
eyes_normal=o
eyes_worried=;
eyes_panic=> <

[frame:0]
 /\_/\
( {L}.{R} )
 > ^ <
/|   |\
(_{1}~{/}_{1}~{/}_)

[frame:1]
 /\_/\
( {L}.{R} )
 > ^ <
 |   |
(_{1}~{/}_{1}~{/}_)
SPRITE

echo ""
echo "[1] 기본 렌더링 — frame 0, normal mood"
output=$(bash "$SCRIPT_DIR/sprite-renderer.sh" "$TEST_SPRITE" 0 normal)
line_count=$(echo "$output" | wc -l | tr -d ' ')
assert_eq "5줄 출력" "5" "$line_count"
assert_contains "눈 문자 'o' 포함" "o" "$output"

echo ""
echo "[2] mood별 눈 변환"
happy_out=$(bash "$SCRIPT_DIR/sprite-renderer.sh" "$TEST_SPRITE" 0 happy)
panic_out=$(bash "$SCRIPT_DIR/sprite-renderer.sh" "$TEST_SPRITE" 0 panic)
assert_contains "happy → ★" "★" "$happy_out"
assert_contains "panic → >" ">" "$panic_out"

echo ""
echo "[3] 비대칭 눈 (panic: > <)"
assert_contains "panic 왼쪽 눈 >" ">" "$panic_out"
assert_contains "panic 오른쪽 눈 <" "<" "$panic_out"

echo ""
echo "[4] 프레임 선택"
f0=$(bash "$SCRIPT_DIR/sprite-renderer.sh" "$TEST_SPRITE" 0 normal)
f1=$(bash "$SCRIPT_DIR/sprite-renderer.sh" "$TEST_SPRITE" 1 normal)
assert_eq "다른 프레임 → 다른 출력" "1" "$([ "$f0" != "$f1" ] && echo 1 || echo 0)"

echo ""
echo "[5] ANSI 코드 포함 확인"
assert_contains "body_color ANSI" $'\033[97m' "$output"
assert_contains "eye_color ANSI" $'\033[32m' "$output"
assert_contains "c1 color ANSI" $'\033[35m' "$output"
assert_contains "reset 코드" $'\033[0m' "$output"

echo ""
echo "[6] panic_eye_color 오버라이드"
assert_contains "panic eye → 31m (red)" $'\033[31m' "$panic_out"

rm -f "$TEST_SPRITE"

echo ""
echo "========================"
echo "Results: ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All tests passed!" || exit 1
