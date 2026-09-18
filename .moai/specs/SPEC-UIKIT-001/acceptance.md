# SPEC-UIKIT-001 — acceptance.md

계획 SPEC이므로 전 AC를 ⬜(미확인)로 시작한다.

본 SPEC은 **순수 추출**이라 통과 조건의 성격이 다른 SPEC과 반대다 — 새 동작이 생겼음을 보이는 것이 아니라 **아무것도 바뀌지 않았음**을 보인다. 그래서 AC 대부분이 "원본과 대조해 같다"의 형태이고, 가드 드라이버도 단언 추가 없이 기존 단언이 초록인 것이 기준이다(REQ-030).

카드 렌더링은 가드 밖이다 — 드라이버는 SwiftUI 뷰를 컴파일 대상으로 삼지 않는다. 그래서 **AC-007(실기기)이 이 SPEC에서 대체 불가능한 증거**이며, "드라이버 초록"으로 갈음할 수 없다(88/88 초록 다음 날 실기기 결함 7건이 나온 이력이 있다).

## AC 매트릭스

| AC | 대응 REQ | 검증 수단 | 상태 |
|---|---|---|---|
| AC-001 | REQ-001~005 | 컴파일 + grep | ⬜ |
| AC-002 | REQ-010~013 | 컴파일 + grep | ⬜ |
| AC-003 | REQ-020 (a~d) · REQ-021 (a~i) | grep + 원본 절별 대조 | ⬜ |
| AC-004 | REQ-022 (a~d) | 원본 절별 대조 + 드라이버 | ⬜ |
| AC-005 | REQ-030 | 드라이버 실행 | ⬜ |
| AC-006 | REQ-040~041 | 변경 파일 대조 + grep | ⬜ |
| AC-007 (실기기) | REQ-031 (d) | 실기기 조작 | ⬜ 리스크 |
| AC-008 (게이트) | REQ-031 (a~c) | 빌드 + 프록시 테스트 | ⬜ |

§2.3·§2.4의 REQ는 절(clause)을 품는다(spec.md §0 "REQ 예산"). **대조는 절 단위**이며, REQ 하나를 통째로 "통과"로 적는 경로는 없다 — AC-003·AC-004의 표가 그 절 목록이다.

---

## AC-001 — 필드 모델이 `AIAssistant` 밖에서 산다 ⬜

- **Given** `AskField`(`Shared/AIAssistant.swift:38-113`)와 `PendingAsk`(`:117-127`)가 `AIAssistant` 안에 중첩돼 있고, `AskField`가 `AIAssistant`의 `private static` 셋(`parseDatetime :1651`·`when :1636`·`isoFormatter :1641`)을 부르고 있으며
- **When** 두 타입이 `Shared/`의 새 파일로 옮겨지면
- **Then** 네 가지가 동시에 성립한다:
  1. `Shared/AIAssistant.swift`에 두 타입의 **정의**가 남지 않는다 — `grep -n "struct AskField\|struct PendingAsk" Shared/AIAssistant.swift`가 0건.
  2. 새 모델 파일에 `import SwiftUI`가 없다 — `grep -c "import SwiftUI" <새 모델 파일>`이 `0`(REQ-003).
  3. 값 해석(`chosenLabel`·`customLabel`·`accepts`)이 **한 곳에만** 있다 — 세 `private static`의 소재를 옮겼든 승격했든, 같은 해석이 두 파일에 나타나지 않는다(계약 5). 대조 방법: 날짜 접두 해석(`"arr:"` 판정)과 카드 왕복 ISO 직렬화가 등장하는 파일은 **`EditCard.swift` 한 곳**이다. ISO 리터럴의 파일 수를 세면 `AIAssistant.swift`의 `parseDate` 때문에 2가 나오지만 그것은 실행부 완화 파서의 선행·합법 발생이지 카드 왕복 직렬화가 아니므로(조건 5) 위반이 아니다.
  4. 가드 드라이버가 컴파일된다 — CLAUDE.md의 `swiftc` 인자 목록에 새 모델 파일이 들어가 있고, 드라이버가 `AskField`/`PendingAsk`를 참조하는 20곳이 모두 해결된다. REQ-005의 별칭 두 줄이 있으면 **`AIAssistant` 본문과 드라이버는 한 줄도 바뀌지 않는다** — 변경 파일 목록에 `Tools/GuardDriver.swift`가 등장하면 별칭이 빠진 것이다.
  5. **날짜 형식이 복제되지 않았다** — 리터럴 `"yyyy-MM-dd'T'HH:mm:ss"`이 `Shared/EditCard.swift`에 **정확히 1건**(카드 왕복 형식의 소유자 `BesirTime`)이고, 추출 diff가 **어느 파일에도 발생을 추가하지 않는다**. `Shared/AIAssistant.swift`의 `parseDate`가 형식 후보 목록으로 갖는 선행 발생분 1건은 **합법적으로 남는다** — 모델이 보낸 ISO 시각을 파싱하는 실행부의 완화 파서지 카드 왕복 형식이 아니며, 건드리면 REQ-041 위반이다. 계획 시점의 "합이 1" 기준은 이 선행 발생분을 못 잰 측정 오류였고 HISTORY 0.2.1에서 시정했다(순수 이동으로는 도달할 수 없는 숫자였다). 기계적 대조: `grep -rc "yyyy-MM-dd'T'HH:mm:ss" Shared/` 합이 **2**(`EditCard.swift` 1 + `AIAssistant.swift` 1)이다 — 늘면 복제(REQ-002), 줄어들면 `parseDate`를 무단 수정한 것이다. 복제의 증상은 훨씬 늦게 온다(카드가 확정한 시각이 실행부 파싱에서 실패). 드라이버도 빌드도 이것을 잡지 못하므로 **이 grep이 유일한 기계적 신호**다.
  6. **모델 파일에 SwiftUI가 새어 들어오지 않았다** — `grep -c '^import SwiftUI' Shared/EditCard.swift`가 `0`. 조건 2와 같은 대상이지만 이쪽은 **작업 도중 새로 생기는** 누출을 본다 — 편의상 `Color`나 `View` 확장을 모델 파일에 얹는 순간 드라이버 집합의 SwiftUI-free 성질이 깨진다.
- **왜 이 AC가 6개 조건인가**: 여섯이 각각 다른 방식으로 깨진다(정의 잔류 / SwiftUI 누출 / 해석 복제 / 컴파일 인자 누락 / 별칭 누락 / 작업 중 누출). 하나만 확인하면 나머지가 조용히 남고, 3·5는 빌드와 드라이버 **양쪽 모두 잡지 못한다**.

## AC-002 — 카드 뷰가 `AIAssistant`를 타입으로 모른다 ⬜

- **Given** `AskCardView`(`Shared/AIChatView.swift:158-557`)·`ChipFlow`(`:564-612`)가 `private`이고, `assistant`를 정확히 **9곳**에서 부르고 있으며 — `isThinking`(`:181`·`:537`), `choose(field:value:)`(`:238`), `rechooseTimeBasis`(`:299`), `chooseTime`(`:344`), `choose(field:place:)`(`:444`), `searchPlaces`(`:495`), `submitCustom`(`:523`), `confirmAsk()`(`:534`)
- **When** 뷰가 `Shared/`의 새 뷰 파일로 옮겨지고 중립 표면(D-1에서 확정한 형태)을 쓰게 되면
- **Then** 세 가지가 성립한다:
  1. 새 뷰 파일에 `AIAssistant`라는 이름이 **한 번도 나오지 않는다** — `grep -c "AIAssistant" <새 뷰 파일>`이 `0`. **9곳 중 8곳만 옮기면 이 grep이 그것을 잡는다**(REQ-011이 "남은 한 곳이 있으면 네 화면이 쓸 수 없다"고 적은 이유).
  2. 추출된 타입이 `private`이 아니다 — 다른 파일에서 쓸 수 있다.
  3. 새 AI 클래스가 생기지 않았다 — `AIAssistant`가 그 표면의 유일한 AI 쪽 어댑터이고, 카드 전용 컨트롤러·이벤트버스·별도 영속화 레이어가 없다(계약 3·4).

## AC-003 — 디자인·접근성 불변식이 그대로다 ⬜

- **Given** 카드가 `Theme` 토큰 11종만 쓰고, 접근성 불변식 4건과 플랫폼별 칩 높이 분기를 갖고 있으며
- **When** 추출이 끝나면
- **Then** 항목별로 대조해 전부 같다 — **일괄 통과가 아니라 한 줄씩 대조한다**:

| 항목 | 대조 기준 | 원본 |
|---|---|---|
| 색 | 원시 색·`.secondary`·`.quaternary`·머티리얼이 0건, `Theme` 토큰만 | 계약 6 |
| 선택 표시 | 체크 글리프 + 글자 굵기(색 단독 아님) | `:372` |
| 칩 낭독 | `accessibilityElement(children: .contain)` + 줄 이름·사유 결합 라벨 | `:275`·`:277` |
| 흐린 여유 줄 | 투명도 0.5 + 캡션("출발 기준이라 쓰지 않아요") 이중 표현 | `:267`(캡션)·`:273`(opacity) |
| 확인 버튼 | 잠김 사유가 `accessibilityHint`로 읽힘 | `:555` |
| 칩 높이 | iOS 44 / macOS 28, 양쪽 `@ScaledMetric(relativeTo: .callout)` | `:176`(iOS 44)·`:178`(macOS 28) |
| 디바운스 | 뷰에 타이머가 없다 — 묶음은 어댑터 쪽 | `:487-488` |
| 다크 모드 | `preferredColorScheme` 강제 없음 | 계약 6 |

- **왜 항목별인가**: 이 여덟은 각각 다른 사고에서 나왔고, 추출에서 사라지는 방식도 다르다. "접근성 확인했다"는 한 줄은 어느 것이 확인됐는지 말하지 않는다.

## AC-004 — 값 수용·장소 줄·배치 계약이 그대로다 ⬜

- **Given** `accepts`가 종류별 상한을 갖고(여유 `0...Store.maxBufferMinutes`, 알림 `0...1440`, 반복 `1...Store.maxRecurrenceWeeks`, 이동수단 `TransportMode(rawValue:)`, 시각은 접두 + 정규 ISO — `:89-106`), 장소 줄이 자유 텍스트 확정 버튼을 두지 않으며, 칩이 가로 스크롤 없이 줄바꿈으로 흐르고
- **When** 추출이 끝나면
- **Then**
  1. 상한이 **상수 참조로** 남는다 — 숫자가 문구나 코드에 박히지 않는다. 거절 문구는 여전히 범위를 적지 않는다("그 값은 쓸 수 없어요", `:257`).
  2. 장소 줄에 자유 텍스트를 그대로 확정하는 버튼이 **없다** — 후보 탭만이 확정 경로다(`:407-408`, 결함 P). 0건/오프라인을 구분한 척하지 않는 문구가 그대로다(`:430`).
  3. `ChipFlow`의 `arrange`가 크기 계산과 배치에 **같은 함수**로 쓰인다(`:595`) — 따로 세면 높이와 실제 줄 수가 어긋난다. 가로 `ScrollView`가 없다.
- 드라이버 대조: 값 수용 판정은 드라이버가 검증하는 결정적 부분이므로, AC-005의 기존 단언이 초록인 것으로 (1)의 기계적 증거를 삼는다.

## AC-005 — 가드 드라이버 전체 초록, 단언 추가 없음 ⬜

- **Given** `Tools/GuardDriver.swift`에 `drvCheck(` 호출 지점이 **200곳**이고(정의 1건 제외, `291db49` 실측) `AskField`/`PendingAsk`를 20곳에서 참조하며
- **When** CLAUDE.md의 드라이버 블록을 (새 모델 파일을 인자에 넣어) 돌리면
- **Then** 전체 초록이고, **단언이 새로 추가되지 않았다** — 본 SPEC은 순수 추출이므로 통과 조건은 "기존 단언이 그대로 통과"다. 새 단언이 필요해졌다면 그것은 동작이 바뀐 신호이므로 REQ-041 위반으로 다룬다.
- 총 단언 수는 반복 안의 호출 때문에 호출 지점 수보다 크다 — **문서에 총수를 박지 않고 run-phase 실행 출력으로 실측한다**(SPEC-ASK-001 HISTORY 0.2.1 관례). 게이트는 "이름으로" 판정한다: 전체 초록 여부.

## AC-006 — 범위 경계: 네 화면이 한 줄도 바뀌지 않았다 ⬜

- **Given** 카드 t1이 "이 카드에서는 기존 4화면을 건드리지 않는다"로 범위를 못박았고
- **When** 구현이 끝나면
- **Then** `git diff --stat` 출력에 `Shared/AddEventView.swift`·`Shared/EventDetailView.swift`·`Shared/AddActivityView.swift`·`Shared/ActivityDetailView.swift` 네 경로가 **등장하지 않는다**.
- 함께 확인: `AddActivityView.PlaceField`(`:187-267`)의 계약 6 위반(`.secondary` `:206`·`:245`, `.quaternary` `:213`, `.bordered` `:220`)과 디바운스 부재(`runSearch :259` → `placeSearch.search :263`)가 **그대로 남아 있다** — 고쳤다면 범위를 넘은 것이다(t3 소관). 이 AC는 "안 고친 것"을 통과로 판정하는 유일한 AC다.
- 바뀐 파일은 4개뿐이어야 한다 — 새 파일 2개(`Shared/EditCard.swift`·`Shared/EditCardView.swift`) + `AIAssistant.swift` + `AIChatView.swift`. 문서(`CLAUDE.md`·루트 `plan.md`·본 SPEC 3종)는 별도.
- **`parts` 불변성 확인**(D-2의 실측 필요 항목): `let parts`가 `var`로 바뀌면서 사후 변조가 가능해진다. `grep -rn '\.parts = ' Shared/`가 **0건**이어야 한다 — 0이 아니면 카드가 붙잡은 보류 호출이 생성 후에 바뀌고 있다는 뜻이고, 사용자가 고른 값과 실제 실행되는 값이 갈릴 수 있다.

## AC-007 — 실기기에서 AI 카드 동작이 구분되지 않는다 ⬜ 리스크

- **Given** 카드 렌더링·제스처·접근성 낭독은 드라이버가 검증하지 못하고
- **When** 실기기(iPhone, UDID `8D9B807B-F874-5AD8-A62C-BC1731A31A1F`)에 배포해 AI 채팅으로 되묻기 카드를 띄우면
- **Then** 아래 전부가 추출 이전과 같다:

| 확인 항목 | 기대 |
|---|---|
| 카드가 뜨는 조건 | 빈 인자가 있을 때 한 장, 인자 수 = 줄 수 |
| "말씀하신 대로" 줄 | 조용히 정해진 값이 그대로 열거됨 |
| 칩 탭 | 선택 표시(체크 + 굵기)가 즉시 붙음 |
| 시각 줄 | 기준 칩 2개가 **미선택**으로 시작, 기준 없이 확인하면 아무것도 확정되지 않음 |
| 시각 에디터 | 처음 바퀴가 "다음 정각", 확인 전에는 값이 아님 |
| 출발 기준 확정 | 도착 여유 줄이 흐려지고 캡션이 붙음 |
| 장소 줄 | 검색창이 열리고 후보 탭으로 확정, 0건 문구 확인 |
| 직접입력 거절 | 범위 밖 값에서 입력창이 **열린 채** 거절 표시 |
| 확인 버튼 | 빠진 값이 있으면 잠김, 전부 채우면 "등록하기" 1회로 등록 완료 |
| 칩 줄바꿈 | 반복 일정처럼 줄이 많아도 가로로 밀리지 않고 전부 도달 가능 |
| 큰 글씨 설정 | 칩이 잘리지 않음 |
| 다크 모드 | 기기 설정을 따라감 |
| VoiceOver | 줄 이름 + 사유가 함께 읽힘, 확인 버튼 잠김 사유가 들림 |

- **왜 ⬜ 리스크인가**: 이 AC만 빌드로 갈음할 수 없다. 사용자에게 넘기는 목록은 이 표 중 **내가 검증할 수 없는 것만**이고, 나머지는 구현 후 직접 확인한다(CLAUDE.md "Day를 끝낼 때" 4항).

## AC-008 — 품질 게이트 ⬜

- **Given** 새 소스 파일 2개가 추가되고
- **When** 게이트를 돌리면
- **Then**
  1. `xcodegen generate` 실행 후 **`besir-iOS`·`besirShare` 두 타깃의 Team 재선택을 사용자에게 요청**했다 — 요청 없이 넘어가면 다음 빌드가 `No Account for Team`으로 끊긴다.
  2. iOS 빌드가 `BUILD SUCCEEDED`이고 툴체인 경고 제외 **무경고**다(`besir-iOS`, `iPhone 17 Pro` 시뮬레이터).
  3. macOS 빌드가 동일하다(`besir-macOS`).
  4. `cd proxy && npm test`가 전체 통과한다(본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다).
- 명령의 단일 출처는 `hns-besir-app-verify` 스킬이다 — 명령을 새로 만들지 않는다.

🗿 MoAI
