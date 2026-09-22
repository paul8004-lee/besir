---
id: SPEC-UIKIT-005
title: "장소 좌표 사전의 이름-키 충돌 수리 — `AddEventView`·`AIAssistant` (잔여 두 화면)"
version: "0.1.0"
status: in-progress
created: "2026-09-22"
updated: "2026-09-22"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "place-coordinates, systemic-regression, confirmed-places, ai-tooling, contract-5, follow-up-t3"
tier: M
related_specs: [SPEC-UIKIT-003, SPEC-UIKIT-002, SPEC-ONTIME-001]
kanban_card: t6
---

# SPEC-UIKIT-005 — 장소 좌표 사전의 이름-키 충돌 수리 (`AddEventView`·`AIAssistant`)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-22 | 최초 작성. 칸반 카드 t6 본문과 루트 `plan.md` 후속 8번(t3 sync의 `--deep` 렌즈가 올린 계통 회귀)을 GEARS로 정식화. **인용 줄번호는 전부 이 워크트리(`t6`)의 베이스 `c5396b3`에서 명령을 돌려 얻었고, 세는 명령을 각 자리에 함께 적었다** — SPEC-UIKIT-001 HISTORY 0.1.1이 어림 인용 27건으로 run 단계를 없는 코드로 보낸 것이 이 관례가 생긴 이유다. 카드 본문의 "**화면마다 같은 4줄 수정**"은 실측으로 **깨졌다**: `AddEventView`는 t3보다 **작은** 수정이고(§1.4), `AIAssistant`는 t3의 수정을 **받을 수 없다**(§1.5). 둘 다 근거를 명령과 함께 적었다. `AIAssistant` 쪽 기법은 미해소 — §4 D-1에 두 안을 기록하고 B안을 권고하되, 착수 승인 게이트용 미해소 표식은 `plan.md` §2에만 둔다(`spec.md`·`acceptance.md`에는 두지 않는 관례). **인용 정정 1건**: §4 D-1 A안의 "같은 조회를 이미 하는 자리"를 `:740-741`로 적었으나 실측은 **`:738-739`**다(`:740`은 `chosen` 대입, `:741`은 닫는 괄호) — plan 레인의 독립 재측정이 잡아 §4 본문을 고치고 세는 명령(`grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift`)을 붙였다. 이 SPEC에서 명령 출력이 아니라 읽은 코드에서 눈으로 센 유일한 줄번호였고, **정확히 그 하나가 틀렸다.** 나머지 인용은 레인의 재측정과 전부 일치했다 |
| 0.1.1 | 2026-09-22 | D-1 해소 — 운영자가 B안(확정 시점 이름 구분) 채택. §4 D-1 머리말·서두를 해소 문구로 바꾸고 frontmatter `status`를 draft → in-progress로(run 단계 전이). 인용 줄번호 변동 없음 — 코드는 아직 한 줄도 안 바뀌었다. 게이트 기록·AC-005 정리 경위는 progress.md §E.1에 있다 |

## 0. 이 SPEC의 성격과 예산

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §Phase 1.7 후속 8번이고 본 SPEC은 그것을 재발명하지 않는다. 인용 줄번호는 변경 전 상태(`c5396b3`) 기준이라 구현 중 밀린다 — 밀릴 때마다 실측 재정렬한다.

**t3의 수정이 본보기이지 복사 대상이 아니다.** 카드 본문은 "`AddActivityView`·`ActivityDetailView`는 t3에서 사전 키를 줄 신원(`EditField.id`)으로 수정 중 — 그 수정을 본보기로 삼는다 … **화면마다 같은 4줄 수정**"이라고 적었다. 본보기라는 지시는 맞다. **같은 4줄이라는 셈은 틀렸고**, 그 사실이 이 SPEC의 척추다(§1.4·§1.5). 본보기의 다섯 요소 중 몇을 옮기고 몇을 버리는지를 화면마다 근거와 함께 정한다.

**Tier: M.** 파일은 둘(+가드 드라이버 단언 갱신 가능성)이라 S처럼 보이지만, S는 `acceptance.md` 없이 `spec.md §3`에 AC를 인라인하는 등급이다. 이 카드는 그 등급에 들지 않는다 — 근거는 **실측된 표면의 크기와 미해소 설계 분기**다:
- `AIAssistant.swift`가 **2443줄**이고(`wc -l`), 장소 줄이 **5개**이며(`grep -c "kind: .place"` = 5), 좌표를 되읽는 자리가 **3곳**(`:2322`·`:2371`·`:2393`), 그 셋을 부르는 호출부가 **12곳**이다(§4 D-1).
- 기법이 **미해소**다 — A안과 B안이 비용·위험이 다르고, 어느 쪽이든 되돌리기 비싼 결정이다. 착수 승인 게이트에서 운영자가 고른다.
- 좌표는 **화면에 보이지 않는다.** 그래서 관측 가능한 증거의 설계 자체가 작업이며, `acceptance.md`가 그 자리다.

**REQ 예산 — 11건으로 상한(16) 아래다.** 세는 명령은 `grep -c '^- \*\*REQ-' spec.md`이고 값은 **11**이어야 한다: §2.1 4건(001~004) · §2.2 3건(010~012) · §2.3 3건(020~022) · §2.4 1건(030). AC는 `grep -c '^## AC-' acceptance.md` = **9**.

**드라이버 초록은 이 SPEC의 증거로 반만 센다.** `Tools/GuardDriver.swift`는 `AIAssistant.swift`를 컴파일 대상에 넣으므로(이 워크트리 `CLAUDE.md` § 빌드 · 배포의 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`) **AI 인자 경로는 가드 안**이다 — t3와 다른 점이다. 하지만 좌표 사전은 뷰 상호작용으로 채워지고 드라이버는 SwiftUI 뷰를 컴파일하지 않으므로, **"두 줄에 같은 이름의 다른 지점을 고른다"는 조작 자체는 가드 밖**이다. AC-009(시뮬레이터·실기기)가 대체 불가능한 증거다.

## 1. 배경

### 1.1 계통 회귀의 형태 — 넷 중 둘이 닫혔고 둘이 남았다 (`c5396b3` 실측)

네 편집 표면이 "고른 장소의 좌표를 화면이 사전에 들고 있다가 저장할 때 되찾는다"는 같은 형태를 쓴다. 열쇠가 **이름**이면 장소 줄 여럿이 한 사전을 공유하게 되어, 같은 상호의 다른 지점을 두 줄에 고르면 나중 쓰기가 앞 좌표를 덮는다.

```
$ grep -n "\[UUID: Place\]" Shared/AddActivityView.swift Shared/ActivityDetailView.swift
Shared/ActivityDetailView.swift:20:    @State private var confirmedPlaces: [UUID: Place] = [:]
Shared/AddActivityView.swift:24:    @State private var confirmedPlaces: [UUID: Place] = [:]
$ grep -n "\[String: Place\]" Shared/AddEventView.swift Shared/AIAssistant.swift
Shared/AddEventView.swift:19:    @State private var confirmedPlaces: [String: Place] = [:]
Shared/AIAssistant.swift:49:    private var confirmedPlaces: [String: Place] = [:]
```

앞 둘은 t3(`d5203cb`)가 줄 신원 키로 닫았다. 뒤 둘이 이 카드다. 각 화면이 든 장소 줄의 수:

| 화면 | 장소 줄 | 세는 명령과 값 |
|---|---|---|
| `AddEventView` | 2 — `origin_query`(`:158`) · `destination_query`(`:160`) | `grep -c "kind: .place" Shared/AddEventView.swift` = **2** |
| `AIAssistant` | 5 — `origin_query`(`:550`) · `destination_query`(`:564`) · `place_query`(`:572`) · `return_to_query`(`:580`) · `travel_from_query`(`:606`) | `grep -c "kind: .place" Shared/AIAssistant.swift` = **5** |

**한 카드에 장소 줄이 둘 이상 서는 경로가 실재한다.** `askFields`(`:464`)를 읽으면 툴별로 이렇다 — `create_schedule`은 `destination_query` + `origin_query` **2줄**, `create_recurring_schedule`도 같은 **2줄**, `create_activity`는 `place_query` + `travel_from_query` + `return_to_query` **3줄**이다. 줄이 하나뿐이면 이름 키도 겹칠 수 없으므로, 이 세 툴이 결함의 도달 경로다.

### 1.2 왜 같은 이름이 실제로 겹치는가 — 코드가 이미 세 자리에서 말한다

같은 이름의 서로 다른 지점은 예외가 아니라 **검색 결과의 정상 모양**이고, 코드가 그 사실을 세 자리에서 이미 적어 두었다.

- **`Shared/Models.swift:108`** — `Place`가 `Hashable`인 이유를 적은 주석: "장소 검색 결과 목록은 이름이 겹칠 수 있어(같은 상호의 다른 지점) 좌표까지 포함한 값 전체로 구분해야 `ForEach`에서 두 곳이 한 줄로 합쳐지지 않는다." 목록 렌더링은 이름으로 구분하면 안 된다고 이미 판정해 두었는데, 좌표 사전은 그 판정 밖에 있었다. 세는 명령: `grep -n "이름이 겹칠 수 있어" Shared/Models.swift`.
- **`Shared/PlaceSearch.swift:126`** — MapKit 폴백이 `Place(name: item.name ?? p.name ?? query, …)`를 만든다. 최종 폴백이 **질의 문자열 자체**이므로, 한 결과 목록 안에서 같은 이름이 여러 번 나올 수 있다. 세는 명령: `grep -n "item.name ?? p.name ?? query" Shared/PlaceSearch.swift`.
- **`Shared/AIAssistant.swift:2317`** — `resolveOrigin` 안의 주석: "검색하면 모호한 이름(\"스타벅스\")이 다른 지점으로 잡혀, 사용자가 고른 곳과 등록된 곳이 달라진다 — 화면에는 같은 이름이 찍혀 있어 알아챌 방법도 없다." **이 주석이 경고하는 바로 그 일이, 사전 열쇠가 이름이라는 이유로 사전 안에서 일어난다.** 세는 명령: `grep -n "모호한 이름" Shared/AIAssistant.swift`.

### 1.3 하류에 잡는 장치가 없다 — 경로마다 증상이 다르다 (실측)

```
$ grep -rn "isSamePlace" Shared/
Shared/AIAssistant.swift:1297:        if Self.isSamePlace(origin, dest) {
Shared/AIAssistant.swift:1613:        //    이동 구간이 생긴다(`isSamePlace` 가드는 create_schedule 경로 전용).
Shared/AIAssistant.swift:2279:    private static func isSamePlace(_ a: Place, _ b: Place) -> Bool {
$ grep -n "isSamePlace\|origin == \|sameCoord" Shared/Store.swift
(0건)
```

가드는 **한 자리에서만 불린다**(`:1297`). 그 자리가 `create_schedule` 핸들러 안이라는 것은 추정이 아니라 `:1613`의 주석이 **직접 적어 둔 사실**이다. `Store`에는 출발지==도착지 검사가 없다. 따라서 열쇠 충돌의 증상은 경로마다 갈린다:

| 경로 | 장소 줄 | 충돌 시 증상 |
|---|---|---|
| `AddEventView` (화면) | 2 | 두 줄이 한 좌표가 되어 이동시간이 **0분**으로 잡히고, 출발 알람이 도착 시각에 붙는다. 화면엔 이름만 보인다 |
| `create_schedule` | 2 | `isSamePlace`(`:1297`)가 걸려 **"출발지와 목적지가 '스타벅스'으로 같아요"**로 거절된다 — 사용자는 두 지점을 분명히 골랐는데 거절당하므로, 조용하지는 않으나 **정당한 요청이 막히는** 모양이다 |
| `create_recurring_schedule` | 2 | 가드 없음 → 0분짜리 반복 구간이 **주 단위로 복제**된다(기본 `weeks` 8). 118건 사고(`:2384-2386` 주석)와 같은 폭발 반경이다 |
| `create_activity` | 3 | 가드 없음 → 0분짜리 이동 구간 + 활동 시작 시각에 붙는 출발 알람. **화면상 신호 0** |

**이 표가 카드 본문의 "화면상 신호 없음"을 정정한다** — 신호가 없는 것은 셋 중 둘이고, `create_schedule`은 신호가 있되 **엉뚱한 신호**다.

### 1.4 발견 A — `AddEventView`는 t3보다 **작은** 수정이다 (실측)

t3의 수정은 다섯 요소로 이루어졌다(`d5203cb`):

1. `confirmedPlaces: [UUID: Place]` — 줄 신원 키 (`AddActivityView:24`, 주석 `:18-23`)
2. 즐겨찾기 씨앗 별도 사전 `favoritePlaces: [String: Place]` (`:28`, 씨앗 `:129`)
3. **파일당 쓰기 자리 하나** — `choose(field:value:place:)`(`:170`)의 `:179` `if c.fields[i].kind == .place { confirmedPlaces[field] = place ?? favoritePlaces[value] }`
4. **fail-closed 읽기** (`:493-494`) `field(key).flatMap { $0.chosen == nil ? nil : confirmedPlaces[$0.id] }`
5. `reseed`(`:299-302`) / `forgetPlaces`(`:306-308`)

**5번은 `AddEventView`로 옮겨오지 않는다.** 그 요소가 t3에 필요했던 이유는 `AddActivityView`가 다리 토글에서 장소 줄을 **빼고 다시 넣기** 때문이다(`forgetPlaces` 호출 `:198`·`:227`·`:248`) — 되심은 줄은 새 `UUID`라 옛 좌표를 잃는다. `AddEventView`에는 그 경로가 없다:

```
$ grep -n "fields.remove" Shared/AddEventView.swift
266:                    c.fields.remove(at: li)
```

유일한 제거가 `notify_lead_minutes`, 즉 `.notify` 줄이다(`:247` `notifyLeadRow`). 장소 줄은 `buildCard()`(`:147`)에서만 만들어지고, `buildCard()`는 `bootstrap()`의 `guard card == nil`(`:136`) 뒤 `:137`에서 **정확히 한 번** 불린다. 뒤늦게 줄을 더하는 `ensureGatedRows()`(`:185`)는 `!hasTimeRow` 뒤에서 **덧붙이기만** 하고, 그 함수가 붙이는 `gatedRows(…)`(`:215`)에는 `.place` 줄이 없다(`grep -n "kind: \." Shared/AddEventView.swift`의 `:218`·`:220`·`:223`·`:228`·`:238`·`:247` 어느 것도 `.place`가 아니다). **장소 줄의 신원은 시트가 사는 동안 바뀌지 않는다** — 그러므로 `reseed`도 `forgetPlaces`도 막을 것이 없다.

**대신 열쇠 교체만으로는 부족한 자리가 셋 있다.**

**(가) 즐겨찾기 씨앗이 줄에 매이지 않는다.** `:149`가 `for fav in store.favorites { confirmedPlaces[fav.label] = fav.place }`로 같은 사전에 라벨을 심는다. 라벨은 줄의 것이 아니라 즐겨찾기 목록의 것이고, **출발지 줄과 목적지 줄이 같은 즐겨찾기 칩을 고를 수 있다**(`:150-151`이 `originOptions`에, `:161-162`가 목적지 옵션에 같은 `store.favorites` 라벨을 싣는다). 줄 신원 사전과 합칠 수 없다 — t3의 2번이 그대로 필요하다.

**(나) 칩 탭 경로에는 지금 쓰기 자리가 아예 없다.** `choose(field:value:)`(`:256`)는 `confirmedPlaces`에 한 번도 쓰지 않는다:

```
$ grep -n "confirmedPlaces" Shared/AddEventView.swift
17: (주석)   19: (선언)   149: (즐겨찾기 씨앗)   165: (편집 목적지 씨앗)
169: (편집 출발지 씨앗)   305: (choosePlace 쓰기)   425: (현재 위치 쓰기)   512: (읽기)
$ grep -c "confirmedPlaces\[" Shared/AddEventView.swift
6
```

즐겨찾기 칩이 지금 동작하는 것은 **`chosen`에 라벨이 들어가고 그 라벨이 사전 열쇠이기 때문**일 뿐이다(`:512` `field(key)?.chosen.flatMap { confirmedPlaces[$0] }`). 열쇠를 줄 신원으로 바꾸면 **이 경로가 통째로 죽는다** — 즐겨찾기를 고른 일정이 좌표 없이 저장된다. 그래서 t3의 3번(쓰기 자리 하나)을 **새로 들여와야** 하며, 이것은 "열쇠 교체"가 아니라 순증이다.

**(다) 현재 위치 확정이 줄 신원을 쥐기 전에 쓴다.** `confirmCurrentLocationAsOrigin(_:)`(`:420`)이 `:425`에서 `confirmedPlaces[Self.hereMarker] = Place(…)`로 **무조건** 쓰고, 출발지 줄의 인덱스는 **그다음** `:427` `if var c2 = card, let i = c2.fields.firstIndex(where: { $0.key == "origin_query" })` 안에서야 손에 들어온다. 줄 신원이 열쇠가 되면 순서가 뒤집혀야 하고, `card`가 nil이면 **열쇠 자체가 없다**. 실측으로 두 호출 경로 모두 `card` 비-nil이다 — `:410`(`prefillOrigin()` `:405` 안, 그 함수는 `bootstrap()`의 `:137` `card = buildCard()` 뒤 `:144`에서 불린다)과 `:396`(`useCurrentLocationAsOrigin()` `:394` 안, 그 함수는 `choose`의 `guard var c = card`(`:257`)를 통과한 `:282`·`:286`에서만 불린다). 그래도 **정의된 동작을 적어 둔다** — 지금은 쓰기가 무조건이고 줄 인덱스 찾기가 조건부라, 둘을 합치면 조건성이 드러나기 때문이다.

**(라) `:165`/`:169`의 편집 씨앗은 줄 신원을 이미 쥐고 있다.** 둘 다 `buildCard()` 본문 안이고, 그 시점에 `fields`는 지역 `var` 배열이다(`:155-163`에서 `title`·`origin_query`·`destination_query` 순으로 만들어진다). 목적지 줄은 `fields[2]`, 출발지 줄은 `fields[1]`이므로 `.id`가 그 자리에서 읽힌다. **run 단계가 이걸 다시 발견하지 않도록 여기 적는다.**

### 1.5 발견 B — `AIAssistant`는 t3의 수정을 **받을 수 없다** (load-bearing)

세 화면에서 되읽기 경로는 `줄 → 줄.id → 사전 → Place`다. `AIAssistant`에서는 **`툴 인자(모델을 거쳐 온 String) → 사전 → Place`**다. 되읽는 세 자리 어디에도 줄이 스코프에 없다:

| 자리 | 시그니처 | 읽는 식 |
|---|---|---|
| `:2309` `resolveOrigin(_ query: String? = nil, orDefault: Bool = false)` | `String?` | `:2322` `if let confirmed = confirmedPlaces[q] { return confirmed }` |
| `:2366` `unresolvedGenericPlace(_ raw: Any?)` | `Any?` | `:2371` `if confirmedPlaces[q] != nil { return false }` |
| `:2388` `resolveDestination(_ query: String, creation: Bool = false)` | `String` | `:2393` `if let confirmed = confirmedPlaces[query.trimmingCharacters(in: .whitespaces)] { return confirmed }` |

**`EditField.id`로 열쇠를 바꾸면 이 조회는 좁혀지는 것이 아니라 성립하지 않는다** — 세 함수는 `UUID`를 손에 쥔 적이 없고, 쥘 수도 없다. 쓰기 자리(`:748` `confirmedPlaces[place.name] = place`, `choose(field:place:)` `:747` 안)만 신원으로 바꾸면 읽기가 전부 nil을 돌려받아, 사용자가 카드에서 고른 좌표가 **한 건도** 실행부에 도달하지 않는다. 그 결과는 지금보다 나쁘다 — 확정한 이름이 매번 재검색으로 풀려 `:2317`의 주석이 경고한 바로 그 사고가 상시화된다.

**카드 본문의 "그 수정을 본보기로 삼는다"를 문자 그대로 읽으면 run 단계가 불가능한 편집으로 들어간다.** 그래서 여기 명시한다: **`AIAssistant`에 대해 본보기가 되는 것은 t3의 *불변식*이지 t3의 *열쇠*가 아니다.**

불변식은 SPEC-UIKIT-003 REQ-021("좌표가 값과 함께 온다")과 같다 — **한 대화 안에서 이름 → 좌표 대응은 단사(injective)여야 한다.** 그 불변식을 어떻게 세울지가 §4 D-1의 미해소 분기이며, 두 안 모두 REQ-010~012를 만족해야 한다.

## 2. 요구사항 (GEARS)

### 2.1 `AddEventView` (001번대)

- **REQ-001 (Ubiquitous)**: The screen's confirmed-place dictionary shall be keyed by row identity, and its read shall be fail-closed. `@State private var confirmedPlaces: [String: Place]`(`:19`)를 `[UUID: Place]`로 바꾸고, `confirmedPlace(_:)`(`:511-512`)의 `field(key)?.chosen.flatMap { confirmedPlaces[$0] }`를 t3와 같은 fail-closed 형태 `field(key).flatMap { $0.chosen == nil ? nil : confirmedPlaces[$0.id] }`로 바꾼다(본보기: `AddActivityView:493-494`). 근거: §1.1·§1.4. 기계적 신호: `grep -c "\[UUID: Place\]" Shared/AddEventView.swift`가 **1**, `grep -c "\[String: Place\]" Shared/AddEventView.swift`가 **0**.
  - **fail-closed가 선택이 아닌 이유.** 이름이 열쇠이던 동안에는 `chosen`이 nil인 줄이 사전에 **자연히** 걸리지 않았다(열쇠가 없으니까). 신원이 열쇠가 되면 줄은 언제나 열쇠를 갖고 있으므로, `chosen`을 지운 줄이 **옛 좌표를 계속 들고 있게 된다.** t3가 렌즈 권고로 이 절을 복원한 자리이며(SPEC-UIKIT-003 §HISTORY 0.2.1 ⑥), 빠뜨리면 같은 결함이 형태만 바꿔 살아난다.
  - 읽기 소비자 넷이 이 함수를 통과하므로 자리는 하나다 — `:406`(`prefillOrigin` 가드) · `:444-445`(`recomputeEstimates`) · `:516`(`originCoord`) · `:547-548`(`save()`). 세는 명령: `grep -n "confirmedPlace(" Shared/AddEventView.swift`.

- **REQ-002 (Ubiquitous)**: The favorites seed shall live in its own label-keyed dictionary, separate from the row-identity dictionary. `:149`의 `for fav in store.favorites { confirmedPlaces[fav.label] = fav.place }`를 `favoritePlaces: [String: Place]`로 옮긴다(본보기: `AddActivityView:28`·`:129`). 근거: §1.4 (가) — 라벨은 줄이 아니라 즐겨찾기 목록의 것이고, 출발지 줄(`:158`, 옵션 `:150-151`)과 목적지 줄(`:160`, 옵션 `:161-162`)이 **같은 칩을 고른다.** 기계적 신호: `grep -c "favoritePlaces" Shared/AddEventView.swift`가 **2 이상**(선언 + 씨앗).

- **REQ-003 (Ubiquitous)**: The chip-tap path shall carry exactly one coordinate write site, and a searched place shall structurally beat a favorite seed. `choose(field:value:)`(`:256`)에 `place: Place? = nil`을 더하고, `guard var c = card, let i = …`(`:257`) 직후 한 줄로 `if c.fields[i].kind == .place { confirmedPlaces[field] = place ?? favoritePlaces[value] }`를 둔다. `choosePlace(field:place:)`(`:304-307`)는 자기 자리의 쓰기(`:305`)를 버리고 `place`를 실어 넘긴다(본보기: `AddActivityView:170`·`:179`). 근거: §1.4 (나) — **지금 칩 탭 경로에는 쓰기 자리가 없고**, 열쇠가 신원이 되는 순간 즐겨찾기 경로가 죽는다.
  - **`place ?? favoritePlaces[value]`의 순서가 구조다.** 검색 후보는 지점까지 특정된 값이고 즐겨찾기 라벨은 우연히 같을 수 있는 이름일 뿐이다. 반대로 두면 검색해서 고른 "스타벅스" 홍대점이 즐겨찾기 "스타벅스"의 좌표로 조용히 바뀐다. 쓰기가 **한 자리**여야 이 순서가 호출 순서에 기대지 않는다(계약 5).
  - 둘 다 없으면(둘 다 nil) 그 줄의 좌표는 **nil로 지워진다.** 이름이 열쇠이던 시절엔 열쇠가 바뀌며 저절로 풀리던 자리이므로, 명시로 갚는다.
  - 기계적 신호: `grep -c "confirmedPlaces\[" Shared/AddEventView.swift`가 줄어든다 — 씨앗 둘(`:165`·`:169`) + 쓰기 하나 + 현재 위치 하나 + 읽기 하나 = **5**, 즐겨찾기 씨앗은 `favoritePlaces`로 나갔다.

- **REQ-004 (Ubiquitous)**: Confirming the current location shall write the coordinate only once the origin row's identity is in hand, and the card-absent case shall be defined. `confirmCurrentLocationAsOrigin(_:)`(`:420`)의 `:425` 쓰기를 `:427`의 `if var c2 = card, let i = …` 블록 **안**으로 옮겨 `confirmedPlaces[c2.fields[i].id] = Place(…)`로 쓴다. `Self.hereMarker`(`:34`)는 **`chosen`의 값과 옵션 식별자로만 남고 사전 열쇠에서는 빠진다** — `:151`·`:275`·`:285`·`:415`·`:423`·`:428`·`:432`의 용법은 그대로다. 근거: §1.4 (다).
  - **`card`가 nil이면 좌표를 쓰지 않고 `chosen`도 세우지 않는다.** 실측으로 두 호출 경로(`:396`·`:410`) 모두 `card` 비-nil이므로 관측되는 동작 변화는 없지만, 지금은 쓰기가 무조건이고 인덱스 찾기가 조건부라 **합치는 순간 조건성이 드러난다** — 어느 쪽으로 갈지 코드가 아니라 이 줄이 정한다. 반쯤 확정된 상태(좌표는 있는데 `chosen`이 없는)를 만들지 않는 쪽이다.
  - `:165`/`:169`의 편집 씨앗은 `buildCard()` 본문 안이라 `fields[2].id`·`fields[1].id`가 그 자리에서 읽힌다(§1.4 (라)) — 별도 장치가 필요 없다.
  - 기계적 신호: `grep -c "confirmedPlaces\[Self.hereMarker\]" Shared/AddEventView.swift`가 **0**.

### 2.2 `AIAssistant` (010번대)

> 이 절의 세 REQ는 **기법 중립**이다 — §4 D-1의 A안·B안 어느 쪽을 골라도 셋 다 성립해야 한다. 기법 선택은 `plan.md`의 착수 승인 게이트에서 정해진다.

- **REQ-010 (Ubiquitous)**: Within one conversation, the mapping from a confirmed place's lookup key to its coordinates shall be injective. 한 대화 안에서 서로 다른 좌표를 가진 두 확정 장소가 같은 조회 열쇠를 갖지 않는다. 근거: §1.1·§1.2·§1.5, SPEC-UIKIT-003 REQ-021의 같은 불변식. 지금은 `:748` `confirmedPlaces[place.name] = place` 하나가 이름을 열쇠로 쓰므로 단사가 아니다.
  - **반증 신호(어느 안이든 같다)**: `create_activity`에서 활동 장소와 가는 편 출발지에 같은 상호의 다른 지점을 고르면 이동 구간이 0분으로 만들어진다(§1.3의 표).

- **REQ-011 (Ubiquitous)**: A stored coordinate shall be returned for a query only when that coordinate was confirmed, in this conversation, for that same query. 사전은 대화 범위로 산다 — 지워지는 자리가 `resetConversation()`의 `:217` `confirmedPlaces = [:]` 하나뿐이다(`grep -n "confirmedPlaces = \[:\]" Shared/AIAssistant.swift`). 따라서 **앞 카드에서 확정한 좌표가 뒤 카드의 같은 열쇠에 붙는 경로**가 열려 있고, 열쇠를 인자 슬롯으로 바꾸면(A안) 그 위험이 커진다 — 사용자가 이번 카드에서 확정한 적 없는 이름이 앞 카드의 좌표를 받는다. 저장된 값이 **확정 당시의 질의를 함께 들고**, 되읽을 때 **그 질의가 지금 질의와 같을 때만** 좌표를 돌려주어야 한다.
  - `:2317`의 주석이 "즐겨찾기보다 뒤에 본다"고 정해 둔 우선순위는 바뀌지 않는다 — 즐겨찾기(오래 사는 설정)가 확정 장소(이번 대화만 사는 값)를 이긴다.

- **REQ-012 (Unwanted)**: A disambiguating string shall not reach stored data. 어느 안을 고르든, `Store`에 저장되는 `Place`의 `name`·`address`는 사용자가 고른 장소의 **원래 값**이다. B안처럼 구분용 문자열을 열쇠와 `chosen`에 싣더라도, `resolveDestination`(`:2388`)·`resolveOrigin`(`:2309`)이 돌려주는 것은 **사전에 저장된 `Place` 그 자체**이므로 이름이 오염되지 않아야 한다. 근거: 내부 토큰이 모델·요약 문구로 새어 나간 전례가 두 번 있다(`:44-48` 주석 — 현재 위치·가는 편 없음). 기계적 신호는 저장 경로의 코드 대조와 AC-009 12번이다.

### 2.3 보존과 범위 경계 (020번대)

- **REQ-020 (Unwanted)**: `AddEventView` shall not gain a reseed or forget-places mechanism. t3의 다섯 번째 요소(`AddActivityView:299-302`·`:306-308`)를 **옮겨오지 않는다.** 근거(실측): 이 화면은 장소 줄을 배열에서 빼지 않는다 — `grep -n "fields.remove" Shared/AddEventView.swift`가 `:266` **한 건**이고 그것은 `.notify` 줄이며, `buildCard()`(`:147`)는 `guard card == nil`(`:136`) 뒤 한 번만 불리고 `ensureGatedRows()`(`:185`)가 붙이는 `gatedRows(…)`(`:215`)에는 `.place` 줄이 없다. 붙이면 아무것도 막지 않는 정책이 두 번째 소유자를 갖는다(계약 5 역방향). 기계적 신호: `grep -c "reseed\|forgetPlaces" Shared/AddEventView.swift`가 **0**.

- **REQ-021 (Unwanted)**: This SPEC shall not modify anything outside its two source files and the guard driver. `Shared/AddEventView.swift` · `Shared/AIAssistant.swift` 둘과, 인자 가드 단언이 실제로 바뀔 때에 한해 `Tools/GuardDriver.swift` 셋뿐이다. 특히 **무변경**: `Shared/AddActivityView.swift` · `Shared/ActivityDetailView.swift` · `Shared/EditCard.swift` · `Shared/EditCardView.swift` · `Shared/Store.swift` · `Shared/PlaceSearch.swift` · `Shared/Models.swift` · `Shared/AIChatView.swift` · `Shared/FullSirView.swift`. 근거: 좌표 사전은 화면·어시스턴트가 각자 소유하는 상태이고, 공유 컴포넌트는 `chosen`(String)만 본다. 기계적 신호: `git diff --name-only <base>...HEAD -- 'Shared/*.swift'`가 **정확히 두 파일**.
  - **새 소스 파일을 만들지 않는다** — 따라서 `xcodegen generate`가 필요 없고 **서명 계정 리셋도, `besir-iOS`·`besirShare` 두 타깃의 Team 재선택 요청도 없다.** 기계적 신호: `git diff --name-only --diff-filter=A <base>...HEAD -- 'Shared/*.swift'`가 **0건**. (`Tools/`는 빌드 대상이 아니므로 그 파일이 바뀌어도 `xcodegen`과 무관하다 — 이 워크트리 `CLAUDE.md` § 빌드 · 배포.)
  - 수정 중 눈에 띈 개선은 코드가 아니라 루트 `plan.md`의 후속 항목으로 적는다.

- **REQ-022 (Ubiquitous)**: Nothing user-visible shall change except what the chosen `AIAssistant` design forces. 이 카드는 좌표의 정확성을 고치는 것이지 보임새를 바꾸는 것이 아니다. 화면 배치·칩 문법·줄 구성·문구는 그대로다. **유일한 예외**: §4 D-1에서 **B안이 채택될 경우** 같은 이름이 겹치는 순간에 한해 확정 칩의 글자가 구분용 문자열로 바뀐다. 그 변화는 결함의 최악 성질("화면엔 이름만 보여 알아챌 신호가 없다")을 **의도적으로** 되갚는 것이므로 손실이 아니라 순증이며, 그때에만 `ui-design` 렌즈가 run 단계 명단에 든다(`plan.md` §4).
  - A안이 채택되면 보이는 변화는 **0건**이고, 그 사실 자체가 AC-007의 판정 대상이다.

### 2.4 게이트 (030번대)

- **REQ-030 (Ubiquitous)**: The change shall pass the project gate on both platforms, keep the argument-guard driver green, and update the driver's assertions alongside any argument-behaviour change. 네 절:
  - (a) **AI 인자 가드 드라이버 전체 초록.** 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 블록이 단일 출처이며, 그 컴파일 집합이 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`로 시작하므로 **`AIAssistant.swift`의 모든 변경은 드라이버를 통과해야 한다.** t6 착수 시점 실측 베이스라인은 **205/205 통과**(이 세션이 `c5396b3`에서 직접 실행).
  - (b) **인자 거동이 바뀌면 `Tools/GuardDriver.swift`의 단언도 같이 갱신한다** — 같은 `CLAUDE.md` 문장의 지시이고, 이유와 제약은 그 파일 머리말에 있다. 바뀌지 않으면 손대지 않는다.
  - (c) iOS·macOS 양쪽 **무경고** 빌드. **총계가 아니라 `.swift` 계수로 잰다** — `appintentsmetadataprocessor`의 "No AppIntents.framework" 경고는 전체 빌드에서만 나타나고 어떤 `.swift` 파일도 가리키지 않으므로, 기준은 `grep 'warning:' <build.log> | grep -c '\.swift'`가 **0**이다(`hns-besir-app-verify` SKILL.md의 `grep -v appintentsmetadataprocessor` 필터와 같은 판정을 계수로 적은 것).
  - (d) `cd proxy && npm test` 전체 통과 — 이 SPEC은 프록시를 건드리지 않지만 게이트는 돈다.

## 3. Out of Scope

이 절이 세는 것은 **이 카드가 만들지 않은 결함**이다. 인접한 결함은 요구사항이 아니라 여기에 증거와 함께 적는다.

### Out of Scope — `Store` 수준의 출발지==도착지 검사

- `grep -n "isSamePlace\|origin == \|sameCoord" Shared/Store.swift`가 **0건**이다. 0분짜리 구간을 `Store`가 막지 않는다는 것은 사실이지만, **이 카드가 만든 결함이 아니고** 고치면 활동·일정·반복의 저장 정책이 한꺼번에 바뀐다.
- 이 카드가 열쇠를 고치면 0분 구간의 **원인**이 사라진다. `Store` 방어는 다른 원인에 대한 별도 판단이므로 루트 `plan.md` 후속으로만 남긴다.

### Out of Scope — `isSamePlace` 가드의 적용 범위 확대

- 가드는 `create_schedule` 경로 전용이다(`AIAssistant.swift:1297` 호출, `:1613` 주석이 그 사실을 명시). `create_recurring_schedule`·`create_activity`에 없다는 것은 §1.3의 실측이다.
- **넓히지 않는다.** 이 카드가 닫는 것은 "고른 좌표가 덮인다"이지 "모델이 같은 장소를 두 번 보낸다"가 아니다. 두 결함은 원인이 다르고, 같은 수정으로 닫으면 어느 쪽이 닫혔는지 말할 수 없게 된다.

### Out of Scope — `PlaceSearch`의 이름 생성 방식

- MapKit 폴백의 `Place(name: item.name ?? p.name ?? query, …)`(`Shared/PlaceSearch.swift:126`)가 한 목록 안에서 같은 이름을 여러 번 낼 수 있다는 것이 §1.2의 실측이다.
- **고치지 않는다.** 같은 이름의 다른 지점은 현실이고, 검색이 그것을 숨기는 쪽이 더 나쁘다 — `Models.swift:108`이 이미 "좌표까지 포함한 값 전체로 구분한다"고 정했다. 소비자 쪽에서 구분하는 것이 옳은 방향이며 이 카드가 그 일을 한다.

### Out of Scope — 데드 코드 정리 (카드 t5)

- 본 카드가 두 파일을 수정하므로 t5가 적어 둔 줄번호가 밀린다. t5는 plan에서 grep 재실측하기로 이미 카드 본문에 적혀 있다.

### Out of Scope — 고른 안이 강제하지 않는 모든 시각적 변경

- 확정 칩의 모양·장소 줄 배치·검색 결과 목록의 렌더링은 그대로다(REQ-022). B안이 채택될 때 겹치는 이름에 붙는 구분 문자열만이 유일한 예외다.
- 고른 장소의 주소 상시 표시(루트 `plan.md` 후속 7번)는 여전히 컴포넌트 소관이며 이 카드 밖이다.

### Out of Scope — `ActivityDetailView`의 `.onChange(of: nearbyCategory)` 취소 부재

- 루트 `plan.md` 후속 12번이 t3 sync의 렌즈로 올린 항목이다. **이 카드가 그 파일을 건드리지 않는다**(REQ-021).

### Out of Scope — 출시 전 제거할 테스트용 코드

- `Store.deleteEverythingForTesting()` · `AIAssistant.transcriptForDebugging()` — 별건이다.

## 4. 결정 기록

### D-1 — `AIAssistant`에서 단사성을 어떻게 세울 것인가 — **해소: B안 채택 (2026-09-22 운영자 확정)**

§1.5가 보인 대로 t3의 열쇠(`EditField.id`)는 여기 쓸 수 없다. 두 안이 있었고 **어느 쪽도 자명하지 않아** 착수 승인 게이트로 올라갔으며, 운영자가 **B안**을 골랐다(2026-09-22 — 리드 디스패치로 run 레인에 전달, 경위는 progress.md §E.1). 아래 두 안의 분석은 결정 기록으로 남긴다.

**A안 — 인자 슬롯을 열쇠로.** `AskField.key`(= `EditField.key`, `typealias`는 `:31`)로 건다. 쓰기 자리(`:748`)에서는 `bubbles[b].ask?.fields[f].key`로 손에 넣을 수 있고(같은 조회를 `:738-739`가 이미 한다 — `grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift`), 읽는 자리에서는 각 생성 경로가 슬롯 이름을 **리터럴로 알고 있다**(`input["origin_query"]`·`input["destination_query"]` 등).

- **비용(실측).** 세 해석 함수의 시그니처(`:2309`·`:2366`·`:2388`)에 슬롯을 실어야 하고, 그 셋을 부르는 자리가 **12곳**이다 — `resolveOrigin` 4곳(`:1282`·`:1445`·`:1571`·`:2121`), `resolveDestination` 8곳(`:1292`·`:1435`·`:1446`·`:1574`·`:1620`·`:2062`·`:2124`·`:2172`). 세는 명령: `grep -c "resolveOrigin(" Shared/AIAssistant.swift` = **5**(선언 1 포함), `grep -c "resolveDestination(" Shared/AIAssistant.swift` = **9**(선언 1 포함). `unresolvedGenericPlace`는 호출부가 **4곳** 더 있다(`:474`·`:812`·`:2325`·`:2394`; `grep -c` = **5**, 선언 1 포함).
- **새 위험 — 대화 범위 오염.** 사전은 `resetConversation()`(`:217`)에서만 비워지므로 슬롯 열쇠는 대화가 끝날 때까지 산다. 사용자가 **이번 카드에서 확정한 적 없는 이름**이 뒤 호출에서 같은 슬롯에 실려 오면 **앞 카드의 좌표를 조용히 받는다.** 지금의 이름 열쇠에는 없던 위험이다(이름이 다르면 안 걸렸다).
- **그래서 A안은 저장된 값이 확정 당시의 질의를 함께 들고, 되읽을 때 그 질의가 지금 질의와 같을 때만 좌표를 돌려주는 가드를 반드시 포함한다** — REQ-011이 그 가드를 요구사항으로 박아 둔 이유다. 가드 없는 A안은 결함을 다른 결함으로 바꾼다.

**B안 — 확정 시점에 이름을 구분한다 (권고).** `:748`에서, `place.name`이 이미 **다른 좌표**에 묶여 있으면 결정적인 구분 열쇠(이름 + 주소의 구별되는 조각)로 저장하고 `chosen`도 **같은 문자열**로 세운다.

- **읽는 자리가 하나도 바뀌지 않는다** — `:2322`·`:2371`·`:2393`은 여전히 String 열쇠로 조회한다. 시그니처 셋과 호출부 12곳이 그대로다.
- **모호함이 카드 위에 보이게 된다.** 결함의 가장 나쁜 성질이 "화면엔 이름만 보여 알아챌 신호가 없다"인데, B안은 겹치는 순간 사용자에게 두 줄이 다른 곳임을 **글자로** 보여준다. 수리와 관측 가능성을 한 번에 얻는다.
- **대화 범위 오염이 구조적으로 닫힌다** — 열쇠가 좌표를 구분하는 문자열이므로, 앞 카드의 다른 지점이 뒤 카드의 같은 이름에 붙을 수 없다. REQ-011이 추가 가드 없이 성립한다.
- **비용을 숨기지 않는다.** ① 구분 문자열이 `chosen`에 실려 **모델에게 그대로 간다.** 모델이 그 문자열을 그대로 되돌려주지 않고 **말을 바꾸면**(paraphrase) 사전 조회가 빗나가 새 검색으로 떨어진다 — 그때의 동작은 **이 카드 이전의 모호한 검색 동작**이지 잘못된 확정 좌표가 아니므로, 열화의 방향이 안전한 쪽이다. 그래도 관측 대상이므로 AC-005에 넣는다. ② 구분 문자열이 저장 데이터에 새면 안 된다 — REQ-012가 그것을 막는다. ③ 칩 글자가 바뀌므로 그 경우에만 `ui-design`이 run 단계 명단에 든다(REQ-022).

**권고: B안.** 이유 셋 — 읽는 자리 12곳을 건드리지 않아 회귀 면적이 작다, 대화 범위 오염을 추가 가드 없이 닫는다, 그리고 결함의 **관측 불가능성**을 함께 고친다. A안의 이점(인자와 열쇠의 개념적 일치)은 이 셋보다 가볍다.

**어느 쪽도 "화면마다 같은 4줄"이 아니다.** 카드 본문의 그 셈은 t3의 다섯 요소 중 몇 개가 옮겨갈 수 있는지를 세지 않은 값이고, §1.4·§1.5가 그것을 실측으로 정정했다.

### D-2 — `AddEventView`에 t3의 `reseed`/`forgetPlaces`를 옮길 것인가 — **해소됨 (옮기지 않는다)**

t3의 다섯 요소 중 5번은 **다리 토글이 장소 줄을 빼고 다시 넣는 화면**에만 필요하다. `AddEventView`에는 그 경로가 없다(§1.4 — `fields.remove` 1건이 `.notify` 줄, `buildCard()` 1회 호출, `gatedRows`에 `.place` 없음). 옮기면 아무것도 막지 않는 장치가 하나 더 생기고, 앞으로 누군가 "왜 여기만 있지"를 되물어야 한다. REQ-020이 이 판정이다.

**넘겨받았다는 사실이 필요하다는 증거는 아니다** — t3의 D-1이 `PlaceField` 디바운서에서 같은 판정을 했고, 그때도 실측이 넘겨받은 항목 중 하나를 기각했다.

### D-3 — `AddEventView`의 현재 위치가 `card == nil`일 때 — **해소됨 (쓰지 않는다)**

`:425`의 쓰기는 지금 무조건이고, 줄 인덱스는 `:427`의 `if var c2 = card` 안에서만 잡힌다. 열쇠가 신원이 되면 둘을 합쳐야 하고, 그 순간 "`card`가 없으면?"이 답을 요구한다. 실측으로 두 호출 경로(`:396`·`:410`) 모두 `card` 비-nil이므로 관측 차이는 없지만, **좌표만 있고 `chosen`이 없는 반쯤 확정된 상태를 만들지 않는 쪽**을 택한다 — 그쪽이 REQ-001의 fail-closed 읽기와 같은 방향이다. REQ-004가 이 판정이다.

## 5. 관련 문서

- 루트 [`plan.md`](../../../plan.md) §Phase 1.7 후속 **8번** — 이 카드의 등록 근거(2026-09-22 운영자 승인, t3 병합 후 · t5 앞)
- [SPEC-UIKIT-003](../SPEC-UIKIT-003/spec.md) — 활동 두 화면 전환(t3). **본 SPEC의 본보기**이며 REQ-021이 같은 불변식, §HISTORY 0.2.1이 MAJOR-A의 경위
- [SPEC-UIKIT-002](../SPEC-UIKIT-002/spec.md) — `AddEventView` 전환(t2a). 이 화면이 독립 바인딩을 버리고 이름-키 사전을 들이게 된 자리
- [SPEC-ONTIME-001](../SPEC-ONTIME-001/spec.md) — AI 인자 방어의 원본. `resolveOrigin`/`isSamePlace` 가드가 왜 방어적으로 짜였는지
- [CHECKLIST.md](../../../CHECKLIST.md) — 사용자 관점 요구사항. 수정으로 인용 줄번호가 밀리면 **이 카드가 sync에서 수리한다**(드리프트를 만든 카드가 수리한다는 관례 — t1이 179건을 어긋낸 뒤 생긴 규칙)

🗿 MoAI
