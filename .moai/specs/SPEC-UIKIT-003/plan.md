# SPEC-UIKIT-003 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 설계 원본은 루트 `plan.md` §Phase 1.7.
> 루트 `plan.md`는 "계획이 실제와 달라지면 그 자리에서 갱신"하는 1차 참조 문서다 — 본 카드가
> 카드 본문에 없던 차이(기준 없는 시각 줄)를 새로 판단했으므로 sync에서 §Phase 1.7 t3 행에
> 반영한다.

## 0. Tier 판단

**Tier: M**

- 근거: 건드리는 파일 **4개** — `Shared/AddActivityView.swift`(전환 본체, 267줄) +
  `Shared/ActivityDetailView.swift`(전환 본체, 222줄) + `Shared/EditCard.swift`(기준 없는 시각의
  해석·글자·확정 표면) + `Shared/EditCardView.swift`(시각 줄 배치·기준 칩 순서·흐림 판정).
  문서 갱신 1종(루트 `plan.md` §Phase 1.7 t3 행).
- **REQ 15건 · AC 10건** — 실측 명령과 함께: `grep -c '^- \*\*REQ-' spec.md` = **15**,
  `grep -c '^## AC-' acceptance.md` = **10**. D-3 해소로 REQ-014가 들어와 상한까지 **1건** 남았다.
  Tier M 상한(REQ 16 / AC 16)은 SPEC-UIKIT-002
  plan.md §0이 인용한 값을 따른다(`.claude/`가 이 워크트리에 없어 원문 줄번호는 인용하지 않는다 —
  세지 않은 수치를 적지 않는다). **REQ 16 도달 또는 파일 5개는 분할 신호.**
- Tier L이 아닌 이유: 두 화면 합쳐 489줄이고 전환이 사실상 재작성이라도 같은 파일 안에서 일어난다.
- `design.md`/`research.md`는 Tier L 전용 — 설계 판단은 본 세션의 실측(§1.1~1.4)과
  SPEC-UIKIT-002의 본보기로 갈음했다.

## 1. 마일스톤

의사결정 가변성 순서(컴포넌트 표면 → 전환 본체 둘 → 대조·게이트). 실행 순서도 의존성상 동일하다:
M1 → M2 → M3 → M4 → M5.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1·D-2·D-3) | — | 설계 확정 — SPEC 3종 완결. **D-3 해소**(2026-09-22 운영자 "올림") → REQ-014 신설, REQ 15건. 미해소 결정 **0건** | 🟢 |
| M2 | REQ-001~003 | AC-001·AC-002·AC-003 | 컴포넌트 표면 — `anchored` 옵션(해석·글자·확정 네 경로), 시각 줄 두 줄 배치 + 기준 칩 출발→도착, 흐림 판정이 기준 있는 줄을 본다. **전부 기본값·내부 변경**이라 `AIAssistant`·`AddEventView`·`AIChatView`는 한 줄도 안 바뀐다. **REQ-003은 M3보다 먼저 끝나야 한다**(§2 첫 항목) | ⬜ |
| M3 | REQ-010~014 | AC-004·AC-005 | `AddActivityView` 전환 — `@State` 12개 → `card` 하나, 다리 둘을 줄 멤버십으로, 알림 리드 줄(요청 ②)과 **가는 편 도착 여유 줄**(D-3) 신설, 캡션 제거, header/footer는 카드 밖 유지 | ⬜ |
| M4 | REQ-020~021 | AC-005·AC-006 | `ActivityDetailView` 전환 — `Form` → `ScrollView` 크롬 통일, 네 줄(제목·장소·시작·종료), 주변 맛집·삭제·반복 안내는 화면 소유, 장소 좌표 결함(§1.2) 닫기 | ⬜ |
| M5 | REQ-030~031, REQ-040~042 | AC-007~010 | 보존 대조와 게이트 — 어포던스 **절 단위 개별 대조**(일괄 통과 금지), 접근성 순증·후퇴 명시, `PlaceField` 판정 3절, 무경고 빌드 양쪽, 드라이버 전체 초록, 프록시, 시뮬레이터·실기기 | ⬜ |

## 2. 알려진 이슈 / 리스크

- **M2의 REQ-003이 M3의 REQ-014보다 먼저 끝나야 한다 — 순서가 곧 결함 방지다.** D-3이 "올림"으로
  확정되면서 §1.4가 휴면에서 **활성**으로 바뀌었다. `currentBasis`(`EditCardView.swift:168`)의
  `?? .departure` 폴백 때문에, 기준 없는 시작 시각이 확정되는 순간 `departureAnchored`가 참이 되고
  **새로 생긴 여유 줄이 영구히 흐려진다**("출발 기준이라 쓰지 않아요"가 붙은 채 고칠 수 없다).
  순서를 뒤집으면 태어나자마자 못 쓰는 줄을 만들고, 원인이 두 화면 밖의 공유 컴포넌트에 있어
  화면만 들여다보면 찾지 못한다. 반증 신호: 활동 추가에서 시작 시각을 고르는 순간 여유 줄이
  흐려진다(AC-003 (3)).
  - `?? .departure` 폴백 **자체는 고치지 않는다** — 기준 있는 줄에서는 옳은 방어이고, 고치면
    기존 두 화면의 동작이 함께 바뀐다. REQ-003은 "누구에게 묻는가"만 고쳐 폴백에 닿지 않게 한다.
- **기준 없는 시각의 확정 경로가 이 전환의 1급 리스크**(REQ-001 (d)). `currentBasis`는 기준 없는
  줄에서 nil을 돌려주는 것이 정답인데, `datetimeEditor`의 확인이 `guard let basis = currentBasis(...)
  else { return }`(`EditCardView.swift:216`)로 시작한다. 갈라 주지 않으면 **활동의 시각 줄은 확인을
  눌러도 아무 일도 일어나지 않는다** — 조용히 멎는 종류라 빌드도 드라이버도 잡지 못한다.
  반증 신호: 시작·종료를 고르고 확인해도 칩이 점선인 채고 `isReady`가 풀리지 않는다.
- **카드 정체성**(REQ-013 (a)). `EditCardView`의 지역 상태 다섯(`EditCardView.swift:20-27`)이 전부
  `field.id`(UUID)를 키로 쓴다. 카드를 계산 프로퍼티로 만들거나 `Group`·조건문으로 한 겹 싸거나
  `.id(...)`를 붙이면 **장소 이름을 한 글자도 칠 수 없다.** SPEC-UIKIT-002 REQ-021(a)가 이미 겪은
  자리이므로 새로 발견할 것이 아니라 그대로 따라간다.
- **`hasPrefix("")`는 항상 참이다**(REQ-001 (a)). `parseDatetime`의 접두 목록에서 빈 문자열이
  `"arr:"`·`"dep:"` **앞에** 놓이면 기준 있는 시각이 전부 기준 없는 시각으로 풀린다. 목록 순서가
  이 변경의 유일한 조용한 함정이다. 반증 신호: 일정 폼의 확정 칩이 "도착 9월 …"이 아니라 "9월 …"로
  나온다(AC-002).
- **장소가 선택 사항인 줄이 `isReady`를 막는다**(REQ-030). `isReady`는 `chosen != nil`을 전수로 본다
  (`EditCard.swift:224`). 활동 장소는 지금 "장소 (선택)"(`AddActivityView.swift:50`)이므로, 줄을
  그냥 만들면 **장소 없는 활동을 영영 만들 수 없다.** 본 SPEC은 "'장소 없음' 칩을 옵션으로" 정했다 —
  줄을 안 만드는 쪽은 나중에 장소를 더할 길이 화면에서 사라져 기각했다.
- **주변 맛집이 좌표를 읽는다**(REQ-021). 장소를 다시 고른 뒤 `nearby`·`nearbyLoaded`를 비우지
  않으면, 새 장소 이름 아래 옛 장소의 식당이 남아 §1.2의 결함이 형태만 바꿔 살아남는다.
- **`PlaceField`는 옮기지도 디바운서를 붙이지도 않는다**(REQ-042). t2a가 넘긴 두 항목 중
  **디바운스 부재는 실측 결과 결함이 아니다** — `onChange`가 0건이고 검색은 `.onSubmit`과 버튼
  탭 두 경로뿐이다. 넘겨받았다는 사실을 결함의 증거로 쓰지 않는다.
- **줄번호 드리프트가 t5로 흘러간다.** 본 카드가 두 화면을 재작성하므로 t5(데드 코드 정리)가
  적어 둔 줄번호(`Store.addActivity(title:)(:178)` 등)와 `CHECKLIST.md`의 인용이 밀린다. t5는
  plan에서 grep 재실측하기로 이미 카드 본문에 적혀 있고, `CHECKLIST` 인용은 **본 카드가 sync에서
  수리한다**(드리프트를 만든 카드가 수리한다는 관례).
- **하네스 배정**(CLAUDE.md "작업을 시작할 때", 매번 적용):
  - M2 — `ui-design`(시각 줄 두 줄 배치·기준 칩 순서·기준 없는 줄의 모양), `swift-impl`(모델·뷰 확장)
  - M3 — `swift-impl`(전환 본체), `ui-design`(다리 줄의 배치와 '장소 없음' 칩)
  - M4 — `swift-impl`(전환 본체), `ui-design`(`Form` → `ScrollView` 크롬 통일)
  - M5 — `code-safety`(구현 변경 후), `ux-check`(시뮬레이터·실기기 목록)
  - plan 단계(이 문서) — **0명.** 읽기 전용 실측과 문서 작성뿐이라 부를 조건이 없다.

## 3. 검증 계획

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AI 인자 가드 | CLAUDE.md의 드라이버 블록(인자 변동 없음 — 새 파일 0개) | 전체 초록, **단언 추가 없음** |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED`, 툴체인 경고 제외 무경고 |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 (본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다) |
| 시뮬레이터 | 입력 문구 + 기대 결과를 정확히 준 스크립트 방식(초기화 시점 포함) | AC-010 시뮬레이터 목록 전부 |
| 실기기 | `-allowProvisioningUpdates` → `devicectl device install app` → `process launch` | AC-010 실기기 전용 항목 |

`hns-besir-app-verify` 스킬이 이 명령들의 단일 출처다 — 명령을 새로 만들지 않고 그 스킬을 돈다.
**`xcodegen generate`는 돌리지 않는다**(새 소스 파일 0개, REQ-040 (d)) — 따라서 서명 Team 재선택
요청도 없다. 이 문장이 지워져 있으면 새 파일을 만든 것이다(REQ-041 위반).

**드라이버 초록은 이 카드의 증거가 아니다.** 드라이버는 SwiftUI 뷰를 컴파일하지 않으므로 REQ-001~003,
REQ-010~021의 관측 가능한 결과는 전부 가드 밖이다. 게이트로는 돌리되 증거로는 세지 않는다.

## 4. 후속 (본 SPEC 밖)

- **카드 t5** — 데드 코드 정리. 본 카드 done 이후. 본 카드가 `Store.addActivityWithTravel`의
  `notifyLeadMinutes`를 실제로 쓰게 만들므로 t5의 "확정 7건" 중 활동 관련 항목은 재실측 대상이다.
- **`EditCardActions.chooseTime`의 기준 옵셔널화**(§4 D-2 A안) — 활동·일정 카드가 모두 안정된 뒤의
  정리 항목. 지금 하면 파일이 5~6개가 되어 한 Day 상한을 넘는다.
- **`ActivityDetailView` 주변 맛집 섹션의 계약 6 위반 5건** — be full sir Phase 1 소관.
- **`ConflictBanner`의 계약 6 위반 2건**(`AddEventView.swift:601`·`:604`) — t2a가 남긴 것.
  본 카드도 건드리지 않으며, 루트 `plan.md` 후속 항목으로만 남는다.

🗿 MoAI
