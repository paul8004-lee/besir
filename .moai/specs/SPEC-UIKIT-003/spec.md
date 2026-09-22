---
id: SPEC-UIKIT-003
title: "활동 두 화면을 편집 카드 컴포넌트로 전환 + 시각 줄 배치 정리 (UI 통일 3/3)"
version: "0.2.1"
status: completed
created: "2026-09-22"
updated: "2026-09-22"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "ui-unification, shared-component, activity, travel-leg, contract-5, contract-6, theme-tokens"
tier: M
related_specs: [SPEC-UIKIT-001, SPEC-UIKIT-002, SPEC-UIKIT-004, SPEC-ONTIME-001]
kanban_card: t3
---

# SPEC-UIKIT-003 — 활동 두 화면을 편집 카드 컴포넌트로 전환 + 시각 줄 배치 정리 (UI 통일 3/3)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-22 | 최초 작성. 칸반 카드 t3 본문(활동 화면 둘 + 2026-09-20 사용자 확인 중 요청 ①②③)을 GEARS로 정식화. 인용 줄번호는 워크트리 `t3`의 베이스 `30be9ad` 실측이며, 세는 명령을 각 REQ에 함께 적었다 — SPEC-UIKIT-001 HISTORY 0.1.1이 어림 인용 27건으로 run 단계를 없는 코드로 보냈던 것이 이 관례가 생긴 이유다 |
| 0.2.0 | 2026-09-22 | **D-3 해소(운영자 "올림" 확정)** — REQ-014(가는 편 도착 여유 줄) 신설로 REQ 15건. 리드는 `REQ-015`로 불렀으나 §2.2가 010번대라 슬롯은 **REQ-014**다(015를 쓰면 §0 예산표의 대역이 깨지고 014가 빈 번호로 남는다). 이름만 다르고 내용은 요청 그대로. **이 결정이 §1.4의 휴면 결함을 깨웠다** — `currentBasis`(`EditCardView.swift:168`)의 `?? .departure` 폴백 때문에 기준 없는 시각이 확정되는 순간 `departureAnchored`가 참이 되어, 새로 생긴 여유 줄이 **영구히 흐려지고 "출발 기준이라 쓰지 않아요"가 붙는다.** REQ-003이 예방에서 **관측 가능한 결함의 수리**로 격상됐고 REQ-014의 선행 조건이 됐다. 인용 정정 1건: D-3의 여유 옵션 출처가 `AddEventView:227-230`이 아니라 **`:223-226`**이다(0.1.0 작성 시 grep이 아니라 읽은 출력에서 눈으로 어림한 유일한 자리) |
| 0.2.1 | 2026-09-22 | **sync 단계 종료 — 3-phase close(`completed`).** 이 sync는 문서만 만지고 끝나지 않았다. ① 독립 렌즈(code-safety `--deep`)가 확정 결함 **MAJOR-A**를 냈다 — `confirmedPlaces: [String: Place]` 하나를 장소 줄 셋이 공유해 같은 상호의 다른 지점을 두 줄에 고르면 좌표가 뒤바뀌고, 활동이 고른 적 없는 좌표로 저장되며 출발지==도착지 0분 구간과 활동 시작 시각 출발 알림이 생긴다. **REQ-021("좌표가 값과 함께 온다")의 미충족**이고 §1.2 결함이 형태만 바꾼 것이라(`:121`이 이미 경고한 경로) 범위 밖이 아니다. 리드가 기계적 사실 일곱을 직접 재확인했고 운영자 판정으로 카드가 run으로 되돌아갔다. ② 수정: 두 파일에서 사전 열쇠를 이름 → **줄 신원(`EditField.id`)**으로, 즐겨찾기는 별도 씨앗 사전으로 분리, 쓰기 자리를 파일당 한 줄로 모아 "검색이 즐겨찾기를 이긴다"를 호출 순서가 아닌 **구조**로 고정. 구현자가 스케치에 없던 함정(다리 줄 재생성 시 신원이 바뀌어 좌표를 잃는 경로)을 `reseed`/`forgetPlaces`로 함께 막았다. MINOR-C(없는 메커니즘을 가리키던 주석)도 정정. 렌즈 권고를 받아 `confirmedPlace`의 **fail-closed 절을 복원**했다(잘못된 장소보다 없는 장소가 낫다 — 방어를 먼저 걷어내지 않는다). ③ 렌즈 **재판정 GO**, 새 결함 0건. ④ 게이트 4종을 최종 트리에서 다시 실측 — 드라이버 **205/205**·iOS/macOS **Swift 소스 경고 0**·프록시 **7/7**·신규 소스 0·파일 넷·`?? 0` 0. ⑤ 루트 `CHECKLIST.md` 인용 수리 10좌표 12자리(판정 집계 102·8·2·1 불변), 루트 `plan.md` t3 행 done + 후속 **13건**, `progress.md` §E.3 중복 스텁 제거. ⑥ AC 매트릭스 — ✅ 3(AC-004·007·009) · 🟡 6(기계 몫 충족·AC-010 관측 대기) · ⬜ 1. **시뮬레이터가 조건에 든 AC는 ✅로 올리지 않았다.** ⑦ 후시 선언 (e)(f)(g)와 AC-008 F-3: 운영자 승인. ⑧ 나머지 두 화면(`AddEventView`·`AIAssistant`)의 같은 이름-키 부류는 **카드 t6**로 등록. ⑨ sync가 두 번 틀렸고 둘 다 사유째 기록했다 — 파일별 줄 수를 실측 없이 §E.2에서 옮겨 적은 것(렌즈가 반증), AC-006을 "시뮬레이터 대기"로 적었으나 실제로는 기계적 결함이 있던 것. run 단계의 문서 커밋 둘(`8cbc47a`·`3dc3a76`)은 HISTORY 행 없이 지나갔고, 빠진 행을 소급 발명하지 않고 이 행이 그 사실을 적는다. 근거·이월은 `progress.md` §E.4. |

## 0. 이 SPEC의 성격

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §Phase 1.7이고 본 SPEC은 그것을 재발명하지 않는다. 인용 줄번호는 변경 전 상태(`30be9ad`) 기준이라 구현 중 밀린다 — 밀릴 때마다 실측 재정렬한다.

**UI 통일 세 장 중 마지막이다.** t1(SPEC-UIKIT-001)이 컴포넌트를 뽑아 AI 카드를 전환했고, t2a(SPEC-UIKIT-002)가 `AddEventView`를, t4(SPEC-UIKIT-004)가 `EventDetailView` 크롬을 전환했다. 남은 것이 활동 쪽 두 화면이다. **`AddEventView` 전환이 본 SPEC의 본보기이며 그 판단을 다시 하지 않는다** — 카드 신원 고정, 조건부 줄의 멤버십 표현, 화면 소유로 남기는 것의 경계는 SPEC-UIKIT-002 REQ-020~022가 이미 정했고 여기서는 활동 쪽 차이만 새로 판단한다.

**활동이 일정과 다른 점은 둘이지 하나가 아니다.** 카드 본문은 "이동 다리(leg)가 붙는 점"만 들었는데, 실측하면 하나가 더 있다: **활동의 시작·종료는 기준(도착/출발)이 없는 시각**이다. 이동 일정의 시각 줄은 `arr:`/`dep:` 접두를 반드시 갖는다(`EditCard.swift:65-77`). 다리는 새 컴포넌트 표면 없이 흡수되지만(§2.2 REQ-011), 기준 없는 시각은 컴포넌트가 모르는 모양이라 표면이 하나 는다(§2.1 REQ-001). 카드 본문이 명시하지 않은 차이이므로 여기 적어 둔다.

**REQ 예산 — 15건으로 상한(16) 아래다.** 세는 명령은 `grep -c '^- \*\*REQ-' spec.md`이고 값은 **15**여야 한다: §2.1 3건(001~003) · §2.2 **5건(010~014)** · §2.3 2건(020~021) · §2.4 2건(030~031) · §2.5 3건(040~042). D-3 해소로 REQ-014가 들어와 **여유가 1건 남았다** — 한 건만 더 늘면 상한이므로, 그 지점부터는 분할 신호로 읽는다.

**드라이버 초록은 이 SPEC에서 증거가 되지 못한다.** `Tools/GuardDriver.swift`는 SwiftUI 뷰를 컴파일 대상으로 삼지 않으므로 카드 렌더링·제스처·접근성 낭독은 가드 밖이다. 205/205 초록 다음 날 실기기 결함 7건이 나온 이력이 있다. acceptance.md의 실기기 항목이 대체 불가능한 증거다.

## 1. 배경

### 1.1 측정된 어긋남 (`30be9ad` 실측)

네 편집 화면 중 셋이 카드 문법을 쓰는데 활동 둘만 옛 문법이다. 옛 문법의 내용물:

- `AddActivityView`(267줄) — `TextField`(`:78`) · `PlaceField` 3곳(`:50`·`:102`·`:110`) · `DatePicker` 2개(`:86-87`) · `Toggle` 4개(`:99`·`:107`·`:141`·`:144`) · 세그먼트 `Picker`(`:126-132`). 폼 값이 `@State` **12개**(`:14-29`, 진행 깃발 `saving` 포함 13개)에 흩어져 있고 제출 판정은 별도 계산 프로퍼티 `canSave`(`:35-41`)다.
- `ActivityDetailView`(222줄) — `Form`/`Section`(`:37-78`) · `TextField` 2개(`:39`·`:42`) · 즐겨찾기 `Menu`(`:44-53`) · `DatePicker` 2개(`:57-58`). 편집값이 `@State` **5개**(`:11-15`)에 있고 `load()`(`:106-113`)가 채우고 `save()`(`:115-129`)가 되읽는다.

계약 6(색은 전부 `Theme` 토큰) 위반은 두 파일에서 **10건**이다 — `AddActivityView` 4건(`:125`·`:206`·`:213`·`:245`), `ActivityDetailView` 6건(`:63`·`:172`·`:180`·`:194`·`:197`·`:201`). 세는 명령: `grep -c "\.secondary\|\.tertiary\|\.quaternary" Shared/AddActivityView.swift Shared/ActivityDetailView.swift`.

### 1.2 `ActivityDetailView`의 장소 편집은 좌표를 잃는다 (실측된 결함)

`:117-120`이 장소를 이렇게 만든다 — `Place(name: locationName, address: locationAddress, latitude: a.location?.latitude ?? 0, longitude: a.location?.longitude ?? 0)`. 이름만 바꾸고 좌표는 **옛 장소의 것을 그대로 쓴다.** "집"을 "회사"로 고치면 이름은 회사, 좌표는 집이다. 그 좌표를 읽는 소비자가 이미 있다: 같은 화면의 주변 맛집(`:30-33` `placeCoord` → `:215-221` `loadNearby`)이 회사 이름 아래 집 주변 식당을 보여준다. 카드의 장소 줄은 검색해서 고르는 자리(`EditCardView:280-`)라 좌표가 값과 함께 확정되므로, 전환이 이 결함을 함께 닫는다(REQ-021).

### 1.3 t2a가 t3로 넘긴 두 항목

SPEC-UIKIT-002 §3이 `PlaceField`의 계약 6 위반과 디바운스 부재를 "t3 소관"으로 넘겼다. 본 SPEC이 실측해 판정한다(§4 D-1, REQ-042) — **넘겨받았다는 사실이 그 둘이 결함이라는 증거는 아니다.**

### 1.4 깨어난 결함 — 시각 줄이 둘인 카드의 여유 흐림 (D-3 해소로 활성)

`EditCardView.departureAnchored`(`:74-77`)는 `card.fields.first(where: { $0.kind == .datetime })` 한 줄만 보고 카드 전체의 여유 줄 흐림(`:142`·`:149`)을 정한다. 시각 줄이 하나뿐인 지금은 맞다. 활동 카드는 **시작·종료 두 장**을 들므로 이 전제가 깨진다.

**0.1.0에서는 휴면이었다** — 활동 카드에 `.buffer` 줄이 없어 판정 결과를 쓰는 곳이 없었다. **D-3이 "올림"으로 확정되면서 깨어났다.** 경로를 끝까지 따라가면 이렇다:

1. `first(where: { $0.kind == .datetime })`가 활동 카드의 **시작 줄**을 고른다(배열 첫 시각 줄).
2. 시작 줄은 기준이 없으므로 확정값이 접두 없는 ISO다 → `parseDatetime`이 `(prefix: "", …)`로 푼다(REQ-001 (a)).
3. `BesirTime.anchor(ofPrefix: "")`는 **nil**이다 — 여기까지는 의도대로다.
4. 그런데 `currentBasis`(`:168`)가 `… .flatMap { BesirTime.anchor(ofPrefix: $0.prefix) } ?? .departure`로 **nil을 `.departure`로 덮는다.**
5. 따라서 `departureAnchored`가 **참**이 되고, 새로 생긴 여유 줄은 시작 시각이 확정되는 순간부터 **영구히 흐려지며 "출발 기준이라 쓰지 않아요"(`:143`)가 붙는다.**

관측되는 증상은 "방금 만든 여유 줄을 고칠 수 없다"이고, 원인은 두 화면 밖의 공유 컴포넌트에 있다. **내 변경이 무엇을 망가뜨렸는지가 아니라 무엇을 도달 가능하게 만들었는지**를 묻는 자리다. REQ-003은 이 때문에 예방이 아니라 **수리**이며 REQ-014의 선행 조건이다.

`?? .departure` 폴백 자체는 **고치지 않는다.** 기준 있는 줄에서는 옳은 방어이고(손상된 접두를 출발로 보는 편이 안전하다), 고치면 기존 두 화면의 동작이 함께 바뀐다. REQ-003은 **누구에게 묻는가**를 고쳐 폴백에 닿지 않게 한다.

## 2. 요구사항 (GEARS)

### 2.1 컴포넌트 표면 확장 (001번대)

- **REQ-001 (Ubiquitous)**: The field model shall support a datetime row that carries no arrival/departure basis. `EditField`에 `var anchored: Bool = true`를 더하고, `anchored == false`인 `.datetime` 줄은 기준 칩 없이 시각만 고른다. 기본값이 있으므로 기존 생성부는 한 줄도 바뀌지 않는다 — `.datetime` 줄을 만드는 곳은 `AddEventView:218`과 `AIAssistant:590` **2곳뿐**이고 둘 다 기준이 있는 줄이다(세는 명령: `grep -rn "kind: .datetime" Shared/`가 2건). 네 경로를 함께 고친다:
  - (a) **해석** — `BesirTime.parseDatetime`(`EditCard.swift:65-77`)의 접두 목록을 `["arr:", "dep:", ""]`로 넓혀 접두 없는 정규 ISO도 `(prefix: "", date:)`로 푼다. **빈 문자열은 반드시 마지막**이다: `hasPrefix("")`는 항상 참이라 앞에 두면 `arr:`가 영영 도달하지 않는다. 파서를 새로 만들지 않는 이유는 그 파일이 자기 존재 이유로 적어 둔 것과 같다(`:9-11`, 계약 5).
  - (b) **기준 매핑** — `BesirTime.anchor(ofPrefix:)`(`:79-86`)는 **고치지 않는다**. `default: return nil`이 이미 `""`를 "기준 없음"으로 답한다.
  - (c) **글자** — `customLabel`의 `.datetime` 가지(`:172-177`)에 남아 있는 삼항 `$0.prefix == "arr:" ? "도착 " : "출발 "`을 `BesirTime.anchor(ofPrefix:)` 경유로 바꾼다(nil이면 접두어 없이 시각만). 그 삼항이 남아 있는 한 접두 해석이 두 곳이고, `""`가 들어오면 **"출발"이라고 거짓말한다.** 기계적 신호: `grep -c '"arr:" ?' Shared/EditCard.swift`가 **0**.
  - (d) **확정** — `EditCardActions`(`:239-247`)에 `var chooseTimePlain: @MainActor (UUID, Date) -> Bool = { _, _ in false }`를 기본값과 함께 더하고, `datetimeEditor`(`EditCardView:208-233`)의 확인 버튼이 `field.anchored`로 갈라 부른다. `chooseTime`(`:242`)의 `ScheduleAnchor`를 옵셔널로 바꾸지 않는 근거는 §4 D-2에 있다. 기본값이 있으므로 기존 두 생성부(`AIAssistant`·`AddEventView`)는 무변경이다.
  - **`currentBasis`(`EditCardView:167-170`)는 기준 없는 줄에서 nil을 돌려주는 것이 정답이므로 고치지 않는다.** 확인이 `guard let basis = currentBasis(field) else { return }`(`:219`)에서 조용히 멎던 것이 (d)로 갈라지는 이유다 — 갈라지 않으면 활동의 시각 줄은 **확인을 눌러도 아무 일도 일어나지 않는다.**

- **REQ-002 (Ubiquitous)**: The datetime row shall place its basis chips on their own line, ordered departure-then-arrival, with the time chip on a new line below. `datetimeRow`(`EditCardView:181-203`)의 단일 `ChipFlow`를 둘로 나눠 기준 칩 한 줄, 그 아래 시각 칩 한 줄로 둔다. 기준 칩 순서는 `ForEach([ScheduleAnchor.arrival, .departure])`(`:184`)를 `[.departure, .arrival]`로 바꿔 **출발 기준 → 도착 기준**이다. 근거: 2026-09-20 사용자 확인 중 요청 ③. 지금은 셋이 한 `ChipFlow`에 있어 폭에 따라 시각 칩이 기준 칩 옆에 붙었다 아래로 내려갔다 하고, 큰 글씨 설정에서는 줄바꿈 위치가 또 달라진다 — **배치가 폭의 함수인 것이 요청의 실제 내용**이다. `anchored == false`면 첫 줄이 통째로 없다(REQ-001). 이 함수는 공유 컴포넌트라 **AI 카드와 `AddEventView`가 함께 바뀐다** — 요청 ③의 "공유 컴포넌트라 일정 폼·AI 카드에 함께 적용"이 이것이며, 두 화면에 손을 대서 얻는 것이 아니다.

- **REQ-003 (Ubiquitous)**: Basis-driven dimming shall read the row it belongs to, not an arbitrary datetime row. `departureAnchored`(`:74-77`)의 `first(where:)`가 카드 전체를 대표하던 전제를 없앤다 — 여유 줄의 흐림(`:142`·`:149`)은 **기준이 있는 시각 줄**을 보고 정한다(`first(where: { $0.kind == .datetime && $0.anchored })`). 근거: §1.4. **D-3이 "올림"으로 확정되면서 이 REQ는 예방이 아니라 관측 가능한 결함의 수리가 됐고, REQ-014의 선행 조건이다** — 순서를 뒤집어 여유 줄을 먼저 만들면, 그 줄은 태어나자마자 고칠 수 없는 상태로 흐려진다.
  - 활동 카드에는 **기준 있는 시각 줄이 하나도 없으므로** 고친 뒤 `first(where:)`는 nil을 돌려주고 `guard … else { return false }`가 걸려 여유 줄이 흐려지지 않는다 — 가는 편은 도착 기준 구간이라 여유를 실제로 쓰므로 이것이 맞는 결과다.
  - 기계적 신호: `grep -c "kind == .datetime })" Shared/EditCardView.swift`가 **0**.

### 2.2 `AddActivityView` 전환 (010번대)

- **REQ-010 (Ubiquitous)**: The card shall be the single source of the form's input. `title`·`locationPlace`·`startDate`·`endDate`·`addOutbound`·`originPlace`·`addReturn`·`returnPlace`·`outboundMode`·`returnMode`·`notifyEnabled`·`syncToCalendar` 12개 `@State`(`:14-29`)를 `@State private var card: EditCard?` 하나로 대체하고, 제출 판정은 `canSave`(`:35-41`)를 버리고 `card.isReady`(`EditCard.swift:224`)를 쓴다. 좌표는 `chosen`(String)에 담기지 않으므로 `AddEventView`와 **같은 형태**로 푼다 — `confirmedPlaces[name] = place` 사전을 화면이 들고 즐겨찾기 옵션 생성과 `choosePlace` 시점에 즉시 채운다. 지연 해석 함수를 만들지 않는다(계약 5: `AIAssistant.resolvePlace`의 세 번째 구현이 된다).

- **REQ-011 (Ubiquitous)**: Travel legs shall be expressed as row membership, adding no new component surface. "가는 이동"·"오는 이동" 두 `Toggle`(`:99`·`:107`)은 `.toggle` 줄 둘(`outbound_enabled`·`return_enabled`)이 되고, 켜질 때 장소 줄 + 수단 줄이 배열에 **들어가고** 꺼질 때 **빠진다** — `AddEventView`가 `notify_enabled` → `notify_lead_minutes`에 쓴 그 경로(SPEC-UIKIT-002 REQ-022(b))를 그대로 쓴다. 근거: 카드 본문의 "그 차이를 컴포넌트의 옵션으로 흡수하고 화면마다 따로 계산하지 않는다"는 지시를, **이미 있는 옵션(동적 멤버십)으로** 이행하는 것이 가장 적은 표면이다. 섹션·그룹 개념을 카드에 새로 만들지 않는다. 요청 ①("'이동 일정 함께 만들기' 화면도 같은 UI로 통일")이 이 REQ로 닫힌다 — 별도 화면이 아니라 같은 카드의 줄들이 되므로 통일이 배치가 아니라 **구조**로 성립한다.
  - 꺼진 동안의 값은 화면이 기억했다 다시 켜질 때 되심는다(`AddEventView`의 `lastNotifyLead` 형태). 되심지 않으면 토글을 껐다 켠 사용자가 방금 고른 출발지를 잃는다.
  - 장소가 아직 없으면(`:95` `locationPlace == nil`) 다리 줄 자체가 생기지 않는다 — 지금의 "장소를 정하면 이동도 함께 만들 수 있어요"(`:96`)는 **없는 줄을 설명하는 말**이므로 장소 줄의 `note`로 내려간다.

- **REQ-012 (Ubiquitous)**: The travel legs' notification lead shall be a card row, not a constant. `defaultNotify = 30`(`:33`)을 없애고 `notify_lead_minutes` 줄(`kind: .notify`)을 `notify_enabled`가 켜져 있을 때만 배열에 둔다. 옵션은 `AddEventView.notifyLeadRow`(`:246-252`)와 **같은 넷**(출발 시각·10분 전·30분 전·1시간 전)에 직접입력 허용이다 — 두 폼이 다른 보기를 내면 같은 값을 두 문법으로 배우게 된다. 근거: 요청 ②("그 화면에서 알림 세부설정 가능하게 — 현재 불가"). `Store.addActivityWithTravel`은 `notifyLeadMinutes: Int`를 **이미 받고 있으므로**(`Store.swift:212`) Store 쪽 변경은 없다 — 값이 없던 게 아니라 화면이 묻지 않았을 뿐이다.
  - 캡션 `"여유 \(defaultBuffer)분 · 알림 \(defaultNotify)분 전"`(`:116`)은 **통째로 사라진다** — D-3 해소로 두 값이 모두 줄이 되므로 캡션에 남길 것이 없다(REQ-014). 줄로 물어놓고 캡션으로 또 말하면 둘이 어긋날 자리가 생긴다. 정보 손실 0: 캡션이 보여주던 두 값이 이제 보이고 **고칠 수도 있다**.

- **REQ-014 (Ubiquitous)**: The outbound leg's arrival buffer shall be a card row, named for the leg it actually applies to. `defaultBuffer = 10`(`:32`)을 없애고 `buffer_minutes` 줄(`kind: .buffer`)을 다리 줄과 같은 동적 멤버십으로 둔다 — `outbound_enabled`가 켜져 있을 때만 배열에 있다. 옵션은 `AddEventView`의 여유 줄(`:223-226`)과 **같은 넷**(0·10·20·30분)에 직접입력 허용이다. 근거: 2026-09-22 운영자 D-3 확정("올림"). 알림만 줄이 되면 캡션에 여유만 남아 **하나는 고칠 수 있고 하나는 못 고치는** 모양이 된다.
  - **줄 이름은 "가는 편 도착 여유"다 — "도착 여유"가 아니다.** `Store.addActivityWithTravel`이 복귀 구간의 버퍼를 `bufferMinutes: 0`으로 **박아 두기 때문이다**(`Store.swift:238`). 이름에서 "가는 편"을 빼면 줄이 오는 편에도 적용된다고 말하는 것이고, 그건 거짓말이다. `AddEventView`의 "도착 여유"와 이름이 다른 유일한 자리이며, 다른 이유가 코드에 있다.
  - **오는 편의 `0`은 그대로 둔다.** 줄을 둘로 늘리거나 Store 시그니처를 바꾸지 않는다 — 요청은 여유를 **묻는 것**이지 복귀 구간의 정책을 바꾸는 것이 아니다. `Shared/Store.swift`는 여전히 무변경이다(REQ-041).
  - **REQ-003이 선행 조건이다.** 이 줄이 REQ-003 없이 태어나면 §1.4의 경로대로 시작 시각이 확정되는 순간 흐려져, **만들자마자 고칠 수 없는 줄**이 된다.

- **REQ-013 (Ubiquitous)**: The screen shall keep the card's identity stable and keep outside it exactly what the card cannot own. 세 절:
  - (a) 카드는 `.task`에서 **정확히 한 번** 만들어 `@State`에 저장한다. 계산 프로퍼티로 만들지 않는다 — `EditField.id`가 인스턴스마다 새 `UUID`라 `EditCardView`의 지역 상태 다섯(`:20-27`)이 매 렌더 초기화되고 **장소 이름을 한 글자도 칠 수 없다**(SPEC-UIKIT-002 REQ-021(a)가 겪은 자리).
  - (b) `EditCardView`는 `ScrollView` 루트의 고정 위치에 무조건 놓고 `Group`·`AnyView`·가변 `.id`로 감싸지 않는다. 지금의 조건부 섹션(`:95` `if locationPlace == nil`, `:100`·`:108`·`:115`·`:138`·`:140`·`:143`)은 전부 줄 멤버십으로 옮겨간다.
  - (c) 화면 header(`:66-73`)와 footer(`:150-163`)는 그대로 남고 `EditCardChrome(header: nil, confirmTitle: nil)`로 카드 쪽 크롬을 끈다 — 끄지 않으면 제목이 둘, 제출 버튼이 둘이다.

### 2.3 `ActivityDetailView` 전환 (020번대)

- **REQ-020 (Ubiquitous)**: The card shall own the activity's editable values, and the screen shall keep what is not editing. 카드가 갖는 줄은 넷이다 — 제목(`.title`) · 장소(`.place`) · 시작(`.datetime`, `anchored: false`) · 종료(`.datetime`, `anchored: false`). `@State` 5개(`:11-15`)와 `load()`(`:106-113`)의 되읽기가 카드 생성 한 번으로 대체된다. **화면 소유로 남는 것**: 반복 회차 안내(`:60-65`) · 주변 맛집 섹션(`:66-68`·`:143-221`) · 삭제 버튼과 두 확인 대화상자(`:69-77`·`:93-101`) · 툴바(`:85-92`). 근거: `AddEventView`가 `ConflictBanner`를 카드 밖 화면 소유로 남긴 것과 같은 경계(SPEC-UIKIT-002 REQ-022(c)) — 카드는 **인자를 묻는 물건**이지 화면이 아니다.
  - `Form`/`Section` 크롬은 `AddEventView`·`AddActivityView`와 같은 `ScrollView` + `Theme.bg` 형태로 맞춘다. 네 화면 중 이 하나만 `Form`인 것이 t3가 닫는 마지막 어긋남이다.
  - 저장은 지금처럼 `store.modifyActivity`(`Store.swift:301-330`)를 부른다 — `updateActivity`를 직접 부르면 묶인 이동 구간이 제자리에 남는다(`:121-122` 주석이 이미 겪은 일로 적어 둔 것).

- **REQ-021 (Ubiquitous)**: Editing the place shall carry its coordinates. 장소 줄이 `.place` 줄이 되면서 §1.2의 결함이 닫힌다 — 고른 장소의 좌표가 `confirmedPlaces`에서 값과 함께 온다. `:117-120`의 `latitude: a.location?.latitude ?? 0`는 사라진다. 기계적 신호: `grep -c "?? 0" Shared/ActivityDetailView.swift`가 **0**.
  - 즐겨찾기 `Menu`(`:44-53`)는 장소 줄의 **즐겨찾기 칩**으로 대체된다 — 같은 값을 고르는 두 문법이 한 앱에 남지 않게 한다.
  - 좌표가 실제로 바뀌므로 주변 맛집의 `nearbyLoaded` 결과는 낡는다. 장소를 다시 고르면 `nearby`·`nearbyLoaded`를 비운다 — 비우지 않으면 새 장소 이름 아래 옛 장소의 식당이 남는다(§1.2의 증상이 형태만 바꿔 살아남는 경로다).

### 2.4 보존해야 할 것 (030번대)

- **REQ-030 (Ubiquitous)**: The conversion shall lose no user-visible affordance, and each changed form shall be named. 대조 단위는 acceptance.md의 절이며 일괄 판정하지 않는다. 명시적으로 형태가 바뀌는 셋:
  - (a) **종료 시각의 범위 제한이 예방에서 거절로 바뀐다.** 지금은 `DatePicker(..., in: startDate...)`(`AddActivityView:87`·`ActivityDetailView:58`)가 시작보다 앞선 값을 **고를 수 없게** 막는다. 카드의 `datetimeEditor`(`EditCardView:208-233`)에는 범위가 없으므로 고를 수는 있고 확인에서 거절된다(`chooseTimePlain`이 `false`). 거절의 보임새는 **줄 `note`("종료는 시작보다 뒤여야 해요") + 에디터 유지 + 확정 안 됨**이다(M5 실측). "그 값은 쓸 수 없어요" 캡슐(`:133-137`)은 텍스트 직접입력 경로 전용이라 시각 줄에는 도달하지 못한다 — 캡슐을 시각 경로에 추가하면 공유 컴포넌트의 거절 문법이 둘이 된다. 거절 문구에 유효 범위를 나열하지 않는 것은 여전히 규칙이다. 컴포넌트에 범위 옵션을 새로 만들지 않는 근거: 표면 하나를 늘려 얻는 것이 거절 한 번을 없애는 것뿐이다.
  - (b) **이동수단 세그먼트 피커가 칩이 된다**(`AddActivityView:123-134` → `.mode` 줄 둘). 정보 손실 0 — `TransportMode.title`이 같은 글자를 담는다. 아이콘(`:128`)은 사라진다(SPEC-UIKIT-002 REQ-030(a)와 같은 판정).
  - (c) **즐겨찾기 `Menu`가 칩이 된다**(REQ-021). 목록이 길면 메뉴는 스크롤하고 칩은 감긴다 — 도달성은 같고 탭이 하나 준다.
  - 사라지지 않는 것으로 특히 확인할 것: 활동 장소가 **선택**이라는 성질(`:50` "장소 (선택)"). 장소 줄이 `isReady`에 걸리면 장소 없는 활동을 만들 수 없게 된다 — `isReady`는 `chosen != nil`을 전수로 보므로(`EditCard.swift:224`) 장소 줄은 **비어 있어도 되는 줄**로 다뤄야 한다. 이 SPEC은 그 방법을 "장소를 고르지 않으면 줄을 만들지 않는다"가 아니라 **"'장소 없음' 칩을 옵션으로 둔다"**로 정한다 — 줄이 없으면 장소를 나중에 더할 길이 화면에서 사라진다.

- **REQ-031 (Ubiquitous)**: The converted screens shall carry the component's accessibility contract and name what they lose. 근거(실측): 두 화면의 접근성 호출과 `@ScaledMetric`은 각각 **0건**이므로(`grep -c "accessibility\|ScaledMetric"`) 컴포넌트가 가진 것(줄 단위 그룹 낭독 `EditCardView:151-153`, 선택 상태 3중 표현, `.isSelected` 특성 `:269`, 칩 높이 iOS 44/macOS 28 `:29-33`)은 전부 순증이다.
  - **잃는 것을 숨기지 않는다**: 세그먼트 `Picker`의 "조정 가능" 특성과 좌우 스와이프 선택, `Toggle` 넷의 스위치 특성, `Form`의 섹션 헤더 랜드마크 낭독이 사라진다. 대체 경로는 전부 칩 탭이며 도달 가능한 값은 같다.

### 2.5 검증과 범위 경계 (040번대)

- **REQ-040 (Ubiquitous)**: The conversion shall pass the project gate on both platforms and on a real device. 네 절: (a) AI 인자 가드 드라이버 전체 초록, **단언 추가 없음** — 본 SPEC은 AI 툴 인자를 건드리지 않는다. (b) iOS·macOS 양쪽 **무경고** 빌드(툴체인 경고 제외). (c) `cd proxy && npm test` 전체 통과. (d) **새 소스 파일을 만들지 않는다** — 따라서 `xcodegen generate`가 필요 없고 **서명 계정 리셋도, 두 타깃의 Team 재선택 요청도 없다.** 기계적 신호: `git diff --name-only --diff-filter=A origin/master...HEAD -- 'Shared/*.swift'`가 0건.

- **REQ-041 (Unwanted)**: This SPEC shall not modify anything outside its four files. `Shared/AddActivityView.swift` · `Shared/ActivityDetailView.swift` · `Shared/EditCard.swift` · `Shared/EditCardView.swift` 넷 외의 소스 파일이 한 줄도 바뀌지 않는다 — 특히 `AIAssistant.swift` · `AddEventView.swift` · `AIChatView.swift` · `Store.swift` · `FullSirView.swift`는 무변경이다. 근거: `anchored`와 `chooseTimePlain` 둘 다 기본값을 가지므로 기존 생성부가 바뀔 이유가 없고, 바뀌었다면 기본값을 빠뜨린 것이다. REQ-002·003의 변경은 공유 컴포넌트 **안**에서 일어나 호출부에 닿지 않는다. 전환 중 눈에 띈 개선은 코드가 아니라 루트 `plan.md`의 후속 항목으로 적는다.

- **REQ-042 (Unwanted)**: `PlaceField` shall neither move nor gain a debouncer; only its colour contract is repaired. 세 절:
  - (a) **옮기지 않는다.** `AddActivityView`가 카드로 바뀌면 이 파일의 `PlaceField` 호출 3곳(`:50`·`:102`·`:110`)이 사라지지만 `FullSirView`의 3곳(`:107`·`:366`·`:379`)이 남는다. 타입을 옮기면 문서 인용이 어긋난다 — t1이 `CHECKLIST` 인용 179건을 어긋낸 방식이고, 얻는 것은 파일 이름의 정합뿐이다.
  - (b) **디바운서를 붙이지 않는다.** t1 §1.1이 "디바운스 부재"로 적었으나 실측하면 **결함이 아니다**: `PlaceField`의 검색은 `.onSubmit`(`:229`)과 버튼 탭(`:230`) 두 경로뿐이고 `onChange`가 **0건**이다(`grep -c "onChange" Shared/AddActivityView.swift`). 글자마다 부르지 않으므로 디바운서가 막을 할당량 소모가 애초에 없다. 붙이면 아무것도 막지 않는 정책이 두 번째 소유자를 갖는다(계약 5 역방향 위반).
  - (c) **계약 6 위반 3건만 고친다** — `:206`·`:213`·`:245`의 `.secondary`·`.quaternary`를 `Theme.muted`·`Theme.raised`로 바꾼다. 파일을 이미 열어 두므로 비용이 0에 가깝고, t2a가 넘긴 항목 중 실재하는 것이 이것뿐이다.

## 3. Out of Scope

- **`ActivityDetailView`의 주변 맛집 섹션**(`:143-221`) — be full sir Phase 1 소관이다. 계약 6 위반 5건(`:172`·`:180`·`:194`·`:197`·`:201`)이 여기 남으며, 본 SPEC은 세어 두기만 한다. `AddEventView`가 `ConflictBanner`의 위반 2건(`:601`·`:604`)을 남긴 것과 같은 경계다.
- **복귀 구간의 여유를 묻는 것** — `Store.swift:238`이 `0`으로 박아 둔 정책은 그대로다. D-3은 여유를 **묻는 줄**을 들여왔을 뿐 복귀 구간의 값을 바꾸지 않는다(REQ-014).
- **반복 활동 생성** — AI 채팅 소관이고 이 화면은 단발성 전용이다(`:4-5`).
- **데드 코드 정리**(`Store.addActivity(title:)` 등) — **카드 t5**. 본 SPEC의 전환으로 줄번호가 밀리므로 t5가 plan에서 grep 재실측한다.
- 출시 전 제거할 테스트용 코드(`deleteEverythingForTesting`·`transcriptForDebugging`) — 별건.

## 4. 결정 기록

### D-1 — `PlaceField`가 t3로 넘어온 두 항목 — **해소됨**

t2a §3이 계약 6 위반과 디바운스 부재를 넘겼다. 실측 결과 **전자는 실재하고 후자는 아니다**(REQ-042 (b)). 넘겨받은 항목을 확인 없이 착수했다면 아무것도 막지 않는 디바운서를 하나 더 만들 뻔했다. 거처는 그대로 두고 색만 고친다.

### D-2 — 기준 없는 시각의 확정 경로 — **해소됨**

두 안이 있었다. **A안**: `EditCardActions.chooseTime`의 `ScheduleAnchor`를 옵셔널로 바꾼다 — 개념은 깨끗하지만 생성부 둘(`AIAssistant`·`AddEventView`)과 그 안쪽 함수 시그니처가 따라 바뀌어 **파일이 5~6개**가 되고 CLAUDE.md의 한 Day 상한(3~4)을 넘는다. **B안(채택)**: 기본값을 가진 `chooseTimePlain`을 더한다 — 기존 생성부 무변경, 파일 4개 유지. 뷰가 `field.anchored`로 한 곳에서 갈라므로 분기가 흩어지지 않는다. A안은 t3 이후 활동·일정 카드가 모두 안정된 뒤의 정리 항목으로 루트 `plan.md`에 남긴다.

### D-3 — 이동 다리의 '여유'도 줄로 올릴지 — **해소됨 (2026-09-22 운영자 "올림")**

카드 본문의 요청 ②는 **알림만** 들었다. 그런데 캡션(`:116`)은 여유와 알림을 나란히 보여주므로, 알림만 줄이 되면 **"하나는 고칠 수 있고 하나는 못 고치는"** 캡션이 남는다. 두 안을 올려 운영자가 재질문 뒤 **올림**을 골랐다(리드 전달).

채택안의 내용은 REQ-014다 — `.buffer` 줄 하나(옵션은 `AddEventView:223-226`과 동일)가 늘고 캡션이 통째로 사라진다. 이름은 **"가는 편 도착 여유"**다(`Store.swift:238`이 복귀 구간 버퍼를 `0`으로 박아 두므로, "가는 편"을 빼면 줄이 거짓말을 한다).

**결정이 결함을 하나 깨웠다.** 0.1.0은 §1.4를 "휴면"으로 적고 "지금 증상 0건"이라고 했는데, 여유 줄이 생기는 순간 `currentBasis`의 `?? .departure` 폴백(`EditCardView.swift:168`)을 타고 **관측 가능한 결함**이 된다 — 새 여유 줄이 시작 시각 확정과 동시에 영구히 흐려진다. REQ-003이 그래서 예방에서 수리로 격상됐고 REQ-014의 선행 조건이 됐다. 0.1.0이 "D-3의 결과와 무관하게 REQ-003을 둔다"고 적어 둔 것이 이 자리에서 값을 했다.

**인용 정정**: 0.1.0은 여유 옵션의 출처를 `AddEventView:227-230`으로 적었으나 실측은 **`:223-226`**이다. 이 SPEC에서 grep이 아니라 읽은 출력에서 눈으로 어림한 유일한 줄번호였고, 정확히 그 하나가 틀렸다.

## 5. 관련 문서

- 루트 [`plan.md`](../../../plan.md) §Phase 1.7 — 설계 원본
- [SPEC-UIKIT-001](../SPEC-UIKIT-001/spec.md) — 컴포넌트 추출(t1). `EditField`·`EditCard`·`EditCardView`의 계약
- [SPEC-UIKIT-002](../SPEC-UIKIT-002/spec.md) — `AddEventView` 전환(t2a). **본 SPEC의 본보기**이며 REQ-020~022가 전환 판단의 원본
- [SPEC-UIKIT-004](../SPEC-UIKIT-004/spec.md) — `EventDetailView` 크롬 통일(t4). `BesirTime` 포매터 단일화
- [CHECKLIST.md](../../../CHECKLIST.md) — 사용자 관점 요구사항. 전환으로 인용 줄번호가 밀리면 sync에서 수리한다
