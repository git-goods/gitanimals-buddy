# 릴리스 가이드 (내부용)

## 릴리스 전략

```
main (개발) → PR → release (배포) → 자동: 버전 bump + 태그 + GitHub Release
```

### 브랜치 역할

| 브랜치 | 역할 | 누가 머지하나 |
|--------|------|-------------|
| `main` | 개발 브랜치. 기능/버그 PR이 여기로 머지됨 | 메인테이너 |
| `release` | 배포 브랜치. main에서 PR로만 업데이트 | 메인테이너 |
| `feat/*`, `fix/*` | 작업 브랜치 | 기여자 |

### 흐름

```
1. 기여자: feat/xxx → main (PR)
2. 메인테이너: main → release (PR 생성)
3. release PR 머지 시 GitHub Actions가 자동으로:
   - 커밋 타입 분석 → 버전 bump (major/minor/patch)
   - plugin.json, marketplace.json 버전 업데이트
   - git tag 생성 (v0.3.0)
   - GitHub Release 생성 (changelog 포함)
```

## 버전 규칙

[Semantic Versioning](https://semver.org/) 기반:

| 커밋 타입 | 버전 변경 | 예시 |
|----------|----------|------|
| `feat:` | **minor** (0.2.0 → 0.3.0) | 새 펫, 새 기능 |
| `fix:`, `refactor:` | **patch** (0.3.0 → 0.3.1) | 버그 수정, 리팩토링 |
| `docs:`, `test:` | **patch** (0.3.0 → 0.3.1) | 문서, 테스트 |
| `BREAKING CHANGE` | **major** (0.3.0 → 1.0.0) | 호환성 깨지는 변경 |

> 1.0.0 이전(0.x.y)에서는 minor가 breaking일 수 있음

## GitHub Actions 설정

`.github/workflows/release.yml`:

```yaml
name: Release

on:
  pull_request:
    branches: [release]
    types: [closed]

jobs:
  release:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          ref: release
          fetch-depth: 0

      - name: Determine version bump
        id: bump
        run: |
          # PR의 커밋 메시지에서 타입 분석
          COMMITS=$(git log --oneline ${{ github.event.pull_request.base.sha }}..${{ github.event.pull_request.merge_commit_sha }})
          
          if echo "$COMMITS" | grep -qi "BREAKING CHANGE"; then
            echo "type=major" >> $GITHUB_OUTPUT
          elif echo "$COMMITS" | grep -qi "^[a-f0-9]* feat"; then
            echo "type=minor" >> $GITHUB_OUTPUT
          else
            echo "type=patch" >> $GITHUB_OUTPUT
          fi

      - name: Get current version
        id: current
        run: |
          VERSION=$(jq -r '.version' .claude-plugin/plugin.json)
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Calculate new version
        id: new
        run: |
          IFS='.' read -r major minor patch <<< "${{ steps.current.outputs.version }}"
          case "${{ steps.bump.outputs.type }}" in
            major) major=$((major+1)); minor=0; patch=0 ;;
            minor) minor=$((minor+1)); patch=0 ;;
            patch) patch=$((patch+1)) ;;
          esac
          echo "version=${major}.${minor}.${patch}" >> $GITHUB_OUTPUT

      - name: Update version files
        run: |
          NEW_VERSION="${{ steps.new.outputs.version }}"
          # plugin.json
          jq --arg v "$NEW_VERSION" '.version = $v' .claude-plugin/plugin.json > tmp.json && mv tmp.json .claude-plugin/plugin.json
          # marketplace.json (top-level and plugin entry)
          jq --arg v "$NEW_VERSION" '.version = $v | .plugins[0].version = $v' .claude-plugin/marketplace.json > tmp.json && mv tmp.json .claude-plugin/marketplace.json

      - name: Commit version bump
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
          git commit -m "release: v${{ steps.new.outputs.version }}"
          git push

      - name: Create tag
        run: |
          git tag "v${{ steps.new.outputs.version }}"
          git push origin "v${{ steps.new.outputs.version }}"

      - name: Generate changelog
        id: changelog
        run: |
          PREV_TAG=$(git tag --sort=-v:refname | head -2 | tail -1)
          if [ -z "$PREV_TAG" ]; then
            CHANGELOG=$(git log --oneline --no-merges HEAD)
          else
            CHANGELOG=$(git log --oneline --no-merges ${PREV_TAG}..HEAD)
          fi
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          echo "$CHANGELOG" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: "v${{ steps.new.outputs.version }}"
          name: "v${{ steps.new.outputs.version }}"
          body: |
            ## Changes
            ${{ steps.changelog.outputs.changelog }}
            
            ## Install / Update
            ```
            /plugin marketplace add git-goods/gitanimals-buddy
            /plugin install gitanimals-buddy@gitanimals-buddy
            ```
            
            Already installed? Run:
            ```
            /plugin marketplace update gitanimals-buddy
            /plugin update gitanimals-buddy@gitanimals-buddy
            ```

      - name: Run tests
        run: |
          bash tests/test-mood.sh
          bash tests/test-bubble.sh
          bash tests/test-sprite-renderer.sh

  sync-main:
    needs: release
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main
          fetch-depth: 0

      - name: Sync version back to main
        run: |
          git fetch origin release
          git checkout origin/release -- .claude-plugin/plugin.json .claude-plugin/marketplace.json
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
          git diff --cached --quiet || git commit -m "chore: sync version from release"
          git push
```

## 수동 릴리스 (긴급 시)

자동화가 안 될 때 수동으로 릴리스:

```bash
# 1. release 브랜치에서
git checkout release
git merge main

# 2. 버전 bump
NEW_VERSION="0.3.0"
jq --arg v "$NEW_VERSION" '.version = $v' .claude-plugin/plugin.json > tmp.json && mv tmp.json .claude-plugin/plugin.json
jq --arg v "$NEW_VERSION" '.version = $v | .plugins[0].version = $v' .claude-plugin/marketplace.json > tmp.json && mv tmp.json .claude-plugin/marketplace.json

# 3. 커밋 + 태그 + push
git add .claude-plugin/
git commit -m "release: v${NEW_VERSION}"
git tag "v${NEW_VERSION}"
git push origin release --tags

# 4. main에 버전 동기화
git checkout main
git checkout release -- .claude-plugin/plugin.json .claude-plugin/marketplace.json
git add . && git commit -m "chore: sync version from release"
git push origin main
```

## 사용자에게 업데이트 전달

릴리스 후 사용자는:

```bash
# 마켓플레이스 메타데이터 갱신
/plugin marketplace update gitanimals-buddy

# 플러그인 업데이트
/plugin update gitanimals-buddy@gitanimals-buddy

# 리로드
/reload-plugins
```

## 체크리스트

릴리스 전 확인:

- [ ] 모든 테스트 통과 (`bash tests/test-*.sh`)
- [ ] README.md 동기화 (새 펫/기능 반영)
- [ ] CLAUDE.md 아키텍처 최신 상태
- [ ] 미리보기 확인 (`bash scripts/preview.sh`)
