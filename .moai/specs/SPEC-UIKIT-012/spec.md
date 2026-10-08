---
id: SPEC-UIKIT-012
title: "연결된 이동 구간 드래그 재설계 — 오는 편은 활동 끝을, 가는 편은 활동 시작을 옮긴다 · 최소 길이·자정 한계 · 미리보기와 확정의 단일 출처"
version: "0.4.1"
status: draft
created: "2026-10-08"
updated: "2026-10-08"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "drag, travel-leg, activity-resize, timetable, single-source, recurrence, guard-driver"
tier: M
related_specs: [SPEC-UIKIT-009, SPEC-UIKIT-011]
kanban_card: t43
---

# SPEC-UIKIT-012 — 연결된 이동 구간 드래그 재설계

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-10-08 | 최초 작성. 칸반 카드 **t43**(시뮬레이터 4묶음 18번 메모 — 운영자 지시)을 GEARS로 정식화했다. 기준 트리는 `b59fcaa`(브랜치 `WT-leg-drag-resize`). 방향 ④(가는 편 = 시작만, 오는 편 = 끝만)는 2026-10-08 칸반 리드의 질문에서 운영자가 확정했다 — **이 세션은 운영자의 답을 직접 보지 않았고 리드가 전한 것을 적었다**(SPEC-UIKIT-009 `plan.md` D-6과 같은 표기). |
| 0.2.0 | 2026-10-08 | **plan 감사 1회차(FAIL 0.60, `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`, 결함 D-1~D-22) 반영.** 오케스트레이터가 보낸 설계 확정안(〔제안〕)을 적용했다. ① 반복 "전체"의 대상을 소유 활동과 같은 역할(같은 반복·같은 제목·같은 장소 이름)의 회차로 좁혔다(REQ-010, 감사 D-2). ② 역방향 조회를 명시 연결 → 정방향 `linkedLegs(for:)` 재사용 → 앵커 시각 동률 규칙 → 모호하면 소유 없음으로 다시 정의했다(REQ-004, D-3). ③ 옛 드래그로 이미 틈이 생긴 오는 편은 틈을 그대로 두고 함께 옮긴다(REQ-001·002, D-4). ④ 자정 한계를 "구간 블록이 이미 닿은 날 안에 머문다, 도착은 다음 날 0시 미만"으로 바꿨다(REQ-007, D-5·D-7·D-9). ⑤ 연결된 구간의 미리보기를 `span(for event:on:)` 안으로 옮겼다(REQ-009, D-6). ⑥ 반복 일괄은 `moveActivity`와 같은 모양(기존 `shiftEvent` 루프 + 저장 한 번)으로 바꿨다(REQ-010, D-14). 게이트 표식 4건(최소 길이·자정·구글·SPEC-009 처리)은 착수 승인 몫으로 `plan.md` §2에 남겼다. REQ 14 → 14, AC 12 → 12, 드라이버 추가 단언 15 → 19. 줄번호는 다시 쟀다(`progress.md` §E.1 0.2.0 표). |
| 0.3.0 | 2026-10-08 | **plan 감사 2회차(FAIL 0.80, `.moai/reports/plan-audit/SPEC-UIKIT-012-review-2.md`, N-1~N-15) 반영 — 마지막 수정.** ① 자정 한계를 "끌린 구간의 출발·도착이 각자 지금 날짜에 머문다" 한 규칙으로 바꿨다 — 0.2.0 규칙은 자정을 걸친 구간을 그리는 날 밖으로 통째로 옮길 수 있어 `span`이 하루 전체 높이 블록을 그렸다(REQ-007, N-1). ② 소유 활동은 드래그 시작 때 한 번 구해 드래그 값에 담고, 후보는 같은 반복·같은 날 활동으로 먼저 좁힌다(REQ-004·008·009, N-2). ③ REQ-003의 "다른 것은 바꾸지 않는다"를 반복 대상·알림 식별자 재배정과 맞게 한정했다(N-4). ④ 출발 없는 경고 블록 오는 편은 동률 비교에서 제외한다(동률 불성립 → 후보가 둘이면 소유 없음, N-5). ⑤ 같은 역할 구간이 없는 회차는 건너뛴다(REQ-010, N-10). 게이트 4건은 그대로다. REQ 14 · AC 12, 추가 단언 19 → 20(AF-018-23). |
| 0.4.0 | 2026-10-08 | **plan 감사 3회차(FAIL 0.71, `.moai/reports/plan-audit/SPEC-UIKIT-012-review-3.md`, R3-1~R3-10 · G-1) 반영 — 재감사 없음, 고친 대조는 이 레인이 직접 돌려 `progress.md` §E.1 0.4.0 표에 남겼다.** ① REQ-007을 나열 판정(`Store.overlapsDay`·`ScheduledEvent.isListed(on:)`의 반열린 규약)에 맞췄다 — 출발은 끌기 전 나열된 첫날 안(0시 포함), 도착은 마지막 날 안에 **엄격히**(그 날 0시도 다음 날 0시도 아님). 0.3.0은 자정을 걸친 구간의 도착을 0시 정각으로 보낼 수 있어 그 날 목록에서 빠졌다(R3-1). AF-018-10 −15 → **−5**, AF-018-23은 `isListed(on:)`로 잰다. ② 드롭은 구간·소유 활동을 id로 저장소에서 다시 읽어 현재 값으로 자른다(REQ-008, R3-3, AF-018-24 추가). ③ 5분 단위를 Store 상수 하나로(R3-6). ④ AC의 구조 대조를 macOS `awk`에서 돌아가게 고치고 양성 대조를 붙였다(R3-2). 게이트 D-4 설명에 예시와 셋째 안을 더했다(G-1). 출발 없는 경고 블록은 가는 편·오는 편 모두 동률 비교에서 제외한다 — 가는 편은 도착이 있어 늘 비교되고, 오는 편만 출발이 없을 수 있다(R3-4, 비대칭은 `plan.md` §7). REQ 14 · AC 12, 추가 단언 20 → **21**. |
| 0.4.1 | 2026-10-08 | **plan 재감사 4회차(`.moai/reports/plan-audit/SPEC-UIKIT-012-review-4.md`)의 차단 결함 N4-1만 수리 — 범위 축소, 5회차 없음.** 출발이 있는 경고 블록(재추정 실패로 `travelSeconds = nil`, 출발과 옛 도착이 남은 오는 편 — `Store.swift:1320`·`:1327`)은 앵커(출발)의 날 하루에만 나열되는데(`Models.swift:230`) 0.4.0 REQ-007은 나열에 쓰이지 않는 옛 도착까지 묶어, 출발 23:50·옛 도착 00:10에서 +15 요청이 **−10**(반대 부호)이 됐다. 0.4.1: ① REQ-007 — 경고 블록과 나열 구간이 없는 깨진 레코드는 나열을 정하는 시각(경고 블록은 앵커, 깨진 레코드는 도착) 하나만 그 날 안에 머물면 된다 ② REQ-008 — 유효 Δ는 요청과 반대 부호가 되지 않는다(되면 0) ③ AF-018-25 추가. 자가 점검(실제 술어를 옮긴 독립 스크립트)의 출력은 `progress.md` §E.1 0.4.1 표에 있다. 경미 N4-2~N4-7은 범위 밖으로 남겼다. REQ 14 · AC 12, 추가 단언 21 → **22**. |

## 0. 이 SPEC의 성격과 예산

**운영자가 방향을 정한 동작 변경의 계약이다.** 무엇을 바꿀지는 18번 메모와 방향 ④가 정했고, 이 SPEC은 그 방향이 코드에서 닿는 자리와 한계(최소 길이·자정)·모호한 데이터의 처리를 적는다. 지시는 다시 묻지 않는다.

**Tier: M.**

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 바꾸는 소스 파일 | **3** — `Shared/Store.swift`(1828줄) · `Shared/ContentView.swift`(972줄) · `Tools/GuardDriver.swift`(5366줄). 새 파일 없음 | `wc -l` |
| 드라이버 단언 | 제자리 고쳐 쓰기 2(AF-018-02·03) · 추가 22(AF-018-04~25) | `plan.md` §5 |
| REQ · AC | **14 · 12** — Tier M 상한 16 아래 | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` |

Tier S를 넘는 이유는 셋이다. 저장 동작(Store)과 화면 미리보기(ContentView)가 같은 한계·소유 조회 함수를 함께 읽어야 하고(계약 5), 반복 일정의 회차별 적용과 한 반복 안의 여러 활동(체류·점심시간)이 엮이며, 끄는 느낌·배치는 사람만 볼 수 있어 시뮬레이터 절이 필요하다. 크게 고치는 파일은 3개라 한 Day 한도(3~4) 안이다. 새 `Shared/` 파일이 없으므로 `xcodegen generate`와 서명 팀 재선택이 없다.

## 1. 배경

### 1.1 운영자 지시

원문은 `.moai/reports/2026-10-05-sim-4bundle-result.md:65`의 18번 메모다(같은 파일 `:23`이 카드 t43을 만들었다).

> "명세대로. 다만 오는 이동 블록을 길게 눌러 이동하면 활동의 시간 또한 변경되는 것이 좋아보임. (오는 이동을 아래로 30분 끌면 활동 블록도 30분 추가.) 이와 통일성을 맞추기 위해 가는 이동 또한 꾹 눌러 이동 시 버퍼가 바뀌는 것이 아니라 활동 블록의 시작 시간이 바뀌도록 설정."

| 항 | 지시 | 출처 |
|---|---|---|
| 메모 | 오는 이동을 아래로 30분 끌면 활동이 30분 늘어난다. 가는 이동을 끌면 버퍼가 아니라 활동 시작이 바뀐다 | 〔운영자〕 18번 메모 |
| ④ | 가는 편 드래그 = **시작만** 움직이고 끝은 고정(위로 끌면 길어지고 아래로 끌면 짧아진다). 오는 편 드래그 = 대칭으로 **끝만** 움직이고 시작은 고정. 다른 안 "활동 전체를 옮긴다"는 운영자가 버렸다 | 〔운영자 — 리드 경유, 2026-10-08〕 이 세션은 답을 직접 보지 않았다 |
| ⑤ | 연결된 활동이 없는 이동 구간은 지금 동작 그대로 | 〔제안〕 리드 제안, 이의 없음 |

### 1.2 지금 동작 (기준 트리 `b59fcaa`, 코드 열람)

- **제스처**: `RescheduleOverlay`가 0.35초 길게 누르기로 시작하고(`Shared/ContentView.swift:899`), 세로 이동량을 5분 단위로 반올림해 `ActiveDrag.deltaMinutes`에 담는다(`:464-465`). 한계는 어디에도 없다. 놓을 때 `deltaMinutes != 0`이면 `finalizeDrag`(`:767-786`)를 부른다(`:470`).
- **확정**: 이동 구간이면 반복 일정(`recurrenceId != nil`, `:778`)일 때 "전체 반복 일정 이동 / 이 일정만 이동" 대화상자(`:176-182`)를 거쳐, 아니면 바로 `store.adjustTravelLeg(e, byMinutes:wholeSeries:)`(`:780`·`:783`)를 부른다.
- **`adjustTravelLeg`**(`Shared/Store.swift:1387-1410`): "전체"면 같은 반복·같은 앵커·같은 목적지(가는 편)/출발지(오는 편) 이름의 구간을 고르고(`:1392-1395`), 루프(`:1400-1408`)에서 출발 기준 구간은 `shiftEvent`로 통째 평행이동하고(`:1404`), 도착 기준 구간은 `adjustBuffer`로 도착을 고정한 채 여유를 `clampBuffer(buffer − Δ)`로 바꾼다(`:1406`, 상하한 `:62`). 활동은 **건드리지 않는다**. 저장은 루프 뒤 한 번(`:1409`).
- **미리보기**: `offsetY(for:)`(`ContentView.swift:514-521`)가 끌리는 블록에만 `dragOffsetMinutes`(`:595-603`)를 더한다 — 순수 평행이동이고 연결된 활동은 미리보기에서 움직이지 않는다.
- **블록 범위의 단일 출처**: `span(for activity:on:)`(`:543-556`)과 `span(for event:on:)`(`:558-592`)이 렌더·높이·배치(`positionedBlocks` `:711-734`, 호출 `:717`·`:722`)·히트 테스트(`block(atX:y:)` `:753`)가 함께 읽는 유일한 계산이다(`CLAUDE.md` 계약 5). 활동 최소 그리기 높이 `minActivityMinutes = 20`은 `ContentView`의 private 상수다(`:531`).

그래서 오는 편을 아래로 끌면 활동 끝과 오는 편 사이에 틈이 벌어지고, 가는 편을 끌면 출발 시각과 여유만 바뀐다. 이것이 SPEC-UIKIT-009 결정 D-6 (a)로 문서화된 지금의 의미다(`.moai/specs/SPEC-UIKIT-009/plan.md:135-143`).

### 1.3 이 SPEC이 조사로 찾은 것

(가) **딱딱한 평행이동이면 불변식이 저절로 지켜진다.** 가는 편은 `arrivalDate == activity.startDate`이고 여유는 구간 블록 **안의** 여유다(출발 = 도착 − 이동시간 − 여유, `Shared/Models.swift:165`). 오는 편은 `departureDate == activity.endDate`이고 여유가 0이다(`legAnchor` `Shared/Store.swift:378-380`). 그러니 활동 가장자리를 Δ만큼 옮기고 같은 쪽 구간을 기존 `shiftEvent`(`:1439-1447` — 도착·출발에 같은 Δ, 알림 재예약 `:1446`)로 Δ만큼 옮기면 이동시간·여유·출발 산식이 모두 그대로다. 출발 산식(`@MX:DEBT` `Store.swift:1304`)도 평행이동 산술도 새로 쓰지 않는다.

(나) **연결은 두 가지이고 정방향 조회가 이미 둘을 순서대로 본다.** 명시적 연결(`linkedActivityId`, `Models.swift:191`)과 반복 회차의 추정 연결(`estimatedLegs(for:)` `Store.swift:1427-1433` — 같은 `recurrenceId`, 활동 시작일과 같은 날 도착, 장소 이름 대조, 같은 조건이면 `.first`)이다. 활동 → 구간 방향은 `linkedLegs(for:)`(`:1414-1422`)가 명시 먼저, 없으면 추정을 본다. 구간 → 활동 방향은 명시적 연결만 보는 `activity(forLeg:)`(`:415-418`)뿐이다.

(다) **한 반복에 활동이 둘일 수 있다.** AI 반복 생성은 출근·복귀·점심 이동·점심 후 복귀 구간과 체류·점심시간 활동을 한 `recurrenceId`로 만든다(`Shared/AIAssistant.swift:2321` → `:2336`·`:2344`·`:2359`·`:2364`·`:2376`). 점심 장소가 없으면 점심시간 활동의 장소가 목적지가 되어(`:2371` `lunchPlace ?? dest`) 체류와 점심시간이 같은 출근·복귀 구간을 추정으로 주장한다. 그래서 역방향 조회에는 동률 규칙이 필요하고(REQ-004), "전체"의 대상은 반복 전체가 아니라 소유 활동과 같은 역할의 회차여야 한다(REQ-010). 지금 코드도 "전체"에서 역할 필터를 쓴다(`Store.swift:1392-1395`).

(라) **명시적 구간은 `recurrenceId`를 갖지 않는다.** `addEvent`(`Store.swift:868`)의 매개변수에는 `recurrenceId`가 없고 `recurrenceId`를 넣는 곳은 반복 생성(`:955`)뿐이다. 반복 회차에 명시적 구간이 붙은 옛 데이터는 있을 수 있지만(`addLeg`는 명시적 구간이 **없을 때만** 거절한다 `:481-482`) 그 구간은 `recurrenceId`가 없어 대화상자 없이 "이 일정만"으로 움직인다.

(마) **옛 의미로 틈이 생긴 데이터가 있다.** 지금 의미로 오는 편을 끌면 출발 ≠ 활동 끝인 구간이 남는다 — 운영자의 스크립트 18이 그 틈을 만들었다(SPEC-UIKIT-009 `acceptance.md:456`). 새 의미는 그 틈을 고치지 않고 함께 옮긴다(REQ-001). 틈은 구간 상세를 저장하면 닫힌다(SPEC-UIKIT-009 `design.md:126`).

(바) **자정을 넘는 구간과 같은 날 추정이 어긋난다.** 화면은 자정을 넘는 블록을 이틀에 나눠 그리지만(`span` 주석 `ContentView.swift:540`), 추정 연결은 같은 날만 대조해 다음 날 도착하는 오는 편을 놓친다(`@MX:WARN` `Store.swift:436`, 드라이버 AF-015-11 `Tools/GuardDriver.swift:4321`). 도착이 정확히 다음 날 0시여도 같은 날 대조가 깨진다(`cal.isDate($0.arrivalDate, inSameDayAs: activity.startDate)` `Store.swift:1430`). **이 근거는 반복 추정 구간에만 해당한다** — 명시 연결 구간은 날짜와 무관하게 이어진다. 그래도 한계를 두 종류 구간에 같게 두는 이유는 나열 판정 때문이다: 시간표는 반열린 구간 `[출발, 도착)`이 그 날과 겹칠 때만 구간을 그 날에 나열하므로(`Store.overlapsDay` `Store.swift:38-41`, `ScheduledEvent.isListed(on:)` `Models.swift:229-235`) 끌기가 나열되는 날을 바꾸면 끄는 화면에서 블록이 사라진다(REQ-007).

(사) **같은 묶음 구성원이 겹치면 반폭으로 갈린다.** 배치는 소유 묶음(`packingGroups` `Store.swift:438-452`)의 구성원이 서로 겹치면 나란히 그린다(`ScheduleLogic.overlapSlots` `Models.swift:395`, 이유 `@MX:NOTE` `:388-392`). 끄는 동안 활동만 `span`에서 늘이고 구간을 `offsetY`로 평행이동하면, 배치는 구간의 **저장된** 범위로 겹침을 판정해 둘이 반폭으로 갈렸다가 놓는 순간 전폭으로 돌아온다. 그래서 연결된 구간의 미리보기도 `span(for event:on:)` 안에서 옮긴다(REQ-009).

(아) **AI 가드의 주석 전제는 좁아지지만 남는다.** `zeroUpdateIssue` 주석(`Shared/AIAssistant.swift:2582-2586`)은 "한 회차를 드래그해 여유를 바꾼 시리즈(`adjustTravelLeg` → `adjustBuffer`)"를 회차별 값이 갈리는 예로 든다. 이 SPEC 뒤 소유 활동이 있는 반복 구간은 여유를 바꾸지 않지만, 소유 활동이 없는 반복 구간(복귀 시각이 없는 반복은 활동이 생기지 않는다 `AIAssistant.swift:2331`)은 지금 경로(`adjustBuffer`)를 그대로 탄다. 가드는 그대로 옳다 — 이 SPEC은 `AIAssistant.swift`를 바꾸지 않는다(REQ-014).

### 1.4 이웃

| 대상 | 관계 |
|---|---|
| SPEC-UIKIT-009 (completed) | 결정 D-6 (a)·REQ-018의 드래그 의미 절·AC-018 (2)(3)·스크립트 18을 이 SPEC이 대체한다. 동결된 SPEC이라 그 파일은 고치지 않는다(권장, `plan.md` D-8 게이트). |
| `moveActivity` | 활동 블록 드래그. 바꾸지 않는다 — 이 SPEC의 확정 경로는 이것과 같은 모양(기존 `shiftEvent` 루프 + 루프 밖 저장)을 따른다. |
| CHECKLIST K13 | 이 카드의 ❌ 행. run 뒤 sync가 갱신한다(`plan.md` §6). |
| t44 | 문서 인용 재사상. 이 카드가 `ContentView.swift`·`Store.swift` 줄을 옮기므로 CHECKLIST D8·K7 인용이 밀릴 수 있다 — sync 몫. |

## 2. 요구사항 (GEARS)

### [DELTA] A 연결된 구간 드래그의 의미

- [EXISTING] 제스처(0.35초, 5분 단위), 대화상자 문구, `finalizeDrag`의 두 호출(`ContentView.swift:780`·`:783`)과 `adjustTravelLeg` 서명 — 그대로 둔다.
- [MODIFY] `Store.adjustTravelLeg`(`Store.swift:1387-1410`) — 소유 활동이 있는 구간은 활동 가장자리를 옮긴다.
- [NEW] 구간 → 소유 활동 조회 함수 하나(화면과 저장이 함께 읽는다).

- **REQ-001 (Event-driven)**: When the user drops a return leg (departure-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's end by Δ, keep its start, and shift the return leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's departure equals the activity's end after the drop if it did before, and an existing gap between them stays the same. 근거: 18번 메모 "오는 이동을 아래로 30분 끌면 활동 블록도 30분 추가"와 방향 ④〔운영자〕. 옛 드래그로 틈이 생긴 데이터(§1.3 (마))는 틈을 그대로 두고 함께 옮긴다〔제안 — 오케스트레이터 확정안〕 — 드래그가 불변식을 고치지 않고, 상세 저장이 닫는다.

- **REQ-002 (Event-driven)**: When the user drops an outbound leg (arrival-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's start by Δ, keep its end, and shift the outbound leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's arrival equals the activity's start after the drop if it did before. 근거: 18번 메모 "버퍼가 바뀌는 것이 아니라 활동 블록의 시작 시간이 바뀌도록"과 방향 ④〔운영자〕. 출발 알림은 `shiftEvent`의 재예약(`Store.swift:1446`)으로 시작과 함께 움직인다.

- **REQ-003 (Ubiquitous · Unwanted)**: The leg drop of REQ-001 or REQ-002 shall change the schedule only of the owning activity and its dragged-side leg — and, for a series move under REQ-010, of the same-role occurrences and their dragged-side legs; it shall not change the other leg of any of those activities, any other activity or event, or any dragged leg's buffer or travel time, where re-assigning notification identifiers by the notification refresh is not a schedule change; and the change shall not add another copy of the departure-time computation or of the leg-shift arithmetic. 근거: 지시의 "틈 없이"와 §1.3 (가). 평행이동은 기존 `shiftEvent`를 부른다. 알림 갱신은 모든 이벤트의 `notificationId`를 비우고 다시 매기므로(`Store.swift:1534`·`:1538`) 그것을 예외로 적었다(감사 2회차 N-4).

- **REQ-004 (Ubiquitous)**: The store shall resolve the owning activity of a leg in one function that both the timetable preview and the drop read, in this order: (a) when the leg has an explicit link to an existing activity, that activity, and when the link is dangling, none; (b) otherwise, when the leg has a recurrence id, the candidates are the activities of that recurrence starting on the calendar day of the leg's arrival whose forward leg lookup (the existing explicit-first, else estimated, lookup) contains the leg; one candidate is the owner; with two or more, only the candidates whose anchor time equals the leg's anchor-side time (outbound: leg arrival equals activity start; return: leg departure equals activity end, and a missing departure never equals) remain, and exactly one remaining candidate is the owner; (c) in every other case the leg has no owner. 근거: §1.3 (나)(다). 정방향(`linkedLegs(for:)` `Store.swift:1414-1422`)을 다시 써서 명시 우선 순서가 양방향에서 같고 둘째 매칭 규칙이 생기지 않는다. 모호하면 추측하지 않는다 — `@MX:WARN`(`:436`)과 같은 태도다. 같은 날로 먼저 좁혀도 결과는 같다 — 추정 대조가 활동 시작일과 같은 날 도착만 보기 때문이다(`:1430`). 좁히는 이유는 비용이다(반복 활동 수 × 이벤트 수, 감사 2회차 N-2). 출발이 없는 경고 블록 오는 편(`failedBlockAnchor` `Models.swift:210-213`)은 동률이 성립하지 않아, 후보가 둘이면 소유 없음이 된다(N-5). 오케스트레이터 확정안은 후보 판정에 `estimatedLegs(for:)`를 직접 쓰라 했으나, 명시 구간이 있는 반복 활동(§1.3 (라))에서 정방향과 어긋나므로(감사 D-3 (b)) `linkedLegs(for:)`로 썼다 — 추정 경로는 그 안에서 `estimatedLegs(for:)`를 그대로 부른다〔조사〕.

- **REQ-005 (State-driven)**: While a dragged leg has no owning activity — including a dangling link and an ambiguous recurrence match — the store shall apply today's behavior unchanged: a departure-anchored leg shifts as a whole and an arrival-anchored leg keeps its arrival and absorbs the drag into its buffer, clamped as today. 근거: 방향 ⑤〔제안 — 리드, 이의 없음〕. 지금 코드 `Store.swift:1400-1408`.

### [DELTA] B 한계

- [NEW] 끌기의 유효 Δ를 정하는 Store 함수 하나. 화면의 최소 그리기 높이 상수는 Store의 정의를 읽는다.

- **REQ-006 (Ubiquitous · Unwanted)**: The leg drop shall not leave the owning activity shorter than the minimum activity length of 20 minutes, defined once in the store and read by the timetable's minimum drawing height; for an activity already shorter than that minimum, the limit shall reject any shortening and shall apply any lengthening unchanged. 근거: 운영자 지시는 한계를 말하지 않았다 — 〔제안〕(`plan.md` D-3 게이트). 화면은 20분 미만 활동도 20분 높이로 그리므로(`ContentView.swift:531`·`:555`) 그보다 짧게 줄이면 보이는 블록과 저장된 길이가 어긋난다.

- **REQ-007 (Ubiquitous · Unwanted)**: The leg drop shall keep the set of days on which the dragged leg is listed unchanged: with F and L the first and last day on which the leg is listed before the drag, the new departure (or the anchor time when the departure is missing) shall be on or after the start of F and before the end of F, and the new arrival shall be strictly after the start of L and strictly before the end of L. 근거: §1.3 (바) — 〔제안〕(`plan.md` D-4 게이트). 나열은 반열린 겹침 `출발 < 그 날 끝 && 도착 > 그 날 시작`이다(`Store.swift:38-41`, `Models.swift:229-235`). **이 규칙이 나열을 보존하는 이유(한 문장)**: 새 출발이 F 안이고 새 도착이 L 안(양 끝 제외)이면, F~L의 모든 날 d에 대해 출발 < F 끝 ≤ d 끝, 도착 > L 시작 ≥ d 시작이라 겹침이 참이고, F 앞의 날은 끝이 F 시작 ≤ 출발이라, L 뒤의 날은 시작이 L 끝 > 도착이라 겹침이 거짓이다 — 나열되는 날의 집합이 끌기 전과 같다. 도착이 L의 0시보다 엄격히 뒤여야 하는 이유: 자정을 걸친 구간의 도착이 L 0시 정각이 되면 반열린 규약으로 L 목록에서 빠지고, 미리보기가 토막이 됐다가 놓으면 사라지며, 다음 끌기의 하한이 0이 되어 그 활동을 오는 편으로 다시 줄일 수 없다(감사 3회차 R3-1). 도착이 L 끝(다음 날 0시) 정각도 막는 이유: 하루짜리 반복 추정 구간이 같은 날 대조(`Store.swift:1430`)를 잃는다. 끌기 전부터 이 조건을 어긴 옛 데이터(도착이 0시 정각)는 조건을 다시 만족하는 쪽(되돌리는 쪽)으로만 움직인다. **For a warning block (no travel time) and for a broken record with no listed span (departure missing, or arrival not after departure), only the listing time — the warning block's anchor time, or the broken record's arrival, which decides its single listed day d — shall satisfy start of d ≤ new value < end of d, and no other time of such a record shall enter the limit.** 근거: 경고 블록은 앵커의 날 하루에만 나열되고(`Models.swift:230`), 깨진 레코드는 도착의 날 하루에만 나열된다(`:234`). 재추정에 실패한 출발 기준 구간은 출발과 **옛** 도착을 남긴 채 `travelSeconds`만 비우므로(`Store.swift:1320`·`:1327`) 옛 도착은 나열에 쓰이지 않는다 — 0.4.0은 그것까지 묶어 반대 부호의 Δ를 냈다(감사 4회차 N4-1).

- **REQ-008 (Ubiquitous)**: For a leg with an owning activity, the effective Δ shall be computed by one store function that takes the leg and its already-resolved owning activity and uses only their times — no lookup over the stored schedules — from the requested Δ and the limits of REQ-006 and REQ-007, with times in seconds first truncated toward zero to whole minutes and the clamped result rounded toward zero to a multiple of the snap step, a single 5-minute constant defined once in the store and read by the gesture's rounding as well; the timetable gesture shall store that effective Δ as the drag's value during the drag, the drop shall re-read the dragged leg by its id from the stored schedule, resolve the owner once from that current value, and apply the store function again to the same requested value using only the current stored times — never the times of the leg value captured when the drag began — and shall change nothing when the leg id no longer exists, and when the effective Δ is 0 the drop shall change nothing. The effective Δ shall never have a sign opposite to the requested Δ; when the limits would produce an opposite sign, the effective Δ shall be 0. 근거(이 문장): 끌린 방향과 반대로 활동이 움직이는 일을 어떤 데이터에서도 막는 일반 안전 조항이다(감사 4회차 N4-1). 근거: 미리보기와 확정이 따로 한계를 계산하면 손을 놓는 순간 블록이 튄다(계약 5 — `span`이 같은 이유로 단일 출처가 됐다 `ContentView.swift:540`). 확정 때 저장소에서 다시 읽어 자르는 것은 드래그·대화상자 사이에 활성화 동기화나 재추정(`refreshUpcomingEstimates` `Store.swift:1547` — 출발 120분 이내 구간, 호출 `App.swift:101`)이 구간을 바꾼 경우를 막는다. 드롭이 받는 값은 `onBegin`에서 뜬 사본이다(`ContentView.swift:460`·`:780`·`:783`). 저장소가 그 사이 바뀌지 않았다면 결과는 미리보기와 같다. 소유 활동이 없는 구간은 지금 동작이라(REQ-005) 이 조항 밖이다.

### [DELTA] C 미리보기

- [MODIFY] `span(for activity:on:)`(`ContentView.swift:543-556`) · `span(for event:on:)`(`:558-592`) · `dragOffsetMinutes(forEvent:)`(`:600-603`) · 제스처 `onChange`(`:463-466`).

- **REQ-009 (State-driven)**: While a leg with an owning activity is being dragged, the timetable shall draw both that activity (start for an outbound leg, end for a return leg) and the dragged leg moved by the effective Δ inside the two block-extent functions, building the moved time before the same-day clipping, read through one view helper that names the dragged leg, its owning activity, and the effective Δ, where the owning activity is resolved once when the drag begins and kept in the drag value so that no block-extent, offset, or gesture-change computation resolves it again, so that rendering, layout, height, and hit-testing read the same moved extents and the dragged leg adds no separate translation; a leg without an owning activity shall keep today's translation preview. 근거: §1.3 (사) — 구간을 `offsetY`로만 옮기면 배치가 저장된 범위로 겹침을 판정해 끄는 동안 반폭으로 갈린다〔제안 — 오케스트레이터 확정안, 감사 D-6〕. 레인 느낌은 기기에서 확인한다(시뮬레이터 S-8).

### [DELTA] D 반복 일정

- [EXISTING] 대화상자는 끌린 구간의 `recurrenceId`로 켜진다(`ContentView.swift:778`) — 그대로.

- **REQ-010 (Event-driven)**: When the user chooses to move the whole recurring series for a dragged leg with an owning activity, the store shall apply REQ-001 or REQ-002 to every activity with the owning activity's recurrence id, title, and location name, each through that occurrence's own same-role leg found by the forward leg lookup and each with the dragged Δ limited by that occurrence's own limits, and shall skip an occurrence that has no such leg without editing that occurrence; it shall leave every other activity of the recurrence and its legs unchanged; it shall persist the activities once and the events once for the whole operation regardless of the number of occurrences, re-sort the activities by start once when any start changed, and re-schedule the nearest notifications once. 근거: §1.3 (다)〔제안 — 오케스트레이터 확정안, 감사 D-2〕 — 지금의 역할 필터(`Store.swift:1392-1395`)와 같은 뜻을 활동 쪽에서 적었다. 저장 규율은 지금 주석("회차마다 저장하면 26주 반복이면 130번" `:1409`)과 같다. 시작이 바뀌면 정렬해야 한다(`updateActivity`는 한다 `:286`). 알림은 iOS가 64건만 붙드므로 가장 가까운 60건을 다시 고른다(`rescheduleNearestNotifications` `:1519-1543`, 그 함수가 `save()`까지 한다 `:1542`).

- **REQ-011 (Event-driven)**: When the user chooses to move only this occurrence, or the dragged leg has no recurrence id, the store shall apply REQ-001 or REQ-002 to the dragged leg's owning activity only; the recurrence dialog shall continue to be keyed on the dragged leg's recurrence id. 근거: §1.3 (라) — 추정 구간은 `recurrenceId`를 갖고 명시적 구간은 갖지 않는다. 드라이버가 데이터 성질을, 구조 대조가 대화상자 키를 못박는다(AC-008).

### [DELTA] E 동기성 · 외부 동기화

- **REQ-012 (Ubiquitous · Unwanted)**: The leg drop shall complete synchronously — no `Task`, no `await`, no ignored `try?` — and shall not push the changed activity or leg times to Google Calendar, matching the activity drag today. 근거: 이 진입점은 동기 함수이고 `finalizeDrag`가 결과를 기다리지 않는다. 비동기 재정렬 `realignLegs(of:)`(`Store.swift:581`)는 쓰지 않는다. 구글 미반영은 `moveActivity`와 같은 물려받은 갭(SPEC-UIKIT-009 D-10 (a))이다 — 〔제안〕, `plan.md` D-6 게이트.

### [DELTA] F 드라이버 · 범위

- **REQ-013 (Ubiquitous)**: The guard driver shall assert the observable behavior of REQ-001 through REQ-011 by `plan.md` §5 — AF-018-02 and AF-018-03 rewritten in place and AF-018-04 through AF-018-25 added, each number one unconditional `drvCheck` call, with no fixture that waits on a travel-time estimate — and its run shall end with no ✗ and exit 0, with the new total recorded against a base total measured on the unchanged tree in the same run phase. 근거: 드라이버 하한 규칙. 하한은 코드가 강제하지 않고(`Tools/GuardDriver.swift:306` — 실패 0이면 0) 문서에만 있다. 새 총수 T = B + 22(`plan.md` §5).

- **REQ-014 (Ubiquitous · Unwanted)**: The change shall touch only `Shared/Store.swift`, `Shared/ContentView.swift`, and `Tools/GuardDriver.swift` among source files; shall add no source file, no AI class, no color outside `Theme`, and no secret; shall leave `proxy/`, `Shared/AIAssistant.swift`, and the activity drag (`moveActivity`) unchanged; shall keep `adjustBuffer` reachable from the no-owner path; shall keep the iOS build free of source warnings; and shall neither build nor verify the macOS app. 근거: `CLAUDE.md` 계약 1·2·4·6, Day 파일 한도, iOS 전용 방침(2026-09-30), §1.3 (아).

## 3. 바뀌지 않는 것

- 활동 블록 드래그(`moveActivity` `Store.swift:1361-1382`) — 활동과 두 구간이 함께 평행이동한다.
- 길게 누르기 0.35초(`ContentView.swift:899`), 5분 단위, 탭·스와이프, 드래그 중 스크롤 잠금.
- 대화상자 문구("전체 반복 일정 이동" / "이 일정만 이동" `ContentView.swift:180-181`).
- 소유 활동이 없는 구간의 드래그(REQ-005), 그 미리보기(평행이동).
- 끌기 뒤 겹침 검사를 하지 않는다 — 늘어난 활동이 다음 블록과 겹칠 수 있다. 활동 드래그도 지금 검사하지 않는다(`moveActivity`에 `conflicts` 호출 없음).
- 드래그를 되돌리는 기능(실행 취소)은 없다 — 지금도 없다.
- 구글 캘린더에 시각을 올리지 않는다(REQ-012).
- `realignLegs`·활동 상세 화면의 구간 편집, 배치 묶음 함수 `packingGroups`.
- AI 도구·프록시·`Theme` 토큰.

## 4. 범위 밖

### Out of Scope — 끌기 대상 확장

- 활동 블록의 가장자리를 직접 잡아 늘리기(크기 조절 손잡이)는 만들지 않는다.
- 드래그 중 자동 스크롤과 날짜 넘김은 만들지 않는다.

### Out of Scope — 데이터 수리

- 옛 드래그로 생긴 틈을 드래그가 닫지 않는다(REQ-001). 틈을 닫는 별도 이전 작업은 하지 않는다.
- 추정 연결의 같은 날 약점(`@MX:WARN` `Store.swift:436`)은 고치지 않는다 — 이 SPEC은 끌기가 그 약점을 새로 만들지 않게만 막는다(REQ-007).
- 배치 묶음(`packingGroups`)이 두 활동이 같은 구간을 주장할 때 고르는 활동과 REQ-004의 소유 활동이 다를 수 있다(`plan.md` §7 잔여 위험) — 묶음 규칙은 바꾸지 않는다.

### Out of Scope — 외부 동기화

- 바뀐 시각을 구글 캘린더에 반영하는 일(삭제 후 재생성)은 이 카드에서 하지 않는다 — 운영자가 다르게 정하면 별도 카드(`plan.md` D-6).

### Out of Scope — 맥 앱과 문서

- 맥 앱은 빌드·검증하지 않는다(iOS 전용 방침). 드래그 오버레이는 iOS 전용 코드다.
- 동결된 SPEC-UIKIT-009 파일은 고치지 않는다(권장) — 대체 관계는 이 SPEC이 기록한다.

## 5. 결정

미해소 결정은 `plan.md` §2에 있다. 착수 승인 뒤 이 표를 확정안으로 바꾼다.

| 결정 | 지금 상태 | 이 SPEC에서 닿는 곳 |
|---|---|---|
| D-1 의미(오는 편 = 끝, 가는 편 = 시작) | 〔운영자〕 확정 — 리드 경유 | REQ-001·002·003 |
| D-2 진입점·역방향 조회·동률 규칙 | 〔제안〕 오케스트레이터 확정안 | REQ-004·005·011 |
| D-3 최소 길이 20분 | 〔제안〕 게이트 | REQ-006 |
| D-4 자정 한계(나열되는 날 집합 불변 — 반열린 규약) | 〔제안〕 게이트 | REQ-007 |
| D-5 미리보기 = 확정(구간도 `span` 안, 소유는 드래그 시작 때 한 번) | 〔제안〕 오케스트레이터 확정안 | REQ-008·009 |
| D-6 구글 미반영 | 〔제안〕 게이트 | REQ-012 |
| D-7 반복 "전체" = 같은 역할 회차 · `moveActivity` 모양 일괄 | 〔제안〕 오케스트레이터 확정안 | REQ-010 |
| D-8 SPEC-UIKIT-009 대체 기록 | 〔제안〕 게이트 | §1.4 · §4 |
| D-9 옛 틈 데이터 = 틈 유지 | 〔제안〕 오케스트레이터 확정안 | REQ-001 |

## 6. 관련 문서

- `.moai/reports/2026-10-05-sim-4bundle-result.md:23`·`:65` — 카드 t43과 18번 메모 원문
- `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`·`-review-2.md`·`-review-3.md` — plan 감사 1~3회차
- [SPEC-UIKIT-009](../SPEC-UIKIT-009/spec.md) — 대체되는 드래그 의미(REQ-018, `plan.md` D-6)
- [SPEC-UIKIT-011](../SPEC-UIKIT-011/spec.md) — 형식 기준. 드라이버 하한 498은 루트 `plan.md:458`·`CHECKLIST.md:284`(`498/498`)
- `CHECKLIST.md:202` — K13
- 이 SPEC의 조사 기록 — `research.md`

🗿 MoAI
