# SPEC-UIKIT-009 — research.md

> 이 문서는 세 렌즈 보고서의 요약과 **이 세션이 다시 잰 것**, 그리고 렌즈·오케스트레이터의 방향과 **어긋난 자리**의 기록이다. 본문을 렌즈에서 옮기지 않고 절 번호로 인용한다.
> 결정 기록은 `plan.md` §2에 있다(0.1.1에서 모두 해소). 여기서는 결정을 새로 만들지 않고 근거만 적는다.
> 기준 트리 `b2c3987`(브랜치 `WT-edit-card-unify`). 렌즈: 데이터·Store `.moai/reports/t17/plan-lens-data-store.md`(이하 **데이터 렌즈**) · 편집 화면·생성 카드 문법 `plan-lens-ui-edit-surfaces.md`(**UI 렌즈**) · 시간표 배치 `plan-lens-timeline-overlap.md`(**타임라인 렌즈**).

## 1. 방법과 신뢰 수준

- 렌즈 보고서의 `[재측]` 표지는 **오케스트레이터가** 잰 것이다. 이 세션은 그 표지를 믿지 않고 요구사항·수락 기준이 기대는 좌표를 전부 다시 쟀다(§3). 다시 재지 않은 좌표는 이 SPEC에 쓰지 않았다.
- "코드 열람"으로만 얻은 결함 주장(장소를 못 지움 · 끝 ≤ 시작 재정렬 · 일괄 삭제 무연쇄 · 제목·장소 변경이 구간에 안 미침)은 **가설**이다. 실행으로 재현하지 않았고 REQ-020이 재현을 수리보다 먼저 두게 한다.
- 이 세션은 어떤 빌드·드라이버·시뮬레이터도 실행하지 않았다. 드라이버·빌드 수치는 오케스트레이터가 같은 트리에서 남긴 로그를 읽은 것이다(§3 표 34·35).

## 2. 렌즈 요약

| 렌즈 | 핵심 발견(절) | 이 SPEC에서의 자리 |
|---|---|---|
| 데이터 | 연결은 구간 → 활동 한 방향 포인터이고 역할은 `anchor`(§1·§2) · 연결을 거는 길은 `addActivityWithTravel` 하나(§1) · 시간을 고쳐도 연결 필드는 산다, 끊기는 것은 결합(§1) · 낱개 삭제는 연쇄하고 일괄은 안 한다(§3) · 비-Optional 필드는 조용한 전체 손실(§2) · 구글 왕복은 링크를 안 싣는다(§2) | REQ-002·003·005·006·008·009·012·019 · 범위 밖 |
| UI | 공유 카드 호출 4곳(§머리 정정) · 구간 줄 문법은 `AddActivityView` 로컬(§1·§4) · 활동↔구간을 잇는 UI 경로 없음(§1 3) · 이동 편집은 `AddEventView`가 활동을 모르는 채로(§5·§8 (a)) · `EventDetailView`의 같은 제목 삭제(§2) · 편집이 들어갈 자리 후보 셋(§10 1) | REQ-001·007·011·013 · 결정 D-1·D-2 |
| 타임라인 | 배치는 연결을 읽지 않고 `<=`가 맞닿은 구간과 활동을 다른 무리로 나눈다(§0·§1·§2) · 렌더는 간격 3 pt를 넣고 히트테스트는 안 넣는다(§1) · `ContentView`만 고치면 된다(§5) · 드라이버가 못 컴파일한다(§6) · 안 A·B·C(§4) | REQ-015~018 · 결정 D-6·D-7 |

## 3. 이 세션의 재측정 — 명령과 관측 출력

명령은 워크트리 루트에서 돌렸다. 출력은 관측한 그대로다(길면 줄였다).

| # | 명령 | 관측 출력 | 쓰인 곳 |
|---|---|---|---|
| 1 | `git rev-parse --short HEAD` · `git branch --show-current` · `git status --short` | `b2c3987` · `WT-edit-card-unify` · `?? .moai/reports/t17/`(그 밖의 변경 없음) | 기준 트리 |
| 2 | `wc -l .moai/reports/t17/*.md` | 데이터 106 · 타임라인 87 · UI 129 | 렌즈 규모 |
| 3 | `wc -l Shared/*.swift Tools/*.swift` | ContentView 980 · Store 1499 · AddEventView 781 · AddActivityView 630 · EditCardView 538 · Models 513 · ActivityDetailView 444 · EventDetailView 430 · EditCard 356 · AIAssistant 3174 · GuardDriver 3474 | spec §0 |
| 4 | `ID="SPEC-UIKIT-009"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` · `ls .moai/specs \| grep -c SPEC-UIKIT-009` | `PASS` · `0`(중복 없음) | frontmatter `id` |
| 5 | `grep -rn linkedActivityId Shared ShareExtension Tools proxy \| wc -l` | `18` (Models:190 · Store:179·217·225·334·368·374·581·591·1120 · AIAssistant:2038·2057·2826 · ContentView:651 · AddActivityView:8 · GuardDriver:922·955·1437) | spec §0 |
| 6 | `grep -c "activities\|ActivityBlock\|activityId\|linkedActivityId" Shared/AddEventView.swift Shared/EventDetailView.swift` | `0` · `0` | REQ-001 |
| 7 | `grep -rn "EditCardView(" Shared` | `AIChatView:110` · `AddEventView:68` · `ActivityDetailView:64` · `AddActivityView:72` — 4줄 | spec §0 (렌즈 "5곳" 정정) |
| 8 | `grep -c 'private func legToggleRow\|private func outboundRows\|private func returnRows\|private func notifyToggleRow\|private func notifyLeadRow' Shared/AddActivityView.swift` · `grep -c "fields.insert\|fields.removeAll\|fields.remove(" …` · `grep -c "@State" …` · `grep -c 'private func\|private var\|private static\|private let' …` | `5` · `11` · `18`(뷰 15 + `PlaceField` 3) · `50` | REQ-007 |
| 9 | `grep -n "remembered\|lastNotify" Shared/AddActivityView.swift`에서 `@State`만 | `9` | REQ-007 |
| 10 | `grep -rn "addActivityWithTravel(" Shared` | `FullSirView:463` · `AddActivityView:523` · `AIAssistant:2005` | design §5 |
| 11 | `grep -rn "\.conflicts(" Shared` · `grep -n "isSamePlace(" Shared/AIAssistant.swift` · `grep -c isSamePlace Shared/AddActivityView.swift` | 4줄(`AddEventView:692` · `AIAssistant:1803·2042·2849`) · 6줄(`:1085·1348·1779·1968·2192` + 정의 `:2917`) · `0` | D-4·D-9 |
| 12 | `grep -rn "AddEventView(" Shared` | `ContentView:151`(`AddEventView()` 생성) · `EventDetailView:92`(`AddEventView(editing: event)`) | REQ-001 |
| 13 | `grep -n "CodingKeys\|init(from\|func encode" Shared/Models.swift` | 무출력 | F11 |
| 14 | `sed -n 1487,1499p Shared/Store.swift` · `sed -n 393,397p …` | `load()` `:1494-1498`(guard `:1495-1496`) · `loadActivities()` `:393-397`(guard `:394-395`) | F11 |
| 15 | `awk 'NR>=1065 && NR<=1171' Shared/Store.swift \| grep -c "enqueueCalendarUpload\|removeFromCalendar"` · `awk 'NR>=572 && NR<=610' …` · `awk 'NR>=945 && NR<=992' …` | `0`(이동·드래그) · `1`(addEvent) · `2`(updateEvent) | F12·D-10 |
| 16 | `grep -c "linkedActivityId\|anchor" Shared/GoogleCalendarService.swift` | `0` | F12 |
| 17 | `grep -n "linkedActivityId" Shared/Store.swift \| awk -F: '$1>=628 && $1<=695' \| wc -l` (범위는 `grep -n '    func ' Shared/Store.swift`로 잰 `addRecurringEvents` `:628` ~ 닫는 괄호 `:695`(다음 함수 `recurringSeries` `:698`) — 0.1.1에서 REQ-011과 같은 측정으로 맞췄다, review-1 D13) | `0` — 반복 생성 함수 안에 `linkedActivityId`가 없다 | REQ-011 · D-8 |
| 18 | `grep -n "gap \* CGFloat\|1 / CGFloat(p.columns)\|p.columns" Shared/ContentView.swift` | `:746` · `:748` · `:764` · `:765` | REQ-016·AC-016 |
| 19 | `grep -n "private func span(for\|private func positionedBlocks\|private func columnFrame\|private func block(atX\|private struct PositionedBlock\|minActivityMinutes: CGFloat\|minTravelMinutes: CGFloat\|failedBlockHeight: CGFloat\|hourHeight: CGFloat" Shared/ContentView.swift` · `grep -n "struct SwipePager"` | `:542`·`:557` · `:699` · `:745` · `:759` · `:683` · `:533` · `:534` · `:536` · `:37`(56) · `:799` | design §6 |
| 20 | `sed -n 527,585p Shared/ContentView.swift` | 실패 블록은 도착 시각에서 아래로 `failedBlockHeight / hourHeight × 60` = 20/56×60 ≈ 21.4분(`:557-563`) | F10 — 렌즈에 없던 자리(§4) |
| 21 | `sed -n 640,680p Shared/ContentView.swift` · `grep -n showsTitle Shared/ContentView.swift` | 연결된 구간은 제목 숨김 `:651`(`showsTitle`), 실패 블록은 제목을 그린다 | REQ-006 |
| 22 | `sed -n 318,395p Shared/EventDetailView.swift` · `grep -n "sameTitleEvents" Shared/EventDetailView.swift` · `grep -cF 'store.events.filter { $0.title == event.title }' …` | `sameTitleEvents` `:331-333`, 사용 `:356`·`:368`·`:373`(4줄) · 리터럴 `:332` 1 | REQ-013·AC-013 |
| 23 | `sed -n 82,96p Shared/EventDetailView.swift` | 편집 단추 `:88`, 시트 `:91-92` | REQ-001 |
| 24 | `sed -n 301,330p Shared/Store.swift` | nil 장소 `:321` · 끝 ≤ 시작 거절 `:322` · 재정렬 `:326-328` | REQ-005 |
| 25 | `grep -rn "updateActivity(\|realignReturnLeg(\|linkedLegs(" Shared` | `updateActivity` 호출 `Store:323` 하나 · `realignReturnLeg` `:327` 하나 · `linkedLegs` `:1075` 하나 | 범위 밖 |
| 26 | `grep -n "종료는 시작보다 뒤여야" Shared/*.swift` | `AddActivityView:391·406` · `ActivityDetailView:227·242` | REQ-005 근거 |
| 27 | `sed -n 1,14p Shared/NotificationManager.swift` · `sed -n 28,48p …` | `center`는 번들 식별자가 없으면 nil(`:10-14`) · `schedule` 선언 `:32`, `center`가 nil이면 nil `:33`, 과거 시각이면 nil `:34` | AC-007 (8) 한계 |
| 28 | `sed -n 15,40p Shared/DirectionsService.swift` · `grep -n "var directions" Shared/Store.swift` | `struct DirectionsService`, `Store.directions`는 호출마다 새로 만드는 계산 속성(`:491`) — 드라이버가 갈아 끼울 자리가 없다 | AC 결정성 |
| 29 | `sed -n 28,34p Tools/GuardDriver.swift` | `drvCheck` `:30` · ✓ `:31` · ✗ `:32` | 단언 이름 규칙 |
| 30 | `grep -o "<파일>\(\.swift\)\{0,1\}:[0-9]\{1,4\}" CHECKLIST.md plan.md \| wc -l`(파일마다) | CHECKLIST: Store 39 · ContentView 5 · ActivityDetailView 1 · EventDetailView 1 · AddActivityView 2 · AddEventView 6 · EditCard 3 · Models 6 · GuardDriver 1 / 루트 plan.md: Store 4 · AddActivityView 9 · AddEventView 6 · EditCard 3 · ActivityDetailView 2 · Models 1 · 나머지 0 | REQ-021(하한) |
| 31 | `sed -n 105p plan.md` | t5가 "나중에 UI에서 쓸 것"을 죽은 코드 보존 사유로 거절 | D-9 |
| 32 | `grep -n "일정 모두 삭제" Shared/SettingsView.swift` · `grep -n "활동 추가\|이동 일정 추가" Shared/ContentView.swift` | `SettingsView:78` · `ContentView:228-229` | 스크립트 문구 |
| 33 | `grep -n "^8\. \*\*U-1" CHECKLIST.md` | `:538` | REQ-021 |
| 34 | 오케스트레이터 로그: `grep -c '^  ✓ ' driver-run.log` · `grep -c '^  ✗ ' …` · `tail -3 …` | `357` · `0` · `357/357 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · `run_exit=0` | 기준선 |
| 35 | 오케스트레이터 로그: `grep -c '^SwiftCompile' ios-build.log` · `grep -n "BUILD SUCCEEDED" ios-build.log` · `grep 'warning:' ios-build.log \| grep -v 'Metadata extraction skipped' \| wc -l` · `grep -c 'warning:' ios-build.log` · `grep -c 'warning:' driver-compile.log` (0.1.3에서 이 세션이 다시 셈) | `42` · `:944` · `0` · `2`(툴체인 안내뿐) · `24` — 0.1.3부터 빌드 기준선은 iOS 하나다(`plan.md` §2 P-1). 방침 전의 다른 로그 값은 기준이 아니며 `progress.md` §E.1에 역사 관측으로만 한 줄 남겼다 | 기준선 |
| 36 | `grep -n departureDate Shared/*.swift` · `grep -n travelSeconds Shared/*.swift` (0.1.1) | 읽는 곳·쓰는 곳 전부 — 요약은 §4 13 | REQ-023 · D-14 |
| 37 | `sed -n 994,1036p Shared/Store.swift` · `sed -n 505,583p Shared/ContentView.swift` (0.1.1) | 도착 기준 실패: `:999`·`:1000` 둘 다 nil, guard `:1006` / 출발 기준 실패: `:1024` nil, `:1025` 출발 대입, guard `:1031`, 도착 대입 `:1033` / 블록 선택 `:511` · 실패 분기 `:558` · 출발 고정 최소 높이 `:580` | REQ-010 · REQ-023 |
| 38 | `sed -n 1118,1131p Shared/Store.swift` · `grep -n linkedLegs Shared/*.swift Tools/GuardDriver.swift` (0.1.1) | 명시적 우선 `:1120-1124` · 추정 `:1126-1130`(같은 날 `:1128`, 장소 이름 `:1129-1130`) · 호출 `moveActivity` `:1075` 하나(+ `Models.swift:189` 주석) | REQ-015 · D-8 (b) |
| 39 | `sed -n 189,230p Shared/Store.swift \| grep -c travelSecondsHint` (0.1.1) | `0` — `addActivityWithTravel`에는 힌트 인자가 없다 | AC-018 Given (review-1 D5) |
| 40 | `git log --oneline -S 'var travelSeconds: TimeInterval?' -- Shared/Models.swift` · 같은 명령으로 `departureDate` (0.1.1) | 둘 다 `d3c9327 최초 커밋` 한 줄 | `plan.md` §3 (저장소 이전 데이터는 확인 불가) |
| 41 | `grep -c 'e.departureDate != nil' Shared/ContentView.swift` · `grep -c 'columnEnds' Shared/ContentView.swift Shared/Models.swift` · `grep -c '반복 일정의 한 회차입니다' Shared/ActivityDetailView.swift` · `awk '/^enum ScheduleAnchor/,/^}/' Shared/Models.swift \| grep -c 'case '` (0.1.1) | `1` · `8` / `0` · `1`(`:68`) · `1` | AC-010 (9) · AC-016 (2) · AC-011 (4) · AC-019 (4) 기준값 |
| 42 | `awk 'NR>=80&&NR<=100' Shared/ContentView.swift` · `awk 'NR>=500&&NR<=660' …` (0.1.2) | 나열 `events(on:)` `:87-95`(guard `:89`, 도착일 폴백 `:90`, `overlapsDay` `:92`, 주석 "출발시각이 없는(계산 실패) 일정은 … 도착일에만" `:85-86`) · 블록 선택 `:511` · 실패 분기 `:558-561`(주석 "실패 블록은 도착일에만 나열되므로" `:560`) · 자르기 `:567-571` · 출발 고정 최소 높이 `:580` · `failedEstimateBlockView` `:627-642`(높이 `:637`) | REQ-023 · review-2 D14 |
| 43 | `awk 'NR>=990&&NR<=1040' Shared/Store.swift` · `awk 'NR>=1240&&NR<=1282' …` · `grep -n refreshUpcomingEstimates Shared/*.swift` (0.1.2) | 출발지 guard `:1001`·`:1026`과 추정 실패 guard `:1006`·`:1031` 사이에는 추정 호출뿐 · 재추정 대상 `:1251-1254` · 출발 기준 재추정 `:1263-1264` · 호출 `App.swift:25`(백그라운드 작업)·`:101`(활성화) | REQ-020 · REQ-023 (다) · AC-010 (10) |
| 44 | `grep -n 'applyEstimate(\|applyDepartureAnchoredEstimate(\|applyCached' Shared/Store.swift` · `awk 'NR>=640&&NR<=690'` · `awk 'NR>=740&&NR<=772'` (0.1.2) | 호출 `:600`·`:601`·`:664`·`:673`·`:750`·`:759`·`:975`·`:976`·`:1261`·`:1264`·`:1400` · 반복 첫 회차 캐시 `:665`·`:674`, 뒤 회차 `else if let` `:667`·`:676` · 생성자 `:656-658` · 반복 묶음 수정 `:757-759` | REQ-023 (가)~(라) |
| 45 | `awk 'NR>=120&&NR<=175' Shared/Store.swift` · `grep -n 'daysWithSchedule\|overlapsDay\|departureDate' Shared/*.swift` (0.1.2) | 달력 점 `recomputeDaysWithSchedule` `:132-150`, 나열 판정의 사본 `:136`(`if let dep = e.departureDate, e.arrivalDate > dep`) · 계약 주석 `:32-37` · `dayKeys` `:157-172` | REQ-023 점 절 · AC-010 (13) |
| 46 | `grep -c 'e.arrivalDate > dep' Shared/ContentView.swift Shared/Store.swift` · `grep -c 'failedBlockAnchor\|isListed(on:' Shared/*.swift` (0.1.2) | `1` / `1` · 전 파일 `0` | AC-010 (9) 기준값 |
| 47 | `grep -n '전제' Tools/GuardDriver.swift` · `grep -n '전제' .moai/state/verify/t17-plan/driver-run.log` · `awk 'NR>=979&&NR<=993' Tools/GuardDriver.swift` (0.1.2) | S 전제 `:991` · J 전제 `:1369`(그리고 반복 절 전제 `:667`) / 로그 `:95`·`:150`·`:211` · S절 주석 "실패하면 실행부가 검사를 건너뛴다 … S절이 네트워크 상태에 좌우된다" `:981-985` | REQ-020 · `acceptance.md` 결정성 문단 (review-2 D15) |
| 48 | `awk 'NR>=154&&NR<=212' Shared/Models.swift` · `awk 'NR>=160&&NR<=230' Shared/GoogleCalendarService.swift` (0.1.2) | `origin: Place?` `:158`(주석 "옛 일정은 nil일 수 있음" `:157`) · 구글 가져오기 `parse`는 `departureDate`·`travelSeconds` 없이 생성(`:216-224`) → 동기화가 `applyEstimate`를 부른다(`Store.swift:1400`) | AC-010 (10)의 출발지 nil 경로 · REQ-023 (가) |
| 49 | `awk 'NR>=1115&&NR<=1132' Shared/Store.swift` (0.1.2) | 추정의 같은 날 대조는 `arrivalDate` 기준(`:1128`) — L을 모레로 두면 R의 구간이 L에 대응될 수 없다 | AC-015 Given (review-2 D16) |
| 50 | `git log --oneline -3 master` · `git show --stat 00cd149` · `git show 00cd149:CLAUDE.md \| sed -n 10,12p` · `grep -n "macOS\|양쪽" CLAUDE.md`(이 워크트리) (0.1.3) | 맨 위 `00cd149 docs: iOS 전용 전환 — 맥 빌드·검증 중단, 코드는 보존 (운영자 지시 2026-09-30, card t38)` · `CLAUDE.md \| 9 +++++++--` · 방침 원문 세 줄 · 이 워크트리 판에는 맥 빌드 명령 `:53`과 "iOS·macOS 양쪽 **무경고** 빌드" `:121`이 남아 있다 | 방침 P-1 출처 · REQ-019 |
| 51 | `grep -n 'platform:\|- Shared$\|^  besir' project.yml` · `grep -n '#if os\|#else\|#endif' Shared/ContentView.swift` · `grep -rh '#if os' Shared \| wc -l` · `git grep -h -e '#if os' -e '#elseif os' b2c3987 -- Shared \| sed 's/^ *//' \| sort \| uniq -c` (0.1.3) | 맥 타깃 `:89`(`platform: macOS` `:91`, `- Shared` `:93`) · `ContentView`의 `#if os` `:2`·`:195`(맥)·`:454`·`:857` · 저장소 전체 37 · `#if os(iOS)` 25 · `#if os(macOS)` 12(`canImport(AppKit)` 0) | REQ-019 근거 · AC-019 (6) 기준값 · `spec.md` §3 받아들인 갭 |
| 52 | AC-019 (6)의 명령을 스크래치 사본에 돌림 — 기준 목록 대 `HEAD` 목록 · 한 줄 지운 사본 · `#if os(macOS)`를 더한 사본 · `#if os(iOS)`를 더한 사본 (0.1.3) | `0` · `1` · `1` · `0` | AC-019 (6) 양성 대조 |

## 4. 렌즈·오케스트레이터의 방향과 어긋난 자리

1. **`isSamePlace` 사용처.** 데이터 렌즈 §4 (b)는 사용처를 `:1348`·`:1779`·`:1968`·`:2192` 넷으로 적었다. 측정은 다섯이다 — `:1085`(`!isSamePlace(taken, place)`, `Self.` 없는 호출)가 더 있다(표 11). D-4 (b)의 영향 범위가 한 곳 는다.
2. **`NotificationManager.swift:21`.** 데이터 렌즈 §6 10은 과거 출발 알림 생략을 `NotificationManager.swift:21`로 적었다. `:21`은 `bootstrap()` 안이다. 생략은 `schedule` 안(`:32` 선언, 과거 시각 가드 `:34`)이고, 더 중요한 것은 **드라이버에서는 `center`가 늘 nil**(`:10-14`, 비번들 실행)이라 알림이 항상 nil이라는 점이다 — "과거 출발 알림 생략"은 드라이버로 관측할 수 없다(AC-007 (8)의 한계).
3. **`addActivityWithTravel` 범위.** 타임라인 렌즈 §3은 `:179-236`, 데이터 렌즈는 `:189-230`이다. 측정: 문서 주석 `:176-188`, 함수 `:189-230`. 뒤엣것을 썼다.
4. **`ScheduleLogic` 자리.** 타임라인 렌즈 §6은 `Models.swift:~207`이라 적었다. 측정 `enum ScheduleLogic` `:213`.
5. **`@State` 수.** UI 렌즈 §4는 "18개, private 49개"라 적었다. `@State` 18은 파일 전체 값이고(뷰 15 + `PlaceField` 3, 표 8) private 선언은 50이다. 결론(기억값 9)은 같다.
6. **오케스트레이터의 "묶음을 한 묶음으로 packing"** — 타임라인 렌즈 안 A는 "묶음의 최소 높이 처리"만 적고 **묶음 구성원끼리 겹치는 경우**를 다루지 않는다. 측정하니 셋이다: 최소 높이(`:533-534`) · **이동시간 계산 실패 블록이 도착 시각 아래로 자라 가는 편이 활동 시작 위로 겹침**(`:557-563`, 표 20 — 렌즈에 없던 자리) · 끌어 들인 구간. 그래서 안 A는 안쪽 배치를 갖는다(design §6.2, REQ-017).
7. **오케스트레이터의 "시간은 유도라서 시간 수정이 무엇도 분리할 수 없다"** — 카드 UI 경로에서는 참이지만 세 곳에서 약하다. ① AI 경로의 `modifyEvent`는 `updateEvent`를 그대로 불러(`Store.swift:356`) 결합을 계속 끊는다 — 이 카드가 고치지 않는다(범위 밖 첫 절). Store 안에서 `updateEvent`가 연결된 구간의 시간을 활동에서 다시 유도하게 하면 AI 경로도 닫히지만 AI가 "바꿨어요"라 말한 시각이 조용히 무시되는 새 거짓이 생긴다 — 택하지 않았다(`plan.md` §6). ② 유도는 **저장 때 바뀐 구간에만** 적용된다 — 드래그로 벌어진 틈(D-6 (a))은 그 구간을 고치기 전까지 유지된다(design §4). ③ 구글에서 가져온 구간은 링크가 없어 유도 대상이 아니다(design §7).
8. **D-9의 권장.** 오케스트레이터는 "짝 제외 입력을 더한다"를 게이트로 냈다. 호출자 4곳(표 11) 중 D-1 (a) 뒤에도 닿는 것은 AI 경로 셋뿐이고 그 셋은 범위 밖이다. 호출자 없는 입력은 죽은 API다 — t5가 "나중에 쓸 것"을 죽은 코드 보존 사유로 거절했다(표 31). 그래서 권장은 (b) 더하지 않음이고 D-1 (a)에 조건부다(`plan.md` §2 D-9).
9. **`AddActivityView` 전환의 파일 수.** 오케스트레이터의 방향은 "활동 카드에 구간 줄을 얹는다"였다. 줄 문법이 뷰 로컬이라(표 8) 활동 카드에 옮겨 적으면 같은 규칙이 두 곳이 된다 — 계약 5 위반이다. 그래서 `AddActivityView`가 공유 문법을 쓰도록 바뀌어야 하고(빌더 5개·`fields.insert/remove` 11자리·기억값 9개를 뺀다), 그 결과 MB의 크게 고칠 파일이 넷이 되어 한도 끝이다(D-11).
10. **활동 카드의 저장은 동기다.** UI 렌즈 §10 1은 "`ActivityDetailView` + 구간 줄이 더 짧은 길"이라 했다. 현재 저장은 동기(`ActivityDetailView.swift:315-330`, `modifyActivity` 뒤 곧바로 `dismiss()`)인데 구간 수정은 이동시간 조회로 `async`다. 그래서 진행 표시·잠금·결과 보고가 필요하다(생성 카드의 `saving` 패턴, `AddActivityView.swift:516-542`) — "짧은 길"이 짧지 않다.
11. **새로 만든 결정 D-13.** 오케스트레이터의 열두 게이트에 "활동 장소·제목이 구간에 미치는 범위"가 없다. 카드가 구간 줄(출발지·도착지)을 보여주는 이상 저장된 구간이 카드가 보인 값과 어긋나면 카드가 거짓말이 된다 — 그래서 D-13을 더했다(`plan.md` §2).
12. **D-12와 REQ-004의 의존.** "장소 없음"으로 구간이 함께 사라지는 REQ-004는 `modifyActivity`가 장소를 지울 수 있어야 성립한다(REQ-005). D-12 (a)가 채택돼 이 의존은 그대로 성립한다.
13. **(0.1.1) `departureDate`는 "추정 성공"의 신호가 아니다 — 역할에 따라 다르다.** 0.1.0의 REQ-010 근거는 "계산 실패는 `departureDate`를 nil로 남긴다"라 적었는데, 이것은 도착 기준(`applyEstimate`, `Store.swift:999-1000`·guard `:1006`)에만 맞다. 출발 기준(`applyDepartureAnchoredEstimate`)은 `:1025`에서 출발을 먼저 대입하고 guard `:1031`에서 빠지므로 실패해도 `departureDate`가 남는다 — 같은 SPEC의 `design.md` §4가 이미 ":1025에서 출발이 추정 앞에 대입된다"고 적어 문서 안에서 서로 어긋났다(review-1 D3, 오케스트레이터가 다시 재어 확인). 이 세션이 `departureDate`를 읽는 곳을 전부 훑은 결과(표 36·37): 성공 판정으로 쓰는 뷰 자리는 `ContentView.swift:511`(블록 선택)과 `:558`(기하의 실패 분기) 둘이고, 나머지는 `travelSeconds`를 함께 보거나(`Store.swift:1224`·`:1152`·`:1178`, `EventDetailView.swift:204`) 날짜 대체값으로 쓰거나(`AddEventView.swift:237`, `GoogleCalendarService.swift:172`) 복구 경로다(`Store.swift:1252`·`:1264` — 실패한 오는 편을 다가올 때 다시 계산한다). 그래서 저장을 바꾸지 않고 판정 하나(`travelSeconds == nil`)를 두 뷰 자리가 함께 읽게 했다(REQ-023, `design.md` §4). `AIAssistant.swift:1846`은 같은 사실을 이미 알고 `travelSeconds != nil`로 판정한다 — 선례이자, 같은 앱 안에 판정이 둘 있었다는 증거다. `AIAssistant.swift:2644`(목록 표지)는 여전히 `departureDate == nil`만 보지만 이 카드 밖이다(`spec.md` §3).
14. **(0.1.1) 반복 회차 추정을 배치에만 쓰는 근거.** 운영자가 "증상이 반복 회차에서도 났다"고 답했다(D-8 (b), 칸반 리드 경유). 추정(`linkedLegs`, 표 38)은 이미 `moveActivity`가 쓰는 코드라 새 추정을 만들 필요가 없고, 같은 코드를 쓰면 "함께 움직이는 구간"과 "함께 줄어드는 구간"이 같은 집합이 된다. 배치는 레코드를 쓰지 않으므로 추정이 틀려도 폭만 달라진다. 편집(REQ-011)과 삭제(REQ-012)에 쓰지 않는 것은 틀린 추정이 레코드를 바꾸기 때문이다 — 특히 삭제는 되돌릴 수 없다. 약점(같은 날 대조 `:1128` · 이름 대조 `:1129-1130`) 중 첫째는 결정적인 예로 고정했다(AC-015 (11)).

15. **(0.1.2) 0.1.1의 REQ-023은 실패 모양을 하나로 봤다(review-2 D14).** 0.1.1은 "실패한 오는 편 = 출발 = 도착 = 활동 끝, `travelSeconds` nil"만 적었다. 이것은 새로 만들거나 고칠 때(`addEvent` `:587`·`:601`, `updateEvent` `:962`·`:976`)만 맞다. 이 세션이 추정 함수의 호출자를 전부 훑은 결과(표 43·44) 모양은 넷이다 — 도착 기준(가), 출발 기준 새로 만듦(나), **출발 기준 재추정 실패(다)** — `refreshUpcomingEstimates`(`:1263-1264`)와 반복 묶음 수정(`:757-759`)이 출발을 두고 옛 도착을 남긴다 — , **반복 뒤 회차(라)** — 첫 회차가 실패하면 뒤 회차가 추정 없이 `departureDate` nil로 저장된다(`:674`·`:676`). 0.1.1의 판정(`travelSeconds == nil`)을 그대로 두면 (다)가 옛 도착 자리에 경고를 그리고, 나열(`ContentView.swift:89-92`)은 `[출발, 옛 도착]`을 보고 실패 분기(`:558-561`)는 날짜로 자르지 않으므로 자정을 넘는 (다)는 출발일 맨 위에 경고가 하나 더 생긴다 — 기준 트리에 없던 회귀다. review-2는 이것을 코드 읽기로 찾았고 오케스트레이터가 다시 읽어 확인했다(실행 아님). **왜 놓쳤나**: 0.1.1은 `departureDate`를 읽는 곳(소비자)을 전수 훑었지만 `applyDepartureAnchoredEstimate`를 **부르는 곳**(생산자)을 훑지 않았다 — 레코드 모양은 생산자가 정한다. 같은 이유로 달력 점(`Store.swift:136`)이 나열 판정의 사본이라는 것도 0.1.1은 잡지 못했다(소비자 목록에는 있었으나 "점과 나열이 같은 말을 한다"는 계약 주석 `:32-37`을 판정 교체의 영향으로 읽지 않았다). 0.1.2의 규칙 — 앵커 시각 하나(출발 기준은 `departureDate ?? arrivalDate`, 그 밖은 `arrivalDate`), 그 날 하루에만 나열, 네 자리가 한 함수를 읽음 — 은 `design.md` §4에 있고, 도착 기준 실패 블록은 이 규칙에서 지금과 한 치도 다르지 않다(A = `arrivalDate`).
16. **(0.1.2) 재추정 실패 모양은 네트워크 없이 닿는다(review-2 D15의 부분 해법).** review-2는 "다섯째 재현은 오프라인에서만 닿는다"고 했고 새로 만든 구간에 대해서는 맞다(`addEvent`의 출발지는 비-Optional, `:573`). 그러나 추정 함수는 저장 필드를 먼저 대입한 뒤 출발지 guard(`:1001`·`:1026`)에서도 빠지고, 그 guard와 추정 실패 guard(`:1006`·`:1031`) 사이에는 레코드를 바꾸는 줄이 없다(표 43). 출발지 nil은 실제 데이터 모양이다(`Models.swift:157-158`). 그래서 드라이버가 출발지 nil 레코드를 넣고 `refreshUpcomingEstimates`를 부르면 (다)·(가) 모양이 결정적으로 남는다(AC-010 (10)). 두 guard가 같은 상태를 남긴다는 것은 **코드 읽기**이고 단언은 출발지 guard 쪽을 탄다 — 추정 실패 guard 쪽의 도달은 여전히 오프라인 실행의 몫이다. 오케스트레이터 지시("오프라인에서만 관측")보다 한 걸음 넓은 해법이라 반환 보고에 적었다.
17. **(0.1.2) 오프라인 실행의 ✗ 집합은 미리 셀 수 없다.** 전제 단언은 둘(`Tools/GuardDriver.swift:991` S · `:1369` J, 표 47)이지만 S절 주석(`:981-985`)은 추정이 없으면 겹침 검사가 건너뛰어진다고 적는다 — S절의 다른 단언도 빨개질 수 있다. 이 세션은 오프라인 실행을 하지 않았으므로 기대 ✗ 집합은 "적어도 두 전제 줄"로만 적었다(`acceptance.md` 결정성 문단).

### 4.1 review-1과 운영자가 0.1.1에서 바꾼 것

| 무엇 | 누가 | 왜 | 어디에 |
|---|---|---|---|
| 결정 13건 해소 | 운영자(칸반 리드 경유 — 이 세션은 답을 직접 보지 않았다) | MP-7 착수 승인 게이트(review-1 D1) | `plan.md` §2 · `progress.md` §E.1 |
| D-8 (a) → (b) | 운영자 | 증상이 반복 회차에서도 났다 | REQ-015·017 · AC-015 (9)–(13) · `design.md` §5·§6 · `spec.md` §3 |
| 오는 편 실패 표시(D-14 (b), REQ-023 신설) | 운영자(review-1 D3의 두 안 중 (b)) | 스크립트 20의 기대가 코드 경로와 반대였다 — 경고를 기대하는 쪽으로 코드를 맞춘다 | REQ-010·020·023 · AC-010 (4)–(9) · 스크립트 13a·20 · `design.md` §4 |
| 카드 범위의 기준 커밋 | review-1 D2 | 직렬 배달에서 고정 기준은 앞 카드 변경을 딸려 온다 | REQ-022 · AC-022 · `plan.md` §5 |
| 통과 수 재계산 | review-1 D4 | AC-001을 빠뜨렸고 grep·갭을 드라이버 하한에 셌다 | `acceptance.md` § 통과 수(0.1.1 당시 98, T ≥ 455 — 0.1.2에서 103, T ≥ 460) |
| AC-018 결정성 | review-1 D5 | 가는 편에 힌트가 없어 `adjustBuffer`가 네트워크에 기댔다 | AC-018 Given |
| 재현 목록 한 벌 | review-1 D6 | REQ-003 근거·REQ-020·AC-020 (5)가 서로 달랐다 | REQ-003 근거(주장 삭제) · REQ-020 · AC-020 (5) |
| lane 정의 · 절별 단언/갭 · 표 단일 출처 · 이진 대리 지표 · 이름표 · 범위 | review-1 D7·D8·D9·D10·D12·D13 | 문서 정합성 | REQ-015 · AC-003·008·011·012 · AC 매트릭스 카드 열 · AC-001·005·016·019 · REQ-009·010 · 표 17 |
| REQ 분할 안 함 | 오케스트레이터 지시(review-1 D11 불채택) | REQ 상한 여유 | — |

### 4.2 review-2(FAIL 0.84, must-pass 전부 PASS)가 찾은 것과 0.1.2의 대응

review-2는 새 문장의 좌표 약 60곳을 다시 재어 어긋남 0건, 통과 수 산술(65·9·24 = 98, 422·431·455)과 REQ→AC 역방향 23행이 맞다고 확인했다. 남은 결함은 0.1.1이 새로 쓴 REQ-023과 그 재현 경로에 몰려 있었다 — review-1과 같은 부류(한 모양·한 날·한 환경에 대해 쓴 규칙이 다른 것을 놓침)다.

| 결함 | 무엇이었나 | 왜 생겼나 | 0.1.2의 자리 |
|---|---|---|---|
| D14 (major) | REQ-023이 재추정 실패 모양을 몰라 옛 도착 자리·자정 넘는 출발일 맨 위에 경고를 그리게 된다 | 소비자만 훑고 생산자를 훑지 않았다(§4 15) | REQ-023 문장·근거 · `design.md` §4 표·규칙·실례 · §6.2·§6.3 E9 · AC-010 (10)–(13) · AC-017 (9) · 경계표 · 스크립트 20b · MC 파일 목록에 `Store.swift`(작게) · 통과 수 103 |
| D15 (major) | REQ-020이 "기준 트리에서 먼저 보인다"를 약속했으나 게이트 실행은 온라인이라 실패 분기에 닿지 않는다 | 드라이버의 전제 단언(S·J)을 읽지 않았다 | REQ-020 문장(세 갈래) · AC-010 (4) 도달 기록 · (10) 결정적 재현 · AC-020 (5) · 결정성 문단과 오프라인 실행 · `plan.md` §5 |
| D16 | AC-015의 L이 R과 같은 날일 수 있어 (9)가 사전의 나중 쓰기에 좌우된다 | 날짜를 적지 않았다 | AC-015 Given(L은 모레) · (9) 기대 반환을 키·값 집합으로 · `design.md` §5 한 줄(같은 날 두 회차는 명세하지 않음 — 갭) |
| D17 | 매트릭스·`plan.md`가 AC-013 (4)를 가리키나 번호가 없었다 | 글머리로 적었다 | AC-013 (4) · 포인터 대조 스크립트(`progress.md` §E.1) |
| D18 (optional, 채택) | 요약본이 D-14를 "권장과 다른 것"이라 했다 | 원문과 다른 요약 | `spec-compact.md` 머리 · `spec.md` §4 |
| D19 (optional, 채택) | AC-024 행에 스크립트 20a·21의 REQ가 없었다 | 스크립트 추가 때 행을 안 고쳤다 | AC 매트릭스 AC-024 · `plan.md` §0 |
| D11 (optional) | REQ 분할 | — | 채택하지 않음(오케스트레이터 지시) |

## 5. 렌즈 밖에서 이 세션이 새로 읽은 것

- **`deleteActivities`의 호출자는 AI 삭제와 테스트용 임시 함수뿐이다**(표 22와 별개: `grep -rn "deleteActivities(" Shared` → `AIAssistant:2909`, `Store:1321`). 연쇄를 더하면 `deleteEverythingForTesting`은 `deleteEvents(events)`를 먼저 부르므로(`Store.swift:1320`) 이미 구간이 없어 두 번 정리하지 않는지 확인해야 한다. 낱개 `deleteActivity`는 식사 정리를 구간 id와 활동 id를 합쳐 한 번 부른다(`:381`) — 일괄은 합집합으로 한 번 불러야 한다(정리 절차를 한 코드로 합치는 이유, design §5).
- **`EventDetailView`의 같은 제목 삭제가 `deleteEvent`를 루프한다**(`:373`). `deleteEvents`(`Store.swift:1287-1300`)가 이미 있다. REQ-013이 그 줄을 바꾸므로 같이 정리할 수 있으나 요구하지 않는다(`plan.md` §6).
- **`AddActivityView.save`는 `addActivityWithTravel`의 반환을 버린다**(`:523` 이후 `saving = false; dismiss()`) — 이동시간 계산 실패는 저장 순간에 사용자가 모른다(REQ-010).
- **드라이버의 결정성 장치**: `Store.directions`는 호출마다 새로 만드는 `struct`라(표 28) 네트워크를 갈아 끼울 수 없다. 그래서 이동시간 힌트를 진입점이 받게 하고(`addEvent`가 이미 받는다), 앵커 쪽 시각은 추정과 무관하다는 사실(`Store.swift:1025`)로 단언한다.
- **`updateActivity`의 바깥 호출은 0이다**(표 25) — 죽은 코드 후보. **지우기 전에 확인이 필요하다**(삭제 영향은 확인하지 않았다).

## 6. 조사하지 못한 것 (증거 없음 ≠ 통과)

- **시뮬레이터·실기기 동작 전부.** 카드가 실제로 어떻게 보이는지, 저장 진행 표시, 탭·드래그의 느낌은 관측하지 않았다(AC-023·024).
- **(0.1.3) 맥 타깃.** 방침 P-1로 이 SPEC은 맥 앱을 빌드·검증하지 않는다 — 이 세션도 하지 않았고 이후 단계도 하지 않는다. `Shared/` 변경이 맥 타깃에 미치는 영향은 받아들인 갭이다(`spec.md` §3 "맥 앱의 빌드와 검증" 절).
- **프록시 `npm test`.** 이 세션도 오케스트레이터도 돌리지 않았다 — 이 SPEC은 프록시를 바꾸지 않는다(AC-019 (1)).
- **`AIAssistant.swift`의 카드 조립 코드.** t30의 몫이라 깊게 읽지 않았다. 줄 키 어휘(`:567-568`)만 확인했다.
- **세 편집 화면의 복사된 장소 검색 도우미**(`searchPlaces`·`choosePlace`·`confirmedPlace` 등)를 바이트 단위로 대조하지 않았다(UI 렌즈도 같다). 활동 카드가 `origin_query`·`return_query` 줄을 처리할 때 그 도우미가 줄 키에 무관하게 동작하는지는 코드를 완전히 읽어 확인하지 않았다 — MB의 B3가 처음 확인한다(가설: 줄 신원 기준이라 무관).
- **`hourHeight`가 배치 함수 입력에 미치는 영향의 실측.** `span(for:on:)`은 뷰에 남으므로 순수 함수는 이미 분으로 환산된 입력을 받는다는 설계를 세웠으나, 실패 블록의 분 환산이 `hourHeight`에 의존하는 것은(표 20) 실행으로 확인하지 않았다.
- **카카오·MapKit 이동시간의 실제 값.** 시뮬레이터 스크립트의 기대는 앵커 쪽 시각만 적었다.
- **(0.1.1) 오는 편 실패의 실제 재현.** 이 세션은 드라이버·시뮬레이터를 돌리지 않았다. REQ-023의 근거는 코드 읽기(표 37·43·44)와 review-1·review-2·오케스트레이터의 같은 읽기다. 새로 만든 구간의 드라이버 재현은 추정이 실패하는 실행(오프라인)에서만 닿고(AC-010 (4)), 재추정 실패 모양은 출발지 nil 레코드로 결정적으로 닿는다고 **읽었다**(AC-010 (10) — 실행하지 않았다).
- **(0.1.2) 기존 드라이버 절이 `travelSeconds == nil`인 레코드의 나열·점을 단언하는지.** 훑지 않았다 — MC 게이트의 "뺀 수 0"이 잡는다(`plan.md` §3).
- **(0.1.2) 자정 근처의 시뮬레이터 동작.** 스크립트가 없다(시계를 맞춰야 한다). 기계 쪽은 AC-010 (12)(13)·AC-017 (9)다.
- **(0.1.1) 배치 묶음 조회의 렌더 비용.** 활동 수 × 일정 수의 거르기가 페이지 셋마다 돈다 — 측정하지 않았다(가설: 무시할 만함).
- **(0.1.1) 저장소 이전 데이터.** `departureDate`는 있고 `travelSeconds`가 없는 레코드가 `d3c9327` 이전 앱에서 만들어졌는지 알 수 없다(표 40). 있었다면 REQ-023 뒤 경고로 그려진다.
- **MCP `spec_audit`.** 이 SPEC 디렉터리를 본다는 보장이 없다 — SPEC-UIKIT-008 기록에서 MCP 서버가 주 체크아웃을 읽는 것으로 보였다(추정). 린트는 워크트리 CLI로 확인한다(`progress.md` §E.1).

## 7. 결정과의 연결

결정 D-1~D-14의 해소 기록과 근거는 `plan.md` §2에 있다(2026-09-30 전부 해소, D-8 (b)·D-14 (b)가 적용된 변경). 이 문서의 §4가 새로 세운 것(D-13, D-9 권장, 안쪽 배치, 저장의 비동기화, 0.1.1의 13·14)은 그 기록에 반영돼 있다. 0.1.3의 iOS 전용은 결정이 아니라 운영자 방침 P-1이다(`plan.md` §2 첫머리, 출처 측정은 §3 표 50·51).

🗿 MoAI
