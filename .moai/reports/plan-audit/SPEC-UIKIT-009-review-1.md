Model: claude-opus-5-5

# SPEC Review Report: SPEC-UIKIT-009
Iteration: 1/3
Verdict: FAIL
Overall Score: 0.73

> Reasoning context ignored per M1 Context Isolation. 호출자는 작성자 추론을 넘기지 않았고, 작업 지시(경로·보고서 위치·재측정 요구)만 받았다. 판단 근거는 SPEC 디렉터리의 산출물 일곱 개와 기준 트리 `b2c3987`의 코드·로그를 이 세션이 직접 읽거나 명령으로 잰 결과뿐이다.
>
> 입력 계약(Tier L): `spec.md` · `plan.md` · `acceptance.md` · `design.md` · `research.md` 다섯을 전부 읽었고, `spec-compact.md`(앞 40줄)·`progress.md`도 대조했다.
>
> 교차 모델 감사: 주 체크아웃의 `.moai/config/sections/workflow.yaml`(이 워크트리에는 `.moai/config/`가 없다)이 `audit.model: multi`, gates `claude: required · codex: off · glm: advisory`였다. `mcp__moai__audit_multi`를 이 게이트로 호출했고 결과는 `overall_verdict: fail`, GLM은 `inconclusive`("z.ai response carried no content", fail-open)였다. 판정은 이 감사자의 것이다. 정리 스킬 `moai-ref-cross-model-audit`는 이 세션의 스킬 목록에 없어 불러오지 못했다.

## Must-Pass Results

- [PASS] MP-1 REQ number consistency: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → REQ-001부터 REQ-022까지 빠짐·중복 없이 이어지고 세 자리 영채움이 일정하다(`grep -c` = 22). AC도 `## AC-001`~`## AC-024`, 24건으로 이어진다.
- [PASS] MP-2 EARS/GEARS format compliance (판정 계층: **요구사항 계층 `spec.md` REQ-XXX만**. `acceptance.md`의 Given/When/Then AC는 검증 계층이라 여기서 채점하지 않았다): 22건 모두 GEARS 문형을 따른다. 예: REQ-001 "When the user chooses 편집 … the app shall open …"(spec.md:L101, Event-driven), REQ-006 "While a travel leg's `linkedActivityId` does not resolve … the app shall treat …"(L111, State-driven), REQ-009 "The app shall never create …"(L124, Unwanted), REQ-008 안의 "where calendar sync is enabled …, a created leg shall be queued"(L122, Where 게이트). 흠은 있으나 형식 실패는 아니다 — 문형 이름표 "Event-detected"(L124·L126)가 GEARS 다섯 패턴에 없는 이름이고, REQ-008·REQ-019처럼 `shall` 절 넷~아홉을 한 REQ에 묶은 경우가 있다(D11 참고, optional).
- [PASS] MP-3 YAML frontmatter validity: spec.md:L2-13에 12개 필드가 전부 있고 형이 맞다 — `id: SPEC-UIKIT-009` · `title` · `version: "0.1.0"`(따옴표 semver) · `status: draft`(8값 열거 안) · `created: "2026-09-30"` · `updated: "2026-09-30"` · `author` · `priority: P1` · `phase` · `module` · `lifecycle: spec-anchored` · `tags`(쉼표 문자열). 거부 별칭(`created_at`·`updated_at`·`labels`·`spec_id`)은 없다. 선택 필드 `tier: L`(L14)은 스키마의 S|M|L 열거에 맞다. 이 세션이 직접 돌린 `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` → `✓ No findings — all SPEC documents are valid`.
- [N/A] MP-4 Section 22 language neutrality: 단일 언어(Swift, iOS·macOS 앱) 프로젝트 SPEC이다. 여러 언어 도구를 다루지 않는다.
- [PASS] MP-5 D7 cross-SPEC reconciliation: 다섯 산출물에서 뽑은 참조는 SPEC-UIKIT-003·004·005·007·008(자기 자신 009 제외)이고, 다섯 모두 `.moai/specs/<ID>/spec.md`가 있으며 `status: completed`다. retired·superseded·archived가 없으니 BLOCKING이 없다. SPEC-UIKIT-005의 "결정 게이트 표식은 `plan.md` §2에만" 관례는 그 SPEC의 HISTORY 0.1.0(spec.md:L25)에 실제로 적혀 있음을 확인했다.
- [PASS] MP-6 D8 cross-platform discipline: `grep -c 'syscall'` 결과가 SPEC 디렉터리 일곱 파일 모두 0이다. 해당 사항이 없어 자동 통과다.
- [FAIL] MP-7 clarification gate: `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` → **13건**, 전부 `plan.md`(L70·L81·L91·L101·L112·L123·L133·L143·L154·L164·L174·L185·L195, D-1~D-13), `research.md`는 0건이다. 작성자가 관례대로 일부러 남긴 착수 승인 게이트이고 `progress.md` §E.1(L7)도 `kickoff_gate: pending`으로 적었다. 그래도 점수와 상관없이 must-pass 실패다. 오케스트레이터(칸반 리드)가 `AskUserQuestion`으로 13건을 운영자에게 묻고, 그 답을 반영해 manager-spec이 표식을 걷어낸 뒤에야 이 기준이 통과한다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.75 | 0.75 | 대부분 해석이 하나다. 좌표 인용 정확도가 이례적으로 높다 — 이 세션이 표본 약 90곳을 다시 쟀는데 전부 일치했다(아래 § 재측정 표본). 모호한 곳: REQ-015(L150)의 "same lane at the same lane width"는 E6(design.md:L158, 구성원 O1 [0,.5]·A [0,1])·E3b와 문자 그대로는 어긋나고 "lane"이 바깥 칸이라는 정의가 없다. AC-009 (3)(acceptance.md:L173)은 힌트를 쓸지 정하지 않아 경쟁 경로에 닿는지가 실행자 재량이다 |
| Completeness | 1.0 | 1.0 | HISTORY(spec.md:L21-25) · WHY §0-§1(L27-90) · WHAT §2(L92-171) · HOW `design.md` · 요구사항 22 · AC 24 · 범위 밖 H3 `### Out of Scope — …` 6개(L175·L180·L185·L190·L194·L199), 각각 `-` 항목이 있다. frontmatter 12필드가 모두 있고 Tier L 산출물 다섯이 다 갖춰졌다 |
| Testability | 0.55 | 0.50 | AC 대부분은 명령 하나로 판정되도록 잘 짜여 있다. 다만 판단이나 비결정성이 끼는 AC가 여럿이다 — AC-016 (2) "얇은 자리만 남는다"(L262) · AC-016 (4)와 AC-005 (3)의 "조회를 거친다"(L264·L113)가 코드 읽기에 기댄다 · AC-019 (4)(5)는 눈으로 확인한다(L306-307) · AC-018 (3)은 네트워크가 있어야 참이 된다(D5) · 스크립트 20의 기대값이 코드 경로와 반대다(D3) |
| Traceability | 0.75 | 0.75 | REQ 22건 모두에 AC가 하나 이상 있고(acceptance.md:L15-40), 없는 REQ를 가리키는 AC도 없다. 그러나 REQ 안의 절 몇 개는 대응 AC가 없거나 갭으로만 남았다(REQ-003 재추정 · REQ-008 캘린더 · REQ-012 알림·캘린더 · REQ-011 안내 — D8). `plan.md` §0의 REQ→AC 표(L22)와 §1 카드 표(L31-33)가 AC 매트릭스와 어긋난다(D9) |

집계: 네 차원의 조화평균은 4 / (1/0.75 + 1/1.0 + 1/0.55 + 1/0.75) ≈ **0.73**이다. Tier L 통과선 0.85(`spec-workflow.md` § SPEC Complexity Tier, 주 체크아웃 L142)에 못 미친다. MP-7 실패만으로도 이미 FAIL이다.

## Defects Found (structured defect-list)

D1. MP7-CLARIFY — plan.md:L70·L81·L91·L101·L112·L123·L133·L143·L154·L164·L174·L185·L195 — 해소되지 않은 `[NEEDS CLARIFICATION: D-n …]` 표식이 13건 있다(clarification gate). — Severity: critical — Class: blocking — Required fix: 오케스트레이터가 D-1~D-13을 `AskUserQuestion`으로 운영자에게 묻는다(질문 하나에 선택지 4개까지이므로 여러 라운드로 나눈다). 답을 받은 뒤 manager-spec이 결정마다 표식을 "해소: (x) 채택 (날짜, 운영자)"로 바꾸고, 권장과 다른 답이 나온 결정은 `plan.md` §2의 "바뀌는 줄"에 적힌 REQ·AC를 고친다.

D2. AC022-BASE — acceptance.md:L11 · L334-343 (AC-022), plan.md:L248 — 모든 카드의 범위 명령이 고정 기준 `b2c3987`에 대고 `git diff --name-only`와 `--numstat`을 잰다. 그런데 MB는 "MA 뒤"(plan.md:L49)이고 기본 배달은 직렬이라(L26), MB·MC의 마지막 커밋에서 `b2c3987`과 비교하면 앞 카드의 변경이 딸려 들어온다. 예를 들어 MB에서는 `Shared/Store.swift`가 잡혀 MB 선언 목록(L49) 밖이 되고, 크게 고친 파일도 Store·GuardDriver·EditCard·AddActivityView·ActivityDetailView로 5 > 4가 된다. 이렇게 되면 AC-022 (1)(2)는 MB·MC에서 구조적으로 만족할 수 없다. REQ-022(spec.md:L171) "each of which … at most four files"와도 부딪친다. — Severity: major — Class: blocking — Required fix: AC-022의 기준을 "그 카드의 기준 커밋"(카드 워크트리를 만든 커밋, 또는 앞 카드의 병합 커밋)으로 바꾸고 카드마다 그 SHA를 `progress.md` §E.2에 적게 한다. 누적 불변식인 AC-019 (1)(3)(4)는 `b2c3987`을 그대로 써도 된다. 둘을 구분해 적는다.

D3. SCRIPT20-WARNBLOCK — acceptance.md:L410(스크립트 20) · L187(AC-010 [사람]) · L368(경계 대응표 "departureDate가 nil"), spec.md:L126(REQ-010 근거) — 스크립트 20은 네트워크를 끈 채 **오는 편**을 만들면 "경고 블록(삼각형 아이콘)"이 그려진다고 기대한다. 그런데 출발 기준 추정은 추정을 확인하기 전에 `event.departureDate = departureDate`를 넣고(Store.swift:1025, 추정 실패로 빠지는 guard는 :1031), 시간표는 `departureDate == nil`일 때만 실패 블록을 고른다(ContentView.swift:511). 그러니 이동시간 계산에 실패한 오는 편도 16분짜리 일반 이동 블록(수단 아이콘)으로 그려지는 것으로 읽힌다(:579-580). REQ-010 근거의 "계산 실패는 `departureDate`를 nil로 남기고(`Store.swift:1000`·`:1006`)"는 도착 기준(`applyEstimate`)에만 맞는 말이다. design.md:L91이 ":1025에서 출발이 추정 앞에 대입된다"를 스스로 적었으니 문서 안에서도 서로 어긋난다. [증거 수준: 코드 읽기. 시뮬레이터로 재현하지는 않았다] — Severity: major — Class: blocking — Required fix: 둘 중 하나를 고른다. (a) 스크립트 20과 AC-010 [사람]을 **가는 편**을 오프라인으로 만드는 시나리오로 바꾼다(그러면 실패 블록이 된다). (b) 오는 편 실패도 경고로 보이게 하는 요구사항을 새로 두고 REQ·AC·파일 목록에 넣는다. 어느 쪽이든 REQ-010 근거 문장과 경계표 행을 역할별로 나눠 다시 쓴다.

D4. PASSCOUNT-ARITH — acceptance.md:L380(§ 통과 수) · L57(AC-001) · L110-114(AC-005) · L122-132(AC-006) — (i) AF 하한 합 "58"이 AC-001의 `AF-001-01`~`03`(하한 3, L57)을 빠뜨렸다. 넣으면 AF는 61, 합은 94, T 하한은 451이다. (ii) AC-006 "하한 10, `AG-006-`"라 했지만 10개 항목 중 (1)(2)(3)(9)는 `grep` 명령이고 "(드라이버)"로 표시된 것은 (4)-(8)·(10) 여섯뿐이다. AC-005 "하한 4"도 (3)이 grep이고 (4)는 갭이다. 드라이버 라벨의 하한이 드라이버가 낼 수 없는 항목까지 세고 있다. 이 하한이 카드별 누적 바닥(MA ≥ 415 · MB ≥ 428 · MC ≥ 448)을 정하므로 run 레인이 그 바닥을 맞추려고 억지 단언을 만들 수 있다. — Severity: major — Class: blocking — Required fix: AC마다 "드라이버 하한"과 "명령(grep) 항목"을 AC-016처럼(L260 "하한 2 드라이버") 따로 적고, § 통과 수의 AF·AG·AH 합과 카드별 누적 바닥을 다시 센다(AC-001 포함).

D5. AC018-NONDET — acceptance.md:L286·L291(AC-018 Given·(3)) — 가는 편 드래그의 기대("여유가 20분에서 5분으로")는 `adjustBuffer`가 `guard let travel = event.travelSeconds else { return }`(Store.swift:1152)를 지나야 성립한다. 그런데 Given에서 힌트가 붙은 것은 오는 편뿐("오는 편(힌트 30분)")이고 가는 편에는 힌트가 없다. 드라이버는 프록시가 비어 있어 오프라인이면 이동시간 계산에 실패하므로(acceptance.md:L46이 스스로 적었다), 이 특성화 단언은 네트워크 상태에 따라 ✓/✗가 갈린다. "기준 트리에서도 ✓여야 한다"(L294)는 요구도 결정적으로 지킬 수 없다. — Severity: major — Class: blocking — Required fix: AC-018 Given의 가는 편에도 이동시간 힌트를 준다. 기준 트리에는 `addActivityWithTravel`에 힌트 인자가 없으니 `addEvent(… travelSecondsHint:, linkedActivityId:)`로 직접 만든다고 적는다.

D6. REQ020-SCOPE — spec.md:L105(REQ-003 근거 "REQ-020이 먼저 재현하게 한다") · L167(REQ-020 목록) · acceptance.md:L82-88(AC-003) · L320(AC-020 (5)) — REQ-003 근거는 "제목·장소가 구간에 미치지 않음"을 REQ-020이 먼저 재현하게 한다고 하지만, REQ-020이 나열한 결함에는 이 항목이 없고 AC-003에도 "기준 트리에서는 ✗" 표지가 없다. AC-020 (5)의 재현 목록(AC-004 (1)(5) · AC-012 (2))에는 AC-005 (1)도 빠졌다. REQ-020 본문의 "the current packing result … shown by an assertion run on the unmodified code"는 ContentView를 드라이버가 컴파일하지 않으므로 추출(C1)을 거치지 않고는 지킬 수 없다. 근거 문단은 이를 인정하지만 요구사항 문장 자체는 그대로다. — Severity: minor — Class: blocking — Required fix: REQ-020 목록·AC-003·AC-020 (5)를 한 벌로 맞춘다(REQ-003 결함을 넣든지, REQ-003 근거에서 그 주장을 빼든지). 배치 절은 "on the behavior-preserving extraction commit (C1)"으로 고쳐 쓴다.

D7. REQ015-LANE — spec.md:L150(REQ-015) · design.md:L155·L158(E3b·E6) · acceptance.md:L249(AC-015 (5)) — "draw every member of the group in the same lane at the same lane width"를 문자 그대로 읽으면 E6(O1 [0,.5]·A [0,1])이나 E3b(A·R [0,.25]/[.25,.5])처럼 묶음 안에서 폭이 갈리는 기대값과 충돌한다. "lane" = 바깥 칸이라는 정의가 spec.md에 없다. — Severity: minor — Class: blocking — Required fix: REQ-015에 "lane = the group's outer column range; members may subdivide it per REQ-017"을 한 줄로 정의한다.

D8. REQ-CLAUSE-COVERAGE — spec.md:L105(REQ-003 "travel time re-estimated") · L122(REQ-008 캘린더 절) · L128(REQ-011 "keep its notice") · L137(REQ-012 "notification cancelled and its calendar item removed") — 이 절들은 대응 AC가 없거나 갭으로만 남았다. AC-003에는 재추정 확인이 없다. AC-008은 L162에서 캘린더를 갭으로 명시했다. AC-011은 L199에서 안내를 "운영자 재량"으로 뒀다. AC-012에는 알림·캘린더 확인도 갭 표기도 없다. — Severity: minor — Class: blocking — Required fix: 절마다 (a) 검증할 수 있는 단언(예: AC-003에 "장소가 바뀐 구간의 `travelSeconds`가 새 끝점으로 재계산되거나 nil이고 결과 플래그와 일치")을 더하거나, (b) AC-008처럼 "드라이버가 못 보는 것" 갭 줄을 명시한다. AC-012는 적어도 (b)를 붙인다.

D9. PLAN-MAP-DRIFT — plan.md:L22(REQ→AC 표) · L31(MA 행 "018(1)") · L43(A1이 드래그 특성화 셋을 모두 MA에 둠) · acceptance.md:L40(AC-024 "(+010·011)") · L9(AF = MA 절) — plan §0 표에는 010→010·023, 011→011로 적혀 AC-024가 빠졌다. §1 표는 MA에 AC-018 (1)만, MC에 015~018을 배정했지만, A1 목록과 `AF-018-` 접두(MA 절)는 (1)-(3)을 전부 MA에 둔다. AF 라벨을 쓰는 AC-005·010·013·014도 §1 표에서는 MB에 걸려 있어 "AF = MA" 규칙과 어긋난다. — Severity: minor — Class: blocking — Required fix: 한 곳(acceptance.md AC 매트릭스)을 단일 출처로 정하고 plan.md §0·§1 표를 그 기준으로 다시 쓴다. 단언 접두는 "어느 카드가 더하는가"로 정한다.

D10. AC-JUDGMENT — acceptance.md:L59(AC-001 (3): 기준 1 → 최종 1이라 변화를 가려내지 못하고 나머지를 렌즈 읽기에 맡김) · L113(AC-005 (3) "그 자리는 조회를 거친다") · L262(AC-016 (2) "얇은 자리만 남는다") · L264(AC-016 (4) 코드 대조) · L306-307(AC-019 (4)(5) 눈 확인) — 명령 출력만으로 PASS/FAIL이 갈리지 않는 부분이 있다. 매달린 링크 → 단독 폼 라우팅(REQ-006 편집 절)은 사람도 재현할 수 없다고 AC-005 (4)가 밝혔으니 기계 판정이 사실상 없다. — Severity: minor — Class: optional — Required fix: 가능하면 이진 대리 지표로 바꾼다. 예: AC-016 (2) → `grep -c 'columnEnds' Shared/ContentView.swift` = 0. AC-005 (3)·AC-001 (3) → 편집 라우팅과 `showsTitle`이 부르는 조회 함수 이름이 각 1회라는 `grep -c`. 대리 지표를 못 만드는 항목은 "갭"으로 분류해 적는다.

D11. REQ-ATOMICITY/HOW — spec.md:L122(REQ-008, 절 4개) · L152(REQ-016 "one pure function in a source file the guard driver compiles") · L165(REQ-019, 절 9개) · L169-171(REQ-021·022, 배달 절차) — REQ 하나에 서로 독립인 `shall` 절 여러 개가 묶였고, 규범 문장에 구현 방식(파일·함수·프레임워크 이름)과 배달 절차가 들어 있다. 대부분 `CLAUDE.md` 계약(1~6)을 옮긴 것이라 프로젝트 제약으로서는 정당하다. — Severity: minor — Class: optional — Required fix: 선택 사항이다. 원한다면 REQ-008·REQ-019를 절 단위로 나눠 AC와 1:1로 잇는다. 이 경우 REQ 수가 Tier L 상한 25에 닿는지 먼저 센다.

D12. LABEL-EVENT-DETECTED — spec.md:L124·L126 — 문형 이름표 "Event-detected"는 GEARS 다섯 패턴에 없다. 두 REQ의 문장은 Unwanted와 Event-driven 형식이다. — Severity: minor — Class: optional — Required fix: 이름표를 "Unwanted · Event-driven"과 "Event-driven"으로 고친다.

D13. RANGE-LABEL — spec.md:L128(REQ-011 "반복 경로 범위 `:628-700`") vs research.md:L43(표 17의 `awk … $1>=620 && $1<=700`) — 같은 측정을 두 범위로 적었다. 결론("대입 없음")은 이 세션이 `grep -n linkedActivityId Shared/Store.swift`로 확인했고 옳다(대입은 :591 한 곳, 600~1100 사이 참조는 :1120 하나). — Severity: minor — Class: optional — Required fix: 두 곳의 범위를 하나로 맞춘다.

## 재측정 표본 (이 세션이 기준 트리 `b2c3987`에서 직접 확인)

- 트리 상태: `git rev-parse --short HEAD` → `b2c3987`, `git branch --show-current` → `WT-edit-card-unify`, `git status --short` → `?? .moai/reports/t17/` · `?? .moai/specs/SPEC-UIKIT-009/`. `git diff --stat b2c3987 -- Shared Tools` → 무출력(코드 변경 없음).
- spec.md §0 표: 파일 길이 11개가 전부 일치(`wc -l`). `linkedActivityId` 18곳이 줄 목록까지 research.md 표 5와 같다. `activities|ActivityBlock|…` 0/0. `EditCardView(` 4곳(AIChatView:110 · AddEventView:68 · ActivityDetailView:64 · AddActivityView:72). `addActivityWithTravel(` 호출 3곳(정의 Store:189 제외). `.conflicts(` 4곳. `isSamePlace(` 6줄(:1085·1348·1779·1968·2192 + 정의 :2917).
- AC 기준값: 빌더 5 · `fields.insert/remove` 11 · `@State` 18 · 키 리터럴 AddActivityView 58 / ActivityDetailView 0 / EditCard 0 · 여섯 문구 각 1 · `import SwiftUI` in EditCard 0 · 같은 제목 filter 리터럴 1 · `ActivityDetailView(activityId` in EventDetailView 0 · `딸린 이동` 0 · `linkedActivityId == nil` in ContentView 1 · `gap \* CGFloat|1 / CGFloat(p.columns)` 줄 :748·:765. 전부 SPEC의 기준값과 같다.
- 코드 좌표(Read로 확인): Store :189-230 · :211 · :214/:222 · :217/:225 · :219/:227 · :301-330 · :321 · :322 · :326-328 · :333-340 · :356 · :368-384 · :393-397 · :572-583 · :589 · :591 · :606-608 · :958 · :964 · :979-980 · :985-991 · :1000/:1006 · :1008-1012 · :1025 · :1033 · :1065-1086 · :1088-1114 · :1122-1123 · :1126-1130 · :1158 · :1273-1282 · :1287-1300 · :1303-1313 · :1320-1321 · :1494-1498. ContentView :37 · :464/:478 · :511 · :533-536 · :542/:557-563 · :567-569 · :651 · :683 · :699-742 · :711 · :717-726 · :730 · :745-750 · :759-773 · :780-791 · :799. EventDetailView :75 · :88 · :91-92 · :331-333 · :356 · :368 · :373 · :395. AddActivityView :8 · :16 · :23 · :37-53 · :169-267 · :190-203 · :330-376 · :508 · :516-542 · :596. ActivityDetailView :64 · :68 · :85 · :102 · :227 · :242 · :322/:329. EditCard :1 · :7-8 · :69 · :109. Models :154 · :180-182 · :186-190 · :199 · :213 · :498. NotificationManager :10-14 · :32-34. GuardDriver :30-32. AIAssistant :567-568 · :2038 · :2821 · :2826 · :2909. SettingsView :78. CHECKLIST :538-540. 루트 plan.md :105. **어긋난 좌표 0건**(D13은 같은 측정을 두 범위로 적은 표기 문제다).
- 기준선 로그(`.moai/state/verify/t17-plan/`): `grep -c '^  ✓ ' driver-run.log` = 357 · `✗` = 0 · `tail -3` = `357/357 통과` / `[실제 데이터] 대조 통과 — …` / `run_exit=0`. `^SwiftCompile` 42/38. `BUILD SUCCEEDED` ios :944 · mac :587. 툴체인 안내를 뺀 경고 0/0. 전체 `warning:` 2/1. driver-compile `warning:` 24. 기존 드라이버 라벨 접두는 AA·AB·AC·AD·AE·O·P·C·D·W·X이고, 새 접두 AF·AG·AH와 충돌하지 않는다(현재 0건).
- REQ-021 인용 하한: CHECKLIST Store 39 · ContentView 5 · Models 6 · AddEventView 6 · EditCard 3 · AddActivityView 2 · ActivityDetailView 1 · EventDetailView 1 · GuardDriver 1 / 루트 plan.md Store 4 · AddActivityView 9 · AddEventView 6 · EditCard 3 · ActivityDetailView 2 · Models 1. SPEC 값과 전부 같다.
- design.md §6 실례: E1·E2·E3·E3b·E4·E5·E6·E7·E8의 새·옛 결과를 `positionedBlocks`(ContentView:699-742)의 정렬·무리 끊기·첫 빈 열 규칙으로 손 추적했고 모두 SPEC의 표와 같았다. 손 추적은 실행이 아니므로 가설 수준이라는 SPEC의 표기는 그대로 유효하다.

## Gaps (이 감사가 관측하지 않은 것)

- 드라이버·빌드·시뮬레이터를 실행하지 않았다. 기준선 수치는 오케스트레이터 로그를 이 세션이 직접 세어 확인한 값이다.
- D3은 코드 읽기에 근거한다. 시뮬레이터에서 오프라인으로 오는 편을 만들어 보지 않았다.
- `mcp__moai__spec_audit`/`spec_drift`는 호출하지 않았다. `progress.md` L67이 이 MCP 서버가 워크트리 SPEC을 보지 못한다(`total_specs: 0`)고 기록했고, 대신 워크트리 CLI 린트를 직접 돌렸다.
- GLM 교차 감사는 `inconclusive`였고 codex는 설정상 off라 교차 모델 의견은 사실상 없다.
- `spec-compact.md`는 앞 40줄(REQ-001~019)만 대조했다.

## Regression Check (Iteration 2+ only)

해당 없음 — 1회차.

## Recommendation

manager-spec에 보낼 수정 지시(순서대로):

1. **(D1, 착수 게이트)** 오케스트레이터가 D-1~D-13을 운영자에게 묻는다. 답이 오면 `plan.md` §2의 표식 13개를 해소 문구로 바꾸고, 권장과 다른 답이 나온 결정만 "바뀌는 줄"대로 REQ·AC를 고친다. MP-7이 통과해야 다음 회차 판정이 의미 있다.
2. **(D2)** AC-022와 plan.md §5 "범위" 행의 기준을 카드별 기준 커밋으로 바꾼다. 누적 불변식(AC-019)과 카드 범위(AC-022)의 기준을 따로 적는다.
3. **(D3)** 스크립트 20 · AC-010 [사람] · 경계표 L368 · REQ-010 근거를 역할별 실제 코드 경로(Store.swift:1025 대 :1000, ContentView.swift:511)에 맞춘다.
4. **(D4)** § 통과 수를 다시 센다. AC-001을 넣고, AC-005·AC-006의 드라이버 하한과 grep 항목을 가른다.
5. **(D5)** AC-018 Given의 가는 편에 이동시간 힌트를 넣는다(기준 트리에서는 `addEvent`로 직접 만든다).
6. **(D6~D9)** REQ-020 목록·AC-003·AC-020 (5)를 한 벌로 맞추고, REQ-015에 "lane"을 정의하고, 검증되지 않는 REQ 절에 단언이나 갭 줄을 붙이고, plan.md §0·§1 표를 AC 매트릭스에 맞춘다.
7. D10~D13은 optional이다 — 오케스트레이터가 판단한다.

좌표 인용의 정확도(표본 약 90곳, 불일치 0)와 결함 주장을 가설로 표기하는 규율은 이 SPEC의 강점이다. 위 blocking 결함은 대부분 문서 안의 정합성 문제이고 설계 자체의 결함은 아니다.
