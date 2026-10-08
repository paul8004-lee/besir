---
id: SPEC-UIKIT-012
title: "연결된 이동 구간 드래그 재설계 — 오는 편은 활동 끝을, 가는 편은 활동 시작을 옮긴다 · 최소 5분 · 자정 넘기기와 끄는 중 시간표 연장 · 구글 삭제 후 재생성"
version: "0.5.0"
status: draft
created: "2026-10-08"
updated: "2026-10-08"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "drag, travel-leg, activity-resize, timetable, midnight, google-calendar, single-source, recurrence, guard-driver"
tier: M
related_specs: [SPEC-UIKIT-009, SPEC-UIKIT-011]
kanban_card: t43
---

# SPEC-UIKIT-012 — 연결된 이동 구간 드래그 재설계

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-10-08 | 최초 작성. 칸반 카드 **t43**(시뮬레이터 4묶음 18번 메모 — 운영자 지시)을 GEARS로 정식화했다. 기준 트리는 `b59fcaa`(브랜치 `WT-leg-drag-resize`). 방향 ④(가는 편 = 시작만, 오는 편 = 끝만)는 2026-10-08 칸반 리드의 질문에서 운영자가 확정했다 — **이 세션은 운영자의 답을 직접 보지 않았고 리드가 전한 것을 적었다**(SPEC-UIKIT-009 `plan.md` D-6과 같은 표기). |
| 0.2.0 | 2026-10-08 | **plan 감사 1회차(FAIL 0.60, `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`, 결함 D-1~D-22) 반영.** 반복 "전체"의 대상을 같은 역할 회차로 좁히고(REQ-010), 역방향 조회를 명시 연결 → 정방향 `linkedLegs(for:)` → 앵커 동률 → 소유 없음으로 정의했다(REQ-004). 옛 틈은 유지(REQ-001), 연결된 구간의 미리보기를 `span(for event:on:)` 안으로(REQ-009), 반복 일괄은 `moveActivity` 모양(REQ-010). REQ 14 · AC 12, 추가 단언 19. |
| 0.3.0 | 2026-10-08 | **plan 감사 2회차(FAIL 0.80, N-1~N-15) 반영.** 자정 한계 한 규칙, 소유는 드래그 시작 때 한 번 구해 드래그 값에 담음, 출발 없는 경고 블록 오는 편은 동률 불성립, 같은 역할 구간이 없는 회차는 건너뜀. 추가 단언 20. |
| 0.4.0 | 2026-10-08 | **plan 감사 3회차(FAIL 0.71, R3-1~R3-10 · G-1) 반영.** 자정 한계를 나열 판정의 반열린 규약에 맞췄고, 드롭은 id로 다시 읽으며, 5분 단위를 Store 상수 하나로, 구조 대조에 양성 대조를 붙였다. 출발 없는 경고 블록 ~~은 가는 편·오는 편 모두 동률 비교에서 제외한다~~ 〔0.5.0 정정 — 감사 4회차 N4-5: 동률은 가는 편이면 도착, 오는 편이면 출발로 잰다. 출발이 없는 오는 편은 동률이 성립하지 않는다(REQ-004와 같다)〕. 추가 단언 21. |
| 0.4.1 | 2026-10-08 | **재감사 4회차 차단 결함 N4-1만 수리.** 경고 블록·깨진 레코드는 나열을 정하는 시각 하나만 한계에 넣고, 유효 Δ는 요청과 반대 부호가 되지 않게 했다. 추가 단언 22. 경미 N4-2~N4-7은 남겼다. |
| 0.5.0 | 2026-10-08 | **운영자 게이트 답변 반영 — 0.5.0 미감사(독립 감사 없음).** 운영자가 게이트 4건에 답했고 그 가운데 셋이 권장 기본값을 뒤집었다(원문 §1.1, 리드 전달 `.moai/reports/t43/gate-answers.md`). ① 최소 활동 길이 20분 → **5분**(REQ-006). ② 자정 **넘기기 허용** + 끄는 동안 시간표가 24:00 아래로 연장(REQ-007 재작성, REQ-015 신설). 아래로 넘는 것만 말씀이 있어 위로는 끌기 전 나열되는 날을 바꾸지 않는 한쪽 자르기를 남겼다〔가정〕. ③ 구글 캘린더에 **삭제 후 재생성**으로 반영(REQ-012 재작성). ④ SPEC-UIKIT-009 파일 무수정(답변 = 권장). 자정을 넘긴 반복 추정 구간이 활동과의 연결을 잃는 문제를 정확한 앵커 시각 대조 우선으로 막는 REQ-016을 〔제안〕으로 더했다. 0.4.1의 반대 부호 금지 조항은 "유효 Δ는 0과 요청 사이"라는 방향별 자르기로 바꿨다(더 강한 성질, `progress.md` §E.1 0.5.0 표의 격자 52만여 건). 경미 N4-2·N4-3·N4-4·N4-5·N4-7은 고쳤고 N4-6은 게이트가 닫혀 사라졌다. REQ 14 → **16**, AC 12 → **15**, 드라이버 추가 단언 22 → **25**(AF-018-04~28), 제자리 고쳐 쓰기 2 → **4**(AF-018-02·03, AF-015-09·11). 바뀐 목록은 `plan.md` §11, 개수는 `progress.md` §G. |

## 0. 이 SPEC의 성격과 예산

**운영자가 방향을 정한 동작 변경의 계약이다.** 무엇을 바꿀지는 18번 메모·방향 ④·게이트 답변 넷이 정했다. 이 SPEC은 그 결정이 코드에서 닿는 자리, 운영자가 말하지 않은 경계(위로 넘기기·연장 상한·화면 도달성)의 〔가정〕, 모호한 데이터의 처리를 적는다. 지시는 다시 묻지 않는다.

**Tier: M** — 요구 16 · 수락 기준 15로 Tier M 상한(각각 16, 서로 독립 — `.claude/rules/moai/workflow/spec-workflow.md` § SPEC Complexity Tier)의 **끝**에 있다. 열린 질문의 답이 요구를 하나라도 더하면(예: 끄는 중 자동 스크롤을 별도 요구로 세움) Tier L로 올리거나 카드를 쪼갠다(`plan.md` §12).

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 바꾸는 소스 파일 | **3** — `Shared/Store.swift`(1828줄) · `Shared/ContentView.swift`(972줄) · `Tools/GuardDriver.swift`(5366줄). 새 파일 없음. `Shared/GoogleCalendarService.swift`(442줄)는 건드리지 않는다 — 기존 Store 함수 `removeFromCalendar`·`enqueueCalendarUpload`를 다시 쓴다 | `wc -l` |
| 드라이버 단언 | 제자리 고쳐 쓰기 4(AF-018-02·03, AF-015-09·11) · 추가 25(AF-018-04~28) | `plan.md` §5 |
| REQ · AC | **16 · 15** | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` |

크게 고치는 파일은 3개라 한 Day 한도(3~4) 안이다. 새 `Shared/` 파일이 없으므로 `xcodegen generate`와 서명 팀 재선택이 없다.

## 1. 배경

### 1.1 운영자 지시

**18번 메모** — `.moai/reports/2026-10-05-sim-4bundle-result.md:65`(같은 파일 `:23`이 카드 t43을 만들었다):

> "명세대로. 다만 오는 이동 블록을 길게 눌러 이동하면 활동의 시간 또한 변경되는 것이 좋아보임. (오는 이동을 아래로 30분 끌면 활동 블록도 30분 추가.) 이와 통일성을 맞추기 위해 가는 이동 또한 꾹 눌러 이동 시 버퍼가 바뀌는 것이 아니라 활동 블록의 시작 시간이 바뀌도록 설정."

**게이트 답변(2026-10-08, 리드의 AskUserQuestion — 원문 그대로, 출처 `.moai/reports/t43/gate-answers.md` §1)**:

| 게이트 | 답변 원문 | 0.4.1 권장값과의 관계 |
|---|---|---|
| D-3 최소 활동 길이 | "애초에 활동 자체를 5분으로도 설정할 수 있게" | 권장(20분) 기각 → 5분 |
| D-4 자정 | "넘기기를 허용하고, 수정할 때에만 다음날 시간대가 보이도록(00시에서 내리는 만큼 시간대가 연장됨). 나중에 생성된 일정을 볼때는 기존에 자정을 넘기는 일정을 조회할 때처럼 같은 블록으론 취급되지만 일자에 따라 나뉘어서 보이게" | 권장(막기) 기각 → 넘기기 허용 + 끄는 중 연장 |
| D-6 구글 캘린더 | "삭제 후 재생성으로 반영" | 권장(반영 안 함) 기각 → 삭제 후 재생성 |
| D-8 SPEC-UIKIT-009 | "파일 안 고침 (Recommended)" | 권장 채택 |

| 항 | 지시 | 출처 |
|---|---|---|
| 메모 | 오는 이동을 아래로 30분 끌면 활동이 30분 늘어난다. 가는 이동을 끌면 버퍼가 아니라 활동 시작이 바뀐다 | 〔운영자〕 18번 메모 |
| ④ | 가는 편 드래그 = 시작만, 오는 편 드래그 = 끝만. "활동 전체를 옮긴다"는 버렸다 | 〔운영자 — 리드 경유〕 이 세션은 답을 직접 보지 않았다 |
| ⑤ | 연결된 활동이 없는 이동 구간은 지금 동작 그대로 | 〔제안〕 리드 제안, 이의 없음 |
| D-3 해석 | 드래그로 줄일 때의 최소 = 5분(드래그 한 칸). 화면 최소 그리기 높이(20분)는 줄이지 않는다 | 〔가정〕 리드 해석 — 그리기 높이는 말씀 없음, 열린 질문 |
| D-4 해석 | (1) 끄는 동안 시간표가 00:00 아래로 늘어나 다음 날 시간대가 보이고, 끄는 양만큼 늘어난다 (2) 놓은 뒤에는 자정을 넘는 **하나의 레코드**로 저장되고 보기에서는 날짜별로 나뉘어 그려진다(`span(for:on:)`의 기존 자르기) (3) 연장은 끄는 동안에만 있다 | 〔가정〕 리드 해석 (1)~(3) |
| D-4 경계 | 위로 00:00을 넘는 끌기(가는 편을 첫날 0시 앞으로)와 연장의 상한은 말씀이 없다 → 위로는 나열되는 날을 바꾸지 않게 자르고, 아래로는 첫날 다음 날 끝까지 | 〔가정〕 이 레인 — 열린 질문 |
| D-6 해석 | 활동 길이가 드래그로 바뀌면 그 활동과 끌린 쪽 구간의 구글 일정을 지우고 다시 만든다. 단건과 반복 "전체" 모두 | 〔가정〕 리드 해석 — 반복 "전체"는 말씀이 없다 |

### 1.2 지금 동작 (기준 트리 `b59fcaa`, 코드 열람)

- **제스처**: `RescheduleOverlay`가 0.35초 길게 누르기로 시작하고(`Shared/ContentView.swift:899`), 세로 이동량을 5분 단위로 반올림해 `ActiveDrag.deltaMinutes`에 담는다(`:463-466`). 한계는 어디에도 없다. 놓을 때 `deltaMinutes != 0`이면 `finalizeDrag`(`:767-786`)를 부른다(`:470`).
- **확정**: 이동 구간이면 반복 일정(`recurrenceId != nil`, `:778`)일 때 대화상자(`:176-182`)를 거쳐, 아니면 바로 `store.adjustTravelLeg(e, byMinutes:wholeSeries:)`(`:780`·`:783`)를 부른다.
- **`adjustTravelLeg`**(`Shared/Store.swift:1387-1410`): 출발 기준 구간은 `shiftEvent`로 통째 평행이동(`:1404`), 도착 기준 구간은 `adjustBuffer`로 여유를 바꾼다(`:1406`). 활동은 건드리지 않는다. 저장은 루프 뒤 한 번(`:1409`). 구글 호출이 없다.
- **미리보기**: `offsetY(for:)`(`ContentView.swift:514-521`)가 끌리는 블록에만 `dragOffsetMinutes`(`:595-603`)를 더한다.
- **블록 범위의 단일 출처**: `span(for activity:on:)`(`:543-556`)과 `span(for event:on:)`(`:558-592`)이 렌더·높이·배치(`positionedBlocks` `:711-734`)·히트 테스트(`block(atX:y:)` `:753`)가 함께 읽는 유일한 계산이다(`CLAUDE.md` 계약 5). 그리는 날의 끝은 두 함수에 리터럴 `1440`으로 박혀 있다(`:549`·`:578`).
- **하루 높이**: 시각 눈금과 구분선이 `ForEach(0..<24)` 둘(`:420`·`:429`), 높이가 `24 * hourHeight` 둘(`:483`·`:485`)이다. `hourHeight = 56`(`:37`).
- **스크롤**: 드래그 중 `.scrollDisabled(activeDrag != nil)`(`:494`), 날짜 넘김도 잠근다(`SwipePager` `isLocked` `:408`). 자동 스크롤은 없다 — `ScrollViewReader`·`scrollTo`가 이 파일에 0건이다. 오버레이는 손가락의 시작점 대비 세로 이동량(pt)을 분으로 바꾼다(`:463-466`, 오버레이 `:877-970`). `UIScrollView`에 닿는 자리는 `ScrollTouchFixView`(`:854-863`, 조상 스크롤 뷰를 찾아 `delaysContentTouches`를 끈다)뿐이다.
- **구글 선례**: `removeFromCalendar`(`Store.swift:97-103`)는 묘비를 먼저 저장하고 원격 삭제를 시도한다 — 실패해도 묘비가 남아 다음 동기화가 다시 지운다. `updateRecurringSeries`(`:1024`~)는 gid를 한 번에 모으고(`:1078`), 로컬 gid를 원격 삭제 **전에** 비우고(`:1080`, 이유 주석 `:1074-1077`), 삭제를 한 번에 건넨 뒤(`:1082`) 재등록을 큐에 넣는다(`:1084`). `updateActivity`(`:282-299`)는 저장 뒤 `Task` 하나에서 지우고 다시 올린다. `enqueueCalendarUpload`(`:1113`~)는 대상에 `.pending`을 먼저 저장하고 직렬 업로드 작업에 잇는다(`:1141-1147`). 업로드 실패는 `.failed`로 남아(`:1196-1201`) 설정 화면이 "캘린더에 못 올린 항목 N건"과 "다시 시도"를 보인다(`Shared/SettingsView.swift:61-64`).

### 1.3 이 SPEC이 조사로 찾은 것

(가) **딱딱한 평행이동이면 불변식이 저절로 지켜진다.** 가는 편은 `arrivalDate == activity.startDate`, 오는 편은 `departureDate == activity.endDate`이고 여유 0이다(`legAnchor` `Store.swift:378-380`). 활동 가장자리를 Δ 옮기고 같은 쪽 구간을 기존 `shiftEvent`(`:1439-1447`)로 Δ 옮기면 이동시간·여유·출발 산식이 그대로다.

(나) **연결은 두 가지이고 정방향 조회가 이미 둘을 순서대로 본다.** 명시적 연결(`linkedActivityId`)과 반복 회차의 추정 연결(`estimatedLegs(for:)` `Store.swift:1427-1434`)이다. 활동 → 구간은 `linkedLegs(for:)`(`:1414-1422`), 구간 → 활동은 명시적 연결만 보는 `activity(forLeg:)`(`:415-418`)뿐이다.

(다) **한 반복에 활동이 둘일 수 있다.** AI 반복 생성은 체류·점심시간 활동을 한 `recurrenceId`로 만들고(`Shared/AIAssistant.swift:2321`), 점심 장소가 없으면 두 활동이 같은 출근·복귀 구간을 추정으로 주장한다(`:2371`). 그래서 역방향 조회에는 동률 규칙이 필요하고(REQ-004), "전체"의 대상은 같은 역할 회차여야 한다(REQ-010).

(라) **명시적 구간은 `recurrenceId`를 갖지 않는다**(`addEvent` `Store.swift:868`, 넣는 곳은 반복 생성 `:955`뿐).

(마) **옛 의미로 틈이 생긴 데이터가 있다.** 새 의미는 틈을 고치지 않고 함께 옮긴다(REQ-001).

(바) **자정을 넘긴 반복 추정 구간은 연결을 잃는다 — 넘기기를 허용하면 이것이 드래그로 닿는다.** 추정 대조는 구간 도착이 활동 시작일과 같은 날인지 본다(`cal.isDate($0.arrivalDate, inSameDayAs: activity.startDate)` `Store.swift:1430`). 오는 편을 아래로 끌어 도착이 다음 날로 넘어가면 그 구간은 `linkedLegs`·`packingGroups`·"전체" 조회에서 빠진다 — 다음 활동 드래그가 그 구간을 두고 가고, 배치 묶음이 풀리고, 다음 구간 드래그는 소유 없는 지금 동작이 된다. `@MX:WARN`(`:436`)과 드라이버 AF-015-11(`Tools/GuardDriver.swift:4321`)이 이 약점을 이미 못박고 있다. 0.4.1은 자정 한계로 이 경로를 막았지만 운영자가 넘기기를 허용했으므로 REQ-016이 맡는다〔제안〕. **명시 연결 구간은 해당 없다** — `linkedActivityId`로 날짜와 무관하게 이어진다.

(사) **같은 묶음 구성원이 겹치면 반폭으로 갈린다**(`ScheduleLogic.overlapSlots` `Models.swift:395`). 그래서 연결된 구간의 미리보기도 `span(for event:on:)` 안에서 옮긴다(REQ-009). 최소 활동 길이가 5분이 되면서 새로 닿는 경우가 있다: 그리기 최소 높이 20분(`ContentView.swift:531`)을 유지하면 5~19분 활동은 20분 높이로 그려져 바로 뒤에 붙은 오는 편과 화면에서 겹치고, 같은 묶음이라 둘이 반폭으로 갈린다 — 폼으로 짧은 활동을 만들 때 지금도 생기는 모양이다(열린 질문, `plan.md` §2 Q-1).

(아) **AI 가드의 주석 전제는 좁아지지만 남는다**(`Shared/AIAssistant.swift:2582-2586`). 이 SPEC은 `AIAssistant.swift`를 바꾸지 않는다(REQ-014).

(자) **끄는 중 연장은 지금 화면 구조에서 손가락이 닿아도 눈에 거의 보이지 않는다**〔조사 — 코드 열람, 화면 미관측〕. 드래그 중에는 스크롤이 잠기고 자동 스크롤이 없으며, 손가락 이동량이 곧 분이다(위 1.2). 24:00 줄은 스크롤이 맨 아래일 때 화면 아래 끝에서 하단 여백(`.padding([.horizontal, .bottom])` `:486`)만큼 위에 있다. 시간표가 아래로 늘어나도 스크롤 위치는 그대로라 늘어난 시간대는 화면 아래 밖에 생긴다. 손가락은 화면 아래 끝까지 내려갈 수 있고(제스처는 뷰 밖에서도 위치를 계속 보고한다), 그만큼은 넘길 수 있지만, 넘어간 부분은 보이지 않는다. 운영자 지시 "다음날 시간대가 보이도록"을 실제로 채우려면 끄는 중 자동 스크롤이 필요하다 — 이 SPEC 본문은 리드 지시대로 자동 스크롤 없음〔가정〕을 기본으로 두되 요구 문장을 매개변수로 써서 나중에 더할 수 있게 했다(REQ-015 Where 절). 선택지 비교는 `plan.md` D-11.

### 1.4 이웃

| 대상 | 관계 |
|---|---|
| SPEC-UIKIT-009 (completed) | 결정 D-6 (a)·REQ-018의 드래그 의미 절·AC-018 (2)(3)·스크립트 18을 이 SPEC이 대체한다. 운영자 답변(D-8)대로 그 파일은 고치지 않는다. |
| `moveActivity` | 활동 블록 드래그. 바꾸지 않는다. 다만 REQ-016이 `estimatedLegs`를 바꾸면 반복 활동 드래그가 함께 옮기는 추정 구간도 정확한 앵커 대조를 먼저 본다 — 결과가 달라지는 것은 자정을 넘긴 추정 구간뿐이다. |
| CHECKLIST K13 | 이 카드의 ❌ 행. run 뒤 sync가 갱신한다(`plan.md` §6). |
| t44 | 문서 인용 재사상 — 이 카드가 줄을 옮기므로 sync 몫. |

### 1.5 0.4.1 → 0.5.0 요구 대응표

AC·드라이버 단언·시뮬레이터 단계·결정의 대응은 `plan.md` §11에 있다.

| 0.4.1 | 0.5.0 | 이유 |
|---|---|---|
| REQ-001·002·003 | 유지(003에 구글 식별자 예외 한 구절) | 의미 D-1은 그대로. 구글 재등록이 gid를 바꾸는 것은 일정 변경이 아니다 |
| REQ-004 | 바뀜 — 같은 날 활동으로 먼저 좁히는 단계 삭제 | 자정을 넘긴 오는 편은 도착일이 활동 시작일과 다르다. 조회는 드래그 시작·드롭 때만 하므로 좁히지 않아도 비용이 작다 |
| REQ-005 | 바뀜 — id가 사라진 구간은 REQ-008의 독립 조항으로 | 감사 4회차 N4-4 (b) |
| REQ-006 | 다시 씀 — 20분 → 5분, 그리기 높이와 분리 | 게이트 D-3 |
| REQ-007 | 다시 씀 — 막기 → 넘기기 허용(위로는 한쪽 자르기, 아래로는 첫날 다음 날 끝까지) | 게이트 D-4 |
| REQ-008 | 다시 씀 — 드롭은 받은 값을 자른다, 유효 Δ는 0과 요청 사이 | N4-4 (a), 반대 부호 조항은 방향별 자르기로 흡수 |
| REQ-009 | 바뀜 — 자르기를 그리는 날의 시작·한계와 비교로 | 넘기기 허용으로 옮긴 시각이 그리는 날 밖으로 갈 수 있다 |
| REQ-010·011 | 유지 | — |
| REQ-012 | 다시 씀 — 구글 미반영 → 삭제 후 재생성 | 게이트 D-6 |
| REQ-013 | 바뀜 — 추가 25, 고쳐 쓰기 4, T = B + 25 | 단언 재설계 |
| REQ-014 | 바뀜 — `GoogleCalendarService.swift`·`Models.swift` 무변경 명시 | 범위 |
| — | **신설 REQ-015** 끄는 중 시간표 연장 | 게이트 D-4 (1)(3) |
| — | **신설 REQ-016** 정확한 앵커 대조 우선 추정 〔제안〕 | §1.3 (바) |

## 2. 요구사항 (GEARS)

### [DELTA] A 연결된 구간 드래그의 의미

- [EXISTING] 제스처(0.35초, 5분 단위), 대화상자 문구, `finalizeDrag`의 두 호출(`ContentView.swift:780`·`:783`)과 `adjustTravelLeg` 서명 — 그대로 둔다.
- [MODIFY] `Store.adjustTravelLeg`(`Store.swift:1387-1410`) — 소유 활동이 있는 구간은 활동 가장자리를 옮긴다.
- [NEW] 구간 → 소유 활동 조회 함수 하나(화면과 저장이 함께 읽는다).

- **REQ-001 (Event-driven)**: When the user drops a return leg (departure-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's end by Δ, keep its start, and shift the return leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's departure equals the activity's end after the drop if it did before, and an existing gap between them stays the same. 근거: 18번 메모와 방향 ④〔운영자〕. 옛 틈은 그대로 두고 함께 옮긴다〔제안〕.

- **REQ-002 (Event-driven)**: When the user drops an outbound leg (arrival-anchored) that has an owning activity after dragging it by an effective Δ minutes, the store shall move that activity's start by Δ, keep its end, and shift the outbound leg as a whole by the same Δ with its travel time and buffer unchanged, so that the leg's arrival equals the activity's start after the drop if it did before. 근거: 18번 메모와 방향 ④〔운영자〕. 출발 알림은 `shiftEvent`의 재예약(`Store.swift:1446`)으로 함께 움직인다.

- **REQ-003 (Ubiquitous · Unwanted)**: The leg drop of REQ-001 or REQ-002 shall change the schedule only of the owning activity and its dragged-side leg — and, for a series move under REQ-010, of the same-role occurrences and their dragged-side legs; it shall not change the other leg of any of those activities, any other activity or event, or any dragged leg's buffer or travel time, where re-assigning notification identifiers by the notification refresh and clearing or re-assigning Google event identifiers under REQ-012 are not schedule changes; and the change shall not add another copy of the departure-time computation or of the leg-shift arithmetic. 근거: §1.3 (가). 알림 갱신은 모든 이벤트의 `notificationId`를 다시 매긴다(`Store.swift:1534`·`:1538`).

- **REQ-004 (Ubiquitous)**: The store shall resolve the owning activity of a leg in one function that both the timetable preview and the drop read, in this order: (a) when the leg has an explicit link to an existing activity, that activity, and when the link is dangling, none; (b) otherwise, when the leg has a recurrence id, the candidates are the activities of that recurrence whose forward leg lookup (the existing explicit-first, else estimated, lookup) contains the leg; one candidate is the owner; with two or more, only the candidates whose anchor time equals the leg's anchor-side time (outbound: leg arrival equals activity start; return: leg departure equals activity end, and a missing departure never equals) remain, and exactly one remaining candidate is the owner; (c) in every other case the leg has no owner. 근거: §1.3 (나)(다). 0.4.1까지는 후보를 구간 도착과 같은 날 시작하는 활동으로 먼저 좁혔다 — 자정을 넘긴 오는 편은 도착일이 활동 시작일과 달라 그 단계가 소유를 놓친다(§1.3 (바)). 이 함수는 드래그 시작과 드롭 때 한 번씩만 불리므로(REQ-009) 좁히지 않는 비용은 반복 활동 수 × 정방향 조회 한 번이다. 동률은 가는 편이면 도착, 오는 편이면 출발로 잰다 — 출발이 없는 오는 편은 동률이 성립하지 않는다(감사 4회차 N4-5).

- **REQ-005 (State-driven)**: While a dragged leg that still exists in the stored schedule has no owning activity — including a dangling link and an ambiguous recurrence match — the store shall apply today's behavior unchanged: a departure-anchored leg shifts as a whole and an arrival-anchored leg keeps its arrival and absorbs the drag into its buffer, clamped as today. 근거: 방향 ⑤〔제안〕. 지금 코드 `Store.swift:1400-1408`. 사라진 구간은 REQ-008의 독립 조항이 다룬다(N4-4 (b)).

### [DELTA] B 한계

- [NEW] 끌기의 유효 Δ를 정하는 Store 함수 하나와 최소 활동 길이 상수 하나. 화면의 최소 그리기 높이 상수(20분)는 그리기 전용으로 남는다.

- **REQ-006 (Ubiquitous · Unwanted)**: The leg drop shall not leave the owning activity shorter than the minimum activity length of 5 minutes, defined once in the store as a constant separate from the timetable's minimum drawing height; for an activity already shorter than that minimum, the limit shall reject any shortening and shall apply any lengthening unchanged. 근거: 게이트 D-3 "애초에 활동 자체를 5분으로도 설정할 수 있게"〔운영자〕 — 수동 폼은 종료가 시작보다 뒤이기만 하면 받으므로(`Shared/AddActivityView.swift:150-158`) 5분 활동은 이미 만들 수 있다. 5분은 드래그 한 칸이다. 그리기 최소 높이 20분(`ContentView.swift:531`)은 바꾸지 않는다〔가정 — 말씀 없음, `plan.md` Q-1〕.

- **REQ-007 (Ubiquitous · Unwanted)**: The leg drop shall allow the dragged leg and its owning activity to cross midnight, limited only as follows, where F is the first day on which the leg is listed before the drag and L the last: for an upward drag (negative Δ), the set of days on which the leg is listed shall not change — the new departure shall be on or after the start of F and the new arrival strictly after the start of L; for a downward drag (positive Δ), the new arrival shall be no later than the end of the day after F. For a warning block (no travel time) and for a broken record with no listed span, only the listing time — the warning block's anchor time, or the broken record's arrival — shall enter these limits, with F = L = the day of that time and the downward limit strict (before the end of the day after F). 근거: 게이트 D-4 "넘기기를 허용"〔운영자〕. 위로 넘기기와 상한은 말씀이 없다 — 연장이 "00시에서 내리는 만큼"이라 아래 방향에만 정의돼 있으므로 위로는 끌기 전 나열되는 날을 바꾸지 않는다〔가정〕(나열은 반열린 겹침 — `Store.overlapsDay` `Store.swift:38-41`, `ScheduledEvent.isListed(on:)` `Models.swift:229-235`; 위로 끌면 출발·도착이 함께 줄어 F 앞의 날에는 닿지 않고 L은 도착 > L 시작으로 남는다). 아래 상한은 끄는 날 다음 날 끝까지라 연장이 하루를 넘지 않는다〔가정〕. 경고 블록은 앵커의 날 하루에만 나열되고(`Models.swift:230`) 재추정 실패 뒤 남은 옛 도착(`Store.swift:1320`·`:1327`)은 나열에 쓰이지 않는다(감사 4회차 N4-1).

- **REQ-008 (Ubiquitous)**: For a leg with an owning activity, the effective Δ shall be computed by one store function that takes the leg and its already-resolved owning activity and uses only their times — no lookup over the stored schedules — from a requested Δ and the limits of REQ-006 and REQ-007, with times in seconds first truncated toward zero to whole minutes, the limits applied only in the direction of the request so that the effective Δ always lies between 0 and the requested Δ inclusive, and the result rounded toward zero to a multiple of the snap step, a single 5-minute constant defined once in the store and read by the gesture's rounding as well; the timetable gesture shall store that effective Δ as the drag's value during the drag; the drop shall re-read the dragged leg by its id from the stored schedule, resolve the owner once from that current value, and apply the store function to the value it receives (the drag's stored effective Δ) using only the current stored times — never the times of the leg value captured when the drag began — and when the effective Δ is 0 the drop shall change nothing. When the dragged leg's id no longer exists in the stored schedule, the drop shall change nothing, with or without an owner. 근거: 미리보기와 확정이 따로 한계를 계산하면 손을 놓는 순간 블록이 튄다(계약 5). 드롭 때 다시 읽는 것은 드래그·대화상자 사이 동기화나 재추정(`refreshUpcomingEstimates` `Store.swift:1547`)이 구간을 바꾼 경우를 막는다. `finalizeDrag`(바꾸지 않는다)가 넘기는 값은 드래그 값이다(N4-4 (a)). "0과 요청 사이"는 0.4.1의 반대 부호 금지를 포함하면서 요청보다 크게 움직이는 일도 막는다 — 대칭 자르기는 이미 상한을 넘은 옛 데이터에서 +15 요청을 −60으로 바꾼다(`progress.md` §E.1 0.5.0 표, AF-018-25).

### [DELTA] C 미리보기와 끄는 중 연장

- [MODIFY] `span(for activity:on:)`(`ContentView.swift:543-556`) · `span(for event:on:)`(`:558-592`) · `dragOffsetMinutes(forEvent:)`(`:600-603`) · 제스처 `onBegin`·`onChange`(`:458-466`) · 시각 눈금·구분선(`:420`·`:429`) · 하루 높이(`:483`·`:485`).

- **REQ-009 (State-driven)**: While a leg with an owning activity is being dragged, the timetable shall draw both that activity (start for an outbound leg, end for a return leg) and the dragged leg moved by the effective Δ inside the two block-extent functions, building the moved time first and then clipping it by comparing it with the drawn day's start and the day limit of REQ-015 — a time before the start clips to the start and a time after the limit clips to the limit — read through one view helper that names the dragged leg, its owning activity, and the effective Δ, where the owning activity is resolved once when the drag begins and kept in the drag value so that no block-extent, offset, or gesture-change computation resolves it again, so that rendering, layout, height, and hit-testing read the same moved extents and the dragged leg adds no separate translation; a moved block whose extent no longer meets the drawn day shall not be drawn as a full-height block or at a wrong position; a leg without an owning activity shall keep today's translation preview. 근거: §1.3 (사). 0.4.1까지의 "같은 날이면 자정 기준 분, 아니면 0 또는 1440" 자르기는 저장된 블록에서는 이 비교와 같은 값을 내지만(나열된 블록은 그 날과 겹친다), 옮긴 시각이 그리는 날 앞으로 가면 끝이 1440으로 잡혀 하루 전체 높이가 된다(감사 2회차 N-1과 같은 모양).

- **REQ-015 (State-driven · Where)**: While a leg with an owning activity is being dragged and the moved end of that leg or of its owning activity lies after the end of the day on which the drag began, the timetable page of that day shall extend below 24:00 by that excess rounded up to a whole hour, with the hour grid, its labels, the content height, both block-extent functions' clipping, and hit-testing all reading one view helper that yields the page's day limit in minutes; the limit shall be 1,440 at every other time and shall return to 1,440 when the drag ends, whether it is committed or cancelled; the other pages shall not change during the drag. Where the timetable provides automatic scrolling during a drag, the drag value shall include the scroll offset change in the requested Δ so that the preview and the drop still read one value. 근거: 게이트 D-4 "수정할 때에만 다음날 시간대가 보이도록(00시에서 내리는 만큼 시간대가 연장됨)"〔운영자〕, 해석 (1)(3)〔가정〕. 연장 눈금의 표기(다음 날 00·01…)는 `ui-design` 몫이다. 날짜 넘김은 드래그 중 잠겨 있어(`ContentView.swift:408`) 다음 날 페이지는 갱신하지 않는다 — 끄는 페이지가 연장된 시간대를 직접 그린다. 놓은 뒤에는 날짜별로 나뉘어 그려진다(지금의 나열·자르기, 해석 (2)). **자동 스크롤은 이 SPEC의 기본값에 없다**〔가정 — 리드 지시〕 — 그래서 연장된 시간대는 대부분 화면 아래 밖에 생긴다(§1.3 (자)). 자동 스크롤을 넣는 결정은 `plan.md` D-11·Q-4다. 활동 블록 드래그와 소유 없는 구간 드래그는 연장하지 않는다〔가정 — `plan.md` Q-9〕.

### [DELTA] D 반복 일정

- [EXISTING] 대화상자는 끌린 구간의 `recurrenceId`로 켜진다(`ContentView.swift:778`) — 그대로.

- **REQ-010 (Event-driven)**: When the user chooses to move the whole recurring series for a dragged leg with an owning activity, the store shall apply REQ-001 or REQ-002 to every activity with the owning activity's recurrence id, title, and location name, each through that occurrence's own same-role leg found by the forward leg lookup and each with the dragged Δ limited by that occurrence's own limits, and shall skip an occurrence that has no such leg without editing that occurrence; it shall leave every other activity of the recurrence and its legs unchanged; it shall persist the activities once and the events once for the whole operation regardless of the number of occurrences, re-sort the activities by start once when any start changed, and re-schedule the nearest notifications once. 근거: §1.3 (다)〔제안〕. 저장 규율은 지금 주석(`Store.swift:1409`)과 같다. 알림은 가장 가까운 60건을 다시 고른다(`rescheduleNearestNotifications` `:1519-1543`, 그 함수가 `save()`까지 한다 `:1542`).

- **REQ-011 (Event-driven)**: When the user chooses to move only this occurrence, or the dragged leg has no recurrence id, the store shall apply REQ-001 or REQ-002 to the dragged leg's owning activity only; the recurrence dialog shall continue to be keyed on the dragged leg's recurrence id. 근거: §1.3 (라).

- **REQ-016 (Ubiquitous)**: The store's estimated leg lookup for a recurring activity shall first look for the legs whose anchor time equals the activity's anchor-side time — an outbound leg whose arrival equals the activity's start and a return leg whose departure equals the activity's end, each with the activity's recurrence id and the place-name match used today — and shall fall back to today's same-day rule only for a role with no such leg, in the one function that the forward leg lookup and the packing groups already share. 근거: §1.3 (바) — 오는 편을 끌어 도착이 다음 날로 넘어가도 출발 = 활동 끝은 그대로라 정확한 대조가 연결을 지킨다〔제안 — 확인 필요, `plan.md` D-10·Q-6〕. 바뀌는 고정 핀은 AF-015-09·11이고 `@MX:WARN`(`Store.swift:436`)의 문장도 바뀐다. 같은 날 대조로만 이어지던 구간(옛 틈 데이터)은 지금과 같다 — 그 구간이 자정을 넘으면 여전히 연결을 잃는다(잔여 위험).

### [DELTA] E 동기성 · 외부 동기화

- **REQ-012 (Ubiquitous · Event-driven)**: The leg drop shall change the stored schedule synchronously — no `await` and no ignored `try?` in the drop — and, when the drop changed at least one activity and the Google account is connected, it shall reflect the change in Google Calendar by deleting and re-creating, for every changed activity and its dragged-side leg that already has a Google event id, that record's Google event, in exactly one `Task` per drop whose first synchronous segment reads those ids by record id from the current store, clears them on the records, and records the deletion tombstones before any remote call, then removes all of them in one batched removal and enqueues all of those records for upload in one call; no loop in the drop shall contain a network call; a remote deletion failure shall leave its tombstone for the next sync to retry, and an upload failure shall leave the record in the failed upload state shown in Settings; and when the account is not connected, the drop shall leave every Google event id and upload state unchanged. 근거: 게이트 D-6 "삭제 후 재생성으로 반영"〔운영자〕, 반복 "전체"에도 적용〔가정〕. 순서와 묶음은 `updateRecurringSeries`(`Store.swift:1073-1085` — gid 한 번에 모으기, 원격 삭제 전 로컬 gid 비우기, 삭제 한 번, 큐 한 번)와 `removeFromCalendar`(`:97-103` — 묘비 먼저)를 따른다. 묘비를 첫 동기 구간에서 남기는 이유: 로컬 gid를 비운 뒤 묘비 전에 동기화가 끼면 원격 사본을 모르는 일정으로 당겨올 수 있다(묘비 주석 `Store.swift:86-96`). 연결 확인과 재등록 대상은 `updateActivity`(`:288` — 연결됐고 gid가 있을 때만)와 같다 — gid가 없던 레코드는 새로 올리지 않는다. 화면에서 실패가 보이는 자리: 재등록 실패는 설정의 "캘린더에 못 올린 항목 N건"(`Shared/SettingsView.swift:61-64`), 원격 삭제 실패는 화면에 따로 뜨지 않고 다음 동기화가 다시 지운다 — 그 사이 구글에는 옛 길이와 새 길이 사본이 함께 보일 수 있다(`plan.md` §7). 비동기 재정렬 `realignLegs(of:)`(`:581`)는 쓰지 않는다.

### [DELTA] F 드라이버 · 범위

- **REQ-013 (Ubiquitous)**: The guard driver shall assert the observable behavior of REQ-001 through REQ-012 and REQ-016 by `plan.md` §5 — AF-018-02, AF-018-03, AF-015-09, and AF-015-11 rewritten in place and AF-018-04 through AF-018-28 added, each number one unconditional `drvCheck` call, with no fixture that waits on a travel-time estimate — and its run shall end with no ✗ and exit 0, with the new total recorded against a base total measured on the unchanged tree in the same run phase. 근거: 드라이버 하한 규칙(`Tools/GuardDriver.swift:306` — 실패 0이면 0, 하한은 문서에만). 새 총수 T = B + 25. 구글 연결 갈래와 화면 연장은 드라이버가 닿지 않는다 — 드라이버에서 `googleConnected`는 거짓이다(`Tools/GuardDriver.swift:1497`).

- **REQ-014 (Ubiquitous · Unwanted)**: The change shall touch only `Shared/Store.swift`, `Shared/ContentView.swift`, and `Tools/GuardDriver.swift` among source files; shall add no source file, no AI class, no color outside `Theme`, and no secret; shall leave `proxy/`, `Shared/AIAssistant.swift`, `Shared/GoogleCalendarService.swift`, `Shared/Models.swift`, and the activity drag (`moveActivity`) body unchanged; shall keep `adjustBuffer` reachable from the no-owner path; shall keep the iOS build free of source warnings; and shall neither build nor verify the macOS app. 근거: `CLAUDE.md` 계약 1·2·4·6, Day 파일 한도, iOS 전용 방침(2026-09-30). `moveActivity` 본문은 그대로지만 REQ-016이 그 함수가 읽는 추정을 바꾼다(§1.4).

## 3. 바뀌지 않는 것

- 활동 블록 드래그(`moveActivity` `Store.swift:1361-1382`)의 본문 — 활동과 두 구간이 함께 평행이동한다. 활동 드래그는 시간표를 연장하지 않는다.
- 길게 누르기 0.35초, 5분 단위, 탭·스와이프, 드래그 중 스크롤·날짜 넘김 잠금.
- 대화상자 문구("전체 반복 일정 이동" / "이 일정만 이동" `ContentView.swift:180-181`).
- 소유 활동이 없는 구간의 드래그(REQ-005)와 그 미리보기(평행이동, 연장 없음).
- 화면의 최소 그리기 높이(활동 20분 · 이동 16분, `ContentView.swift:531-532`).
- 끌기 뒤 겹침 검사를 하지 않는다. 실행 취소는 없다.
- `realignLegs`·활동 상세 화면의 구간 편집, 배치 묶음 함수 `packingGroups`의 본문(읽는 추정만 REQ-016으로 바뀐다).
- AI 도구·프록시·`Theme` 토큰·`GoogleCalendarService`.

## 4. 범위 밖

### Out of Scope — 끌기 대상 확장

- 활동 블록의 가장자리를 직접 잡아 늘리기(크기 조절 손잡이)는 만들지 않는다.
- 드래그 중 자동 스크롤은 이 SPEC의 기본값에 없다 — 운영자가 `plan.md` D-11의 (ii)를 고르면 REQ-015의 Where 절로 들어온다.
- 위로 0시를 넘겨 앞날로 늘이는 연장은 만들지 않는다〔가정〕.

### Out of Scope — 데이터 수리

- 옛 드래그로 생긴 틈을 드래그가 닫지 않는다(REQ-001).
- 같은 날 대조로만 이어지던 추정 구간(정확한 앵커 대조가 맞지 않는 옛 데이터)이 자정을 넘을 때의 연결 상실은 고치지 않는다(REQ-016 잔여).
- 배치 묶음이 두 활동이 같은 구간을 주장할 때 고르는 활동과 REQ-004의 소유 활동이 다를 수 있다 — 묶음 규칙은 바꾸지 않는다.

### Out of Scope — 외부 동기화

- 구글 연결이 끊긴 상태에서 놓은 드래그를 나중에 연결됐을 때 다시 올리지 않는다 — 지금 활동 드래그와 같다.
- 구글 일괄 요청(batch API)·반복 이벤트(RRULE) 전환은 하지 않는다.
- 활동 블록 드래그(`moveActivity`)의 구글 반영은 이 카드에서 하지 않는다(물려받은 갭 그대로).

### Out of Scope — 맥 앱과 문서

- 맥 앱은 빌드·검증하지 않는다(iOS 전용 방침).
- 동결된 SPEC-UIKIT-009 파일은 고치지 않는다(운영자 답변 D-8).

## 5. 결정

미해소 질문은 `plan.md` §2 끝의 열린 질문 목록에 있다. 착수 승인 뒤 이 표를 확정안으로 바꾼다.

| 결정 | 지금 상태 | 이 SPEC에서 닿는 곳 |
|---|---|---|
| D-1 의미(오는 편 = 끝, 가는 편 = 시작) | 〔운영자〕 확정 — 리드 경유 | REQ-001·002·003 |
| D-2 진입점·역방향 조회·동률 규칙 | 〔제안〕 — 0.5.0에서 같은 날 좁히기 삭제 | REQ-004·005·011 |
| D-3 최소 길이 5분 | 〔운영자〕 답변 + 그리기 높이 유지〔가정〕 | REQ-006 |
| D-4 자정 넘기기 허용 | 〔운영자〕 답변 + 위로 한쪽 자르기·아래 상한〔가정〕 | REQ-007·015 |
| D-5 미리보기 = 확정 | 〔제안〕 — 0.5.0에서 자르기를 그리는 날 기준 비교로 | REQ-008·009 |
| D-6 구글 삭제 후 재생성 | 〔운영자〕 답변 + 반복 "전체" 포함〔가정〕 | REQ-012 |
| D-7 반복 "전체" = 같은 역할 회차 | 〔제안〕 | REQ-010 |
| D-8 SPEC-UIKIT-009 파일 무수정 | 〔운영자〕 답변 | §1.4 · §4 |
| D-9 옛 틈 데이터 = 틈 유지 | 〔제안〕 | REQ-001 |
| D-10 정확한 앵커 대조 우선 추정 | 〔제안 — 확인 필요〕 | REQ-016 |
| D-11 끄는 중 연장의 화면 도달 — 자동 스크롤 없음 | 〔가정 — 리드 지시〕, 선택지 비교 | REQ-015 |

## 6. 관련 문서

- `.moai/reports/2026-10-05-sim-4bundle-result.md:23`·`:65` — 카드 t43과 18번 메모 원문
- `.moai/reports/t43/gate-answers.md`(주 체크아웃, 미추적) — 게이트 답변 원문과 리드 해석
- `.moai/reports/plan-audit/SPEC-UIKIT-012-review-1.md`~`-review-4.md` — plan 감사 1~4회차(0.5.0은 감사받지 않았다)
- [SPEC-UIKIT-009](../SPEC-UIKIT-009/spec.md) — 대체되는 드래그 의미
- [SPEC-UIKIT-011](../SPEC-UIKIT-011/spec.md) — 형식 기준. 드라이버 하한 498은 루트 `plan.md:458`·`CHECKLIST.md:284`
- 이 SPEC의 조사 기록 — `research.md`

🗿 MoAI
