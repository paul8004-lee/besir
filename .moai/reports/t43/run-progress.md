# 카드 t43 — run 단계 증거 (SPEC-UIKIT-012)

작성: run 레인, 2026-10-08. 워크트리 `.claude/worktrees/t43`(브랜치 `WT-leg-drag-resize`), 기준 트리 `b59fcaa`(HEAD `9f05c7a` = SPEC 0.7.1 문서). 모든 아래 값은 이 워크트리에서 직접 돌린 명령의 원문 출력이다. 마감 시점에 갱신된다.

## 1. M0 — 기준 측정(코드 변경 전)

### 1.1 드라이버 기준 B

명령(CLAUDE.md 드라이버 블록 그대로):

```bash
cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \
  && swiftc -o /tmp/gd /tmp/gd.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd
```

원문 출력 꼬리(전체 584줄은 `.moai/state/verify/t43/baseline-driver.log`):

```text
498/498 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
```

종료 코드 **0**. **B = 498** → 마감 목표 **T = 522**(B + 24). `ls -d $TMPDIR/besir-gd-*` → 없음.

### 1.2 빌드 기준(무경고)

```bash
xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
```

원문 로그 `.moai/state/verify/t43/baseline-build-ios.log`. exit **0** · `BUILD SUCCEEDED` 1회 ·
`grep "warning:" … | grep -v appintentsmetadataprocessor | sort -u` → **빈 출력(경고 0)**.

### 1.3 M0 문서(SPEC 0.7.2)

Q-3·5·9 표식 닫음 + 경미 9건(N5-4~7·N5-9~13) 문서 수리 — 명령·출력은 SPEC `progress.md` §E.1 "0.7.2 개정" 실측 표.

## 2. 마감 증거

_(마감 시점에 채운다 — Store·ContentView·드라이버 마일스톤 뒤)_
