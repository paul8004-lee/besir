Model: claude-opus-5-5

# SPEC Review Report: SPEC-UIKIT-009
Iteration: 3/3
Verdict: FAIL
Overall Score: 0.84

> Reasoning context ignored per M1 Context Isolation. 호출자가 넘긴 것은 작업 지시(경로·보고서 위치·탐색 범위)와 0.1.3 방침 변경의 요약뿐이다. 방침의 출처는 이 세션이 `git log --oneline -3 master`(맨 위 `00cd149`)와 `git show 00cd149:CLAUDE.md`(:10-12 방침 원문, :126 Day 닫기의 "iOS **무경고** 빌드")로 직접 읽어 확인했다. 판정 근거는 SPEC 디렉터리 산출물 일곱 개와 기준 트리 `b2c3987`의 코드·로그를 이 세션이 읽거나 명령으로 잰 결과다.
>
> 입력 계약(Tier L): `spec.md`(238줄) · `plan.md`(326) · `acceptance.md`(472) · `design.md`(243) · `research.md`(158)를 전부 읽었고 `progress.md`(243) 전체와 `spec-compact.md`의 머리·AC 표·파일 표를 대조했다. 두 이전 보고서(review-1·review-2)를 읽었다.
>
> 교차 모델 감사: 이 워크트리에는 `.moai/config/`가 없어 주 체크아웃 `/Users/iseongmin/Projects/besir/.moai/config/sections/workflow.yaml`의 `audit:` 블록을 읽었다 — `model: multi`, gates `claude: required · codex: off · glm: advisory`. `mcp__moai__audit_multi`를 이 게이트로 불렀고 결과는 `overall_verdict: fail`, GLM은 `inconclusive`("z.ai response carried no content", fail-open)였다. 교차 모델 의견은 이번에도 없고 판정은 이 감사자의 것이다.
>
> 통과선: 주 체크아웃 `.claude/rules/moai/workflow/spec-workflow.md:142` — Tier L **0.85**.
>
> **이번 회차가 마지막 회차다.** 판정이 FAIL이므로 끝의 § 에스컬레이션에 운영자 선택지를 적었다.

## Must-Pass Results

- [PASS] MP-1 REQ number consistency: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → `REQ-001`~`REQ-023` 빠짐·중복 없음, 세 자리 영채움, `grep -c` = 23. AC는 `grep -o '^## AC-[0-9]*' acceptance.md` → `AC-001`~`AC-024`, 24건. 0.1.3에서 수가 바뀌지 않았다.
- [PASS] MP-2 EARS/GEARS format compliance (판정 계층: **요구사항 계층 `spec.md`의 REQ-XXX만**. `acceptance.md`의 Given/When/Then은 검증 계층이라 여기서 채점하지 않았다): 이름표 23개가 모두 GEARS 이름이다(`grep -o '^- \*\*REQ-[0-9]* ([^)]*)'`). 0.1.3에서 바뀐 REQ-019는 "The change shall use only Theme tokens … and, because development and verification are iOS-only, shall add no macOS-only code and shall not delete the existing macOS code or any `#if os` branch, while no gate of the change shall build or verify the macOS app"(spec.md:L168) — Ubiquitous · Unwanted 형식이 유지된다. REQ-020(L170)·REQ-023(L183)도 각각 Ubiquitous·State-driven이다.
- [PASS] MP-3 YAML frontmatter validity: spec.md:L2-13에 12필드가 모두 있고 형이 맞다 — `version: "0.1.3"`(따옴표 semver) · `status: draft` · `created`/`updated: "2026-09-30"` · `priority: P1` · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부 별칭 없음. 선택 필드 `tier: L`(L14). 이 세션이 돌린 `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` → `✓ No findings — all SPEC documents are valid`.
- [N/A] MP-4 Section 22 language neutrality: 단일 언어(Swift) 앱 SPEC이다.
- [PASS] MP-5 D7 cross-SPEC reconciliation: 일곱 파일에서 뽑은 참조는 SPEC-UIKIT-003·004·005·007·008(자기 자신 009 제외)이고, 다섯 모두 `.moai/specs/<ID>/spec.md`가 있으며 `status: completed`다. BLOCKING 없음.
- [PASS] MP-6 D8 cross-platform discipline: `grep -c syscall` → 일곱 파일 모두 0.
- [PASS] MP-7 clarification gate: `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` → 무출력(exit 1). 방침 P-1은 결정 게이트가 아니라고 스스로 밝혔고(plan.md:L73) 표식을 만들지 않았다. 단서는 review-2와 같다 — 운영자 답과 방침의 원문 발화는 이 감사가 관측하지 않았다(방침은 `master`의 `CLAUDE.md`로만 확인).

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.75 | 0.75 | 좌표 인용은 이번에도 정확하다(아래 § 재측정 표본 약 70곳, 어긋남 0). 모호한 곳: AC-015 Given이 "네 구간"이라 쓰고 셋만 나열한다(D22). REQ-023의 [REMOVE]는 달력 점의 사본 `Store.swift:136`을 없앤다고 하지만 `design.md` §4는 계산된 구간에 그 사본을 남기는 설계를 적는다(D23) |
| Completeness | 1.0 | 1.0 | HISTORY 0.1.0~0.1.3(spec.md:L23-28) · WHY §0-§1 · WHAT §2 · HOW `design.md` · REQ 23 · AC 24 · `### Out of Scope — …` 7개(`grep -c` = 7, 새 절 L213 "맥 앱의 빌드와 검증" 포함, 각 `-` 항목 있음) · frontmatter 12필드 · Tier L 산출물 다섯 |
| Testability | 0.75 | 0.75 | 대부분의 AC가 명령 하나로 판정된다. 새 AC-019 (6)은 이 세션이 스크래치 사본으로 다시 돌려 기준 0 · 한 줄 지움 1 · 맥 지시문 더함 1 · iOS 지시문 더함 0을 얻었다(작성자 기록과 같다). 흠: AC-022 (1)(2)가 모든 경로를 재므로 카드가 반드시 커밋하는 증거·문서 파일이 선언 목록 밖으로 잡히고 크게 고친 파일 수에도 들어간다 — 올바른 작업이 FAIL로 판정될 수 있다(D20) |
| Traceability | 0.90 | 1.0 밴드에 근접 | REQ 23건 모두 AC가 있다. 매트릭스(acceptance.md:L17-42) ↔ `plan.md` §0 REQ→AC(L22) ↔ §1 카드 표(L33-36)를 행마다 대조해 같았다. 흠: REQ-020의 "새로 만든 구간의 실패 모양은 도달 기록" 절이 반복 뒤 회차 모양 (라)까지 약속하지만 그것을 기록하는 AC 항목이 없다(D21). REQ-019의 "기존 맥 코드를 지우지 않는다"는 대리 지표 AC-019 (6)과 그 갭 문장이 지시문 밖의 맥 전용 코드를 덮지 않는다(D24) |

집계: 4 / (1/0.75 + 1/1.0 + 1/0.75 + 1/0.90) = 4 / 4.778 ≈ **0.84**. Tier L 통과선 0.85에 못 미친다. 2회차 0.84와 같다 — **낮아지지 않았으므로 STOP(점수 후퇴) 신호는 아니다.** 다만 이번이 3회차 상한이고 blocking 결함(D20~D24)이 남아 있어 FAIL이며, 재시도 계약에 따라 운영자에게 올린다.

## Defects Found (structured defect-list)

번호는 review-2(D14~D19)에 이어 붙였다. 이번 회차의 새 결함은 모두 0.1.2·0.1.3이 새로 쓰거나 고친 문장, 또는 이전 회차가 보지 않은 범위 측정의 경로 집합에서 나왔다.

D20. AC022-PATHSET — acceptance.md:L369(AC-022 (1)) · L370((2)) · L366(Given) · plan.md:L40(MA 선언에는 "문서: CHECKLIST·루트 `plan.md`는 sync"가 있다) vs L52(MB)·L60(MC)(문서 없음) · spec-compact.md:L87-88(MB·MC에 "sync 문서"가 있다) — AC-022는 `git diff --name-only <BASE> HEAD`와 `--numstat <BASE> HEAD`를 **경로 제한 없이** 잰다. 그런데 (i) 각 카드는 `.moai/specs/SPEC-UIKIT-009/progress.md` §E.2를 반드시 고친다 — AC-022 Given 자신이 `card_base_sha`를 거기 적으라 하고(L366), AC-020 (5)가 재현 줄 원문을 거기 두라 한다(L348). `git ls-files .moai/specs | grep -c .` → 48로 SPEC 디렉터리는 추적 대상이고 `.moai/state/`만 무시된다(`git check-ignore -v` → `.gitignore:28:**/.moai/state/`). 이 파일은 어느 카드의 선언 목록에도 없다. (ii) REQ-021에 따라 MB·MC의 sync도 `CHECKLIST.md`·루트 `plan.md`를 고치지만, AC-022 (1)이 판정 목록으로 지목한 `plan.md` §1에서 MB·MC 선언에는 문서가 없다(요약본 `spec-compact.md`에는 있다 — 두 문서가 어긋난다). (iii) (2)의 "추가+삭제 100줄 이상인 파일 ≤ 4"가 이 문서·증거 파일까지 세는데, 크게 고칠 파일 예측(MB 4 — 한도 끝, plan.md:L52)은 소스만 셌다. 전 카드 SPEC-UIKIT-008은 같은 검사에서 `':!.moai/specs/SPEC-UIKIT-008'` 등을 명시적으로 뺐다(`.moai/specs/SPEC-UIKIT-008/acceptance.md:271`) — 이 SPEC에는 그 제외가 없다. 결과: AC-022 (1)은 증거 파일을 커밋하는 모든 카드에서 구조적으로 FAIL이 되고, (2)는 MB에서 한도 판정이 문서 크기에 좌우된다. [증거 수준: 명령 — `git ls-files`·`git check-ignore`·SPEC-UIKIT-008 원문. 카드 커밋은 아직 없으므로 실제 diff는 관측하지 않았다] — Severity: major — Class: blocking — Required fix: AC-022 (1)(2)의 경로 집합을 정한다. 예: (1)은 `-- . ':!.moai/specs/SPEC-UIKIT-009' ':!.moai/reports'`로 SPEC·보고서를 빼고, (2)는 `-- Shared Tools`(한 Day 한도가 세는 소스)로 제한한다. 그리고 `plan.md` §1의 MB·MC 선언에 "sync 문서: `CHECKLIST.md` · 루트 `plan.md`"를 MA와 같게 더해 `spec-compact.md`:L87-88과 맞춘다. REQ-022 근거(spec.md:L174)에 "선언 집합은 소스 + 그 카드의 sync 문서이고, SPEC·보고서 경로는 범위 측정에서 뺀다"를 한 줄 적는다.

D21. REQ020-SHAPE-RA — spec.md:L170(REQ-020 "the shapes a failed estimate leaves on a newly created leg shall be recorded as a reach record — the observed line together with the premise it needs, taken from a separately named offline run") vs acceptance.md:L193(AC-010 (4) — `addEvent`로 만든 (가)·(나)만) · L348(AC-020 (5) ⓑ — "새로 만든 구간의 실패 모양은 도달 기록"이 AC-010 (4) 줄만 가리킨다) — 모양 (라)(반복 뒤 회차 — 첫 회차 추정이 실패하면 캐시가 nil이라 뒤 회차가 추정 없이 저장된다, `Store.swift:673-677`, 이 세션이 확인)는 **새로 만든 구간**에 생기는 실패 모양이다. REQ-020의 규범 문장은 그것도 도달 기록으로 남긴다고 약속하지만 이를 기록하는 AC 항목이 없고, 수락 기준·요구사항 어디에도 갭으로 적혀 있지 않다. 이 갭은 `progress.md`:L32의 자기 점검 표에만 있다("(라)는 기준 트리에서 재현하지 않음 … → 갭") — 진행 기록은 계약이 아니다. REQ-023 뒤에도 (라)의 그림은 기준 트리와 같으므로(design.md:L112) 영향은 작지만, review-2 D15와 같은 부류(요구사항과 수락 기준이 약속의 범위를 다르게 말함)다. — Severity: minor — Class: blocking — Required fix: 둘 중 하나. (a) REQ-020의 그 절을 "a leg newly created through `addEvent` (shapes (가)·(나))"로 좁히고, "(라) has no deterministic or reach path in the driver and is shown only by constructed records (AC-010 (7)(11)(12))"를 REQ-020 근거와 AC-020 (5) ⓑ에 갭으로 적는다. (b) 오프라인 실행에서 반복 생성 절이 (라)를 남기는지 AC-010 (4)에 도달 줄 하나를 더한다. (a)가 좁다.

D22. AC015-LEG-COUNT — acceptance.md:L262(AC-015 Given "… 네 구간 모두 명시적 연결은 없다") · L273((9) "R·L과 네 구간에 부르면 반환이 정확히 `{R 가는 편 → R, R 오는 편 → R}`") — Given이 나열한 구간은 R의 가는 편 · R의 오는 편 · L의 오는 편 **셋**이다. "네"를 맞추려고 실행자가 L의 가는 편(도착 모레 23:00, 목적지 P)을 더하면, `linkedLegs` 추정(`Store.swift:1128-1129` — 같은 날 `arrivalDate`·목적지 이름)이 그 구간을 L에 대응시키므로 (9)의 기대 반환(키 둘)이 틀린다. 0.1.2가 review-2 D16을 고치며 새로 쓴 문장이다. — Severity: minor — Class: blocking — Required fix: L262·L273의 "네 구간"을 "세 구간"으로 고치거나, 넷째 구간을 명시하고 (9)의 기대 반환에 그 대응을 넣는다.

D23. REQ023-DOTS-COPY — spec.md:L181([REMOVE] "나열과 점에 따로 복사된 판정 `guard let dep = e.departureDate, e.arrivalDate > dep`(`ContentView.swift:89` · `Store.swift:136`의 같은 조건)") · L183(REQ-023 "the day listing …, the calendar dots, … shall read one shared function") vs design.md:L120(달력 점 `recomputeDaysWithSchedule` — "앵커가 있으면 A의 날 키 하나, **없으면 지금의 `:136-140`**") · L236(열린 항목) · acceptance.md:L198(AC-010 (9)는 `grep -c 'e.arrivalDate > dep'`을 `ContentView.swift`에서만 0으로 재고 `Store.swift`는 재지 않는다) — 요구사항은 점의 사본을 없앤다고 하고, 설계는 계산된 구간에 대해 그 사본을 그대로 두는 모양을 적는다. 설계대로 가면 계산된 구간의 나열 규칙이 `Models.swift`의 날짜 판정(ContentView가 부름)과 `Store.swift:136`의 인라인 조건 두 곳에 남는다 — 계약 5가 막으려는 모양이고, REQ-023이 근거로 든 "점과 나열이 같은 말을 한다는 기존 계약"(`Store.swift:32-37`)도 다시 두 벌이 된다. 동작 동일성은 AC-010 (13)이 표본 레코드로 보지만, 구조 판정(9)은 어느 쪽으로 구현해도 통과한다. [증거 수준: 문서 대조 — `grep -c 'e.arrivalDate > dep' Shared/ContentView.swift Shared/Store.swift` → 1 / 1] — Severity: minor — Class: blocking — Required fix: 한 쪽으로 맞춘다. 권장: design.md §4의 점 절을 "앵커가 있으면 A의 날, 없으면 날짜 판정 함수가 쓰는 같은 구간 규칙(예: 공유 함수가 돌려주는 `[start, end]`를 `dayKeys`에 넘김)"으로 고치고, AC-010 (9)에 `grep -c 'e.arrivalDate > dep' Shared/Store.swift` = **0**(기준 1)을 더한다. 사본을 남기기로 하면 spec.md:L181의 [REMOVE]에서 `Store.swift:136`을 빼고 REQ-023의 "one shared function"을 "failed-estimate legs"로 좁힌다.

D24. AC019-6-NONDIRECTIVE-MAC — acceptance.md:L335(AC-019 (6)의 갭 "분기 줄은 두고 분기 안의 맥 코드만 지우거나 바꾼 변경은 이 명령이 잡지 못한다 — `code-safety`가 `#if os(macOS)` 구간에 닿은 헝크를 진행 기록에 적는다") · plan.md:L267(같은 범위) vs `Shared/ContentView.swift:617-618`·`:624-626`/`:641`·`:672-674` — 이 카드(MC)가 크게 고칠 시간표 블록 뷰 셋에는 **지시문 밖의** 맥 전용 코드가 있다. 세 `.onTapGesture`는 주석이 "iOS에서는 도달하지 않는다(무해한 죽은 코드). macOS에서는 이 탭이 그대로 쓰인다"라고 적는다(이 세션이 `grep -n 'macOS' Shared/ContentView.swift`로 확인). REQ-019는 "shall not delete the existing macOS code"라고 하지만, 대리 지표 (6)은 지시문 줄만 보고 갭 문장과 `code-safety` 몫은 `#if os(macOS)` 구간만 가리킨다. MC가 블록 선택(`:511`)과 `failedEstimateBlockView`를 고치는 김에, 또는 Day 닫기의 "죽은 코드" 정리 지시에 따라 이 탭을 지우면 맥 앱의 탭이 사라지는데 어떤 항목도 그것을 잡거나 갭으로 적지 않는다. — Severity: minor — Class: blocking — Required fix: AC-019 (6)의 갭 문장과 plan.md:L267의 `code-safety` 몫에 "지시문 밖에서 주석이 맥 전용으로 밝힌 코드(`ContentView.swift`의 `.onTapGesture` 셋 — `:618`·`:641`·`:674`)를 지우거나 바꾼 헝크"를 더한다. 원한다면 대리 지표를 하나 더 둔다: `grep -c 'onTapGesture' Shared/ContentView.swift`가 기준값(이 세션은 세지 않았다 — run이 재어 적는다) 이상.

D25. AC019-6-COMMENT-FP — acceptance.md:L335 — AC-019 (6)의 `git grep -e '#if os'`는 주석 안의 문자열도 잡는다. 이 세션이 스크래치 사본에 주석 한 줄(`// macOS 보존: #if os 분기는 지우지 않는다`)을 더해 같은 파이프를 돌리니 **1**(FAIL)이 나왔다. 이 SPEC은 맥 보존의 이유를 주석으로 남기게 유도하므로(plan.md:L78 "run이 하지 않는 것") 올바른 변경이 거짓 FAIL을 낼 수 있다. — Severity: minor — Class: optional — Required fix: 패턴을 줄 머리의 지시문으로 고정한다(예: `git grep -h -E '^\s*#(if|elseif) os|canImport\(AppKit\)'`)고 양성 대조에 "주석 줄 더함 → 0"을 더한다.

D26. AC002-7-HINT — acceptance.md:L71(AC-002 When "활동 23:00–23:50에 오는 편(이동 30분 — 도착이 다음 날 00:20)을 붙이면") · L79((7) "이틀 모두에 나열된다") — 그 오는 편에 힌트를 넘기는지 명시하지 않았다. 힌트 없이 만들면 온라인에서는 실제 경로 시간에 따라(10분 이하이면 자정을 넘지 않는다), 오프라인에서는 모양 (나)(출발 = 도착)가 되어 (7)이 ✗가 된다. 괄호의 "이동 30분"이 힌트로 읽히므로 대부분의 실행자는 결정적으로 짤 것이다. — Severity: minor — Class: optional — Required fix: "(이동시간 힌트 30분 — 도착이 다음 날 00:20)"으로 적는다.

D27. SIM-AIRPLANE — acceptance.md:L446(13a) · L456(20) · L458(20b) "시뮬레이터의 네트워크를 끈다(비행기 모드 또는 Mac 네트워크 차단)" — iOS 시뮬레이터는 호스트 Mac의 네트워크를 쓰므로 시뮬레이터 안의 비행기 모드로는 이동시간 조회가 끊기지 않는 것으로 알고 있다. 그렇다면 비행기 모드를 고른 운영자는 세 스크립트에서 "다름"을 적게 된다. [증거 수준: 일반 지식 — 이 세션은 시뮬레이터를 실행하지 않았다. UNVERIFIED] — Severity: minor — Class: optional — Required fix: "Mac의 네트워크를 끈다(시뮬레이터의 비행기 모드는 호스트 네트워크를 끊지 않는다)"로 적거나, 운영자가 먼저 한 번 확인하게 한다.

D28. REQ020-OMITS-REQ013 — spec.md:L170(REQ-020 결함 목록 넷) · L142(REQ-013 근거 — "같은 제목 일정 모두 삭제"가 다른 활동의 구간까지 쓸어 갈 수 있다, 코드 읽기) — REQ-013이 고치는 결함은 재현 목록에 없고, 빠진 이유(REQ-003처럼)도 적혀 있지 않다. 뷰의 필터(`EventDetailView.swift:331-333`)를 드라이버가 컴파일하지 않으므로 재현할 수 없는 것이 이유로 보인다. — Severity: minor — Class: optional — Required fix: REQ-020 근거에 "REQ-013의 같은 제목 결함은 뷰 코드라 드라이버가 닿지 않는다 — MB 전 빌드에서 스크립트 13을 돌리면 사람 재현(선택)"을 한 줄 더한다.

D29. MAC-GAP-NARROWER — spec.md:L216(받아들인 갭 "이 카드가 `Shared/`에서 바꾼 코드가 맥 타깃의 컴파일이나 동작을 깨도 어떤 게이트도 그것을 잡지 않는다") — 참고 사항이다. 드라이버 컴파일은 macOS 호스트의 `swiftc`로 `Store`·`Models`·`EditCard`·`AIAssistant` 등을 컴파일한다(기준 로그 `driver-compile.log`의 경고가 "deprecated in macOS 26.0"이다). 그래서 드라이버 집합에 든 파일의 맥 쪽 컴파일은 사실상 게이트에 걸려 있고, 갭은 적힌 것보다 좁다(`ContentView`·편집 화면 등 드라이버 밖 파일). 방침과 충돌하지는 않는다 — 맥 앱을 빌드하는 것이 아니다. — Severity: minor — Class: optional — Required fix: 원하면 갭 문장에 "드라이버 컴파일 집합 밖의 파일"로 범위를 적는다.

D11. REQ-ATOMICITY/HOW (review-1에서 넘어옴) — spec.md:L125(REQ-008) · L155(REQ-016) · L168(REQ-019) — 오케스트레이터 지시로 채택하지 않았다(HISTORY 0.1.1·0.1.2). — Severity: minor — Class: optional — Required fix: 없음(오케스트레이터 재량).

## 탐색 결과 — 호출자가 지목한 자리마다

- **REQ-023 규칙(두 앵커의 실패 모양 · 재추정 실패 · 앵커 시각과 나열할 날 · 네 자리)**: 생산자를 이 세션이 다시 전수로 훑었다 — `grep -rn 'ScheduledEvent(' Shared ShareExtension` → 생성자 셋(`GoogleCalendarService.swift:216` · `Store.swift:584` · `:656`), `grep -rn 'departureDate = \|travelSeconds = \|\.anchor = '` → 대입 자리 전부, 추정 호출 `:600`·`:601`·`:664`·`:673`·`:750`·`:759`·`:975`·`:976`·`:1261`·`:1264`·`:1400`. 모양은 넷으로 닫힌다(도착 기준 반복 뒤 회차는 (가)와 같은 모양, `:663-669`). 끌기(`adjustTravelLeg` → 출발 기준은 `shiftEvent`가 두 시각을 함께 옮김 `:1137-1145`, 도착 기준은 `adjustBuffer`의 `guard travel` `:1152`) · 활동 종료 변경(`realignReturnLeg` `:333-340`) 뒤에도 앵커가 활동 끝에 남는다. 시간표에서 `departureDate`를 읽는 자리는 `ContentView.swift:89`·`:511`·`:558` 셋뿐이고(`grep -n departureDate Shared/ContentView.swift`) 점은 `Store.swift:136` — 네 자리 목록이 맞다. 결함은 점의 사본이 남는 설계 한 곳(D23)이다. 자정: (다)·(나)·(가) 자정 판과 23:50 넘침·가는 편 출발일 공백은 문서에 명시돼 있다.
- **REQ-020 세 갈래**: 재추정 실패의 무네트워크 경로는 코드로 확인했다 — `applyDepartureAnchoredEstimate`는 `:1024`·`:1025` 대입 뒤 출발지 guard `:1026`, 사이에 레코드를 바꾸는 줄 없이 추정 `:1027-1030` · guard `:1031`. `refreshUpcomingEstimates`는 출발지를 거르지 않고 `:1251-1254`에서 출발 시각만 본다. 빠진 것은 (라)의 도달 기록(D21)이다.
- **AC-010 (4)–(13)**: 포인터·기대값을 전부 대조했다. (13)의 `daysWithSchedule`은 `@Published private(set)`(`Store.swift:24`)이라 드라이버가 읽을 수 있고 `events`의 `didSet`이 재계산한다(`:10`). 둘 다 `Calendar.current`다(드라이버 `sCal` = `Calendar.current`, `GuardDriver.swift:977`). 새 결함 없음.
- **AC-015**: D22.
- **AC-017 (9)**: E9의 옛·새 배치를 `positionedBlocks`(`ContentView.swift:699-742`) 규칙으로 손 추적했고 design.md §6.3과 같다(새: 묶음 항목 [1350, 1431], U 열 1 / 옛: R이 `1410 <= 1410`으로 열 0 재사용, D+1은 `span`의 출발 고정 최소 높이 `:580`으로 0–16). 손 추적은 실행이 아니다.
- **통과 수**: AF = 3+7+5+6+2+8+5+5+5+5+3+3+4+3+2 = **66** · AG = 6+3 = **9** · AH = 7+8+2+9+2 = **28** · 합 **103**. 바닥 357+66 = **423** · +9 = **432** · +28 = **460**. 0.1.1 → 0.1.2 차이 +5(AC-010 +4, AC-017 +1), 0.1.0 91 → 0.1.1 98 차이 +7도 맞다. AC 머리의 하한을 항목 번호와 대조했다: AC-010 MA (1)–(4)·(10) = 5, MC (5)–(8)·(11)–(13) = 7, 명령 (9) · AC-015 MC (1)–(7)·(13) = 8, MA (9)–(12) = 4, 명령 (8) · AC-019 드라이버 (2) = 2, 명령 (1)(3)(4)(6) = 4, 갭 (5). 0.1.3이 드라이버 합을 바꾸지 않는다는 주장도 맞다(뺀 맥 빌드 절·스크립트 23, 더한 (6) 모두 드라이버 줄이 아니다).
- **MC 파일 목록**: 크게 고침 3(`Models`·`ContentView`·`GuardDriver`) · 작게 고침 1(`Store` — 달력 점 `:132-150`)은 REQ-022의 넷 이하에 든다. 결함은 목록 자체가 아니라 AC-022가 재는 경로 집합이다(D20).
- **"(n)" 포인터**: 경계표(acceptance.md:L397-411) · 매트릭스 · `plan.md` §0·§1·§2·§3 · design.md · REQ 근거의 AC 항목 포인터를 표본이 아니라 모두 대조했다. 끊긴 포인터는 없다. "§3 마지막 절"을 가리키는 네 자리는 새 절이 "저장 경로의 기존 결함" 앞에 들어가 여전히 맞다(spec.md:L213·L218).
- **iOS 전용 방침 편집(0.1.3)**: `grep -n -i 'macos\|맥\|두 플랫폼\|양쪽\|두 빌드\|SwiftCompile'`로 네 문서를 훑었다 — 남은 자리는 방침 기록·범위 밖 절·AC-019 (6)·AC-020 (3)의 "맥 빌드는 게이트에 없다"·AC-024의 "맥 앱은 실행하지 않는다"·스크립트 23을 뺀 기록뿐이다. 맥 동작을 검증했다고 말하는 REQ·AC는 없다. 스크립트 범위(14~22 · 11단계, 1~22 · 25단계)와 기준선(iOS `SwiftCompile` 42, `BUILD SUCCEEDED` `:944`)이 모두 맞다. `design.md`에 플랫폼 문장이 없다는 작성자 주장도 `grep` 무출력으로 확인했다. 결함은 지시문 밖 맥 코드(D24)와 대리 지표의 거짓 FAIL(D25)이다.

## 재측정 표본 (이 세션이 기준 트리 `b2c3987`에서 직접 확인)

- 트리: `git rev-parse --short HEAD` → `b2c3987` · `git branch --show-current` → `WT-edit-card-unify` · `git status --short` → `?? .claude/` · `?? .moai/reports/plan-audit/SPEC-UIKIT-009-review-1.md` · `?? …-review-2.md` · `?? .moai/reports/t17/` · `?? .moai/specs/SPEC-UIKIT-009/` · `git diff --stat b2c3987 -- Shared Tools` → 무출력.
- **0.1.3 새 좌표**: 이 워크트리 `CLAUDE.md:53`(맥 빌드 명령) · `:121`("iOS·macOS 양쪽 **무경고** 빌드") · `master`의 `CLAUDE.md:10-12`(방침 원문) · `:126` · `project.yml:89`(`besir-macOS:`)·`:91`(`platform: macOS`)·`:93`(`- Shared`) · `ContentView.swift`의 `#if os` `:2`·`:195`(맥 — 툴바 동기화 단추, `:195-207`)·`:454`·`:857`, `#endif` `:4`·`:207`·`:486`·`:980` · `grep -c '#if os'` Store 2 · AddActivityView 1 · ActivityDetailView 1 · ContentView 4 · Models·EditCard·EventDetailView 0 · 기준 목록 37줄(`25 #if os(iOS)` · `12 #if os(macOS)`). **전부 일치.**
- **AC-019 (6) 재실행**(스크래치 사본): 기준 대 `HEAD` → `0` · 한 줄 지움 → `1` · `#if os(macOS)` 더함 → `1` · `#if os(iOS)` 더함 → `0` · 주석 줄 더함 → `1`(D25).
- **0.1.2 좌표(REQ-023·REQ-020·AC-010)**: Store `:10`·`:24`(`private(set) daysWithSchedule`)·`:32-38`·`:132-150`·`:136` · `:572-610`(`:573` 출발지 비-Optional · `:587` · `:591` · `:600-601` · `:606-608`) · `:648-650` · `:656-658` · `:663-677` · `:740-772`(`:757-759`) · `:952-992`(`:962` · `:975-976`) · `:994-1036`(`:999`·`:1000`·`:1001`·`:1006`·`:1024`·`:1025`·`:1026`·`:1031`·`:1033`) · `:1128` · `:1137-1145` · `:1152` · `:1178` · `:1224` · `:1245-1271`(`:1251-1254`·`:1263-1264`) · `:1400` · `:517`·`:529`. ContentView `:37`(56) · `:82-95` · `:511` · `:533-536` · `:549-553` · `:557-583` · `:627-642` · `:647` · `:651`. App `:25`·`:101`. Models `:157-158`. AIAssistant `:1846`·`:2622`·`:2644`. GuardDriver `:413`·`:481`·`:977`·`:991`·`:1310-1320`·`:1369`. 기준 로그 `driver-run.log:150`·`:211`. **전부 일치.**
- **AC 기준값**: `e.arrivalDate > dep` ContentView **1** / Store **1** · `e.departureDate != nil` ContentView **1** · `columnEnds` ContentView **8** / Models **0** · `store.events.filter { $0.title == event.title }`(-F) **1** · `linkedActivityId == nil` ContentView **1** · `failedBlockAnchor\|isListed(on:` 전 파일 **0** · ActivityDetailView `:68` 안내 문구 · `:102` 확인 문구 · SettingsView `:78`. SPEC 값과 같다.
- **기준선 로그**: `ios-build.log` `^SwiftCompile` 42 · `BUILD SUCCEEDED` `:944` 등은 작성자·review-1·review-2가 같은 값을 얻었다. 이번 회차는 driver-compile.log의 경고 줄 원문을 새로 봤다 — 모두 `DirectionsService`·`LocationManager`·`PlaceSearch`(이 카드가 건드리지 않는 파일)이고 "deprecated in macOS 26.0"이다(D29의 근거). 이 세션의 어긋난 좌표 **0건**.

## Gaps (이 감사가 관측하지 않은 것)

- 드라이버·빌드·시뮬레이터를 실행하지 않았다. 기준선은 오케스트레이터 로그를 이전 회차들과 이 세션이 다시 센 값이다.
- D20은 카드 커밋이 아직 없어 실제 `git diff`를 관측하지 않았다 — 추적 여부(`git ls-files`·`git check-ignore`)와 SPEC 문장, 전 카드의 선례로 판단했다.
- D23·D24는 문서·코드 대조이고 아직 없는 구현에 대한 설계 결함 가설이다.
- D27은 일반 지식이고 UNVERIFIED다.
- 운영자의 D-1~D-14 답과 방침의 원 발화는 관측하지 않았다 — 방침은 `master`의 `CLAUDE.md` 커밋으로만 확인했다.
- `mcp__moai__spec_audit`/`spec_drift`는 부르지 않았다(워크트리 SPEC을 보지 못한다는 기록 — progress.md:L207). 워크트리 CLI 린트로 대신했다.
- 교차 모델 의견 없음(GLM `inconclusive`, codex off).

## Regression Check (Iteration 2+ only)

Defects from previous iterations:

- D1 (MP-7 표식 13건): **RESOLVED** — `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` 무출력, 일곱 파일 모두 0. plan.md §2 해소 줄 유지.
- D2 (카드 범위 고정 기준): **RESOLVED** — AC-022가 카드 기준 커밋 `<BASE>`로 잰다(acceptance.md:L366-371). **단, 같은 AC의 경로 집합에 새 결함 D20**(기준 커밋이 아니라 잴 경로의 문제라 별개로 셌다).
- D3 (스크립트 20 기대가 코드와 반대): **RESOLVED** — REQ-023(spec.md:L183) · 스크립트 20은 MC 뒤에만 참(acceptance.md:L456) · 13a는 가는 편(L446).
- D4 (통과 수 산술): **RESOLVED** — 66/9/28/103, 423/432/460을 다시 유도(위 § 탐색).
- D5 (AC-018 비결정성): **RESOLVED** — Given이 두 구간 모두 `travelSecondsHint: 1800`으로 `addEvent`를 직접 부른다(L313). 이 세션도 `sed -n 189,230p Shared/Store.swift | grep -c travelSecondsHint` → 기록된 0을 신뢰할 근거(`addActivityWithTravel` 본문 `:189-230`)를 봤다.
- D6 (재현 목록 한 벌): **RESOLVED** — REQ-020 결함 넷(spec.md:L170)과 AC-020 (5) ⓐ 넷(L348)이 같다.
- D7 (lane 정의): **RESOLVED** — spec.md:L153 끝 문장.
- D8 (REQ 절 대응 AC): **RESOLVED** — AC-003 (5)(L93) · AC-008 갭 줄(L168) · AC-011 (4)(L217) · AC-012 갭 줄(L232).
- D9 (plan 표 ↔ 매트릭스): **RESOLVED** — 23행 REQ→AC와 카드 열을 다시 대조해 같았다.
- D10 (판단에 기대는 AC): **RESOLVED** — 대리 지표·갭 분류 유지(AC-001 (3) · AC-005 (3)(4) · AC-016 (2) · AC-019 (4)(5)).
- D11 (REQ 분할·HOW): **OPEN — optional, 채택 안 함**(HISTORY 0.1.1·0.1.2). 세 회차 모두 남았지만 blocking이 아니고 오케스트레이터가 채택하지 않기로 한 항목이라 정체(stagnation)로 세지 않는다.
- D12 ("Event-detected" 이름표): **RESOLVED** — 23개 이름표 모두 GEARS 이름.
- D13 (반복 경로 범위): **RESOLVED** — `:628-695` 한 측정.
- D14 (REQ-023의 실패 모양 하나): **RESOLVED** — 모양 넷(spec.md:L183 (가)~(라), design.md:L98-103) · 앵커 시각과 그 날 하루 나열(L105-112) · 네 자리(L120) · AC-010 (10)–(13) · AC-017 (9) · 스크립트 20b. 생산자 전수를 이 세션이 다시 훑어 모양이 넷으로 닫힘을 확인했다. **파생 결함 D23**(점의 사본이 설계에 남음).
- D15 (REQ-020 다섯째 재현 도달 불가): **RESOLVED** — 세 갈래(무네트워크 결정적 재현 · 도달 기록 · 메모리 구성)로 나뉘고 AC-010 (4)(10)·AC-020 (5)·결정성 문단(acceptance.md:L48-50)이 한 벌이다. 무네트워크 경로는 코드로 확인했다. **파생 결함 D21**((라)의 도달 기록 누락).
- D16 (AC-015 L의 날짜): **RESOLVED** — L은 모레(L262), (9)는 키·값 집합으로 대조(L273), 같은 날 두 회차는 명세하지 않는다고 적었다(design.md:L135 · plan.md:L242). **파생 결함 D22**(같은 문장의 "네 구간").
- D17 (AC-013 (4) 번호): **RESOLVED** — acceptance.md:L244 "4. (명령, MB)".
- D18 (요약본 결정 문구): **RESOLVED** — spec-compact.md:L4 "권장과 다른 것은 D-8 (b), 새로 더한 결정은 D-14 (b)".
- D19 (AC-024 REQ 대응): **RESOLVED** — 매트릭스 L42에 001·002·008, plan.md:L22의 001·002·008 행에 024.

정체 감지: 세 회차에 걸쳐 그대로 남은 blocking 결함은 없다. 이번 blocking 다섯(D20~D24) 가운데 셋(D21·D22·D23)은 0.1.2가 review-2 결함을 고치며 새로 쓴 문장에서, 하나(D24)는 0.1.3의 방침 문장에서, 하나(D20)는 이전 두 회차가 재지 않은 범위 명령의 경로 집합에서 나왔다. 호출자가 경고한 부류(한 모양·한 역할·한 환경에 대해 쓴 문장이 다른 것을 놓침)가 D21((라)) · D24(지시문 밖 맥 코드) · D20(MA의 문서 선언이 MB·MC에 없음)로 이번에도 나타났다.

## Recommendation

**FAIL — 3회차 상한 도달.** must-pass 일곱은 모두 통과하고, review-1·review-2의 blocking 결함 열셋은 모두 닫혔다. 점수는 0.84로 2회차와 같고(후퇴 아님) 통과선 0.85에 0.01 모자란다. 남은 blocking 다섯은 모두 한두 줄의 문서 수정으로 닫히는 정합성 결함이며 설계 자체를 흔드는 것은 없다.

manager-spec에 보낼 수정 지시(오케스트레이터가 아래 에스컬레이션에서 길을 고른 뒤):

1. **(D20, 가장 무겁다)** AC-022 (1)의 경로에서 `.moai/specs/SPEC-UIKIT-009`·`.moai/reports`를 빼고 (2)를 `-- Shared Tools`로 제한한다. `plan.md` §1 MB(L52)·MC(L60) 선언에 sync 문서를 MA(L40)와 같게 더해 `spec-compact.md`:L87-88과 맞춘다. REQ-022 근거에 경로 규칙 한 줄.
2. **(D21)** REQ-020의 "newly created leg" 절을 `addEvent` 경로((가)·(나))로 좁히고 (라)를 REQ-020 근거·AC-020 (5) ⓑ에 갭으로 적는다.
3. **(D22)** AC-015 L262·L273의 "네 구간" → "세 구간".
4. **(D23)** design.md §4 점 절을 공유 함수 한 벌로 고치고 AC-010 (9)에 `grep -c 'e.arrivalDate > dep' Shared/Store.swift` = 0을 더한다(또는 반대로 [REMOVE]와 REQ-023 문장을 좁힌다).
5. **(D24)** AC-019 (6)의 갭과 plan.md:L267의 `code-safety` 몫에 지시문 밖 맥 전용 코드(`ContentView.swift:618`·`:641`·`:674`의 `.onTapGesture`)를 더한다.
6. D25~D29·D11은 optional이다 — 오케스트레이터가 판단한다.

## 에스컬레이션 (재시도 계약 — 3회차 FAIL)

오케스트레이터는 `AskUserQuestion`으로 운영자에게 다음 셋을 제시한다(이 감사자는 묻지 않는다).

1. **PASS-with-debt** — 현재 0.1.3으로 run에 들어가고 D20~D24를 문서 부채로 기록한다. D20은 MA의 AC-022 판정 전에 반드시 닫아야 한다(닫지 않으면 MA 게이트가 증거 파일 때문에 FAIL로 읽힌다). 나머지 넷은 해당 카드(MA: D21 · MA/MC: D22 · MC: D23·D24)의 착수 전에 닫으면 된다.
2. **범위 축소** — 이 SPEC은 이미 배달 카드 셋으로 나뉘어 있어 축소의 이득이 작다. 굳이 고른다면 MC(REQ-015~018·023)를 별도 SPEC으로 떼어 MA·MB를 먼저 통과시키는 길이다.
3. **명시적 연장(4회차)** — D20~D24만 고친 0.1.4를 이 결함 목록으로 한정한 재감사에 넣는다. 결함이 모두 한두 줄 수정이라 비용이 작다. 운영자의 의식적 선택이어야 한다.

결함 이력(세 회차): review-1 D1~D13(blocking 9 · optional 4) → review-2 D14~D19(blocking 4 · optional 2, review-1 blocking 전부 해소) → review-3 D20~D29(blocking 5 · optional 5, review-2 blocking 전부 해소). 회차마다 앞 회차의 blocking은 모두 닫혔고, 새 blocking은 매번 그 회차가 새로 쓴 문장이나 앞 회차가 재지 않은 자리에서 나왔다.
