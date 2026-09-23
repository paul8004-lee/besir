# SPEC 검토 보고서: SPEC-UIKIT-007
Iteration: 2/3
Verdict: FAIL
Overall Score: 0.89

> 작성자 추론 맥락은 전달되지 않았다(M1 Context Isolation). 호출자가 준 사실("D1은 게이트 몫으로 남김, D15 유지, D14는 plan.md §4로 이동, 소스 무변경")은 무엇을 볼지 정하는 데만 썼고, 각 항목은 트리에서 다시 확인했다.
> 범위: 1회차 결함 목록(D1~D15)의 델타와 그 회귀, 그리고 must-pass 전 항목 재판정. `Shared/`는 여전히 `73ceb43`과 같다(`git diff --quiet 73ceb43 -- Shared/ proxy/ project.yml CHECKLIST.md` exit 0). 그래서 1회차에 전수 대조한 코드 인용은 다시 재지 않았다. 새로 들어온 인용만 대조했다.
> 교차 모델: `audit_multi`(claude required · codex off · glm advisory) → overall `needs-attention`. GLM은 이번에도 `inconclusive`(응답 본문 없음, fail-open)라 판정은 claude 단독이다.

**FAIL의 성격.** 남은 must-pass 실패는 **MP-7 하나**다. 그 원인은 리드의 착수 승인 게이트가 아직 열리지 않은 것이고, 작성 결함이 아니다. 1회차 blocking 결함 가운데 manager-spec 몫(D2~D6·D13)은 전부 해소됐다. 새로 찾은 결함은 모두 optional이다. 점수는 0.79 → 0.89로 올랐으므로 STOP 신호는 없다.

**3회차 전에 반드시 알아둘 것.** D1(MP-7)은 1·2회차에 같은 모양으로 남아 있다. 게이트 없이 3회차를 돌리면 "세 회차 연속 무변경" 정체 결함이 되고, 3회차가 상한이다. 그러니 **리드가 게이트를 먼저 열고, 그 결정을 반영한 뒤 3회차를 돌려야 한다.**

## Must-Pass Results

- [PASS] **MP-1 REQ 번호 일관성**: `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:91)·002(:93)·003(:95)·004(:97)·005(:101)·006(:103)·007(:107)·008(:109). 연속이고 중복이 없으며 세 자리가 일관된다. 옛 번호 잔재도 없다 — `grep -n -E 'REQ-0[1-9][0-9]|REQ-[1-9]|·0(10|11|20|21)\b|0(10|11|20|21)→|0(10|11|20|21)번대|\(0(10|11|20|21)' spec.md plan.md progress.md` → 출력 없음, exit 1.
- [PASS] **MP-2 GEARS 형식** — *판정 층위: 요구사항 층(`spec.md` §2 :91-109)만.* AC(§3.1)는 검증 층이라 채점하지 않았다. Event-driven 3건(001·003·008), State-driven 1건(002), Where 2건(004·005), Ubiquitous 1건(006), Unwanted 1건(007 "The change shall not modify…"). REQ-004는 "Where the sheet is constructed in create mode (no event to edit), or with an event whose saved origin is nil"로 바뀌어 정적 설정(생성 인자)임이 문장에 드러난다. 인용한 생성 자리 둘은 `ContentView.swift:151` `AddEventView()`와 `EventDetailView.swift:79` `AddEventView(editing: event)`이고, `grep -n 'AddEventView(' Shared/*.swift`가 찍는 것도 정확히 이 둘이다.
- [PASS] **MP-3 YAML frontmatter**: `spec.md:1-17`은 1회차와 같다. 12/12 필드, 거부 별칭 0건. `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` → `✓ No findings — all SPEC documents are valid`. 개정이 커밋 전에 이루어졌으므로 `version: "0.1.0"`을 유지한 것도 타당하다(HISTORY :25 "커밋 전에").
- [N/A] **MP-4 언어 중립성**: 단일 언어(Swift) 앱이다.
- [PASS] **MP-5 D7**: 참조 SPEC-UIKIT-002·003·005·006은 모두 `status: completed`다. 새 참조는 없고, retired/superseded/archived나 미발견도 0건이다.
- [PASS] **MP-6 D8**: `grep -c 'syscall'` → 0·0·0.
- [FAIL] **MP-7 명확화 게이트** — *clarification gate finding*: `grep -n '\[NEEDS CLARIFICATION' plan.md` → `:47`(D-1) · `:57`(D-2) · `:66`(Tier). `research.md`는 없다. 표식이 spec.md에 없다는 것(0건)은 규약에 맞는다. 해소 경로는 오케스트레이터(리드)의 `AskUserQuestion`이다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.85 | 0.75~1.0 사이 | D3 해소 — REQ-007(:107)이 run 범위에 SPEC 디렉터리를 선언해 REQ-008(:109)과의 충돌이 사라졌다. D9 해소(:97). D10 부분 해소 — 꼬리에 "근거:"·"수리 모양(참고):" 표식이 붙었다(:91·:93·:95·:97·:101·:103·:107·:109). 남은 것: REQ-007의 감사 보고서 예외가 비규범 표식("근거:") 안에 있다(N1). |
| Completeness | 0.90 | 1.0 대역 하단 | 필수 절은 1회차와 같이 모두 있다(HISTORY :21-25, 배경 :37-85, 요구사항 :87-109, AC :115-149, `### Out of Scope —` 4개 :192-208). 감점 사유는 하나 남았다 — D-1 (b) 채택 시 AC-002의 새 값이 여전히 "바뀐다"(:117)뿐인데, 이것은 D1(게이트)에 묶여 있다. |
| Testability | 0.85 | 0.75~1.0 사이 | D5·D7·D8·D12·D13 해소: 프리필 칩 두 형태(:145·:169·:179), N₀(:141·:166), AC-003 기계 신호(:129), (나)의 기록 값과 재시도 1회(:137·:171), `약 Z분`(±2분)(:145·:180). 남은 것: AC-005에서 Y < X·출발 시각 > D가 통과 조건인지 기록 값인지 흐려졌다(N4). ±2분은 여전히 실측값이 아닌 가정이다(progress.md:88). |
| Traceability | 0.95 | 1.0 대역 하단 | D4 해소 — `plan.md:18-19` 매핑이 AC 헤더 8개(:119-147)와 한 칸도 어긋나지 않는다(001→001·006 · 002→006·007 · 003→006 · 004→007 · 005→002 · 006→003 · 007→002·004·008 · 008→005·006). D11 해소 — REQ-004 뒤 절반이 AC-001 첫째 grep에 묶였다(:97·:145). 코드 읽기 판정이라는 성격은 남는다. |

집계: 조화평균 4 / (1/0.85 + 1/0.90 + 1/0.85 + 1/0.95) = 4 / 4.5167 = **0.89**. 1회차(0.79)보다 올랐으므로 STOP 신호는 없다. Tier S 통과선 0.75 이상이다. 판정은 MP-7 방화벽으로 FAIL이다.

## Defects Found (structured defect-list)

D1. MP-7-clarification-gate — plan.md:L47·L57·L66 — 게이트 표식 3건이 미해소로 남아 있다(설계상 리드 몫). — Severity: critical — Class: blocking — Required fix: (1) 리드가 착수 승인 게이트에서 `AskUserQuestion`으로 D-1·D-2·Tier를 결정한다. (2) manager-spec이 표식을 결정 사실로 바꾸고, 조건부 요구사항 둘을 무조건형으로 다시 쓴다 — REQ-005(:101) "Where the kickoff gate resolves D-1…"와 REQ-008(:109)의 D-2 의존. :117·:212도 함께 고친다. (3) D-1 (b)가 채택되면 REQ-005를 철회하거나 새로 쓰고 AC-002의 셋째 값과 헝크 조건을 구체 값으로 다시 적는다. 그 경우 3회차 범위가 커진다.

N1. REQ-007-carve-out-in-nonnormative-tail — spec.md:L107·L125 — 영어 규범 문장은 "shall not modify any repository path outside its declared files"다. 그런데 plan 감사 보고서(`.moai/reports/plan-audit/…`, `git check-ignore` exit 1 — 무시 목록 밖)를 경계에서 빼는 예외는 "근거:" 꼬리에만 있다. AC-002 첫째 명령은 `':!.moai/reports/plan-audit'`로 그 경로를 뺀다. D10에서 비규범이라고 표시한 자리가 규범 예외를 싣고 있는 셈이다. 합리적인 엔지니어라면 같은 뜻으로 읽겠지만, 문언만 보면 REQ와 AC가 다르다. — Severity: minor — Class: optional — Required fix: 규범 문장에 "(plan-audit reports under `.moai/reports/plan-audit/` excepted)"를 넣는다.

N2. AC-002-whole-repo-vs-plan-md-duty — spec.md:L107·L125 — D3를 고치면서 AC-002 첫째 명령이 저장소 전체 대조로 넓어졌다("그 밖의 경로가 하나라도 있으면 FAIL"). 이제 run 중 루트 `plan.md`를 바꾸면 AC-002가 기계적으로 떨어진다. 그런데 `CLAUDE.md`는 "계획이 실제와 달라지면 **그 자리에서** 이 파일을 갱신한다"고 지시한다. 직전 선례도 있다 — 카드 t6의 run 커밋 `27d35a5`("M2 증거 영속 + … 후속 14번")가 run 중에 루트 `plan.md`에 9줄을 더했다(`git show --stat 27d35a5` → `plan.md | 9 +++++++++`). 이 SPEC의 경계(run 중 발견은 progress.md에 적고 sync가 옮긴다)는 정당한 설계지만 문서에 적혀 있지 않다. 그래서 `CLAUDE.md`를 문언대로 따르는 run 레인은 AC-002에 걸린다. — Severity: minor — Class: optional — Required fix: REQ-007 근거 또는 plan.md §4에 "run 중 새 발견은 `progress.md` §E.2의 카드 밖 발견에 적고, sync가 루트 `plan.md`로 옮긴다"는 한 문장을 넣는다. 게이트 반영 편집 때 함께 넣으면 된다.

N3. AC-002-fixed-base-merge-sensitivity — spec.md:L125 — 기준이 `73ceb43` 고정이다. run이 끝나기 전에 카드 브랜치로 `origin/master` 병합이 한 번이라도 들어오면, 다른 카드의 경로가 diff에 섞여 거짓 FAIL이 된다. 1회차의 좁은 범위(`Shared/ Tools/ ShareExtension/ proxy/ project.yml`)에도 같은 성질이 있었지만, 범위가 넓어져 걸릴 자리가 늘었다. 가능성은 낮다. — Severity: minor — Class: optional — Required fix: "카드 브랜치에 병합 커밋이 있으면 `git log --no-merges --name-only --format= 73ceb43..HEAD`로 이 카드 커밋만 센다"를 덧붙이거나, run 종료 전 병합 금지를 적는다.

N4. AC-005-condition-vs-record-blur — spec.md:L137 — 1회차에는 "(가)이면 4번의 Y < X이고 출발 시각이 D보다 늦으며, 5번의 … 회색이다"가 통과 조건으로 분명했다. 개정 뒤에는 이것이 "값은 (가)면 N₀·X·D·Y(4번의 Y < X, 출발 시각이 D보다 늦음)"라는 괄호 속으로 들어갔다. (가)로 분류됐는데 경로 조회가 흔들려 Y ≥ X가 나오면 AC-005가 통과인지 실패인지 문언이 정하지 않는다. — Severity: minor — Class: optional — Required fix: "(가)의 통과 조건: Y < X이고 출발 시각이 D보다 늦다. 5번은 (가)·(나) 모두 줄이 비고 저장이 회색이다"처럼 조건을 괄호 밖으로 꺼낸다.

N5. progress-self-invalidating-records — progress.md:L129-L130·L35 — (1) §F.1은 "표식 `grep -c 'NEEDS CLARIFICATION'` → plan 3 · spec 0 · progress 0"이라고 적었다. 그런데 그 줄(:129)에 패턴 문자열이 들어가 있어서, 지금 다시 돌리면 progress는 **1**이다(이 감사가 실측: `grep -c 'NEEDS CLARIFICATION' progress.md` → 1). 바로 앞 문장은 같은 자기참조를 피하려고 패턴을 옮겨 적지 않았는데, 이 줄은 그러지 못했다. (2) :35의 "exit 1(추적 대상 …)"에서 `git check-ignore` exit 1은 "무시 목록 밖"이라는 뜻이다. 그 파일은 지금 추적되고 있지 않다(`git status --short` → `??`). — Severity: minor — Class: optional — Required fix: (1)은 "이 줄을 쓰기 전 측정"이라고 적거나 패턴을 옮겨 적지 않는다. (2)는 "무시 목록 밖(커밋하면 diff에 잡힌다)"으로 고친다. MP-7에는 영향이 없다 — MP-7은 `[NEEDS CLARIFICATION` 괄호 표식을 plan.md·research.md에서만 본다.

## Regression Check (Iteration 2+ only)

1회차 결함 목록(`SPEC-UIKIT-007-review-1.md`)의 각 항목:

- D1 (MP-7 게이트 표식 3건): **UNRESOLVED(설계상)** — plan.md:47·57·66 그대로. 리드의 게이트 몫이다. 이번 회차 FAIL의 유일한 must-pass 원인이다.
- D2 (MP-1 REQ 번호 공백): **RESOLVED** — REQ-001~008(:91-109), 옛 번호 grep exit 1. AC 헤더(:123 REQ-005·007, :127 006, :131 007, :135 008, :139 001·002·003·008, :143 002·004, :147 007), spec.md:33 대역 서술("005·006"·"007·008"), :195(REQ-007), :212(REQ-005·REQ-008), plan.md :13·:16·:33-37·:39·:55까지 모두 옮겨졌다. §2 절 제목의 대역 표기("001번대" 등)도 지웠다(:89·:99·:105).
- D3 (REQ-020↔REQ-021 run 범위 충돌): **RESOLVED** — REQ-007(:107) "in run, `Shared/AddEventView.swift` and this SPEC directory (`progress.md` §E.2·§E.3, `spec.md` frontmatter `status`·`updated`)". 이 수정이 AC-002 범위를 넓혔고, 그 부작용은 N2·N3에 적었다.
- D4 (plan 매핑 002→005): **RESOLVED** — plan.md:18-19 "002→006·007"이고, "(AC-005는 수정 전 재현이라 REQ-002를 검증하지 않는다.)"가 덧붙었다. AC 헤더와 전 칸 일치한다.
- D5 (AC-007 6번 칩 글자 타이밍): **RESOLVED** — :145 "`현재 위치` 또는 `현재 위치(…)` 칩으로 프리필되고(…칩 글자가 아니다)", :179 같은 문구와 이유. 파트 A 3번(:169)과 §1.2의 3(:60)도 같은 두 형태로 맞췄다. 7번(:180)은 저장 이름을 칩 글자에서 읽게 했다 — `:447`의 `currentPlaceName ?? "현재 위치"`와 `:452`의 지명 부착이 같은 순간의 값을 쓰므로 맞는 추론이다.
- D6 (HISTORY 수): **RESOLVED** — :25 "어긋난 것은 F5·F6의 줄 범위 둘", "세 곳을 고쳤다 — 1번 …, 7번 …, 8번 …". progress.md:41-45와 일치한다.
- D13 (Z 허용치): **RESOLVED** — :145·:180 "`약 Z분`(±2분)".
- D7 (칩 글자 `강남역`, optional): **RESOLVED** — N₀(:166 "고른 뒤 출발지 칩에 찍힌 이름을 N₀로 적는다", :141·:171·:177).
- D8 (AC-003 판정·대리 신호, optional): **RESOLVED** — :129의 기계 신호는 '프리필' ≥1이고, '도달 불가'를 남기면 '편집 씨앗' ≥1이어야 한다. 검토자 판정은 "기록 항목(통과 기준 아님)"으로 내렸다. 기준선은 이 감사가 실측했다 — `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift | grep -c` '프리필' 0 · '도달 불가' 1(:535) · '편집 씨앗' 0. plan.md:127-128과 일치하고, `73ceb43`이 이 기준에 떨어진다는 서술도 맞다.
- D9 (REQ-004 Where 문형, optional): **RESOLVED** — :97. 생성 자리 인용 `ContentView.swift:151`·`EventDetailView.swift:79`가 맞다.
- D10 (규범성 꼬리·HOW, optional): **PARTIALLY RESOLVED(수용)** — 표식을 달았고, AC-001(:121)의 글자 그대로 식은 D-1 (a)의 일부로 명시했다. 요구사항 속 식별자는 한 줄 수리의 계약으로 남겼는데, 수용 가능하다. 다만 REQ-007의 "근거:" 꼬리에 규범 예외가 하나 남았다(N1).
- D11 (REQ-004 nil 절반, optional): **RESOLVED** — :97·:145가 AC-001 첫째 grep의 식을 판정 근거로 묶었다. 관측이 아니라는 점도 명시했다.
- D12 (AC-005 (나), optional): **RESOLVED** — :137·:171·:173, plan.md:74-76. 기록 값과 재시도 1회 상한이 들어갔다. 이 개정으로 (가)의 조건이 흐려진 부분은 N4에 적었다.
- D14 (편집 중 검색 기준 좌표, optional): **MOVED(수용)** — plan.md:104-108에 M3 렌즈 입력으로 들어갔다. 인용 `AddEventView.swift:378`과 `App.swift:90`은 1회차에 대조했다.
- D15 (frontmatter 부가 필드, optional): **KEPT(수용)** — lint가 통과하고, 자매 SPEC 관례와 같다.

정체 판정: 세 회차 연속으로 무변경인 결함은 없다(이번이 2회차). D1은 두 회차째 그대로지만 manager-spec이 진전하지 못해서가 아니라 게이트를 기다리는 것이다. 3회차가 게이트 전에 돌면 정체로 판정된다.

## Recommendation

**FAIL — 남은 blocking은 D1(게이트) 하나다.** manager-spec이 이번 회차에 고쳐야 할 blocking 결함은 없다.

1. **리드 — 게이트를 먼저 연다.** `plan.md` §2의 세 항목을 `AskUserQuestion`으로 정한다(:47 D-1, :57 D-2, :66 Tier). 이 감사가 확인한 판단 재료:
   - (a)안은 코드 한 줄이고 함수 본문을 바꾸지 않으며, 카드 전환 전 화면(`d3c9327` :73-74·:410·:425)의 동작으로 돌아간다.
   - (a)안에서도 "현재 위치" 칩 직접 탭은 동작한다(`choose` :276이 옛 좌표를 먼저 지운다).
   - 수리가 새로 깨우는 쓰기 경로는 1회차에 찾지 못했다.
2. **manager-spec — 게이트 결정을 반영하는 한 번의 편집.** 표식 3건을 결정 사실로 바꾸고, REQ-005·REQ-008의 조건절과 spec.md:117·:212를 갱신한다. 같은 편집에서 optional N1(예외를 규범 문장으로)·N2(run 중 발견의 행선지 한 문장)·N4(AC-005 조건을 괄호 밖으로)·N5(자기참조 기록)를 함께 처리하기를 권한다. N3는 재량이다.
3. **3회차 감사 범위:** 게이트 반영 델타 — 표식 0건, REQ-005/008 무조건형, :117·:212, 그리고 D-1 (b)면 AC-002 재명세 — 와 그 회귀 확인. D-1 (a)이고 편집이 문구 범위에 그치면 코드 인용은 다시 재지 않아도 된다.

## 검증 증거 (이 회차에 직접 돌린 명령)

| 주장 | 명령 | 관측 |
|---|---|---|
| 기준 트리 | `git rev-parse --short HEAD` · `git status --short` | `73ceb43` · `?? .moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md`, `?? .moai/specs/SPEC-UIKIT-007/` |
| 소스 무변경 | `git diff --quiet 73ceb43 -- Shared/ proxy/ project.yml CHECKLIST.md` | exit 0 |
| REQ·AC 헤더 | `grep -n '^- \*\*REQ-' spec.md` · `grep -n '^#### AC-' spec.md` | REQ-001~008(:91-109) · AC-001~008(:119-147), 헤더의 REQ 목록은 위 D2 항목 |
| 옛 번호 잔재 | `grep -n -E 'REQ-0[1-9][0-9]\|REQ-[1-9]\|·0(10\|11\|20\|21)\b\|…' spec.md plan.md progress.md` | 출력 없음, exit 1 |
| REQ 참조 분포 | `grep -o -E 'REQ-00[0-9]' … \| sort \| uniq -c` | 전부 001~008 범위 |
| lint | `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` | `✓ No findings` |
| MP-7 | `grep -n '\[NEEDS CLARIFICATION' plan.md` · `grep -c 'NEEDS CLARIFICATION' plan.md spec.md progress.md` | :47·:57·:66 · 3 / 0 / 1(progress.md:129의 자기참조 — N5) |
| D7 | 참조 추출 + `grep -m1 '^status:'` | 002·003·005·006 `completed` |
| D8 | `grep -c 'syscall'` | 0·0·0 |
| REQ-004 새 인용 | `awk 'NR>=148 && NR<=153' Shared/ContentView.swift` · `grep -n 'AddEventView(' Shared/*.swift` | :151 `AddEventView()` · ContentView:151, EventDetailView:79 두 자리뿐 |
| AC-003 기준선 | `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift \| grep -c` '프리필'/'도달 불가'/'편집 씨앗' | 0 / 1(:535) / 0 |
| N2 선례 | `git show --stat 27d35a5` · `git diff --name-only 8e68316~1 42c29c0` · `git diff --name-only 924f924~1 9f96219` | t6 run 커밋이 `plan.md | 9 +++` · t6 plan~run 종료 경로에 `plan.md` 포함 · t5는 자기 SPEC이 선언한 `CLAUDE.md`·`Shared/` 5개 |
| N1·N5 | `git check-ignore -v .moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md` | exit 1(무시 목록 밖), 파일은 `??`(미추적) |
| 교차 모델 | `mcp__moai__audit_multi` | overall `needs-attention`, glm `inconclusive`(fail-open) |

**미검증(Gaps).** 빌드·`npm test`·시뮬레이터·가드 드라이버는 금지 조건대로 돌리지 않았다. 1회차 D5·D7·D14의 코드 읽기 가설은 이번에도 관측하지 않았다. 개정은 그 가설을 흡수하는 방향(두 형태 허용, N₀ 기록)이라, 가설이 틀려도 AC가 거짓 실패하지 않는다. N3는 병합 시나리오의 가정이다.

**잔여 위험.** 파트 A가 (다)로 나올 가능성은 REQ-008이 처리한다. ±2분 허용치는 실측값이 아니다. GLM이 두 회차 연속 응답하지 않아 이번 판정도 단일 모델 판정이다.
