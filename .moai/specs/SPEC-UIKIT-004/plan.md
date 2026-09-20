# SPEC-UIKIT-004 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 설계 원본은 루트 `plan.md` §Phase 1.7의
> t4 행 — 본 plan 단계에서 그 행을 `SPEC-UIKIT-004`로 확정 기록했다(분할표 갱신).

## 0. Tier 판단

**Tier: M**

- 근거: 본체 파일 **2개** — `Shared/EventDetailView.swift`(크롬 패스·377줄) + `Shared/EditCard.swift`
  (BesirTime 확장 — 포매터 2·접근자 2). 추가로 N2 전환 8줄이 3개 파일을 제자리 치환한다
  (`AddEventView` 5·`EditCardView` 1·`AIAssistant` 2, REQ-011). 문서 갱신 3종(루트 `plan.md`
  t4 행·본 SPEC 4종·`CHECKLIST.md` 인용 수리는 sync).
- **REQ 14건 · AC 9건** — 실측 명령과 함께: `grep -c '^- \*\*REQ-' spec.md` = **14**,
  `grep -c '^## AC-' acceptance.md` = **9**. `spec-workflow.md`의 Tier M 상한(REQ 16 / AC 16)
  아래다. 여유 2건은 구현 중 측정 정정용(spec.md §0).
- Tier L이 아닌 이유: Tier L은 >1000 LOC 또는 >15파일. 본 카드는 소스 5파일(본체 2+치환 3)이고
  치환 3개는 한 줄씩이다.
- `design.md`/`research.md`는 Tier L 전용 — 설계 검토는 리드 디스패치(사전 확정된 D-1·D-2)와
  본 세션의 전수 재실측 + GLM 교차협의(D-4, spec.md §4)로 갈음했다.

## 1. 마일스톤

의사결정 가변성 순서(중립 타입 확장 → 화면 본체 → 대조·게이트). 실행 순서도 동일하다:
M1 → M2 → M3 → M4.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1~D-4·문서) | — | 설계 확정 — D-1(승계)·D-2·D-3·D-4 확정, SPEC 4종 완결, 루트 `plan.md` t4행 확정 기록. **미해소 결정 없음** — D-1은 2026-09-18 운영자 확정을 승계했고 나머지는 본 세션 실측으로 닫혔다 | 🟢 |
| M2 | REQ-001~003, REQ-010~012 | AC-001~004 | `BesirTime` 확장 — 포매터 `full`·`clock` 이사(패턴 불변), `anchor(ofPrefix:)`·`prefix(for:)` 신설, N2 8곳 제자리 치환. **드라이버 P 계열 초록·단언 추가 없음이 옮김의 기계적 증거** | 🟢 |
| M3 | REQ-020~023 | AC-005 | `EventDetailView` 크롬 패스 — 컨테이너 3곳(2 교체+1 신규), 색 토큰화(secondary 9·tertiary 1·quaternary 1·red/green 2), 접근성 순증, 38pt `@ScaledMetric` | 🟢 |
| M4 | REQ-030~031, REQ-040~041 | AC-006~009 | 어포던스 **절별 대조**(일괄 통과 금지), 범위 diff 검사, 무경고 빌드 양쪽, 드라이버·프록시, 시뮬레이터 | 🟢 |

## 2. 알려진 이슈 / 리스크

- **드라이버 컴파일 경계가 M2의 1급 제약이다.** `EditCard.swift`는 드라이버 `swiftc` 인자
  목록에 있고 `import SwiftUI`가 없어야 한다(기계적 신호 `grep -c '^import SwiftUI'
  Shared/EditCard.swift` = **0** 유지). 신규 멤버 `anchor(ofPrefix:)`는 `ScheduleAnchor`
  (`Models.swift:204`)를 반환하는데 — `Models.swift`도 컴파일 집합 안이므로 성립한다. 그러나
  반환 표기에 SwiftUI 타입이 한 건이라도 들어가면 드라이버가 못 돈다. 실패 신호: swiftc 오류.
- **"오후 3:5" 회귀가 이 카드의 상시 함정이다.** 포매터를 다루는 모든 줄에서 패딩(mm/m)을
  손대지 않는다(REQ-003). 반증 신호: swift 실측 출력에 "3:5" 또는 "3시 5분"이 **full·compact·
  clock 자리에** 나타나는 것(AC-002 표 참조 — `when`의 "3시 5분"만이 올바른 비패딩 표기다).
- **N2 치환은 제자리여야 한다.** `AddEventView`·`EditCardView`·`AIAssistant`의 diff가 열거
  8줄 외에 한 줄이라도 더 담으면 REQ-041 위반이다(AC-008). 줄 추가·삭제로 인접 줄 번호가
  밀리면 `CHECKLIST.md` 인용 12건(AIAssistant 6·EditCardView 6)이 흔들린다 — 치환은
  우변만 바꾸는 형태를 유지한다. 단 `anchor(ofPrefix:)`가 옵셔널을 돌려주므로 :476·:885은
  flatMap, :554·:168은 `?? .departure` 적응이 필요하다(교차검토 6번) — 한 줄은 유지되지만
  순수 우변 치환은 아니라는 것을 run이 알고 있어야 한다.
- **크롬 패스가 "재디자인"으로 미끄러지는 것을 방어한다.** 섹션 순서·문구·분기는 무변경
  (REQ-030·D-4 변경 금지 목록). 캘린더 네 갈래를 젽는 리팩터는 t2a D-1이 금지한 바로 그
  결함의 재발이다(REQ-022).
- **BesirTime 신규 멤버 삽입으로 `EditCard.swift` 줄이 민다** — `EditCard.swift`를 인용하는
  `CHECKLIST.md` 2건은 sync가 바이트 대조로 수리한다(§1.4, t2a 101조각 전례). run이
  CHECKLIST를 고치지 않는다.
- **하네스 배정**(CLAUDE.md "작업을 시작할 때", 매번 적용):
  - M2 — `swift-impl`(BesirTime 확장·치환), `ai-tooling`(`AIAssistant.swift` 1줄과 드라이버
    P 계열 초록 확인)
  - M3 — `ui-design`(크롬 매핑 표의 시각적 승인), `swift-impl`(본체)
  - M4 — `code-safety`(구현 변경 후), `ux-check`(시뮬레이터·실기기 목록)

## 3. 검증 계획

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AI 인자 가드 | CLAUDE.md(워크트리 판)의 드라이버 블록 — 인자 변동 없음(새 파일 0개) | 전체 초록, **단언 추가 없음** |
| 패딩 실측 | swift 한 줄 — 5종 포매터로 `2026-09-17T15:05:00`을 찍어 비교 | AC-002 표의 문자열과 전부 일치 |
| 매핑 신호 | `grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` + `grep -rn '? "arr:" : "dep:"' Shared/*.swift` | **2**(열거된 유지 2곳) + **0** |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED`, 툴체인 경고 제외 무경고 |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 (본 SPEC은 프록시 무변경 — 게이트만) |
| 범위 diff | `git diff --name-only origin/master...HEAD` | 소스 5종(본체 2+치환 3), 문서 예외만 추가 |
| 시뮬레이터 | 입력 문구 + 기대 결과를 정확히 준 스크립트 방식(초기화 시점 포함) | AC-009 시뮬레이터 목록 전부 |

`hns-besir-app-verify` 스킬이 이 명령들의 단일 출처다 — 명령을 새로 만들지 않고 그 스킬을
돈다. **`xcodegen generate`는 돌리지 않는다**(새 소스 파일 0개, REQ-040 (d)) — 서명 Team
재선택 요청이 없는 것이 통과 조건이다(t1과 반대 방향의 기대).

## 4. 후속 (본 SPEC 밖)

- **카드 t3** — 활동 화면 둘(`AddActivityView`·`ActivityDetailView`, `SPEC-UIKIT-003`).
  t4 done 뒤 착수. 본 카드가 `BesirTime.anchor`를 만들어 두면 t3의 시각 줄이 같은 문법을 쓴다.
- CB(ConflictBanner 계약 6 우회 3건)·B7·S-lens4(buffer 초산 3곳) — t2a §E.3 후보. 본 카드가
  담지 않는다(§3). 리드가 다음 카드 후보로 관리한다.
- 실기기 전용 확인 목록(AC-009)은 **Day 닫기 이월 목록**으로 리드가 넘긴다 — t2a와 같은
  standing 정책(2026-09-18).

🗿 MoAI
