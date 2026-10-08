# SPEC-UIKIT-012 — progress.md

칸반 카드 **t43** · 연결된 이동 구간 드래그 재설계. 2026-10-08 plan 레인(`manager-spec`, 서브에이전트)이 작성했다. 워크트리 `.claude/worktrees/t43`(브랜치 `WT-leg-drag-resize`), 기준 트리 `b59fcaa`.

## §E.1 Plan-phase Audit-Ready Signal

- **방식: serial** — 이 레인이 직접 읽고 썼다. 서브에이전트를 띄우지 않았다.
- **Tier: M**(`plan.md` §0). REQ 14 · AC 12(아래 계수).
- **산출물**: `spec.md` · `plan.md` · `acceptance.md` · `research.md` · `progress.md`(이 파일). `research.md`는 오케스트레이터 지시로 추가했다.
- **범위**: 이 SPEC 디렉터리 밖에는 쓰지 않았다. 코드·빌드·드라이버 실행·커밋을 하지 않았다.
- **게이트 표식**: `plan.md` §2에 4건(D-3·D-4·D-6·D-8), `research.md` §7에 같은 4건. `spec.md`·`acceptance.md` 0건.
- **일관성 재독**: 다섯 파일을 한 번 다시 읽고 REQ↔AC 추적(REQ 14개 모두 AC 매트릭스에 1회 이상), 게이트 표식 위치, 시간 추정 없음, 번역투 비유어 없음을 아래 명령으로 확인했다.
- **plan_status(현재)**: **0.6.0 draft, 미감사** — 아래 "0.6.0 개정" 절과 §H. "0.5.0 개정" 절·§G와 이하 줄은 그 시점 기록.
- **plan_status(0.4.1 기록)**: audit-ready — **0.4.1**(재감사 4회차 차단 결함 N4-1 수리, `.moai/reports/plan-audit/SPEC-UIKIT-012-review-4.md`; 이전: 0.4.0 감사 1~3회차 반영: `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`·`-review-2.md`·`-review-3.md`; 감사 상한 도달, 재감사 없음 — 고친 대조는 0.4.0 표의 실행 출력으로 입증). **게이트 표식 4건(`plan.md` D-3·D-4·D-6·D-8)은 착수 승인에서 운영자가 답하도록 일부러 남겼다 — 재감사의 MP-7 FAIL은 예상된 결과다.** 감사 D-15가 더하라고 한 결정(옛 틈·반복 범위·밤샘 활동·미리보기 배치)은 오케스트레이터 지시로 새 게이트 없이 〔제안〕으로 적용하고 `plan.md` §9 ②에 나열했다.

### 관측된 증거 — 이 레인이 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` | `b59fcaa` | 기준 트리 |
| `ID="SPEC-UIKIT-012"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` | `PASS` | frontmatter `id` |
| `ls .moai/specs \| grep -c SPEC-UIKIT-012`(워크트리 · 주 체크아웃) | `0` · `0` | 중복 없음 |
| `wc -l Shared/ContentView.swift Shared/Store.swift Shared/Models.swift Tools/GuardDriver.swift Shared/AIAssistant.swift` | `972` · `1828` · `707` · `5366` · `3292` | spec §0 |
| `sed -n 20,26p` · `sed -n 63,67p .moai/reports/2026-10-05-sim-4bundle-result.md` | `:23` t43 생성 줄 · `:65` 18번 메모 원문 | spec §1.1 |
| `rg -n 'func finalizeDrag\|deltaMinutes = Int\|minActivityMinutes\|…' Shared/ContentView.swift` | `:28` pendingMove · `:37` hourHeight 56 · `:60-61` ActiveDrag/Kind · `:176-182` 대화상자 · `:464-465` 반올림 · `:514` offsetY · `:531`·`:532` 최소 높이 · `:543`·`:558` span · `:595`·`:600` dragOffsetMinutes · `:711` positionedBlocks · `:753` block(atX:y:) · `:767` finalizeDrag · `:772`·`:775`·`:780`·`:783` 호출 | spec §1.2 · plan §2·§3 |
| `sed -n 455,475p;510,605p;760,790p Shared/ContentView.swift` | 제스처 `:458-470` · 미리보기 `:514-521` · span 본문 `:543-592` · finalizeDrag `:767-786` | spec §1.2 · research §2 |
| `grep -n 'minimumDuration\|0.35' Shared/ContentView.swift` | `:851` · `:878` · `:899 longPress.minimumPressDuration = 0.35` | spec §1.2·§3 |
| `grep -n 'if e.recurrenceId != nil\|drag.deltaMinutes != 0'` · `grep -n '자정을 넘는 블록은'` | `:778` · `:470` · `:540` | spec REQ-008·REQ-011 |
| `grep -rn 'func events(on\|func activities(on' Shared/` | `ContentView.swift:87` · `:95` | plan D-4 · research §3 (라) |
| `rg -n 'func adjustTravelLeg\|func shiftEvent\|…' Shared/Store.swift` | `:10`·`:14` didSet · `:62` clampBuffer · `:134` 재계산 · `:282` updateActivity · `:311` modifyActivity · `:352` realignReturnLeg · `:365` recurrenceEpisode · `:378` legAnchor · `:400` explicitLegs · `:407` legs · `:415` activity(forLeg:) · `:436` @MX:WARN · `:482` 거절 · `:581` realignLegs · `:682` saveActivities · `:810` conflicts · `:1113` enqueueCalendarUpload · `:1337` 알림 예약 · `:1361` moveActivity · `:1387` adjustTravelLeg · `:1414` linkedLegs · `:1427` estimatedLegs · `:1439` shiftEvent · `:1451` adjustBuffer · `:1476` rescheduleNotification · `:1519` rescheduleNearestNotifications · `:1744` reconcileActivities · `:1816` save | spec §1.2·§1.3 · plan · research |
| `sed -n 1355,1475p;1515,1545p;280,300p;400,440p;476,484p Shared/Store.swift` | adjustTravelLeg 본문 `:1387-1410`(분기 `:1401-1407`, 저장 `:1409`(0.2.0 정정)) · shiftEvent 재예약 `:1446` · adjustBuffer 이동시간 가드 `:1454` · 산식 복제 `:1462` · 일괄 `:1523`·`:1541`·`:1542` · 정렬 `:286` · 명시 구간 허용 주석 `:477-480` | spec · plan D-7 · research §4 |
| `grep -n '@MX:DEBT: 출발시각'` · `grep -n 'rescheduleNotification(at: idx)'` · `grep -n 'activities.sort'` | `:1304`·`:1462`·`:1492` · `:1446`·`:1472` · `:209`·`:261`·`:286` | spec REQ-003 · plan |
| `grep -n 'func addEvent'` · `awk 'NR>=868&&NR<=885' … \| grep -n 'recurrenceId\|linkedActivityId'` · `grep -n 'recurrenceId = '` · `grep -n 'func addRecurringEvents'` | `:868` · 매개변수에 `linkedActivityId`만(`recurrenceId` 없음) · `:955` · `:924` | spec §1.3 (다) · research §3 (다) |
| `grep -n 'var bufferMinutes\|var linkedActivityId' Shared/Models.swift` · `sed -n 150,205p` | `:166` · `:191` · 산식 주석 `:165` | spec §1.3 (가) |
| `sed -n 2575,2592p Shared/AIAssistant.swift` · `rg -n 'adjustBuffer\|adjustTravelLeg' Shared Tools` | 주석 `:2582-2586`(0.2.0 정정) · 호출 `Store.swift:1406` · 드라이버 `:614`·`:3666`·`:3675` · 화면 `:780`·`:783` | spec §1.3 (바) · REQ-014 |
| `rg -n 'AF-018\|AF-015-11' Tools/GuardDriver.swift` · `sed -n 3630,3690p` | AF-018 머리 `:3637` · 01 `:3660` · 02 `:3669`(호출 `:3666`) · 03 `:3678`(호출 `:3675`) · 픽스처 `:3638-3653` · AF-015-11 `:4321` | plan §5 |
| `sed -n 300,310p Tools/GuardDriver.swift` · `rg -n 'drvPass + drvFail'` | 종료 코드 `:306`(0.2.0 정정) · 요약 `:5360` | plan §5 |
| `grep -c 'drvCheck(' Tools/GuardDriver.swift` | `513` | plan §5(하한 근거로 쓰지 않음) |
| `grep -on '498…' plan.md CHECKLIST.md` | `plan.md:458` `498/498` · `CHECKLIST.md:284` `498/498` | plan §5 · AC-011 |
| `awk 'NR>=135&&NR<=143' SPEC-UIKIT-009/plan.md` · `awk NR==158/160 spec.md` · `NR==318/319/456 acceptance.md` · `NR==126/190/209 design.md` · `grep -n '^status' spec.md` | D-6 (a) 원문 · REQ-017 · REQ-018 · AC-018 (2)(3) · 스크립트 18 · E4 · `status: completed`(`:5`) | spec §1.4 · plan D-8 · research §6 |
| `awk NR==190/458/599 plan.md` · `awk NR==93/196/202/284/313 CHECKLIST.md` | K13 ❌ 원문 · D8 `ContentView.swift:897-899`·`:772`·`:780` · K7 · 현존 목록 | plan §6 |
| `awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift \| grep -c 'adjustBuffer('` · 같은 범위 `grep -c 'save()'` | `1` · `1` | AC-003 · AC-010 기준값 |
| `grep -c 'Task {' Shared/Store.swift` | `8` | AC-010 양성 대조 |
| `grep -c 'minActivityMinutes' Shared/ContentView.swift Shared/Store.swift` · `grep -c 'minActivityMinutes: CGFloat = 20' Shared/ContentView.swift` | `2` · `0`(Store) · `1` | AC-004 기준값 |
| `grep -c 'startOfDay\|minActivityMinutes - \|20 - ' Shared/ContentView.swift` · `awk 'NR>=455 && NR<=475' … \| grep -c 'store\.'` | `0` · `0` | AC-006 기준값 |
| `grep -c 'inSameDayAs: activity.startDate' Shared/Store.swift` | `1` | AC-006 |
| `ls Shared \| wc -l` | `27` | AC-011 3 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` | `14` · `12` | spec §0 · plan §0 |
| `grep -c 'NEEDS CLARIFICATION'` spec · acceptance · plan · research | `0` · `0` · `4` · `4` | 게이트 표식 위치 |
| REQ별 AC 매트릭스 출현 수(`awk '/^\| AC-0/' acceptance.md \| grep -c <REQ>`) | 001~014 모두 1 이상(013만 1) | 추적성 |
| 번역투 비유어 `grep -c '축\|기둥'`(네 파일) | acceptance 1(`축소` — 비유어 아님) · 나머지 0 | 문체 |

### 이 레인이 정정한 오케스트레이터 서술

- "명시적 구간은 반복 회차에 존재할 수 없다" → 옛 데이터에서는 존재할 수 있다(`Store.swift:481-482`는 명시 구간이 없을 때만 거절). 다만 그 구간은 `recurrenceId`가 없어 대화상자 키에 대한 결론은 같다(research §3 (다)).
- `Models.swift`의 `linkedActivityId`는 `:191`, 출발 산식 원 마커는 `Store.swift:1304`, `shiftEvent`의 재예약은 `:1446`, `updateActivity`의 정렬은 `:286`이다.

### 0.2.0 개정 — plan 감사 1회차 반영 (2026-10-08)

입력: `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`(FAIL 0.60, D-1~D-22)와 오케스트레이터의 설계 확정안 10항. 수치 전후: REQ 14 → 14 · AC 12 → 12 · 추가 단언 15 → 19 · T = B + 15 → **B + 19** · 게이트 표식 plan 4 / research 4 → 그대로.

| 결함 | 처리 | 바꾼 곳 |
|---|---|---|
| D-1 MP-7 게이트 | **게이트로 남김**(착수 승인 몫, 지시) | plan §2 D-3·D-4·D-6·D-8 |
| D-2 반복 범위 | 고침 — 소유 활동과 같은 반복·제목·장소 이름 회차만, 각자 정방향 조회 | spec REQ-010 · plan D-7 · AF-018-19 · S-9 |
| D-3 역방향 유일성 | 고침 — 명시 → 정방향 `linkedLegs` 후보 → 앵커 동률 → 없음. 확정안의 `estimatedLegs` 직접 사용 대신 `linkedLegs` 사용(정방향과 명시 우선 일치, 감사 D-3 (b)) | spec REQ-004·005 · plan D-2 · AF-018-20·21 |
| D-4 옛 틈 | 고침 — 틈 유지(새 게이트 없이 〔제안〕 D-9) | spec REQ-001·§1.3 (마) · AF-018-22 |
| D-5 자정 포함 경계 | 고침 — 도착 < 다음 날 0시(반열린), AF-018-08 = +35(도착 23:55), S-6 기대 일치 | spec REQ-007 · plan D-4 · AC-005 · S-6 |
| D-6 미리보기 반폭 | 고침 — 소유 구간도 `span(for event:on:)` 안, 뷰 도우미 하나, `dragOffsetMinutes(forEvent:)` 0, "떨림은 받아들인 위험" 문구 삭제 | spec REQ-009 · plan D-5 · AC-007 |
| D-7 밤샘 활동 잠김 | 고침 — 구간 자신이 닿은 날 기준 | REQ-007 · AF-018-10 |
| D-8 드라이버 네트워크 | 고침 — `afInjectedLeg`·`ActivityBlock` 직접 주입, AF-018-17은 데이터 성질 회귀 핀 + `finalizeDrag` 구조 대조 | plan §5 · AC-008 · AC-011 3 |
| D-9 출발 nil 한계 | 고침 — 앵커 시각으로 잰다, AF-018-14에 −15 | REQ-007 · plan D-4 · AC-009 |
| D-10 S-6 취약 | 고침 — 22:00–22:30, 도착 A 기록, 이동시간 85분 미만 조건 명시 | S-6 |
| D-11 REQ-008 범위 | 고침 — 주어를 소유 활동 있는 구간으로 | REQ-008 |
| D-12 인용 | 고침(아래 실측) — `:1409`·`:1400`·`:306`·`:1519-1543`·`:1439-1447`·`:2582-2586`, 루트 `plan.md:190` 수리 무조건 | spec · plan · research · acceptance |
| D-13 계수 규칙 | 고침 — 번호 하나 = 한 번 실행되는 `drvCheck` 하나, 복합은 `&&` | plan §5 |
| D-14 일괄 복제 | 고침(감사의 처방 대신 확정안) — `moveActivity` 모양, `shiftEvent` 재사용으로 산술 복제 0. "events 한 번 대입" 대신 "persist 한 번" | REQ-010 · plan D-7 · AC-010 |
| D-15 게이트 부족 | **거절(지시)** — 네 결정을 〔제안〕으로 적용하고 §9 ②에 나열, 새 게이트는 만들지 않음 | plan §9 |
| D-16 격리 상수 | 고침 — 단정하지 않고 〔가설〕 + run의 무경고 빌드 확인 지시 | plan D-3 · AC-011 5 |
| D-17 "may grow" | 고침 — shall 문장 | REQ-006 |
| D-18 REQ-003 AC 없음 | 고침 — `grep -c 'addingTimeInterval(-'` 기준 5 · 증가 0, 새 대입 없음 | AC-010 |
| D-19 약한 G | 고침 — (a)(b) 회귀선으로 분류하고 D를 주 증거로 명시, (c) 본문 `diff`로 교체, (d) `grep -v '!='` 추가. `inSameDayAs` 계수는 삭제(역방향이 이제 `linkedLegs`를 부르므로 의미가 약함) | AC-006·007·010 |
| D-20 시뮬레이터 | 고침 — S-5 되돌리기를 "40분 아래로", 오는 편 알림 S-11, 실행 취소 없음 명시, 점심 포함 S-9. 옛 틈은 새 빌드에서 만들 수 없어 S 없음(드라이버 22) | 스크립트 |
| D-21 수리 목록 | 고침 — CHECKLIST D8 근거, `Models.swift:391` @MX:NOTE(기록만), 드라이버 `:3637` 머리 주석, SPEC-009 `spec-compact.md`·`research.md` | plan §6 · D-8 |
| D-22 한계 세부 | 고침 — 가는 편 대칭식, 초는 0 쪽 버림 뒤 5분 내림, 확정 때 같은 함수로 다시 자름 | REQ-008 · plan D-3·D-4 |

**이 레인이 새로 찾은 것**: 배치 묶음 `packingGroups`(`Store.swift:438-452`)는 두 활동이 같은 구간을 추정으로 주장하면 나중 활동이 덮어쓴다(`:447-448`). 점심 장소 없는 반복에서 화면 묶음은 점심시간, 드래그 소유는 체류일 수 있다 — `plan.md` §7 잔여 위험과 spec §4에 적었다(화면 미관측). 또 `afInjectedLeg`는 AF-018 머리(`:3637`)보다 아래(`:3806`)의 지역 함수다 — 앞선 참조 가능 여부는 〔가설〕로 run에 넘겼다.

#### 0.2.0 실측 표

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `awk 'NR>=1392&&NR<=1410' Shared/Store.swift` | 역할 필터 `:1392-1395` · 루프 `:1400` · 닫는 괄호 `:1408` · `save()` `:1409` · 함수 끝 `:1410` | REQ-005·010 · AC-010 |
| `awk 'NR>=300&&NR<=308' Tools/GuardDriver.swift` | `:306 else { code = drvFail > 0 ? 1 : 0 }` | REQ-013 · plan §5 |
| `awk 'NR>=1439&&NR<=1448' Shared/Store.swift` | `shiftEvent` `:1439-1447`, 산술 `:1442-1445`, 재예약 `:1446` | spec §1.3 (가) · plan D-5 |
| `awk 'NR>=2580&&NR<=2587' Shared/AIAssistant.swift` | 주석 `:2582-2586` | spec §1.3 (아) |
| `awk 'NR>=1540&&NR<=1545' Shared/Store.swift` | `events = updated` `:1541` · `save()` `:1542` · 함수 끝 `:1543` | REQ-010 · plan D-7 |
| `awk 'NR==190' plan.md \| grep -o '.{60}버퍼만 조정.{0,20}'` | "… 이동 블록만 옮기면 활동은 고정하고 버퍼만 조정 \| `Shared/ContentVi…" | plan §6(수리 무조건) |
| `grep -n 'recurrenceId\|lunchPlace ?? dest\|let leg[1-4]\|return_time' Shared/AIAssistant.swift`(2290~2400) | `:2314` leg1 · `:2321` recurrenceId · `:2331` return_time · `:2336`·`:2344`·`:2359`·`:2364`·`:2376` 전달 · `:2371` 점심시간 | spec §1.3 (다)(아) |
| `grep -n 'func packingGroups\|func overlapSlots'` · `awk 'NR>=438&&NR<=455' Shared/Store.swift` · `awk 'NR>=386&&NR<=396' Shared/Models.swift` | `Store.swift:438-452`(덮어쓰기 `:447-448`) · `Models.swift:395`(NOTE `:388-392`, "끌어 들인 구간" `:391`) | spec §1.3 (사) · plan §6·§7 |
| `awk 'NR>=711&&NR<=735' Shared/ContentView.swift` | `positionedBlocks` `:711-734`, `span` 호출 `:717`·`:722` | spec §1.2 |
| `awk 'NR>=208&&NR<=214' Shared/Models.swift` | `failedBlockAnchor` `:210-213` | REQ-007 · plan D-4 |
| `awk 'NR>=3806&&NR<=3820' Tools/GuardDriver.swift` · `grep -n 'af15d0 =\|recurrence: af15'` | `afInjectedLeg` `:3806-3817`(travelSeconds 1200/nil) · AF-015 기준일 `:4274`, 주입 `:4286`·`:4290`·`:4294` | plan §5 · AC-005 |
| `awk 'NR==896\|\|NR==897\|\|NR==951\|\|NR==960\|\|NR==989' Shared/Store.swift` | 추정 대기 `:896`·`:897` · 과거 건너뜀 `:951` · 반복 추정 `:960` · 재예약 `:989` | plan §5 |
| `awk 'NR>=58&&NR<=62' Shared/Store.swift` | `nonisolated static let maxBufferMinutes = 180` `:61`(이유 주석 `:60`) | plan D-3 〔가설〕 |
| `grep -c 'addingTimeInterval(-' Shared/Store.swift` | `5` | AC-010 |
| `awk 'NR==1430' Shared/Store.swift` | `cal.isDate($0.arrivalDate, inSameDayAs: activity.startDate)` | REQ-007 |
| `awk 'NR>=600&&NR<=603' Shared/ContentView.swift` | `dragOffsetMinutes(forEvent:)` 본문 | REQ-009 · AC-007 |
| `awk '/onChange: \{ dy in/,/\},/' … \| grep -c 'store\.'` · `grep -c 'startOfDay\|dateInterval(of: .day'` · `finalizeDrag` 안 `if e.recurrenceId != nil` · 두 `span`의 `legDragShift\|activeDrag` | `0` · `0` · `1` · `0` · `0` | AC-006·007·008 기준값 |
| `awk '/private func offsetY/,/^    }$/' \| wc -l` · `finalizeDrag` 같은 꼴 | `8` · `20`(awk 범위가 함수 하나로 끊긴다 — `diff` 명령의 근거) | AC-007 |
| `ls .moai/specs/SPEC-UIKIT-009/` | `acceptance.md design.md plan.md progress.md research.md spec-compact.md spec.md` | plan D-8 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -o 'AF-018-[0-9][0-9]' plan.md \| sort -u \| wc -l` | `14` · `12` · `22`(01~22 → 추가 19) | spec §0 · REQ-013 |
| `grep -c 'NEEDS CLARIFICATION'` spec · plan · acceptance · research | `0` · `4` · `0` · `4` | 게이트 위치 |
| REQ별 AC 매트릭스 출현 수 | 001:3 002:3 003:4 004:2 005:2 006:3 007:4 008:2 009:3 010:3 011:3 012:2 013:1 014:2 | 추적성 |
| `grep -c '축\|기둥'`(네 파일) | 모두 `0` | 문체 |
| `wc -l *.md` | acceptance 243 · plan 246 · research 102 · spec 204 | 보고 |

**검증하지 못한 것**: 드라이버·빌드·시뮬레이터 미실행. 반폭 분할(D-6)과 묶음/소유 불일치는 코드 읽기 추론. 공유 상수의 격리 경고와 `afInjectedLeg` 앞선 참조는 〔가설〕. 오케스트레이터 열람 셋(스크롤 잠금·60초 중복 판정·gid 시각 미갱신)은 본문을 다시 읽지 않았다.

### 0.3.0 개정 — plan 감사 2회차 반영 (2026-10-08, 마지막 수정)

입력: `.moai/reports/plan-audit/SPEC-UIKIT-012-review-2.md`(FAIL 0.80, N-1~N-15)와 오케스트레이터 지시. 수치 전후: REQ 14 → 14 · AC 12 → 12 · 추가 단언 19 → **20**(AF-018-23) · T = B + 19 → **B + 20**(B = 498이면 518) · 게이트 표식 plan 4 / research 4 → 그대로(MP-7 FAIL은 예상된 결과 — 착수 승인에서 닫는다).

| 결함 | 처리 | 바꾼 곳 |
|---|---|---|
| N-1 화면 밖 이동 | 고침 — REQ-007을 "출발·도착이 각자 지금 날짜에 머문다" 한 규칙으로(닿는 날 집합 불변 → 겹침 유지와 밖으로 안 나감이 함께 성립, 한 문장 증명 REQ-007). AF-018-10: +15 → **+5**, −15 → **−10**, 밤샘 −30 적용. AF-018-23(격자 훑기) 추가. S-13 추가 | spec REQ-007 · plan D-4·§5 · AC-005 · S-13 |
| N-2 프레임마다 조회 | 고침 — `onBegin`에서 한 번 구해 `ActiveDrag`에 담음, 후보를 같은 반복·같은 날 활동으로 먼저 좁힘, 한계 함수는 (구간, 소유) 순수 산술, G 대조(`span`·`onChange`·도우미 안 조회 0, `onBegin` 1). **지시와 다른 점**: `finalizeDrag`는 그대로 두고 드롭 때 `adjustTravelLeg` 안에서 한 번 다시 구한다(서명 유지, 같은 함수라 결과 동일) | spec REQ-004·008·009 · plan D-2·D-5 · research §3 (나) · AC-007 |
| N-3 S-6 기대 | 고침 — 멈추는 도착 = A + 5·⌊(24:00 − A − 1분)/5⌋, 예시 셋, 정렬이 중요한 이유(0 쪽 5분 내림). 경계표의 "23:55"는 드라이버 픽스처 한정 | S-6 · 경계표 |
| N-4 REQ-003 충돌 | 고침 — 반복 대상 회차와 알림 식별자 재배정을 예외로 명시 | spec REQ-003 |
| N-5 출발 없는 동률 | 고침 — 출발 없으면 동률 불성립 → 소유 없음. AF-018-21 (b)로 단언 | spec REQ-004 · plan D-2 · AF-018-21 |
| N-6 주입 여유 0 | 고침 — 여유를 말하는 새 단언(11·13·21 (a))은 여유 20·출발 재설정 뒤 붙임, 기대를 수치로(20→5·도착 고정) | plan §5 · AC-003 |
| N-7 86,400초 픽스처 | 고침 — 기준일을 `date(byAdding: .day, value: 60)` 뒤 하루 시작으로, AF-015 꼴은 본보기에서 뺌 | plan §5 · AC-005 |
| N-8 구글 대조 | 고침 — `enqueueCalendarUpload\|removeFromCalendar\|googleEventId` 계수 0(위반 시 실패) | AC-010 |
| N-9 AC-010 범위 | 고침 — 새 경로가 부르는 새 함수 전부에 `awk`를 돌린다, 갈래별 저장 횟수는 읽기 판정 | AC-010 |
| N-10 구간 없는 회차 | 고침 — 활동도 고치지 않고 건너뜀 | spec REQ-010 · plan D-7 |
| N-11 수리 목록 | 고침 — `Store.swift:520`(run이 좁혀 고침), SPEC-009 `plan.md:110`·`:151-152`, `design.md:176`·`:237`, `research.md:87` | plan §6 · D-8 |
| N-12 시뮬레이터 | 고침 — S-12(캘린더 앱 구글 시각), S-13(자정 걸친 구간 끌기), S-9 앞에 S-7 반복 삭제 | 스크립트 |
| N-13 AF-018-17 | 고침 — "드롭 뒤 `recurrenceId`·`linkedActivityId` 불변" 회귀 핀으로 바꾸고 대화상자 키는 G 대조가 근거라고 명시 | plan §5 · AC-008 |
| N-14 앞선 참조 가설 | 고침 — 감사가 `swiftc -emit-sil`로 확인한 결과를 적고 〔가설〕 닫음, 뒤에 선언된 일반 변수(`afCal` `:3823`·`afDay` `:3824`)는 끌어온다, run 컴파일이 마지막 확인 | plan §5 |
| N-15 D-3 대안 | 고침 — 5분을 고르면 드래그 최소 길이 상수와 그리기 최소 높이(20, 그리기 전용)를 분리한다고 게이트 문구에 적음 | plan D-3 · research §7 |

#### 0.3.0 실측 표

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `awk 'NR>=576&&NR<=580' Shared/ContentView.swift` | 날 밖 출발 → 0, 날 밖 도착 → 1440 (`:576-578`), `natural ≥ 16`이면 그대로 반환(`:579-580`) | spec REQ-007 · plan D-4 |
| `awk 'NR==26' Shared/ContentView.swift` | `@State private var activeDrag: ActiveDrag?` | plan D-5 |
| `awk 'NR==1534\|\|NR==1538' Shared/Store.swift` | `notificationId = nil` `:1534` · 재배정 `:1538` | spec REQ-003 |
| `awk 'NR==205\|\|NR==206' Shared/Models.swift` | `failedBlockAnchor` 설명(반복 뒤 회차 출발 nil) | REQ-004 동률 |
| `awk 'NR==520' Shared/Store.swift` | "오는 편을 끌어 벌어진 틈은 이 저장으로 닫힌다" | plan §6 |
| `awk 'NR==110\|\|NR==151\|\|NR==152' SPEC-UIKIT-009/plan.md` · `NR==176\|\|NR==237 design.md` · `NR==87 research.md` | 각 줄 실재(틈·묶음·경고 블록 끌기 서술) | plan D-8 |
| `awk 'NR==3823\|\|NR==3824' Tools/GuardDriver.swift` | `let afCal = Calendar.current` · `let afDay = … addingTimeInterval(45 * 86400)` | plan §5 |
| `awk 'NR==4274' Tools/GuardDriver.swift` | `af15d0 = afCal.startOfDay(for: Date()).addingTimeInterval(60 * 86400)` | N-7 |
| `awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift \| grep -c 'enqueueCalendarUpload\|removeFromCalendar\|googleEventId'` | `0` | AC-010 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -o 'AF-018-[0-9][0-9]' plan.md \| sort -u \| wc -l` | `14` · `12` · `23`(01~23 → 추가 20) | spec §0 · REQ-013 |
| `grep -c 'NEEDS CLARIFICATION'` spec · plan · acceptance · research | `0` · `4` · `0` · `4` | 게이트 |
| `grep -c '축\|기둥'`(네 파일) | 모두 `0` | 문체 |
| 손 계산 | AF-018-08 +35 · 09 −20 · 10 +5/−10/−30 · S-6 A=22:52 → 23:57 · S-13 +15 → 23:55 | AC-005 · S절 |

**검증하지 못한 것**: 드라이버·빌드·시뮬레이터 미실행. 전체 높이 블록(N-1)과 프레임 비용(N-2)은 코드 구조에서 유도한 것이고 화면·계측으로 보지 않았다. 공유 상수 격리 경고는 〔가설〕. AF-018-23은 새 함수를 부르므로 기준 트리 관측이 없다.

### 0.4.0 개정 — plan 감사 3회차 반영 (2026-10-08, 재감사 없음)

입력: `.moai/reports/plan-audit/SPEC-UIKIT-012-review-3.md`(FAIL 0.71, R3-1~R3-10 · G-1). 수치 전후: REQ 14 · AC 12 그대로, 추가 단언 20 → **21**(AF-018-24), T = B + 20 → **B + 21**(B = 498이면 519), 게이트 표식 plan 4 / research 4 그대로(착수 승인 몫 — MP-7 FAIL은 의도).

| 결함 | 처리 | 바꾼 곳 |
|---|---|---|
| R3-1 0시 경계 | 고침 — REQ-007을 나열 판정의 반열린 규약에 맞춤(F.시작 ≤ 출발 < F.끝, L.시작 < 도착 < L.끝), 집합 보존 한 문장 증명. AF-018-10 −15 → **−5**, AF-018-23을 `isListed(on:)`로 재고 0시 허용 규칙에서 실패함을 명시, S-14 추가 | spec REQ-007·§1.3 (바) · plan D-4 · AC-005 · S-14 |
| R3-2 헛도는 대조 | 고침 — 이스케이프한 개별 `awk`, 범위 확인 `wc -l`, 양성 대조 실행(아래 표) | AC-007 |
| R3-3 드롭 사본 | 고침 — 드롭은 id로 저장소에서 다시 읽어 현재 값으로 소유·한계, id 없으면 무동작, AF-018-24, 소유 갈림 두 경우를 잔여 위험에 | spec REQ-008 · plan D-5·§7 · AC-006 |
| G-1 게이트 설명 | 고침 — D-4 게이트에 예 ①②③, 같은 날 추정 근거는 반복 추정 구간 한정, 셋째 안(반복 추정 구간만 막기, 비용 규칙 둘) | plan D-4·§9 · spec §1.3 (바) · research |
| R3-4 출발 없는 동률 | 지금 선택 유지(제외) + 문구 정리 — 감사 권고안(`failedBlockAnchor` 비교)은 출발 기준 회차의 앵커가 도착 시각(`Models.swift:212`)이라 체류 끝과 같지 않아 동률을 풀지 못한다. HISTORY ④를 본문과 같게, 비대칭을 plan §7에 | spec HISTORY · plan §7 |
| R3-5 픽스처 연결 | 고침 — AF-018-08~10·23·24 모두 명시 연결, 활동 시각·길이 명시 | plan §5 · AC-005 |
| R3-6 5분 상수 | 고침 — Store 상수 하나를 제스처와 한계 함수가 읽음 | spec REQ-008 · plan §3·D-5 |
| R3-7 시뮬레이터 | 고침 — S-11을 S-1·S-3 재실행으로 옮기고 "출발 시각 − 알림 행 N분 전"으로, S-6 전제(A < 24:00), S-14(0시 경계 위로 끌기) | 스크립트 |
| R3-8 명령 위생 | 고침 — `mkdir -p`, 범위 대조를 작업 트리 대 기준(`git diff --name-only b59fcaa --`) + `git status --porcelain` | AC-010 · AC-011 |
| R3-9 낡은 상태 줄 | 고침 — plan_status 0.4.0, 관련 문서에 review-2·3 | progress · spec §6 |
| R3-10 픽스처 시각 | 고침 — 2시간 안 출발 픽스처 금지와 이유(`Tools/GuardDriver.swift:3770`의 재추정이 초기화 `:3783-3784` 전에 돈다) | plan §5 |

#### 0.4.0 실측 표 — 구조 대조의 양성 대조(이 레인이 기준 트리 `b59fcaa`에서 실제로 돌림)

| 명령 | 출력 | 뜻 |
|---|---|---|
| `awk '/func span\(for activity/,/^    }$/' Shared/ContentView.swift \| wc -l` | `14` | 범위가 잘린다 |
| `awk '/func span\(for event/,/^    }$/' … \| wc -l` | `35` | 〃 |
| `awk '/func dragOffsetMinutes\(forEvent/,/^    }$/' … \| wc -l` | `4` | 〃 |
| `awk '/func legDragShift\|var legDragShift/,/^    }$/' … \| wc -l` | `0` | 기준에는 도우미가 없다(마감에서 1 이상이어야 함) |
| `awk '/onChange: \{ dy in/,/\},/' … \| wc -l` · `awk '/onBegin: \{ x, y in/,/\},/' … \| wc -l` | `4` · `5` | 범위가 잘린다 |
| 같은 범위의 아는 패턴: `grep -c 'minutesSinceMidnight'`(span 둘) · `'activeDrag'`(dragOffset) · `'hourHeight'`(onChange) · `'block(atX'`(onBegin) | `2` · `4` · `1` · `1` · `1` | 범위 안 계수가 작동한다 |
| `printf 'func span(for event: X) {\n        let o = store.owningActivity(forLeg: e)\n    }\n' \| awk '/func span\(for event/,/^    }$/' \| grep -c 'owningActivity'` | `1` | 금지 패턴이 있으면 잡는다 |
| 같은 입력에서 그 줄을 뺀 것 | `0` | 없으면 0 |
| `awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift \| wc -l` · 같은 범위 `grep -c 'Task\|await\|try?'` · 대조 `grep -c 'Task {' Shared/Store.swift` | `24` · `0` · `8` | AC-010 범위·회귀선·패턴 작동 |
| 같은 범위 `grep -c 'adjustBuffer('` | `1` | AC-003 |
| 같은 범위 `grep -c 'enqueueCalendarUpload\|removeFromCalendar\|googleEventId'` | `0` | AC-010 회귀선 |
| `grep -c 'startOfDay\|dateInterval(of: .day' Shared/ContentView.swift` · 같은 패턴 `Shared/Store.swift` | `0` · `2` | AC-006 회귀선(패턴은 Store에서 작동) |
| `grep -c 'minActivityMinutes: CGFloat = 20' Shared/ContentView.swift` | `1` | AC-004 양성 대조 |
| `awk '/private func finalizeDrag/,/^    }$/' … \| grep -c 'if e.recurrenceId != nil'` | `1` | AC-008 |
| `git show b59fcaa:Shared/ContentView.swift \| awk '/private func offsetY/,/^    }$/' \| wc -l` | `8` | AC-007 `diff` 범위가 잘린다 |
| `git -C <worktree> diff --quiet b59fcaa -- Shared/AIAssistant.swift` | 출력 없음(exit 0) | AC-003 |
| `git diff b59fcaa -- Shared/Store.swift Shared/ContentView.swift Tools/GuardDriver.swift \| wc -l` | `0` | 기준 = 작업 트리(아래 계수는 마감에서 의미) |
| 강제 언래핑 필터 양성 대조: `printf '+        let x = y!\n+ if a != b\n' \| grep -v '!=' \| grep -c '[])a-zA-Z]!'` | `1` | `!=`는 거르고 `y!`는 잡는다 |
| 결정성 필터 양성 대조: `printf '+  await store.addEvent(x)\n' \| grep -c 'addRecurringEvents\|await store.addEvent'` · 파일 전체 `grep -c` 같은 패턴 | `1` · `17` | AC-011 3 |
| `ls -d .moai/state/verify/t43` | `No such file or directory` | R3-8 — 명령에 `mkdir -p` 추가 |
| `git status --porcelain -- Shared Tools proxy project.yml \| wc -l` · `git diff --name-only b59fcaa -- … \| wc -l` | `0` · `0` | AC-011 4 기준 |
| `awk 'NR>=36&&NR<=42' Shared/Store.swift` · `grep -n 'func isListed' Shared/Models.swift` · `awk 'NR>=216&&NR<=236' Shared/Models.swift` | `overlapsDay` `:38-41`(반열린) · `isListed` `:229-235`(앵커 날 `:230`, 나열 구간 `:219-222`) | REQ-007 |
| `grep -n 'refreshUpcomingEstimates' Shared/App.swift Shared/Store.swift Tools/GuardDriver.swift` · `awk 'NR==3770\|\|NR==3783\|\|NR==3784' Tools/GuardDriver.swift` | `App.swift:25`·`:101` · `Store.swift:1547` · 드라이버 `:3770` · 초기화 `:3783`·`:3784` | REQ-008 · plan §5 |
| `awk 'NR>=345&&NR<=356' Shared/EventDetailView.swift` | 알림 행 `:352` "출발 N분 전" | S-11 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -o 'AF-018-[0-9][0-9]' plan.md \| sort -u \| wc -l` | `14` · `12` · `24` | 추가 21 |

**쓰지 못한 대조**: AC-007의 `diff <(…) <(…)`는 이 세션의 worktree 가드가 복합 git 명령으로 막아 그대로는 돌리지 못했다 — 대신 같은 범위를 `git show … | awk … | wc -l`로 돌려 범위가 잘리는 것(8줄)을 보였다. run은 두 범위를 파일로 떨어뜨린 뒤 `diff`한다.

**검증하지 못한 것**: 드라이버·빌드·시뮬레이터 미실행. 0시 정각 구간의 목록 이탈과 미리보기 토막은 감사의 독립 실행과 코드 읽기로만 확인. 공유 상수 격리 경고는 〔가설〕. 드래그 중 재추정이 실제로 끼어드는 타이밍은 관측하지 않았다.

### 0.4.1 개정 — 재감사 4회차 차단 결함 N4-1만 수리 (2026-10-08, 5회차 없음)

현재 수치: REQ 14 · AC 12 · AF-018-01~25(추가 22) · **T = B + 22**(B = 498이면 520) · 게이트 표식 plan 4 / research 4(착수 승인 몫). 위 0.2.0~0.4.0 절의 `B + 20`·`B + 21`은 그 시점의 기록이다.

| 바꾼 곳 | 내용 |
|---|---|
| spec.md frontmatter·HISTORY 0.4.1 행 | 버전 0.4.1 |
| spec.md REQ-007 끝 | 경고 블록·깨진 레코드는 나열을 정하는 시각 하나(앵커 / 도착)만 d.시작 ≤ 새 값 < d.끝, 다른 시각은 한계 밖 |
| spec.md REQ-008 끝 | 유효 Δ는 요청과 반대 부호가 되지 않는다 — 되면 0 |
| spec.md §0 · REQ-013 | 추가 22(AF-018-04~25), T = B + 22 |
| plan.md D-4 규칙 | 같은 내용의 산식 문장 |
| plan.md §5 | AF-018-25 행, 계수 22, T = B + 22(520), `&&` 번호 목록에 25 |
| acceptance.md AC-009 · 매트릭스 · AC-011 | AF-018-25, REQ 008 추가, T = B + 22, AF-018-01~25 |

**미수리 경미 — 재감사 범위 밖(run M0 또는 sync에서 처리)**: N4-2(S-14가 최소 길이 한계에 먼저 걸림) · N4-3(AF-018-10 연달은 −15의 기준 위치) · N4-4(REQ-008·REQ-005 드롭 문구) · N4-5(HISTORY 동률 문구와 REQ-004) · N4-6(게이트 D-4 예 ③·안 (b) 문구) · N4-7(AC-007 `diff <(…)` 가드 거부 — 파일로 떨어뜨려 `diff`). 

#### 0.4.1 실측 표 — 자가 점검(실제 술어를 옮긴 독립 스크립트)

스크립트: `/private/tmp/claude-501/-Users-iseongmin-Projects-besir/a2ac6679-46a7-4926-9b74-35c2f672850f/scratchpad/n41/check.swift`. `Store.overlapsDay`(`Store.swift:38-41`), `failedBlockAnchor`(`Models.swift:210-213`), `listedSpan`(`:219-222`), `isListed(on:)`(`:229-235`)를 옮겨 적고 0.4.1 한계(위 규칙 + 반대 부호 → 0)와 0.4.0 한계(양성 대조)를 구현했다. 달력은 Asia/Seoul. 이 워크트리의 가드가 바깥 경로 heredoc·Write를 거부해, 파일을 SPEC 디렉터리에 잠깐 쓰고 `mv`로 scratchpad로 옮긴 뒤 `swiftc -o …/check …/check.swift`(출력 없음) → `…/check` 실행.

```text
(a) N4-1 case: dep 23:50, old arr 00:10, travelSeconds=nil, anchor=.departure
  req 15 -> 0.4.1 eff 5 | 0.4.0 eff -10
  req 5 -> 0.4.1 eff 5 | 0.4.0 eff -10
  req -5 -> 0.4.1 eff -5 | 0.4.0 eff -10
  req -30 -> 0.4.1 eff -30 | 0.4.0 eff -30
(b) grid: 23232 cases (broken-record legs incl. 132) | 0.4.1 opposite-sign 0, 0.4.1 listing changed 0 | 0.4.0 opposite-sign 2292
(c) AF-018-08 ret 23:00->23:20 +60 -> 35 (0.4.0: 35)
    AF-018-09 out 00:20->00:40 -30 -> -20 (0.4.0: -20)
    AF-018-10 cross +15 -> 5 (0.4.0: 5), -15 -> -5 (0.4.0: -5), overnight out 21:40->22:00 -30 -> -30 (0.4.0: -30)
    AF-018-23 listing preserved -180..+180: true
    AF-018-24 live 23:15->23:35 +60 -> 20 (0.4.0: 20)
    broken record arr<=dep (dep 23:00 arr 22:00) +15 -> 15, -15 -> -15
```

격자: 출발 분 {0, 1, 5, 10, 300, 1380, 1400, 1410, 1430, 1435, 1439} × 도착 날 {같은 날, 다음 날} × 도착 분 같은 집합 × 이동시간 {있음, 없음} × 앵커 {도착, 출발} × 요청 ±5…±60(5분 간격, 0 제외) = 23,232건. 0.4.1은 반대 부호 0건·나열 변경 0건, 0.4.0은 반대 부호 2,292건(양성 대조 — 같은 격자가 옛 규칙을 잡는다).

| 명령 | 출력 | 쓰인 곳 |
|---|---|---|
| `awk 'NR>=1310&&NR<=1332' Shared/Store.swift` | `travelSeconds = nil` `:1320` · 출발 대입 `:1321` · 추정 실패 반환 `:1327`(도착 그대로) | REQ-007 근거 |
| `awk 'NR>=3751&&NR<=3778' Tools/GuardDriver.swift` | AF-010-10-a 픽스처 `:3753-3759` · 재추정 `:3770` · 단언 `:3773-3777` | AF-018-25 |
| `awk 'NR>=216&&NR<=236' Shared/Models.swift`(0.4.0 표와 같음) | 앵커 날 `:230` · 도착 날 폴백 `:234` | REQ-007 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -o 'AF-018-[0-9][0-9]' plan.md \| sort -u \| wc -l` | `14` · `12` · `25` | 추가 22 |
| `grep -c 'NEEDS CLARIFICATION'` spec · acceptance · plan · research | `0` · `0` · `4` · `4` | 게이트 |
| `grep -o 'B + 2[0-9]' spec.md plan.md acceptance.md research.md \| sort \| uniq -c` | spec·plan·acceptance 각 `B + 22` 1건, research 0 | T 일치 |
| `awk '/^\| AC-0/' acceptance.md \| grep -c '008'` | `3` | REQ-008 추적(AC-006·009·…) |
| `grep -c '축\|기둥'`(네 파일) | spec 1(HISTORY "범위 축소" — 비유어 아님) · 나머지 0 | 문체 |
| `ls .moai/specs/SPEC-UIKIT-012` | `acceptance.md plan.md progress.md research.md spec.md` | 임시 스크립트를 남기지 않았다 |

**검증하지 못한 것**: 스크립트는 술어를 옮겨 적은 것이라 앱 코드 자체를 실행하지 않았다(드라이버·빌드 미실행). 최소 길이 한계(REQ-006)는 이 격자에 넣지 않았다 — 소유 활동 없이 자정 한계만 쟀다.

### 0.5.0 개정 — 운영자 게이트 답변 반영 (2026-10-08, 미감사)

**plan_status: draft — 0.5.0 미감사(독립 감사 없음).** 게이트 4건은 답변됨(표식 제거), 새 열린 질문 Q-1~Q-9는 착수 승인 몫. 현재 수치: REQ 16 · AC 15 · AF-018-01~28 + AF-015-09·11 고쳐 쓰기 · **T = B + 25**(B = 498이면 523). 위 절들의 `B + 22` 등은 그 시점 기록이다.

#### 0.5.0 실측 표

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` | `6cabc93`(코드는 `b59fcaa`와 같음 — 아래 `shasum` 동일) | 기준 |
| `ID="SPEC-UIKIT-012"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` | `PASS` | frontmatter |
| `wc -l Shared/ContentView.swift Shared/Store.swift Tools/GuardDriver.swift Shared/Models.swift Shared/GoogleCalendarService.swift` | `972` · `1828` · `5366` · `707` · `442` | spec §0 |
| `grep -n '1440\|ForEach(0..<24\|24 \* hourHeight\|scrollDisabled\|class ScrollTouchFixView\|struct RescheduleOverlay\|…' Shared/ContentView.swift` | 클립 `:549`·`:578` · 눈금 `:420`·`:429` · 높이 `:483`·`:485` · 잠금 `:494`·`:408` · `:854` · `:877` · `ScrollViewReader`/`scrollTo` 0건 | REQ-009·015 · D-11 |
| `awk '/func span\(for activity/,/^    }$/' … \| grep -v '^ *//' \| grep -c '1440'` · 같은 꼴 `span(for event` | `1` · `1` | AC-007 양성 대조 |
| `grep -c 'ForEach(0..<24' Shared/ContentView.swift` · `grep -c '24 \* hourHeight' …` | `2` · `2` | AC-013 양성 대조 |
| `awk '/func updateRecurringSeries/,/^    }$/' Shared/Store.swift \| grep -n 'googleEventId = nil\|removeFromCalendar(\|enqueueCalendarUpload(\|if googleConnected'` | `50: if googleConnected` · `57: … googleEventId = nil` · `59: await removeFromCalendar(gids)` · `61: enqueueCalendarUpload(eventIDs: ids)` | AC-014 순서 양성 대조 |
| `awk '/func updateActivity\(/,/^    }$/' … \| grep -c 'Task {'` · 같은 꼴 `adjustTravelLeg` | `1` · `0` | AC-014 |
| `git show b59fcaa:Shared/ContentView.swift \| awk '/private func offsetY/,…/' \| shasum` · 작업 트리 같은 꼴 · `finalizeDrag` 둘 | `2cd32a58…` · `2cd32a58…` · `3027e8ee…` · `3027e8ee…` | AC-007(N4-7 — `diff <(…)` 대체) |
| `awk '/private func estimatedLegs/,/^    }$/' Shared/Store.swift \| grep -c 'inSameDayAs'` · 같은 범위 `grep -c 'arrivalDate == activity.startDate\|departureDate == activity.endDate'` | `1` · `0` | AC-015 양성 대조 |
| `awk 'NR==1073\|\|NR==1080\|\|NR==1082\|\|NR==1084\|\|NR==1434' Shared/Store.swift` | `if googleConnected {` · gid 비우기 · `await removeFromCalendar(gids)` · `enqueueCalendarUpload(eventIDs: ids)` · `}` | spec §1.2 · D-6 |
| `sed -n 1172,1233p Shared/Store.swift` · `sed -n 52,72p Shared/SettingsView.swift` | 업로드 실패 `.failed`(`:1199`·`:1224`) · 설정 "캘린더에 못 올린 항목 N건"·"다시 시도"(`:61-64`) | REQ-012 |
| `grep -n 'googleConnected\|AF-015-11' Tools/GuardDriver.swift` | `:1490` 주석 · `:1497` `!store.googleConnected` 단언 · `:4321` | AC-014 · D-10 |
| `sed -n 4268,4299p Tools/GuardDriver.swift` | L 오는 편 출발 = L 끝(`:4291-4294`), AF-015-09 집합 `:4295-` | D-10 (A) 핀 뒤집힘 |
| `sed -n 150,175p Shared/AddActivityView.swift` | 종료 ≤ 시작이면 거절, 그 밖 허용 | REQ-006 |
| `sed -n 140,150p /Users/iseongmin/Projects/besir/.claude/rules/moai/workflow/spec-workflow.md` | Tier M 요구 16 · 수락 기준 16(서로 독립) | Tier |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -o 'AF-018-[0-9][0-9]' plan.md \| sort -u \| wc -l` | `16` · `15` · `28` | REQ-013 |
| `grep -c 'NEEDS CLARIFICATION'` spec · acceptance · plan · research | `0` · `0` · `9` · `9` | 열린 질문 위치 |
| `grep -o 'B + 2[0-9]' spec.md plan.md acceptance.md \| sort \| uniq -c` | spec 2 · plan 2 · acceptance 1, 모두 `B + 25` | T 일치 |
| `grep -c '축\|기둥'`(네 파일) | 모두 `0` | 문체 |
| `wc -l *.md`(SPEC 디렉터리) | acceptance 231 · plan 361 · progress(이 절 전) 274 · research 126 · spec 252 | 보고 |

**자가 점검 스크립트**: `/private/tmp/claude-501/-Users-iseongmin-Projects-besir/a2ac6679-46a7-4926-9b74-35c2f672850f/scratchpad/v050/check.swift`. 앱 술어(`Store.overlapsDay`, `failedBlockAnchor`, `listedSpan`, `isListed(on:)`)를 옮겨 적고 0.5.0 한계(`plan.md` D-3·D-4)와 양성 대조 두 규칙(대칭 자르기, 아래 상한 없음)을 구현했다. 달력 Asia/Seoul. SPEC 디렉터리에 썼다가 `mv`로 scratchpad로 옮긴 뒤 `swiftc -o …/check …/check.swift`(출력 없음) → 실행:

```text
(c) AF 기대값
  AF-018-06 1h 오는 편 -60 -> -55
  AF-018-07 3분 활동 가는 편 +5 -> 0 | -15 -> -15
  AF-018-08 22:00-23:00 오는 편 23:00->23:20 +90 -> 90
     드롭 뒤 구간 나열 D/D+1: false true | 활동(22:00-다음날 00:30) 나열 D/D+1: true true
  AF-018-09 가는 편 00:20->00:40 -30 -> -20
  AF-018-10 걸친 오는 편 +15 -> 15 | 새 픽스처 -15 -> -5 | 밤샘 가는 편 21:40->22:00 -30 -> -30
  AF-018-16 길이 60/60/15 오는 편 -15 -> [-15, -15, -10]
  AF-018-24 사본 -45 -> 끄는 값 -30 | 현재 값으로 드롭 -20 | 사본 기준이었다면 -30
  AF-018-25 (a) 이틀 넘는 오는 편 +15 -> 0 | -15 -> -15 | 대칭 자르기였다면 +15 -> -60 , -5 -> -60
  AF-018-25 (b) 경고 블록(출발 23:50·옛 도착 00:10) +15 -> 15 | -15 -> -15
  AF-018-26 오는 편 23:00->23:20 +1500 -> 1480
     드롭 뒤 나열 D/D+1/D+2: false true false
  AF-018-14 경고 가는 편(정오) +15/-15 -> 15 -15
  S-14 2시간 활동(21:40-23:40), 오는 편 23:40->다음날 00:B, 1시간 위: ["B=1 e=0 도착 0:01", "B=5 e=0 도착 0:05", "B=7 e=-5 도착 0:02", "B=10 e=-5 도착 0:05", "B=25 e=-20 도착 0:05"]
(b) v050 격자 522720건: downBeyond=0 minLen=0 opposite=0 overshoot=0 upChanged=0
(b) symmetric 격자 522720건: downBeyond=0 minLen=30888 opposite=35640 overshoot=55660 upChanged=34920
(b) noCap 격자 522720건: downBeyond=33748 minLen=0 opposite=0 overshoot=0 upChanged=0
```

격자: 출발 분 11개 × 도착 날 {0,1,2} × 도착 분 11개 × 이동시간 {있음, 없음} × 앵커 2 × 활동 길이 {3,5,20,60,180} × 요청 ±5…±180(5분 간격). 0.5.0은 다섯 성질(반대 부호·요청 초과·위로 나열 변경·아래로 F+1 초과·최소 길이 위반) 모두 0건이고, 같은 격자가 대칭 자르기와 상한 없음 규칙의 위반을 잡는다(양성 대조). AF-018-27·28과 AF-015-09·11은 Store 함수를 부르므로 이 스크립트 밖이다(코드 읽기로 기대를 정했다). 스크립트는 SPEC 디렉터리에 남기지 않았다(`ls` → 다섯 파일).

## §G 0.5.0 개정 요약

### G.1 사라진 것 · 새로 생긴 것 · 바뀐 것

명령(이 레인 실행): `git show HEAD:<파일>`로 0.4.1 본문을 임시 파일로 떨어뜨리고 `grep -o '^- \*\*REQ-[0-9]*'`·`'^## AC-[0-9]*'`·`'^| AF-01[58]-[0-9]*'`·`'^| S-[0-9]*'`로 식별자를 뽑아 `comm`으로 비교한 뒤 임시 파일을 지웠다. 출력:

```text
== req old=14 new=16 removed: (없음) added: REQ-015 REQ-016
== ac old=12 new=15 removed: (없음) added: AC-013 AC-014 AC-015
== af old=25 new=30 removed: (없음) added: AF-015-09 AF-015-11 AF-018-26 AF-018-27 AF-018-28
== s old=14 new=15 removed: (없음) added: S-15
```

(AF-015-09·11은 단언 수로는 새 것이 아니라 기존 핀의 제자리 고쳐 쓰기다 — 표에 새로 오른 것.) **번호가 사라진 것은 0건**이고, 내용이 뒤집히거나 다시 쓰인 것은 다음과 같다(손 분류, `plan.md` §11·`spec.md` §1.5):

| 구분 | 목록 | 수 |
|---|---|---|
| 다시 씀(뜻이 바뀜) | REQ-006·007·008·012 · AC-004·005·009 · AF-018-06·07·08·23·25 · S-5·6·12·13·14 | 4 · 3 · 5 · 5 |
| 바뀜(일부) | REQ-003·004·005·009·013·014 · AC-006·007·010·011·012 · AF-018-10·16·24 · AF-015-09·11 | 6 · 5 · 5 |
| 유지 | REQ-001·002·010·011 · AC-001·002·003·008 · AF-018-01~05·09·11~15·17~22 · S-1~4·7~11 | 4 · 4 · 18 · 9 |
| 새로 | REQ-015·016 · AC-013·014·015 · AF-018-26·27·28 · S-15 | 2 · 3 · 3 · 1 |
| 뒤집힌 대조 | 0.4.1 AC-010 "adjustTravelLeg 안 구글 호출 0" → AC-014 "`Task` 1 · `removeFromCalendar(` 1 · `enqueueCalendarUpload(` 1 · 순서" | 1 |

### G.2 규모와 분할

Tier M 유지(REQ 16 · AC 15 — 각각 상한 16, 서로 독립). 파일 3개(Store · ContentView · GuardDriver), `GoogleCalendarService.swift` 무변경. 분할 비교 표는 `plan.md` §12 — X 한 장(16·15, 버리는 코드 없음, 상한 끝) / Y 두 장(①15·14 ②3·3, 버리는 것 대조 한 줄) / Z 세 장(0.4.1 막기 규칙을 구현하고 버림). 이 레인의 기울기는 Y(권고만, 결정은 운영자 — Q-8).

### G.3 열린 질문과 〔가정〕

열린 질문(`plan.md` §2 끝 · `research.md` §8): Q-1 그리기 높이 · Q-2 폼 분 간격 · Q-3 위로 대칭 연장 · Q-4 자동 스크롤 · Q-5 연장 상한 · Q-6 넘긴 추정 구간 · Q-7 구글 반복과 호출 수 · Q-8 분할 · Q-9 연장 대상.

〔가정〕: D-3 드래그 최소 = 5분, 그리기 20분 유지 · D-4 해석 (1)~(3) · 위로는 나열 불변 · 아래 상한 = F 다음 날 끝 · 경고 블록은 나열 시각 하나 · D-6 반복 "전체" 포함 · 재등록은 gid 있던 레코드만(`updateActivity`처럼 autoAdd 무관) · D-11 자동 스크롤 없음(리드 지시) · 연장은 연결된 구간 드래그만 · "드롭당 추적 `Task`" = 실패가 묘비·`.failed`로 남는 `Task` 하나(별도 보관 속성은 요구하지 않음).

### G.4 실행한 검증 · 못 한 검증

실행: 위 0.5.0 실측 표의 명령 전부, 자가 점검 스크립트(AF 기대값 + 격자 522,720건 × 세 규칙), 식별자 `comm` 비교, 인용 줄 점검(`awk 'NR==…'`로 새로 단 인용을 읽어 `:469`·`:4291-4294`를 고쳤다).

못 한 것: 드라이버·iOS 빌드·시뮬레이터(코드 무변경 단계). 구글 연결 갈래의 실제 동작·호출 수·할당량(구글 할당량 수치는 조회하지 않았다). 끄는 중 손가락이 스크롤 영역 밖에서도 위치를 보고하는지, `scrollDisabled` 상태의 프로그램 스크롤(〔가설〕). 폼의 분 간격(Q-2). AF-018-27·28·AF-015-09·11의 기대는 코드 읽기다. 독립 감사 없음.

### 0.6.0 개정 — 운영자 2차 답변 반영 (2026-10-08, 미감사)

**plan_status: draft — 0.6.0 미감사(독립 감사 없음).** 현재 수치: REQ 16 · AC 15 · AF-018-01~27 + AF-015-09·11 고쳐 쓰기 · **T = B + 24**(B = 498이면 522). 인계 파일 `.moai/reports/t43/google-card-handoff.md`(이 워크트리, 새 파일).

#### 0.6.0 실측 표

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `grep -n 'return ScrollView {' Shared/ContentView.swift` · `grep -n 'let y = gr.location'` · `awk 'NR==456\|\|NR==457\|\|NR==479'` | `:417` · `:939` · 오버레이 `.overlay(`·`RescheduleOverlay(` `:456-457`, 닫힘 `:479` | D-11 — 오버레이가 스크롤 콘텐츠 안 |
| `grep -n 'let view = ScrollTouchFixView()\|HStack(spacing: 0) {\|private struct SwipePager'` | `:893` · `:804` · `:791` | D-11 — 조상 스크롤 뷰 찾기, 페이저는 스크롤 뷰가 아님 |
| `grep -c 'setContentOffset\|stopAutoScroll\|dismantleUIView' Shared/ContentView.swift` · `grep -c 'CADisplayLink(\|Timer.scheduledTimer\|\.invalidate()'` | `0` · `0` | AC-016 기준(패턴 없음) |
| `printf 'let l = CADisplayLink(target: p, selector: #selector(tick))\n' \| grep -c 'CADisplayLink('` · `printf 'func stopAutoScroll() { link?.invalidate(); link = nil }\n' \| grep -c 'invalidate()'` · `printf 'func tick() { … setContentOffset … onChange(gr.location(in: gr.view).y - startY) }\n' \| grep -c 'setContentOffset'` | `1` · `1` · `1` | AC-016 양성 대조 |
| `awk '/func updateActivity\(/,/^    }$/' Shared/Store.swift \| grep -c 'Task {\|removeFromCalendar\|enqueueCalendarUpload\|googleEventId'` · 같은 패턴 `adjustTravelLeg` | `6` · `0` | AC-010 구글 0건 대조 양성 대조 · 회귀선 |
| `grep -c 'minActivityMinutes: CGFloat = 5$'` · `'= 20'` · `'minTravelMinutes: CGFloat = 16'` (ContentView) | `0` · `1` · `1` | AC-004 양성 대조 · 회귀선 |
| `grep -rln 'DatePicker' Shared/` · `grep -rn 'minuteInterval' Shared/` · `grep -rn 'UIDatePicker' Shared/` · `sed -n 215,245p Shared/EditCardView.swift` | 7개 파일 · 0건 · 0건 · `DatePicker("날짜·시각", …)` `:227`, `.graphical` `:231` | spec §1.2 분 간격 사실 |
| WebFetch `…/uikit/uidatepicker/minuteinterval.json` | "The default and minimum values are 1; the maximum value is 30." | 〃 |
| WebFetch `…/uikit/uiscrollview/isscrollenabled.json` | "Setting the value to false disables scrolling." "When scrolling is disabled, the scroll view doesn’t accept touch events; it forwards them up the responder chain." — 프로그램 오프셋 언급 없음 | D-11 〔가설〕 유지 |
| WebFetch `…/quartzcore/cadisplaylink/init(target:selector:).json` | "The newly constructed display link retains the target." — 무효화 언급 없음 | D-11 타이머 |
| WebFetch `…/uikit/uigesturerecognizer/location(in:).json` | "Returns the point computed as the location in a given view of the gesture …" | D-11 위치 재읽기 |
| `sed -n 85,110p Shared/EventDetailView.swift` · `grep -rn 'activity(forLeg' Shared/` | 편집 시트 `:91-98`(`activity(forLeg:)` 있으면 활동 편집, 없으면 `AddEventView`) · 호출 `ContentView.swift:662`·`EventDetailView.swift:94` | Q-10 |
| `sed -n 306,365p;575,600p;1547,1560p;1626,1640p Shared/Store.swift` · `grep -n 'if let newStart {\|let listedIDs\|…'` | `modifyActivity` 시작 `:325`, 끝 재정렬 `:339-344`, `realignReturnLeg` `:352-359`(명시만 `:353`), `realignLegs` 명시 `:587`, `listedIDs` `:439`, `removeExplicitLegs` `:1630-1642`(13줄) | research §9 |
| `grep -rn 'F12' …SPEC-UIKIT-009/*.md` | `spec.md:90`(정의) · `:197`(범위 밖) · `research.md:41-42` | 인계 §7 |
| 자가 점검 바이너리 재실행(`…/scratchpad/v050/check`) | 첫 줄 `AF-018-06 … -55` · `AF-018-07 … 0 \| -15` · `AF-018-08 … 90` — 0.5.0과 같음(한계 규칙 무변경, 드래그 최소 5분 무변경) | plan §5 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` | `16` · `15` | Tier |
| `grep -c 'NEEDS CLARIFICATION'` spec · acceptance · plan · research | `0` · `0` · `6` · `6` | 열린 질문 위치 |
| `grep -o 'B + 2[0-9]' spec.md plan.md acceptance.md \| sort \| uniq -c` | spec 2 · plan 2 · acceptance 1, 모두 `B + 24` | T 일치 |
| `grep -c '축\|기둥'`(네 파일) | 모두 `0` | 문체 |
| `grep -n 'removeFromCalendar\|enqueueCalendarUpload\|googleConnected\|AF-018-28\|S-15\|S-12' spec.md acceptance.md` | acceptance `:122`(구글 0건 대조 자체) · `:138`(이관 표기) · spec HISTORY `:31` · 대응표 `:129` — 그 밖 0 | 구글 서술 이관 확인 |
| `wc -l *.md` | acceptance 222 · plan 274 · progress(이 절 전) 369 · research 149 · spec 248 | 보고 |

## §H 0.6.0 개정 요약

### ① 사라진 것 · 새로 생긴 것 · 바뀐 것

명령: 0.5.0 판(작업 트리, 커밋 전)을 SPEC 디렉터리에 `cp`로 떠 두고 `grep -o`로 식별자를 뽑아 `comm`으로 비교한 뒤 사본을 지웠다(`ls` → 다섯 파일). 출력:

```text
== REQ old=16 new=16  removed: (없음)  added: (없음)
== AC  old=15 new=15  removed: AC-014  added: AC-016
== S   old=15 new=16  removed: S-12 S-15  added: S-16 S-17 S-18
== AF(표의 행 머리) old=30 new=23  removed: AF-018-03 05 12 13 19 20 21 22  added: ~~AF-018-28
```

AF 줄은 표 모양 탓에 숫자가 어긋난다 — 0.6.0 표가 같은 기대의 행을 합쳤다(`AF-018-02·03`, `04·05`, `11~13`, `18~22`). 계수 규칙(번호 하나 = `drvCheck` 하나)으로 센 실제 변화는 **AF-018-28 하나가 빠진 것**이고(인계 파일), 번호 집합은 AF-018-01~27 + AF-015-09·11이다.

| 구분 | 목록 | 수 |
|---|---|---|
| 사라짐(→ t48 인계) | AC-014 · AF-018-28 · S-12 · S-15 · Q-7 · 0.5.0 REQ-012 구글 본문 | 1 · 1 · 2 |
| 새로 | AC-016 · S-16·17·18 · Q-10·11·12 · `research.md` §9 | 1 · 3 · 3 |
| 다시 씀 | REQ-012(0.4.1 형태로 되돌림) · REQ-015(자동 스크롤 본 요구) · D-11 · S-6 · AC-010(구글 0건 대조 복원) | — |
| 바뀜 | REQ-003·006·009·013·016 · AC-004·012·013·015 · AF-018-27 · AF-015-09·11(근거 = 운영자 2차 Q-6) · S-5·13·14 · D-3·D-4(정정)·D-6·D-10 | — |
| 닫힌 질문 | Q-1(답변) · Q-2(사실 — 1분) · Q-4(답변) · Q-6(답변) · Q-8(답변) · Q-7(이관) | 6 |

### ② 수치 · Tier · T

REQ **16** · AC **15**(Tier M 상한 각 16, 서로 독립 — 리드 안내의 "합 25"는 규칙과 다르다). 자동 스크롤은 REQ-015 둘째 조항으로 접었다 — 따로 세우면 REQ 17로 Tier M 초과(Q-12, 리드 판단). 드라이버 고쳐 쓰기 4 · 추가 24 → **T = B + 24**(B = 498이면 522).

### ③ 자동 스크롤 설계 요지

- 오버레이는 `ScrollView` 안이라 손가락 위치가 콘텐츠 좌표다 → 보정은 매 틱 `location(in:)`을 다시 읽는 것으로 충분, 오프셋을 더하면 두 번 더해진다. 분 변환은 `onChange` 한 곳.
- 손가락이 멈추면 인식기 이벤트가 없으므로 `CADisplayLink` 틱이 위치를 다시 읽고 `onChange`를 부른다.
- 띠 12%·최소 44pt, 깊이 비례 최대 600pt/초〔제안〕. 위는 콘텐츠 맨 위에서, 아래는 콘텐츠 끝에서 멈춘다. 놓으면 연장이 사라져 화면이 하루 끝으로 튀어 오른다(S-17).
- 멈춤 함수 하나를 `.ended`·`.cancelled/.failed`·`onBegin` 거절·`dismantleUIView`·창에서 빠짐·틱 안 상태 검사가 부른다. 대상은 약한 대리 객체(문서: 디스플레이 링크는 대상을 붙잡는다).
- **확인한 것**: 코드 구조(오버레이 위치·좌표·분 변환·조상 스크롤 뷰 찾기), Apple 문서 세 건(위 표). **못 한 것**: `scrollDisabled` 중 `setContentOffset`이 먹는지(문서는 터치만 언급 — 〔가설〕, 대체안: 잠금 대신 팬 인식기 끄기), SwiftUI `.scrollDisabled`가 `isScrollEnabled`를 쓰는지, 백그라운드 전환 시 `.cancelled` 수신, 스크롤 영역 밖 손가락 위치 보고, `CADisplayLink`의 격리 경고, 감각 매개값.

### ④ 열린 질문 · 〔가정〕 · 착수 승인 설명

열린 질문(plan §2 끝 · research §8): Q-3 위로 넘기기 · Q-5 연장 상한 · Q-9 연장 대상 · Q-10 짧은 활동 탭 경로 · Q-11 편집 끝 변경의 추정 복귀 구간 · Q-12 Tier.

〔가정〕: 그리기 바닥 5분(5분 이상은 실제 길이) · 이동 최소 높이 16분 유지 · "같은 블록" = 활동 + 가는 편 + 오는 편 묶음 연결 유지(정정 — 0.5.0의 "레코드 하나가 날짜별로 보임" 해석을 고침) · 위로는 첫날 0시에서 멈춤 · 아래 상한은 끄는 날 다음 날 끝 · 경고 블록은 나열 시각 하나 · 연장·자동 스크롤은 연결된 구간 드래그만 · 자동 스크롤 매개값.

착수 승인 설명은 `plan.md` §9(①의 전후 그림 — 자정 넘기기 + 자동 스크롤 + 한 묶음 + 짧은 활동 높이, ②의 확인 목록).

### ⑤ 실행한 검증 · 못 한 검증

실행: 위 0.6.0 실측 표 전부, Apple 문서 WebFetch 4건(JSON 엔드포인트 — HTML 페이지는 본문이 비어 JSON으로 다시 받았다), 자가 점검 바이너리 재실행, 식별자 `comm`, 새 인용 줄 재측정(`:417`·`:939`·`:893`·`:804`·`:325`·`:339`·`:439`·`:587`·`:1630-1642`를 고쳤다).

못 한 것: 드라이버·iOS 빌드·시뮬레이터, 자동 스크롤의 모든 실제 동작(③의 〔가설〕), 5분 블록의 실제 탭 가능성, 구글 관련 전부(t48), 독립 감사.

### ⑥ 5~19분 활동의 탭 경로

- 히트 범위는 그리기와 같은 `span`이라 실제 길이로 줄어든다 — 5분 ≈ 4.7pt, 10분 ≈ 9.3pt, 19분 ≈ 17.7pt(56pt/시간). 지금은 20분 바닥 ≈ 18.7pt.
- 운영자 근거("가는 이동을 눌러도 같은 창")는 **명시 연결 구간에서만** 성립한다 — `EventDetailView.swift:94`가 `activity(forLeg:)`(명시만)로 활동 편집을 고르고, 반복 회차의 추정 구간은 이동 일정 폼(`AddEventView`)을 연다.
- 대체 경로가 없는 경우: 구간 없는 활동, 반복 회차 활동(구간이 추정). Q-10에서 (a) 그대로 · (b) 히트 범위만 최소 보장(계약 5의 한 곳 계산이 두 값을 냄) · (c) 추정 구간 탭 라우팅 확장(범위 밖 파일)을 물으며, 이 레인의 기울기는 (a) + S-18 관찰 후 결정.
- 반폭 분할은 줄어든다(바로 붙은 오는 편과 겹치지 않음).

## §E.2 Run-phase Evidence

_<pending run-phase>_

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_
