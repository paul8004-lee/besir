---
id: SPEC-UIKIT-001
title: "일정·활동 편집 카드 컴포넌트 추출 (UI 통일 1/3)"
version: "0.2.1"
status: in-progress
created: "2026-09-18"
updated: "2026-09-18"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "ui-unification, shared-component, contract-5, ask-card, theme-tokens"
tier: M
related_specs: [SPEC-ASK-001, SPEC-ONTIME-001]
kanban_card: t1
---

# SPEC-UIKIT-001 — 일정·활동 편집 카드 컴포넌트 추출 (UI 통일 1/3)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-18 | 최초 작성 — 루트 `plan.md:411-417`("다음 Day — 일정·활동 화면 UI 통일", 2026-09-16 사용자 요청, 범위 확정 "활동까지 전부")을 GEARS로 정식화. 칸반 카드 t1이 그 Day를 세 장으로 쪼갠 첫 장이므로 본 SPEC의 범위는 **컴포넌트 추출 + AI 카드 전환**까지이며 네 화면은 건드리지 않는다(t2·t3 소관). 인용 줄번호는 작업 트리 `291db49` 실측 |
| 0.1.1 | 2026-09-18 | 인용 줄번호 **실측 재정렬 27건**. 0.1.0의 결합 지점 9곳(`:181`·`:238`·`:299`·`:344`·`:444`·`:495`·`:523`·`:534`·`:537`)과 `private static` 셋(`:1636`·`:1641`·`:1651`)은 `awk`로 대조해 정확했으나, 접근성·디자인 인용 다수가 어긋나 있었다 — 지역 상태 `:167-179`→`:164-171`, 체크 글리프 `:434-437`→`:372`, 접근성 `:271-275`→`:275`·`:277`, 흐린 여유 줄 `:262-268`→`:267`·`:273`, 힌트 `:554`→`:555`, 디바운스 주석 `:489-490`→`:487-488`, 거절 문구 `:254`→`:257`, 칩 높이 `:174-179`→`:176`·`:178`, `accepts` `:88-111`→`:89-106`, 결함 P `:391-396`→`:407-408`, 0건 문구 `:412-415`→`:430`, `arrange` `:604`→`:595`, 가로스크롤 주석 `:559-562`→`:561`. `PlaceField`의 계약 6 위반 줄(`:206`·`:213`·`:220`·`:245`)과 디바운스 부재 줄(`:259`→`:263`)을 새로 실측해 §1.1·AC-006에 명시. **원인**: 0.1.0 작성 시 일부 줄번호를 grep 실측이 아니라 읽은 출력에서 눈으로 어림했다 — run-phase가 없는 코드를 찾아다니게 만드는 종류의 오차다 |
| 0.2.0 | 2026-09-18 | **① REQ 예산 초과 시정(lead 증거 읽기 지적).** 0.1.x가 "REQ 16건 — Tier M 상한과 정확히 일치"로 적었으나 **실제 정의는 20건**이었다(001~004·010~013·020~026·030~032·040~041). "16"은 산출 근거가 없다 — SPEC-ASK-001의 문구를 형식째 옮기면서 숫자까지 가져왔고 제 REQ를 세지 않았다. `spec-workflow.md:149`의 Tier M 상한 16은 실재하는 기준이므로 **실제 초과**였다. tier up은 기각(t1은 4파일로 Tier L의 >15파일 기준에 크게 못 미친다), 추가 분할도 기각(뷰 추출은 원자적이라 중간 상태가 컴파일되지 않는다) — 원인은 범위가 아니라 **과형식화**이므로 §2.3(7→3)·§2.4(3→2)를 자연 단위로 합쳐 **16건**으로 맞췄다. 의무는 하나도 지우지 않고 절(clause)로 내렸으며, 절이 일괄 판정되지 않게 acceptance.md가 절 단위 대조를 유지한다. 산출 근거는 §0 "REQ 예산" 항에 명시. **② `ui-design` 설계안 반영**: D-1 = 클로저 묶음, D-2 = 파일명 확정, REQ-002를 "옮기거나 승격" 열린 형태에서 **정의 이동 + 위탁** 지정 형태로 확정(`when` 호출부 13곳 실측 — 그냥 옮기면 REQ-041과 부딪힌다), REQ-005 신설(별칭 2줄로 드라이버 20곳 무변경), REQ-021을 4건→9절로 보강, D-3 신설. 전문가가 "`when` 20여 곳"이라 한 것은 **실측 13곳**으로 정정해 실었다 |
| 0.2.1 | 2026-09-18 | **run-phase 계측 시정 2건**(M2 `f9cd9bb` 후 실측). **① AC-001 조건 5의 grep 기준("`Shared/` 합이 1")은 측정 오기였다** — `Shared/AIAssistant.swift`의 `parseDate`가 형식 후보 목록으로 리터럴 선행 발생분 1건을 이미 갖고 있어(fda161c에서 구 `isoFormatter`와 합쳐 **2건**) 순수 이동으로는 도달할 수 없는 숫자였다. 계측 형태로 시정: `EditCard.swift` 1건(`BesirTime` — 카드 왕복 형식의 소유자) + `AIAssistant.swift` 1건(`parseDate`, 무수정) = 합 2, **총수 2→2의 순수 이동**. `parseDate`를 건드리는 것이 오히려 REQ-041 위반이다. 같은 헐거움을 가진 AC-001 **조건 3의 대조 방법** 문장도 이 계측 형태에 맞췄다(lead 후속 지시). **② `when` 호출부 "13곳"은 실측과 안 맞는 오기다** — fda161c에서 `Self.when(` **12줄/20발생**, M2 후 동일(무수정). 0.2.0이 `ui-design` 전문가의 "20여 곳"을 "실측 13곳"으로 정정했다 했으나 발생 수 기준으로는 **전문가 쪽이 맞았다**. 결론(그냥 옮으면 호출부가 함께 바뀌므로 안 됨 — 정의 이동 + 위탁)은 변함없다. §2.1 표·본문과 plan.md §2의 수치를 같이 고쳤다. **③ M4 후 최종 문서 패스**(`bb09e01`, code-safety CONFIRMED 반영): AC-001 조건 4를 "드라이버 **본문**(단언·로직)은 무변경, 머리말 실행 명령 1줄은 REQ-004 갱신" 형태로 시정(M2가 머리말 주석을 합법 갱신해 "GuardDriver.swift 등장 = 별칭 누락" 판정이 거짓이 됐다), AC-006의 "4개 파일"에 예외 셋(GuardDriver 머리말 1줄·`project.pbxproj`·문서+`progress.md`)을 명시, plan.md §1에 M3·M4 🟢·M5 🟡와 D-3 해소(전부 t1 밖)를 반영, plan.md §4 후속 두 항목에 순수 값 뷰 재렌더 계약 — 소유자 화면이 `@Published` 상태를 바꿔야 화면이 갱신된다 — 을 t2·t3 완료 조건으로 추가, D-3 서술 두 곳을 해소 상태로 정합 |

## 0. 이 SPEC의 성격

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §6 "다음 Day — 일정·활동 화면 UI 통일"(`plan.md:411-417`)이고, 본 SPEC은 그것을 재발명하지 않는다. 인용 줄번호는 변경 전 현재 상태(`291db49`) 기준이므로 구현 중 밀릴 수 있다 — 그때마다 실측 재정렬한다(SPEC-ONTIME-001 HISTORY 0.2.3이 세운 관례).

**왜 세 장으로 쪼개졌는가.** 루트 `plan.md:412`는 네 화면 약 1,800줄을 한 Day의 범위로 적었지만, CLAUDE.md는 한 Day에 새로 만들거나 크게 고치는 파일을 **3~4개**로 제한한다. 네 화면 + 컴포넌트 + AI 카드는 6파일이므로 제한을 넘는다. 그래서 칸반 대기열이 t1(컴포넌트 추출 + AI 카드) · t2(일정 화면 2개) · t3(활동 화면 2개)로 나눴고, 본 SPEC은 t1에 대응한다. **t2·t3는 별도 SPEC**(`SPEC-UIKIT-002`·`SPEC-UIKIT-003`)으로 쓰며 본 SPEC의 REQ 번호를 재번호하지 않는다.

**REQ 예산 — 16건으로 상한과 같다.** `spec-workflow.md:149`가 정한 Tier M 요구사항 상한은 **16**이고, `:152`는 초과를 "tier up 또는 SPEC 분할 신호이며 예산을 느슨하게 하는 것이 아니다"로 못박는다. 본 SPEC의 REQ 정의는 **정확히 16건**이다 — §2.1 5건(001~005) · §2.2 4건(010~013) · §2.3 3건(020~022) · §2.4 2건(030~031) · §2.5 2건(040~041). 하나라도 늘면 분할 신호다.

§2.3과 §2.4의 REQ가 절(clause)을 품고 있는 것은 그 때문이 아니라 **그것이 자연스러운 단위이기 때문**이다. "추출된 컴포넌트가 접근성 계약을 그대로 보존한다"는 하나의 요구사항이고, 체크 글리프·낭독 결합·힌트·칩 높이는 그 요구사항을 확인하는 아홉 개의 절이다. 절을 각각 REQ로 올리면 번호는 늘지만 의무는 같고, 상한의 취지(`:152` — "plan-auditor가 모든 요구사항을 한눈에 들고 있어야 한다")에 오히려 반한다. **대신 절이 일괄 판정되지 않도록 acceptance.md가 절 단위로 대조한다** — REQ 하나를 통째로 "통과"로 적는 경로는 없다.

**왜 AI 카드를 먼저 전환하는가.** 추출한 컴포넌트를 아무도 쓰지 않으면 그것이 옳게 추출됐는지 알 방법이 없다. AI 카드는 추출 원본이므로, 그것이 컴포넌트를 쓰고도 **동작이 그대로**인 것이 추출의 정확성에 대한 유일한 기계적 증거다. 네 화면을 같은 카드에서 함께 옮기면 두 종류의 실패(추출이 틀렸다 / 전환이 틀렸다)가 한 덩어리로 도착해 어느 쪽인지 가를 수 없다.

## 1. 배경

같은 일(일정 만들기)을 하는 화면이 세 벌이다 — AI 되묻기 카드 한 장, 일정 화면 두 개, 활동 화면 두 개. 한 곳을 고치면 나머지가 어긋나는 구조이고, 이것은 CLAUDE.md 계약 5("같은 계산을 두 곳에 두지 않는다")가 이미 코드 계산에 대해 금지한 것과 같은 모양이다. 계약 5는 `ContentView.span(for:)`에서 렌더링과 히트테스트가 따로 계산하다 어긋난 사고를 겪고 세워졌다 — 본 SPEC은 그 원칙을 **화면**에 적용한다.

### 1.1 측정된 어긋남 (`291db49` 실측)

| 파일 | 줄 수 | `Theme.` 토큰 사용 |
|---|---|---|
| `Shared/AIChatView.swift` | 612 | **28** |
| `Shared/AddEventView.swift` | 550 | 6 |
| `Shared/EventDetailView.swift` | 377 | 6 |
| `Shared/AddActivityView.swift` | 267 | 4 |
| `Shared/ActivityDetailView.swift` | 222 | 2 |

CLAUDE.md 계약 6은 "색을 직접 쓰지 않는다 — 전부 `Theme` 토큰을 거친다"고 못박는다. 토큰 사용 수가 28 대 2~6으로 갈리는 것은 카드 쪽만 그 계약을 지키고 있다는 뜻이며, 실제로 `AddActivityView.PlaceField`(`Shared/AddActivityView.swift:187-267`)는 `.secondary`(`:206`·`:245`)·`.quaternary`(`:213`)·`.bordered`(`:220`)를 그대로 쓴다. 같은 `PlaceField`는 장소 검색도 다시 구현하는데 **디바운스가 없다** — `runSearch`(`:259`)가 `store.placeSearch.search`를 바로 부른다(`:263`). 카드 쪽은 같은 실패를 이미 겪고 디바운스를 어시스턴트에 두었고, 그 이유가 주석에 남아 있다: "뷰가 타이머를 들면 카드가 다시 그려질 때마다 흩어져 글자마다 호출이 나간다(카카오 일일 할당량)"(`Shared/AIChatView.swift:487-488`).

즉 카드 UI가 "나은 쪽"인 것은 취향이 아니라 **사고를 겪고 고친 이력이 쌓인 결과**다. 그래서 통일의 방향은 카드 → 화면이고, 카드가 단일 출처가 된다.

### 1.2 추출 대상 (`291db49` 실측)

| 심볼 | 위치 | 성격 |
|---|---|---|
| `AIAssistant.AskField` | `Shared/AIAssistant.swift:38-113` | 필드 모델 — `Kind`·`Option`·`Lookup`·`chosenLabel`·`customLabel`·`accepts` |
| `AIAssistant.PendingAsk` | `Shared/AIAssistant.swift:117-127` | 카드 한 장의 모델 — `parts`·`stated`·`fields`·`isReady` |
| `AskCardView` | `Shared/AIChatView.swift:158-557` | 카드 뷰 — 줄 렌더링·시각 줄·직접입력·장소 검색·확인 버튼 |
| `ChipFlow` | `Shared/AIChatView.swift:564-612` | 칩 줄바꿈 배치(`Layout` 구현) |

## 2. 요구사항 (GEARS)

> REQ 번호는 **§2.N 대역식**이다 — §2.1→001번대, §2.2→010번대, §2.3→020번대, §2.4→030번대, §2.5→040번대. 연속 번호가 아니며, 대역 사이의 빈 번호는 REQ 누락이 아니라 그 절에 추가 REQ가 붙을 자리다. acceptance.md·plan.md의 REQ 범위 표기가 이 대역에 의존하므로 재번호하지 않는다.

### 2.1 필드 모델 중립화 (001번대)

- **REQ-001 (Ubiquitous)**: The field model shall live outside `AIAssistant` — `AskField`(`:38-113`)와 `PendingAsk`(`:117-127`)가 중첩을 벗어나 `Shared/`의 독립 파일로 옮겨진다. 옮긴 뒤 이름은 AI 전용으로 읽히지 않아야 한다(네 화면이 같은 타입을 쓸 예정이므로).
- **REQ-002 (Ubiquitous)**: The moved field model shall reach the date interpretation through a single neutral owner, without touching non-card call sites. 근거(실측): `AskField`가 `AIAssistant`의 **`private static` 멤버 셋**에 기대고 있다 — `parseDatetime`(`:1651`), `when`(`:1636`), `isoFormatter`(`:1641`). Swift의 `private`는 파일이 아니라 **타입 선언 범위**이므로, 중첩을 벗어나는 순간 세 참조가 전부 끊긴다.

  **셋의 사용 분포가 다르다**(`291db49` 실측, 정의부 제외):

  | 멤버 | 호출부 | 분포 |
  |---|---|---|
  | `parseDatetime` | 5곳 — `:82`·`:109`(AskField 내부), `:934`·`:984`·`:991`(카드 해소 경로) | 카드 경로 전용 |
  | `isoFormatter` | 4곳 — `:110`(AskField 내부), `:926`·`:993`(카드 해소 경로), `:1653`(`parseDatetime` 내부) | 카드 경로 전용 |
  | `when` | **12줄(20발생)** | 카드 밖까지 — 등록 요약·겹침 안내·활동 요약 |

  따라서 `when`을 그냥 옮기면 **호출부 12줄(20발생)이 함께 바뀌고**, 그것은 순수 추출(REQ-041)과 부딪힌다. 지정 형태는 **정의 이동 + 위탁**이다: 세 멤버의 정의를 중립 소유자(예: 모델 파일의 `BesirTime`)로 옮기고, `AIAssistant`는 기존 시그니처를 위탁 한 줄로 남긴다 —

  ```swift
  private static func when(_ d: Date) -> String { BesirTime.when(d) }
  ```

  정의는 각각 한 곳, 호출부 변경은 카드 경로에 한정된다. **금지**: 새 파일에 `dateFormat`을 다시 적는 것. 그러면 카드의 `accepts`와 실행부 직렬화가 다른 형식을 쓰게 되고, 그것이 계약 5가 막으려는 정확한 모양이다(현재 `:920` 주석이 "출처(isoFormatter)가 accepts·직렬화와 같은 자리에 있어야 세 곳이 어긋나지 않는다"로 같은 말을 해두었다).

- **REQ-003 (Unwanted)**: The moved model file shall not import SwiftUI. 근거(실측): 가드 드라이버의 컴파일 집합(`Tools/GuardDriver.swift`·`Shared/AIAssistant.swift`·`Store`·`Models`·`Config`·`PlaceSearch`·`DirectionsService`·`LocationManager`·`NotificationManager`·`GoogleCalendarService`·`SharedInbox`)에는 `import SwiftUI`가 **한 건도 없다**. 드라이버는 SwiftUI 뷰를 컴파일 대상으로 삼지 않는다(SPEC-ASK-001 plan.md §2가 세운 경계) — 모델이 SwiftUI를 끌어오면 그 경계가 무너진다. 그래서 모델과 뷰는 **반드시 다른 파일**이다.
- **REQ-004 (Event-driven)**: When the field model moves to a new file, the guard-driver compile command shall name that file. 근거(실측): `Tools/GuardDriver.swift`가 `AskField`·`PendingAsk`를 **20곳**에서 참조한다(`drvAsk`가 `PendingAsk?`를 돌려주는 등). CLAUDE.md의 드라이버 명령은 `Shared/AIAssistant.swift`만 `cat`으로 합치고 나머지 9개 파일을 `swiftc` 인자로 넘기므로, 새 모델 파일을 그 인자 목록에 넣지 않으면 드라이버가 컴파일되지 않는다. **CLAUDE.md의 그 명령 블록을 함께 갱신한다.**
- **REQ-005 (Ubiquitous)**: The extraction shall leave `AIAssistant`'s body and the guard driver untouched by name. 이름 통일은 t3에서 한 번에 하고, t1에서는 `AIAssistant` 안에 별칭 두 줄(`typealias AskField = <새 필드 타입>` / `typealias PendingAsk = <새 카드 타입>`)을 둔다. 그러면 `AskField.Lookup`·`AskField.Option`·`AskField.customLabel`·`PendingAsk(parts:stated:fields:)`가 그대로 해석되어 **`AIAssistant` 본문과 드라이버 20곳을 한 줄도 고치지 않고** 추출이 끝난다. 두 이름이 공존하는 것은 그 자체로 가벼운 드리프트이므로 **t3에서 별칭을 지우고 이름을 통일한다**를 `SPEC-UIKIT-003`의 완료 조건에 넣는다 — 임시성을 문서에 박지 않으면 별칭이 영구화된다.

### 2.2 카드 뷰 추출 (010번대)

- **REQ-010 (Ubiquitous)**: The card view shall live in `Shared/` and be non-private — `AskCardView`(`Shared/AIChatView.swift:158-557`)·`ChipFlow`(`:564-612`)·그 안의 `chip(_:selected:dashed:action:)` 빌더가 새 뷰 파일로 옮겨진다. 현재 셋 다 `private`이므로 파일 밖에서 쓸 수 없다.
- **REQ-011 (Unwanted)**: The extracted view shall not name `AIAssistant` as a type. 근거(실측): 결합 지점은 정확히 **9곳**이다 — `isThinking`(`:181`, `:537`), `choose(field:value:)`(`:238`), `rechooseTimeBasis`(`:299`), `chooseTime`(`:344`), `choose(field:place:)`(`:444`), `searchPlaces`(`:495`), `submitCustom`(`:523`), `confirmAsk()`(`:534`). 아홉 지점 전부가 중립 표면을 거쳐야 하며, 남은 한 곳이 있으면 네 화면이 그 컴포넌트를 쓸 수 없다.
- **REQ-012 (Ubiquitous)**: `AIAssistant` shall remain the sole AI-side adapter of that neutral surface — 새 AI 클래스를 만들지 않는다(CLAUDE.md 계약 4). 어댑터는 기존 `AIAssistant`가 중립 표면을 만족시키는 형태이고, 별도의 카드 전용 컨트롤러·이벤트버스·영속화 레이어를 두지 않는다(계약 3).
- **REQ-013 (Ubiquitous)**: The extracted view shall keep its card-lifetime local state — `customOpen`·`draft`·`rejected`·`draftBasis`·`draftDate`(`:164-171`)가 컴포넌트 안에 남는다. 근거(주석 `:162-163`): 이 상태를 채팅 뷰로 올렸더니 "카드가 요약으로 바뀐 뒤에도 열린 입력창과 거절 표시가 남아 다음 카드로 흘러갔다". 호출자에게 상태를 넘기는 설계는 그 사고를 되돌린다.

### 2.3 보존해야 할 불변식 (020번대)

> 아래는 전부 **이미 사고를 겪고 세워진 것**이며, 순수 추출에서 조용히 사라지기 쉽다. 세 REQ는 각각 절(clause)로 열거되고, acceptance.md는 **절 단위로 하나씩 대조한다** — REQ 하나가 통째로 "통과"로 판정되는 일은 없다. 절을 REQ로 쪼개지 않은 이유는 §0의 REQ 예산 항에 적었다.

- **REQ-020 (Ubiquitous)**: The extracted component shall preserve the design contract:
  (a) 색은 `Theme` 토큰만 — 원시 색·`.secondary`·`.quaternary`·시스템 머티리얼을 쓰지 않는다(계약 6). 현재 카드가 쓰는 토큰 11종: `ink`·`muted`·`faint`·`line`·`bg`·`raised`·`travel`·`travelFill`·`travelInk`·`warn`·`radius`;
  (b) 선택 칩의 글자는 `Theme.bg`이고 `.white`가 아니다 — 다크 모드에서 갈린다;
  (c) 모서리는 `Theme.radius`이고 리터럴 수치가 아니다(칩의 `Capsule()`은 의도된 형태이므로 위반이 아니다);
  (d) `preferredColorScheme`을 강제하지 않는다 — 기기 설정을 따른다.

- **REQ-021 (Ubiquitous)**: The extracted component shall preserve the accessibility contract verbatim:
  (a) 선택 표시를 색에만 맡기지 않는다 — 체크 글리프 + `.semibold`(`:372`), 그리고 칩의 `.accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)`;
  (b) 칩은 줄 이름과 묶여 읽힌다 — `accessibilityElement(children: .contain)`(`:275`) + `accessibilityLabel(field.note.map { "\(label). \($0)" } ?? label)`(`:277`). 왜 떴는지가 화면에만 있고 음성에 없으면 안 된다;
  (c) 흐려진 여유 줄은 투명도(`:273`)만으로 상태를 말하지 않고 캡션(`:267`)을 함께 둔다;
  (d) 확인 버튼의 잠김 이유는 힌트로 읽힌다 — `accessibilityHint`(`:555`);
  (e) 후보 줄은 이름과 주소가 한 덩어리로 읽힌다(`:462`) — 따로 읽히면 같은 이름의 다른 지점을 가를 수 없다;
  (f) 칩 높이는 iOS `44`pt / macOS `28`pt, 양쪽 `@ScaledMetric(relativeTo: .callout)`(`:176`·`:178`). 고정하면 큰 글씨 설정에서 칩이 잘리고, iOS 44pt는 터치 최소치다;
  (g) 긴 문구를 숨기지 않는다 — `note` 캡션의 `.fixedSize(horizontal: false, vertical: true)`, 확정 시각 칩의 `.lineLimit(nil)` + `.fixedSize`;
  (h) 직접입력 칩은 점선 테두리로 성격 차이를 **형태로** 구분한다;
  (i) iOS 숫자 줄은 `.keyboardType(.numberPad)`과 확인 버튼을 함께 유지한다 — 숫자판에 완료 키가 없다.

- **REQ-022 (Ubiquitous)**: The extracted component shall preserve the behavioral contract:
  (a) 뷰는 검색 디바운스 타이머를 들지 않는다 — 묶음은 **호출자 책임**이다(주석 `:487-488`). 뷰가 타이머를 들면 재렌더마다 흩어져 글자마다 호출이 나가고, 그것이 곧 카카오 일일 할당량이다;
  (b) 값 수용 범위는 상수 참조로 남는다 — 여유 `0...Store.maxBufferMinutes`, 알림 `0...1440`, 반복 `1...Store.maxRecurrenceWeeks`, 이동수단 `TransportMode(rawValue:)` 유효, 시각은 접두 + 정규 ISO만(`:89-106`). 상한을 문구에 박지 않는다 — 거절 사유가 "그 값은 쓸 수 없어요"뿐인 이유가 "상한이 Store 상수라 문구에 박으면 두 곳이 된다"(`:257`)이다. 거절 시 입력창을 닫지 않는다 — 닫으면 무엇이 안 받아들여졌는지 사라진다;
  (c) 장소 줄에 자유 텍스트를 그대로 확정하는 버튼을 두지 않는다 — 후보를 탭해 좌표까지 확정한다(주석 `:407-408`, 2026-09-16 실기기 결함 P). 0건과 오프라인을 구분한 척하지 않고 양쪽을 함께 말하는 문구도 그대로 둔다(`:430`). 검색이 도는 동안에도 다른 줄은 조작 가능하다 — 카드를 막지 않는다;
  (d) 칩은 가로 스크롤 없이 줄바꿈으로 흐른다 — `ChipFlow`의 `arrange`가 크기 계산과 배치에 **같은 함수**로 쓰인다(`:595`). 근거(주석 `:561`): "화면 밖으로 밀린 칩은 고를 수 없는 값이고, 이 카드에서 못 고른 값은 그대로 조용한 기본값이 된다."

### 2.4 검증 (030번대)

- **REQ-030 (Ubiquitous)**: The guard driver shall stay fully green with no assertion added — `drvCheck(` 호출 지점 **200곳**(정의 1건 제외, `291db49` 실측). 총 단언 수는 반복 안의 호출 때문에 호출 지점 수보다 크므로 **run-phase 실행 출력으로 실측**한다(SPEC-ASK-001 HISTORY 0.2.1이 세운 관례 — 총수를 문서에 박지 않는다). 본 SPEC은 순수 추출이므로 통과 조건은 **기존 단언이 그대로 초록**인 것이며, 새 단언이 필요해졌다면 그것은 동작이 바뀐 신호이므로 REQ-041 위반으로 다룬다.

- **REQ-031 (Ubiquitous)**: The extraction shall pass the project gate on both platforms and on a real device:
  (a) iOS(`besir-iOS`, `iPhone 17 Pro` 시뮬레이터)·macOS(`besir-macOS`) 양쪽 **무경고** 빌드(툴체인 경고 제외). `#if os(iOS)` 분기 세 자리(칩 높이 44/28, `.datePickerStyle(.graphical)`, `.keyboardType`/`.submitLabel`)가 새 파일로 같이 가야 한다;
  (b) 새 소스 파일이 생기므로 `xcodegen generate`가 필요하고 그것은 서명 계정을 리셋한다 — **`besir-iOS`·`besirShare` 두 타깃의 Team 재선택을 사용자에게 요청**해야 한다(CLAUDE.md 빌드 절);
  (c) `cd proxy && npm test` 전체 통과(본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다);
  (d) 실기기에서 AI 카드 동작이 추출 이전과 **구분되지 않는다**. 카드 렌더링·제스처·접근성 낭독은 드라이버가 검증하지 못하므로(뷰를 컴파일하지 않는다) 실기기 확인이 유일한 증거다 — 확인 항목은 acceptance.md AC-007에 열거한다.


### 2.5 범위 경계 (040번대)

- **REQ-040 (Unwanted)**: This SPEC shall not modify the four editing screens — `AddEventView`·`EventDetailView`·`AddActivityView`·`ActivityDetailView`는 한 줄도 바뀌지 않는다. 근거: 카드 t1의 본문이 "이 카드에서는 기존 4화면을 건드리지 않는다"로 못박고, §0이 그 이유(두 실패가 한 덩어리로 도착하는 것을 막는다)를 적었다. `AddActivityView.PlaceField`가 계약 6을 어기는 것은 §1.1에 측정돼 있지만 **고치지 않는다** — t3 소관이다.
- **REQ-041 (Unwanted)**: This SPEC shall change no observable behavior — 순수 추출이다. 칩 문구·순서·간격, 거절 문구, 확인 버튼 문구("등록하기"), 시각 에디터의 처음 바퀴 위치("지금에서 다음 정각", `:359`), 기준을 미리 골라두지 않는 것(`:168`·`:290`) 전부 그대로다. 추출 중 개선하고 싶은 것이 보이면 **하지 않고 plan.md의 후속 항목으로 적는다**(CLAUDE.md: "계획에 없는 리팩터링은 하지 않는다").

## 3. Out of Scope

- 네 편집 화면의 전환 — `SPEC-UIKIT-002`(t2: 일정 화면 2개) · `SPEC-UIKIT-003`(t3: 활동 화면 2개).
- `AddActivityView.PlaceField`의 계약 6 위반(`.quaternary`·`.secondary`·`.bordered`)과 디바운스 부재 — t3에서 컴포넌트로 교체되며 함께 사라진다.
- `AIAssistant`의 툴 선언·실행부 방어·프록시 — 본 SPEC은 뷰와 필드 모델만 옮긴다. `resolvedMode`·`resolveOrigin`·`isSamePlace` 50m 가드·`list_schedules` 자기교정은 건드리지 않는다.
- 활동의 이동 다리(leg)를 컴포넌트 옵션으로 흡수하는 일 — t3 카드 본문이 명시한 t3 범위다.
- **새 필드 종류 추가** — 현재 `Kind` 일곱(`.place`·`.mode`·`.buffer`·`.notify`·`.weeks`·`.title`·`.datetime`)만 옮긴다. 네 화면의 토글(알림 받기 / 구글 캘린더 등록 / 가는·오는 이동 함께 만들기)에 해당하는 `.toggle`이 없지만 t1에서 만들지 않는다 — 쓰는 곳이 없는 종류를 미리 넣으면 t2에서 실제 필요한 모양과 어긋난다. t2의 함정은 plan.md §2에 적어뒀다.
- **`AddActivityView.PlaceField` 삭제** — 아직 쓰는 곳이 있으므로 남긴다. 컴포넌트로 대체되며 사라지는 것은 t3다.
- `AIChatView`에 남는 카드 **밖**의 계약 6 우회와 전송 버튼 접근성 라벨 — 기본값은 t1 밖이다(§4 D-3 — 2026-09-18 전부 t1 밖으로 확정).
- 출시 전 제거 대상 테스트용 코드(`deleteEverythingForTesting`·`transcriptForDebugging`) — 별도 항목.

## 4. 결정 기록

### D-1 — 중립 액션 표면의 형태 — **해소됨**

- **선택지**: 클로저 묶음(struct of closures)
- **기록일**: 2026-09-18
- **반영 REQ**: REQ-011 · REQ-012
- **근거 제공**: `ui-design` 전문가 검토(2026-09-18). 아래 근거는 본 세션이 트리에서 재확인한 것만 싣는다.

뷰는 `@ObservedObject`를 갖지 않는 순수 뷰가 되고, 동작은 값 위의 클로저 묶음으로 넘어온다. 세 선택지의 탈락 이유:

| 선택지 | 탈락 이유 |
|---|---|
| 프로토콜 | 준수체가 `ObservableObject`여야 재렌더가 살아, **화면마다 참조 타입 4개**가 생긴다 — `Store` 밖에 상태 보관소가 네 곳 생기는 것이고 계약 3이 금지한 모양이다. 뷰 시그니처에 제네릭이 전파된다 |
| 중립 `ObservableObject` | 같은 계약 3 문제에 더해 **드라이버 전제를 깬다**. `Tools/GuardDriver.swift:101`이 "choose/submitCustom은 **버블 쪽 사본**을 고친다"를 전제로 `drvLiveAsk`가 `bubbles[$0].ask`를 값으로 읽는다(`:102-104`, 실측 확인). `Bubble.ask`가 참조 타입이 되면 이 전제와, "값 복사라서 늦게 온 검색 결과가 다른 카드에 앉을 수 없다"는 `setLookup` 쪽 안전장치가 함께 흔들린다 — t1이 감당할 변경이 아니다 |
| **클로저 묶음(채택)** | 값은 계속 `Store`/`AIAssistant`에만 있고, AI 결합이 어댑터 **한 함수**로 수축한다(계약 3·4 충족). 클로저 타입에 SwiftUI가 없어 REQ-003과도 맞는다. 드라이버 영향 없음 |

**보류된 판단 하나**: 뷰에서 `@ObservedObject var assistant`를 없애도 재렌더가 유지되는지는 부모(`AIChatView.chat`이 `assistant.bubbles`를 읽는다)가 담당한다는 **코드 구조 독해에 근거한 추론**이며, 실행으로 확인한 사실이 아니다. 반증 신호는 acceptance.md AC-002의 재렌더 항목이다 — 칩을 탭해도 체크가 안 뜨거나, 검색 결과가 줄에 안 얹히거나, `isThinking` 중 확인 버튼이 안 잠기면 이 추론이 틀린 것이고 즉시 되돌린다.

### D-2 — 새 파일의 이름과 개수 — **해소됨**

- **선택**: `Shared/EditCard.swift`(모델·동작 표면·날짜 단일 출처) + `Shared/EditCardView.swift`(뷰·`ChipFlow`·`chip`)
- **기록일**: 2026-09-18
- **반영 REQ**: REQ-001 · REQ-003 · REQ-010

2파일 분할은 취향이 아니라 **REQ-003이 강제하는 것**이다. 동작 표면(클로저 묶음)도 SwiftUI-free이므로 모델 파일에 함께 두며, 그러면 드라이버 `swiftc` 목록에 추가되는 파일은 `EditCard.swift` **하나**로 끝난다(REQ-004). 모델과 뷰를 한 파일로 합치면 SwiftUI가 드라이버 컴파일 집합에 들어가 11개 파일의 SwiftUI-free 성질이 깨진다.

이름이 `Ask*`가 아닌 이유는 REQ-001이다 — t2·t3의 네 화면이 같은 타입을 쓰므로 AI 전용으로 읽히면 안 된다.

**주의(실측 필요 항목)**: 화면 카드가 `parts`·`stated` 없이 카드를 만들려면 두 저장 프로퍼티에 기본값이 필요하고, Swift는 **`let` + 기본값을 멤버와이즈 이니셜라이저에서 제외**하므로 `var`로 바뀐다. 불변성이 느슨해지는 것은 사실이므로 acceptance.md가 `parts` 사후 대입이 0건인지 확인한다.

### D-3 — `AIChatView`에 남는 계약 6 우회·접근성 구멍을 t1에서 함께 고칠지 — **해소됨: 전부 t1 밖(2026-09-18 운영자 확정, lead 디스패치)**

`AIChatView.swift`는 이미 본 SPEC의 변경 대상이고, 그 안에 카드 **밖**의 우회가 남아 있다(실측):

| 위치 | 내용 | 성격 |
|---|---|---|
| `:85` | `Text("생각 중…").foregroundStyle(.secondary)` | 계약 6 우회 — `Theme.muted`로 바꿔도 보이는 변화 거의 없음 |
| `:114` | `.foregroundStyle(bubble.role == .user ? .white : .primary)` | 계약 6 우회 — `Theme.bg`/`Theme.ink`와 사실상 동일 |
| `:113` | `RoundedRectangle(cornerRadius: 14)` | 계약 6 우회지만 `Theme.radius`(3)로 바꾸면 **말풍선 모양이 눈에 보이게 바뀐다** |
| `:128-130` | 전송 버튼이 아이콘 전용이고 `.accessibilityLabel`이 없다 | 접근성 구멍 — 영구 컨트롤 |

`:57-68`의 툴바 버튼 둘도 아이콘 전용이고 `.help()`(macOS 툴팁)만 있어 iOS 접근성 라벨이 없지만, **`:56` 주석이 "⚠️ 테스트용 임시 — 출시 전에 뺀다"로 명시**하므로 라벨을 붙일 가치가 없다. 목록에서 제외한다.

**왜 열어두는가**: 네 건 모두 REQ-041("동작을 바꾸지 않는다")에 걸린다. `:113`은 외형이 실제로 바뀌고, 접근성 라벨 추가도 VoiceOver 출력이 달라지는 관측 가능한 변화다 — 좋은 변화이지만 변화다. CLAUDE.md는 "추출 중 개선하고 싶은 것이 보이면 하지 않고 후속 항목으로 적는다"고 하므로 **기본값은 전부 t1 밖**이다. 운영자가 일부를 t1에 넣기로 정하면 REQ-041에 예외 절을 달고 acceptance.md에 대응 항목을 추가한다. **결과(2026-09-18)**: 운영자 확정 — 전부 t1 밖(lead 디스패치 "REQ-041 예외 절 불필요", progress.md §E.1). 예외 절·대응 항목 없이 후속 항목으로 남는다.


## 5. 관련 문서

- 루트 `plan.md` §6 `:411-417` — 설계 원본. 구현 중 어긋나면 **그 자리에서 함께 갱신**한다(CLAUDE.md).
- 루트 `CHECKLIST.md` — 사용자 관점 요구사항. 본 SPEC은 동작을 바꾸지 않으므로(REQ-041) 신규 항목이 없고, AI 카드 관련 기존 항목이 그대로 초록인지만 확인한다.
- `SPEC-ASK-001` — 카드의 출생 SPEC. REQ-011~014가 카드 형태를, plan.md §2가 "드라이버는 뷰를 컴파일하지 않는다" 경계를 세웠다. 본 SPEC은 그 형태를 **보존**한다.
- `SPEC-ONTIME-001` — be on-time sir as-built 베이스라인. 본 SPEC은 REQ를 건드리지 않는다.

🗿 MoAI
