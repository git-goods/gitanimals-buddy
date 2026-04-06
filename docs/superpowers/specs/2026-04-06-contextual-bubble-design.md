# 컨텍스트 인식 대사 시스템 (Contextual Bubble System)

## 개요

현재 mood별 고정 영어 대사 풀 대신, **mood + 시간대 + 코딩습관 + 이벤트** 조건을 합친 한글 대사 풀에서 랜덤으로 선택하는 시스템.

## 동기

- 현재 대사가 mood 4가지 × 5-7개로 단조로움
- 시간대, 코딩 습관, 세션 이벤트 등 활용 가능한 컨텍스트가 많음
- 한글 대사로 더 친근한 경험 제공

## 설계

### 대사 데이터 파일

`resources/bubbles.txt` — 조건 태그 + 대사를 `|` 구분으로 정의:

```
# mood 기반 (기존 대체)
mood:happy | 코딩 고고!
mood:happy | 오늘도 화이팅~
mood:happy | 좋은 흐름이야!
mood:happy | 신난다!
mood:happy | 야호~!
mood:normal | 집중 모드!
mood:normal | 꾸준히 가자~
mood:normal | 순조로워!
mood:normal | 잘 하고 있어!
mood:worried | 슬슬 조심...
mood:worried | 아끼자...
mood:worried | 좀 빡빡해...
mood:worried | 흠...
mood:panic | 거의 다 썼어!!
mood:panic | 살려줘!!
mood:panic | 아악!!
mood:panic | 큰일이다!

# 시간대
time:morning | 좋은 아침~
time:morning | 오늘도 시작!
time:morning | 모닝 코딩!
time:afternoon | 밥은 먹었어?
time:afternoon | 오후도 힘내!
time:afternoon | 졸리면 커피!
time:evening | 저녁이다~
time:evening | 야근인가?
time:evening | 오늘 수고했어!
time:dawn | 새벽이잖아...
time:dawn | 자야 하지 않아?
time:dawn | 몸 조심해!

# 코딩 습관
habit:long_session | 슬슬 쉬어가자!
habit:long_session | 스트레칭 타임!
habit:long_session | 눈 좀 쉬어~
habit:weekend | 주말에도 코딩?!
habit:weekend | 열정 대단해!
habit:weekend | 쉬어도 돼~

# 이벤트
event:ctx_half | 컨텍스트 반 썼다!
event:ctx_half | 절반 지점!
event:ctx_high | 컨텍스트 거의 다!
event:ctx_high | 정리가 필요해!
event:cost_1usd | $1 돌파!
event:cost_1usd | 오늘 좀 쓴다!
```

### 대사 엔진

`scripts/bubble.sh` — mood.sh의 `get_mood_bubble` 대체

```
Usage: source bubble.sh → get_contextual_bubble <mood> <ctx_pct> <cost_usd>
```

**동작:**
1. 현재 시각 → 시간대 태그 (morning/afternoon/evening/dawn)
2. 세션 시작 시간 감지 → 장시간 코딩 여부 (2시간+)
3. 요일 감지 → 주말 여부
4. ctx_pct, cost_usd → 이벤트 조건 매칭
5. 매칭되는 조건 태그의 대사들을 하나의 풀로 수집
6. mood가 worried/panic이면 mood 대사를 2배 비중으로 추가 (경고 빈도↑)
7. 풀에서 랜덤 1개 선택

**시간대 기준:**
- morning: 06:00 - 11:59
- afternoon: 12:00 - 17:59
- evening: 18:00 - 22:59
- dawn: 23:00 - 05:59

**장시간 코딩 감지:**
- `~/.cache/gitanimals/session-start.txt`에 세션 시작 타임스탬프 기록 (fetch-pet.sh의 SessionStart hook에서)
- 현재 시간 - 시작 시간 ≥ 7200초(2시간) → `habit:long_session`

**이벤트 조건:**
- ctx_pct ≥ 50 → `event:ctx_half`
- ctx_pct ≥ 80 → `event:ctx_high` (ctx_half 대체, 중복 아님)
- cost_usd ≥ 1.0 → `event:cost_1usd`

### statusline.sh 변경

```bash
# 기존
bubble=$(get_mood_bubble "$MOOD")

# 변경
source "$SCRIPT_DIR/bubble.sh"
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
bubble=$(get_contextual_bubble "$MOOD" "$CTX_PCT" "$COST")
```

### 파일 구조

| Action | Path | 역할 |
|--------|------|------|
| Create | `resources/bubbles.txt` | 조건 태그 + 대사 데이터 |
| Create | `scripts/bubble.sh` | 대사 엔진 (조건 수집 + 랜덤 선택) |
| Modify | `scripts/statusline.sh` | bubble 호출을 bubble.sh로 교체 |
| Modify | `scripts/fetch-pet.sh` | 세션 시작 시간 기록 추가 |
| Modify | `scripts/mood.sh` | `get_mood_bubble` 함수 제거 |
| Create | `tests/test-bubble.sh` | 대사 엔진 테스트 |
| Modify | `README.md` | 대사 시스템 문서화 |

### 성능 고려

- `bubbles.txt` 파싱: `grep` + `shuf`/`awk` 로 조건 매칭 → 10ms 이내
- 세션 시작 시간: 파일 1회 read → 무시할 수준
- 총 오버헤드: 기존 대비 +15ms 이내 (300ms 제한 여유 충분)

### 향후 확장

- **언어 선택**: `gitanimals.json`에 `lang: "ko"` 설정 → `resources/bubbles-ko.txt`, `resources/bubbles-en.txt` 분리
- **커스텀 대사**: 유저가 자신만의 bubbles.txt를 `~/.config/gitanimals/bubbles.txt`에 추가
- **펫별 대사**: 태그에 `pet:rabbit |` 추가하여 펫 고유 대사 지원
