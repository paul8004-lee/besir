# SPEC 검토 보고서: SPEC-UIKIT-007
Iteration: 1/3
Verdict: FAIL
Overall Score: 0.79

> 작성자 추론 맥락은 전달되지 않았다(M1 Context Isolation). 호출자가 준 "환경 사실"(워크트리 경로, 베이스 `73ceb43`, 규칙 파일 위치)은 경로 해석에만 썼다.
> 입력: Tier S — `spec.md`(220줄) · `plan.md`(136줄) · `progress.md`(111줄). `research.md`·`acceptance.md`·`design.md` 없음(Tier S라 정상).
> 교차 모델 감사: `workflow.yaml` `audit.model: multi`(claude required · codex off · glm advisory). `mcp__moai__audit_multi` 결과 overall `needs-attention`, GLM `inconclusive`(z.ai 응답 본문 없음, fail-open), codex는 설정상 꺼짐. 판정은 claude 앵커 단독이다.

**FAIL의 성격.** 점수(0.79)는 Tier S 통과선 0.75를 넘는다. FAIL은 must-pass 방화벽 둘에서 나온다. MP-7은 작성 결함이 아니라 **착수 승인 게이트가 아직 열리지 않았다는 신호**다 — SPEC이 표식을 규약대로 `plan.md`에 두었고, 리드가 게이트에서 풀면 해소된다. MP-1은 문언상 실패이고 기계적 재번호로 고쳐진다. 코드 인용은 표본이 아니라 SPEC이 든 인용 전부를 `73ceb43` 트리에서 대조했고 어긋난 것이 없다(아래 §검증 증거).

## Must-Pass Results

- [FAIL] **MP-1 REQ 번호 일관성**: `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:91)·002(:93)·003(:95)·004(:97)·010(:101)·011(:103)·020(:107)·021(:109). 중복 0, 세 자리 zero-padding 일관. 그러나 004→010(005~009 없음), 011→020(012~019 없음) 두 곳이 비어 있다. 대역식 번호는 `spec.md:33`("§2.1 4건(001~004) · §2.2 2건(010·011) · §2.3 2건(020·021)")에 공개돼 있지만 MP-1 문언("Even one gap … = FAIL")에 대역 예외가 없다. 감사자 재량으로 문언을 완화하지 않는다. 이 프로젝트의 선례도 갈려 있다(SPEC-ONTIME-001 review-1은 optional, SPEC-FULL-001 review-1은 critical). M6에 따라 must-pass 실패는 항상 blocking이다.
- [PASS] **MP-2 GEARS 형식** — *판정 층위: 요구사항 층(`spec.md` §2, :91-109)만.* §3.1의 Given-When-Then AC는 검증 층의 올바른 형식이라 여기서 채점하지 않았다. 8건 모두 GEARS 문형으로 시작한다. Event-driven 3건(REQ-001 :91 "When the edit sheet builds its card…", REQ-003 :95 "When the edit sheet opens…", REQ-021 :109 "When the card is about to leave run…"), State-driven 1건(REQ-002 :93 "While the edit sheet is open…"), Where 2건(REQ-004 :97, REQ-010 :101), Ubiquitous 1건(REQ-011 :103 "The comment above `confirmedPlace(_:)` shall…"), Unwanted 1건(REQ-020 :107 "The change shall not modify…"). REQ-004의 `Where`가 능력 게이트가 아니라 모드 조건처럼 읽히는 점, 요구사항 뒤에 붙은 규범성 한국어 꼬리는 minor로 따로 적었다(D9·D10).
- [PASS] **MP-3 YAML frontmatter**: `spec.md:1-17`에 12개 필드가 모두 있다. id `SPEC-UIKIT-007`(정규식 통과), title 따옴표 문자열, version `"0.1.0"`, status `draft`(enum), created·updated `"2026-09-23"`, author `"manager-spec"`, priority `P2`, phase `"Phase 1.7 — 화면 UI 통일"`(금지값 아님), module `"shared-ui"`, lifecycle `spec-anchored`, tags 쉼표 문자열. 거부 별칭(`created_at`·`updated_at`·`labels`·`spec_id`) 0건. `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` → `✓ No findings — all SPEC documents are valid`. `module`이 path-like가 아닌 점은 optional(D15).
- [N/A] **MP-4 언어 중립성**: 단일 언어(Swift) iOS·macOS 앱의 한 화면 수정이다. 다언어 도구 서술이 없다.
- [PASS] **MP-5 D7 교차 SPEC 조정**: D7 동사 실행 — 본문 참조 SPEC-UIKIT-002·003·005·006 모두 `status: completed`, 자기 자신(007)은 `draft`. retired/superseded/archived 0건, 미발견 0건. BLOCKING 없음.
- [PASS] **MP-6 D8 크로스플랫폼**: `grep -c 'syscall'` → spec.md 0 · plan.md 0 · progress.md 0. D8-4에 따라 자동 통과.
- [FAIL] **MP-7 명확화 게이트** — *clarification gate finding*: `grep -n '\[NEEDS CLARIFICATION' plan.md` → `:47` D-1(한 줄 씨앗만 둘지, 프리필 가드를 더 둘지) · `:57` D-2(한 자리 두 빌드인지, 수정 전 파트 A로 막을지) · `:66` Tier(S로 확정할지). `research.md`는 없다. 오케스트레이터가 `AskUserQuestion`으로 세 항목을 풀기 전에는 착수 승인이 진행될 수 없다. 해소 경로는 manager-spec 수정이 아니라 리드의 게이트다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.75 | 0.75 | 요구사항 대부분이 단일 해석이다(REQ-001 :91은 줄·값·효과를 특정). 감점: REQ-020(:107)의 run 범위 선언이 REQ-021(:109)과 충돌(D3), REQ-004(:97)의 `Where` 문형(D9), 요구사항 꼬리의 규범성 한국어 문장("우선한다" :103·:107, 무변경 목록 :107)이 GEARS 문장과 구분 표시 없이 섞임(D10) |
| Completeness | 0.90 | 1.0 대역 하단 | HISTORY :21-25, 배경(WHY) :37-85, 범위·예산(WHAT) :27-35, 요구사항 :87-109, 인라인 AC :115-149, `### Out of Scope —` H3 4개와 `-` 항목(:192-208), HOW는 `plan.md` §1·§5. frontmatter 12/12. 감점: D-1 (b) 채택 시 AC-002의 새 기대값이 "바뀐다"(:117)로만 적혀 있고 값이 없다, REQ-004 뒤 절반(nil 출발지 편집)에 관측 AC가 없다(:145) |
| Testability | 0.70 | 0.50~0.75 사이 | AC-001(:121)·AC-002(:125)·AC-004(:133)·AC-008(:149)은 명령과 기대값이 모두 기계적이다. 감점: AC-003의 "검토자 판정"(:129), AC-006의 칩 글자 `강남역`이 검색 후보 이름과 다를 수 있음(:141, D7), AC-007 6번의 `현재 위치(…)` 기대가 역지오코딩 타이밍에 달림(:145·:179, D5), AC-007의 `약 Z분 유지`에 허용치가 없는데 AC-006은 ±2분(:141 대 :145, D13) |
| Traceability | 0.85 | 0.75~1.0 사이 | REQ 8건 전부 AC ≥1, AC 8건 전부 실재 REQ를 가리킴(헤더 :119-147). 감점: `plan.md:18`의 매핑 "002→005·006·007"이 AC-005 헤더(:135, REQ-021만)와 어긋나고, AC-005는 수정 전 재현이라 REQ-002를 검증할 수 없다(D4). REQ-004 뒤 절반은 코드 읽기로만 판정(:145) |

집계: 조화평균 4 / (1/0.75 + 1/0.90 + 1/0.70 + 1/0.85) = 4 / 5.0495 = **0.79**. Tier S 통과선 0.75 이상. 판정은 MP-1·MP-7 방화벽으로 FAIL이다.

## Defects Found (structured defect-list)

D1. MP-7-clarification-gate — plan.md:L47·L57·L66 — `[NEEDS CLARIFICATION]` 3건(D-1 수리 모양, D-2 수정 전 증거 시점, Tier 확정)이 미해소다. — Severity: critical — Class: blocking — Required fix: (1) 리드(오케스트레이터)가 착수 승인 게이트에서 `AskUserQuestion`으로 세 항목을 결정한다. (2) 결정 뒤 manager-spec이 각 표식을 채택안으로 바꾸고, 조건부로 걸린 두 요구사항을 무조건형으로 다시 쓴다 — REQ-010(spec.md:101)의 "Where the kickoff gate resolves D-1…"와 REQ-021(spec.md:109)의 D-2 의존. spec.md:117(§3.1 머리말)과 :212(§4)도 결정 사실로 갱신한다. (3) **D-1 (b)가 채택되면** REQ-010은 (b)가 금지 대상 그 자체를 추가하므로 철회하거나 새로 써야 하고, AC-002의 셋째 기대값과 헝크 조건을 구체 값으로 다시 적어야 한다(지금은 "바뀐다"뿐). 그 경우 2회차 감사 범위가 커진다.

D2. MP-1-req-numbering-gaps — spec.md:L91-L109 — 대역식 번호로 005~009·012~019가 비어 있다. — Severity: critical(must-pass) — Class: blocking — Required fix: REQ-010→005, 011→006, 020→007, 021→008로 다시 매기고 모든 참조를 옮긴다. 대상 줄은 `grep -n -E 'REQ-0(10|11|20|21)|0(10|11|20|21)→|010·011|020·021' spec.md plan.md progress.md`로 찾는다(이번 실행에서 spec.md 14개 줄(:33·:99·:101·:103·:107·:109·:123·:127·:131·:135·:137·:147·:195·:212) · plan.md 9개 줄(:13·:16·:19·:33·:34·:35·:37·:39·:55) · progress.md 1개 줄(:85)이 걸렸다). 이 grep에 걸리지 않는 약식 표기도 같이 옮긴다 — spec.md:139의 `REQ-001·002·003·021`, spec.md:33의 대역 서술, plan.md:18-19의 매핑표. 재번호가 끝나면 `grep -c '^- \*\*REQ-' spec.md` = 8과 AC 헤더의 REQ 목록을 다시 대조한다.

D3. REQ-020-run-scope-contradiction — spec.md:L107 대 L109 — REQ-020은 run의 선언 파일을 `Shared/AddEventView.swift` 하나로 적고 SPEC 디렉터리는 sync에만 허용한다. 그런데 REQ-021은 run을 떠나기 전 `progress.md`에 파트 A·B 증거를 요구하고, plan.md:36(M4)은 run 종료 때 `progress.md` §E.2·§E.3을 쓴다. 첫 run 커밋의 `status: draft → in-progress` 전이도 spec.md를 건드린다. 문언대로 읽으면 REQ-020이 REQ-021을 금지한다. AC-002(:125)의 `git diff --name-only` 범위가 `.moai/`를 빼고 있어 AC로는 드러나지 않는다. — Severity: minor — Class: blocking — Required fix: REQ-020의 run 선언을 "`Shared/AddEventView.swift`와 이 SPEC 디렉터리(`progress.md`, `spec.md` frontmatter `status`·`updated`)"로 고친다.

D4. plan-traceability-map-mismatch — plan.md:L18 대 spec.md:L135 — 매핑 "002→005·006·007"이 AC-005 헤더 "(REQ-021)"와 어긋난다. AC-005는 수정 전 빌드에서 결함을 재현하는 기준이라 REQ-002(수정 후 동작)를 검증할 수 없다. — Severity: minor — Class: blocking — Required fix: plan.md:18을 "002→006·007"로 고친다(D2 재번호와 한 번에).

D5. AC-007-step6-label-timing — spec.md:L145·L179 — 6번은 `현재 위치(…)` 프리필을 기대한다. 그러나 칩 글자에 지명이 붙는 것은 `confirmCurrentLocationAsOrigin`이 도는 그 순간 `currentPlaceName`이 이미 있을 때뿐이다(`AddEventView.swift:452-455`). 5번은 권한 "안 함" 상태로 앱을 다시 실행한다 — 그 프로세스의 시작 요청(`App.swift:90` → `LocationManager.swift:51-53`)은 곧바로 돌아와 역지오코딩이 한 번도 돌지 않는다. 권한을 되돌려도 `locationManagerDidChangeAuthorization`은 `isLocating`일 때만 측위를 시작한다(`LocationManager.swift:119-120`). 그래서 6번의 첫 확정은 지명 없이 `현재 위치`로 찍힐 가능성이 높다. 8번(:181)은 같은 사정을 이미 "`현재 위치` 또는 `현재 위치(…강남구…)`"로 받아두었으니 두 단계의 기대가 서로 어긋난다. **코드 읽기 가설이다 — 시뮬레이터로 관측하지 않았고, 권한을 되돌릴 때 iOS가 앱을 종료하는지도 확인하지 않았다.** — Severity: minor — Class: blocking — Required fix: 6번과 AC-007의 기대를 "`현재 위치` 또는 `현재 위치(…)`로 6초 안에 프리필"로 바꾼다. 이 단계가 확인하는 회귀는 "프리필이 일어난다"이지 칩 글자가 아니다. 다른 방법으로는 5번 끝에 "권한을 되돌린 뒤 앱을 종료하고 다시 실행"을 넣는다.

D6. HISTORY-count-contradiction — spec.md:L25 대 progress.md:L43-L44 — HISTORY는 "어긋난 것은 F6의 줄 범위 하나"라고 적었지만 progress.md §E.1은 F5(`:51-54` → `:51-53`)도 고쳤다고 기록한다. 같은 문장의 "두 곳을 고쳤다 … 셋 다"도 수가 맞지 않는다(고친 것은 1번 메뉴 이름, 7번 재실행, 8번 기대 문구 셋이다). — Severity: minor — Class: blocking — Required fix: "어긋난 것은 F6·F5의 줄 범위 둘(결론 같음)", "세 곳을 고쳤다"로 바로잡는다.

D13. AC-tolerance-inconsistency — spec.md:L141 대 L145·L180 — AC-006은 X와 D에 ±2분을 주지만 AC-007의 "`약 Z분`이 유지"에는 허용치가 없다. 편집 저장은 `Store.updateEvent`가 이동시간을 다시 조회한다(`Store.swift:953` → `applyEstimate` :980). progress.md:87은 조회 결과가 호출마다 조금 다를 수 있다고 스스로 적었다. 1분만 흔들려도 AC-007이 문언상 실패한다. — Severity: minor — Class: blocking — Required fix: AC-007과 스크립트 7번에 "`약 Z분`(±2분)"을 적는다.

D7. expected-chip-text-literal — spec.md:L141·L170-L171(AC-005 (다) :171 포함) — 기대 칩 글자를 `강남역`으로 못박았다. 저장되는 이름은 카카오 `place_name`이다(`PlaceSearch.swift:32`·`:43` → `choosePlace` `AddEventView.swift:324`). 검색어 "강남역"의 후보 이름이 `강남역` 그대로라는 보장은 없다(예: 호선이 붙은 이름). **가설이다 — 카카오를 호출해 확인하지 않았다.** — Severity: minor — Class: optional — Required fix: 기대를 "1번에서 고른 후보의 이름 그대로"로 적고, 1번에서 그 이름을 X·D와 함께 기록하게 한다.

D8. AC-003-judgment-and-proxy — spec.md:L129 — (1) "(검토자 판정 — `code-safety` 렌즈)"가 이진 판정이 아니다. (2) `grep -c '늘 함께'` = 0은 "거짓 단언 제거"의 대리 신호인데, 수정 뒤에는 그 단언이 참이 된다. `:166`이 `:178`과 짝을 이루면 반쪽 쓰기가 남지 않는다 — 쓰기 자리 :174/:169, :178/:166, :276/:270, :447/:449가 모두 이름과 좌표를 함께 적는다. 따라서 이 신호는 거짓 문장이 아니라 수정 후 참이 될 문장을 지우도록 강제한다. REQ-011의 실질 요구는 둘째 절("출발지 줄의 반쪽 쓰기 결과를 이름으로 적는다")이다. — Severity: minor — Class: optional — Required fix: 통과 기준을 기계 신호('프리필' ≥1과 "도달 불가" 단언의 제거 또는 한정)로 두고, 검토자 판정은 기록 항목으로 내린다.

D9. REQ-004-where-semantics — spec.md:L97 — GEARS의 `Where`는 능력 게이트·기능 플래그·정적 설정이다. "Where the sheet creates a new event, or edits an event whose saved origin is nil"은 모드나 상태 조건처럼 읽힌다. `editing`이 시트 인스턴스의 생성 인자라 정적 설정으로 옹호할 수는 있어 MP-2 실패로 보지 않았다. — Severity: minor — Class: optional — Required fix: "Where the sheet is constructed in create mode (no event to edit), or with an event whose saved origin is nil, …"처럼 정적 설정임을 문장에 드러내거나 `While`로 바꾼다.

D10. normative-korean-tails-and-HOW — spec.md:L91·L103·L107 — 요구사항 불릿의 GEARS 문장 뒤 한국어 꼬리에 규범 내용이 섞여 있다. 정확한 코드 모양(:91 "`:166`을 `allowsCustom: true, chosen: editing?.origin?.name, busy: …`로"), 선호("줄 수를 늘리지 않는 편집을 우선한다" :103·:107), 무변경 파일 목록(:107)이다. 요구사항에 함수·변수 이름(`chosen`·`confirmedPlace`·`bootstrap`·`prefillOrigin`)도 들어 있다(RQ-3/RQ-4). 한 줄 수리의 Tier S 계약이라 실용적이고, AC-001(:121)도 정확한 식 `chosen: editing?.origin?.name`을 grep으로 요구한다. 그래서 같은 의미의 다른 구현(예: `editing?.origin.map(\.name)`)은 AC-001에 떨어진다. D-1 (a)가 확정되면 이 결박은 결정의 일부가 된다. — Severity: minor — Class: optional — Required fix: 꼬리 가운데 규범 문장을 GEARS 문장으로 올리거나 "근거:"·"수리 모양(참고):" 표식으로 비규범임을 밝힌다.

D11. REQ-004-nil-half-unobserved — spec.md:L145 — REQ-004 뒤 절반(nil 출발지 편집)은 "코드 읽기로만 판정한다 … 이것은 관측이 아니다"로 정직하게 적혀 있지만, 판정에 쓰는 명령이 없다. — Severity: minor — Class: optional — Required fix: "AC-001의 첫째 grep 결과(옵셔널 체이닝 식)가 판정 근거"라고 명령에 묶는다.

D12. AC-005-outcome-na-pass — spec.md:L137·L171 — (나)(5초 안에 위치를 못 얻음)로 분류되면 AC-005의 통과 조건이 "분류됨"뿐이고, `progress.md`에 요구하는 "X/Y/D 값"의 Y는 (나)에서 생기지 않는다(저장이 회색). — Severity: minor — Class: optional — Required fix: (나)에서 기록할 값(Y 없음)과 재시도 상한(예: 한 번 더 뒤에도 (나)면 결과로 인정)을 적는다.

D14. edit-mode-location-request-removed — Shared/AddEventView.swift:L376-L379(코드 읽기) — 수리 뒤 편집 시트는 열릴 때 위치를 요청하지 않는다(`:424`가 곧장 돌아옴). 출발지 검색의 기준 좌표(`near: location.currentLocation`, :378)는 이제 `App.swift:90`의 앱 시작 측위에만 기댄다. 시작 측위가 실패한 세션에서는 편집 중 출발지 검색이 기준 좌표 없이 나간다. 결함이 아니라 수리가 바꾸는 도달 가능성이고, **관측하지 않았다**. — Severity: minor — Class: optional — Required fix: M3 `code-safety`·`ui-design` 렌즈 입력으로 넘긴다(SPEC 수정 불필요).

D15. frontmatter-extras — spec.md:L11·L15-L16 — 스키마는 `module`을 "path-like"(영향 디렉터리)로 정의하는데 값이 `shared-ui`다(실제 디렉터리는 `Shared/`). `related_specs`·`kanban_card`는 스키마 밖 필드다(선택 필드 목록에는 `depends_on`이 있다). lint는 통과하고 자매 SPEC(UIKIT-005)도 같은 값을 쓴다. — Severity: minor — Class: optional — Required fix: 저장소 관례로 유지해도 된다. 바꾼다면 `module: "Shared"`.

## Regression Check (Iteration 2+ only)

해당 없음 — 1회차.

## Recommendation

**FAIL — 두 경로로 나눠 처리한다.**

1. **리드(오케스트레이터) — 게이트 먼저.** `plan.md` §2의 세 항목(D-1 :47, D-2 :57, Tier :66)을 `AskUserQuestion`으로 결정한다(D1). manager-spec이 대신 정할 수 있는 항목이 아니다. 판단 재료: (a)안은 코드 1줄이고, 함수 본문을 바꾸지 않으며, 카드 전환 전 화면(`d3c9327` :73-74·:410·:425)의 동작으로 돌아간다. 이것은 이 감사가 확인한 사실이다.
2. **manager-spec — 게이트 결과를 받아 한 번에 고친다.**
   - 표식 3건을 결정 사실로 바꾸고, REQ-010·REQ-021의 조건절과 spec.md:117·:212를 갱신한다(D1). D-1 (b)면 REQ-010을 철회하거나 새로 쓰고 AC-002 기대값을 구체화한다.
   - REQ를 001~008로 다시 매기고 참조를 모두 옮긴다(D2). plan.md:18 매핑의 "002→005"를 지운다(D4).
   - REQ-020의 run 선언에 이 SPEC 디렉터리를 넣는다(D3).
   - AC-007 6번의 기대 글자를 8번처럼 두 형태로 받는다(D5). `약 Z분`에 ±2분을 준다(D13).
   - HISTORY :25의 수를 바로잡는다(F5·F6 둘, 고친 곳 셋)(D6).
   - optional D7~D12·D15는 manager-spec이 재량으로 판단한다. D14는 run의 M3 렌즈에 넘긴다.
3. **2회차 감사 범위:** D1~D6·D13의 델타와 그 회귀 확인. D-1이 (a)이고 위 수정이 문구 범위에 그치면 코드 인용은 다시 잴 필요가 없다 — `Shared/`는 무변경이다(`git diff --quiet 73ceb43 -- Shared/ project.yml CHECKLIST.md proxy/` exit 0).

**통과 근거가 된 사실(수리 설계 자체의 건전성).** 결함 서술(§1.1~§1.5)과 수리 모양(REQ-001)은 트리에서 성립한다. 출발지 줄(:165-166)에는 `chosen:`이 없고 목적지 줄(:169)에는 있다. 씨앗 :178은 `confirmedPlace`(:538)의 `chosen == nil` 거름에 막혀 읽히지 않는다. 연쇄 :149→:465-466, :151→:424→:425-435, :428→:441→:447-449→:459도 코드와 한 줄씩 맞는다. 수리 뒤에도 "현재 위치" 칩 직접 탭은 동작한다 — `choose`(:276)가 `favoritePlaces[hereMarker]` = nil로 옛 좌표를 먼저 지우므로 :424 가드가 씨앗 좌표에 막히지 않는다. REQ-002·AC-007 8번의 전제가 성립한다. 직접입력 경로는 장소 줄에 없다(`EditCardView.swift:310`, 루트 plan.md 후속 14). 선택된 직접입력 칩을 탭하면 `openCustom`(`EditCardView.swift:123`·`:418`)만 불리고 값이나 좌표는 바뀌지 않는다. 수리가 새로 깨우는 쓰기 경로는 찾지 못했다(D14는 읽기 경로다).

## 검증 증거 (이 감사가 직접 돌린 명령)

| 주장 | 명령 | 관측 |
|---|---|---|
| 기준 트리 | `git rev-parse --short HEAD` · `git branch --show-current` · `git rev-parse --short origin/master` | `73ceb43` · `WT-origin-overwrite` · `73ceb43` |
| 소스 무변경 | `git diff --quiet 73ceb43 HEAD -- proxy/ Shared/ project.yml`; `git diff --quiet 73ceb43 -- Shared/ project.yml CHECKLIST.md proxy/` · `git status --short` | 둘 다 exit 0 · `?? .moai/specs/SPEC-UIKIT-007/`뿐 |
| REQ·AC 수 | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^#### AC-' spec.md` | 8 · 8(Tier S 상한 8·8) |
| Out of Scope | `grep -n '^### Out of Scope' spec.md` | :192·:197·:202·:206 |
| lint | `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` | `✓ No findings` |
| MP-7 | `grep -n '\[NEEDS CLARIFICATION' plan.md`; `ls research.md` | :47·:57·:66; 파일 없음 |
| D7 | 참조 SPEC 추출 후 `status:` | 002·003·005·006 `completed` |
| D8 | `grep -c 'syscall'` 3파일 | 0·0·0 |
| Tier 기준 | 주 체크아웃 `spec-workflow.md:138-150` | S: <300 LOC · <5 files · 0.75 · REQ/AC 8·8 (plan.md:16의 `:140` 인용 일치) |
| AddEventView 인용 | `wc -l`; `awk` 60-100·110-260·264-475·525-600 | 645줄; :119·:142-152·:149·:151·:165-169·:174·:177-178·:231·:246·:276·:292-308·:302-303·:412-418·:423-436·:424·:426·:433·:438-460·:441·:447-449·:452-455·:459·:465-466·:531-539·:573·:595 전부 일치 |
| Store 인용 | `awk` 328-353·800-820·925-997 | :332-352·:343·:345·:804-816·:812·:930-970·:944·:953·:954·:961-969·:965·:968·:975·:992-993 일치 |
| 호출부 | `grep -n 'updateEvent(' Shared/*.swift` | AddEventView:595 · Store:343 (+정의 :930) |
| 기타 인용 | LocationManager :51-53·:61·:132·:154-157 · EditCard :171-174·:181·:240 · ActivityDetailView :141-144 · AIAssistant :550-555·:2181(→:2238 `modifyEvent`) · EventDetailView :75·:79·:190·:197 · ContentView :228 · Models :157-158 · GoogleCalendarService :181-185 · CLAUDE.md(워크트리) :52·:53·:59-63 · `.gitignore:28` · 루트 plan.md :73·:530·:533 · UIKIT-006 progress §E.4.2(:326·:344-346) | 전부 일치 |
| 이력 | `git log --format='%h %ad %s' --date=short -- Shared/AddEventView.swift`; `git show d3c9327:…`(:73-74·:410·:425); `git show 1b98e14:…`(:148-149·:155·:159·:495-496); `git show 02481c6 -- Shared/AddEventView.swift` | d3c9327→1b98e14(t2 M4)→6032343→8158159→02481c6(t6); 출발지 보존·결함 유입·주석 신설(`+…늘 함께`) 모두 확인 |
| 기준선 수치 | `grep -c` 'editing?.origin' / 'chosen: editing?.origin?.name' / 'chosen: editing?.destination.name' / '늘 함께' / 'hereMarker'; `grep -B8 … \| grep -c '프리필'`; CHECKLIST `grep -o 'AddEventView[.swift]*:[0-9]' \| wc -l` · `grep -c 'AddEventView'` | 0 · 0 · 1 · 1 · 8; 0; 0 · 6 (plan.md §5와 일치, `#L` 앵커 인용도 0) |
| 주 체크아웃 | `git worktree list` | `/Users/iseongmin/Projects/besir 291db49 [master]` |
| 교차 모델 | `mcp__moai__audit_multi`(gates claude required·codex off·glm advisory) | overall `needs-attention`, glm `inconclusive`(fail-open) |

**미검증(Gaps).** 빌드·`npm test`·시뮬레이터·가드 드라이버는 금지 조건대로 하나도 돌리지 않았다. D5(역지오코딩 타이밍, 권한 복원 시 앱 종료 여부), D7(카카오 후보 이름), D14(편집 중 검색 기준 좌표)는 코드 읽기 가설이고 관측이 아니다. 결함 자체의 존재도 SPEC이 밝힌 대로 코드 읽기와 이력 대조로만 뒷받침되며, 첫 관측은 파트 A다. macOS 편집 시트는 보지 않았다.

**잔여 위험.** 파트 A가 (다)로 나오면 전제가 무너진다(REQ-021이 그 경로를 이미 갖고 있다). ±2분 허용치는 실측값이 아니다(progress.md:87). GLM이 응답하지 않아 이 판정은 단일 모델 판정이다.
