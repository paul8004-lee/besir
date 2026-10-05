Model: claude-opus-5-5

# SPEC Review Report: SPEC-UIKIT-009
Iteration: 4 (extended — 운영자가 2026-10-05 3회 상한 연장을 승인, review-3 결함 목록으로 한정한 재감사)
Verdict: PASS
Overall Score: 0.91

> Reasoning context ignored per M1 Context Isolation. 호출자가 넘긴 것은 작업 지시(범위·경로·판정 규칙)뿐이고, 판정 근거는 SPEC 산출물 일곱 개와 기준 트리 `b2c3987`의 코드를 이 세션이 직접 읽고 명령으로 잰 결과다.
>
> 입력: `spec.md`(239줄) · `plan.md`(326) · `acceptance.md`(474) · `design.md`(243) · `research.md`(158, 관련 줄 `grep`) · `spec-compact.md`(127) · `progress.md`(270, 0.1.4 수정 기록 §와 Gaps 전체). 이전 보고서 review-3 전체와, 결함 이력은 그 보고서의 회귀 절로 확인했다.
>
> 트리: `git rev-parse --short HEAD` → `e7e34f6` · `git branch --show-current` → `WT-edit-card-unify` · `git diff --stat b2c3987 -- Shared Tools` → 무출력(exit 0). 그래서 아래 코드 좌표는 모두 기준 트리 `b2c3987`의 값이다.
>
> 교차 모델 감사: 주 체크아웃 `/Users/iseongmin/Projects/besir/.moai/config/sections/workflow.yaml:77-82`의 `audit:` 블록 — `model: multi`, gates `claude: required · codex: off · glm: advisory`. `mcp__moai__audit_multi`를 이 게이트로 불렀고 결과는 `overall_verdict: pass`, GLM은 `inconclusive`("z.ai response carried no content", fail-open)였다. 교차 모델 의견은 이번에도 없고 판정은 이 감사자의 것이다.
>
> 통과선: 주 체크아웃 `.claude/rules/moai/workflow/spec-workflow.md:142` — Tier L **0.85**.

## Must-Pass Results

- [PASS] MP-1 REQ number consistency: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → `REQ-001`~`REQ-023`, 빠짐·중복 없음, 세 자리 영채움, `grep -c` = 23. AC는 `grep -o '^## AC-[0-9]*' acceptance.md` → `AC-001`~`AC-024`, 24건. 0.1.4에서 수가 바뀌지 않았다.
- [PASS] MP-2 EARS/GEARS format compliance (판정 계층: **요구사항 계층 `spec.md`의 REQ-XXX만**. `acceptance.md`의 Given/When/Then은 검증 계층이라 여기서 채점하지 않았다): 이름표 분포 `Event-driven` 8 · `Event-driven · Unwanted` 2 · `State-driven` 3 · `State-driven · Unwanted` 1 · `Ubiquitous` 3 · `Ubiquitous · Unwanted` 4 · `Unwanted` 1 · `Unwanted · Event-driven` 1 = 23, 모두 GEARS 이름이다. 0.1.4가 바꾼 REQ-020 문장(spec.md:L171 "the shapes a failed estimate leaves on a leg newly created through `addEvent` (shapes (가)·(나)) shall be recorded as a reach record …")은 Ubiquitous 형식이 유지된다. REQ-022·REQ-023은 근거만 바뀌었다.
- [PASS] MP-3 YAML frontmatter validity: spec.md:L2-13에 12필드가 모두 있고 형이 맞다 — `version: "0.1.4"`(따옴표 semver) · `status: draft` · `created: "2026-09-30"` · `updated: "2026-10-05"` · `priority: P1` · `phase: "Phase 1.7 — 일정·활동 화면 UI 통일"`(단계 이름 금지값 아님) · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부 별칭 없음. 선택 필드 `tier: L`(L14). 이 세션이 돌린 `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` → `✓ No findings — all SPEC documents are valid`.
- [N/A] MP-4 Section 22 language neutrality: 단일 언어(Swift) 앱 SPEC이다.
- [PASS] MP-5 D7 cross-SPEC reconciliation: `grep -Eoh 'SPEC-([A-Z][A-Z0-9]+-)+[0-9]+' *.md | sort -u` → SPEC-UIKIT-003·004·005·007·008·009(자기 자신). 다섯 모두 `.moai/specs/<ID>/spec.md`가 있고 `status: completed`다. BLOCKING 없음.
- [PASS] MP-6 D8 cross-platform discipline: `grep -c syscall` → 일곱 파일 모두 0.
- [PASS] MP-7 clarification gate: `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` → 무출력(exit 1). 단서는 이전 회차와 같다 — 운영자 답과 방침의 원 발화는 이 감사가 관측하지 않았다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.85 | 0.75–1.0 사이(1.0 쪽) | review-3의 모호함 둘이 닫혔다 — AC-015는 "세 구간"을 정확히 셋으로 나열하고(acceptance.md:L263·L274), 달력 점의 규칙이 REQ-023 근거(spec.md:L184)·design.md §4(L120)·§9(L236)·AC-010 (9)(acceptance.md:L198)에서 같은 말을 한다. 남은 것은 같은 쪽으로 풀리는 문구 둘: REQ-022의 규범 문장에는 측정 제외가 없고 근거·AC-022에만 있다(D30), REQ-023 근거의 점 문장은 "나열 구간도 없으면 도착일" 폴백을 빠뜨렸다(design·AC에는 있다 — D30에 함께 적음) |
| Completeness | 1.0 | 1.0 | HISTORY 0.1.0~0.1.4(spec.md:L23-29) · WHY §0-§1 · WHAT §2 · HOW `design.md` · REQ 23 · AC 24 · `### Out of Scope — …` 7개(`grep -c` = 7, 각 `-` 항목 있음) · frontmatter 12필드 · Tier L 산출물 다섯 + `spec-compact.md`·`progress.md` |
| Testability | 0.85 | 0.75–1.0 사이(1.0 쪽) | review-3의 흠(D20 — 경로 제한 없는 범위 명령이 올바른 카드를 FAIL로 읽음)이 닫혔고, 이 세션이 새 경로 규칙을 병합된 카드 t16 범위로 다시 돌려 작성자 기록과 같은 값을 얻었다(아래 D20). 남은 흠: AC-019 (6)과 새로 더한 AC-010 (9)의 `Store.swift` 명령이 주석 줄의 문자열도 센다(D25 — optional, 열린 채) |
| Traceability | 0.95 | 1.0 밴드에 근접 | REQ 23건 모두 AC가 있고 매트릭스(acceptance.md:L17-42) ↔ `plan.md` §0 REQ→AC(L22) ↔ §1 카드 표(L33-36)가 같다. review-3의 흠 둘 — (라)의 도달 기록 약속(D21)과 지시문 밖 맥 코드(D24) — 이 요구사항·수락 기준·계획에 같은 문장으로 들어갔다. 남은 흠: 경계 상황표의 두 행이 포인터 하나·모양 하나를 빠뜨렸다(D32 — optional) |

집계: 4 / (1/0.85 + 1/1.0 + 1/0.85 + 1/0.95) = 4 / (1.1765 + 1.0 + 1.1765 + 1.0526) = 4 / 4.4056 ≈ **0.91**. Tier L 통과선 0.85를 넘는다. 3회차 0.84에서 올랐다 — 점수 후퇴(STOP) 아님.

## Defects Found (structured defect-list)

번호는 review-3(D20~D29)에 이어 D30부터 붙였다. 이번 회차의 새 결함은 셋이고 **모두 optional**이다. blocking인 새 결함은 없다.

D30. REQ022-NORMATIVE-EXCLUSION — spec.md:L175(REQ-022) · spec.md:L184(REQ-023 근거의 점 문장) — (i) REQ-022의 규범 문장은 "touches no path outside the declared set of its card"인데, 모든 카드가 반드시 고치는 `.moai/specs/SPEC-UIKIT-009/progress.md`(AC-022 Given이 `card_base_sha`를 거기 적게 한다)는 선언 집합 밖이다. 이 경로를 측정에서 빼는 규칙은 같은 줄의 근거와 AC-022 (1)(acceptance.md:L370)·`plan.md` §5(L284)에만 있다. 글자 그대로 읽으면 규범 문장은 모든 카드에서 어겨지지만, 근거·AC·계획이 같은 제외를 말하므로 실행자는 한쪽으로 풀 것이다. (ii) REQ-023 근거의 점 문장은 "앵커가 있으면 A의 날 하나, 없으면 공유 함수가 돌려주는 나열 구간 [출발, 도착]을 기존 `dayKeys`에 넘기므로"라고 쓰고, 나열 구간도 없는 경우(계산된 구간인데 `arrivalDate <= departureDate` — 예: 이동시간 0)의 도착일 키 폴백을 빠뜨렸다. design.md:L120과 AC-010 (9)(acceptance.md:L198)에는 폴백이 있다. 규범 문장의 "a leg whose travel time has been computed shall be listed and drawn as before"가 이 경우를 덮으므로 결과는 같다. — Severity: minor — Class: optional — Required fix(원할 때): (i) REQ-022 문장 끝에 ", where the measurement excludes this SPEC's directory and `.moai/reports/`"를 더한다. (ii) REQ-023 근거 문장에 "나열 구간도 없으면 도착일 키 하나"를 더한다.

D31. AC019-6-PROXY-REASON — acceptance.md:L336("대리 지표는 더하지 않았다(기준값 없이 세는 지표가 되므로)") vs progress.md:L139("대리 지표는 더하지 않았다(지시)") — 수락 기준 본문이 적은 이유가 사실과 다르다. 기준값은 잴 수 있다 — 이 세션이 기준 트리에서 `grep -c '\.onTapGesture {' Shared/ContentView.swift` → **3**(`:618`·`:641`·`:674`)을 얻었다. 진행 기록은 같은 결정의 이유를 "지시"라고 적어 두 문서의 이유가 다르다. 대리 지표를 두지 않는 결정 자체는 review-3이 "원한다면"으로 적은 선택이라 문제가 아니다. — Severity: minor — Class: optional — Required fix(원할 때): 괄호를 "(오케스트레이터 지시 — 갭으로만 다룬다)"로 고치거나, 대리 지표 `grep -c '\.onTapGesture {' Shared/ContentView.swift` ≥ **3**(기준 3)을 갭 문장에 더한다.

D32. BOUNDARY-TABLE-SIBLING-ROWS — acceptance.md:L401((나) 행) · L404(단독 이동 행) vs L403((라) 행) · spec.md:L184 — 0.1.4는 경계 상황표의 (라) 행에 AC-010 (13)을 더했지만(`(7)(11)(12)` → `(7)(11)(12)(13)`, progress.md:L136), 같은 이유로 (13)이 덮는 (나) 행(`AC-010 (2)(4)(7)(9)(11)(12)`)에는 더하지 않았다 — (13)은 "(12)의 레코드를 하나씩" 넣는 단언이고 (12)에는 자정 (나)가 있다(acceptance.md:L201-202). 또 단독 이동 행은 "모양 (가)~(다)가 그대로 생긴다"고 쓰지만 REQ-023 근거는 "단독 이동도 같은 네 모양을 갖는다"(spec.md:L184)이고 AC-010 Given은 (라)까지 네 모양을 모두 단독 이동으로 만든다(acceptance.md:L187). 이 회차들이 거듭 보인 부류(한 모양에 대해 고친 문장이 형제 문장을 놓침)이지만, 경계표는 보조 표이고 AC 본문의 포인터는 맞다. — Severity: minor — Class: optional — Required fix(원할 때): L401 (나) 행의 포인터에 `(13)`을 더하고, L404 행의 "(가)~(다)"를 "(가)~(라)"로 고친다.

D25(열린 채, optional — review-3에서 넘어옴, 이번에 범위가 조금 넓어짐). AC019-6-COMMENT-FP — acceptance.md:L336 — `git grep -e '#if os'`가 주석 안의 문자열도 잡는 문제는 그대로다. 0.1.4가 AC-010 (9)에 더한 `grep -c 'e.arrivalDate > dep' Shared/Store.swift`·`git grep -c … -- Shared/Store.swift`와 기존 `awk '/func recomputeDaysWithSchedule/,/^    }$/' … | grep -c departureDate`도 같은 모양이다 — 구현이 그 함수 안에 옛 조건을 설명하는 주석을 남기면 거짓 FAIL이 난다(코드 읽기, 실행하지 않음). — Severity: minor — Class: optional — Required fix(원할 때): 주석 줄을 거르는 `grep -v '^\s*//'`를 파이프에 넣거나, 갭 문장에 "주석 줄이 잡히면 그 줄을 §E.2에 적고 판정에서 뺀다"를 더한다.

## Regression Check (Iteration 2+ only)

Defects from previous iteration (review-3):

- **D20 (AC-022 경로 집합 · 선언 문서 어긋남) — RESOLVED.**
  - 현재 문장: AC-022 Given "잴 경로(review-3 D20) … SPEC 디렉터리(`.moai/specs/SPEC-UIKIT-009/` — 카드가 반드시 고치는 `progress.md` §E.2 포함)와 보고서(`.moai/reports/`)는 선언 목록에 넣지 않고 범위 측정에서 뺀다"(acceptance.md:L367) · (1) `git diff --name-only <BASE> HEAD -- . ':!.moai/specs/SPEC-UIKIT-009' ':!.moai/reports'`(L370) · (2) `git diff --numstat <BASE> HEAD -- Shared Tools`(L371) · 양성 대조(L372). 같은 경로 규칙이 `plan.md` §5 범위 행(L284), REQ-022 근거(spec.md:L175), `spec-compact.md:L76`에 있다. 선언 문서: `plan.md` MA(L40) · MB(L52) · MC(L60) 모두 "문서: CHECKLIST·루트 `plan.md`는 sync" — `spec-compact.md:L86-88`과 같다.
  - 이 세션의 재측정(이미 병합된 t16 범위, 자기 SPEC 이름만 008로 — 스크래치 없이 읽기 전용 `git diff`): `git log -1 --format='%h %p %s' 291c3cf` → `291c3cf 4a2043e c230ef9 Merge WT-place-resolution: t16 … SPEC-UIKIT-008 3-phase close` · `git diff --name-only 291c3cf^1 291c3cf | wc -l` → **33**(디렉터리별 `.moai/reports` 21 · `.moai/specs` 5 · 소스·문서 7) · 제외를 건 명령 → **8**줄(`.moai/specs/SPEC-UIKIT-005/acceptance.md` · `CHECKLIST.md` · `Shared/AIAssistant.swift` · `Shared/AIChatView.swift` · `Shared/EditCard.swift` · `Shared/EditCardView.swift` · `Tools/GuardDriver.swift` · `plan.md`) · `--numstat … | awk '$1+$2>=100' | wc -l` → **19**(보고서 12 · SPEC 4 · `CHECKLIST.md` · 소스 둘) · `-- Shared Tools`로 → **2**줄(`764 84 Shared/AIAssistant.swift` · `1661 6 Tools/GuardDriver.swift`). acceptance.md:L372의 값과 모두 같다. 전례 `.moai/specs/SPEC-UIKIT-008/acceptance.md:271`이 같은 pathspec 꼴(`-- . ':!.moai/specs/SPEC-UIKIT-008' …`)임을 원문으로 확인했다.
  - 카드별 선언과 요구사항 대조: MA가 고칠 것(진입점·조회·재현 단언)은 `Store`·`GuardDriver`, MB는 `EditCard`·`AddActivityView`·`ActivityDetailView`·`GuardDriver`·`EventDetailView`, MC는 `Models`·`ContentView`·`GuardDriver`·`Store`(작게)로 각 카드의 AC 항목이 선언 밖 파일을 요구하지 않는다(코드 읽기).
- **D21 (REQ-020의 (라) 도달 기록 약속) — RESOLVED.**
  - 현재 문장: REQ-020 "the shapes a failed estimate leaves on a leg newly created through `addEvent` (shapes (가)·(나)) shall be recorded as a reach record"(spec.md:L171), 근거 ② 끝의 "**갭(review-3 D21)**: 반복 뒤 회차 (라)도 … 드라이버에는 결정적 경로가 없고 그 레코드를 보는 단언도 없다 … (라)는 메모리에서 만든 레코드로만 보인다(AC-010 (7)(11)(12)(13))". 같은 갭이 AC-010 갭 줄(acceptance.md:L203) · AC-020 (5) ⓑ(L349) · 결정성 문단 ④(L48) · 경계표 (라) 행(L403) · `plan.md` A1(L45) · `spec-compact.md`(L41·L64·L74)에 같은 말로 있다. review-3이 권한 (a)안 그대로다.
  - 근거 좌표 재측정: `sed -n 626,632p Shared/Store.swift` → `addRecurringEvents`의 `origin: Place,`가 `:629`(비-Optional) · `sed -n 654,680p` → 첫 회차 추정 `:673` · 캐시 `:674` · `else if let` `:676` · 캐시 적용 `:677` · 생성자 `arrivalDate: anchorTime`(`:656-658`). `sed -n 2214,2220p Shared/AIAssistant.swift` → `:2217` `addRecurringEvents` · `:2218` `anchor: .departure(…)`. `sed -n 2560,2570p Tools/GuardDriver.swift` → `"return_time": "13:00"`이 있는 반복 생성(`:2567-2568`). 모두 일치한다.
- **D22 (AC-015 "네 구간") — RESOLVED.** acceptance.md:L263 "정확히 **세 구간** — R의 가는 편 · R의 오는 편 · L의 오는 편 — 이고 L에는 가는 편을 두지 않는다" · L274 "Given의 세 구간에 부르면 반환이 정확히 `{R 가는 편 → R, R 오는 편 → R}`". `grep -n '네 구간\|세 구간\|구간 넷\|구간 셋' *.md` → 남은 "네 구간"은 HISTORY 0.1.4의 "전 → 후" 인용(spec.md:L29)과 진행 기록의 그 행(progress.md:L137)뿐이다. `:59`·`:240`의 "세 구간"은 다른 AC이고 실제로 셋이다.
- **D23 (달력 점의 사본이 설계에 남음) — RESOLVED.**
  - 현재 문장: `[REMOVE]` "나열과 점에 따로 복사된 판정 … (`ContentView.swift:89` · `Store.swift:136`의 같은 조건)"(spec.md:L182) · REQ-023 근거 "`:136`의 인라인 사본은 계산된 구간 쪽까지 통째로 없어진다(review-3 D23 …)"(L184) · design.md §4 "달력 점 … 같은 나열 구간을 기존 `dayKeys`에 넘기고, 나열 구간이 없으면 `failedBlockAnchor ?? arrivalDate`의 날 키 하나. 지금의 `:136-140` 인라인 조건은 계산된 구간 쪽까지 남지 않는다"(design.md:L120) · §9 "달력 점의 모양은 0.1.4에서 정했다"(L236) · AC-010 (9) "**점의 규칙(review-3 D23)** … `grep -c 'e.arrivalDate > dep' Shared/ContentView.swift Shared/Store.swift` = 두 파일 모두 **0**(기준 1 / 1)"(acceptance.md:L198) · `plan.md` MC(L60)·C3(L64).
  - 기준값 재측정: `grep -c 'e.arrivalDate > dep' Shared/ContentView.swift Shared/Store.swift` → `Shared/ContentView.swift:1` · `Shared/Store.swift:1` · `git grep -c 'e.arrivalDate > dep' -- Shared/Store.swift` → `Shared/Store.swift:1`, exit 0 · `git grep -c 'listedSpan' -- Shared/Store.swift` → 무출력, exit 1(0건일 때의 모양 — AC가 기대값을 "무출력 · exit 1"로 적은 근거와 같다) · `awk '/func recomputeDaysWithSchedule/,/^    }$/' Shared/Store.swift | grep -c departureDate` → `1`(범위 19줄 — 함수 `:132-150`을 정확히 자른다) · `awk '/private func events\(on date/,/^    }$/' Shared/ContentView.swift | grep -c departureDate` → `1`(범위 9줄 — `:87-95`) · `grep -c 'e.departureDate != nil' Shared/ContentView.swift` → `1`. `sed -n 128,158p Shared/Store.swift`·`sed -n 80,96p Shared/ContentView.swift`로 두 사본(`:136` · `:89`)과 그 `else` 폴백(도착일)을 읽었고, 새 규칙(나열 구간 → `dayKeys`, 없으면 `failedBlockAnchor ?? arrivalDate`)이 계산된 구간에서 같은 날을 낸다는 것은 코드 읽기로 맞다.
  - 네 문서의 점 규칙 대조: design.md §4 · AC-010 (9)·(13) · `plan.md` C3 · REQ-023 근거가 같은 규칙이다. 근거 문장 하나만 폴백을 빠뜨렸다(D30 (ii), optional).
- **D24 (지시문 밖 맥 전용 탭) — RESOLVED.**
  - 현재 문장: AC-019 (6) 갭 "ⓑ 지시문 **밖**에서 주석이 맥 전용으로 밝힌 코드를 지우거나 바꾼 변경 … `Shared/ContentView.swift`의 시간표 블록 뷰 `.onTapGesture` 셋이다 — `:618`(활동 블록) · `:641`(`failedEstimateBlockView`) · `:674`(이동 블록)"(acceptance.md:L336) · `plan.md` §4 `code-safety` 몫(L267) · P-1 "run이 하지 않는 것"(L78) · C3(L64) · REQ-019 근거(spec.md:L169) · `spec-compact.md:L73`.
  - 좌표 재측정: `grep -n 'onTapGesture\|macOS' Shared/ContentView.swift` → 코드 줄 `:618`·`:641`·`:674`, 주석 `:616-617`·`:625`·`:673`(나머지 `:456`·`:459`·`:883`은 iOS 오버레이 주석), 지시문 `:195`. `sed -n 612,680p`로 주석 원문 "도달하지 않는다(무해한 죽은 코드). macOS에서는 이 탭이 그대로 쓰인다"(`:617`·`:673`)와 "macOS에서만 필요하지만"(`:625`)을 확인했다. 형제 누락 탐색: 세 카드가 건드리는 일곱 파일(`Store`·`Models`·`EditCard`·`AddActivityView`·`ActivityDetailView`·`EventDetailView`·`ContentView`)에서 `grep -n -i 'macos\|AppKit\|NSView\|#if os\|#else\|#endif'` → 지시문 밖에서 맥 전용을 밝힌 코드는 `ContentView`의 이 셋뿐이고 `#else` 분기는 없다. 목록에 빠진 자리 없음.
- **D25 (AC-019 (6) 주석 거짓 FAIL) — OPEN, optional.** 0.1.4가 의도적으로 손대지 않았다. 범위가 AC-010 (9)의 새 `Store.swift` 명령까지 조금 넓어졌다(위 Defects의 D25 줄). blocking으로 바뀌지 않았다.
- **D26 (AC-002 (7) 힌트) — RESOLVED(이 판의 수정이 아니라 기록 없는 선행 편집으로).** acceptance.md:L71 "오는 편(이동시간 힌트 30분 — 도착이 다음 날 00:20)" · L79 "이 오는 편은 **이동시간 힌트 30분으로 만든다** … — review-3 D26". review-3이 권한 문구와 같다. 작성자를 확인할 수 없다는 것은 `progress.md`:L131·L150에 갭으로 적혀 있다 — 문구 자체는 맞으므로 결함으로 세지 않는다.
- **D27 (시뮬레이터 비행기 모드) — OPEN, optional.** 스크립트 13a(acceptance.md:L448)·20(L458)의 "비행기 모드 또는 Mac 네트워크 차단"이 그대로다. 근거는 여전히 일반 지식이고 UNVERIFIED다.
- **D28 (REQ-020이 REQ-013 결함을 빠뜨림) — OPEN, optional.** spec.md:L171 결함 목록 넷 그대로.
- **D29 (맥 갭이 적힌 것보다 좁음) — OPEN, optional.** spec.md:L217 그대로.
- **D11 (REQ 분할·HOW) — OPEN, optional, 채택 안 함**(HISTORY 0.1.1·0.1.2). 네 회차 모두 남았지만 오케스트레이터가 채택하지 않기로 한 optional 항목이라 정체로 세지 않는다.

정체 감지: 네 회차에 걸쳐 그대로 남은 blocking 결함은 없다. review-3의 blocking 다섯은 모두 닫혔다. 이번 새 결함 셋(D30~D32)은 모두 optional이며, 그중 D32는 이 회차들이 거듭 보인 부류(한 모양에 대해 고친 문장이 형제 문장을 놓침)가 보조 표에서 한 번 더 나온 것이다.

## Gaps (이 감사가 관측하지 않은 것)

- 드라이버·빌드·시뮬레이터를 실행하지 않았다(지시). AC-010 (9)의 MC 뒤 기대값(0건·무출력)은 구현이 없어 관측할 수 없고, 기준값만 이 세션이 쟀다.
- AC-022의 새 경로 규칙은 이 SPEC의 카드 커밋이 없어 이 SPEC 위에서는 돌리지 못했다. 양성 대조는 병합된 t16 범위에서 읽기 전용 `git diff`로 다시 돌렸다(스크래치 사본은 쓰지 않았다).
- D21의 "드라이버에 (라)에 이르는 결정적 경로가 없다"는 작성자와 이 세션 모두 코드 읽기다. 예를 들어 좌표가 잘못된 `Place`로 추정을 네트워크 없이 실패시킬 수 있는지는 `DirectionsService`를 실행해 보지 않아 모른다 — SPEC은 이것을 갭으로 받아들였으므로 판정에 쓰지 않았다.
- D25의 범위 확장(AC-010 (9)의 주석 거짓 FAIL)은 스크래치 실험 없이 명령 모양으로 판단했다.
- D27은 일반 지식이고 UNVERIFIED다.
- `mcp__moai__spec_audit`/`spec_drift`는 부르지 않았다(워크트리 SPEC을 보지 못한다는 기록 — progress.md:L234). 워크트리 CLI 린트로 대신했다.
- 교차 모델 의견 없음(GLM `inconclusive`, codex off).
- `research.md`는 관련 줄만 `grep`으로 대조했다(0.1.4가 고치지 않았다고 기록한 파일이고, 남은 문장은 0.1.1·0.1.2 측정 기록이다).

## Recommendation

**PASS.** 판정 규칙의 네 조건을 모두 만족한다.

1. **review-3 blocking 다섯이 모두 RESOLVED**: D20(경로 규칙 · 선언 문서 — 양성 대조 33/8 · 19/2를 이 세션이 다시 얻음) · D21(REQ-020을 `addEvent`의 (가)·(나)로 좁히고 (라)를 일곱 자리에 같은 문장의 갭으로) · D22("세 구간") · D23(점의 사본 제거 — 네 문서가 같은 규칙, 기준값 `git grep`·`awk` 재측정) · D24(`.onTapGesture` 셋 `:618`·`:641`·`:674` 좌표 확인, 형제 파일에 빠진 자리 없음).
2. **새 blocking 결함 없음**: 새로 찾은 D30~D32는 모두 문구·보조 표 수준이고, 실행자가 이웃 문장(근거·AC 본문)으로 같은 쪽으로 풀 수 있다.
3. **must-pass 일곱 모두 통과**(MP-4는 N/A): 위 Must-Pass Results의 명령 출력.
4. **점수 0.91 ≥ 0.85**.

오케스트레이터 재량(optional — 고치지 않아도 판정은 바뀌지 않는다):

1. (D32) acceptance.md:L401 (나) 행에 `(13)`을 더하고 L404의 "(가)~(다)"를 "(가)~(라)"로.
2. (D30) REQ-022 문장 끝에 측정 제외 절을, REQ-023 근거의 점 문장에 "나열 구간도 없으면 도착일 키 하나"를.
3. (D31) AC-019 (6)의 괄호 이유를 진행 기록과 맞추거나, 대리 지표 `grep -c '\.onTapGesture {' Shared/ContentView.swift` ≥ 3(기준 3)을 더한다.
4. (D25·D27·D28·D29·D11) 이전 회차의 optional — 그대로 두어도 된다. 다만 D25는 MC의 AC-010 (9) 판정 때 주석 줄이 잡히면 그 줄을 §E.2에 적고 판정에서 빼는 것이 안전하다.

이 PASS는 Phase 1 감사 판정일 뿐이고 Implementation Kickoff Approval(plan→run 사람 게이트)을 대신하지 않는다.
