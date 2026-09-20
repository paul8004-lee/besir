# SPEC-UIKIT-002 — progress.md

card: t2 · worktree `.claude/worktrees/t2` · branch `WT-ui-unify-2`
base: 로컬 master(t1 sync 직후) — plan 커밋 `bf28cdf` 시점 `Shared/`·`Tools/`가 인용 기준 `434610e`와
무변경임을 run lane이 `git diff --stat 434610e..bf28cdf -- Shared/ Tools/`로 확인(출력 없음).
plan-phase 커밋: `bf28cdf` (SPEC v0.1.0, Tier M, REQ 14 / AC 9)
run-phase 커밋: `59efd0b` (M2·M3, 2026-09-20) — M4 에이전트가 2026-09-18 16:55 API 사용량
한도(429)로 중단된 뒤 lead의 이어받기 디스패치(2026-09-20)로 재개하며, "다시 끊겨도 작업이
사라지지 않게" 마일스톤별 커밋 규율이 들어왔다. M2·M3은 이미 한 트리로 검증돼 있어 한 커밋으로
묶고 그 이유를 커밋 메시지에 적었다(게이트 증거 205/205·빌드가 정확히 이 조합 트리에 귀속).
run-phase 세션: run lane (session f39b95e2), 2026-09-18 디스패치 (운영자 run 진입 승인 완료)

## §E.1 Plan-phase Audit-Ready Signal

plan_status: audit-ready
plan_complete_at: 2026-09-18

- 산출물 3종 완결(`bf28cdf` — 초안 전수 재실측으로 인용 5건 정정).
- D-1(카드 분할 A안)·D-2(표면 형태, `ui-design` 협의) 해소. **D-3(과거 시각)은 run 착수 전 운영자
  확정: (i) 그대로 둔다** — lead 디스패치(2026-09-18) "REQ-041 예외 절 불필요. '과거 일정 알림 미예약을
  화면이 말하게 하는 후속 항목'은 Day 닫기 이월 목록으로 리드가 넘긴다 — run이 만들지 않는다".
  spec.md §4 D-3 해소 기록은 run lane이 같은 날 반영(HISTORY 0.1.1과 한 문서 편집).
- **AC-009(시뮬레이터·실기기)는 운영자 standing 정책(2026-09-18)에 따라 리드가 시뮬레이터 스크립트로
  진행** — run은 기계 게이트까지만 닫는다(t1 AC-007 정정 기록과 같은 양식의 이관 고지).

## Phase 4 Mode Selection

직렬 sub-agent(besir-app 하네스 전문가 위임). M2·M3이 `Shared/EditCard.swift`를 공유하고
M2 표면 → M3 정책 → M4 전환 본체 → M5 대조가 연속 의존이라 병렬 쓰기 에이전트를 세우지 않았다
(쓰기 에이전트 동시 2금지). 배정: M2 `swift-impl` · M3 `ai-tooling` · M4 `swift-impl`(+`ui-design`
검토 통합 1회) · M5 `code-safety`. `ux-check`는 미배정 — AC-009가 리드 소관으로 이관됐기 때문(§E.1).

## §E.2 Run-phase Evidence

### M2 — 컴포넌트 표면 확장 (REQ-001~004 / AC-001) ✅

구현: `swift-impl` 전문가(블로커 보고 후 재위임 1회). 검증: 전문가 빌드 + run lane diff 직독.

- **정예 0.1.1 경위(REQ-001 블로커 → 해소)**: `swift-impl`이 `Kind` 전수 switch의 **네 번째**
  (`AIAssistant.swift:890-900`, 보류 턴 인자 채우기)를 발견 — SPEC 재실측은 세 곳만 셌다. 전문가는
  임의 수정 없이 보고했고, run lane이 해당 구간을 직접 읽어 사실 확인 뒤 **측정 오류 정정**으로
  spec.md 0.1.1을 반영했다: REQ-001에 네 번째 가지(`:892`) 명시, REQ-041에 그 가지의 좁은 예외 절
  (`, .toggle` 7글자, 실행 중 미도달 — AI 카드는 토글 줄을 만들지 않는다), acceptance.md AC-001 절 5.
  미룂(옵션 2) 대신 예외 절(옵션 1)을 택한 이유: 미루면 M2–M3 사이 트리가 컴파일되지 않고, M3에
  섞으면 "AIAssistant 변경은 디바운서뿐"이라는 M3 증거가 흐려진다. 되돌림 비용은 7글자다.
- **변경**: `Shared/EditCard.swift` — `Kind.toggle`(`:65`, seed 계약 주석), `customLabel`(`:117`)·
  `accepts`(`:133`) 가지, `Option.detail`, `busy`, `startsOpen`, `EditCardChrome`(nil=숨김, AI 기본
  문구는 뷰 쪽에). `Shared/EditCardView.swift` — `chrome` 기본값(`:16`), 헤더 조건 렌더, 루트
  `.onAppear` seed(합집합, draft 미충전), 줄 이름 옆 `busy` 진행 표시, 칩 `detail`(미선택
  `Theme.muted`/선택 `Theme.bg`), `confirmButton` 조건 렌더(`@ViewBuilder` + `if let`).
  `Shared/AIAssistant.swift` — `:892` 한 줄(`, .toggle`).
- **Claim**: AC-001 다섯 조건(정예 후 기준) 성립.
- **Evidence** (전문가 실행, 로그 `/tmp/t2-build-ios-2.log`·`/tmp/t2-build-macos-2.log`):
  1. iOS `xcodebuild -scheme besir-iOS … build` → `** BUILD SUCCEEDED **`, exit=0, 경고 필터
     (`grep "warning:" | grep -v appintentsmetadataprocessor`) 결과 빈 출력.
  2. macOS 동일 게이트 → `** BUILD SUCCEEDED **`, exit=0, 필터 결과 빈 출력.
  3. `git diff --name-only` → 소스 3종(EditCard·EditCardView·AIAssistant) + 문서 2종(SPEC 정예).
     `git diff -- Shared/AIAssistant.swift` → 정확히 한 훙크·한 줄(`:892`).
  4. `.init(key:` = **11**, Option 생성 = **16**, `^import SwiftUI` in EditCard.swift = **0**.
- **run lane 직접 검증**: 두 뷰/모델 파일 diff 전수 독검 — 지시 6항목과 일치, 색 전부 Theme 토큰,
  주석은 why형·파일 밀도와 같음. SourceKit "Cannot find type" 진단은 단일 파일 분석 노이즈로
  판정(변경 전 줄——예: `AIAssistant.swift:31-32`——에서 동일 오류 발생, 빌드는 양쪽 초록).
- **Gaps**: 토글 칩 렌더링·seed·크롬 숨김·busy·startsOpen은 전부 뷰 영역이라 빌드로만 증명된다.
  최초 실사용은 M4의 알림·캘린더 토글 줄이며 확인은 AC-009(리드 소관)다.

### M3 — 장소 검색 디바운서 단일화 (REQ-010~011 / AC-002·003) ✅

구현: `ai-tooling` 전문가. 검증: 전문가 드라이버·빌드 + run lane diff 직독.

- **변경**: `Shared/EditCard.swift` — `PlaceSearchDebouncer` 신규(`:194-257` — `gate`/`arm`/`noteDone`/
  `cancelAll`, 지연 상수 유일 소유, 정책 문단(카카오 할당량·350ms 근거·같은 질의 스킵)을 타입 문서로
  이전). `Shared/AIAssistant.swift` — 저장 프로퍼티 둘 → `placeDebounce` 하나(`:50-52`),
  `searchPlaces`가 gate/arm/noteDone 위임으로 재작성(`:757-787`), `cancelPlaceSearches` 한 줄
  위임(`:797`). `setLookup`·`maxPlaceSuggestions`는 AIAssistant에 잔류(REQ-010 — AI 의미 불이전).
- **Claim**: AC-002 네 조건 + AC-003 성립.
- **Evidence** (전문가 실행):
  1. 가드 드라이버(CLAUDE.md 블록 — cat에 EditCard.swift 포함): **`205/205 통과`**, exit=0.
     **P-1~P-7 전부 ✓** — 특히 P-4(즉시 '찾는 중')·P-5 두 단언(같은 질의 스킵·비우면 상태 비움)·
     P-6(카드 소멸 뒤 결과 버림). 단언 추가·수정 0건 — `Tools/GuardDriver.swift` diff 무변경.
  2. `grep -rc "350_000_000" Shared/` → `EditCard.swift:1`, 나머지 27개 파일 전부 0 — **합계 1**.
  3. `grep -c '^import SwiftUI' Shared/EditCard.swift` → `0`.
  4. iOS·macOS 빌드 `** BUILD SUCCEEDED **`, exit=0, 툴체인 필터 후 경고 0건.
  5. `git diff --name-only` → 소스 3종(M2 포함 트리 기준) + 문서 2종. `AIChatView.swift` 무변경.
- **run lane 직접 검증**: `AIAssistant.swift` diff 전수 독검 — `.fire`에서 `setLookup(.searching)`이
  `arm`보다 선행(P-4 동기성), `noteDone`이 `setLookup`보다 선행(원본 `:779→:782` 순서 보존),
  fire 클로저 `[weak self]`·`Task.isCancelled` 이중 가드 유지. 디바운서 본체 독검 — `noteDone`
  완료 시점 기록의 이유(예약 시점 기록 시 '찾는 중' 갇힘)가 주석으로 명시, 주석에는 리터럴
  `350_000_000` 대신 "350ms"를 써 grep 게이트 합계를 지킴.
- **Gaps**: 350ms 체감·타이핑 손감은 기기 확인 영역(AC-009, 리드). 폼 화면의 두 번째 사용처는
  M4가 만들며, 그 때 비로소 "공용"이 실제로 둘을 괸다.

### M4 — AddEventView 전환 (REQ-020~023 / AC-004·005) ✅

구현: `swift-impl` 전문가(2026-09-18 429 중단 → 2026-09-20 이어받기, 수정 패치 1회).
검증: 전문가 빌드·프록시 + run lane 전수 독검.

- **변경**: `Shared/AddEventView.swift` 전면 전환(+448/−395) — `@State` 8개만 남김(`card`·
  `confirmedPlaces`·`estimates`·`estimating`·`saving`·`lastNotifyLead`·`calendarDefault`·
  `placeDebounce`), 폼 값 11개·`canSave`·`depFmt`·`didLoadEditing` 제거. `Shared/EditCard.swift` —
  `BesirTime.compact`(static let, "M/d (E) a h시 mm분") + **`options` let→var(HISTORY 0.1.2 승인 이탈)**.
  게이트 줄(시각·수단·여유·알림 토글·리드·캘린더)은 필드 멤버십으로 조건화, 편집 프리필은 이벤트
  값으로 seed, 좌표는 탭 순간 확정, ConflictBanner는 화면 소유 유지+`.combine` 낭독, 재계산 컨트롤
  글자 라벨 획득.
- **Claim**: AC-004 다섯 조건 + AC-005 다섯 조건 성립.
- **Evidence** (전문가 실행, 수정 패치 후 재실시 포함):
  1. iOS·macOS `** BUILD SUCCEEDED **`, exit=0, 툴체인 필터 후 경고 0건.
  2. `grep -c '@State'` = **8**(전부 화면 소유), `canSave` = **0**, `DateFormatter()` = **0**.
  3. `EditCard(` 생성부 grep 1곳(`buildCard`) — `.task`의 `guard card == nil`로 정확히 한 번,
     이후 제자리 수정·삽입/제거만. `AIAssistant`·`AIChatView`·`EditCardView`·`Tools/`는 HEAD(59efd0b)와
     바이트 동일.
  4. 프록시 `npm test` **7/7 통과**(REQ-040(c)).
  5. REQ-021 (a)(b)(c)·REQ-022 (a)(b)(c)(d) 절 자기검토 **8/8 PASS** + run lane 전수 독검 일치.
- **수정 패치(1회, run lane 지시)**: save() 조용한 no-op 창(≤5초) 제거 — 위치 없이 "현재 위치"
  표식을 탭하면 chosen을 남기지 않아 `isReady` 잠금이 유지된다(원본이 제출 판정 식으로 잠그던
  관측 계약 복원). 첫 패치에서 why-주석이 'canSave' 문자열을 담아 grep을 오염시킨 것을 전문가가
  자가 포착해 문구를 고치고 전 검증을 재실행했다.
- **판단 기록(run lane 승인, 리드 보고에 명시)**: ① `options` let→var — 제자리 `detail` 갱신의
  유일한 경로(재구성은 `id = UUID()` 재발급으로 REQ-021(a) 위반) ② 편집 모드 startsOpen=false
  (REQ-003 취지 — 값 있는 줄 아래 빈 입력칸 방지) ③ prefillOrigin 대기 중 재확인 1줄(원본의
  덮어쓰기 버그 경로만 좋아짐 — 29절 #29에 기록) ④ 줄 라벨은 원본·AI 문구 혼합(ui-design 검토 대기).
- **잔여 관측 차이(문서화, AC-006 대조에서 절별 판정)**: 시각 줄 note는 커밋된 기준만 따름
  (draft 기준은 순수 값 뷰가 못 본다 — 휴면 계약의 반대편 제약). 출발지 검색이 상시 필드가 아닌
  "장소 검색" 칩 뒤로(1탭 추가). 검색 ≥2글자 가드 소멸(공용 디바운서 정책에 글자수 가드 없음 —
  AI 카드와의 통일). 시각 미확정 저장 불가(판정이 isReady로 — SPEC 승인).
- **Gaps**: 렌더링·제스처·낭독은 AC-009(리드). `ui-design` 검토 통과 1회가 M5 전에 남아 있다.
