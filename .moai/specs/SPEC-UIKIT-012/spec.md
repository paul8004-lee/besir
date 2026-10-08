---
id: SPEC-UIKIT-012
title: "연결된 이동 구간 드래그 재설계 — 오는 편은 활동 끝을, 가는 편은 활동 시작을 옮긴다 · 최소 5분 · 자정 넘기기와 끄는 중 연장·가장자리 자동 스크롤 · 자정을 넘어도 묶음 유지"
version: "0.6.0"
status: draft
created: "2026-10-08"
updated: "2026-10-08"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "drag, travel-leg, activity-resize, timetable, midnight, auto-scroll, single-source, recurrence, guard-driver"
tier: M
related_specs: [SPEC-UIKIT-009, SPEC-UIKIT-011]
kanban_card: t43
---

# SPEC-UIKIT-012 — 연결된 이동 구간 드래그 재설계

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-10-08 | 최초 작성. 칸반 카드 **t43**(시뮬레이터 4묶음 18번 메모 — 운영자 지시). 기준 트리 `b59fcaa`(브랜치 `WT-leg-drag-resize`). 방향 ④는 리드 경유 운영자 확정. |
| 0.2.0 | 2026-10-08 | plan 감사 1회차(FAIL 0.60) 반영 — 같은 역할 회차, 역방향 조회 순서, 옛 틈 유지, `span` 안 미리보기, `moveActivity` 모양 일괄. |
| 0.3.0 | 2026-10-08 | plan 감사 2회차(FAIL 0.80) 반영 — 소유는 드래그 시작 때 한 번, 출발 없는 오는 편 동률 불성립. |
| 0.4.0 | 2026-10-08 | plan 감사 3회차(FAIL 0.71) 반영 — 반열린 나열 규약, 드롭 재읽기, 5분 상수 하나. 〔0.5.0 정정 — N4-5: 동률은 가는 편이면 도착, 오는 편이면 출발로 잰다. 출발이 없는 오는 편은 동률이 성립하지 않는다〕 |
| 0.4.1 | 2026-10-08 | 재감사 4회차 차단 결함 N4-1만 수리. |
| 0.5.0 | 2026-10-08 | 운영자 게이트 답변 4건 반영(최소 5분 · 자정 넘기기와 끄는 중 연장 · 구글 삭제 후 재생성 · SPEC-UIKIT-009 무수정). 0.5.0 미감사. |
| 0.6.0 | 2026-10-08 | **운영자 2차 답변 반영 — 0.6.0 미감사(독립 감사 없음).** 원문은 §1.1(리드 전달 `.moai/reports/t43/split-answers.md`). ① **구글 반영을 새 카드 t48로 분리** — 0.5.0의 REQ-012 구글 본문·AC-014·AF-018-28·S-12·S-15·Q-7을 `.moai/reports/t43/google-card-handoff.md`로 옮기고, REQ-012는 0.4.1의 "동기 · 구글 미반영" 형태로 되돌렸다(물려받은 갭 F12, t48이 닫는다). ② **가장자리 자동 스크롤을 본 요구로**(REQ-015) — 손가락이 화면 위·아래 가장자리 띠에 머무는 동안 시간표가 따라 움직인다. ③ **이전 D-4 해석 정정** — "같은 블록"은 활동 + 가는 편 + 오는 편이 자정을 넘어도 한 묶음으로 남아 이동·편집 연계가 유지된다는 뜻이다. 그래서 정확한 앵커 시각 대조 우선(REQ-016)을 〔제안〕에서 운영자 근거가 있는 요구로 올렸다. ④ **활동 그리기 최소 높이를 실제 길이로**(REQ-006·009) — 20분 → 5분 바닥(〔가정〕). ⑤ 폼의 분 간격은 질문이 아니라 사실로 적었다(1분 — §1.2). REQ 16 → **16**, AC 15 → **15**, 드라이버 추가 25 → **24**(AF-018-04~27), 고쳐 쓰기 4. 바뀐 목록은 `plan.md` §11, 개수는 `progress.md` §H. |

## 0. 이 SPEC의 성격과 예산

**운영자가 방향을 정한 동작 변경의 계약이다.** 무엇을 바꿀지는 18번 메모·방향 ④·게이트 답변 넷·2차 답변 넷이 정했다. 이 SPEC은 그 결정이 코드에서 닿는 자리, 운영자가 말하지 않은 경계(위로 넘기기·연장 상한·연장 대상)의 〔가정〕, 모호한 데이터의 처리를 적는다.

**Tier: M** — 요구 16 · 수락 기준 15로 Tier M 상한(각각 16, 서로 독립 — `.claude/rules/moai/workflow/spec-workflow.md:146-152`)의 끝이다. 가장자리 자동 스크롤은 REQ-015 안에 넣었다 — 따로 세우면 요구가 17이 되어 Tier L(설계 문서 필요)이나 분할이 된다. 이것은 리드가 판단할 사항으로 `plan.md` §0에 적었다.

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 바꾸는 소스 파일 | **3** — `Shared/Store.swift`(1828줄) · `Shared/ContentView.swift`(972줄) · `Tools/GuardDriver.swift`(5366줄). 새 파일 없음. 자동 스크롤은 `ContentView.swift` 안의 오버레이(`:877-970`)에 붙는다 | `wc -l` |
| 드라이버 단언 | 제자리 고쳐 쓰기 4(AF-018-02·03, AF-015-09·11) · 추가 24(AF-018-04~27) | `plan.md` §5 |
| REQ · AC | **16 · 15** | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` |

## 1. 배경

### 1.1 운영자 지시

**18번 메모** — `.moai/reports/2026-10-05-sim-4bundle-result.md:65`:

> "명세대로. 다만 오는 이동 블록을 길게 눌러 이동하면 활동의 시간 또한 변경되는 것이 좋아보임. (오는 이동을 아래로 30분 끌면 활동 블록도 30분 추가.) 이와 통일성을 맞추기 위해 가는 이동 또한 꾹 눌러 이동 시 버퍼가 바뀌는 것이 아니라 활동 블록의 시작 시간이 바뀌도록 설정."

**게이트 답변 1차(2026-10-08, `.moai/reports/t43/gate-answers.md` §1)** 〔운영자〕:

| 게이트 | 답변 원문 |
|---|---|
| D-3 최소 활동 길이 | "애초에 활동 자체를 5분으로도 설정할 수 있게" |
| D-4 자정 | "넘기기를 허용하고, 수정할 때에만 다음날 시간대가 보이도록(00시에서 내리는 만큼 시간대가 연장됨). 나중에 생성된 일정을 볼때는 기존에 자정을 넘기는 일정을 조회할 때처럼 같은 블록으론 취급되지만 일자에 따라 나뉘어서 보이게" |
| D-6 구글 캘린더 | "삭제 후 재생성으로 반영" |
| D-8 SPEC-UIKIT-009 | "파일 안 고침 (Recommended)" |

**2차 답변(2026-10-08, `.moai/reports/t43/split-answers.md` §1)** 〔운영자〕:

| 질문 | 답변 원문 |
|---|---|
| 카드 분할(Q-8) | "두 장 — 핵심 먼저, 구글은 별도 (Recommended)" |
| 끄는 중 연장 표시(Q-4) | "가장자리 자동 스크롤 (Recommended)" |
| 반복 추정 구간(Q-6) | "이때 말한 같은 블록으로 취급이란 말은 활동일정에서 자정을 넘겨도 가는 이동과 오는이동까지 한 묶음으로 결정하여 이동과 편집이 연계되던 연결성을 유지하란 말이었음" |
| 그리기 최소 높이(Q-1) | "실제 길이대로 줄임. 왜냐면 가는 이동 오는 이동이 붙어서 활동일정을 클릭하기 어렵다 하여도 가는 이동을 눌러 편집창을 들어가면 활동 일정을 눌렀을 때 나타나는 창과 같기 때문" |

| 항 | 지시 | 출처 |
|---|---|---|
| 의미 | 오는 편 끌기 = 활동 끝, 가는 편 끌기 = 활동 시작, 연결 없는 구간은 지금대로 | 〔운영자〕 메모·④ / 〔제안〕 ⑤ |
| D-3 | 드래그로 줄일 때 최소 5분 | 〔가정〕 리드 해석 |
| D-4 | 넘기기 허용, 끄는 동안만 24:00 아래로 연장, 놓은 뒤 날짜별로 나뉘어 그려짐 | 〔운영자〕 + 〔가정〕 (1)~(3) |
| **D-4 정정** | **"같은 블록" = 활동 + 가는 편 + 오는 편이 자정을 넘어도 한 묶음 — 활동을 옮기면 이동이 따라가고, 이동을 끌면 활동이 움직이는 연결성 유지.** 0.5.0의 "하나의 레코드가 날짜별로 나뉘어 보임"만으로 읽은 해석을 정정한다. 날짜별로 나뉘어 그리는 것은 그대로 맞다 | 〔운영자〕 2차 Q-6 원문 + 〔가정〕 리드 정정 |
| D-6 | 구글 반영은 운영자가 정했지만 순서만 나눠 t48에서 한다 | 〔운영자〕 2차 Q-8 |
| Q-4 | 끄는 중 가장자리 자동 스크롤 | 〔운영자〕 2차 |
| Q-1 | 활동은 실제 길이대로 그린다(히트 범위도 함께 줄어든다) | 〔운영자〕 2차, 새 바닥 5분은 〔가정〕 |
| 경계 | 위로 넘기기는 첫날 0시에서 멈춤 · 아래 상한은 첫날 다음 날 끝 · 연장은 연결된 구간 드래그만 · 이동 구간 최소 높이 16분 유지 | 〔가정〕 — 말씀 없음 |

### 1.2 지금 동작 (기준 트리 `b59fcaa`, 코드 열람)

- **제스처**: `RescheduleOverlay`(`Shared/ContentView.swift:877-970`)가 0.35초 길게 누르기로 시작하고(`:899`), 시작점 대비 세로 이동량을 5분 단위로 반올림해 `ActiveDrag.deltaMinutes`에 담는다(`:463-466`). 놓을 때 `finalizeDrag`(`:767-786`).
- **오버레이의 좌표계** 〔조사〕: 오버레이는 `ScrollView` **안**의 `GeometryReader`에 붙어 있다(`ScrollView` `:417`, 오버레이 `:456-479`). 그래서 `location(in: gr.view)`(`:939`)는 스크롤되는 콘텐츠의 좌표다 — 콘텐츠가 움직이면 같은 손가락 위치의 y가 그만큼 바뀐다.
- **스크롤과 날짜 넘김**: 드래그 중 `.scrollDisabled(activeDrag != nil)`(`:494`), 날짜 넘김 잠금(`SwipePager` `isLocked` `:408`). 자동 스크롤은 없다(`ScrollViewReader`·`scrollTo`·`CADisplayLink`·`Timer` 0건). `UIScrollView`에 닿는 자리는 조상 스크롤 뷰를 찾는 `ScrollTouchFixView`(`:854-863`)뿐이다.
- **`adjustTravelLeg`**(`Shared/Store.swift:1387-1410`): 출발 기준은 `shiftEvent`(`:1404`), 도착 기준은 `adjustBuffer`(`:1406`). 활동을 건드리지 않고 구글도 부르지 않는다.
- **블록 범위의 단일 출처**: `span(for activity:on:)`(`:543-556`)·`span(for event:on:)`(`:558-592`). 그리는 날 끝은 리터럴 `1440`(`:549`·`:578`), 하루 높이는 `ForEach(0..<24)`(`:420`·`:429`)·`24 * hourHeight`(`:483`·`:485`). 활동 최소 그리기 높이 `minActivityMinutes = 20`(`:531`, 쓰는 곳 `:555`), 이동 `minTravelMinutes = 16`(`:532`). `span(for activity:)` 주석(`:550-554`)은 잘린 반쪽도 최소 높이로 늘리는 이유를 "늘리지 않으면 보이지도 탭되지도 않는 블록"으로 적는다.
- **폼의 분 간격(사실)** 〔조사〕: 활동 생성·편집 카드의 시각 줄은 SwiftUI `DatePicker`(`Shared/EditCardView.swift:227`, `.graphical` `:231`)이고, `Shared/` 어디에도 `minuteInterval`·`UIDatePicker` 설정이 없다(`grep -rn 'minuteInterval\|UIDatePicker' Shared/` → 0건). SwiftUI `DatePicker`는 분 간격 매개변수가 없으므로 시스템 기본값을 쓴다 — Apple 문서상 `UIDatePicker.minuteInterval`의 "default and minimum values are 1"이다(`https://developer.apple.com/tutorials/data/documentation/uikit/uidatepicker/minuteinterval.json`, 2026-10-08 조회). 즉 **폼은 1분 단위**로 시각을 고르고, 종료가 시작보다 뒤면 받는다(`Shared/AddActivityView.swift:150-158`). 5분 활동은 폼으로 이미 만들 수 있다. SwiftUI가 그 기본값을 그대로 쓰는지는 화면에서 보지 않았다〔가설 — 문서·코드 근거〕.
- **구간 탭의 편집 경로** 〔조사〕: 구간 상세의 편집은 `store.activity(forLeg:)`(명시 연결만, `Store.swift:415-418`)가 활동을 찾으면 활동 편집 화면, 아니면 이동 일정 폼으로 간다(`Shared/EventDetailView.swift:91-98`). 반복 회차의 **추정 구간은 명시 연결이 없어 이동 일정 폼이 열린다** — Q-1 답변의 근거("가는 이동을 눌러도 같은 창")는 명시 연결 구간에서만 성립한다(§1.3 (사), `plan.md` Q-10).

### 1.3 이 SPEC이 조사로 찾은 것

(가) **딱딱한 평행이동이면 불변식이 저절로 지켜진다** — 가는 편 도착 = 활동 시작, 오는 편 출발 = 활동 끝(`legAnchor` `Store.swift:378-380`). 기존 `shiftEvent`(`:1439-1447`)로 옮긴다.

(나) **연결은 두 가지다** — 명시(`linkedActivityId`)와 반복 회차의 추정(`estimatedLegs` `:1427-1434`). 활동 → 구간은 `linkedLegs`(`:1414-1422`), 구간 → 활동은 명시만 보는 `activity(forLeg:)`.

(다) **한 반복에 활동이 둘일 수 있다**(체류·점심시간, `Shared/AIAssistant.swift:2321`·`:2371`) → 동률 규칙(REQ-004)과 같은 역할 회차(REQ-010).

(라) **명시적 구간은 `recurrenceId`를 갖지 않는다**(`Store.swift:868`·`:955`).

(마) **옛 틈 데이터** — 틈을 유지하고 함께 옮긴다(REQ-001).

(바) **자정을 넘긴 반복 추정 구간은 묶음을 잃는다 — 운영자의 "한 묶음" 뜻과 어긋난다.** 추정 대조는 구간 도착이 활동 시작일과 같은 날인지 본다(`Store.swift:1430`). 오는 편을 끌어 도착이 다음 날이 되면 그 구간은 `linkedLegs`·`packingGroups`·`moveActivity`·"전체" 조회에서 빠진다. 운영자 2차 답변("자정을 넘겨도 가는 이동과 오는이동까지 한 묶음으로 … 이동과 편집이 연계되던 연결성을 유지")이 정확한 앵커 시각 대조 우선(REQ-016)의 근거이고, 같은 근거로 고정 핀 AF-015-09·11과 `@MX:WARN`(`Store.swift:436`)을 뒤집는다. 연결을 쓰는 모든 자리의 표는 `research.md` §9다 — 요약: 드래그·활동 이동·배치 묶음·새 소유 조회는 (A)로 묶음을 지킨다. 활동 편집 화면에서 **끝**을 바꾸면 복귀 구간을 옮기는 `realignReturnLeg`(`:352-359`)는 명시 연결만 보아(`:353`) 반복 추정 복귀 구간을 **자정과 무관하게 지금도** 옮기지 않는다 — 이 카드가 만든 갭이 아니므로 범위 밖으로 두고 열린 질문으로 올린다(`plan.md` Q-11).

(사) **활동을 실제 길이대로 그리면 짧은 활동의 탭 범위가 줄어든다.** `span`은 렌더와 히트 테스트가 함께 읽는다(계약 5). 5분 활동은 56pt/시간에서 약 4.7pt다. 구간이 붙은 활동은 구간을 눌러 들어갈 수 있다는 것이 운영자 근거지만, 그 우회는 명시 연결 구간에서만 활동 편집으로 간다(§1.2). 반복 회차(추정 구간)와 구간이 없는 활동은 대체 경로가 없다(`plan.md` Q-10). 그리기 바닥이 5분으로 내려가면 5~19분 활동이 바로 붙은 오는 편과 화면에서 겹치지 않으므로 같은 묶음 반폭 분할(`ScheduleLogic.overlapSlots` `Models.swift:395`)이 줄어든다.

(아) **AI 가드 주석 전제**(`Shared/AIAssistant.swift:2582-2586`)는 좁아지지만 남는다 — 바꾸지 않는다.

(자) **끄는 중 연장은 자동 스크롤 없이 보이지 않는다** — 0.5.0이 찾은 것. 운영자가 가장자리 자동 스크롤을 골랐다(REQ-015). 설계와 확인한 것·못 한 것은 `plan.md` D-11.

### 1.4 이웃

| 대상 | 관계 |
|---|---|
| SPEC-UIKIT-009 (completed) | 드래그 의미(D-6 (a)·REQ-018·AC-018 (2)(3)·스크립트 18)와 REQ-017 묶음 안 배치의 전제(20분 최소 높이)를 대체한다. 파일은 고치지 않는다(D-8). |
| 카드 **t48** | 구간 드래그가 바꾼 활동 길이의 구글 반영(삭제 후 재생성). 재료는 `.moai/reports/t43/google-card-handoff.md`. |
| `moveActivity` | 본문은 그대로. REQ-016이 그 함수가 읽는 추정을 바꾼다. |
| CHECKLIST K13 · t44 | sync 몫. |

### 1.5 0.5.0 → 0.6.0 요구 대응표

| 0.5.0 | 0.6.0 | 이유 |
|---|---|---|
| REQ-003 | 바뀜 — 구글 식별자 예외 구절 삭제 | 구글 분리 |
| REQ-006 | 바뀜 — 그리기 최소 높이를 5분 바닥으로 | 2차 Q-1 |
| REQ-009 | 바뀜 — 활동 범위는 실제 길이(5분 바닥) | 2차 Q-1 |
| REQ-012 | 되돌림 — 0.4.1 "동기 · 구글 미반영" 형태, 구글 본문은 인계 파일로 | 2차 Q-8 |
| REQ-013 | 바뀜 — 추가 24, T = B + 24 | AF-018-28 이동 |
| REQ-015 | 다시 씀 — 가장자리 자동 스크롤이 본 요구 | 2차 Q-4 |
| REQ-016 | 바뀜 — 〔제안〕 → 운영자 근거 | 2차 Q-6 |
| 그 밖 | 유지 | — |

## 2. 요구사항 (GEARS)

### [DELTA] A 연결된 구간 드래그의 의미

- [EXISTING] 제스처(0.35초, 5분 단위), 대화상자 문구, `finalizeDrag`의 두 호출과 `adjustTravelLeg` 서명 — 그대로.
- [MODIFY] `Store.adjustTravelLeg` — 소유 활동이 있는 구간은 활동 가장자리를 옮긴다.
- [NEW] 구간 → 소유 활동 조회 함수 하나.

- **REQ-001 (Event-driven)**: When the user drops a return leg (departure-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's end by Δ, keep its start, and shift the return leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's departure equals the activity's end after the drop if it did before, and an existing gap between them stays the same. 근거: 18번 메모와 방향 ④〔운영자〕. 옛 틈은 유지〔제안〕.

- **REQ-002 (Event-driven)**: When the user drops an outbound leg (arrival-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's start by Δ, keep its end, and shift the outbound leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's arrival equals the activity's start after the drop if it did before. 근거: 18번 메모와 방향 ④〔운영자〕.

- **REQ-003 (Ubiquitous · Unwanted)**: The leg drop of REQ-001 or REQ-002 shall change the schedule only of the owning activity and its dragged-side leg — and, for a series move under REQ-010, of the same-role occurrences and their dragged-side legs; it shall not change the other leg of any of those activities, any other activity or event, or any dragged leg's buffer or travel time, where re-assigning notification identifiers by the notification refresh is not a schedule change; and the change shall not add another copy of the departure-time computation or of the leg-shift arithmetic. 근거: §1.3 (가). 알림 갱신은 `notificationId`를 다시 매긴다(`Store.swift:1534`·`:1538`).

- **REQ-004 (Ubiquitous)**: The store shall resolve the owning activity of a leg in one function that both the timetable preview and the drop read, in this order: (a) when the leg has an explicit link to an existing activity, that activity, and when the link is dangling, none; (b) otherwise, when the leg has a recurrence id, the candidates are the activities of that recurrence whose forward leg lookup (the existing explicit-first, else estimated, lookup) contains the leg; one candidate is the owner; with two or more, only the candidates whose anchor time equals the leg's anchor-side time (outbound: leg arrival equals activity start; return: leg departure equals activity end, and a missing departure never equals) remain, and exactly one remaining candidate is the owner; (c) in every other case the leg has no owner. 근거: §1.3 (나)(다). 같은 날 활동으로 먼저 좁히지 않는다 — 자정을 넘긴 오는 편의 소유를 놓친다. 조회는 드래그 시작과 드롭 때 한 번씩이다(REQ-009).

- **REQ-005 (State-driven)**: While a dragged leg that still exists in the stored schedule has no owning activity — including a dangling link and an ambiguous recurrence match — the store shall apply today's behavior unchanged: a departure-anchored leg shifts as a whole and an arrival-anchored leg keeps its arrival and absorbs the drag into its buffer, clamped as today. 근거: 방향 ⑤〔제안〕. 지금 코드 `Store.swift:1400-1408`.

### [DELTA] B 한계

- [NEW] 유효 Δ를 정하는 Store 함수 하나, 드래그 최소 길이 상수(5분) 하나, 5분 단위 상수 하나.
- [MODIFY] 화면의 활동 최소 그리기 높이 `minActivityMinutes`(`ContentView.swift:531`) 20 → 5.

- **REQ-006 (Ubiquitous · Unwanted)**: The leg drop shall not leave the owning activity shorter than the minimum activity length of 5 minutes, defined once in the store; for an activity already shorter than that minimum, the limit shall reject any shortening and shall apply any lengthening unchanged; and the timetable shall draw an activity at its actual length, padding only an activity or a clipped day-part shorter than 5 minutes up to 5 minutes, while the travel-leg minimum drawing height stays 16 minutes. 근거: 게이트 D-3 "애초에 활동 자체를 5분으로도 설정할 수 있게"와 2차 Q-1 "실제 길이대로 줄임"〔운영자〕. 5분 바닥은 〔가정〕이다 — 바닥이 없으면 시작 = 끝인 깨진 레코드(`ContentView.swift:97-98`이 시작일에 나열한다)와 자정에서 1~4분만 남은 반쪽이 높이 0~4pt가 되어 `span` 주석(`:550-554`)이 막으려던 "보이지도 탭되지도 않는 블록"으로 돌아간다. 5분은 드래그로 만들 수 있는 가장 짧은 활동이라 5분 이상 활동은 모두 실제 길이다. 바닥 상수는 드래그 최소 길이와 같은 값이지만 그리기 전용으로 `ContentView`에 둔다〔가정〕. 이동 최소 높이는 말씀이 없어 그대로다(`:532`).

- **REQ-007 (Ubiquitous · Unwanted)**: The leg drop shall allow the dragged leg and its owning activity to cross midnight, limited only as follows, where F is the first day on which the leg is listed before the drag and L the last: for an upward drag (negative Δ), the set of days on which the leg is listed shall not change — the new departure shall be on or after the start of F and the new arrival strictly after the start of L; for a downward drag (positive Δ), the new arrival shall be no later than the end of the day after F. For a warning block (no travel time) and for a broken record with no listed span, only the listing time — the warning block's anchor time, or the broken record's arrival — shall enter these limits, with F = L = the day of that time and the downward limit strict (before the end of the day after F). 근거: 게이트 D-4 "넘기기를 허용"〔운영자〕. 위로 넘기기와 상한은 말씀이 없다〔가정 — `plan.md` D-4〕. 나열은 반열린 겹침(`Store.overlapsDay` `:38-41`, `isListed(on:)` `Models.swift:229-235`). 경고 블록 근거는 감사 4회차 N4-1.

- **REQ-008 (Ubiquitous)**: For a leg with an owning activity, the effective Δ shall be computed by one store function that takes the leg and its already-resolved owning activity and uses only their times — no lookup over the stored schedules — from a requested Δ and the limits of REQ-006 and REQ-007, with times in seconds first truncated toward zero to whole minutes, the limits applied only in the direction of the request so that the effective Δ always lies between 0 and the requested Δ inclusive, and the result rounded toward zero to a multiple of the snap step, a single 5-minute constant defined once in the store and read by the gesture's rounding as well; the timetable gesture shall store that effective Δ as the drag's value during the drag; the drop shall re-read the dragged leg by its id from the stored schedule, resolve the owner once from that current value, and apply the store function to the value it receives (the drag's stored effective Δ) using only the current stored times — never the times of the leg value captured when the drag began — and when the effective Δ is 0 the drop shall change nothing. When the dragged leg's id no longer exists in the stored schedule, the drop shall change nothing, with or without an owner. 근거: 계약 5, 드롭 재읽기(R3-3), N4-4. "0과 요청 사이"는 대칭 자르기가 옛 데이터에서 +15를 −60으로 바꾸는 일을 막는다(`progress.md` §E.1 0.5.0 표).

### [DELTA] C 미리보기 · 끄는 중 연장 · 가장자리 자동 스크롤

- [MODIFY] 두 `span` · `dragOffsetMinutes(forEvent:)` · `onBegin`·`onChange` · 눈금·높이 · `RescheduleOverlay`(`:877-970`) · 드래그 중 스크롤 잠금(`:494`).

- **REQ-009 (State-driven)**: While a leg with an owning activity is being dragged, the timetable shall draw both that activity (start for an outbound leg, end for a return leg) and the dragged leg moved by the effective Δ inside the two block-extent functions, building the moved time first and then clipping it by comparing it with the drawn day's start and the day limit of REQ-015 — a time before the start clips to the start and a time after the limit clips to the limit — read through one view helper that names the dragged leg, its owning activity, and the effective Δ, where the owning activity is resolved once when the drag begins and kept in the drag value so that no block-extent, offset, or gesture-change computation resolves it again, so that rendering, layout, height, and hit-testing read the same moved extents — with the activity drawn at its actual length under REQ-006 — and the dragged leg adds no separate translation; a moved block whose extent no longer meets the drawn day shall not be drawn as a full-height block or at a wrong position; a leg without an owning activity shall keep today's translation preview. 근거: §1.3 (사), 감사 2회차 N-1. 저장된 블록에서는 지금의 자르기와 같은 값이다.

- **REQ-015 (State-driven · Event-driven)**: While a leg with an owning activity is being dragged, (1) when the moved end of that leg or of its owning activity lies after the end of the day on which the drag began, the timetable page of that day shall extend below 24:00 by that excess rounded up to a whole hour, with the hour grid, its labels, the content height, both block-extent functions' clipping, and hit-testing all reading one view helper that yields the page's day limit in minutes, which shall be 1,440 at every other time and shall return to 1,440 when the drag ends, committed or cancelled, while the other pages do not change; and (2) while the finger rests inside the top or bottom edge band of the visible timetable, the timetable shall scroll toward that edge by itself, at a speed that grows with the finger's depth into the band, also when the finger does not move, stopping at the top of the content and at the end of the current content, and on every scroll step the drag value shall be recomputed from the finger's current position in the scrolled content through the same one function that turns finger movement into the requested Δ, so that the preview and the drop read one value; the automatic scrolling shall stop on every path that ends or abandons the drag — release, cancellation, failure, the overlay leaving the window or being dismantled — and shall never outlive the drag. 근거: 게이트 D-4 "수정할 때에만 다음날 시간대가 보이도록(00시에서 내리는 만큼 시간대가 연장됨)"과 2차 Q-4 "가장자리 자동 스크롤 (Recommended)"〔운영자〕. 오버레이가 스크롤 콘텐츠 안에 있어 손가락의 콘텐츠 좌표가 스크롤만큼 바뀌므로, 매 단계 손가락 위치를 다시 읽으면 보정이 따로 필요 없다(`ContentView.swift:456-479`·`:939`) — 오프셋을 따로 더하면 두 번 더해진다. 위 가장자리는 콘텐츠 맨 위(첫날 0시)에서 멈추고, 위로 넘기기는 REQ-007의 자르기 그대로다〔가정〕. 연장 눈금 표기는 `ui-design` 몫. 놓으면 연장이 사라져 스크롤 위치가 새 콘텐츠 끝을 넘을 수 있다 — 화면은 하루 끝으로 돌아온다(S-17). 활동 블록 드래그와 소유 없는 구간 드래그는 연장·자동 스크롤을 하지 않는다〔가정 — `plan.md` Q-9〕. 메커니즘·확인 상태는 `plan.md` D-11.

### [DELTA] D 반복 일정 · 묶음

- [EXISTING] 대화상자는 끌린 구간의 `recurrenceId`로 켜진다 — 그대로.

- **REQ-010 (Event-driven)**: When the user chooses to move the whole recurring series for a dragged leg with an owning activity, the store shall apply REQ-001 or REQ-002 to every activity with the owning activity's recurrence id, title, and location name, each through that occurrence's own same-role leg found by the forward leg lookup and each with the dragged Δ limited by that occurrence's own limits, and shall skip an occurrence that has no such leg without editing that occurrence; it shall leave every other activity of the recurrence and its legs unchanged; it shall persist the activities once and the events once for the whole operation regardless of the number of occurrences, re-sort the activities by start once when any start changed, and re-schedule the nearest notifications once. 근거: §1.3 (다)〔제안〕. 저장 규율 `Store.swift:1409`, 알림 `:1519-1543`.

- **REQ-011 (Event-driven)**: When the user chooses to move only this occurrence, or the dragged leg has no recurrence id, the store shall apply REQ-001 or REQ-002 to the dragged leg's owning activity only; the recurrence dialog shall continue to be keyed on the dragged leg's recurrence id. 근거: §1.3 (라).

- **REQ-016 (Ubiquitous)**: The store's estimated leg lookup for a recurring activity shall first look for the legs whose anchor time equals the activity's anchor-side time — an outbound leg whose arrival equals the activity's start and a return leg whose departure equals the activity's end, each with the activity's recurrence id and the place-name match used today — and shall fall back to today's same-day rule only for a role with no such leg, in the one function that the forward leg lookup and the packing groups already share, so that an activity and its outbound and return legs stay one linked group across midnight for moving the activity, dragging a leg, and grouping on screen. 근거: 2차 Q-6 "자정을 넘겨도 가는 이동과 오는이동까지 한 묶음으로 결정하여 이동과 편집이 연계되던 연결성을 유지"〔운영자〕. 이 문장이 고정 핀 AF-015-09·11과 `@MX:WARN`(`Store.swift:436`)을 뒤집는 근거다. 연결을 쓰는 모든 자리는 `research.md` §9. 같은 날 대조로만 이어지던 옛 틈 구간은 넘기면 여전히 잃는다(잔여).

### [DELTA] E 동기성

- **REQ-012 (Ubiquitous · Unwanted)**: The leg drop shall complete synchronously — no `Task`, no `await`, no ignored `try?` — and shall not push the changed activity or leg times to Google Calendar, matching the activity drag today. 근거: 이 진입점은 동기 함수이고 `finalizeDrag`가 결과를 기다리지 않는다. 구글 반영은 운영자가 정했지만("삭제 후 재생성으로 반영") 2차 답변("구글은 별도")에 따라 카드 t48이 한다 — 그때까지 물려받은 갭 F12(SPEC-UIKIT-009 `spec.md:90`·`:197`)가 남는다. 0.5.0의 구글 요구 원문은 `.moai/reports/t43/google-card-handoff.md` §2.

### [DELTA] F 드라이버 · 범위

- **REQ-013 (Ubiquitous)**: The guard driver shall assert the observable behavior of REQ-001 through REQ-012 and REQ-016 by `plan.md` §5 — AF-018-02, AF-018-03, AF-015-09, and AF-015-11 rewritten in place and AF-018-04 through AF-018-27 added, each number one unconditional `drvCheck` call, with no fixture that waits on a travel-time estimate — and its run shall end with no ✗ and exit 0, with the new total recorded against a base total measured on the unchanged tree in the same run phase. 근거: 드라이버 하한 규칙(`Tools/GuardDriver.swift:306`). T = B + 24. 화면(연장·자동 스크롤·탭 범위)은 UIKit이라 드라이버가 닿지 않는다 — 시뮬레이터 S절.

- **REQ-014 (Ubiquitous · Unwanted)**: The change shall touch only `Shared/Store.swift`, `Shared/ContentView.swift`, and `Tools/GuardDriver.swift` among source files; shall add no source file, no AI class, no color outside `Theme`, and no secret; shall leave `proxy/`, `Shared/AIAssistant.swift`, `Shared/GoogleCalendarService.swift`, `Shared/Models.swift`, and the activity drag (`moveActivity`) body unchanged; shall keep `adjustBuffer` reachable from the no-owner path; shall keep the iOS build free of source warnings; and shall neither build nor verify the macOS app. 근거: `CLAUDE.md` 계약 1·2·4·6, Day 파일 한도, iOS 전용 방침.

## 3. 바뀌지 않는 것

- `moveActivity` 본문 — 활동과 두 구간이 함께 평행이동(읽는 추정만 REQ-016으로 바뀐다). 활동 드래그는 연장·자동 스크롤을 하지 않는다.
- 길게 누르기 0.35초, 5분 단위, 탭·스와이프, 드래그 중 날짜 넘김 잠금.
- 대화상자 문구, 소유 없는 구간의 드래그와 그 미리보기.
- 이동 구간 최소 그리기 높이 16분.
- 겹침 검사 없음, 실행 취소 없음.
- `realignLegs`·`realignReturnLeg`·활동 상세 화면의 구간 편집, `packingGroups` 본문.
- AI 도구·프록시·`Theme`·`GoogleCalendarService`.

## 4. 범위 밖

### Out of Scope — 외부 동기화

- 연결된 구간 드래그가 바꾼 활동 길이는 이 카드에서 구글에 반영하지 않는다(물려받은 갭 F12, 카드 t48이 닫는다 — `.moai/reports/t43/google-card-handoff.md`).

### Out of Scope — 끌기 대상 확장

- 활동 가장자리를 직접 잡아 늘리는 손잡이는 만들지 않는다.
- 위로 0시를 넘겨 앞날로 늘이는 연장은 만들지 않는다〔가정〕.
- 활동 블록 드래그·연결 없는 구간 드래그의 연장·자동 스크롤은 만들지 않는다〔가정〕.

### Out of Scope — 데이터 · 편집 경로

- 옛 틈을 드래그가 닫지 않는다. 같은 날 대조로만 이어지던 옛 틈 추정 구간의 자정 넘김 연결 상실은 고치지 않는다.
- 활동 편집 화면에서 끝을 바꿀 때 반복 추정 복귀 구간이 따라오지 않는 기존 갭(`realignReturnLeg` `Store.swift:352-359`)은 고치지 않는다(`plan.md` Q-11).
- 반복 추정 구간을 눌렀을 때 활동 편집 대신 이동 일정 폼이 열리는 경로(`EventDetailView.swift:94`)는 바꾸지 않는다(`plan.md` Q-10).

### Out of Scope — 맥 앱과 문서

- 맥 앱 빌드·검증 없음. SPEC-UIKIT-009 파일 무수정(D-8).

## 5. 결정

| 결정 | 지금 상태 | 닿는 곳 |
|---|---|---|
| D-1 의미 | 〔운영자〕 | REQ-001·002·003 |
| D-2 소유 조회 | 〔제안〕 | REQ-004·005·011 |
| D-3 최소 5분 · 실제 길이 그리기 | 〔운영자〕 + 5분 바닥〔가정〕 | REQ-006 |
| D-4 넘기기 · 한 묶음 | 〔운영자〕 1차·2차 + 경계〔가정〕 | REQ-007·015·016 |
| D-5 미리보기 = 확정 | 〔제안〕 | REQ-008·009 |
| D-6 구글 | 〔운영자〕 반영 결정, 2차로 t48 분리 | REQ-012(미반영) · §4 |
| D-7 반복 "전체" | 〔제안〕 | REQ-010 |
| D-8 SPEC-UIKIT-009 | 〔운영자〕 | §1.4 |
| D-9 옛 틈 | 〔제안〕 | REQ-001 |
| D-10 정확한 대조 우선 | 〔운영자〕 2차 Q-6 | REQ-016 |
| D-11 가장자리 자동 스크롤 | 〔운영자〕 2차 Q-4 + 매개값〔제안〕 | REQ-015 |

## 6. 관련 문서

- `.moai/reports/2026-10-05-sim-4bundle-result.md:23`·`:65` — 카드와 18번 메모
- `.moai/reports/t43/gate-answers.md`·`split-answers.md`(주 체크아웃, 미추적) — 답변 원문
- `.moai/reports/t43/google-card-handoff.md` — t48 인계
- `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`~`-review-4.md` — 0.5.0·0.6.0은 감사받지 않았다
- [SPEC-UIKIT-009](../SPEC-UIKIT-009/spec.md) · [SPEC-UIKIT-011](../SPEC-UIKIT-011/spec.md)
- `research.md`

🗿 MoAI
