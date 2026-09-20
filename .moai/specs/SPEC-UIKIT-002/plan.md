# SPEC-UIKIT-002 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 설계 원본은 루트 `plan.md:411` §Phase 1.7.
> 루트 `plan.md`는 "계획이 실제와 달라지면 그 자리에서 갱신"하는 1차 참조 문서다 — 본 카드의
> 2a/2b 분할(2026-09-18 운영자 확정)을 같은 커밋에서 반영했다(분할표 t2 행 정정 + t4 행 신설).

## 0. Tier 판단

**Tier: M**

- 근거: 건드리는 파일 **4개** — `Shared/AddEventView.swift`(전환 본체, 550줄) + `Shared/EditCard.swift`(컴포넌트 표면 확장 + 디바운서 이동) + `Shared/EditCardView.swift`(토글 칩·busy 표시·크롬 옵션) + `Shared/AIAssistant.swift`(디바운서 교체만). 문서 갱신 1종(루트 `plan.md` 분할 정정).
- **REQ 14건 · AC 9건** — 실측 명령과 함께: `grep -c '^- \*\*REQ-' spec.md` = **14**, `grep -c '^## AC-' acceptance.md` = **9**. `spec-workflow.md:149`의 Tier M 상한(REQ 16 / AC 16) 아래다. REQ 여유 2건은 D-3이 미해소라 예외 절이 붙을 수 있어 남겨둔 것(spec.md §0). **REQ 16 도달 또는 파일 5개는 분할 신호** — 그때는 t4처럼 새 카드로 뺀다.
- Tier L이 아닌 이유: Tier L은 >1000 LOC 또는 >15파일(`spec-workflow.md:142`). 본 카드는 4파일이고 AddEventView 전환이 사실상 재작성이라도 같은 파일 안에서 일어난다.
- `design.md`/`research.md`는 Tier L 전용 — 설계 검토는 `ui-design` 협의(2026-09-18, spec.md §4 D-2)와 본 세션의 재실측으로 갈음했다.

## 1. 마일스톤

의사결정 가변성 순서(컴포넌트 표면 → 기계적 이동 → 전환 본체 → 대조·게이트). 실행 순서도
의존성상 동일하다: M1 → M2 → M3 → M4 → M5.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1·D-2·문서) | — | 설계 확정 — 카드 분할(A안)·컴포넌트 표면 형태 확정, SPEC 3종 완결. **D-3(과거 시각)만 미해소로 남는다** — run 착수 전 운영자 결정(spec.md §4, 기본값 (i)) | 🟢 |
| M2 | REQ-001~004 | AC-001 | 컴포넌트 표면 확장 — `Kind.toggle`(칩 재사용 + `chosen` seed), `Option.detail`·`EditField.busy`, `startsOpen`, `EditCardChrome`. **전부 기본값을 갖는 추가**라 `AIChatView`·`AIAssistant` 팩토리는 한 줄도 안 바뀐다 | 🟢 |
| M3 | REQ-010~011 | AC-002·AC-003 | 디바운서 단일화 — 지연(350ms)·취소·같은 질의 스킵을 값 타입 하나로 `EditCard.swift`에 옮기고 `AIAssistant.searchPlaces`가 그것을 쓴다. **드라이버 P-4·P-5·P-6이 옮김의 기계적 증거**(단언 추가 없음) | 🟢 |
| M4 | REQ-020~023 | AC-004·AC-005 | `AddEventView` 전환 — `@State card: EditCard` 하나(+`confirmedPlaces` 사전), `canSave`→`isReady`, `.task` 1회 생성, header/footer·`ConflictBanner`는 카드 밖 유지, `depFmt`→`BesirTime.compact` | 🟢 |
| M5 | REQ-030~031, REQ-040~041 | AC-006~009 | 보존 대조와 게이트 — 어포던스 **29절 개별 대조**(일괄 통과 금지), 접근성 순증·후퇴 명시, 무경고 빌드 양쪽, 드라이버 전체 초록, 프록시, 시뮬레이터·실기기 | 🟢 |

## 2. 알려진 이슈 / 리스크

- **D-3(과거 시각)이 run 착수 전 운영자 결정거리다.** 전환하면 폼에서 과거 일정이 만들어지고
  알림만 조용히 안 걸린다(`NotificationManager.swift:34`). 기본값 (i)(그대로 둔다)이지만,
  운영자가 (ii)(피커에 범위)를 고르면 REQ-041에 예외 절 + AC-008에 항목이 붙는다 — **M4 시작 전에
  확정한다.** 결정을 run 세션이 조용히 내리지 않는다.
- **카드 정체성이 이 전환의 1급 리스크**(REQ-021). `EditCardView`의 지역 상태 다섯(`customOpen`·
  `draft`·`rejected`·`draftBasis`·`draftDate`, `EditCardView.swift:17-24`)이 전부 `field.id`(UUID)를
  키로 쓴다(`:344`·`:355`·`:365-366`). 카드를 계산 프로필로 만들거나 `Group`·조건문으로 한 겹 싸거나
  `.id(...)`를 붙이면 **장소 이름을 한 글자도 칠 수 없다**(매 렌더마다 키가 새로生겨 draft가 비움).
  반증 신호: 타이핑 중 에디터가 닫히거나 글자가 지워진다.
- **휴면 계약의 첫 명시적 이행**(spec.md §1.3). `EditCardView`는 아무것도 관찰하지 않는 순수 값
  뷰라, 소유 화면이 자기 상태를 바꿔야 재렌더가 일어난다. `AIChatView`는 부모가 `assistant`를
  관찰해 자연히 성립했지만 `AddEventView`는 **동작 클로저가 `card`의 원소를 고치고, 값 타입
  재할당으로 재렌더를 일으키는** 형태를 스스로 만들어야 한다(REQ-021 (a)). `location.isLocating`·
  `estimating`도 `.onChange`로 `busy`에 명시적으로 잇는다(REQ-021 (c)) — 잊으면 동작은 돌지만
  진행 표시가 안 뜬다.
- **`currentLocationToken`은 `private`이다**(실측 `AIAssistant.swift:2342`). AI 카드의 출발지
  "현재 위치" 옵션 value(`__current_location__`)를 `AddEventView`에서 재사용할 수 없다. 본
  카드의 기본 방향은 **토큰 없이 즉시 채우기** — `AddEventView`의 "현재 위치 사용"(`:116-123`·
  `:438-447`)은 선택 시각에 `Place`를 만들어 `confirmedPlaces`에 바로 넣는 방식이라 사후 해석
  경로가 아예 없다(REQ-020). 토큰 승격은 AI 쪽 방어 주석(`:46-47` — 내부 토큰이 인자로 새어 나간
  전례)과 얽힌 변경이므로 기각 목록에 남긴다.
- **디바운서는 드라이버 컴파일 집합의 SwiftUI-free 경계를 지켜야 한다.** `EditCard.swift`는
  CLAUDE.md 드라이버 `swiftc` 인자 목록(11파일)에 이미 들어 있다. 새 디바운서 타입이 그 파일에
  살려면 `Task`·`UUID`·`Dictionary`까지만 쓸 수 있고 `Color`·`View`·`@State`가 한 건이라도 들어가면
  드라이버가 못 돈다(t1이 모델과 뷰를 다른 파일로 나눈 이유). 기계적 신호:
  `grep -c '^import SwiftUI' Shared/EditCard.swift` = **0** 유지.
- **`AIAssistant`에 허용되는 변경은 `searchPlaces`의 디바운스 경로뿐**(REQ-041). `setLookup` 호출
  (`:769`·`:773`·`:782`)과 `maxPlaceSuggestions` 자르기(선언 `:755`·사용 `:783`)는 AI 쪽 의미라
  따라가지 않는다 — 중립 파일이 AI의 일을 가져가면 계약 4(새 AI 클래스 금지)의 뒷면을 어긋난다.
  기계적 신호: `grep -rc "350_000_000" Shared/` 합이 **1**, 소재는 `EditCard.swift`.
- **`syncToCalendar` 줄의 "정적 조건" 근거는 실측이다**(REQ-022 (b)). `store.config`를 바꾸는 유일한
  경로가 `Store.updateConfig`(`:1476-1479`)이고 호출부가 `SettingsView.swift:95` 한 곳이라, 추가
  시트가 열려 있는 동안 값이 바뀔 수 없다. 이 근거가 깨지면(다른 호출부 생기면) 정적 조건이 아니게
  되니 run에서 다시 확인한다.
- **하네스 배정**(CLAUDE.md "작업을 시작할 때", 매번 적용):
  - M2 — `ui-design`(토글 칩·`detail`·busy·크롬 옵션의 표현), `swift-impl`(모델 확장)
  - M3 — `ai-tooling`(`AIAssistant.searchPlaces` 변경과 드라이버 P 계열 초록 확인)
  - M4 — `swift-impl`(전환 본체), `ui-design`(29절 중 형태가 바뀌는 셋의 승인)
  - M5 — `code-safety`(구현 변경 후), `ux-check`(시뮬레이터·실기기 목록)

## 3. 검증 계획

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AI 인자 가드 | CLAUDE.md의 드라이버 블록(인자 변동 없음 — 새 파일 0개) | 전체 초록, **단언 추가 없음** — 특히 P-1~P-7 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED`, 툴체인 경고 제외 무경고 |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 (본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다) |
| 시뮬레이터 | 입력 문구 + 기대 결과를 정확히 준 스크립트 방식(초기화 시점 포함) | AC-009 시뮬레이터 목록 전부 |
| 실기기 | `-allowProvisioningUpdates` → `devicectl device install app` → `process launch` | AC-009 실기기 전용 항목 |

`hns-besir-app-verify` 스킬이 이 명령들의 단일 출처다 — 명령을 새로 만들지 않고 그 스킬을 돈다.
**`xcodegen generate`는 돌리지 않는다**(새 소스 파일 0개, REQ-040 (d)) — 따라서 서명 Team 재선택
요청도 없다. 이 문장이 지워져 있으면 새 파일을 만든 것이다(REQ-041 위반).

## 4. 후속 (본 SPEC 밖)

- **카드 t4** — `EventDetailView` 크롬 통일 + 시각 포매터 `clock`·`stepTime` 신설. 본 카드가 done된
  뒤 착수. 본 카드가 `BesirTime.compact`를 만들어 두면 t4의 포매터 단일화가 절반 줄어든다.
- **카드 t3** — 활동 화면 둘(`AddActivityView`·`ActivityDetailView`). t4 이후.
- 루트 `plan.md` 후속 항목으로만 남는 것 — 본 카드가 고치지 않는 것: `PlaceField`의 계약 6 위반·
  디바운스 부재(t3), `AIChatView`의 계약 6 우회 4건(t1 D-3 확정), D-3 선택지 (i)을 택했을 때
  "과거 일정에는 알림이 안 걸린다"를 화면이 말하게 하는 후속 항목.

🗿 MoAI
