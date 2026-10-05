---
id: SPEC-UIKIT-009
title: "편집 카드 통일(U-1) — 이동 구간을 활동 카드의 줄로 · 시간 수정 시 결합 유지 · 오는 편 나중 추가 · 삭제 연계 · 겹침 크기 연동"
version: "0.1.4"
status: completed
created: "2026-09-30"
updated: "2026-10-05"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "u-1, edit-card-unify, leg-rows, leg-coupling, delete-linkage, overlap-group, timetable-layout"
tier: L
related_specs: [SPEC-UIKIT-003, SPEC-UIKIT-004, SPEC-UIKIT-007, SPEC-UIKIT-008]
kanban_card: t17
---

# SPEC-UIKIT-009 — 편집 카드 통일(U-1)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-30 | 최초 작성. 칸반 카드 t17(C8 U-1) 본문과 운영자 원문(2026-09-23, 세 가지 제안)을 GEARS로 정식화했다. 기준 트리는 `b2c3987`(브랜치 `WT-edit-card-unify`)이다. 연구 입력은 읽기 전용 렌즈 보고서 셋(`.moai/reports/t17/plan-lens-data-store.md`·`plan-lens-ui-edit-surfaces.md`·`plan-lens-timeline-overlap.md`)이며 본문을 옮기지 않고 절 번호로 인용한다. **줄번호는 전부 이 세션이 이 트리에서 명령으로 다시 쟀고 세는 명령을 옆에 적었다**(렌즈의 `[재측]` 표지는 오케스트레이터 몫이라 그대로 믿지 않았고, 어긋난 자리는 `research.md` §4에 적었다). 게이트 수치(드라이버 `357/357`, iOS·macOS 전체 빌드)는 오케스트레이터가 같은 트리에서 돌려 `.moai/state/verify/t17-plan/`에 남긴 로그를 읽어 인용했다. 미해소 결정 13건은 `plan.md` §2에만 게이트 표식으로 두고(SPEC-UIKIT-005 HISTORY 0.1.0 관례), 이 문서는 **권장 선택지 기준**으로 한 벌의 계약이 되도록 썼다 — 운영자의 답이 다르면 `plan.md` §2가 바꿀 REQ·AC 줄을 적어 두었다. 오케스트레이터의 설계 방향("구간은 활동 카드의 줄 소속, 시간은 유도")을 그대로 받되 세 곳에서 증거와 다르게 읽었다(`research.md` §4: 유도 시간은 AI 경로의 결합 상실을 막지 못한다 · 묶음 배치는 묶음 안 겹침을 처리해야 한다 · 충돌 검사 입력은 호출자가 없어 죽은 API가 된다) |
| 0.1.1 | 2026-09-30 | plan-audit 1회차 FAIL(0.73, `.moai/reports/plan-audit/SPEC-UIKIT-009-review-1.md`)을 반영했다. **결정 게이트 해소**: D-1~D-13을 운영자가 칸반 리드를 거쳐 답했다(이 세션은 운영자의 답을 직접 보지 않았다). 권장안 12건 채택, **D-8만 (b)로 바뀌었다** — 증상이 반복 회차에서도 났다는 답에 따라 `linkedLegs` 추정을 배치 묶음에만 재사용한다(REQ-015·AC-015, 삭제 연쇄 확장은 별도 결정). review-1 D3는 운영자가 **(b)를 골랐다**(코드 변경 포함) — 이동시간을 계산하지 못한 오는 편도 경고 블록으로 그린다. 이것이 **REQ-023 신설**이고 요구사항은 22 → 23, 수락 기준은 24 그대로다(검증은 AC-010·AC-015에 항목으로 넣었다). 결함별: D1 표식 13건 → 해소 기록(`plan.md` §2) · D2 카드 범위를 카드별 기준 커밋으로(AC-022, `plan.md` §5) · D3 REQ-010 근거·경계표·스크립트를 역할별로(13a는 MB 뒤, 20은 MC 뒤) · D4 통과 수를 드라이버 하한과 명령 항목으로 갈라 다시 셈(AF 65 · AG 9 · AH 24 → T ≥ 455) · D5 AC-018 가는 편에도 힌트(`addEvent` 직접) · D6 REQ-020·AC-003·AC-020 (5)를 한 벌로(REQ-003의 재현 주장은 뺐다) · D7 REQ-015에 lane 정의 · D8 절마다 단언이나 갭 줄 · D9 AC 매트릭스에 카드 열을 두고 `plan.md` §0·§1을 거기에 맞춤 · D10 판단에 기대던 항목을 이진 대리 지표나 갭으로 · D12 문형 이름표 · D13 반복 경로 범위를 `:628-695` 한 측정으로. D11(REQ 분할)은 채택하지 않았다(REQ 상한 여유 2를 남긴다) |
| 0.1.2 | 2026-09-30 | plan-audit 2회차 FAIL(0.84, must-pass 전부 PASS, `.moai/reports/plan-audit/SPEC-UIKIT-009-review-2.md`)을 반영했다. 요구사항 23 · 수락 기준 24는 그대로다(새 검증은 기존 AC의 항목으로 넣었다). 결함별: **D14** REQ-023이 실패 모양을 하나(새로 만든 오는 편)로만 봤다 — 이동시간 미계산 레코드의 모양 넷(도착 기준 · 출발 기준 새로 만듦 · 출발 기준 재추정 실패 · 반복 뒤 회차)을 적고, 경고 블록 하나를 **앵커 시각**(출발 기준은 저장된 출발, 없으면 도착 / 그 밖은 도착)에 두고 **그 시각의 날에만** 나열하는 규칙과, 나열·달력 점·블록 선택·기하가 한 함수를 읽는다는 절을 REQ-023에 넣었다. 달력 점(`Store.swift:132-150`)이 같은 함수를 읽으므로 MC가 `Store.swift`를 작게 고친다(크게 고칠 파일은 3 그대로). AC-010에 MA 항목 (10)(재추정 실패 모양의 결정적 재현)과 MC 항목 (11)–(13)(앵커·나열·점), AC-017에 (9)(자정을 넘는 재추정 실패 실례 E9)를 더했고, 통과 수를 다시 셌다(AF 66 · AG 9 · AH 28 = 103, 누적 바닥 423 → 432 → 460) · **D15** REQ-020의 다섯째 재현을 "기준 트리에서 먼저 보인다"에서 떼어 냈다 — 게이트 실행은 온라인 추정을 전제하므로(S·J 전제 단언) 새로 만든 구간의 실패 모양은 이름 붙인 오프라인 실행의 도달 기록으로, 재추정 실패 모양은 출발지 없는 레코드의 결정적 경로로, 판정과 배치는 메모리에서 만든 값으로 보인다. AC-010 (4)·(7), AC-020 (5), `acceptance.md`의 결정성 문단을 같은 문장으로 맞췄다 · **D16** AC-015의 늦은 회차 L을 모레로 옮기고 조회의 기대 반환을 사전의 키·값으로 적었다 · **D17** AC-013의 grep 항목에 번호 (4) · **D18** `spec-compact.md` 머리의 결정 문구 · **D19** AC-024의 대응 REQ에 001·002·008. D11은 이번에도 채택하지 않았다 |
| 0.1.3 | 2026-09-30 | **iOS 전용 방침**을 반영했다(감사 결함이 아니라 운영자 방침이고 결정 게이트가 아니다 — `plan.md` §2 방침 P-1). 출처: 운영자 방침을 칸반 리드가 전했다(이 세션은 운영자의 말을 직접 보지 않았다). 방침의 원문은 주 체크아웃의 `CLAUDE.md`(`master` 커밋 `00cd149` "docs: iOS 전용 전환 — 맥 빌드·검증 중단, 코드는 보존 (운영자 지시 2026-09-30, card t38)")에 있고 이 워크트리의 `CLAUDE.md`에는 없다 — 이 세션이 `git log --oneline -3 master`·`git show 00cd149:CLAUDE.md`로 읽었다. 뺀 것: 맥 빌드 게이트(AC-020 (3)의 맥 절, `plan.md` §5의 맥 행)와 맥 기준선 수치(`^SwiftCompile` 38 · 맥 프로젝트 경고 0 · `mac-build.log`), "두 빌드"·"두 플랫폼" 문구, 시뮬레이터 스크립트 23(맥 배치 대조). 바꾼 것: REQ-019의 플랫폼 절("iOS·macOS에서 같게 동작")을 방침으로 — 개발·검증은 iOS만, 새 맥 전용 코드 없음, 기존 맥 코드와 `#if os` 분기는 지우지 않음. 더한 것: AC-019 (6)(`#if os` 줄 불변의 명령 대리 지표, 양성 대조 포함) · §3의 받아들인 갭(맥 타깃도 `Shared/`를 컴파일하므로 맥 빌드가 없으면 깨져도 드러나지 않는다). iOS 빌드·드라이버·grep 검증은 그대로다. 드라이버 하한은 바뀌지 않는다(AF 66 · AG 9 · AH 28 = 103, 바닥 423 → 432 → 460 — AC별 재계산은 `progress.md` §E.1). 요구사항 23 · 수락 기준 24 그대로 |
| 0.1.4 | 2026-10-05 | plan-audit 3회차 FAIL(0.84, must-pass 전부 PASS, 통과선 0.85, `.moai/reports/plan-audit/SPEC-UIKIT-009-review-3.md`)의 blocking 결함 **D20~D24만** 고쳤다. 요구사항 23 · 수락 기준 24 · 드라이버 하한(AF 66 · AG 9 · AH 28 = 103, 바닥 423 → 432 → 460)은 그대로다 — 바뀐 항목이 모두 명령·갭 항목이다. 결함별: **D20** AC-022의 경로 집합을 정했다 — (1)은 SPEC 디렉터리와 보고서 경로를 빼고 재고(`-- . ':!.moai/specs/SPEC-UIKIT-009' ':!.moai/reports'`, 전례 SPEC-UIKIT-008 `acceptance.md:271`) (2)의 크게 고친 파일 수는 `-- Shared Tools`로만 센다. `plan.md` §1의 MB·MC 선언에 MA와 같은 sync 문서 줄을 더해 `spec-compact.md`와 맞췄고, REQ-022 근거에 경로 규칙을 한 줄 적었다 · **D21** REQ-020의 도달 기록 절을 `addEvent`로 새로 만든 구간(모양 (가)·(나))으로 좁혔다. 반복 뒤 회차 (라)는 드라이버에 결정적 경로가 없고 그것을 보는 단언도 없어 메모리에서 만든 레코드(AC-010 (7)(11)(12)(13))로만 보인다 — 이 갭을 REQ-020 근거 · AC-010 갭 줄 · AC-020 (5) ⓑ에 적었다 · **D22** AC-015 Given·(9)의 "네 구간" → "세 구간" · **D23** 달력 점이 인라인 사본 대신 공유 함수가 돌려주는 나열 구간을 `dayKeys`에 넘긴다(`design.md` §4·§9) — AC-010 (9)에 `Store.swift`의 `e.arrivalDate > dep` 0건 명령을 더했다 · **D24** AC-019 (6)의 갭과 `plan.md` §4 `code-safety` 몫에 지시문 밖에서 주석이 맥 전용으로 밝힌 코드(`ContentView.swift`의 `.onTapGesture` 셋 `:618`·`:641`·`:674`)를 더했다. optional D25·D27~D29·D11은 고치지 않았다. D26의 문구(AC-002)는 이 판 이전에 기록 없이 들어간 편집으로 이미 있었고 이 판은 손대지 않았다(`progress.md` §E.1 0.1.4 수정 기록) |

## 0. 이 SPEC의 성격과 예산

**한 카드 안에 성격이 다른 두 결함이 있다.** 운영자 ①(편집이 활동을 모른다)은 데이터 결합의 문제이고 ②(배치가 연결을 모른다)는 화면 배치의 문제다. 둘은 고치는 파일이 거의 겹치지 않는다(①은 `Store`·편집 화면, ②는 `Models`·`ContentView`). 그래서 계약은 하나로 두되 마일스톤은 셋으로 나눠 배달 카드 셋에 1:1로 대응시킨다(`plan.md` §1, 결정 D-11).

**Tier: L.**

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 관련 파일 길이 | ContentView 980 · Store 1499 · AddEventView 781 · AddActivityView 630 · EditCardView 538 · ActivityDetailView 444 · EventDetailView 430 · EditCard 356 · Models 513 · GuardDriver 3474 · AIAssistant 3174 | `wc -l Shared/*.swift Tools/GuardDriver.swift` |
| `linkedActivityId` 사용처 | **18곳** (Models 1 · Store 9 · AIAssistant 3 · ContentView 1 · AddActivityView 1(주석) · GuardDriver 3) | `grep -rn linkedActivityId Shared ShareExtension Tools proxy \| wc -l` |
| 편집 화면의 활동 참조 | `AddEventView` **0** · `EventDetailView` **0** | `grep -c "activities\|ActivityBlock\|activityId\|linkedActivityId" Shared/AddEventView.swift Shared/EventDetailView.swift` |
| 공유 카드 호출처 | `EditCardView(` **4곳** (AIChatView:110 · AddEventView:68 · ActivityDetailView:64 · AddActivityView:72) — 렌즈의 "5곳"은 오기 | `grep -rn "EditCardView(" Shared` |
| 이동 구간 줄 문법(뷰 로컬) | 줄 빌더 함수 **5**(`AddActivityView.swift:330·336·353·363·371`) · `fields.insert/remove` **11**곳 · 기억값 `@State` **9** | `grep -c 'private func legToggleRow\|…' Shared/AddActivityView.swift` · `grep -c "fields.insert\|fields.removeAll\|fields.remove(" …` · `grep -c "@State" …`(파일 전체 18 중 PlaceField 3 제외) |
| 생성기 호출 | `addActivityWithTravel(` **3곳**(FullSirView:463 · AddActivityView:523 · AIAssistant:2005) | `grep -rn "addActivityWithTravel(" Shared` |
| `Store.conflicts(` 호출 / `isSamePlace(` | **4곳**(AddEventView:692 · AIAssistant:1803·2042·2849) / **6줄**(정의 :2917 + 사용 :1085·1348·1779·1968·2192) | `grep -rn "\.conflicts(" Shared` · `grep -n "isSamePlace(" Shared/AIAssistant.swift` |
| 드라이버 기준선 | `357/357 통과` · ✓ 357 · ✗ 0 · exit 0 · 실제 데이터 대조 통과 | `grep -c '^  ✓ ' driver-run.log` · `grep -c '^  ✗ ' driver-run.log`(오케스트레이터 로그) |
| 빌드 기준선 | iOS `** BUILD SUCCEEDED **`(`ios-build.log:944`) · `^SwiftCompile` 42 · 프로젝트 경고 0(툴체인 안내 `Metadata extraction skipped` 제외) · 드라이버 컴파일 경고 24줄. 기준선은 iOS 하나다(iOS 전용 방침 — `plan.md` §2 P-1) | `grep -c '^SwiftCompile' ios-build.log` · `grep 'warning:' ios-build.log \| grep -v 'Metadata extraction skipped' \| wc -l` · `grep -c 'warning:' driver-compile.log` |
| 바꿀 파일(**예측 — 측정 아님**) | 앱·도구 소스 8(`Store` · `Models` · `EditCard` · `AddActivityView` · `ActivityDetailView` · `EventDetailView` · `ContentView` · `GuardDriver`) + 문서 2(`CHECKLIST.md` · 루트 `plan.md`). 0.1.1·0.1.2의 변경은 목록을 늘리지 않는다 — D-8 (b)는 `Store`(MA)에 조회 하나, REQ-023은 `Models`(판정 함수)·`ContentView`(나열·블록 선택·기하)와 `Store`의 달력 점 계산 몇 줄(MC, 작게 고침)을 바꾼다 | `plan.md` §1 카드별 목록 |
| REQ / AC 수 | **23 / 24** | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` |

**Tier 판단(측정에 기대)**: Tier M 상한은 요구사항 16·수락 기준 16인데(`spec-workflow.md` § SPEC Complexity Tier) 이 계약은 23·24다 — 요구사항 수만으로 M을 넘는다. 파일 수(소스 8 + 문서 2 = 10)만 보면 M 범위(5~15)이므로 **측정이 L과 어긋나지는 않지만 L을 강제하는 것은 요구사항·수락 기준 수와 세 하위 시스템(데이터·편집 화면·시간표 배치)에 걸친다는 점**이다. 변경 줄 수는 측정할 수 없다 — 코드를 쓰기 전이라서다. 참고로만 전 카드 SPEC-UIKIT-008이 `git diff --shortstat aa7b792 HEAD -- Shared Tools`로 5파일 +1983/−90이 나왔고(같은 저장소의 실측), 이 카드의 드라이버 단언 분량이 비슷한 규모일 가능성은 **가설**이다.

**한 Day 파일 한도(3~4)**: `CLAUDE.md`의 한도는 "새로 만들거나 크게 고치는 파일"을 센다. 이 카드의 크게 고칠 파일 예측은 `Store` · `EditCard` · `AddActivityView`(줄 문법을 빼내는 쪽) · `ActivityDetailView` · `Models` · `ContentView` · `GuardDriver`로 **7 > 4**다. 그래서 한 카드로 갈 수 없고, 요구사항 모듈을 따라 배달 카드 셋으로 나눈다(결정 D-11). "크게 고침"의 조작적 정의(`git diff --numstat` 추가+삭제 100줄 이상)는 이 SPEC의 제안이며 리드가 확정한다.

**드라이버 초록은 이 SPEC의 증거로 반만 센다.** 드라이버 컴파일 집합에 `ContentView.swift`가 없어 시간표 배치를 지금 모양으로는 돌릴 수 없고(타임라인 렌즈 §6), 화면이 어떻게 보이는지·탭과 드래그의 느낌은 시뮬레이터 앞의 사람만 본다. 이 프로젝트에는 드라이버 88/88 다음 날 실기기 결함 7건이 나온 이력이 있다(2026-09-15). 그래서 배치는 컴파일되는 순수 함수로 빼서 측정하고(REQ-016), 사람만 볼 수 있는 것은 시뮬레이터 스크립트로 넘긴다(AC-023·024).

## 1. 배경

### 1.1 카드와 운영자 원문

카드 t17(C8 U-1, 대형): "이동일정 편집창을 생성 카드와 같은 문법으로: 시간 수정 시 활동 분리 해소 + 오는 편 나중 추가 가능화. 삭제 연계: 활동 삭제 시 연계 이동 모두 삭제, 이동 삭제는 단독. 겹침 시 블록 크기 연동."

운영자 원문(2026-09-23, U-1): "① 이동일정 편집창과 활동일정 편집창이 달라 이동일정에서 시간을 고치면 활동과 분리됨 + 가는 편만 만든 뒤 오는 편을 나중에 추가할 방법이 없음 — 이동일정 편집창을 생성 시의 카드와 같은 문법으로 통일하면 둘 다 해결된다고 봄. 삭제 연계 요구: 이동일정 삭제는 그것만, 활동 삭제 시 연계된 이동일정도 함께 삭제. ② 겹치는 일정이 생기면 활동 블록만 반으로 줄고 이동 블록은 안 줄어듦 — 둘 중 하나라도 줄면 연계 것도 같이 줄도록."

### 1.2 "분리"의 정확한 뜻 — 데이터 연결이 아니라 결합이다

운영자는 "시간을 고치면 활동과 분리된다"고 했다. 코드를 읽으면 끊기는 것은 데이터 연결(`linkedActivityId`)이 아니다.

- `Store.updateEvent`는 저장된 레코드의 복사본에서 시작해(`Store.swift:958`) `linkedActivityId`를 대입하지 않는다. 연결을 지우는 코드도 없다(`grep -rn "linkedActivityId = nil\|linkedActivityId: nil" Shared` → 없음, UI 렌즈 §8 (a)). 연결이 만들어지는 곳은 `addEvent` 한 곳뿐이다(`:591`, 인자를 넘기는 호출은 `:217`·`:225`).
- 끊기는 것은 **결합**이다. `updateEvent`는 활동을 건드리지 않고, 편집 화면은 활동을 모른다(위 표의 0·0). 카드의 `arr:`/`dep:` 접두로 `anchor`(`Models.swift:199`)가 뒤집히면 `linkedLegs`의 역할 판별(`Store.swift:1122-1123`)이 바뀌고, 출발지·도착지·제목은 활동 장소와 대조 없이 고쳐진다.
- 그 결과 활동을 옮기는 `moveActivity`(`:1065-1086`)는 어긋난 오프셋을 같은 변위로 옮겨 굳히고, `realignReturnLeg`(`:333-340`)는 `anchor == .departure`인 구간만 다시 맞춘다.

이 구분이 요구사항의 모양을 정한다 — "연결을 되살린다"가 아니라 **"결합을 끊을 수 있는 편집 경로를 없앤다"**(REQ-001·002).

### 1.3 설계가 기대는 측정 사실

| # | 사실 | 자리 | 확인한 명령 |
|---|---|---|---|
| F1 | 연결은 구간 → 활동 한 방향이다. 역할(가는 편/오는 편)은 `anchor`(`.arrival`/`.departure`/nil=arrival)이고 " (복귀)" 접미는 이름 관례다 | `Models.swift:154-200`·`:498` · `Store.swift:222` | `sed -n 154,200p Shared/Models.swift` · `grep -n "struct ActivityBlock" Shared/Models.swift` |
| F2 | 구간을 만드는 길은 `addActivityWithTravel` 하나이고 활동까지 만든다. `addEvent`는 이미 `linkedActivityId`·`anchor`를 받는다 | `Store.swift:189-230` · `:572-583` | `grep -n "func addActivityWithTravel\|func addEvent" Shared/Store.swift` |
| F3 | 활동 저장은 시간을 따라 구간을 옮긴다. 그러나 `newPlace == nil`은 "그대로 둠"이라 "장소 없음"으로 장소를 지울 수 없고(`:321`), 끝이 시작 이하면 활동은 거절하는데(`:322`) 오는 편은 그래도 그 끝에 재정렬한다(`:326-328`) | `Store.swift:301-330` | `sed -n 301,330p Shared/Store.swift` |
| F4 | 낱개 `deleteActivity`는 명시적 연결 구간을 같이 지우고, 일괄 `deleteActivities`는 지우지 않으며, `deleteEvent`는 그 이벤트만 지운다 | `Store.swift:371-384` · `:1303-1313` · `:1273-1282` | `sed -n` 세 범위 |
| F5 | 일괄 삭제의 호출자는 AI 삭제 경로 하나다(테스트용 임시 `deleteEverythingForTesting` 제외) | `AIAssistant.swift:2909` · `Store.swift:1321` | `grep -rn "deleteActivities(" Shared` |
| F6 | `EventDetailView`의 "같은 제목 일정 모두 삭제"는 제목 문자열 동등으로 모으고 `deleteEvent`를 루프한다. 연결된 가는 편은 활동과 같은 제목이다 | `EventDetailView.swift:331-333` · `:356` · `:373` · `Store.swift:214` | `sed -n 318,390p Shared/EventDetailView.swift` |
| F7 | 편집 진입은 하나다: 툴바 "편집" → `AddEventView(editing:)` 시트 | `EventDetailView.swift:88` · `:91-92` | `grep -rn "AddEventView(editing" Shared` → 1줄 |
| F8 | 시간표는 활동과 구간을 한 번에 배치하고 연결을 보지 않는다. 무리 끊기 판정이 `<=`라 끝 = 시작으로 맞닿은 구간과 활동은 다른 무리다 | `ContentView.swift:699-742` · `:730` · `:651`(연결을 읽는 유일한 곳, 제목 숨김) | `sed -n 699,742p Shared/ContentView.swift` · `grep -n linkedActivityId Shared/ContentView.swift` |
| F9 | 렌더 프레임은 3 pt 간격을 넣고 히트테스트는 안 넣는다 — 열 산술이 두 곳에 있다 | `ContentView.swift:745-750` · `:759-773` | `grep -n "gap \* CGFloat\|1 / CGFloat(p.columns)" Shared/ContentView.swift` |
| F10 | 묶음 안에서도 블록이 서로 겹친다: 활동 최소 20분(`:533`)·구간 최소 16분(`:534`), 이동시간 계산 실패 블록은 도착 시각에서 **아래로** 20 pt 자란다(`:557-563`) — 가는 편이면 활동 시작 위로 겹친다 | `ContentView.swift:533-536` · `:542-583` | `sed -n 527,585p Shared/ContentView.swift` |
| F11 | 저장은 합성 Codable이다. 비-Optional 필드를 더하면 디코더가 던지고 `load()`·`loadActivities()`가 조용히 빈 배열로 돌아와 다음 `save()`가 파일을 `[]`로 덮는다 | `Store.swift:1494-1498` · `:393-397` · `Models.swift:180-182` | `grep -n "CodingKeys\|init(from" Shared/Models.swift` → 없음 · `sed -n 1487,1499p Shared/Store.swift` |
| F12 | 구글 캘린더 왕복은 `linkedActivityId`·`anchor`를 싣지 않는다. 추가·수정·삭제는 캘린더를 갱신하지만 `moveActivity`·`shiftEvent`·`adjustBuffer`는 안 한다 | `GoogleCalendarService.swift:169-225` · `Store.swift:1065-1171` | `grep -c "linkedActivityId\|anchor" Shared/GoogleCalendarService.swift` → 0 · `awk 'NR>=1065 && NR<=1171' Shared/Store.swift \| grep -c "enqueueCalendarUpload\|removeFromCalendar"` → 0 |

### 1.4 이웃 카드

카드 t30(C21 AI 카드 문법 통일)이 같은 "카드 문법 통일"을 AI 채팅 카드에서 한다. **범위 밖이다.** 다만 이 SPEC이 빼내는 줄 문법이 t30을 막지 않게, 줄 키 어휘를 한 표로 두어 AI 카드 어휘(`travel_from_query`·`return_to_query`, `AIAssistant.swift:567-568`)가 사상만 하고 두 번째 빌더를 만들지 않게 한다(REQ-007).

## 2. 요구사항 (GEARS)

### [DELTA] A 결합 — 편집이 활동을 안다

- [EXISTING] 활동 저장은 시간을 따라 구간을 옮긴다(`modifyActivity` → `moveActivity`·`realignReturnLeg`, `Store.swift:301-340`) — 특성화만 한다.
- [MODIFY] 연결된 구간의 편집 진입(`EventDetailView.swift:88-92`) · 활동 저장(`Store.swift:301-330`) · 활동 상세 화면(`ActivityDetailView.swift`).
- [NEW] 활동 카드의 구간 줄 · 구간에서 활동을 찾는 조회(매달린 링크는 없음으로).
- [REMOVE] 연결된 구간을 단독 이동 폼으로 고치는 UI 경로.

- **REQ-001 (Event-driven)**: When the user chooses 편집 on the detail screen of a travel leg whose `linkedActivityId` resolves to an existing activity, the app shall open that activity's edit card with the leg's rows shown, and shall not open the stand-alone travel edit form for that leg. 근거: 결합이 끊기는 경로는 이 진입뿐이다 — 편집 단추(`EventDetailView.swift:88`)가 `AddEventView(editing:)` 시트를 여는 호출은 저장소 전체에서 이 한 줄이다(`grep -rn "AddEventView(editing" Shared`). `AddEventView`·`EventDetailView`의 활동 참조는 0·0이라 그 폼은 활동이 있는지조차 모르고, `updateEvent`는 복사본에서 시작해 활동에 손대지 않는다(§1.2). 결정 D-1.

- **REQ-002 (Ubiquitous · Unwanted)**: The activity edit card shall derive each linked leg's time from the activity — the outbound leg arrives at the activity's start and the return leg departs at the activity's end — and shall contain no row that changes a leg's time basis, its link, or its activity-side endpoint. 근거: 결정 D-3. 시간 줄이 있으면 `arr:`/`dep:` 접두로 기준이 뒤집히고(`EditCard.swift:63-96`, 접두 목록 `:69`) 뒤집힌 구간은 `linkedLegs`의 역할 판별에서 빠진다(`Store.swift:1122-1123`). 시간을 유도로만 두면 시간 수정이 결합을 끊을 수 없다. 생성 카드도 이미 같은 정의다 — 토글 문구가 "활동 시작에 맞춰 도착"·"활동 끝나면 출발"이다(`AddActivityView.swift:191-192`).

- **REQ-003 (Event-driven)**: When the user saves an activity through the activity edit card, each explicitly linked leg shall follow the saved activity: its time by the derivation rule of REQ-002, its activity-side endpoint (the outbound leg's destination, the return leg's origin) from the saved place with the travel time re-estimated, and its title from the saved title. 근거: 지금 저장은 시간만 따라온다(`Store.swift:301-340`). 제목·장소 변경이 구간의 끝점·제목에 닿는 코드는 없다(코드 열람, 데이터 렌즈 §3). 이것은 기준 트리에서 재현하지 않는다 — 고칠 기존 줄이 없는 **새 능력**이기 때문이다. `modifyActivity`는 동기 함수(`-> Bool`, `Store.swift:301-305`)라 이동시간 재추정이 들어갈 자리가 아니고, 따라오기는 새 비동기 진입점이 맡는다(`design.md` §3). 그래서 REQ-020의 재현 목록에 들지 않는다. 장소만 바뀐 활동에 옛 장소로 향하는 구간이 남으면 카드가 보여주는 줄과 실제 구간이 어긋난다. 결정 D-13.

- **REQ-004 (Event-driven)**: When the user saves an activity whose place was cleared with the "장소 없음" chip, the activity's linked legs shall be removed with the place, and the card shall already have shown the leg rows gone before the save. 근거: 구간은 활동 장소가 있어야 존재한다 — `addActivityWithTravel`은 `location == nil`이면 구간 없이 돌아온다(`Store.swift:211`). 생성 카드도 "장소 없음"을 고르면 구간 줄 아홉 키를 전부 뺀다(`AddActivityView.swift:195-203`). 카드에 보인 것과 저장 결과가 다르면 조용한 삭제다. 결정 D-13.

- **REQ-005 (Event-driven · Unwanted)**: When an activity is saved with its place cleared, the activity's place shall become empty; and when an end time that is not later than the start is supplied, the activity shall reject it and its linked legs shall not be re-aligned to that end time. 근거: `modifyActivity`는 `newPlace == nil`을 "그대로 둠"으로 본다(`Store.swift:321`) — 상세 화면의 "장소 없음" 칩은 지금도 장소를 지우지 못한다(UI 렌즈 §3, 코드 읽기 가설 — REQ-020이 재현한다). 끝이 시작 이하면 활동은 거절하는데(`:322`) 오는 편 재정렬(`:326-328`)은 그대로 실행되어 활동 끝에서 조용히 떨어진다 — 카드 UI는 그 입력을 막지만(`ActivityDetailView.swift:227`) AI 경로(`AIAssistant.swift:2821`)는 닿는다. 결정 D-12.

- **REQ-006 (State-driven · Unwanted)**: While a travel leg's `linkedActivityId` does not resolve to an existing activity, the app shall treat that leg as stand-alone — its edit shall open the stand-alone travel form and its title shall be drawn on the timetable. 근거: 이런 구간은 지금 생긴다 — 일괄 `deleteActivities`(`Store.swift:1303-1313`)는 연쇄가 없고 AI 삭제가 그 경로다(`AIAssistant.swift:2909`), `addActivityWithTravel`은 두 `await addEvent` 사이에 활동이 남아 있는지 다시 보지 않는다(`Store.swift:214`·`:222`). 연결된 구간의 제목은 시간표가 그리지 않으므로(`ContentView.swift:651`) 매달린 링크의 구간은 이름 없는 블록이 되고, 편집 진입이 활동 카드로 가면 열 활동이 없다.

### [DELTA] B 오는 편·가는 편 나중 추가와 제거

- [EXISTING] 생성 카드의 구간 줄 문법(뷰 로컬, `AddActivityView.swift:169-376`) — 문법 동등성을 특성화한 뒤 옮긴다.
- [MODIFY] `AddActivityView`(줄 문법을 공유 타입으로 교체) · `addActivityWithTravel`(구간 생성 경로를 새 진입점으로 모음).
- [NEW] 공유 줄 문법(SwiftUI-free) · 구간 추가·수정·제거 진입점과 보호 조건 · 저장 결과 보고.
- [REMOVE] `AddActivityView`의 줄 빌더 함수 5개와 기억값 `@State` 9개(공유 타입으로 이동).

- **REQ-007 (Ubiquitous)**: The leg rows — the two leg toggles, the outbound origin, mode, and arrival buffer, the return destination and mode, and the notification toggle and lead — shall be built and shown-or-removed by one shared, SwiftUI-free row grammar with the same labels, options, order, and membership rules as the creation card, and both the creation card and the activity edit card shall use it; the creation card shall keep no private copy, and the row keys shall live in one table so that another card's vocabulary can map to it without a second builder. 근거: 계약 5. 지금 문법은 `AddActivityView`의 뷰 로컬이다(빌더 5개 `:330-376`, `fields.insert/remove` 11자리 `:190`~`:325`, 기억값 `@State` 9개 `:37-53`). 활동 카드에 옮겨 적으면 같은 규칙이 두 곳이 된다. `EditCard.swift`는 SwiftUI를 가져오지 않고(`:1`·`:7-8`) 드라이버 컴파일 집합에 든다 — 그래서 문법이 거기 살면 멤버십을 명령으로 검증할 수 있다. 키 어휘를 한 표로 두는 것은 t30(§1.4)이 사상만 하게 하려는 것이다. 결정 D-2.

- **REQ-008 (Event-driven)**: When the user turns a leg toggle on and saves, exactly one leg of that role shall be created, linked to the activity, with its time derived; when the user turns a leg toggle off and saves, only that leg shall be deleted; when the saved card differs from its seed in no leg row, no leg record shall change and no calendar upload or removal shall be triggered; and where calendar sync is enabled for the activity, a created leg shall be queued for upload and a deleted leg's calendar item shall be removed. 근거: 오는 편을 나중에 붙일 길이 없다 — 생성기가 `addActivityWithTravel` 하나라 활동까지 만든다(`Store.swift:189-230`). `addEvent`가 이미 `linkedActivityId`·`anchor: .departure`를 받으므로(`:572-583`, 대입 `:591`) 얇은 진입점이면 된다(결정 D-4). 변경 없는 저장이 구간을 건드리면 `updateEvent`가 구글 항목을 지웠다 다시 올린다(`:985-991`) — 무변경 저장은 레코드가 바이트 동일해야 한다. 추가는 `addEvent`가 큐에 올리고(`:606-608`) 삭제는 `deleteEvent`가 캘린더 항목을 지운다(`:1279-1281`) — 이 경로를 그대로 쓴다.

- **REQ-009 (Unwanted · Event-driven)**: The app shall never create a second leg of a role the activity already has, never create a leg for an activity without a place, and never leave a leg linked to an activity that was deleted while the leg was being created; when a requested leg operation is refused for one of these reasons, the card's result shall say which. 근거: 같은 역할이 둘이면 `linkedLegs`와 `realignReturnLeg`는 `.first`만 쓴다(`Store.swift:1122-1123`·`:334`) — 뒤엣것은 움직이지도 재정렬되지도 않는다. 활동 존재 재확인이 없고(`:214`·`:222`) 위치 없는 활동은 구간이 없다(`:211`). 같은 장소 50 m 가드는 `isSamePlace`가 `AIAssistant` 안 private static이라(`:2917`) 폼에서 닿지 않는다 — 이 카드는 생성 카드와 같게 두고(그쪽에도 없다, `grep -c "isSamePlace" Shared/AddActivityView.swift` → 0) 다음 카드로 미룬다(결정 D-4).

- **REQ-010 (Event-driven)**: When a leg operation of the activity edit card fails, or finishes with the leg's travel time not computed, the card's result shall report that, and the app shall not count that leg as made. 근거: 지금 `addActivityWithTravel`의 반환 `made`는 시도한 수다(`Store.swift:219`·`:227`) — 이동시간 계산에 성공한 수가 아니다. 생성 카드는 반환을 버리고 곧바로 닫는다(`AddActivityView.swift:523-542`). 계산 실패의 모양은 **역할마다 다르다.** 가는 편(도착 기준, `applyEstimate`)은 `departureDate`를 nil로 비우고(`Store.swift:1000`, 실패로 빠지는 guard `:1006`) 시간표가 경고 블록으로 그린다(`ContentView.swift:511`·`:627`). 오는 편(출발 기준, `applyDepartureAnchoredEstimate`)은 출발 시각을 추정 **앞에서** 대입하므로(`Store.swift:1025`, guard `:1031`) `departureDate`가 남고 `travelSeconds`만 nil이다 — 기준 트리의 시간표는 이것을 16분짜리 일반 이동 블록으로 그린다(`ContentView.swift:511`·`:558`·`:580`). 그 표시는 REQ-023이 고친다. 어느 쪽이든 사용자는 저장 순간에 모르므로, 결과의 "이동시간 알려짐" 판정은 역할과 무관하게 `travelSeconds`로 한다. 이 요구사항은 **카드의 저장 순간**만 다룬다 — 앱이 활성화될 때의 재추정 실패(REQ-023 근거의 (다))는 카드 조작이 아니라 결과를 보고할 자리가 없고, 그 구간의 신호는 시간표의 경고 블록(REQ-023)뿐이다(범위 밖 §3 마지막 절).

- **REQ-011 (State-driven)**: While the activity being edited has no explicitly linked legs and belongs to a recurrence, the activity edit card shall show no leg rows and shall keep its notice that the edit applies to this occurrence only. 근거: 반복 경로가 만든 구간에는 `linkedActivityId`가 없다 — 대입은 `addEvent` 한 곳(`Store.swift:591`)이고 넘기는 호출은 `addActivityWithTravel`의 두 자리(`:217`·`:225`)뿐이다. 반복 생성 함수 `addRecurringEvents`(`:628-695`, 닫는 괄호 `:695` · 다음 함수 `recurringSeries`는 `:698`)에는 `linkedActivityId`가 한 번도 나오지 않는다(`grep -n linkedActivityId Shared/Store.swift | awk -F: '$1>=628 && $1<=695' | wc -l` → 0). 추정(`linkedLegs`, `:1126-1130`)은 같은 반복·같은 날·장소 이름 대조라 도착이 다음 날인 오는 편을 놓치고(`:1128`) 이름이 같은 두 장소를 가르지 못한다(`:1129-1130`). 결정 D-8 (b)는 이 추정을 **배치 묶음에만** 쓴다(REQ-015) — 추정이 틀려도 블록 폭만 달라지고 레코드는 그대로다. 구간 줄로 추정 구간을 고치게 하면 틀린 추정이 엉뚱한 레코드를 고친다. 그래서 반복 회차의 카드에는 여전히 구간 줄이 없고, 삭제 연쇄도 추정을 쓰지 않는다(REQ-012).

### [DELTA] C 삭제 연계

- [EXISTING] 낱개 활동 삭제의 연쇄(`Store.swift:371-384`) · 구간 삭제는 그것만(`:1273-1282`) — 특성화만 한다.
- [MODIFY] 일괄 활동 삭제(`:1303-1313`) · `EventDetailView`의 같은 제목 모으기(`:331-333`) · 활동 삭제 확인 문구(`ActivityDetailView.swift:102`).
- [NEW] 명시적 구간 개수 조회.
- [REMOVE] 연결된 구간을 쓸어 가는 같은 제목 삭제 경로.

- **REQ-012 (Event-driven)**: When an activity is deleted — one at a time or as a batch — every leg explicitly linked to it shall be deleted with it, with its notification cancelled and its calendar item removed, and no leg linked to another activity and no unlinked event shall be deleted. 근거: 낱개 `deleteActivity`는 이미 연쇄하고(`Store.swift:371-384`) 일괄 `deleteActivities`는 하지 않는다(`:1303-1313`) — AI 삭제 경로(`AIAssistant.swift:2909`)에서 구간이 매달린 채 남는다(REQ-006의 원천). 운영자 규칙 "활동 삭제 시 연계된 이동일정도 함께". 반복이 만든 추정 구간은 이 연쇄에 넣지 않는다 — 결정 D-8 (b)는 추정을 배치 묶음에만 쓰고, 단독 회차 삭제로 넓히는 일은 `deleteActivity`의 옛 주석(`Store.swift:368-370`, 반복 구간은 반복 전체 삭제로 처리)과 부딪치는 별도 결정이다(`plan.md` §6). 결정 D-5.

- **REQ-013 (Event-driven · Unwanted)**: When the user deletes a leg linked to an activity from its detail screen, only that leg shall be deleted, and the same-title delete choice shall not include any leg linked to an activity. 근거: `deleteEvent`는 그 이벤트만 지운다(`Store.swift:1273-1282`) — 운영자 규칙 "이동일정 삭제는 그것만". 그러나 "같은 제목 일정 모두 삭제"는 제목 문자열 동등(`EventDetailView.swift:331-333`)으로 모아 `deleteEvent`를 루프하므로(`:373`) 연결된 가는 편(활동과 같은 제목, `Store.swift:214`)이 다른 활동의 구간까지 쓸어 갈 수 있다. 결정 D-5.

- **REQ-014 (Event-driven)**: When the user opens the delete confirmation of an activity that has N ≥ 1 explicitly linked legs, the confirmation text shall state N; when N is 0 the text shall be unchanged. 근거: 확인 창은 "이 활동을 삭제할까요?"뿐이라(`ActivityDetailView.swift:102`) 딸린 이동이 함께 사라진다는 것을 알리지 않는다. 문안은 제안이다 — `이 활동과 딸린 이동 N건을 삭제할까요?`(`plan.md` §2 D-5). 결정 D-5.

### [DELTA] D 겹침 크기 연동

- [EXISTING] 열 배치 알고리즘의 비그룹 동작(`ContentView.swift:699-742`) — 추출 전에 결과를 기록해 특성화한다. `span(for:on:)`은 기하의 단일 출처로 그대로 둔다.
- [MODIFY] `positionedBlocks` · `columnFrame` · `block(atX:y:in:)`.
- [NEW] 묶음을 아는 배치 순수 함수와 하나의 칸 함수(컴파일되는 파일에) · 배치 묶음 조회(`Store` — 명시적 연결, 그리고 명시적 연결이 없는 반복 회차에는 기존 추정. 결정 D-8 (b)).
- [REMOVE] `ContentView`의 열 산술 두 벌.

- **REQ-015 (State-driven)**: While any block of an activity group overlaps another block on the displayed day, the timetable shall draw every member of the group inside the same lane, so that the group narrows and widens together; an activity group is an activity together with the legs explicitly linked to it, or, for an activity of a recurrence that has no explicitly linked leg, the legs that the existing recurrence inference (same recurrence, same day, same place name) attributes to it; the lane is the group's outer column range, and members may subdivide it per REQ-017. 근거: 배치가 `linkedActivityId`를 읽지 않는다(`ContentView.swift`에서 `:651` 한 곳 — 제목 숨김뿐). 구간 끝 = 활동 시작이라 무리 끊기 `<=`(`:730`)가 서로 다른 무리로 나누고, 셋째 블록이 활동에만 겹치면 활동만 2열이 된다 — 운영자 ②의 결함이다. 거울 사례(셋째 블록이 구간에만 겹침)가 나머지 반쪽이다(타임라인 렌즈 §2, 값은 `design.md` §6). 운영자는 이 증상이 반복 회차에서도 났다고 답했다(결정 D-8 (b)). 반복 회차의 구간에는 명시적 연결이 없으므로(REQ-011 근거) 활동을 옮길 때 이미 쓰는 추정(`linkedLegs`, `Store.swift:1118-1131` — `moveActivity`가 `:1075`에서 부른다)을 **배치 묶음을 정하는 데만** 재사용한다. 같은 추정을 쓰므로 "활동과 함께 움직이는 구간"과 "활동과 함께 줄어드는 구간"이 같은 집합이다(계약 5). 알려진 약점: 도착이 다음 날인 오는 편은 추정에서 빠져(`:1128`) 낱개로 배치되고, 이름이 같은 두 장소는 섞일 수 있다(`:1129-1130`) — 틀려도 폭만 달라진다(잔여 위험, AC-015 (11)). "lane"을 바깥 칸으로 정의한 것은 묶음 안 겹침을 안쪽 배치로 나누는 REQ-017(실례 E3b·E6)과 문장이 부딪치지 않게 하려는 것이다. 결정 D-7.

- **REQ-016 (Ubiquitous)**: The group packing shall be one pure function in a source file the guard driver compiles, taking the spans that `span(for:on:)` already computed and returning each block's lane and lane count; the timetable view shall contain no second implementation of the packing or of the lane arithmetic; and the drawn frame and the hit test shall take their horizontal ranges from the same function. 근거: 계약 5. 드라이버 컴파일 집합에 `ContentView.swift`가 없어 지금 배치는 기계 검증이 불가능하다(타임라인 렌즈 §6). 열 산술이 두 곳이다 — 렌더는 3 pt 간격을 넣고(`ContentView.swift:745-750`) 히트테스트는 정규화된 칸만 본다(`:764-768`); 폭이 균일하지 않게 되면 기존의 3 pt 미만 어긋남이 커진다(F9). 기하 `span(for:on:)`(`:542`·`:557`)은 뷰에 남는다 — 최소 높이·자정 자르기가 뷰의 상수를 쓴다. 결정 D-7.

- **REQ-017 (Ubiquitous · Unwanted)**: Members of one group that overlap each other on the displayed day — an activity inflated to its minimum height, a leg with no travel time drawn as a warning block, a leg the user dragged into its own activity — shall be drawn side by side inside the group's lane and shall never be drawn on top of one another; a gap between members is a legal state and the group is formed by the link or by the inference of REQ-015, not by adjacency; and for a day without any group the result shall equal the current algorithm's result. 근거: F10 — 최소 높이 20·16분(`ContentView.swift:533-534`)이 짧은 활동과 그 오는 편을 겹치게 하고, 계산 실패 블록은 도착 시각 아래로 자라 가는 편이 활동 시작 위로 겹친다(`:557-563`). 묶음 전체를 한 칸으로 채우기만 하면 이 겹침이 한 칸 안에서 서로를 덮는다(`design.md` §6 안 A의 안쪽 배치). 구간을 끌면 활동과 틈이 벌어지는 것은 기존 의도다(`Store.swift:1088-1114`) — 결정 D-6 (a). 그룹 없는 날의 회귀선이 없으면 이 카드가 모든 날의 배치를 조용히 바꾼다.

- **REQ-018 (Ubiquitous · Unwanted)**: The change shall not alter the drag semantics — dragging an activity moves its legs, dragging a linked return leg shifts the whole leg, dragging a linked outbound leg adjusts its buffer with its arrival fixed — nor the tap result of any block of a day without a group, and `span(for:on:)` shall remain the single source of block geometry. 근거: 구간 드래그 의미는 문서화된 의도다(`Store.swift:1088-1090`, `:1091-1114`; 드래그 호출 `ContentView.swift:780-791`). 히트테스트는 렌더와 같은 `placed`를 읽는다(`:464`·`:478`) — 칸 함수를 바꾸면 iOS의 탭·길게 누르기가 함께 바뀌므로 사람 검증이 필요하다(AC-024). 결정 D-6 (a).

### [DELTA] E 기록·검증

- [EXISTING] 드라이버 `357/357` · iOS 빌드 무경고 · CHECKLIST·루트 `plan.md`의 인용.
- [MODIFY] `Tools/GuardDriver.swift`(새 절) · CHECKLIST·루트 `plan.md`(행 갱신·인용 재사상).
- [NEW] 결함 재현 단언 · 구 형식 JSON 디코딩 단언 · 시뮬레이터 스크립트.
- [REMOVE] 없음.

- **REQ-019 (Ubiquitous · Unwanted)**: The change shall use only Theme tokens for colors and keep dark mode following the device; shall keep `EditCard.swift` free of SwiftUI; shall not add an AI class, a tool declaration, a parameter key, or change the Gemini wire format, and shall not touch secrets; shall keep `Store` the single hub with no new persistence layer or event bus; shall add no stored field except an Optional one and no case to `ScheduleAnchor`; shall add a source file only if decision D-2 (b) is adopted; shall give any new icon-only or spinner-collapsing control an explicit accessibility label; and, because development and verification are iOS-only, shall add no macOS-only code and shall not delete the existing macOS code or any `#if os` branch, while no gate of the change shall build or verify the macOS app. 근거: `CLAUDE.md` 계약 1~6. 비-Optional 필드는 기본값이 있어도 옛 파일을 통째로 디코딩 실패시키고 `load()`가 빈 배열로 돌아와 다음 저장이 덮는다(F11) — 일정 전체의 조용한 영구 손실이다. 접근성 패턴은 `AddActivityView.swift:596`("장소 검색")·`:508`(스피너로 접히는 "추가"). **플랫폼 절은 방침이다(0.1.3)**: 2026-09-30부터 iOS 전용으로 개발·검증하고, 맥 코드는 지우지 않고 보존하되 새 맥 전용 코드를 만들지 않으며 맥 빌드·검증을 하지 않는다(운영자 방침, 칸반 리드 경유 · 원문 `master`의 `CLAUDE.md:10-12`, 커밋 `00cd149` — `plan.md` §2 P-1). 시간표 배치는 공유 코드다 — `besir-macOS` 타깃도 `Shared`를 컴파일하고(`project.yml:89`·`:93`), `ContentView.swift`의 `#if os` 줄 넷 가운데 `:195`만 맥 분기(툴바 동기화 단추)이고 `:2`(UIKit 가져오기)·`:454`(탭·드래그를 받는 `RescheduleOverlay` 자리)·`:857`(그 정의 블록)은 iOS 분기다(`grep -n '#if os' Shared/ContentView.swift`). 지시문 밖에도 주석이 맥 전용으로 밝힌 코드가 있다 — 시간표 블록 뷰의 `.onTapGesture` 셋(`:618`·`:641`·`:674`, 주석 "iOS에서는 … 도달하지 않는다(무해한 죽은 코드). macOS에서는 이 탭이 그대로 쓰인다" `:616-617`·`:672-673`, "macOS에서만 필요하지만" `:625`). iOS에서는 죽은 코드로 보여도 맥 앱의 탭이라 지우지 않는 대상이다(review-3 D24 — AC-019 (6) 갭 줄). 그래도 검증은 iOS에서만 한다. 여기서 "보존"은 **지우지 않는다**는 뜻이지 시험으로 지킨다는 뜻이 아니다 — 맥 쪽 동작을 판정하는 AC는 없고, AC-019 (6)은 분기 줄이 그대로인지만 본다. 맥 빌드가 없어 생기는 잔여 위험은 §3 "맥 앱의 빌드와 검증" 절에 받아들인 갭으로 적었다.

- **REQ-020 (Ubiquitous)**: Every behavior of modules A through D and F that a command can observe shall be covered by a guard-driver assertion; each defect the change repairs — a cleared place that stays, an invalid end that re-aligns the legs, a bulk delete that does not cascade, and a leg linked to a missing activity — shall first be shown by an assertion run on the unmodified code, its observed ✓/✗ line recorded in `progress.md` §E.2, before the code is changed; the record shapes that a failed travel estimate leaves on a leg shall be shown as follows, because the gate run of the driver assumes online estimation (its premise assertions S and J): the shape a failed re-estimate leaves shall be shown on the unmodified code through the no-origin exit of the same estimate function, which reaches the same record state without the network; the shapes a failed estimate leaves on a leg newly created through `addEvent` (shapes (가)·(나)) shall be recorded as a reach record — the observed line together with the premise it needs, taken from a separately named offline run — and shall not be required of the gate run; and the predicate and the layout that repair these shapes shall be shown on records constructed in memory, deterministic in any environment; and the current packing result shall be recorded by assertions on the behavior-preserving extraction commit (C1) before the packing is changed. 근거: 결함 주장은 도구가 확인하기 전까지 가설이다(`verification-claim-integrity.md` §1.1 표면 3). 렌즈의 결함은 전부 코드 읽기다. 재현 없이 고치면 고친 것이 결함이었는지 알 길이 없고, 재현 단언은 수리 뒤 회귀선으로 남는다. 배치는 드라이버가 `ContentView.swift`를 컴파일하지 않아 기준 트리에서 잴 수 없다 — 그래서 동작을 바꾸지 않는 추출(C1)이 첫 커밋이고 그 커밋에서 결과를 기록한다(REQ-016). **실패 모양을 따로 다루는 이유(review-2 D15)**: 게이트를 통과하는 드라이버 실행은 온라인 추정을 전제로 단언한다 — `✓ S 전제 — 이 환경에서 이동시간 조회가 된다`(`Tools/GuardDriver.swift:991`, 기준 로그 `driver-run.log:150`)와 `✓ J: 등록이 성공하고 이동시간도 계산됐다(전제 …)`(`:1369`, 로그 `:211`). 그래서 ✗ 0인 실행에서는 추정이 성공해 실패 분기에 닿지 않고, 닿게 하려고 오프라인으로 돌리면 전제가 ✗가 된다 — 한 실행에서 둘을 얻을 수 없다. 대신 셋으로 나눈다. ① 재추정 실패 모양은 네트워크 없이 닿는다: 추정 함수는 저장 필드를 먼저 대입한 뒤 **출발지 없음**(`Store.swift:1001`·`:1026`)과 **추정 실패**(`:1006`·`:1031`)의 두 guard 중 하나에서 빠지는데, 두 guard 사이에는 레코드를 바꾸는 줄이 없다(`sed -n 1020,1036p` — 사이는 추정 호출뿐). 출발지가 nil인 레코드는 실제 데이터 모양이고(`Models.swift:157-158` "옛 일정은 nil일 수 있음"), 드라이버가 그런 레코드를 `store.events`에 직접 넣고 `refreshUpcomingEstimates`를 부르면 같은 상태가 결정적으로 남는다(AC-010 (10) — 두 guard가 같은 상태를 남긴다는 것은 코드 읽기이고 단언은 `:1026` 쪽을 탄다). ② `addEvent`로 새로 만든 구간의 실패 모양 (가)·(나)(`addEvent`는 출발지를 비-Optional로 받는다, `:573`)는 추정이 실패할 때만 닿으므로 도달 기록으로 남긴다(AC-010 (4) — 게이트 실행에서는 "도달: 아니오"가 기대값이다). **갭(review-3 D21)**: 반복 뒤 회차 (라)도 새로 만든 구간의 실패 모양이지만 드라이버에는 결정적 경로가 없고 그 레코드를 보는 단언도 없다 — `addRecurringEvents`의 출발지도 비-Optional이라(`:629`) 출발지 guard로 닿지 않고, 첫 회차 추정(`:673`)이 실패해야만 캐시가 nil이 되어 뒤 회차가 추정 없이 저장된다(`:674`·`:676-677`). 이름 붙인 오프라인 실행에서는 기존 반복 절(예: `Tools/GuardDriver.swift:2567`의 `return_time` 있는 반복 — 오는 편은 `AIAssistant.swift:2217-2218`의 `.departure`)이 (라)를 부수적으로 남길 수 있다고 읽히지만(코드 읽기, 실행하지 않음) 이 절은 그것의 도달 기록을 요구하지 않는다. 그래서 (라)는 메모리에서 만든 레코드로만 보인다(AC-010 (7)(11)(12)(13)). ③ REQ-023의 판정·나열·배치는 메모리에서 만든 네 모양으로 보인다(AC-010 (5)–(8)·(11)–(13), AC-017 (4)·(9)). 그려진 모습은 사람이 본다(스크립트 20·20b). 앞의 네 결함 목록은 AC-020 (5)와 같은 한 벌이다. 제목·장소가 구간에 미치지 않는 것(REQ-003)은 새 능력이라 목록에 없다.

- **REQ-021 (Event-driven)**: When a delivery card moves lines of `Shared/` or `Tools/` that `CHECKLIST.md` or root `plan.md` cite, that card's sync shall re-map every such citation by atomic token replacement with a ledger and a positive control, and shall update the CHECKLIST rows for the day timetable (K5·K8·K9), edit (D) and delete (E) flows and the root `plan.md` card table to what the change made true. 근거: 코드를 옮기면 문서 인용이 깨진다 — t1이 CHECKLIST 인용 179건을 어긋냈고 t15는 파일명 계수 18이 실제 87이었다(공용 메모리). 이 카드가 움직일 파일의 인용 하한(파일명이 붙은 토큰만 센 값이라 실제는 더 많다): CHECKLIST에서 Store 39·ContentView 5·Models 6·AddEventView 6·EditCard 3·AddActivityView 2·ActivityDetailView 1·EventDetailView 1·GuardDriver 1, 루트 `plan.md`에서 Store 4·AddActivityView 9·AddEventView 6·EditCard 3·ActivityDetailView 2·Models 1(`grep -o "<파일>\(\.swift\)\{0,1\}:[0-9]\{1,4\}" <문서> \| wc -l`). 특히 Store는 중간에 줄이 들어가면 39건이 밀린다.

- **REQ-022 (Unwanted)**: The change shall be delivered as delivery cards each of which creates or heavily changes at most four files and touches no path outside the declared set of its card, both measured against that card's own base commit, and shall leave `Shared/AIAssistant.swift`, `Shared/GoogleCalendarService.swift`, and `proxy/` unchanged unless `plan.md` §2 records a decision gate as flipped. 근거: `CLAUDE.md`의 "한 Day에 새로 만들거나 크게 고치는 파일은 3~4개" — 예측 7 > 4(§0). 카드는 직렬로 배달되므로 뒤 카드를 고정 기준 `b2c3987`과 비교하면 앞 카드의 변경이 딸려 와 한도를 구조적으로 넘는다(review-1 D2) — 카드 범위는 그 카드의 기준 커밋과 재고, 누적 불변식(AC-019)만 `b2c3987`과 잰다. "크게 고침"은 `git diff --numstat` 추가+삭제 100줄 이상으로 센다(제안, 리드 확정). **선언 집합은 그 카드의 소스 파일과 그 카드 sync의 문서(`CHECKLIST.md` · 루트 `plan.md`)이고, SPEC 디렉터리(`.moai/specs/SPEC-UIKIT-009/` — 카드가 반드시 고치는 `progress.md` §E.2 포함)와 보고서(`.moai/reports/`) 경로는 범위 측정에서 뺀다. 크게 고친 파일 수는 `Shared`·`Tools`만 센다**(review-3 D20 — 증거 파일이 선언 밖으로 잡히거나 문서 크기가 한도를 정하지 않게. 전례 SPEC-UIKIT-008 `acceptance.md:271`이 자기 SPEC 경로를 같은 방식으로 뺐다). 프록시·`AIAssistant`는 이 카드의 원인이 아니다 — 새 소스 파일이 없으면 `xcodegen generate`도 서명 계정 재선택도 없다(결정 D-2 (a)).

### [DELTA] F 이동시간을 계산하지 못한 구간의 표시 (review-1 D3 (b) · review-2 D14)

- [EXISTING] 도착 기준 구간의 실패는 `departureDate`가 nil이라 도착일에만 나열되고 도착 시각에서 아래로 경고 블록으로 그려진다(`ContentView.swift:89-90`·`:511`·`:558-561`·`:627-642`) — 결과는 한 치도 바뀌지 않는다.
- [MODIFY] 시간표의 날짜 나열(`ContentView.swift:87-95`) · 달력 점(`Store.swift:132-150`) · 블록 선택(`ContentView.swift:511`) · 기하의 실패 분기(`span(for:on:)`, `:558-561`).
- [NEW] 레코드의 "이동시간 미계산 · 실패 블록 앵커 시각" 함수 하나와, 그것을 써서 나열 구간을 정하는 날짜 판정(`Models.swift`의 계산 속성 — 저장 필드가 아니다). 나열과 달력 점이 둘 다 이것을 읽는다(review-3 D23).
- [REMOVE] 나열과 점에 따로 복사된 판정 `guard let dep = e.departureDate, e.arrivalDate > dep`(`ContentView.swift:89` · `Store.swift:136`의 같은 조건).

- **REQ-023 (State-driven)**: While a travel leg's travel time has not been computed — for an arrival-anchored or a departure-anchored leg, whether the estimate failed when the leg was created or edited or when the upcoming leg was re-estimated — the timetable shall draw that leg as exactly one failed-estimate warning block, placed at the leg's failed-block anchor instant (for a departure-anchored leg its stored departure, or its arrival when no departure is stored; for any other leg its arrival) and listed only on the day that contains that instant; the day listing of the timetable, the calendar dots, the choice of block, and the block's geometry, and therefore its hit-test range, shall read one shared function on the leg record; a leg whose travel time has been computed shall be listed and drawn as before; and the stored meaning of `departureDate` and `arrivalDate` shall not change. 근거: 이동시간이 계산되지 않은 구간(`travelSeconds == nil`)의 레코드 모양은 **넷**이다(`sed -n 994,1036p` · `sed -n 656,678p` · `sed -n 1245,1271p Shared/Store.swift`). (가) **도착 기준**(`anchor`가 `.arrival` 또는 nil): `applyEstimate`는 `travelSeconds`와 `departureDate`를 먼저 비우고(`:999`·`:1000`) 출발지 없음(`:1001`)이나 추정 실패(`:1006`)에서 빠진다 — 생성·수정·반복 첫 회차·재추정·구글 가져오기(`:600`·`:975`·`:664`·`:1261`·`:1400`)가 모두 이 모양이고 `arrivalDate`는 목표 도착 그대로다. (나) **출발 기준, 새로 만들거나 고칠 때**: `applyDepartureAnchoredEstimate`는 `travelSeconds`를 비우고 출발을 먼저 대입한 뒤(`:1024`·`:1025`) 같은 두 guard(`:1026`·`:1031`)에서 빠진다. `addEvent`·`updateEvent`는 출발 시각을 `arrivalDate`로도 넘기므로(`:587`·`:601`, `:962`·`:976`) `departureDate == arrivalDate`다. 반복 첫 회차(`:673`)도 같다. (다) **출발 기준, 재추정 실패**: `refreshUpcomingEstimates`(앱이 활성화될 때 `App.swift:101`, 백그라운드 작업 `:25`)는 출발이 두 시간 안인 구간을 고르고(`Store.swift:1251-1254`) 출발 기준 구간에 같은 함수를 저장된 출발로 부른다(`:1263-1264`). 실패하면 도착 대입(`:1033`)이 guard 뒤라 `arrivalDate`가 **옛 값**(출발 + 옛 이동시간)으로 남는다. 반복 묶음 수정(`:757-759`)도 같은 모양을 남긴다. 반복 통근 구간은 캐시 추정으로 만들어졌다가 이 경로로 다시 계산되므로(`:648-650` 주석) 흔히 닿는다. (라) **출발 기준, 반복의 뒤 회차**: 첫 회차가 실패하면 캐시가 nil이라(`:674`) 뒤 회차는 추정 없이(`:676`의 `else if let`이 성립하지 않음) 생성자 모양 그대로 저장된다 — `departureDate` nil, `arrivalDate`는 그 회차의 출발 시각(`:656-658`). 기준 트리의 시간표는 `departureDate` 유무로 고른다: (가)(라)는 도착일에만 나열되고(`ContentView.swift:89-90`) `arrivalDate`의 분에서 아래로 21.4분짜리 경고 블록이다(`:511`·`:558-561`, 높이 20 pt `:536` ÷ `hourHeight` 56 pt `:37`). (나)는 출발 = 도착이라 그날에만 나열되고 16분 일반 블록이다(`:571`·`:580`). (다)는 `[출발, 옛 도착]`이 걸치는 모든 날에 나열되고(`:92`) 날마다 잘린 일반 블록이다(`:567-571`) — 어느 쪽에도 경고가 없다. **판정만 `travelSeconds`로 바꾸면 (다)에서 회귀가 생긴다(review-2 D14)**: 실패 분기는 `arrivalDate`의 분에서 그리고 날짜로 자르지 않으므로(`:558-561`, 주석 "실패 블록은 도착일에만 나열되므로") 옛 도착 자리에 경고가 떨어지고, 나열은 그대로 `[출발, 옛 도착]`을 보므로 자정을 넘는 (다)는 출발일 화면 맨 위(옛 도착의 분)에 경고 블록이 하나 더 생긴다 — 기준 트리에 없던 그림이다. 그래서 이 요구사항은 **앵커 시각 하나**를 정한다. 앵커는 추정과 무관한 쪽이다 — 출발 기준은 추정 앞에 대입된 출발(`:1025`, 없으면 (라)처럼 `arrivalDate`가 그 회차의 출발이다), 도착 기준은 도착. (가)(라)는 앵커가 `arrivalDate`라 나열·자리·모양이 오늘과 같고, (나)는 나열과 시작 분이 같고 모양만 경고로 바뀌며, (다)만 나열이 출발일 하루로 줄고 자리가 출발 시각으로 온다(값의 실례는 `design.md` §4). 달력 점(`Store.swift:132-150`)은 나열 판정의 사본(`:136`)을 따로 갖는데, 점과 일간 나열이 같은 날에 대해 다른 말을 하지 않는다는 기존 계약(`Store.swift:32-37`·`ContentView.swift:82-86` 주석)이 (다)에서 깨지지 않게 같은 함수를 읽는다 — 앵커가 있으면 A의 날 하나, 없으면 공유 함수가 돌려주는 나열 구간 `[출발, 도착]`을 기존 `dayKeys`에 넘기므로 `:136`의 인라인 사본은 계산된 구간 쪽까지 통째로 없어진다(review-3 D23 — 사본을 계산된 구간에 남기면 같은 나열 규칙이 `Models.swift`와 `Store.swift` 두 곳에 산다). 역할(가는 편 · 오는 편 · 활동 없는 단독 이동)과 무관하게 레코드 모양으로만 정한다 — 단독 이동도 같은 네 모양을 갖는다. **저장 의미를 바꾸지 않는 이유**: 실패 때 `departureDate`를 nil로 비우면 `refreshUpcomingEstimates`가 재추정 대상을 `departureDate`로 고르고(`:1252`) 그 값을 출발로 다시 쓰므로(`:1264`) 실패한 오는 편이 다시는 계산되지 않는다. 옛 도착을 지우는 것도 같은 이유로 하지 않는다(그 값은 이동 상세·충돌 검사·구글 업로드가 읽는다 — 범위 밖 §3 마지막 절). 판정을 바꾸는 쪽이 저장을 바꾸는 쪽보다 좁다 — `AIAssistant.swift:1846`도 이미 이 경우의 성공을 `travelSeconds != nil`로 판정한다(선례). 판정이 나열(`:89`)·점(`:136`)·블록 선택(`:511`)·기하(`:558`)에 따로 있으면 렌더와 히트테스트, 점과 나열이 어긋난다 — `span(for:on:)`이 단일 출처가 된 이유다(계약 5). 새 함수는 계산 속성이라 REQ-019의 저장 필드 규칙에 걸리지 않는다. 운영자 선택(review-1 D3 (b), `plan.md` §2 D-14). 0.1.2의 앵커·나열 규칙은 그 선택이 만드는 회귀를 막는 설계 규칙이라 운영자에게 새로 묻지 않았다 — 리드가 확인할 몫이다.

## 3. 범위 밖

### Out of Scope — AI 경로의 구간 결합

- AI `update_schedule`이 연결된 구간의 `anchor`를 뒤집는 것(`new_arrival_iso`), 둘 이상 맞으면 거절하는 것, 삭제가 제목으로 맞추는 것, `AIAssistant.swift:2038`의 "저장소의 마지막 N개 연결 구간" 추정은 이 카드가 고치지 않는다(카드 t30·t18·t20 몫). 그래서 **운영자의 "분리" 증상은 UI 경로에서만 닫힌다** — AI가 구간 시간을 직접 고치면 결합이 여전히 끊길 수 있다.
- AI 일정 목록의 실패 표지(`AIAssistant.swift:2644`, `departureDate == nil`일 때만 " ⚠️이동시간 계산 실패")는 REQ-023과 같은 이유로 실패한 오는 편을 놓친다. REQ-023은 시간표만 고치므로 AI 목록에서는 그 구간이 여전히 표지 없이 나온다(같은 카드들의 몫).
- 이유: `AIAssistant.swift`는 3174줄(`wc -l`)이고 AI 툴 계약(계약 1·4)이 걸려 있다. 이 카드는 앱 쪽 편집 경로와 배치에 한정한다.

### Out of Scope — 구글 캘린더 왕복과 재업로드 공백

- 구글 캘린더 왕복이 `linkedActivityId`·`anchor`를 싣지 않는 것(`GoogleCalendarService.swift:169-225`)은 이 카드 밖이다 — 다른 기기에서 가져온 구간은 연결이 없다.
- `moveActivity`·`shiftEvent`·`adjustBuffer`가 캘린더를 다시 올리지 않는 기존 공백(F12)도 이 카드 밖이다(결정 D-10 (a)). 활동 저장이 구간을 옮긴 뒤 구글 사본이 옛 시각으로 남는 것은 이 카드 이전부터의 동작이다. 새 구간 추가·수정·삭제는 기존 `addEvent`·`updateEvent`·`deleteEvent` 경로를 그대로 타므로 캘린더가 갱신된다(REQ-008).

### Out of Scope — 반복이 만든 구간(명시적 연결 없음)

- 반복 경로가 만든 통근 구간은 명시적 연결이 없다. 이 카드는 그 구간을 기존 추정으로 **배치 묶음에만** 넣는다(결정 D-8 (b), REQ-015). 구간 줄(REQ-011)과 삭제 연쇄(REQ-012)의 대상은 아니다 — 반복 회차 활동의 카드에는 구간 줄이 없고, 회차 하나를 지워도 추정 구간은 남는다(기존 동작, `Store.swift:368-370`).
- 추정을 단독 회차 삭제 연쇄로 넓히는 일은 별도 결정이다(`plan.md` §6).
- 추정의 약점은 고치지 않는다: 도착이 다음 날인 오는 편을 놓치고(`Store.swift:1128`) 이름이 같은 두 장소를 섞을 수 있다(`:1129-1130`). 그 구간은 오늘의 배치(낱개)로 돌아갈 뿐 데이터는 건드리지 않는다. 명시적 연결을 데이터 이전으로 채워 넣는 일(D-8 (c))도 하지 않는다.

### Out of Scope — 충돌 검사의 짝 제외

- `Store.conflicts`에 "연결된 짝 제외" 입력을 더하지 않는다(결정 D-9 (b)). 이 카드 뒤 연결된 구간을 단독 폼으로 고치는 UI 경로가 없어 그 입력의 호출자가 없다 — 쓰이지 않는 어포던스를 더하지 않는다(루트 `plan.md:105`, t5 판단).

### Out of Scope — AI 카드 문법 통일(t30)과 동일 계산의 다른 복제

- AI 채팅 카드를 공유 줄 문법으로 옮기는 일은 t30의 몫이다. 이 카드는 줄 키 어휘를 한 표로 두는 데까지만 한다(REQ-007).
- 같은 장소 50 m 가드(`isSamePlace`)를 폼과 공유하는 일, 세 편집 화면의 복사된 장소 검색 도우미(`AddActivityView`·`ActivityDetailView`·`AddEventView`)를 하나로 합치는 일은 이 카드 밖이다(`plan.md` §6).

### Out of Scope — 맥 앱의 빌드와 검증 (iOS 전용 방침, 2026-09-30)

- 이 카드의 run·sync는 맥 앱(`besir-macOS`)을 빌드하지도 실행하지도 않고, 맥 쪽 동작을 어떤 AC로도 판정하지 않는다. 새 맥 전용 코드는 만들지 않고, 기존 맥 코드와 `#if os` 분기는 지우지 않는다(REQ-019) — 지우지 않을 뿐 동작을 보장하지는 않는다.
- **받아들인 갭(잔여 위험)**: 맥 타깃도 `Shared/`를 컴파일하므로(`project.yml:89`·`:93`) 이 카드가 `Shared/`에서 바꾼 코드가 맥 타깃의 컴파일이나 동작을 깨도 어떤 게이트도 그것을 잡지 않는다. 운영자가 이 갭을 받아들였다 — "맥 앱은 iOS 앱 완성 후 한 번에 제작한다"(칸반 리드 경유, `plan.md` §2 P-1). 이 카드는 그 갭을 메우는 작업을 하지 않는다. 맥 타깃의 빌드 복구와 검증은 맥 앱을 만들 때의 몫이다(`plan.md` §6).

### Out of Scope — 저장 경로의 기존 결함

- `updateEvent`가 `await` 전 스냅샷을 되쓰는 것과 저장하지 않은 채 구글 id를 메모리에서만 비우는 것(`Store.swift:979-988`), `addActivityWithTravel`의 다중 `await`가 만드는 고아 가능성 중 이 카드의 새 진입점이 막는 몫(REQ-009) 밖의 것, `updateActivity`의 바깥 호출 0(호출자는 `modifyActivity` 하나, `grep -rn "updateActivity(" Shared`) — 죽은 코드 후보는 지우기 전에 확인이 필요하다 — 은 후속으로 기록한다(`plan.md` §6).
- 재추정에 실패한 출발 기준 구간(REQ-023 근거 (다))의 **옛 도착 시각**은 레코드에 남는다(저장 의미 불변). REQ-023은 시간표의 나열·점·블록에서만 그 값을 쓰지 않는다 — 이동 상세 화면, 충돌 검사(`Store.swift:529`), AI 일정 목록(`AIAssistant.swift:2622`·`:2644`), 구글 업로드(`GoogleCalendarService.swift:172-196`)는 그 값을 계속 읽는다. 재추정 실패를 저장 순간에 알리는 결과 보고도 없다(REQ-010은 카드 조작만 다룬다).
- 도착 기준 실패 구간(근거 (가))과 반복 뒤 회차(근거 (라))는 `departureDate`가 nil이라 `refreshUpcomingEstimates`의 대상에서 빠진다(`Store.swift:1252`) — 다가와도 다시 계산되지 않는 기존 동작이다. 이 카드는 그 복구 경로를 더하지 않는다(`plan.md` §6).

## 4. 결정

결정 D-1~D-13은 2026-09-30 운영자가 칸반 리드를 거쳐 답해 모두 해소됐다(이 세션은 운영자의 답을 직접 보지 않았다). 기록은 `plan.md` §2에만 둔다(이 프로젝트 관례). 권장안과 다른 답은 D-8 하나로 (b)가 채택됐고, review-1 D3에서 운영자가 고른 (b)는 권장안이 없던 **새 결정 기록 D-14**로 적었다. 0.1.2는 D-14를 이동시간 미계산의 모든 모양에 적용했다(REQ-023) — 새 결정이 아니라 같은 선택이 회귀를 만들지 않게 한 설계 규칙이며, 리드가 확인한다. 0.1.3의 iOS 전용 개발·검증은 결정 게이트가 아니라 운영자 **방침**이다 — 선택지를 묻지 않았고 `plan.md` §2에 방침 P-1로 따로 적었다(REQ-019 플랫폼 절 · §3 "맥 앱의 빌드와 검증" 절). 이 문서의 REQ·AC는 확정된 답과 그 방침 기준이다.

## 5. 관련 문서

- 칸반 카드 **t17** 본문(`moai todo`) · 루트 `CHECKLIST.md`의 이월 목록 U-1(`:538-540`)
- 연구 입력: `.moai/reports/t17/plan-lens-data-store.md` · `plan-lens-ui-edit-surfaces.md` · `plan-lens-timeline-overlap.md` — 이 SPEC의 재측정·어긋난 자리는 `research.md`
- [SPEC-UIKIT-003](../SPEC-UIKIT-003/spec.md) — REQ-011이 구간을 "줄 소속"으로 흡수했다(문법이 `EditCard`에 없는 이유)
- [SPEC-UIKIT-004](../SPEC-UIKIT-004/spec.md) — `EventDetailView`의 삭제 분기(단일·반복·같은 제목)는 잃으면 안 되는 어포던스다
- [SPEC-UIKIT-007](../SPEC-UIKIT-007/spec.md) — 출발지 줄 편집 씨앗(`AddEventView.swift:188`) 유지
- [SPEC-UIKIT-008](../SPEC-UIKIT-008/spec.md) — AI 카드의 구간 키 어휘(t30의 이웃)

🗿 MoAI
