# TODO

## Usage 개선

- [ ] 7일 주간 usage 표시 — rate limit 헤더의 `7d-utilization` 활용
- [ ] usage 캐시 TTL 최적화 — haiku 1토큰 소비하므로 호출 주기 조정
- [ ] usage 임계값 알림 — 80%↑ 말풍선 경고
- [ ] 펫 반응 연동 — usage %에 따라 펫 표정/대사 변화

## 플러그인 완성도

- [ ] install.sh 개선 — OAuth 동작 여부 자동 체크, 설치 시 usage 테스트
- [ ] Linux 지원 — Keychain 없는 환경에서 credentials.json만으로 동작
- [ ] 마켓플레이스 등록 — plugin.json 정비 후 배포

## 스프라이트

- [ ] 새 펫 추가 — 현재 6종 (Goose, Chick, Penguin, Cat, Capybara, Rabbit)
