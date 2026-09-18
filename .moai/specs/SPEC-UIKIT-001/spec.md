---
id: SPEC-UIKIT-001
title: "일정·활동 편집 카드 컴포넌트 추출 (UI 통일 1/3)"
version: "0.1.1"
status: draft
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

## 0. 이 SPEC의 성격

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §6 "다음 Day — 일정·활동 화면 UI 통일"(`plan.md:411-417`)이고, 본 SPEC은 그것을 재발명하지 않는다. 인용 줄번호는 변경 전 현재 상태(`291db49`) 기준이므로 구현 중 밀릴 수 있다 — 그때마다 실측 재정렬한다(SPEC-ONTIME-001 HISTORY 0.2.3이 세운 관례).

**왜 세 장으로 쪼개졌는가.** 루트 `plan.md:412`는 네 화면 약 1,800줄을 한 Day의 범위로 적었지만, CLAUDE.md는 한 Day에 새로 만들거나 크게 고치는 파일을 **3~4개**로 제한한다. 네 화면 + 컴포넌트 + AI 카드는 6파일이므로 제한을 넘는다. 그래서 칸반 대기열이 t1(컴포넌트 추출 + AI 카드) · t2(일정 화면 2개) · t3(활동 화면 2개)로 나눴고, 본 SPEC은 t1에 대응한다. **t2·t3는 별도 SPEC**(`SPEC-UIKIT-002`·`SPEC-UIKIT-003`)으로 쓰며 본 SPEC의 REQ 번호를 재번호하지 않는다.

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
- **REQ-002 (Ubiquitous)**: The moved field model shall carry its own value interpretation. 근거(실측): `AskField`가 `AIAssistant`의 **`private static` 멤버 셋**에 기대고 있다 — `parseDatetime`(`:1651`), `when`(`:1636`), `isoFormatter`(`:1641`). 중첩을 벗어나는 순간 이 세 참조는 컴파일되지 않는다(`private`은 중첩 타입에서만 보였다). 값 해석(`chosenLabel`·`customLabel`·`accepts`)은 모델의 일부이므로 세 멤버도 모델과 **함께** 옮기거나, 모델이 부를 수 있는 가시성으로 승격한다 — 둘 중 어느 쪽이든 **해석이 두 곳에 생기지 않아야 한다**(계약 5).
- **REQ-003 (Unwanted)**: The moved model file shall not import SwiftUI. 근거(실측): 가드 드라이버의 컴파일 집합(`Tools/GuardDriver.swift`·`Shared/AIAssistant.swift`·`Store`·`Models`·`Config`·`PlaceSearch`·`DirectionsService`·`LocationManager`·`NotificationManager`·`GoogleCalendarService`·`SharedInbox`)에는 `import SwiftUI`가 **한 건도 없다**. 드라이버는 SwiftUI 뷰를 컴파일 대상으로 삼지 않는다(SPEC-ASK-001 plan.md §2가 세운 경계) — 모델이 SwiftUI를 끌어오면 그 경계가 무너진다. 그래서 모델과 뷰는 **반드시 다른 파일**이다.
- **REQ-004 (Event-driven)**: When the field model moves to a new file, the guard-driver compile command shall name that file. 근거(실측): `Tools/GuardDriver.swift`가 `AskField`·`PendingAsk`를 **20곳**에서 참조한다(`drvAsk`가 `PendingAsk?`를 돌려주는 등). CLAUDE.md의 드라이버 명령은 `Shared/AIAssistant.swift`만 `cat`으로 합치고 나머지 9개 파일을 `swiftc` 인자로 넘기므로, 새 모델 파일을 그 인자 목록에 넣지 않으면 드라이버가 컴파일되지 않는다. **CLAUDE.md의 그 명령 블록을 함께 갱신한다.**

### 2.2 카드 뷰 추출 (010번대)

- **REQ-010 (Ubiquitous)**: The card view shall live in `Shared/` and be non-private — `AskCardView`(`Shared/AIChatView.swift:158-557`)·`ChipFlow`(`:564-612`)·그 안의 `chip(_:selected:dashed:action:)` 빌더가 새 뷰 파일로 옮겨진다. 현재 셋 다 `private`이므로 파일 밖에서 쓸 수 없다.
- **REQ-011 (Unwanted)**: The extracted view shall not name `AIAssistant` as a type. 근거(실측): 결합 지점은 정확히 **9곳**이다 — `isThinking`(`:181`, `:537`), `choose(field:value:)`(`:238`), `rechooseTimeBasis`(`:299`), `chooseTime`(`:344`), `choose(field:place:)`(`:444`), `searchPlaces`(`:495`), `submitCustom`(`:523`), `confirmAsk()`(`:534`). 아홉 지점 전부가 중립 표면을 거쳐야 하며, 남은 한 곳이 있으면 네 화면이 그 컴포넌트를 쓸 수 없다.
- **REQ-012 (Ubiquitous)**: `AIAssistant` shall remain the sole AI-side adapter of that neutral surface — 새 AI 클래스를 만들지 않는다(CLAUDE.md 계약 4). 어댑터는 기존 `AIAssistant`가 중립 표면을 만족시키는 형태이고, 별도의 카드 전용 컨트롤러·이벤트버스·영속화 레이어를 두지 않는다(계약 3).
- **REQ-013 (Ubiquitous)**: The extracted view shall keep its card-lifetime local state — `customOpen`·`draft`·`rejected`·`draftBasis`·`draftDate`(`:164-171`)가 컴포넌트 안에 남는다. 근거(주석 `:162-163`): 이 상태를 채팅 뷰로 올렸더니 "카드가 요약으로 바뀐 뒤에도 열린 입력창과 거절 표시가 남아 다음 카드로 흘러갔다". 호출자에게 상태를 넘기는 설계는 그 사고를 되돌린다.

### 2.3 보존해야 할 불변식 (020번대)

> 아래는 전부 **이미 사고를 겪고 세워진 것**이며, 순수 추출에서 조용히 사라지기 쉬운 순서로 적었다.

- **REQ-020 (Ubiquitous)**: The extracted component shall use only `Theme` tokens for color — 원시 색·`.secondary`·`.quaternary`·시스템 머티리얼을 쓰지 않는다(계약 6). 현재 카드가 쓰는 토큰: `ink`·`muted`·`faint`·`line`·`bg`·`raised`·`travel`·`travelFill`·`travelInk`·`warn`·`radius`. `preferredColorScheme`을 강제하지 않는다.
- **REQ-021 (Ubiquitous)**: The extracted component shall preserve four accessibility invariants verbatim:
  (a) 선택 표시를 색에만 맡기지 않는다 — 체크 글리프 + 글자 굵기(`:372`);
  (b) 칩은 줄 이름과 묶여 읽힌다 — `accessibilityElement(children: .contain)` + `accessibilityLabel(field.note.map { "\(label). \($0)" } ?? label)`(`:275`·`:277`);
  (c) 흐려진 여유 줄은 색(투명도 0.5)만으로 상태를 말하지 않고 캡션을 함께 둔다(`:267`(캡션)·`:273`(opacity));
  (d) 확인 버튼의 잠김 이유는 힌트로 읽힌다 — `accessibilityHint`(`:555`).
- **REQ-022 (Unwanted)**: The extracted view shall not hold a search debounce timer — 장소 검색의 묶음은 어댑터 쪽에 남는다. 근거(주석 `:487-488`): 뷰가 타이머를 들면 재렌더마다 흩어져 글자마다 호출이 나가고, 그것이 곧 카카오 일일 할당량이다.
- **REQ-023 (Ubiquitous)**: The extracted component shall preserve the platform chip-height split — iOS `44`pt / macOS `28`pt, 둘 다 `@ScaledMetric(relativeTo: .callout)`(`:176`(iOS 44)·`:178`(macOS 28)). 근거(주석): 고정하면 큰 글씨 설정에서 칩이 잘리고, macOS는 포인터라 44pt면 카드만 길어진다.
- **REQ-024 (Ubiquitous)**: The extracted model shall preserve the per-kind acceptance ranges — 여유 `0...Store.maxBufferMinutes`, 알림 `0...1440`, 반복 `1...Store.maxRecurrenceWeeks`, 이동수단 `TransportMode(rawValue:)` 유효, 시각은 접두 + 정규 ISO만(`:89-106`). 상한을 문구에 박지 않는다 — 현재도 거절 사유가 "그 값은 쓸 수 없어요"뿐인 이유가 "상한이 Store 상수라 문구에 박으면 두 곳이 된다"(`:257`)이다.
- **REQ-025 (Ubiquitous)**: The extracted component shall preserve the place-row contract — 자유 텍스트를 그대로 확정하는 버튼을 두지 않고, 후보를 탭해 좌표까지 확정한다. 근거(주석 `:407-408`): 좌표 없는 확정은 카드를 다 채우고 확인을 누른 **뒤에야** 실행부 검색에서 실패했다(2026-09-16 실기기 결함 P). 0건과 오프라인을 구분한 척하지 않고 양쪽을 함께 말하는 문구도 그대로 둔다(`:430`).
- **REQ-026 (Ubiquitous)**: The extracted component shall keep chips reachable without horizontal scrolling — `ChipFlow`가 줄바꿈으로 흘려 넣는다. 근거(주석 `:561`): "화면 밖으로 밀린 칩은 고를 수 없는 값이고, 이 카드에서 못 고른 값은 그대로 조용한 기본값이 된다."

### 2.4 검증 (030번대)

- **REQ-030 (Ubiquitous)**: The guard driver shall stay fully green — `drvCheck(` 호출 지점 **200곳**(정의 1건 제외, `291db49` 실측). 총 단언 수는 반복 안의 호출 때문에 호출 지점 수보다 크므로 **run-phase 실행 출력으로 실측**한다(SPEC-ASK-001 HISTORY 0.2.1이 세운 관례 — 총수를 문서에 박지 않는다). 본 SPEC은 순수 추출이므로 **단언을 새로 추가하지 않고, 기존 단언이 그대로 초록인 것**이 통과 조건이다.
- **REQ-031 (Ubiquitous)**: The build shall be warning-free on both platforms — iOS(`besir-iOS`, `iPhone 17 Pro` 시뮬레이터)·macOS(`besir-macOS`). 새 소스 파일이 생기므로 `xcodegen generate`가 필요하고, 그것은 서명 계정을 리셋한다 — **`besir-iOS`·`besirShare` 두 타깃의 Team 재선택을 사용자에게 요청**해야 한다(CLAUDE.md 빌드 절).
- **REQ-032 (Event-driven)**: When the extraction is complete, the AI card's behavior on a real device shall be indistinguishable from before. 카드 렌더링은 가드 밖이므로(드라이버가 뷰를 컴파일하지 않는다) 실기기 확인이 유일한 증거다. 확인 항목은 acceptance.md AC-006에 열거한다.

### 2.5 범위 경계 (040번대)

- **REQ-040 (Unwanted)**: This SPEC shall not modify the four editing screens — `AddEventView`·`EventDetailView`·`AddActivityView`·`ActivityDetailView`는 한 줄도 바뀌지 않는다. 근거: 카드 t1의 본문이 "이 카드에서는 기존 4화면을 건드리지 않는다"로 못박고, §0이 그 이유(두 실패가 한 덩어리로 도착하는 것을 막는다)를 적었다. `AddActivityView.PlaceField`가 계약 6을 어기는 것은 §1.1에 측정돼 있지만 **고치지 않는다** — t3 소관이다.
- **REQ-041 (Unwanted)**: This SPEC shall change no observable behavior — 순수 추출이다. 칩 문구·순서·간격, 거절 문구, 확인 버튼 문구("등록하기"), 시각 에디터의 처음 바퀴 위치("지금에서 다음 정각", `:359`), 기준을 미리 골라두지 않는 것(`:168`·`:290`) 전부 그대로다. 추출 중 개선하고 싶은 것이 보이면 **하지 않고 plan.md의 후속 항목으로 적는다**(CLAUDE.md: "계획에 없는 리팩터링은 하지 않는다").

## 3. Out of Scope

- 네 편집 화면의 전환 — `SPEC-UIKIT-002`(t2: 일정 화면 2개) · `SPEC-UIKIT-003`(t3: 활동 화면 2개).
- `AddActivityView.PlaceField`의 계약 6 위반(`.quaternary`·`.secondary`·`.bordered`)과 디바운스 부재 — t3에서 컴포넌트로 교체되며 함께 사라진다.
- `AIAssistant`의 툴 선언·실행부 방어·프록시 — 본 SPEC은 뷰와 필드 모델만 옮긴다. `resolvedMode`·`resolveOrigin`·`isSamePlace` 50m 가드·`list_schedules` 자기교정은 건드리지 않는다.
- 활동의 이동 다리(leg)를 컴포넌트 옵션으로 흡수하는 일 — t3 카드 본문이 명시한 t3 범위다.
- 출시 전 제거 대상 테스트용 코드(`deleteEverythingForTesting`·`transcriptForDebugging`) — 별도 항목.

## 4. 결정 기록

### D-1 — 중립 액션 표면의 형태 (해소 대기)

REQ-011의 9개 결합 지점을 무엇으로 대체하는가. 현실적인 선택지는 셋이다.

| 선택지 | 형태 | 비용 |
|---|---|---|
| A | 프로토콜 — `AIAssistant`가 채택 | 뷰가 제네릭 또는 `any`를 들어야 하고, `@ObservedObject` 갱신 경로를 별도로 확보해야 한다 |
| B | 클로저 묶음 구조체 | 타입 결합이 완전히 끊기지만 액션이 9개라 생성부가 길고, `isThinking` 같은 **관측 상태**는 클로저로 표현되지 않는다 |
| C | 중립 `ObservableObject` — `AIAssistant`가 소유하고 갱신 | 뷰의 `@ObservedObject` 경로가 그대로 남고 관측 상태도 자연스럽지만, 상태가 어시스턴트와 그 객체 두 곳에 생기지 않게 **소유권을 명확히** 해야 한다(계약 3·5) |

**해소 조건**: `ui-design` 전문가의 권고를 §4에 규약 슬롯 형식(선택지 / 기록일 / 반영 REQ)으로 기록한 뒤 run-phase에 착수한다. 해소 전에는 REQ-011·REQ-012가 형태를 지정하지 않는다 — 두 REQ가 요구하는 것은 "`AIAssistant`를 타입으로 알지 않는다"와 "새 AI 클래스를 만들지 않는다"이며, 세 선택지 모두 그것을 만족시킬 수 있다.

### D-2 — 새 파일의 이름과 개수 (해소 대기)

REQ-003이 모델과 뷰를 다른 파일로 갈라놓으므로 최소 2개가 새로 생긴다. CLAUDE.md의 한 Day 3~4파일 제한 안에서, 본 SPEC이 만들거나 크게 고치는 파일은 **새 파일 2개 + `AIAssistant.swift` + `AIChatView.swift` = 4개**로 상한에 정확히 걸린다. 파일이 하나라도 더 필요해지면 **분열 신호**이며, 그때는 t1을 더 쪼갠다.

이름은 AI 전용으로 읽히지 않아야 한다(REQ-001) — 네 화면이 같은 타입을 쓸 예정이다. `ui-design` 권고와 함께 확정한다.

## 5. 관련 문서

- 루트 `plan.md` §6 `:411-417` — 설계 원본. 구현 중 어긋나면 **그 자리에서 함께 갱신**한다(CLAUDE.md).
- 루트 `CHECKLIST.md` — 사용자 관점 요구사항. 본 SPEC은 동작을 바꾸지 않으므로(REQ-041) 신규 항목이 없고, AI 카드 관련 기존 항목이 그대로 초록인지만 확인한다.
- `SPEC-ASK-001` — 카드의 출생 SPEC. REQ-011~014가 카드 형태를, plan.md §2가 "드라이버는 뷰를 컴파일하지 않는다" 경계를 세웠다. 본 SPEC은 그 형태를 **보존**한다.
- `SPEC-ONTIME-001` — be on-time sir as-built 베이스라인. 본 SPEC은 REQ를 건드리지 않는다.

🗿 MoAI
