---
name: animals-help
description: GitAnimals Buddy 사용 가능한 명령어 목록 표시
user-invocable: true
allowed-tools:
  - Bash
---

# /animals-help

GitAnimals Buddy 사용 가능한 명령어 목록 표시

## Implementation

```bash
echo "🐾 GitAnimals Buddy — 사용 가능한 명령어"
echo ""
echo "  /animals              현재 활성 펫 표시"
echo "  /animals help         이 도움말 표시"
echo "  /animals login        GitAnimals 웹에서 로그인 후 username 확인"
echo "  /animals login <id>   유저네임 검증 후 설정"
echo "  /animals list         보유 펫 목록 조회"
echo "  /animals select <id>  활성 펫 변경"
echo "  /animals card         현재 펫 상세 정보"
echo "  /animals usage        Usage 모니터링 상태 확인"
echo "  /animals hide         statusLine에서 펫 숨기기"
echo "  /animals show         펫 다시 표시"
echo ""
echo "  /animals-link         현재 repo를 플러그인에 symlink 연결"
echo "  /animals-link status  symlink 연결 상태 확인"
```
