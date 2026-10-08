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

## 2. Store 마일스톤 (커밋 `6fad716` + `69f5d74`, swift-impl)

구현: 소유 조회 `owningActivity(of:)`(REQ-004) · 유효 Δ `effectiveDragMinutes(leg:owner:requestedMinutes:)`(REQ-006~008, 순수 인스턴스 메서드) · 상수 `minDraggedActivityMinutes = 5`·`dragSnapStepMinutes = 5` · `adjustTravelLeg` 소유 갈래 `applyLinkedLegDrag`(REQ-001·002·010·011 — 전체는 먼저 모으고 한 번씩, 저장 루프 밖) · `estimatedLegs` 정확 앵커 시각 대조만(REQ-016). 69f5d74는 effectiveDragMinutes를 인스턴스 메서드로 전환(AC-006 'store.' 대조가 진짜 호출을 잡게).

### 2.1 오케스트레이터 직접 대조(원문)

```text
$ git diff --name-only b59fcaa -- Shared Tools proxy project.yml
Shared/Store.swift
$ awk '/func moveActivity\(/,/^    }$/' Shared/Store.swift | shasum
ab65d72c40fb86a311fe8b9eabe27d7a96d3a758  -
$ git show b59fcaa:Shared/Store.swift | awk '/func moveActivity\(/,/^    }$/' | shasum
ab65d72c40fb86a311fe8b9eabe27d7a96d3a758  -
$ awk '/private func realignReturnLeg/,/^    }$/' Shared/Store.swift | shasum
a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d  -
$ git show b59fcaa:Shared/Store.swift | awk '/private func realignReturnLeg/,/^    }$/' | shasum
a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d  -
$ awk '/private func estimatedLegs/,/^    }$/' Shared/Store.swift | grep -c 'arrivalDate == activity.startDate\|departureDate == activity.endDate'
2
$ awk '/private func estimatedLegs/,/^    }$/' Shared/Store.swift | grep -c 'inSameDayAs'
0
$ awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift | grep -c 'adjustBuffer('
1
$ git diff b59fcaa -- Shared/Store.swift | grep '^+' | grep -c 'Task {\|await \|try?\|enqueueCalendarUpload\|removeFromCalendar\|googleEventId'
0
$ git diff b59fcaa -- Shared/Store.swift | grep '^+' | grep -v '!=' | grep -c '[])a-zA-Z]!'
0
```

핵심 산식 손검증(오케스트레이터): AF-018-10 −15→−5(경계 +1 후 0쪽 스냅) · AF-018-26 +1500→+1480(상한 = F 다음 날 끝) · AF-018-25 (a) +15→0(상한 초과 시 max(0,·)) · (b) −15→−15(경고 블록 위쪽 비엄격 — 00:00−23:50 = −1430분) · S-14 독립 픽스처 −60→−15. 구현과 전부 일치.

이 단계의 빌드·컴파일 결과는 swift-impl 보고(둘 다 exit 0·무경고) — 최종 게이트(§4)에서 오케스트레이터가 다시 돌려 귀속한다. 구현자의 일회성 기대값 하네스(18/18)는 삭제되어 재실행 불가 — 최종 증거는 드라이버(§3)가 대신한다.

## 2.5 ContentView 마일스톤 (커밋 `149872a`, ui-design)

구현: ActiveDrag 소유·끄는 날 · onBegin 소유 1회 · onChange 유효 Δ(스냅 상수 Store 것) · 뷰 도우미 `legDragShift` · 두 span 안 이동 범위(자르기 [0, 하루 한계], 빈 범위 (0,0) 건너뛰기) · 하루 한계 도우미 `dayLimitMinutes`(연장 = 움직이는 끝의 초과분 시간 올림, N5-5 한정) · `minActivityMinutes` 20→5 · 눈금/높이 `hourCount` · 가장자리 자동 스크롤(띠 12%·최소 44pt·최대 600pt/s, CADisplayLink 약한 대리 + `.common`, 멈춤 함수 `stopAutoScroll` — .ended·.cancelled/.failed·onBegin 거절·dismantleUIView·창 이탈·틱 상태 검사 전부) · D-11 대체안 스위치 `usesPanLockFallbackForOwnedLegDrag`(기본 false 본안, 소유 구간 드래그에만 적용).

**경과**: t43-ui가 편집 완료 직후 API 429(주간 한도)로 중단 — 아래 대조는 오케스트레이터가 직접 돌려 완료했다.

### 2.5.1 오케스트레이터 직접 대조(원문)

```text
$ grep -c 'minActivityMinutes: CGFloat = 5$' / ' = 20' / 'minTravelMinutes: CGFloat = 16' Shared/ContentView.swift
1 / 0 / 1
$ grep -c 'ForEach(0..<24' / '24 \* hourHeight' Shared/ContentView.swift
0 / 0
$ awk '/private func offsetY/,/^    }$/' Shared/ContentView.swift | shasum
2cd32a58b96328d29f74bde60f15579cd581b3b4  -      ← git show b59fcaa 같은 꼴과 동일
$ awk '/private func finalizeDrag/,/^    }$/' Shared/ContentView.swift | shasum
3027e8ee6676bf96d0062dafbab4ab00598db5c1  -      ← git show b59fcaa 같은 꼴과 동일
$ AC-007 묶음(범위 확인) span(activity)·span(event)·dragOffset(forEvent)·legDragShift·onChange·onBegin
35 · 68 · 8 · 5 · 11 · 10 (모두 1 이상)
$ AC-007 금지 패턴(owningActivity): span(activity)·span(event)·dragOffset·legDragShift·onChange → 0·0·0·0·0, onBegin → 1
$ span 소비(legDragShift|activeDrag): 2 · 1 (각 1 이상) · span 비주석 1440: 0 · 0
$ AC-006: awk onChange 범위 | grep -c 'store\.' → 1
$ AC-016: CADisplayLink( → 1 · invalidate() → 1 · handleLongPress 안 stopAutoScroll() → 3(.ended·.cancelled/.failed·onBegin 거절) · dismantleUIView → 1(안에 stop 호출 1) · forMode: .common → 1
$ 드라이버 호스트 컴파일(swiftc, 미실행): error 0
$ xcodebuild … build-exit=0 · BUILD SUCCEEDED 1 · 경고 필터 뒤 0건(.moai/state/verify/t43/m4-build-ios.log)
```

**미확인(〔가설〕 그대로)**: `.scrollDisabled` 중 `setContentOffset` 동작 여부(S-16이 판정 — 대체안 스위치 상수 하나로 전환) · 놓을 때 화면 튀어 오름의 실제 모양(S-17) · 밴드 감각값(S-16) · 5분 블록 실제 탭 가능성(S-18).

## 3. 드라이버 마감 (커밋 `ee8b742`)과 최종 게이트

드라이버: 고쳐 쓰기 4(AF-018-02·03 — 기존 체인 재사용·기대만 교체, AF-015-09 집합 대조·AF-015-11 contains 뒤집기)·AF-015-12 라벨 손질(N5-13, 단언 본문 무변경)·추가 24(AF-018-04~27, 번호 하나 = drvCheck 하나, 하위 사례마다 새 픽스처, `afInjectedLeg`·`ActivityBlock` 직접 주입, 기준일 오늘+60일, AF-018-23 격자 세 픽스처). 구현자(t43-swift) 관측과 오케스트레이터 관측이 독립으로 일치한다.

### 3.1 드라이버 최종(오케스트레이터 관측 원문 — CLAUDE.md 블록 그대로, 로그 `.moai/state/verify/t43/final-driver-orchestrator.log`)

```text
$ /tmp/gd > …/final-driver-orchestrator.log 2>&1; echo driver-exit=$?
driver-exit=0
522/522 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
$ grep -c '✗' …/final-driver-orchestrator.log  → 0        (✓ 522)
$ ls -d $TMPDIR/besir-gd-*  → 없음
```

**T = 522 = B + 24 = 498 + 24**(AC-011 1·2). AF ✓ 목록: AF-018-01~27 전원 + AF-015-09·10·11·12. 구현자 중간 경과 1건(첫 실행 520/522 — 본인 단언의 `activities.isEmpty` 조건 오류, 활동 바이트 불변 대조로 수정; 단언 수·번호 무변경)은 보고된 대로 해결됐고 최종 522가 그 위에서 관측됐다.

### 3.2 최종 게이트(오케스트레이터 관측 원문)

```text
$ git diff --name-only b59fcaa -- Shared Tools proxy project.yml
Shared/ContentView.swift
Shared/Store.swift
Tools/GuardDriver.swift                                   (AC-011 4 — 소스 3파일)
$ git status --porcelain -- Shared Tools proxy project.yml → (마감 커밋 뒤 빈 줄 0건)
$ git diff b59fcaa -- Tools/GuardDriver.swift | grep '^+' | grep -c 'addRecurringEvents\|await store.addEvent'
0                                                          (AC-011 3 — 결정성)
$ ls Shared | wc -l → 27                                   (AC-011 4 — 새 파일 없음)
$ xcodebuild … build-exit=0 · BUILD SUCCEEDED 1 · 경고 필터 뒤 0건   (AC-011 5 — 무경고, 로그 final-build-ios-orchestrator.log)
$ grep -c 'addingTimeInterval(-' Shared/Store.swift → 5    (AC-010 — 기준 5, 증가 0)
$ awk 'Coordinator 범위' | 주석 제외 grep -c 'while\|Task {' → 0   (AC-016 — 맨 grep 1은 "while을 두지 않는다" 규칙 설명 주석)
$ ls -d $TMPDIR/besir-gd-* → 없음                          (AC-011 6)
```

해시 대조(`moveActivity` ab65d72c…·`realignReturnLeg` a6ca6f17…·`offsetY` 2cd32a58…·`finalizeDrag` 3027e8ee…)와 AC-004·006·007·013·015·016 구조 대조는 §2·§2.5의 원문 그대로 마감 트리에서 유효하다(그 사이 소스 변경은 GuardDriver뿐).

### 3.3 code-safety 판정(t43-safety, 2026-10-08) — **PASS(차단 0)**

8개 렌즈 전수. 요지: await 인덱스 0 · 묻힘 0 · 무한/멈춤 0(CADisplayLink 시작 1곳·종료 6경로 전부 stopAutoScroll 도달 실측) · 강제 언래핑 0 · 경계 주의 1건(아래) · 복제 계산 0 · 루프 안 저장 0. 판정자가 드라이버를 독립 재실행해 522/522·exit 0을 재확인했고 단언 게임화 흔적 없음을 봤다.

- **[5-1 주의 — 잔여 위험로 기록]** 드래그 중 비동기 갱신(전경 복귀 직후 재추정 등)이 끌리는 구간을 고치면 미리보기 Δ만 옛 사본 기준으로 한시적으로 어긋난다 — 드롭은 id 재읽기로 항상 현재값이라 **확정은 올바르다**. 수리는 AC-007(onBegin 1회 원칙)과 상충해 기록으로 둔다 → `plan.md` §7 잔여 위험에 반영 완료.
- [정보] stopAutoScroll의 0.1초 클램프 타이밍은 S-17 관측 항목 · 회차 루프 안 개별 알림 재예약은 기존 `moveActivity` 패턴이고 최종 `rescheduleNearestNotifications` 1회가 규범화(후속 정리 후보) · `minTravelMinutes` 확대 3줄 두 갈래 반복은 주석 상호 지목 유지 · `usesPanLockFallbackForOwnedLegDrag`는 S-16 통과 시 후속 카드 제거 대상.

### 3.4 못 한 것(Gaps) · 잔여 위험

- **시뮬레이터·실기기 관측 전무** — S-1~S-11·S-13·S-14·S-16~S-18은 운영자 몫(AC-012). 특히 S-16(`scrollDisabled` 중 프로그램 스크롤 〔가설〕 — 대체안 스위치 `usesPanLockFallbackForOwnedLegDrag` 상수 하나로 전환), S-17(연장 축소 시 오프셋 클램프), S-18(5분 블록 탭).
- code-safety가 재실행하지 않은 것: iOS 무경고 빌드(오케스트레이터 §3.2 관측으로 대체)·5-1의 실행 재현(경로만 코드 실증).
- 구글 반영 없음(카드 t48)·활동 끝 편집 추정 복귀 갭(t49)·옛 틈 회차 연결 상실(t50) — 결정된 수용 위험 그대로.
- spec §6의 루트 문서 수리(CHECKLIST K13·D8·K7·`:313`, 루트 `plan.md:190`·하한 줄, `Models.swift:391`(기록만), 드라이버 AF-018 머리 주석, `Store.swift:520`)는 **sync 몫**(plan §6) — 이 run은 SPEC 문서만 고쳤다.

## 5. 수리 라운드 fix1 (시작 183e07f — 리드 지시서 `.moai/reports/t43/fix1-brief.md`, sync 증거 `sync-verdict.md`)

배정: ①③ ui-design(t43-ui-fix1) · ② swift-impl(t43-swift) · 문서·게이트·증거 오케스트레이터 · 재판정 code-safety(t43-safety). 경과: t43-ui-fix1가 이번엔 429 없이 완주했다.

### 5.1 ① 자동 스크롤 띠 좌표·속도 상한(sync §3.1 차단) — 커밋 `954bb68`

`autoScrollTick`: `fingerY = gr.location(in: scroll).y - scroll.contentOffset.y`(보이는 창 기준 — UIScrollView의 bounds 원점 = contentOffset이라 location(in: scroll)은 콘텐츠 좌표, 틀린 주석 교체) · 두 띠 모두 `min(max(speed, ±autoScrollMaxSpeed))` 상한 · `AutoScrollProxy.tick` target nil이면 `link.invalidate()`.

**좌표 하네스 원문 출력**(sync의 scrollcoord.swift를 확장 — 옛 식과 고친 식 나란히, Mac Catalyst 실제 UIScrollView 점 변환, 소스·출력 `.moai/state/verify/t43/fix1/scrollcoord-fix1*.swift·txt`):

```text
offset=0.0 visibleY=-30.0 inScroll=-30.0 band=72.0 old=  -850.0 new=  -600.0
offset=0.0 visibleY=10.0  inScroll=10.0  band=72.0 old=  -516.7 new=  -516.7
offset=0.0 visibleY=300.0 inScroll=300.0 band=72.0 old=     0.0 new=     0.0
offset=0.0 visibleY=590.0 inScroll=590.0 band=72.0 old=   516.7 new=   516.7
offset=448.0 visibleY=-30.0 inScroll=418.0 band=72.0 old=     0.0 new=  -600.0
offset=448.0 visibleY=10.0  inScroll=458.0 band=72.0 old=     0.0 new=  -516.7
offset=448.0 visibleY=300.0 inScroll=748.0 band=72.0 old=  1833.3 new=     0.0
offset=448.0 visibleY=590.0 inScroll=1038.0 band=72.0 old=  4250.0 new=   516.7
```

offset 0은 양성 대조(옛 식 = 새 식), offset 448에서 가운데 손가락 0 · 아래 가장자리 516.7 ≤ 600 · 위쪽 띠 작동 · 영역 밖(−30)은 ±600 클램프 — 브리프의 세 조건 모두 관측. 앱 코드의 식이 이 하네스의 new 열과 일치함을 diff로 확인.

### 5.2 ③ 활동 span 분 단위(sync §4.1) — 같은 커밋 `954bb68`

start·end를 `(timeIntervalSince(dayStart)/60).rounded(.down)`로 초를 내려 분 단위로, 길이 = end − start(저장·드래그 경로 공통). 초가 0이면 내림이 항등이라 기존 값 불변(항등 논증 주석 명시). 산술: 10:00:00–11:00:00 → (600, 60) 불변 · 10:00:30–11:00:30 → (600.5, 60) → (600, 60) — 반폭 분할 회귀 해소.

### 5.3 ② 출발 없는 복귀 구간의 짝(sync §3.2 회귀) — 커밋 `8bb15cf`

`private extension ScheduledEvent { anchorComparisonTime }`(Store.swift 파일 끝, 출발 기준 `departureDate ?? arrivalDate` · 도착 기준 `arrivalDate`)이 estimatedLegs 출발 대조·owningActivity 동률 필터 두 곳을 함께 읽는다(계산 한 곳 — 도착 갈래 불변). 드라이버: AF-018-21b 재작성(arrival ≠ 끝이면 소유 없음) + **AF-018-29** 양성 대조(출발 nil 복귀 → 소유·묶음·활동 +30에 arrival +30·departure nil 유지 — 28은 t48 인계 번호라 건너뜀) → **T = B + 25 = 523**. shiftEvent 확인: departure는 `if let` 안에서만 움직이고 arrival은 항상 움직여 nil이 유지된다 — AF-018-29가 실행으로 입증.

### 5.4 게이트(오케스트레이터 관측 원문)

```text
$ 드라이버(CLAUDE.md 블록, 로그 .moai/state/verify/t43/fix1/driver-fix1-orchestrator.log)
driver-exit=0 · 523/523 통과 · [실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
✗ 0 · AF-018-29 라벨 1회 · ls -d $TMPDIR/besir-gd-* → 없음      (네트워크성 실패 없음 — 1회 실행)
$ xcodebuild … build-exit=0 · BUILD SUCCEEDED 1 · 경고 필터 뒤 0건 (build-fix1-orchestrator.log)
$ awk moveActivity → ab65d72c40fb86a311fe8b9eabe27d7a96d3a758  (b59fcaa와 동일)
$ awk realignReturnLeg → a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d  (동일)
$ git diff --name-only 183e07f → Shared/ContentView.swift · Shared/Store.swift · Tools/GuardDriver.swift + SPEC 문서 4종(0.7.3)
$ 인용 대조 python3 -I …/sync/check.py …/fix1/checklist-diff.txt . → 인용 22건(중복 제거 18) 전부 심볼 일치 + 양성 대조 작동
```

재번호(28→29) 뒤 구현자 재검증도 523/523·exit 0(로그 `driver-fix1-renumber.log`, 바이너리 /tmp/gd2). 그 첫 실행 한 번은 exit=1이었는데 오케스트레이터 게이트가 같은 `/tmp/gd` 경로를 동시에 재컴파일한 탓(두 로그의 같은 시각 대조) — 바이너리·로그 경로를 갈라 재실행한 위 두 결과가 깨끗한 관측이다. 커밋 `8bb15cf` 안 "AF-018-28" 문자열 0건·"AF-018-29" 3건(git show 확인).

### 5.5 문서(SPEC 0.7.3 · CHECKLIST)

SPEC 0.7.3(미감사): REQ-004·REQ-016 대조 시각 문구 · §0 단언 수(고쳐 쓰기 5·추가 25)·REQ-013(T = B + 25, 04~27·29)·plan §5·D-10 표·research §10 표(생성 시 첫 회차 추정 실패 행)·AC-015 G(`anchorComparisonTime` 대조로)·AC-011·AC-015 D. CHECKLIST: K13 ✅ → **⚠️**(화면 미관측 + sync 차단 수리 뒤 S-16 확인 필요, 드라이버 523/523)·D8·K7·K5·K9 인용 밀림 수리(ContentView +14줄 — `:916/:924`·`:1071-1073`·`:660`·`:882`·`:897`, Store 인용은 불변)·:310/:313 요약 갱신 — check.py 원문 대조 18건 통과.

### 5.6 code-safety 재판정(fix diff 한정) — **PASS(차단 0)** (t43-safety, 2026-10-08)

범위 `git diff 183e07f..HEAD -- Shared Tools`(954bb68·8bb15cf). ① 좌표 보정·대칭 클램프·proxy 무효화 전부 정확(되먹임 경로 소거, 기존 6경로 약화 없음 — 일곱째 안전망) · ② `anchorComparisonTime`이 정확히 두 곳만 쓰이고 도착 갈래 불변(전수 grep), AF-018-21b 재작성은 게임화 아님(불성립 픽스처 + 29 양성 대조 분리), `realignLegs`의 날것 비교를 안 고친 것이 맞음(명시 연결 전용·바이트 불변 판정)까지 확인 · ③ 분 내림 항등성·30초 조각 최소 높이 유지 확인 · 신규 async/force 0건. 판정자가 드라이버를 재컴파일·재실행해 523/523·exit 0 재확인. [정보 6-1] 앵커 시각 선택 규칙이 `anchorComparisonTime`(Store)과 `failedBlockAnchor`(Models)에 같은 3줄로 두 곳 — 의미가 다르고 주석이 서로를 지목하므로 의도적 분리, 기록만. 못 한 것: 판정 시점에 fix1-brief.md가 이 트리에 없어 sync-verdict 원문으로 판독(→ 이번 커밋에서 브리프를 워크트리에 보존함) · S-16 화면 재관측(운영자 몫) · 빌드·해시·하네스는 오케스트레이터 관측 인용.
