---
id: SPEC-UIKIT-002
title: "AddEventView를 편집 카드 컴포넌트로 전환 + 장소 검색 디바운서 단일화 (UI 통일 2a)"
version: "0.1.3"
status: draft
created: "2026-09-18"
updated: "2026-09-18"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "ui-unification, shared-component, contract-5, edit-card, debounce, theme-tokens"
tier: M
related_specs: [SPEC-UIKIT-001, SPEC-ASK-001, SPEC-ONTIME-001]
kanban_card: t2
---

# SPEC-UIKIT-002 — AddEventView를 편집 카드 컴포넌트로 전환 (UI 통일 2a)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-18 | 최초 작성. 루트 `plan.md` §Phase 1.7의 t2를 GEARS로 정식화. **범위는 카드 분할 뒤의 2a**다 — 운영자가 2026-09-18 A안(분할)을 확정해 `EventDetailView`는 카드 t4(`SPEC-UIKIT-003` 아님 — 별도 SPEC)로 빠졌고, 그 대신 장소 검색 디바운서 단일화가 본 SPEC에 들어왔다. 인용 줄번호는 `434610e`(= `origin/master`, t1 머지 직후) 실측. 작성 중단 후 이어받은 plan 세션이 같은 날 전수 재실측해 **5건 바로잡음** — `Kind` `:60→:59`, t1 별칭의 소유 파일(=`AIAssistant.swift:31-32`, 컴포넌트 아님), `parseDatetime` `:36-44→:35-42`, `setLookup` 인용(호출 `:769`·`:773`·`:782`, `:755`는 `maxPlaceSuggestions` 선언), 칩 경로 `:93-104→:88-104` |
| 0.1.1 | 2026-09-18 | run(M2) 중 재실측 — `Kind`의 전수 switch가 세 곳이 아니라 **네 곳**(`AIAssistant.swift:890-900`, 보류 턴 인자 채우기 — swift-impl 전문가가 발견, 런 세션이 재검증)임을 정정. REQ-001에 네 번째 가지(`:892` 나열)를, REQ-041에 그 가지의 좁은 예외 절을 반영. D-3 해소 기록((i) 운영자 확정, lead 디스패치) 포함. 측정 오류 정정이지 요구사항 변화가 아니다 |
| 0.1.2 | 2026-09-20 | run(M4) 중 이탈 1건 승인·기록 — `EditField.options`를 `let`→`var`로. REQ-021(a)의 "원소를 제자리에서 고친다"(모드 칩의 `Option.detail` 갱신)가 `let` 배열로는 컴파일 불가능하고, 유일한 대안인 `EditField` 재구성은 `id = UUID()`가 새로 생겨 카드 정체성 계약 자체를 깬다. 멤버와이즈 시그니처는 그대로라 기존 생성부 무변경(REQ-002 유지). run lane이 승인하고 lead 완료 보고에 띄운다 |
| 0.1.3 | 2026-09-20 | run(M5 독립 검토) 반영 2건 — ① `Option.label` `let`→`var`: "현재 위치" 칩에 해석 지명을 얹는 확정 뒤 글자 수정(원본 확정 카드의 GPS fix 확인 수단 계승)이 `let`으로 불가능했고 Option 재구성은 `id = UUID()` 재발급이라 칩 신원이 흔들린다. `options` var(0.1.2)와 같은 사정·같은 해법, 생성부 무변경. ② 디바운서 `gate`의 skip 규칙 정교화: **직전 검색이 완료된 뒤의 같은 질의에만** skip을 내린다 — 진행 중 작업을 방금 끊었으면 같은 질의라도 재실행한다(끊긴 작업이 줄에 뿌린 '찾는 중'을 되돌릴 주체가 없어 줄이 갇히는 결함 — code-safety가 디바운서 분리 실행으로 재현·확정). REQ-011의 관측 계약(완료 후 같은 질의 재호출 없음)은 그대로 — 드라이버 P-5 초록 유지가 증거 |

## 0. 이 SPEC의 성격

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §Phase 1.7이고 본 SPEC은 그것을 재발명하지 않는다. 인용 줄번호는 변경 전 현재 상태(`434610e`) 기준이라 구현 중 밀릴 수 있다 — 그때마다 실측 재정렬한다(SPEC-ONTIME-001 HISTORY 0.2.3이 세운 관례, SPEC-UIKIT-001 HISTORY 0.1.1이 27건을 실제로 겪었다).

**왜 2a와 2b로 또 쪼개졌는가.** 칸반 카드 t2는 원래 `AddEventView`(550) + `EventDetailView`(377) 두 화면이었다. plan 단계에서 실측한 결과 **장소 검색 디바운스가 계약 5 충돌을 일으켜 `AIAssistant.swift`가 열려야 했고**(§1.2), 파일이 5개가 되어 CLAUDE.md의 한 Day 상한 3~4를 넘었다. 2026-09-18 운영자가 A안(분할)을 확정해:

- **t2 = 본 SPEC** — `AddEventView` 전환 + 디바운서 단일화. 4파일
- **t4** — `EventDetailView` 크롬 통일 + 시각 포매터 단일화. 2파일. 본 SPEC이 done이 된 뒤 착수
- **t3** — 활동 화면 둘. t4 이후

분할의 부수 이점: `AddEventView` 전환은 사실상 재작성이고 `EventDetailView`는 성격이 다른 크롬 패스라, 함께 묶으면 "전환이 틀렸다"와 "크롬이 틀렸다"가 한 덩어리로 도착해 가를 수 없다. t1이 "AI 카드만 먼저 전환"한 것과 같은 이유다.

**REQ 예산 — 14건으로 상한(16) 아래다.** 세는 명령은 `grep -c '^- \*\*REQ-' spec.md`이고 값은 **14**여야 한다: §2.1 4건(001~004) · §2.2 2건(010~011) · §2.3 4건(020~023) · §2.4 2건(030~031) · §2.5 2건(040~041). 여유 2건은 §D-3(과거 시각)이 미해소라 예외 절이 붙을 수 있어 남겨둔 것이다. 그 이상 늘면 분할 신호다.

§2.4의 REQ는 절(clause)을 품는다 — "기존 기능이 하나도 사라지지 않는다"는 하나의 요구사항이고, 29개 어포던스는 그것을 확인하는 절이다. 절을 각각 REQ로 올리면 번호만 늘고 의무는 같다. **대신 acceptance.md가 절 단위로 대조한다** — REQ 하나를 통째로 "통과"로 적는 경로는 없다.

**드라이버 초록은 이 SPEC에서 증거가 되지 못한다.** `Tools/GuardDriver.swift`는 SwiftUI 뷰를 컴파일 대상으로 삼지 않으므로 카드 렌더링·제스처·접근성 낭독은 가드 밖이다. 88/88 초록 다음 날 실기기 결함 7건이 나온 이력이 있다. AC-009(실기기)가 대체 불가능한 증거다.

## 1. 배경

### 1.1 측정된 어긋남 (`434610e` 실측)

같은 일(일정 만들기)을 하는 화면이 세 벌이고, `AddEventView`는 그 중 가장 큰 것이다.

| 항목 | 값 | 확인 |
|---|---|---|
| `Shared/AddEventView.swift` | **550줄** | `wc -l` |
| 그 중 뷰 본문(`body`~`favoriteChips`) | `:47-401` | 읽음 |
| 접근성 호출 | **0건** | `grep -c accessibility` |
| `@ScaledMetric` | **0건** | 같은 grep |
| `DateFormatter` 선언 | 1건(`depFmt` `:382-385`) — **`static let`이 아니라 계산 프로퍼티**라 접근할 때마다 새로 만든다. 호출부는 `:285`·`:294`·`:297` 셋이므로 재렌더마다 최대 3회 할당 | `grep`, 읽음 |
| 과거 시각을 막는 `in: Date()...` | `:233` — `Shared/` 전체에서 **유일** | `grep -rn "in: Date()"` |

컴포넌트 쪽(t1 산출물):

| 항목 | 값 | 확인 |
|---|---|---|
| `Shared/EditCard.swift` | 159줄, `import SwiftUI` 0건 | `wc -l`, `grep` |
| `Shared/EditCardView.swift` | 465줄 | `wc -l` |
| `EditField.Kind` 종류 | **7** (`place·mode·buffer·notify·weeks·title·datetime`) `:59` — 토글에 대응하는 종류가 없다 | 읽음 |
| `EditCardView` 호출부 | **1곳** — `AIChatView.swift:106` | `grep -rn "EditCardView("` |
| 하드코딩된 크롬 | 헤더 `"몇 가지만 알려주세요"` `:38`, 확인 버튼 `"등록하기"` `:393` | 읽음 |
| `AIAssistant`의 필드 팩토리 | **11개** 함수, `.init(key:...)` **11회** | `grep -c` |
| `AIAssistant`의 `Option` 생성 | **16회** | `grep -c` |
| t1이 남긴 별칭 | `typealias AskField = EditField`(`AIAssistant.swift:31`), `PendingAsk = EditCard`(`AIAssistant.swift:32`) — AI 쪽 위탁이지 컴포넌트 소유가 아니다 | 읽음 |

### 1.2 계약 5 충돌 — 장소 검색 디바운스 (본 SPEC이 생긴 이유)

세 사실이 맞물린다(전부 실측):

1. `EditCardView.placeQueryBinding`(`:341-351`)은 **타이핑 한 글자마다** `actions.searchPlaces`를 부른다. `:339-340`의 주석이 이유를 적어뒀다 — "묶음(디바운스)은 assistant가 한다 — 뷰가 타이머를 들면 카드가 다시 그려질 때마다 흩어져 글자마다 호출이 나간다(카카오 일일 할당량)".
2. 그 디바운서는 `AIAssistant.searchPlaces`(`:764-785`)에만 있다 — 350ms(`:775`) + `Task` 취소(`:766`) + 같은 질의 스킵(`:772`). 상태는 `placeSearchTasks`(`:51`)·`lastPlaceQuery`(`:52`)이고 대화 초기화 시 함께 비운다(`:800-802`).
3. `AddEventView`에는 디바운스가 없다. 검색은 **명시적 트리거**다 — `onSubmit`(`:128`·`:168`), 돋보기 버튼(`:129-132`·`:169-172`), `count >= 2` 가드(`:456`·`:465`).

따라서 `AddEventView`가 카드를 쓰는 순간 디바운스가 필요해지는데, **복제하면 계약 5 위반이다.** 카카오 일일 할당량이 걸린 정책이 두 곳에서 각자 늙는다. 이것이 계약 5가 `ContentView.span(for:)`에서 겪은 사고(렌더링과 히트테스트가 따로 계산하다 어긋남)와 같은 모양이다.

**실제 위험 구간은 드라이버의 P 계열이다.** `Tools/GuardDriver.swift`가 장소 검색 경로를 P-1~P-7로 단언하고 있고(`:1512`·`:1515`·`:1525`·`:1529`·`:1531`·`:1549`·`:1561`·`:1566`·`:1572`·`:1576`·`:1593`·`:1599`·`:1604`), 그 중 **P-5(`:1572`·`:1576`)가 디바운스 동작 자체를 단언한다** — "같은 질의는 다시 부르지 않는다", "입력을 비우면 상태도 비워진다". 디바운서를 옮기고 이 둘이 초록이면 옮김이 옳았다는 기계적 증거가 된다.

### 1.3 t1이 남긴 휴면 계약

`SPEC-UIKIT-001/plan.md` §4가 t2·t3의 완료 조건으로 못박은 것: **`EditCardView`는 아무것도 관찰하지 않는 순수 값 뷰다**(`card`·`busy`·`actions` 모두 `let`, `:7-13`). 소유 화면이 자기 상태를 바꿔야 재렌더가 일어난다. `AIChatView`는 부모가 `assistant`를 `@ObservedObject`로 관찰해 자연히 성립하던 계약이라, **`AddEventView`가 이 계약을 처음으로 명시적으로 이행하는 화면**이다. REQ-021이 그 이행 형태를 고정한다.

## 2. 요구사항 (GEARS)

### 2.1 컴포넌트 표면 확장 (001번대)

- **REQ-001 (Ubiquitous)**: The field model shall carry a boolean field kind whose chosen value is seeded at creation. `EditField.Kind`에 `case toggle`을 더하고, 토글 줄은 반드시 `chosen: "true"` 또는 `"false"`로 생성한다. 근거(실측): `EditCard.isReady`가 `fields.allSatisfy { $0.chosen != nil }`(`:145`)이므로 seed하지 않으면 Bool은 영원히 "안 고른 값"이고 제출이 풀리지 않는다 — `SPEC-UIKIT-001/plan.md` §2가 t1 시점에 미리 적어둔 함정이다. 렌더링은 기존 칩 경로(`EditCardView:88-104`)를 그대로 쓰며 **뷰 코드를 새로 만들지 않는다**. `customLabel`(`EditCard.swift:91-102`)·`accepts`(`:106-129`)·`placeholder(for:)`(`EditCardView:245-252`)의 `switch`가 전수라 세 곳에 가지가 추가되지만 `allowsCustom: false`·`chosen` seed 때문에 실행 중 도달하지 않는다 — 컴파일 강제가 목적이다. **run(M2) 중 재실측(HISTORY 0.1.1)**: 전수 switch는 세 곳이 아니라 **네 곳**이다 — `AIAssistant.swift:890-900`(보류 턴의 인자 채우기)도 `Kind`를 전수 분기하므로 `:892`의 `case .place, .mode, .title: args[f.key] = chosen` 나열에 `.toggle`이 들어가야 컴파일된다. 이 가지 역시 실행 중 도달하지 않는다(AI 카드는 토글 줄을 만들지 않는다) — REQ-041의 예외 절이 이 한 가지만 허용한다.
  - **seed가 "앱이 먼저 정해두지 않는다" 원칙과 부딪히지 않는 이유**를 함께 적는다: AI 카드에서 미리 골라둔 값은 **모델이 조용히 정한 값**이고 그것이 `b303f41`(저장해둔 여유 10분이 0으로 덮여 35건 등록)의 모양이었다. 편집 폼의 `notifyEnabled = true`·`syncToCalendar = true`(`AddEventView:36-37`)는 **앱이 문서화해 둔 기본값**이고 사용자가 보면서 바꾼다. 같은 형태가 아니다.

- **REQ-002 (Ubiquitous)**: The field model shall carry per-option detail text and a per-row busy flag, without breaking any existing construction site. `EditField.Option`에 `var detail: String? = nil`, `EditField`에 `var busy: Bool = false`를 더한다. 근거(실측): 기본값이 있는 저장 프로퍼티는 멤버와이즈 이니셜라이저에서 생략 가능하므로 `AIAssistant`의 필드 팩토리 **11곳**(`.init(key:` 11회)과 `Option` 생성 **16곳**이 한 줄도 바뀌지 않는다. `detail`은 칩 안에 작게 따라붙고(이동수단의 소요시간), `busy`는 줄 이름 옆 `ProgressView`를 띄운다 — 후자는 `placeSearchEditor`의 "찾는 중…"(`EditCardView:274-279`)이 이미 쓰는 문법과 같다. 둘 다 SwiftUI-free라 REQ-040 (d)의 드라이버 경계를 깨지 않는다.

- **REQ-003 (Ubiquitous)**: The field model shall allow a row to open its editor on appearance. `EditField`에 `var startsOpen: Bool = false`를 더하고, `EditCardView`가 `.onAppear`에서 `customOpen`을 그 목록으로 seed한다. 근거: 제목과 목적지는 새 일정마다 반드시 새로 입력하는 값인데, 카드 문법에서는 점선 칩(`EditCardView:99-103`)을 한 번 탭해야 입력칸이 열려 **주 경로에 탭이 둘 늘어난다**. AI 카드는 전부 기본값 `false`라 무변화다.

- **REQ-004 (Ubiquitous)**: The card view shall let its owner suppress the card's own title and confirm button. `EditCard.swift`에 SwiftUI-free한 `EditCardChrome { header: String?, confirmTitle: String? }`를 더하고 `EditCardView(card:busy:actions:chrome:)`의 기본값을 AI 카드의 현재 문구로 둔다. 근거(실측): `EditCardView`는 헤더 `"몇 가지만 알려주세요"`(`:38`)와 확인 버튼 `"등록하기"`(`:393`)를 하드코딩하는데, `AddEventView`에는 이미 화면 제목(`:80`)과 footer 제출 버튼(`:366-373`)이 있어 그대로 붙이면 **제목이 둘, 제출 버튼이 둘**이 된다. 기본값이 있으므로 유일한 기존 호출부 `AIChatView.swift:106`은 **무변경**이다(REQ-041).

### 2.2 장소 검색 디바운스 단일화 (010번대)

- **REQ-010 (Ubiquitous)**: The place-search debounce policy shall live in exactly one neutral owner. 디바운서(지연·취소·같은 질의 스킵)를 `Shared/EditCard.swift`로 옮겨 값 타입 하나가 소유하게 하고, 지연 시간 상수는 그 타입에만 존재한다. 근거(실측): 현재 정책은 `AIAssistant.searchPlaces`(`:764-785`)에만 있고 `350_000_000`은 `Shared/` 전체에서 `AIAssistant.swift:775` **1곳**이다. 카카오 일일 할당량이 걸린 정책이라 두 벌이 되면 한쪽만 늙는다(계약 5). 기계적 신호: `grep -rc "350_000_000" Shared/` 합이 **1**이고 그 파일이 `EditCard.swift`다 — 2가 되면 복제고, `AIAssistant.swift`에 남아 있으면 옮기지 않은 것이다.
  - 옮기는 것은 **정책**이지 상태 전이가 아니다. `setLookup` 호출(`:769`·`:773`·`:782`)과 `maxPlaceSuggestions` 자르기(선언 `:755`·사용 `:783`)는 AI 쪽 의미이므로 따라가지 않는다 — 새 AI 클래스를 만들지 않는다는 계약 4를 뒤집어, 중립 파일이 AI의 일을 가져가지도 않는다.

- **REQ-011 (Unwanted)**: The AI card's search behavior shall not change. `AIAssistant.searchPlaces`가 공용 디바운서를 쓰되 관측 가능한 동작(지연 350ms, 같은 질의 재호출 없음, 카드가 사라진 뒤 도착한 결과를 버림, 입력을 비우면 상태도 비움)이 그대로다. 근거(실측): 이 넷은 드라이버가 이미 단언하고 있다 — P-4(`:1561`·`:1566`), **P-5(`:1572`·`:1576`)**, P-6(`:1593`). **단언을 추가하지 않고 기존 단언이 초록인 것**이 통과 기준이다. 대화 초기화 시의 정리(`:800-802`)도 같은 의미를 유지한다.

### 2.3 `AddEventView` 전환 (020번대)

- **REQ-020 (Ubiquitous)**: The card shall be the single source of the form's input. `originPlace`·`selectedPlace`·`title`·`arrivalDate`·`departureDate`·`anchor`·`mode`·`bufferMinutes`·`notifyLeadMinutes`·`notifyEnabled`·`syncToCalendar` 11개 `@State`(`:13-37`)를 제거하고 `@State private var card: EditCard` 하나로 대체한다. 제출 가능 판정도 `canSave`(`:378-380`)를 버리고 `card.isReady`를 쓴다. 근거: 판정과 값이 두 곳에 있으면 어긋난다(계약 5). 좌표는 `chosen`(String)에 담기지 않으므로 **`AIAssistant`와 같은 형태**로 푼다 — `confirmedPlaces[name] = place`(`AIAssistant.swift:49`·`:748`)와 같은 사전을 화면이 들고, 즐겨찾기 옵션 생성과 `choosePlace` 시점에 **즉시** 채운다. 지연 해석 함수를 만들지 않는다 — 만들면 `AIAssistant.resolvePlace`의 두 번째 구현이 되어 계약 5 위반이다.

- **REQ-021 (Ubiquitous)**: The card's view identity shall stay stable for the life of the sheet. 세 절을 모두 지킨다:
  - (a) 카드는 `.task`에서 **정확히 한 번** 만들어 `@State`에 저장하고, 이후에는 원소를 제자리에서 고치거나 배열에 넣고 뺀다. **계산 프로퍼티로 만들지 않는다.** 근거(실측): `EditField.id`는 `let id = UUID()`(`EditCard.swift:65`)라 인스턴스마다 새로 생기고, `EditCardView`의 지역 상태 다섯(`customOpen`·`draft`·`rejected`·`draftBasis`·`draftDate` `:17-24`)이 전부 그 UUID를 **키로** 쓴다(`:344`·`:355`·`:365-366`). 매 렌더마다 다시 만들면 `draft[field.id]`가 항상 비어 **장소 이름을 한 글자도 칠 수 없다**.
  - (b) `EditCardView`는 `ScrollView` 루트의 고정 위치에 **무조건** 놓는다. `Group`·`AnyView`로 감싸지 않고 바뀌는 `.id(...)`를 붙이지 않는다. 현재 `:56`의 `if selectedPlace != nil && originPlace != nil { ... }` 조건부 섹션은 사라지고, 조건성은 `fields` 멤버십(REQ-022 (b))으로 표현된다.
  - (c) 카드 밖 상태(`location.isLocating` `:117`, `estimating` `:305`)는 `.onChange`로 해당 줄의 `busy`에 명시적으로 잇는다. 잇지 않으면 동작은 돌지만 진행 표시가 뜨지 않는다 — **휴면 계약(§1.3)이 실제로 물리는 자리**다.

- **REQ-022 (Ubiquitous)**: The screen shall keep outside the card exactly what the card cannot own. 네 절:
  - (a) 화면 header(`:78-85`, `.cancelAction` 포함)와 footer(`:362-376`, `.defaultAction`·`saving` 스피너 포함)는 그대로 남고 `chrome`으로 카드 쪽을 끈다(REQ-004).
  - (b) 조건부 줄은 세 갈래로 다르게 푼다. `syncToCalendar`는 **정적 조건**이라 카드 생성 시 줄을 만들거나 만들지 않는다(근거: `store.config`를 바꾸는 유일한 경로가 `Store.updateConfig` `:1476-1479`이고 호출부는 `SettingsView.swift:95` 한 곳뿐이라 시트가 열려 있는 동안 바뀌지 않는다). `notifyLeadMinutes`는 **동적**이라 토글의 `chooseValue`에서 배열에 넣고 뺀다(마지막 값은 화면이 들고 있다가 다시 seed). `bufferMinutes`는 **아무것도 하지 않는다** — `EditCardView.departureAnchored`(`:61-64`)가 이미 출발 기준일 때 흐림 + 캡션(`:119-126`)을 붙인다. 이 규칙을 화면에서 다시 계산하지 않는 것이 계약 5다.
  - (c) `ConflictBanner`(`:521-549`)는 카드 밖 화면 소유로 남는다. 읽던 값들은 `card.fields`의 `chosen`에서 읽고, 시각 해석은 `BesirTime.parseDatetime`(`EditCard.swift:35-42`) 단일 출처를 지난다.
  - (d) 수동 재계산은 카드 아래 화면 소유 컨트롤로 내려가고 **글자 라벨을 얻는다**. 근거(실측): 현재(`:307-309`)는 `Image(systemName: "arrow.clockwise")` + `.help(...)`뿐인데 `.help()`는 macOS 툴팁이라 iOS 접근성 라벨이 아니다 — 지금 이 버튼은 VoiceOver에서 **이름이 없다**.

- **REQ-023 (Ubiquitous)**: The screen shall hold no date formatter of its own. `depFmt`(`:382-385`)를 없애고 같은 패턴(`"M/d (E) a h시 mm분"`)을 `BesirTime`의 `static let` 멤버로 옮긴다. 근거(실측): `EditCard.swift:10-12`가 자기 존재 이유를 "포매터·파서가 파일마다 제각각 생기는 것이 이 프로젝트가 이미 한 번 당한 어긋남이라 정의는 이곳 하나"라고 적어뒀다. **패턴을 `BesirTime.when`으로 흡수하지 않는다** — `swift` 실측 결과 `"M/d (E) a h시 mm분"`은 `9/17 (목) 오후 3시 05분`, `when`("M월 d일 (E) a h시 m분")은 `9월 17일 (목) 오후 3시 5분`이고, `ConflictBanner`(`:548`)가 이 문자열 **둘을 `~`로 잇기** 때문에 폭이 늘어 줄바꿈이 깨진다. 덤으로 계산 프로퍼티 → `static let`이 되어 재렌더마다 최대 3회 할당하던 것(§1.1)이 사라진다. 기계적 신호: `grep -c "DateFormatter()" Shared/AddEventView.swift`가 **0**.

### 2.4 보존해야 할 것 (030번대)

- **REQ-030 (Ubiquitous)**: The conversion shall lose no user-visible affordance. 대조 단위는 acceptance.md AC-006의 **29개 절**이며 일괄 판정하지 않는다. 그 중 명시적으로 형태가 바뀌는 셋:
  - (a) 이동수단 아이콘(`:326`)은 사라진다 — **정보 손실 0**(`TransportMode.title`이 같은 정보를 글자로 담는다). 칩에 체크 글리프·라벨·소요시간이 이미 들어가 큰 글씨에서 두 줄로 감기는 것을 막기 위한 **축소**로 기록한다.
  - (b) 도착 여유 줄은 **사라지는 대신 흐려지고 캡션이 붙는다**(REQ-022 (b)). 숨은 값은 고칠 수 없는 값이라는 판단이 `EditCardView:116-118` 주석에 이미 있다.
  - (c) 소요시간 출처("카카오"·"ODsay"·"추정", `:331-333`)는 칩이 아니라 **줄 캡션(`note`)에 한 번만** 모인다. 칩 하나에 라벨·시간·출처 셋이 들어가면 큰 글씨에서 `ChipFlow`가 세 줄이 된다. 문자열 조립은 `AddEventView` 한 곳에만 둔다.

- **REQ-031 (Ubiquitous)**: The converted screen shall carry the component's accessibility contract and name what it loses. 근거(실측): `AddEventView`의 현재 접근성 호출과 `@ScaledMetric`은 **각각 0건**이므로 컴포넌트가 가진 것(줄 단위 그룹 낭독 `EditCardView:128-130`, 선택 상태 3중 표현 `:224-227`, `.isSelected` 특성 `:239`, 칩 높이 iOS 44/macOS 28 `@ScaledMetric` `:28-32`, 후보 줄 합침 낭독 `:315`)은 전부 순증이다. 새로 붙이는 것은 재계산 버튼의 글자 라벨(REQ-022 (d))과 `ConflictBanner`의 `.accessibilityElement(children: .combine)`이다.
  - **잃는 것을 숨기지 않는다**: `Stepper` 둘(`:350`·`:354`)의 "조정 가능" 특성과 스와이프 미세조정이 사라진다. 도달 가능한 값 범위는 오히려 넓어지지만(오늘 `0...60` → 버퍼 `0...Store.maxBufferMinutes`=180 `Store.swift:61`, 알림 `0...1440`), 제스처 경로는 직접입력으로만 대체된다. **이 카드에서 가장 실질적인 접근성 후퇴**이므로 acceptance.md가 항목으로 든다. `Toggle`의 스위치 특성도 같은 성격으로 잃는다.

### 2.5 검증과 범위 경계 (040번대)

- **REQ-040 (Ubiquitous)**: The conversion shall pass the project gate on both platforms and on a real device. 네 절:
  - (a) AI 인자 가드 드라이버 전체 초록, **단언 추가 없음** — 기존 단언이 그대로 통과한다(특히 P-1~P-7, REQ-011).
  - (b) iOS·macOS 양쪽 **무경고** 빌드(툴체인 경고 제외).
  - (c) `cd proxy && npm test` 전체 통과(본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다).
  - (d) **새 소스 파일을 만들지 않는다** — 변경은 전부 기존 4파일 안에서 일어난다. 따라서 CLAUDE.md의 `xcodegen generate` 조건("새 소스 파일이나 Info.plist 키를 추가했을 때만")에 걸리지 않고, **서명 계정 리셋이 없으며 `besir-iOS`·`besirShare` 두 타깃의 Team 재선택 요청도 필요 없다.** t1과 다른 점이라 명시한다. 기계적 신호: `git diff --name-only --diff-filter=A origin/master...HEAD -- 'Shared/*.swift'`가 0건.

- **REQ-041 (Unwanted)**: This SPEC shall not modify anything outside its four files. `Shared/AddEventView.swift`·`Shared/EditCard.swift`·`Shared/EditCardView.swift`·`Shared/AIAssistant.swift` 넷 **외의 소스 파일이 한 줄도 바뀌지 않는다** — 특히 `EventDetailView`(t4)·`AddActivityView`·`ActivityDetailView`(t3)·`AIChatView`는 무변경이다. 근거: `EditCardChrome`·`Option.detail`·`EditField.busy`·`startsOpen` 전부 기본값을 가지므로 `AIChatView.swift:106`이 바뀔 이유가 없고, 바뀌었다면 기본값을 빠뜨린 것이다. `AIAssistant`에 허용되는 변경은 **`searchPlaces`가 공용 디바운서를 쓰는 것뿐**(REQ-010·011)이며 필드 팩토리 11곳·`Option` 생성 16곳은 무변경이다. **한 가지 예외(HISTORY 0.1.1)**: `Kind.toggle` 추가에 따른 전수 switch 가지 — `:892` 나열에 `, .toggle` 7글자 — 는 컴파일 강제를 위해 허용한다. 실행 중 도달하지 않는 가지다(REQ-001). 추출 중 눈에 띈 개선은 코드가 아니라 루트 `plan.md`의 후속 항목으로 적는다.

## 3. Out of Scope

- `EventDetailView` 크롬 통일과 시각 포매터 `clock`·`stepTime` 신설 — **카드 t4**. 본 SPEC은 `BesirTime`에 `compact` 하나만 더한다(REQ-023).
- 활동 화면 둘(`AddActivityView`·`ActivityDetailView`)과 이동 다리(leg)의 컴포넌트 흡수 — **카드 t3**.
- `AIChatView`에 남은 계약 6 우회 4건 — t1 D-3에서 운영자가 "전부 t1 밖"으로 확정했고 본 SPEC도 건드리지 않는다.
- `PlaceField`의 계약 6 위반·디바운스 부재 — t1 §1.1이 측정해 뒀고 t3 소관이다.
- 출시 전 제거할 테스트용 코드(`deleteEverythingForTesting`·`transcriptForDebugging`) — 별건.

## 4. 결정 기록

### D-1 — `EventDetailView`를 본 SPEC에서 뺀 근거 — **해소됨**

- **결정**: 카드 분할(운영자 A안 확정, 2026-09-18 lead 디스패치)
- **반영**: §0, REQ-041, Out of Scope

`ui-design` 협의(2026-09-18)와 본 세션의 트리 재확인이 같은 결론에 닿았다: `EventDetailView`에는 **편집 가능한 필드가 하나도 없다.** 편집은 전부 `.sheet { AddEventView(editing: event) }`(`EventDetailView.swift:80-82`)로 위임되고 `detailRows`(`:302-348`)의 본문은 읽기 전용 `row(k,v)`(`:350-357`) 세 쌍뿐이다. 따라서 `EditCardView`로 1:1 치환할 대상이 없고, 그 화면의 "전환"은 성격이 다른 크롬 패스다.

기각한 해석 — **컴포넌트에 읽기 전용 렌더링 모드를 추가한다**: `EditCardView` 465줄 전체가 편집 문법(칩·에디터·거절·확인)이라 `readOnly` 분기를 넣으면 거의 모든 가지가 둘로 갈라지고, 그 대가로 얻는 것은 텍스트 세 줄이다. `EditField`는 "고를 값"의 모델(`chosen`·`options`·`accepts`)이라 선택지 없는 확정값을 담으면 의미가 빈다.

**카드 본문이 `EventDetailView:110-146`을 지목했던 것**은 "더 깊이 고치라"가 아니라 "크롬 패스 중에 캘린더 업로드 네 갈래(등록됨 `:115-116` / pending `:117-120` / 실패+재시도 `:122-136` / 계정 미연결 `:138-144`)를 둘로 접지 말라"는 방어로 읽는다 — 그 단순화가 바로 이 블록이 태어난 원인이었다(`:108-109`·`:139-140` 주석). t4가 이 판단을 이어받는다.

### D-2 — 토글·부가정보·크롬의 형태 — **해소됨**

- **선택**: `Kind.toggle`(칩 재사용) · `Option.detail` + `EditField.busy` · `EditCardChrome`
- **근거 제공**: `ui-design` 전문가 검토(2026-09-18). 아래는 본 세션이 트리에서 재확인한 것만 싣는다.
- **반영 REQ**: REQ-001 · REQ-002 · REQ-004

| 기각한 형태 | 이유 |
|---|---|
| 진짜 `Toggle` 컨트롤을 줄 안에 | 카드 전체가 칩 문법 하나인데 스위치가 두 번째 문법이 된다. `Toggle`은 폭을 다 쓰려 해 `ChipFlow`(`EditCardView:417-465`)의 흐름 배치에 들어가지 않는다. 순수 값 뷰라 합성 `Binding`이 필요해 상태 흐름이 다른 줄과 달라진다. **접근성 손해는 실재하며 REQ-031이 그것을 숨기지 않는다** |
| `Kind` 추가 없이 `.mode`로 두 옵션 필드를 만든다 | 오늘은 컴파일되고 동작도 한다. 그러나 `.mode`는 `accepts`에서 `TransportMode(rawValue:)`로 판정하므로(`EditCard.swift:111`) 의미가 거짓이고, 나중에 `.mode`에 분기가 하나 추가되는 순간 토글이 **조용히** 깨진다 |
| 조건부 줄을 배열에서 빼지 않고 `inactive` 캡션으로 일반화 | `EditField`에 `inactive: String?`를 넣고 `departureAnchored`를 흡수하려면 `AIAssistant`가 `chooseTime`/`rechooseTimeBasis`에서 그것을 세팅해야 한다. 흡수하지 않고 병행하면 "줄이 비활성인가" 판정이 두 곳이 되어 계약 5 위반이다. `departureAnchored`의 공짜 경로가 있으므로 불필요 |
| 소요시간을 줄 캡션 하나에 몰아 적는다 | 정보는 보존되지만 어느 칩이 어느 시간인지 눈으로 다시 맞춰야 한다. 현재 `modeCard`(`:319-343`)의 가장 큰 장점이 "고르는 자리와 근거가 같은 자리"인데 그것을 잃는다 |
| `Option`에 `systemImage`도 추가해 모드 아이콘 유지 | 칩 앞자리는 선택 체크 글리프가 이미 쓴다(`:224-226`). 아이콘+체크+라벨+시간이면 큰 글씨에서 칩이 두 줄로 감긴다. 정보 손실은 0이므로 REQ-030 (a)에 "축소"로 명기해 운영자가 뒤집을 수 있게 한다 |

**드라이버 영향 확인(실측)**: `Tools/GuardDriver.swift`는 `Kind`를 **망라 `switch`로 쓰지 않는다** — `==`/`!=` 비교 6곳뿐이다(`:547`·`:935`·`:948`·`:970`·`:980`·`:1019`). `case toggle` 추가로 드라이버가 깨지지 않고, AI 카드는 `.toggle` 필드를 만들지 않으므로 `:547`의 `f.kind == .mode ? "car" : "10"` 분기도 안전하다.

### D-3 — 과거 시각을 계속 막을지 — **해소됨**

- **결정**: **(i) 그대로 둔다** — 폼도 AI 카드와 같이 과거를 허용하고 피커에 범위를 넣지 않는다(운영자 확정, 2026-09-18 lead 디스패치). REQ-041 예외 절은 불필요하다. "과거 일정에는 알림이 안 걸린다"를 화면이 말하게 하는 후속 항목은 **Day 닫기 이월 목록으로 리드가 넘긴다 — run이 만들지 않는다.**
- **반영**: AC-008 절 4의 기록 절((i) 경로), AC-009 시뮬레이터 11번 항목

전환하면 **폼에서 과거 일정을 만들 수 있게 된다.** 실측 사실 셋:

1. `AddEventView.swift:233`의 `in: Date()...`는 `Shared/` 전체에서 과거 시각을 막는 **유일한 곳**이다(`grep -rn "in: Date()"` — 나머지 `DatePicker` 다섯은 범위가 없거나 `in: startDate...`다).
2. `EditCardView`의 `DatePicker`(`:187-189`)에는 범위가 없고 `EditField.accepts`의 `.datetime` 가지(`EditCard.swift:123-128`)도 과거를 거르지 않는다. **AI 카드는 이미 과거 시각을 받아들인다.**
3. `Store.addEvent`(`:571-582`)에 날짜 검증이 없고, 유일한 결과는 `NotificationManager.swift:34`의 `guard date > Date() else { return nil }` — **알림이 조용히 예약되지 않는다.**

즉 이것은 "기존 기능의 손실"이 아니라 **없던 능력의 획득**이고, 그 능력의 부작용이 조용한 실패다. 이 프로젝트가 반복해서 당한 모양(`hns-besir-app-hazards`의 "조용히 묻히는 실패")이라 전환의 부작용으로 흘려보내지 않는다.

| 선택지 | 대가 |
|---|---|
| **(i) 그대로 둔다** — 폼도 AI와 똑같이 과거를 허용 | 두 경로의 동작이 일치해 "UI 통일"에 부합. 다만 과거 일정에 알림이 안 걸리는 것을 아무도 말해주지 않는다. 최소한 그 사실을 화면이 말하게 하는 후속 항목이 필요 |
| **(ii) `EditCardView`의 피커에 `in: Date()...`를 넣는다** | 한 줄로 끝나고 두 경로가 함께 막힌다. **그러나 AI 카드의 동작도 함께 바뀐다** — REQ-041의 "AI 카드 무변경"에 예외 절이 붙고 acceptance.md에 대응 항목이 생긴다 |
| **(iii) `EditField`에 범위를 싣는다** | 화면마다 다른 범위를 줄 수 있어 가장 유연하지만 모델이 커지고, 지금 그 유연함을 원하는 두 번째 호출자가 없다 |

**기본값은 (i)**다 — CLAUDE.md가 "추출 중 개선하고 싶은 것이 보이면 하지 않고 후속 항목으로 적는다"고 하고, (ii)는 t1이 D-3에서 "AI 카드의 관측 가능한 변화는 전부 밖"으로 판정한 것과 같은 성격이기 때문이다. 운영자가 (ii)를 고르면 REQ-041에 예외 절을 달고 AC-008에 대응 항목을 추가한다.

## 5. 관련 문서

- 루트 [plan.md](../../../plan.md) §Phase 1.7 — 설계 원본. 계획이 실제와 달라지면 그 파일을 그 자리에서 갱신한다
- [SPEC-UIKIT-001](../SPEC-UIKIT-001/spec.md) — 컴포넌트 추출(t1). §4 D-1·D-2가 본 SPEC이 쓰는 표면의 형태를 정했고, plan.md §4가 §1.3의 휴면 계약을 남겼다
- [CLAUDE.md](../../../CLAUDE.md) — 여섯 계약, 한 Day 파일 상한, 드라이버 실행 명령
- `hns-besir-app-verify` 스킬 — 빌드·테스트·설치 명령의 단일 출처. 명령을 새로 만들지 않는다
- `hns-besir-app-hazards` 스킬 — D-3이 가리키는 "조용히 묻히는 실패" 패턴

🗿 MoAI
