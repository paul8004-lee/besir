---
id: SPEC-UIKIT-007
title: "일정 편집이 저장된 출발지를 현재 위치로 조용히 바꾸는 결함 — `AddEventView` 출발지 줄의 편집 씨앗"
version: "0.1.2"
status: draft
created: "2026-09-23"
updated: "2026-09-23"
author: "manager-spec"
priority: P2
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "edit-seed, origin, prefill, add-event-view, silent-overwrite, single-source, follow-up-t6"
tier: S
related_specs: [SPEC-UIKIT-002, SPEC-UIKIT-005]
kanban_card: t7
---

# SPEC-UIKIT-007 — 일정 편집이 저장된 출발지를 현재 위치로 바꾸는 결함

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-23 | 최초 작성. 칸반 카드 t7 본문(`moai todo`로 확인)과 루트 `plan.md:533`(후속 17)을 GEARS로 정식화했다. **인용 줄번호는 전부 이 워크트리의 베이스 `73ceb43`(= `origin/master`)에서 명령을 돌려 얻었고, 세는 명령을 각 수치 옆에 적었다.** 오케스트레이터가 넘긴 실측 16건(F1~F16)을 다시 쟀다 — 어긋난 것은 F5·F6의 줄 범위 둘이고, 결론은 같다. 카드 본문의 "이번 Day 회귀 아님"은 사실이 아니다(§1.5). 시뮬레이터 스크립트는 넘겨받은 초안을 따르되 세 곳을 고쳤다 — 1번의 메뉴 이름(`이동 일정 추가`), 7번의 앱 재실행, 8번의 기대 문구(위치 캐시 때문, §3.2 8번 주석). 모두 `progress.md` §E.1에 근거와 함께 적었다. **커밋 전에 plan 감사 1회차(FAIL 0.79 — must-pass MP-1·MP-7) 지적을 반영했다**: REQ 번호를 001~008로 다시 매겼고(옛 번호 10·11·20·21 → 005~008), REQ-007의 run 범위에 이 SPEC 디렉터리를 넣었으며, 스크립트의 기대를 고른 후보의 이름(N₀)·프리필 칩의 두 형태·`약 Z분`(±2분)·(나) 재시도 상한으로 고치고, AC-003을 기계 신호로 바꿨다. MP-7(착수 게이트 표식 셋)은 리드의 게이트 몫이라 그대로 두었다(`progress.md` §F.1) |
| 0.1.1 | 2026-09-23 | **착수 승인 게이트 해소.** 운영자가 결정했고 리드가 전했다: D-1 (a) 한 줄 씨앗(`:166`에 `chosen: editing?.origin?.name`) · D-2 (a) 한 자리 두 빌드 · Tier S. O-1은 리드 판정으로 카드가 아니고 Day 닫기 이월 목록에 올랐다. plan 감사 2회차(FAIL 0.89, 남은 must-pass는 게이트 표식 MP-7 하나)의 optional N1~N5를 같은 편집에서 반영했다. **다시 쓴 요구사항**: REQ-005 — `Where — D-1` 조건을 걷고 무조건형(Unwanted)으로 · REQ-007 — 감사 보고서 예외를 규범 문장으로 올리고(N1), run에 루트 `plan.md`의 계획-실제 갱신을 허용(N2, `CLAUDE.md:23`) · REQ-008 — D-2 의존을 걷고 (a)의 순서를 명시. **다시 쓴 인수 기준**: AC-002 — D-1 (b) 대비 문구 삭제, 루트 `plan.md` 허용, 기준 커밋 조건(N3) · AC-005 — (가)의 통과 조건을 기록 값과 분리(N4). §0·§3.1 머리말·§3.2 P0(이 자리의 시뮬레이터 증거 전부에 적용되는 빌드 조건)·§4·O-1 절도 결정 사실로 고쳤다. REQ 8 · AC 8은 그대로이고, **코드와 인용 줄번호는 바뀌지 않았다**(`Shared/` 무변경). 다음은 plan 감사 3회차(마지막)다 |
| 0.1.2 | 2026-09-23 | **plan 감사 3회차(PASS 0.90) 뒤 R1·R2 반영 — 재감사 없음(감사 상한 도달), 문서만 고쳤고 코드는 무변경.** R1: `dd-a`에서 SPEC-UIKIT-005 AC-009의 출발지 확인 단계(5·8·11번, 10번의 이동 구간 출발지)는 편집 시트로밖에 볼 수 없고 그 시트가 이 카드의 결함을 지녀, §3.2 "함께 돌리기"를 순서로 다시 적었다 — `dd-a`에서는 그 단계를 판정하지 않고 편집 시트에서 저장하지 않는다(6번도 미룸), 파트 A 앞 초기화를 건너뛴다, `dd`를 덮어 설치한 뒤 미룬 단계를 "취소"로 판정하고 6번을 돈다, 그다음 초기화와 파트 B. 겹침 배너를 피하려고 1번의 도착 시각을 내일 오후 7:00으로 옮겼다(7번은 5:00 그대로). AC-005의 초기화 조건을 그 예외에 맞췄다. R2: REQ-007의 "이 카드 항목"을 후속 17 · §Phase 1.7 표의 t7 행 · run 중 새로 덧붙이는 후속 항목으로 정의하고 후속 14를 카드 밖으로 뺐으며, AC-002에 그 밖의 헝크는 FAIL이라고 적었다 |

## 0. 이 SPEC의 성격과 예산

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** `<base>`는 전부 `73ceb43`이다. 수리는 코드 한 줄과 주석 한 덩어리이지만 **동작이 바뀌는 수리**라서, 빌드 초록만으로는 닫지 않고 시뮬레이터 증거(수정 전·수정 후)를 붙인다.

**Tier: S.** run이 고치는 소스 파일은 `Shared/AddEventView.swift` 하나, 코드 한 줄(`:166`)과 주석 여섯 줄 이내(`:531-536`)다. `spec-workflow.md`(주 체크아웃 `.claude/rules/moai/workflow/`)의 Tier S 기준(< 300 LOC, < 5 files) 안에 든다. 새 타입·새 화면·새 저장 경로가 없다. 운영자가 착수 승인 게이트에서 Tier S를 확정했다(2026-09-23, 리드 전달, `plan.md` §2).

**REQ·AC 예산 — 둘 다 Tier S 상한(8)과 같다.** `grep -c '^- \*\*REQ-' spec.md` = **8**, `grep -c '^#### AC-' spec.md` = **8**. §2.1 4건(001~004) · §2.2 2건(005·006) · §2.3 2건(007·008).

**가드 드라이버는 이 카드에서 돌리지 않는다.** 이유 둘: 드라이버의 컴파일 집합(`CLAUDE.md:59-63`)에 `AddEventView.swift`가 없어 이 경로를 아예 지나지 않고, 디스패치가 실행을 금지했다(드라이버는 실제 앱 데이터에 쓴다 — 카드 t8).

## 1. 배경

### 1.1 결함 — 편집 씨앗이 읽히지 않는다 (실측)

```
$ awk 'NR>=165 && NR<=169' Shared/AddEventView.swift
165:            .init(key: "origin_query", kind: .place, label: "출발지", options: originOptions,
166:                  allowsCustom: true, busy: location.isLocating),
167:            .init(key: "destination_query", kind: .place, label: "목적지",
168:                  options: store.favorites.map { .init(label: $0.label, value: $0.label) },
169:                  allowsCustom: true, chosen: editing?.destination.name, startsOpen: fresh),
$ awk 'NR>=537 && NR<=539' Shared/AddEventView.swift
537:    private func confirmedPlace(_ key: String) -> Place? {
538:        field(key).flatMap { $0.chosen == nil ? nil : confirmedPlaces[$0.id] }
539:    }
```

목적지 줄은 `chosen:`을 받고 출발지 줄은 받지 않는다. 편집 씨앗은 두 줄 모두에 좌표를 심지만(`:174` 목적지, `:177-178` 출발지), `confirmedPlace(_:)`는 `chosen`이 nil인 줄의 좌표를 돌려주지 않는다. 그래서 **`:178`의 쓰기는 한 번도 읽히지 않는다.** 바로 위 주석(`:531-536`)은 "지금은 쓰기 자리들이 이름과 좌표를 늘 함께 적어 도달 불가"라고 적었는데, `:178`이 그 반례다 — 이름 없이 좌표만 적는다.

### 1.2 연쇄 — 편집 시트가 열리는 순간 (`bootstrap` `:142-152`)

1. `:149` `recomputeEstimates` — 가드 `:465-466`가 출발지 nil에 걸려 **열자마자는 이동시간을 계산하지 않는다.**
2. `:151` `prefillOrigin` — 가드 `:424` `confirmedPlace("origin_query") == nil`이 통과한다 → `:425` 위치 요청 → `:426-435` 최대 25 × 200ms(5초) 대기.
3. 위치가 오면 `:428` `confirmCurrentLocationAsOrigin` → 가드 `:441`(`chosen == nil`)도 통과 → `:447-448`이 **현재 위치 `Place`를 줄에 쓰고** `:449`가 `chosen`을 `hereMarker`로 세운다 → `:459`가 현재 위치 기준으로 다시 계산한다. 줄에는 "현재 위치" 칩이 선택돼 보이고, 그 순간 지명을 알면 `현재 위치(<지명>)`로 찍힌다(`:452-455`).
4. 위치 권한이 없으면 `LocationManager.swift:51-53`이 곧바로 돌아오고, 5초 뒤 출발지 줄은 빈 채 남는다. `EditCard.swift:240` `isReady`가 거짓이라 `AddEventView.swift:119`가 저장을 잠근다 — 사용자가 출발지를 다시 골라야 한다.

어느 가지든 **저장돼 있던 출발지는 복원되지 않는다.**

### 1.3 저장하면 번지는 것 (코드 읽기)

`save()`는 줄의 좌표를 읽어(`:573`) `store.updateEvent(… origin: origin …)`(`:595`)로 넘긴다. `Store.updateEvent`(`Store.swift:930-970`)는 출발지를 쓰고(`:944`), 이동시간을 다시 구하며(`:953`·`:954`) — `applyEstimate`가 기존 출발 알림을 끄고(`:975`) 새 출발 시각으로 다시 예약한다(`:992-993`) — 구글이 연결돼 있으면 옛 캘린더 항목을 지우고(`:965`) 다시 올릴 대기열에 넣는다(`:968`). **사용자가 고르지 않은 출발지 하나가 이동시간·출발 시각·알림 시각·캘린더 항목을 함께 바꾼다.**

### 1.4 결함은 이 화면에만 있다 (실측)

- `updateEvent(`의 호출부는 둘뿐이다(`grep -n 'updateEvent(' Shared/*.swift` → `AddEventView.swift:595` · `Store.swift:343`). 뒤의 것은 AI 편집 경로 `executeUpdateSchedule`(`AIAssistant.swift:2181`) → `modifyEvent`(`Store.swift:332-352`)이고, 출발지를 받지 않으면 `current.origin`을 그대로 쓴다(`:345`).
- `AddActivityView`에는 편집 모드가 없다(`grep -c 'editing' Shared/AddActivityView.swift` = **0**). `ActivityDetailView.swift:141-144`는 `chosen:`과 좌표를 함께 심는다 — 올바른 모양이다. `AIAssistant`의 `originField`(`:550-555`)는 도구 호출의 되묻기 카드이지 저장된 일정의 편집이 아니다.

### 1.5 언제 들어왔나 (git)

- 카드 전환 전 화면(`d3c9327`)은 출발지를 지켰다 — `.task`가 `loadEditingIfNeeded()`(`:73`)를 먼저 부르고 `prefillOrigin()`(`:74`)을 부르며, 앞의 것이 `originPlace = e.origin`(`:410`)을 넣고 뒤의 것이 `guard originPlace == nil`(`:425`)로 돌아온다.
- 결함은 **`1b98e14`(2026-09-20, 카드 t2 · SPEC-UIKIT-002 M4)에서 들어왔다.** 출발지 줄 `:148-149`에 `chosen:`이 없고, 씨앗 `:159` `confirmedPlaces[o.name] = o`는 `chosen` 이름으로 읽는 `:495-496`에 닿지 않는다(`git log -- Shared/AddEventView.swift`에서 `d3c9327` 바로 다음 커밋).
- t6(`02481c6`)은 사전 열쇠를 줄 신원으로 바꾸며 결함을 그대로 옮겼고, `:531-536`의 주석을 새로 썼다.
- 따라서 카드 본문의 "c5396b3 이전부터 존재(이번 Day 회귀 아님)"는 앞부분만 참이다 — **Phase 1.7 안의 t2가 만든 회귀다.** 루트 `plan.md:533`의 "t6가 만든 것 아님"은 참이다.

### 1.6 무엇을 보고 판정하나

- 상세 화면에는 **출발지 이름이 나오지 않는다**(`grep -n 'origin?\.name\|origin\.name' Shared/*.swift` → `AIAssistant`·`Store`뿐). 상세가 보여주는 것은 `"<수단>로 약 N분"`(`EventDetailView.swift:190`)과 `출발 시각`(`:197`)이다. 그래서 대리 신호는 셋이다 — **편집 시트의 출발지 칩 글자, 이동시간, 출발 시각.**
- 수리 뒤 저장된 출발지는 목적지 줄처럼 **직접입력 칩**으로 보인다 — `chosenLabel`(`EditCard.swift:171-174`)은 옵션 값과 맞지 않으면 `customLabel`을 쓰고, `.place`는 값 그대로다(`:181`).
- **주 체크아웃으로 빌드하면 결함이 재현되지 않는다.** 로컬 `master`가 카드 전환 전 `291db49`이다(`git worktree list`). 수정 전 증거는 `73ceb43` 빌드에서만 나온다.

## 2. 요구사항 (GEARS)

### 2.1 편집 씨앗

- **REQ-001 (Event-driven)**: When the edit sheet builds its card for an event that has a saved origin, the origin row shall carry the saved origin's name as its `chosen` value, so that the first `confirmedPlace("origin_query")` read returns the saved `Place`. 수리 모양(참고): `:166`을 `allowsCustom: true, chosen: editing?.origin?.name, busy: location.isLocating),`로 바꾸는 한 줄이다. 인자 순서(`allowsCustom → chosen → busy`)는 같은 파일 `:231` 이동 수단 줄과 같다. 근거: 목적지 줄(`:169`)과 같은 모양이 되고, `:178`의 씨앗이 비로소 읽힌다(§1.1).

- **REQ-002 (State-driven)**: While the edit sheet is open for an event with a saved origin, the origin row shall change only through the user's explicit pick — a favorite chip, a search result, or a tap on the "현재 위치" chip — and the prefill path shall not overwrite it, including when location permission is denied. 근거: 권한이 없어도 저장된 출발지가 줄에 남아 저장 버튼이 켜진다(지금은 빈 줄에 회색 저장, §1.2의 4). "현재 위치" 칩을 직접 탭하는 경로(`:302-303` → `:412-418`)는 사용자의 선택이므로 그대로 동작한다 — `choose`가 옛 좌표를 먼저 지우므로(`:276`) `:424`가 씨앗 좌표에 막히지 않는다.

- **REQ-003 (Event-driven)**: When the edit sheet opens for an event with a saved origin, the travel estimates shall be computed from the saved origin to the saved destination. 근거: `bootstrap`의 첫 계산(`:149`)이 가드 `:465-466`를 통과한다는 뜻이다. 지금은 첫 계산을 건너뛰고, 현재 위치로 덮인 뒤(`:459`)에야 이동시간이 나온다.

- **REQ-004 (Where)**: Where the sheet is constructed in create mode (no event to edit), or with an event whose saved origin is nil, the origin row shall keep today's prefill behavior. 근거: `editing`은 시트를 만들 때 정해지는 생성 인자다(생성 `ContentView.swift:151` `AddEventView()`, 편집 `EventDetailView.swift:79` `AddEventView(editing: event)`). 두 경우 모두 `editing?.origin?.name`이 nil이라 `chosen`이 지금처럼 비고, `:424`가 통과해 현재 위치를 최대 5초 기다린다. nil 출발지는 옛 일정(`Models.swift:157-158`)과 좌표 없이 복원된 캘린더 일정(`GoogleCalendarService.swift:181-185`)에서 생긴다. nil 출발지 편집은 시뮬레이터 UI로 만들 수 없어, AC-001 첫째 grep이 찍는 옵셔널 체이닝 식을 코드 읽기 판정의 근거로 삼는다(AC-007).

### 2.2 단일 출처와 주석

- **REQ-005 (Unwanted)**: The change shall not add a second "the origin is set" check — such as `editing?.origin != nil` — to `bootstrap`, `prefillOrigin`, or `confirmCurrentLocationAsOrigin`; the origin row's `chosen` shall remain the only such truth. 근거: 계약 5다. 게이트가 D-1 (a) 한 줄 씨앗을 확정해(2026-09-23) 조건절을 걷었다. 세 가드 — `:424`(`confirmedPlace`), `:433`(`await` 너머의 `chosen` 재확인), `:441`(`chosen`) — 가 지금 모두 같은 `chosen`을 읽는다. 둘째 진실을 넣으면 그것을 읽는 가드는 하나뿐이고 나머지 둘은 계속 `chosen`을 읽는다. 두 진실이 어긋나는 날 가드끼리 다른 답을 한다. `:433`의 재확인은 건드리지 않는다.

- **REQ-006 (Ubiquitous)**: The comment above `confirmedPlace(_:)` shall assert nothing false about the tree, and shall name the origin-row consequence of a half-write. 근거: 지금의 `:531-536`은 "지금은 쓰기 자리들이 이름과 좌표를 늘 함께 적어 도달 불가"라고 단언하는데, 수정 전 트리에서는 `:178`이 반례다(§1.1). 수정 뒤에는 쓰기 자리 넷이 모두 이름과 좌표를 함께 적으므로(`:169`/`:174`, `:166`/`:178`, `:270`/`:276`, `:449`/`:447`) 그 단언은 조건을 붙여 남길 수 있다. 새 주석이 한국어로 적을 이유: 이 줄에서 nil 읽기는 "없는 장소"로 끝나지 않고 프리필(`:424`)을 여는 신호라서, fail-closed 읽기만으로는 저장된 출발지가 현재 위치로 조용히 바뀌었다는 것. 수리 모양(참고): 줄 수를 늘리지 않는 재서술(REQ-007).

### 2.3 범위와 증거

- **REQ-007 (Unwanted)**: The change shall not modify any repository path outside its declared files — in run, `Shared/AddEventView.swift`, this SPEC directory (`progress.md` §E.2·§E.3, `spec.md` frontmatter `status`·`updated`), and root `plan.md` limited to plan-versus-reality updates for this card's items; in sync, root `plan.md` and this SPEC directory — with plan-audit reports under `.moai/reports/plan-audit/` excepted as the auditor's output. 근거: 새 파일을 만들지 않으므로 `xcodegen generate`가 필요 없고, 서명 계정 리셋도 `besir-iOS`·`besirShare` Team 재선택 요청도 없다. run에 루트 `plan.md`를 여는 이유는 `CLAUDE.md:23`의 지시 — "계획이 실제와 달라지면 **그 자리에서 이 파일을 갱신**한다" — 이고, 범위는 이 카드 항목의 계획-실제 갱신이다. **이 카드 항목은 셋이다** — 후속 17, §Phase 1.7 표의 t7 행(지금은 없어 추가 대상 — `grep -c 't7' plan.md` = 0), 그리고 run 중에 새로 발견해 뒤에 덧붙이는 후속 항목(선례: t6 run 커밋 `27d35a5`가 후속 14를 덧붙였다). 후속 14는 카드 밖이다 — run은 고치지 않고, sync가 줄 수가 바뀐 경우에만 그 `AddEventView` 인용을 옮긴다(AC-008). 후속 17을 닫는 일은 여전히 sync의 몫이다(AC-008). 감사 보고서 경로는 `.gitignore`에 없어 커밋하면 diff에 잡히므로 규범 문장에서 뺀다(AC-002). 이 경계가 무변경으로 두는 파일 가운데 이 카드와 닿는 것: `Store.swift`(O-1 포함, §3 Out of Scope) · `AIAssistant.swift` · `EditCard.swift` · `EditCardView.swift` · `AddActivityView.swift` · `ActivityDetailView.swift` · `Tools/GuardDriver.swift` · `CHECKLIST.md` · `CLAUDE.md` · `proxy/`. 수리 모양(참고): `AddEventView.swift`의 줄 수 **645**(`wc -l`)를 유지하는 편집 — 코드는 한 줄 안의 인자 추가, 주석은 같은 여섯 줄 안의 재서술이다. 줄 수가 바뀌면 sync가 루트 `plan.md` 후속 14·17의 `AddEventView` 인용을 본문 바이트 대조로 옮긴다(AC-008).

- **REQ-008 (Event-driven)**: When the card is about to leave run, `progress.md` shall carry Part A simulator evidence from a build whose `Shared/` and `project.yml` equal `73ceb43` and Part B evidence from the fix build, each identified by commit SHA and both gathered in one sitting after the fix is written, Part A first; when Part A lands in outcome (다), the fix commit shall be reverted, the card stopped, and the outcome reported to the lead. 근거: 게이트가 D-2 (a) 한 자리 두 빌드를 확정했다(2026-09-23). 파트 A 빌드는 `Shared/`를 고치기 전에 만들어 자리까지 보관한다(`plan.md` §1 M1). 파트 A 결과가 (다)(재현 안 됨)이면 이 SPEC의 전제가 틀린 것이다 — 수정이 먼저 쓰여 있으므로 되돌릴 커밋이 하나 생기고, 게이트는 그 비용을 알고 (a)를 골랐다.

## 3. 인수 기준과 범위 밖

§3.1은 Tier S의 인라인 인수 기준이고, §3.2는 AC-005~007이 함께 쓰는 시뮬레이터 스크립트다. 인접한 결함은 요구사항이 아니라 뒤따르는 `Out of Scope —` 절에 둔다.

### 3.1 인수 기준 (Tier S 인라인)

착수 승인 게이트가 D-1 (a) 한 줄 씨앗을 확정했다(2026-09-23, 운영자 결정·리드 전달). 아래 AC는 그 안을 기준으로 적었다.

#### AC-001 — 출발지 줄이 저장된 이름을 씨앗으로 받는다 (REQ-001)

**Given** run이 끝난 트리에서 **When** `grep -n 'chosen: editing?.origin?.name' Shared/AddEventView.swift`·`grep -n '\.init(key: "origin_query"' Shared/AddEventView.swift`·`grep -c 'chosen: editing?.destination.name' Shared/AddEventView.swift`를 돌리면 **Then** 첫째가 정확히 한 줄이고 그 줄번호가 둘째가 찍은 줄의 바로 다음이며, 셋째가 1이다. `73ceb43`에서는 첫째 0줄 · 둘째 `:165` · 셋째 1이다. 이 글자 그대로의 식을 요구하는 것은 확정된 D-1 (a)의 일부다 — `:169`의 `chosen: editing?.destination.name`과 같은 모양이기 때문이다. 같은 뜻의 다른 식을 쓰려면 게이트에서 D-1을 다시 정한다.

#### AC-002 — 둘째 진실이 없고 고친 자리가 둘뿐이다 (REQ-005·REQ-007)

**Given** run이 끝난 브랜치에서 **When** `git diff --name-only 73ceb43 HEAD -- . ':!.moai/reports/plan-audit'`·`git diff -U0 73ceb43 HEAD -- Shared/AddEventView.swift | grep '^@@'`·`grep -c 'editing?.origin' Shared/AddEventView.swift`·`git diff --name-only --diff-filter=A 73ceb43 HEAD -- Shared/`를 돌리면 **Then** 첫째가 `Shared/AddEventView.swift` 한 줄, `.moai/specs/SPEC-UIKIT-007/` 아래 경로, 그리고 run이 계획-실제 갱신을 했다면 루트 `plan.md`뿐이고(그 밖의 경로가 하나라도 있으면 FAIL. 루트 `plan.md`가 나오면 `git diff 73ceb43 HEAD -- plan.md`를 읽어 헝크마다 REQ-007의 이 카드 항목 셋 가운데 어디에 닿는지 `progress.md` §E.2에 적는다 — 셋 밖에 닿는 헝크가 하나라도 있으면 FAIL), 둘째의 헝크가 `-166`과 `:531-536` 안쪽뿐이라 `bootstrap`(`:142-152`)·`prefillOrigin`(`:423-436`)·`confirmCurrentLocationAsOrigin`(`:438-460`)에 닿는 헝크가 없고, 셋째가 1(`73ceb43`에서 0)이며, 넷째가 0줄이다. 줄 수가 바뀌었다면 세 함수 본문을 이름으로 잘라 `git show 73ceb43:Shared/AddEventView.swift`의 같은 본문과 `cmp`해 무출력임을 보인다. 기준 `73ceb43`이 네 명령 모두에서 성립하는 것은 이 카드가 다른 브랜치를 병합하지 않기 때문이다. 카드 브랜치에 병합이 들어오면 `git merge-base origin/master HEAD`가 찍는 커밋을 기준으로 대조하고, 그 사실과 SHA를 `progress.md` §E.2에 적는다.

#### AC-003 — 주석이 거짓을 말하지 않는다 (REQ-006)

**Given** run이 끝난 트리에서 **When** `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift`의 출력을 `grep -c '프리필'`·`grep -c '도달 불가'`·`grep -c '편집 씨앗'`으로 세면 **Then** 첫째가 1 이상이고(`73ceb43`에서 0), 둘째가 0이거나 — 1 이상이면 셋째도 1 이상이다. 단언을 남기려면 수정 뒤에 참이 되는 조건(편집 씨앗도 이름과 좌표를 함께 심는다는 것)을 같은 주석에 적어야 한다는 뜻이다. `73ceb43`에서는 둘째 1(`:535`)·셋째 0이라 이 기준에 떨어진다. **기록 항목(통과 기준 아님)**: `code-safety` 렌즈가 그 주석이 (1) 출발지 줄의 nil 읽기가 프리필을 연다는 것 (2) fail-closed만으로는 저장된 출발지가 조용히 바뀌었다는 것을 이유로 적는지 읽고, 판정과 근거를 `progress.md` §E.2에 적는다.

#### AC-004 — 빌드 게이트가 전체 컴파일로 통과한다 (REQ-007)

**Given** run이 끝난 트리에서 **When** (a) `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t7/dd build > .moai/state/verify/t7/ios.log 2>&1` (b) 같은 경로로 `-scheme besir-macOS` → `macos.log` (c) `git diff --quiet 73ceb43 HEAD -- proxy/`를 돌리면 **Then** (a)(b) 둘 다 exit 0 · `BUILD SUCCEEDED`이고, `grep -c '^SwiftCompile' <log>`가 0보다 크며 `grep '^SwiftCompile' <log> | grep -c 'AddEventView.swift'`가 1 이상이고, `grep 'warning:' <log> | grep -c '\.swift'`가 둘 다 **0**이다 (c) exit 0 — 프록시를 건드리지 않았으므로 `npm test`는 선택이며, 돌렸는지 여부를 기록한다. DerivedData를 새 경로(`.moai/state/`, `git check-ignore` → `.gitignore:28`)에 두는 이유: 증분 `build/`는 `SwiftCompile` 0단계로도 `BUILD SUCCEEDED`가 나와 "경고 0"을 거짓으로 만든다(SPEC-UIKIT-006 `progress.md` §E.4.2). **가드 드라이버는 돌리지 않는다** — 금지이고, 이 경로에 닿지도 않는다(§0).

#### AC-005 — 파트 A: 수정 전 빌드에서 결함이 재현된다 (REQ-008)

**Given** `git diff --quiet 73ceb43 -- Shared/ project.yml`이 exit 0인 트리의 빌드를 iPhone 17 Pro 시뮬레이터에 설치하고 §3.2의 P0~P4와 초기화(합쳐 돌 때는 건너뜀 — §3.2 "함께 돌리기")를 마친 상태에서 **When** §3.2의 1~5번을 돌리면 **Then** 3번이 (가) · (나) · (다) 중 하나로 분류되고, `progress.md` §E.2에 빌드 SHA · 위 `git diff --quiet`의 exit 0 · 분류 · 기록 값이 적혀 있다. **(가)의 통과 조건**: 4번에서 Y < X이고, 출발 시각이 D보다 늦다. (가)로 분류됐는데 이 조건이 깨지면 AC-005는 FAIL이고, 값과 함께 리드에게 보고한다. **(가)·(나) 공통 통과 조건**: 5번의 출발지 줄이 비고 저장이 회색이다. **기록 값**: (가)는 N₀·X·D·Y, (나)는 N₀·X·D와 "Y 없음(저장 회색)". (나)는 P1을 확인하고 **한 번만** 다시 돈다 — 다시 (나)면 그것을 결과로 받는다(저장된 출발지가 지켜지지 않았으므로 여전히 재현이다). (다)이면 멈추고 REQ-008대로 처리한다.

#### AC-006 — 파트 B: 수정 뒤 저장된 출발지가 남는다 (REQ-001·002·003·008)

**Given** 수정 커밋의 빌드를 같은 시뮬레이터에 설치하고 같은 사전 조건과 초기화를 마친 상태에서 **When** §3.2의 1~5번을 돌리면 **Then** 3번의 출발지 줄이 N₀ 칩이고 "현재 위치" 칩은 선택돼 있지 않으며 대중교통 소요시간이 X와 같고(±2분), 4번이 `약 X분`(±2분)·출발 시각 D(±2분)이고, 5번의 출발지 줄이 N₀이며 저장이 켜져 있다. `progress.md` §E.2에 빌드 SHA와 값(N₀·X·D)이 적혀 있다.

#### AC-007 — 파트 B 회귀: 프리필과 직접 고르기는 그대로다 (REQ-002·REQ-004)

**Given** AC-006에 이어 **When** §3.2의 6~8번을 돌리면 **Then** 6번 새 일정의 출발지가 6초 안에 `현재 위치` 또는 `현재 위치(…)` 칩으로 프리필되고(이 단계가 보는 회귀는 프리필이 일어난다는 것이지 칩 글자가 아니다), 7번의 저장된 "현재 위치" 출발지가 위치가 바뀐 뒤에도 저장 당시 이름의 칩으로 남아 `약 Z분`(±2분)이 유지되며, 8번에서 "현재 위치" 칩을 직접 탭하면 그 칩이 선택되고 소요시간이 Z보다 길게 다시 계산된다. **nil 출발지 편집(REQ-004 뒤 절반)은 시뮬레이터 UI로 만들 수 없어 코드 읽기로만 판정한다** — 근거는 AC-001 첫째 grep이 찍는 식 `chosen: editing?.origin?.name`이다. 옵셔널 체이닝이라 `origin`이 nil이면 `chosen`도 nil이 되어 `:424`가 지금처럼 통과한다. 이것은 관측이 아니다.

#### AC-008 — sync에서 문서가 최종 트리를 가리킨다 (REQ-007)

**Given** sync가 끝난 트리에서 **When** 루트 `plan.md` 후속 17과 14를 읽고 `wc -l Shared/AddEventView.swift`·`grep -o 'AddEventView[.swift]*:[0-9]' CHECKLIST.md | wc -l`·`git diff --quiet 73ceb43 -- CHECKLIST.md`를 돌리면 **Then** (1) 후속 17이 수정 커밋 SHA와 함께 닫혀 있고 결함이 들어온 커밋(`1b98e14`, t2)을 적었다 (2) 줄 수가 645가 아니면 후속 14·17의 `AddEventView` 인용(파일명 앵커와 맨 `:N` 모두)을 본문 바이트로 대조해 옮겼고 대조·정정 건수를 명령과 함께 기록했다 — 단 후속 17의 `c5396b3` 좌표(`:158-159`·`:511-513`)와 `plan.md:73`의 2026-09-12 기록(`AddEventView.swift:279`)은 그날의 좌표라 옮기지 않는다 (3) `CHECKLIST.md`의 `AddEventView` 줄번호 인용이 0건 그대로이고 파일이 무변경이다(exit 0). 수동 편집 행을 체크리스트에 더하는 일은 Day 닫기의 `ux-check`에 넘긴다.

### 3.2 시뮬레이터 스크립트 — AC-005·006·007 공통

**관측자: 사람.** 파트 A·B의 입력은 같고 기대만 다르다. 대리 신호는 §1.6의 셋이다.

**사전 조건(파트마다 한 번)**

- **P0. 빌드.** 파트 A = `Shared/`·`project.yml`이 `73ceb43`과 같은 트리(수정 전에 `dd-a`로 만들어 둔 빌드), 파트 B = run 레인의 수정 커밋(`dd`). run 레인이 빌드·설치하고 SHA를 `progress.md`에 적는다. **이 자리의 시뮬레이터 증거는 전부 — 파트 A·B, SPEC-UIKIT-003 AC-010, SPEC-UIKIT-005 AC-009 — `73ceb43` 이후 커밋의 워크트리에서 만든 빌드로 모은다.** 주 체크아웃(로컬 `master` `291db49`)의 빌드는 카드 전환 전 화면이라 셋 모두에서 가짜 음성이 된다(리드가 운영자에게 전한 안내, 2026-09-23).
- **P1.** 시뮬레이터 메뉴 Features → Location → Custom Location… → 위도 `37.5663`, 경도 `126.9779`(서울시청).
- **P2.** iOS 설정 → besir → 위치 → "앱을 사용하는 동안".
- **P3.** 일정을 만들 때 "구글 캘린더에도 등록" 줄이 보이면 "안 함"을 고른다. 편집 저장이 캘린더에 다시 올리기 때문이다(`Store.swift:961-968`, 올림 판정 `:804-816`). 이 줄은 구글 캘린더와 자동 등록이 켜져 있을 때만 보인다(`AddEventView.swift:246`).
- **P4.** 1번에서 대중교통 칩에 소요시간이 뜨지 않으면(경로 조회 실패) 그 파트는 처음부터 "자동차"로 돌리고 그 사실을 적는다. 아래의 "대중교통"은 그 경우 전부 "자동차"로 읽는다.
- **초기화.** 설정 → "일정 모두 삭제" — P1~P4 다음, 1번 직전. 단 AC-009와 한 자리에서 합쳐 돌 때 파트 A 앞의 초기화는 건너뛴다(아래 "함께 돌리기").

**단계**

1. "+" → **"이동 일정 추가"**(`ContentView.swift:228`). 제목 `T7 출발지 확인`. 출발지가 현재 위치(서울시청 근처 지명)로 프리필되면, 출발지 줄에서 `강남역`을 검색해 강남역(주소 강남구) 후보를 고르고, **고른 뒤 출발지 칩에 찍힌 이름을 N₀로 적는다**(검색 후보의 이름이 그대로 저장되므로 `강남역`과 다를 수 있다). 목적지 줄에서 `서울역`을 검색해 고른다. 시각 줄: "도착 기준" → 내일 오후 7:00 → "확인"(AC-009의 내일 3시 일정·AC-010의 내일 2~4시 활동과 겹치지 않게 — 겹치면 충돌 배너가 뜬다, `AddEventView.swift:56`). 이동 수단: 대중교통. 대중교통 칩의 소요시간을 **X분**으로 적는다.
2. "추가" → 시간표에서 그 일정을 탭 → 상세 카드의 `…로 약 N분`의 N(= X)과 "출발 시각"(**D**)을 적는다.
3. 상세 오른쪽 위 "편집" → 시트가 열리면 **6초** 기다린다(프리필 대기 최대 5초, `AddEventView.swift:426`).
   - 파트 A 기대(결함): 출발지 줄이 `현재 위치` 또는 `현재 위치(…)` 칩으로 선택돼 있다 — N₀가 아니다(지명은 그 순간 역지오코딩이 끝나 있을 때만 붙는다, `:452`). 대중교통 소요시간이 X보다 짧다(시청 → 서울역).
   - 파트 B 기대(수리): 출발지 줄이 N₀ 칩이다. "현재 위치" 칩은 선택돼 있지 않다. 대중교통 소요시간 ≈ X.
   - 파트 A 결과 분류: **(가)** 현재 위치로 바뀜 → 재현 / **(나)** 출발지 줄이 비고 저장이 회색 → 5초 안에 위치를 못 얻은 가지(결함의 다른 모양). N₀·X·D와 "Y 없음(저장 회색)"을 적고, P1을 확인한 뒤 **한 번만** 다시 돈다. 다시 (나)면 그대로 결과로 적는다 / **(다)** N₀ 그대로 → 재현 안 됨: 멈추고 리드에게 보고(SPEC 전제가 틀렸다).
4. 아무것도 건드리지 않고 "저장" → 상세를 다시 본다.
   - 파트 A: `약 Y분`에서 Y < X이고, 출발 시각이 D보다 늦다 — 사용자가 고르지 않은 출발지로 저장됐다. (나)면 저장이 회색이라 이 단계는 건너뛴다.
   - 파트 B: `약 X분`(±2분), 출발 시각 D(±2분).
5. **권한 없는 가지.** iOS 설정 → besir → 위치 → "안 함"(앱이 종료될 수 있다). besir를 다시 실행 → 그 일정 → "편집" → 6초.
   - 파트 A: 출발지 줄이 비어 있고 저장 버튼이 회색이다.
   - 파트 B: 출발지 줄이 N₀이고 저장 버튼이 켜져 있다.
   - 끝나면 위치 권한을 "앱을 사용하는 동안"으로 되돌린다.
6. (파트 B만 — 회귀) "+" → "이동 일정 추가" → 출발지가 6초 안에 `현재 위치` 또는 `현재 위치(…)` 칩으로 프리필된다 → "닫기". 보는 것은 프리필이 일어난다는 것이다 — 5번 뒤라 역지오코딩이 아직 돌지 않았을 수 있어 칩 글자는 가리지 않는다.
7. (파트 B만) "+" → "이동 일정 추가" → 출발지 프리필 그대로, 목적지 `서울역`, 내일 오후 5:00 도착, 대중교통. "추가" 전에 출발지 칩 글자를 적는다(`현재 위치(…)`면 괄호 안 지명이, `현재 위치`뿐이면 `현재 위치`가 저장되는 이름이다 — `:447`). "추가"(소요시간 **Z분**). Custom Location을 `37.4979`, `127.0276`(강남역)으로 바꾼다. **앱 전환기에서 besir를 위로 밀어 종료하고 다시 실행한다.** → 그 일정 → "편집" → 6초. 기대: 출발지 줄이 그 저장된 이름의 칩이고 `현재 위치(…강남구…)`로 바뀌지 않는다. "저장" → `약 Z분`(±2분) 유지.
8. (파트 B만) 7번 일정 → "편집" → "현재 위치" 칩을 직접 탭 → 그 칩이 선택되고(글자는 `현재 위치` 또는 `현재 위치(…강남구…)`) 소요시간이 Z보다 길게 다시 계산된다 → "취소"(저장하지 않음). 끝나면 Custom Location을 P1 값으로 되돌린다.
   - **7번에서 앱을 다시 실행하는 이유**: `LocationManager`는 첫 측위 뒤 갱신을 멈추고(`LocationManager.swift:61`·`:132`), 칩 탭은 이미 가진 좌표가 있으면 그것을 곧장 쓴다(`AddEventView.swift:413-414`). 같은 프로세스에서 위치만 바꾸면 8번이 옛 시청 좌표를 써서, 이 카드와 무관한 캐시 동작이 실패처럼 보인다. 칩의 지명은 역지오코딩이 끝났을 때만 붙는다(`:452`).

**함께 돌리기(D-2 (a) 확정) — 순서가 AC-009의 증거를 지킨다.** SPEC-UIKIT-005 AC-009는 저장된 일정의 출발지를 보라고 한다(그 `acceptance.md:241-242` 5번 · `:254` 8번 · `:261` 10번의 이동 구간 출발지 · `:262-263` 11번). 그런데 상세 화면은 목적지만 그린다(`EventDetailView.swift:172-175`) — 출발지를 볼 곳은 편집 시트뿐이고, `dd-a`의 편집 시트는 이 카드의 결함대로 저장된 출발지를 현재 위치로 덮는다(§1.2). 거기서 저장하면 시험 데이터까지 망가진다. 그래서 한 자리를 이렇게 돈다.

1. `dd-a` 설치 → SPEC-UIKIT-003 AC-010 → SPEC-UIKIT-005 AC-009. **AC-009의 5·8·11번과 10번의 이동 구간 출발지는 여기서 판정하지 않는다.** AC-009 동안 편집 시트(`AddEventView`)에서는 **"저장"을 누르지 않는다.** 열어 보고 "취소"하는 것도 `dd-a`에서는 뜻이 없으니 건너뛴다. 편집 시트에서 저장해야 하는 6번(`:243`)도 미룬다 — 5번 일정의 출발지를 바꾸는 단계라, 5번을 판정하기 전에 돌면 판정할 것이 사라진다.
2. 파트 A 1~5번. **파트 A 앞의 초기화는 건너뛴다**(AC-009의 일정이 남아 있어야 한다). 파트 A의 일정은 제목 `T7 …`로 가린다.
3. `dd`를 `dd-a` 위에 설치한다(시뮬레이터는 앱 데이터를 남긴다). **먼저** 남은 일정에서 AC-009의 5·8·10(이동 구간 출발지)·11번을 판정한다 — 일정마다 편집 시트를 열어 출발지 줄을 보고 **"취소"**(저장하지 않음). 수리 뒤의 시트는 저장된 출발지를 보여준다. 이어서 6번을 돈다(사용자가 `집`을 직접 고르고 저장하는 단계라 수리 뒤에는 안전하다). 판정마다 어느 빌드(`dd-a`/`dd`)에서 나왔는지 AC-009 기록에 적는다.
4. 초기화(설정 → "일정 모두 삭제") → 파트 B 1~8번.

### 3.3 실기기 전용 — Day 닫기 이월 목록 (AC 아님)

- 편집 뒤 출발 알림이 **바뀌지 않은 시각**에 실제로 울린다(파트 B 4번 일정).
- 구글 캘린더에 연결된 기기에서 편집 저장 뒤 캘린더 항목이 같은 출발지·시각으로 남는다.
- macOS의 편집 시트 — 같은 SwiftUI 코드지만 관측하지 않았다.

### Out of Scope — `modifyEvent`의 nil 출발지 대체 (O-1, 코드 읽기 가설 — 미관측)

- `Store.swift:345` `origin: newOrigin ?? current.origin ?? current.destination` — 출발지가 nil인 일정(`Models.swift:158` `var origin: Place?`, `GoogleCalendarService.swift:181-185`)을 AI로 고치면 출발지가 목적지로 채워져 0분 이동이 될 수 있다. 같은 부류("사용자가 안 고른 값으로 저장")다.
- 이 카드는 `Store.swift`를 건드리지 않는다(REQ-007). **리드 판정(2026-09-23): 카드 아님, Day 닫기 이월 목록에 기록.**

### Out of Scope — 이름이 "현재 위치"인 저장된 출발지 (표시 모호성, 잔여 위험)

- 역지오코딩 전에 만든 일정은 출발지 이름이 `현재 위치`다(`AddEventView.swift:447`의 대체값, `LocationManager.swift:157`). 수리 뒤 이 일정을 편집하면 `현재 위치` 직접입력 칩이 실시간 "현재 위치" 옵션 칩 옆에 선택돼 보인다. **데이터는 맞고 표시만 헷갈린다.** 이 카드에서 고치지 않는다.
- 저장된 출발지 이름이 즐겨찾기 라벨과 우연히 같으면 그 즐겨찾기 칩이 선택된 것으로 보인다 — 목적지 줄이 이미 따르는 규칙과 같다.

### Out of Scope — 출발 기준 수동 일정

- 출발 기준으로 저장된 일정도 같은 `bootstrap`·`save()` 경로를 탄다(코드 읽기). 같은 수리가 덮으므로 따로 스크립트로 돌리지 않는다.

### Out of Scope — 가드 드라이버와 이웃 화면

- 드라이버는 돌리지도 고치지도 않는다(§0, 카드 t8). `AddActivityView`·`ActivityDetailView`·`AIAssistant`에는 같은 결함이 없다(§1.4) — 고칠 것이 없다.

## 4. 결정 — 해소 (착수 승인 게이트, 2026-09-23)

운영자가 결정했고 리드가 전했다: **D-1 (a)** 한 줄 씨앗 · **D-2 (a)** 한 자리 두 빌드 · **Tier S**. 세 건 모두 권고안이다. 그래서 REQ-005와 REQ-008의 조건절을 걷었다. O-1은 카드가 아니다(리드 판정, Day 닫기 이월 목록). 결정 기록과 채택하지 않은 안은 `plan.md` §2에 있다.

## 5. 관련 문서

- 칸반 카드 **t7** 본문(`moai todo`) · 루트 [`plan.md`](../../../plan.md) `:533`(후속 17 — 이 SPEC의 출처) · `:530`(후속 14 — 같은 화면의 인접 결함, 이 카드 밖)
- [SPEC-UIKIT-002](../SPEC-UIKIT-002/spec.md) — 결함이 들어온 카드(t2, `1b98e14`)
- [SPEC-UIKIT-005](../SPEC-UIKIT-005/spec.md) — 사전을 줄 신원으로 바꾼 카드(t6, `02481c6`). 그 sync `--deep` 렌즈가 이 결함을 찾았고, `acceptance.md` AC-009가 이 스크립트의 형식이다

🗿 MoAI
