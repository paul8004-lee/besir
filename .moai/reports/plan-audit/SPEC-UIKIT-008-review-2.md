# SPEC Review Report: SPEC-UIKIT-008
Iteration: 2/3
Verdict: FAIL
Overall Score: 0.89

감사 대상 트리: `.claude/worktrees/t16` (branch `WT-place-resolution`, HEAD `2313e38`, 1회차 기준 `e1a40a6`, base `aa7b792`). SPEC 디렉터리는 이제 plan 커밋 `2313e38`에 추적된다(`git ls-files` — 네 파일, 렌즈 보고서 둘, 1회차 감사 보고서). Tier M이므로 `spec.md`(232줄) · `plan.md`(253줄) · `acceptance.md`(350줄)를 입력으로 모두 읽었고, `progress.md`(115줄)는 대조용으로 읽었다. `research.md`는 없다.

M1 맥락 격리: 작성자의 추론 맥락은 전달되지 않았다. 오케스트레이터 지시(작업 트리, 게이트 표식 분류, 게이트 선택지 점검 범위)는 MP-7의 **성격 규정**과 점검 범위에만 반영했고 판정 자체는 바꾸지 않았다.

2회차 범위: 1회차 결함 목록(D1~D22)의 차분과 회귀 점검, 그리고 0.1.1이 새로 쓴 REQ·AC·결정 선택지 문장의 회귀. 1회차 번호는 "1회차 Dn"으로, 이번 회차 결함은 아래 목록의 D1~D12로 적는다.

교차 모델: `audit.model: multi`(주 체크아웃 `workflow.yaml:77-82` — claude required · codex off · glm advisory). `mcp__moai__audit_multi` → claude FAIL, glm `inconclusive`("z.ai response carried no content", fail-open). 종합 FAIL, 이견 없음.

**FAIL의 성격과 요청 질문에 대한 답.**

- 필수 통과 실패는 **MP-7 하나**이고, 그것은 규약대로 `plan.md` §2에 남겨 둔 착수 게이트 표식 10건이다. 소유자는 칸반 리드이며 manager-spec의 작성 결함이 아니다.
- **게이트 표식 말고도 차단 결함이 셋 남아 있다.** 둘은 결정 선택지의 문장 결함이고(D-10 (b), D-6 (b) — 고르면 REQ/AC가 충족 불가능해진다), 하나는 요구사항끼리의 충돌이다(REQ-013의 경로 목록이 REQ-015·AC-013 (5)가 요구하는 편집을 금지한다). 셋 다 한 문단 이하로 고칠 수 있고, **권장안만 고르면** 앞의 둘은 발동하지 않는다. 셋째는 어느 선택지에서도 발동한다.
- 1회차의 작성 결함(차단 1회차 D2~D9·D12, 권고 1회차 D10~D17·D19~D22)은 **전부 해소됐다.** 해소 근거를 이 트리에서 다시 쟀다(§ Regression Check).
- 점수는 0.77 → **0.89**로 올라 Tier M 통과선 0.80을 넘었다. 점수 하락이 아니므로 STOP 신호는 없다.

## Must-Pass Results

- [PASS] **MP-1 REQ 번호 일관성** — `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:142)부터 REQ-015(:178)까지 15건, 빈 번호·중복 없음, 세 자리 채움 일관. `grep -c` = 15. AC도 `grep -c '^## AC-' acceptance.md` = 15(:47~:252)로 Tier M 상한 16 아래다.
- [PASS] **MP-2 GEARS 형식 (요구사항 층 `REQ-XXX` 기준으로 판정)** — 15건 모두 `shall` 구조이고 Ubiquitous · When · While · Where · shall not 패턴 또는 그 복합형이다. 1회차의 문체 결함 둘이 고쳐졌다: REQ-006(:154) "Where D-6 (a) is chosen, … ; where D-6 (b) is chosen, …", REQ-014(:176) "When the card is about to leave run, and again when it is about to leave sync, …". REQ-001(:142)은 Ubiquitous + Event-driven + Where(게이트 수용) 복합형이다. `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` → `✓ No findings — all SPEC documents are valid`. 경미한 문체 사항 하나(REQ-010 안의 소스 주석 절)는 선택 결함 D11로 두었다. AC는 검증 층이므로 Given-When-Then 여부를 여기서 채점하지 않았다(Group 4에서 따로 봄).
- [PASS] **MP-3 YAML 프런트매터** — spec.md:1-17. 필수 12필드가 모두 있다: `id: SPEC-UIKIT-008` · `title` 따옴표 · `version: "0.1.1"` · `status: draft` · `created`/`updated: "2026-09-26"` · `author: "manager-spec"` · `priority: P1` · `phase: "Phase 1.7 — 일정·활동 화면 UI 통일"`(단계명 금지값 아님) · `module: "shared-ui"` · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부되는 별칭 없음. `tier: M`은 선택 필드다. `related_specs`·`kanban_card`는 스키마 밖이지만 프로젝트 선례이고 린트가 통과한다(선택 결함 D12, 1회차 D18 이월).
- [N/A] **MP-4 언어 중립성** — 단일 언어(Swift) 앱 SPEC이다. 다언어 도구 서술이 없다.
- [PASS] **MP-5 D7 교차 SPEC** — D7 검증 명령을 세 파일에 돌렸다: SPEC-UIKIT-003 `completed` · SPEC-UIKIT-005 `completed` · SPEC-UIKIT-007 `completed` · SPEC-ASK-001 `draft` · (자기 자신) SPEC-UIKIT-008 `draft`. retired·superseded·archived가 없고, 찾지 못한 참조도 없다. BLOCKING 없음.
- [PASS] **MP-6 D8 교차 플랫폼** — `grep -c 'syscall'` → spec 0 · plan 0 · acceptance 0 · progress 0. 자동 통과.
- [FAIL] **MP-7 명확화 게이트** — *clarification gate finding*. `grep -rn '\[NEEDS CLARIFICATION' .moai/specs/SPEC-UIKIT-008/` → `plan.md` :55 D-1 · :67 D-2 · :76 D-3 · :90 D-4 · :97 D-5 · :110 D-6 · :116 D-7 · :126 D-8 · :135 D-9 · :142 D-10(10건). `spec.md`·`acceptance.md`에는 없다(관례대로). `research.md`는 없다. `progress.md:8` `kickoff_gate: **pending**`. **분류: 게이트 표식(착수 승인 게이트의 소유자는 칸반 리드)이며 manager-spec의 작성 결함이 아니다.** 리드가 `AskUserQuestion`으로 풀기 전에는 착수 승인이 진행될 수 없다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.85 | 0.75~1.0 사이 | 1회차의 해석 분기 셋이 닫혔다 — REQ-008(:160) 적용 도구 한정, REQ-010(:164) 카드·실행부 발동 조건 분리, REQ-001(:142) 극성 규칙. 남은 것: REQ-013(:174)의 경로 목록이 REQ-015(:178)와 어긋남(D4 — 합리적 엔지니어는 AC-011 (1)을 따라 같게 해석한다), 선택지 D-10 (b)·D-6 (b)를 고를 때의 해석 공백(D2·D3) |
| Completeness | 0.90 | 0.75~1.0 사이 | HISTORY(:21-26, 0.1.1 행이 결함 번호별 수리 자리를 적음) · 성격·예산(§0 :28-47) · 배경(§1 :49-136) · 요구사항(§2 :138-178) · AC(acceptance.md) · Out of Scope H3 8개와 글머리표(:182-217) · 프런트매터 12필드. 연구 입력(렌즈 보고서 둘)이 이제 추적된다. 감점: 선택지 분기가 acceptance에 다 옮겨지지 않았다(AC-005 (2)의 D-3 (c), AC-005 (5)·AC-007 (2)의 D-10 (b) — D2·D5) |
| Testability | 0.85 | 0.75~1.0 사이 | 1회차의 판정 오류가 모두 고쳐졌고 명령을 이 트리에서 모의 실행해 확인했다: 두 자리 이름(`✓ AB-H01`이 `AB-H10`을 세지 않음 → 1), AC-011 (1) 예외 명령(0줄, 예외를 빼면 7줄), AC-010 (3) 양성 대조(1)·Theme 줄(0), `[수용]` 계수(1), 경고 24줄 = 진단 12 + 캐럿 12. 감점: D-10 (b)·D-6 (b)를 고르면 AC-007 (2)·AC-012 (1)이 충족 불가능해지고(D2·D3), AC-010 (3)은 한 줄에 Theme와 직접 색이 섞이면 놓친다(D10) |
| Traceability | 0.95 | 0.75~1.0 사이 | 모든 REQ에 AC가 있고 모든 AC가 있는 REQ를 가리킨다. `plan.md:19-20` 대응표와 `acceptance.md:22-38` 매트릭스가 15쌍 모두 일치한다(1회차 D14 수리 — AC-014 → REQ-002·003·005~011, 011 → 009·014). 감점: REQ-013의 run 단계 SPEC 디렉터리 제한(progress §E.2·§E.3 + frontmatter)을 보는 AC가 없다(D9) |

집계: 조화평균 4 / (1/0.85 + 1/0.90 + 1/0.85 + 1/0.95) = 4 / 4.5167 = **0.89**. Tier M 통과선 0.80을 넘는다. FAIL은 점수가 아니라 MP-7과 차단 결함 D2~D4 때문이다. 1회차 0.77보다 높으므로 점수 하락 STOP 신호는 없다.

## Defects Found (structured defect-list)

D1. MP-7-clarification-gate (1회차 D1 이월) — plan.md:L55·L67·L76·L90·L97·L110·L116·L126·L135·L142 — 결정 D-1~D-10의 `[NEEDS CLARIFICATION]` 10건이 미해소다(`progress.md:8` `kickoff_gate: pending`). — Severity: critical — Class: blocking(**게이트 표식 — 소유자는 칸반 리드, 작성 결함 아님**) — Required fix: 리드가 착수 승인 게이트에서 D-1~D-10과 Tier M 확인을 `AskUserQuestion`으로 정한다. 그 전에 D2·D3(선택지 문장 결함)을 먼저 고쳐 운영자가 충족 불가능한 조합을 고르지 않게 한다. 결정 뒤 manager-spec이 각 표식을 채택 사실로 바꾸고 결정 번호가 붙은 REQ·AC 절을 채택안 하나로 확정한다.

D2. D-10(b)-incompatible-with-D-7(a)-and-D-6(b) — plan.md:L156-158, spec.md:L162 · L154, acceptance.md:L122-124 · L147-148 — D-10 (b)는 "지금 문구를 유지한다"이고, 새로 써야 하는 문구를 머무는 반복·U-2 두 줄로만 한정한다. 그런데 이 트리의 현재 문구 둘이 다른 선택지의 REQ와 맞지 않는다. ① 왕복 가는 편 캡션 `Shared/AIAssistant.swift:560`은 `"미리 정해진 출발지가 맞는지 골라 확인해 주세요. …"`라는 고정 문장이라 채워 온 값을 담지 않는다. **권장안 D-7 (a)**의 REQ-009(:162)는 "the row's caption shall name the filled value"를 요구하므로, D-10 (b) + D-7 (a)이면 REQ-009를 충족할 수 없고 `AB-H07`이 ✗로 남아 REQ-014의 ✗ 0(AC-012 (1))도 깨진다. REQ-001(:142)의 수용 목록에 H-7이 없어 `[수용]`으로 돌릴 길도 없다. ② 후보 캡션 `:735`는 `"… 아래 후보에서 골라 주세요."`다. D-6 (b)(후보를 닫아 둔다)와 함께 고르면 이 문장은 그 순간 거짓이 되어 REQ-006(:154)의 "no caption shall describe a screen state that is not true"를 어기고, D-6 (b) 자체가 캡션을 바꾸라고 하므로(plan.md:114) "지금 문구 유지"와 정면으로 맞선다. D-10 (b)의 "바뀌는 것"은 REQ-006의 구현 용어 절과 REQ-008의 조사·줄표 절만 "해당 없음"으로 돌릴 뿐, 이 두 조합을 적지 않았다. 또 plan은 D-10 (b)에서 AC-005 (5)·AC-006 (4)·AC-007 (2)의 신호가 바뀐다고 적지만 acceptance에는 AC-006 (4)(:137)에만 (D-10 (b)) 분기가 있고 AC-005 (5)·AC-007 (2)에는 없다 — AC-005 (5)의 첫 조건 `grep -c '첫 검색 결과가 말씀하신' = 0`은 무조건이라 D-10 (b)에서 반드시 실패한다. — Severity: major — Class: blocking(**게이트 선택지 결함 — 게이트 전에 고칠 것**) — Required fix: D-10 (b)의 "바뀌는 것"에 "(b)에서도 D-7 (a)이면 왕복 가는 편 캡션을, D-6 (b)이면 후보 카드 캡션을 위 표의 원문으로 새로 쓴다"를 넣거나, D-10 (b)를 "D-6 (a) · D-7 (c)와만 함께 고를 수 있다"로 한정한다. 어느 쪽이든 AC-005 (5)·AC-007 (2)에 (D-10 (b)) 분기를 plan과 같게 적는다.

D3. D-6(b)-is-an-unlisted-acceptance-of-H-5 — spec.md:L142 · L126, plan.md:L114, acceptance.md:L59-60 · L115-116 — REQ-001의 극성 규칙에서 M1 단언은 "가설이 틀렸을 때의 동작"을 적는다. H-5(:126)는 "후보가 첫 렌더에 보이지 않는다"이므로 `AB-H05`는 "후보 줄 `startsOpen == true`"를 단언하게 된다. D-6 (b)는 후보를 닫아 둔 채 캡션으로 안내하는 안이라 H-5의 동작을 **받아들이는** 선택이다. 그런데 REQ-001의 수용 목록(:142 "D-2 (c) for H-4, D-5 (c) for H-3, D-8 (a) for H-9")과 AC-001 (5)(:59-60)에는 D-6 (b)의 H-5가 없고, REQ-001은 "no other assertion shall be rewritten to match observed behavior"라고 닫는다. plan D-6 (b)(:114)의 "바뀌는 것"은 "AC-005 (1)이 캡션 신호로"뿐이고 `AB-H05`의 처리를 적지 않는다. 그래서 D-6 (b)를 고르면 `AB-H05`가 ✗로 남아 AC-012 (1)이 깨지거나, REQ-001이 금지한 방식으로 단언을 고쳐 써야 한다. — Severity: minor — Class: blocking(**게이트 선택지 결함** — 권장안 D-6 (a)에서는 발동하지 않음) — Required fix: REQ-001의 괄호 목록과 AC-001 (5)의 목록에 "D-6 (b) for H-5"를 더하고, plan D-6 (b)의 "바뀌는 것"에 "`AB-H05 [수용]`(후보 줄 `startsOpen == false`) + AC-005 (1) 캡션 신호"를 적는다. (선택) D-3 (c)의 "경로 제거"와 D-7 (c)의 되돌림처럼 수용이 아닌 결정 때문에 단언을 고쳐 쓰는 경우를 REQ-001에 한 문장으로 일반화하면 D-7 (c)(§E.2 기록 형식이 정해져 있지 않음)도 함께 정리된다.

D4. REQ-013-path-set-omits-re-delegated-005/007-bodies — spec.md:L174 vs L178, acceptance.md:L199-200 · L243-245 — REQ-013은 "The change shall not modify repository paths outside its declared set"이고, sync 목록은 `CHECKLIST.md` · 루트 `plan.md` · 이 SPEC 디렉터리 · `Tools/GuardDriver.swift` 좌표 주석 · SPEC-UIKIT-005/007의 `progress.md`뿐이다. 그런데 REQ-015(:178)는 완료된 SPEC-UIKIT-005/007 문서의 인용 재사상을 요구하고 그 본문 편집을 manager-spec 재위임으로 한다고 정하며, AC-013 (5)(:243-245)는 SPEC-UIKIT-005 `acceptance.md`의 AC-005 Given과 AC-009 7·9번에 `c5396b3` 표기를 **붙이라고** 요구한다. 그 편집은 REQ-013 목록 밖의 경로를 바꾼다. AC-011 (1)(:199-200)은 "재위임으로 들어온 SPEC-UIKIT-005/007 본문(sync, 커밋 주체를 §E.4에)"을 허용하므로 검증 층이 요구사항 층보다 넓다. 1회차 D7 수리(base 고정 표기)가 이 편집을 필수로 만들면서 충돌이 실제로 발동하게 됐다(1회차 감사가 놓친 자리이기도 하다). — Severity: minor — Class: blocking(내부 일관성 — 문언대로 읽는 판정자는 REQ-013 또는 AC-013 (5) 가운데 하나를 실패로 낸다) — Required fix: REQ-013의 sync 목록에 "and, through `manager-spec` re-delegation, the citation lines of the SPEC-UIKIT-005 and SPEC-UIKIT-007 `spec.md`·`plan.md`·`acceptance.md` that REQ-015 names"를 넣는다. 근거 끝 문장("sync 레인이 직접 고치지 않는다")은 그대로 두면 된다 — 편집 주체와 경로 허용은 별개다.

D5. AC-005(2)-D-3(c)-branch-not-mirrored — plan.md:L86, acceptance.md:L117-118 · L43 — plan D-3 (c)는 "AC-005 (2)의 후보 카드 맥락 줄은 `create_schedule`만 본다"고 적지만, AC-005 (2)는 세 도구 모두의 후보 카드(`drvPark`)를 요구하고 (D-3 (c)) 표지가 없다. acceptance.md:43은 "결정이 기대값을 바꾸는 절에는 결정 번호를 붙였다"고 스스로 밝힌다. — Severity: minor — Class: optional(plan §2가 선택지 효과의 단일 출처이고 게이트 뒤 개정에서 절을 확정하므로 실제 판정 오류로 이어지지는 않는다) — Required fix: AC-005 (2) 끝에 "**(D-3 (c))** 후보 카드 쪽은 `create_schedule`만 본다"를 붙인다.

D6. D-10(a)-particle-rule-overstated — plan.md:L144 · L151-152, spec.md:L160 — D-10 (a)는 "따옴표로 감싼 이름 바로 뒤에 조사를 붙이지 않는다(REQ-008)"를 일반 원칙처럼 적는데, 같은 표의 채택 원문 셋이 그 문장을 어긴다: `'장소 검색'을 누르면`(:151) · `'Y'에서 출발하는지`(:152) · `'가는 편 없음'을 고르면`(:152). REQ-008 본문은 이 규칙을 같은 이름 줄 캡션에만 걸므로 요구사항 위반은 아니다. 또 `에서`는 받침에 따라 모양이 바뀌지 않고, 나머지 둘은 고정 문구라 받침 오류의 위험이 없다. — Severity: minor — Class: optional — Required fix: D-10 (a)의 문장을 "같은 이름 줄 캡션(REQ-008)에서는, 그리고 값이 들어가는 자리에서는 받침에 따라 모양이 바뀌는 조사(이/가·을/를·은/는·와/과·으로/로)를 따옴표 바로 뒤에 붙이지 않는다"로 좁힌다.

D7. REQ-015-rationale-wording — spec.md:L178, acceptance.md:L245 · L303-309 — 근거가 "이 SPEC의 acceptance.md가 AC-009 7·8번 단계를 현재 좌표로 다시 적으므로"라고 쓰는데, 고정 대상은 SPEC-UIKIT-005 AC-009의 **7·9번**이고(대응하는 이 SPEC의 단계는 스크립트 7·8번), 스크립트 7·8번(:303-309)에는 좌표가 하나도 없다. 실질(운영자가 005의 옛 좌표에 기대지 않는다)은 성립한다. — Severity: minor — Class: optional — Required fix: "이 SPEC의 스크립트 7·8번이 SPEC-UIKIT-005 AC-009 7·9번 단계를 현재 트리 기준으로 다시 적으므로"로 고친다(AC-013 (5)도 같게).

D8. rewritten-target-rows-leave-citing-prose-stale — plan.md(루트):L562, CHECKLIST.md:L533-535, SPEC-UIKIT-005 spec.md:L237-238, spec.md:L178, acceptance.md:L238-240 — "대상 제거·재작성" 행은 새 원문과 바꾼 REQ를 기록하고 바이트 대조에서 빠진다. 그런데 인용하는 문장 자체가 고쳐 쓰일 주석의 내용을 옮겨 적은 경우가 있다: 루트 `plan.md:562` "(`AIAssistant.swift:1654` 주석 — create_schedule 전용)", SPEC-UIKIT-005 `spec.md:237` "가드는 `create_schedule` 경로 전용이다 … `create_recurring_schedule`·`create_activity`에 없다". REQ-010이 주석을 고치면 이 문장들은 글자 그대로는 거짓이 된다(결론 — 수정 경로에는 가드가 없다 — 은 여전히 참이다). 규칙은 인용 토큰만 다루고 옮겨 적은 문장의 처리를 정하지 않는다. — Severity: minor — Class: optional — Required fix: AC-013 (2)의 "대상 제거·재작성" 정의에 "살아 있는 문서(루트 `plan.md`·`CHECKLIST.md`)에서는 인용 문장이 옛 내용을 옮겨 적었으면 그 문장도 새 원문에 맞춘다. 완료된 SPEC 본문에서는 문장을 두고 원장에만 기록한다"를 한 줄 더한다.

D9. SPEC-dir-run-restriction-unverified — spec.md:L174, acceptance.md:L197 — REQ-013은 run 단계에서 이 SPEC 디렉터리의 변경을 `progress.md` §E.2·§E.3과 `spec.md` frontmatter `status`·`updated`로 제한하지만, AC-011 (1)은 `':!.moai/specs/SPEC-UIKIT-008'`로 디렉터리 전체를 뺀다. run이 `spec.md` 본문이나 `acceptance.md`를 고쳐도 어떤 AC도 잡지 않는다. manager-develop의 소유권 규칙이 같은 것을 막으므로 실제 위험은 작다. — Severity: minor — Class: optional — Required fix: 게이트 뒤 개정이 끝난 plan 커밋 SHA를 기준으로 `git diff --name-only <plan 최종 SHA> <run 최종 커밋> -- .moai/specs/SPEC-UIKIT-008/`가 `progress.md`·`spec.md`만 내고 `spec.md` 헝크가 frontmatter 두 줄뿐임을 보는 절을 AC-011에 더한다.

D10. AC-010(3)-mixed-line-underinclusive — acceptance.md:L187 — `grep -v 'Theme\.'`가 줄 단위로 걸러내므로, 한 줄에 Theme 토큰과 직접 색이 함께 있으면(`+ .foregroundStyle(Theme.muted).background(.white)`) 통째로 빠진다. 이 트리에서 그 줄을 넣어 돌리면 **0**이 나왔다. 양성 대조 한 줄(`.gray`)은 1을 낸다. — Severity: minor — Class: optional — Required fix: `grep -v 'Theme\.'`를 빼고, 정규식에 걸린 토큰이 `Theme\.` 바로 뒤에 오지 않는지로 판정하거나(`grep -oE` 후 걸러내기), 한 줄에 둘이 섞인 경우를 사람 대조 항목으로 둔다.

D11. REQ-010-comment-clause-style — spec.md:L164 — Event-driven 복합문 끝에 "and no source comment shall state that the `isSamePlace` guard is exclusive to `create_schedule`"라는 조건 없는 금지 절이 붙어 있다. 린트는 통과하고 AC-008 (6)이 검증한다. — Severity: minor — Class: optional — Required fix: 필요하면 게이트 뒤 개정에서 이 절을 REQ-013의 금지 목록이나 별도 Unwanted 문장으로 옮긴다. 조치하지 않아도 판정에는 영향이 없다.

D12. frontmatter-nonschema-fields (1회차 D18 이월) — spec.md:L11 · L15-16 — `related_specs`·`kanban_card`는 스키마의 선택 필드 목록 밖이고 `module: "shared-ui"`는 실제 경로가 아니다. SPEC-UIKIT-005·007과 같은 관례로 유지했다(HISTORY 0.1.1). — Severity: minor — Class: optional — Required fix: 관례로 유지한다면 조치 없음.

(FAIL 판정 시 이 목록이 수리 경로다. 3회차 감사는 D1의 해소(표식 → 채택 사실)와 D2~D4의 차분, 그리고 게이트 결과로 확정된 REQ·AC 절의 회귀만 본다. 판정 권한은 감사자에게 있다.)

## Regression Check (Iteration 2+ only)

1회차 결함 22건:

- 1회차 D1 MP-7 게이트 표식 — **UNRESOLVED(설계상)**: 10건 그대로(plan.md :55~:142), `progress.md:8` pending. 리드 몫이며 manager-spec의 진척 부족이 아니다 — 정체(stagnation) 표식을 달지 않는다.
- 1회차 D2 REQ-008 범위 — **RESOLVED**: spec.md:160 "When one `create_schedule` or `create_activity` call …" + 끝 문장 "The same value in `origin_query` and `destination_query` of `create_recurring_schedule` is the staying-recurrence signal of REQ-010 and is excluded". AC-006 (5)(acceptance.md:138-139) 신설. 코드 대조: 반복 분기 `AIAssistant.swift:517-530`에 같은 이름 줄이 없고 `:525`에서 `stayingRecurrence`로 수단·여유·알림을 억제한다.
- 1회차 D3 REQ-010 발동 층 — **RESOLVED**: spec.md:164가 "When … carry the same value, the card shall not ask …; when … resolve to places within 50 m …, the executor shall …"로 갈렸고, 이름 다름·좌표 같음의 경우를 잔여 위험으로 적었다. 코드 주석 `:716-719`와 같은 결론이다.
- 1회차 D4 단언 극성 — **RESOLVED(목록에 든 선택지에 대해)**: spec.md:142 극성 규칙, AC-001 (5)(:59-60), AC-008 (5)(:162-164), AC-012 (1)(:219-220)이 함께 선다. 모의 실행 `grep -c '✓ AB-H[0-9][0-9] \[수용\]'` → 1. 목록 밖의 D-6 (b)가 같은 모양을 가진다 — 이번 회차 D3.
- 1회차 D5 D-7 (b) 거짓 전제 — **RESOLVED**: plan.md:122-124가 (b)를 거두고 `statedArguments`(`AIAssistant.swift:338-344`)를 인용한다. 이 트리에서 `:338-344`는 `mode_this_time`·`buffer_minutes`·`notify_lead_minutes` 셋만 읽는다(확인). 잔재 검색: `D-7 (b)`는 HISTORY·progress의 기록에만 있다.
- 1회차 D6 `AB-H1`/`AB-H10` 충돌 — **RESOLVED**: acceptance.md:12-15 두 자리 이름. 모의 입력(`✓ AB-H01 a` / `✓ AB-H10 b`)에서 `grep -c '✓ AB-H01'` → 1.
- 1회차 D7 SPEC-UIKIT-005 재사상·isSamePlace 확대 — **RESOLVED**: REQ-015(:178)에 "대상 제거·재작성" 범주와 base 고정 규칙, AC-013 (2)(5)(:238-245). SPEC-UIKIT-005 `acceptance.md:135-138`(AC-005 Given의 여섯 좌표)과 `:251`·`:259`(AC-009 7·9번 — "지금은 … 거절한다", "가드가 없으므로")가 수리 전 상태 서술임을 확인해 base 고정 분류가 맞다. §1.4(:112)·§3(:196-199)·REQ-010 주석 절·AC-008 (6) 추가. 새로 드러난 충돌은 이번 회차 D4, 옮겨 적은 문장 문제는 D8.
- 1회차 D8 AC-011 (1) 기준점·렌즈 보고서 — **RESOLVED**: 렌즈 보고서 둘이 plan 커밋 `2313e38`에 추적된다(`git ls-files`). AC-011 (1) 명령을 HEAD에서 돌리면 0줄, 예외를 빼고 돌리면 7줄(렌즈 둘 · 감사 보고서 · SPEC 네 파일) — 예외가 정확히 plan 경로만 걸러낸다. 이 보고서 이름(`SPEC-UIKIT-008-review-2.md`)도 글롭에 걸린다.
- 1회차 D9 GuardDriver 계수 — **RESOLVED**: REQ-015·AC-013 (1)에 명령과 계수. 재측정: `CHECKLIST.md` 1(`:619`), 나머지 0. `setenv("CFFIXED_USER_HOME"`은 base `:264` · head `:275`.
- 1회차 D10 D-5 (a) 폴백 — **RESOLVED**: plan.md:102-103, AC-004 (2)(:106).
- 1회차 D11 효과 목록 — **RESOLVED**: D-1 (c)는 plan.md:62-64와 acceptance.md:180·:254·스크립트 2번(:285)이 같다. D-3 (c)는 AC-003(:90-91)·스크립트 3·4번(:288·:292), D-5 (c)는 AC-004 (2)(:107)·스크립트 1번(:281). 남은 옮김 누락은 이번 회차 D5(선택).
- 1회차 D12 D-10 문자열 — **RESOLVED(D-10 (a)에 대해)**: plan.md:147-154 원문 표, AC-005 (5)·AC-006 (4)·AC-007 (2)·AC-008 (2)·AC-010 (3) 신호. 후보 트리 기준값을 다시 셌다 — `첫 검색 결과가 말씀하신` 1 · `가 여러 줄에 같은 이름으로 왔어요` 1 · `미리 정해진 출발지가 맞는지` 1 · `에서 출발하는지 한 번 더 골라 주세요` 0 · `이동 없이 한 곳에서` 0 · `검색 결과가 말씀하신 지점인지 확실하지 않아요` 0 · EditCardView `새로 고르지 않으면 그대로예요` 0 — SPEC이 적은 값과 모두 같다. D-10 (b) 쪽의 결함은 이번 회차 D2.
- 1회차 D13 통과 수 — **RESOLVED**: REQ-014(:176), AC-012 (1)(:219-220), plan §5(:223).
- 1회차 D14 제목·대응표 — **RESOLVED**: acceptance.md:77 "열 조합", :37 "REQ-002·003·005~011", plan.md:19-20 "011→009·014".
- 1회차 D15 REQ 밖 하위 조건 — **RESOLVED**: REQ-012(:170)에 `chip()` 무변경, AC-011 (6)(:209-210) 튜플 반복은 "권고(통과 조건 아님)".
- 1회차 D16 REQ-011 — **RESOLVED**: spec.md:166 "While the most recent recurrence … (`lastRecurrenceId`) is a staying group, when … shall state that the group has no travel legs to change".
- 1회차 D17 GEARS 문체 — **RESOLVED**: REQ-006(:154) Where 절, REQ-014(:176) When 절.
- 1회차 D18 비스키마 필드 — **유지(관례)**: 이번 회차 D12로 이월, 선택.
- 1회차 D19 색 검사 — **RESOLVED**: AC-010 (3)(:187-188) 정규식 확대와 양성 대조. 모의 실행 `.gray` → 1, Theme 줄 → 0. 남은 한계는 이번 회차 D10(선택).
- 1회차 D20 죽은 경로 서술 — **RESOLVED**: REQ-013(:174). base `resolveOrigin(` 호출 `:1323`·`:1486`·`:1612`(기본값)·`:2162`(`true`), head는 `:2380`(`true`)뿐, `resolveOriginAdoption` 호출 `:1459`·`:1648`·`:1786` — 서술과 일치.
- 1회차 D21 서로 다른 후보 선택 — **RESOLVED**: plan.md:193-194 잔여 위험, AC-003(:92) 대상 밖 명시.
- 1회차 D22 경고 줄 수 — **RESOLVED**: REQ-014·AC-012 (2) "24줄 — 진단 12 + 캐럿 문맥 12". `.moai/state/verify/t16-plan/compile-head.log`·`compile-base.log` 모두 `grep -c 'warning:'` 24, `^/`로 시작하는 줄 12, 나머지 12는 `` `- warning: … `` 캐럿 줄이다.

## 착수 게이트 결정 점검 (D-1~D-10, 요청 항목)

| 결정 | 판정 | 근거 |
|---|---|---|
| D-1 U-2 범위 | 성립 | (a)(b)(c) 모두 구현 가능. (c)의 처리가 plan·acceptance에서 하나로 맞춰졌다(1회차 D11) |
| D-2 판정 술어 | 성립 | (c)는 극성 규칙으로 `AB-H04 [수용]` 경로가 생겼다. `drvTopMatches("강남"`은 이 트리에서 `:1835` 한 줄, 주소 인자 없음 — SPEC 서술과 같다 |
| D-3 주입 수리 | 성립 · 경미 | (c)는 "경로 제거"로 기록하며 REQ-001과 충돌하지 않는다(새 단언은 후보 관측 동작이 아니다). AC-005 (2) 옮김 누락은 D5(선택) |
| D-4 다중 호출 | 성립 | 1회차와 같음 |
| D-5 보류 뒤 루프 | 성립(전제 미확인) | (a)의 전제는 이 트리에서 **거짓으로 드러나지 않는다.** 프록시 변환부 `proxy/src/index.js:176-209`는 역할 순서를 검사하지 않고 `function_call_output` 뒤에 사용자 메시지를 그대로 잇는다. 다만 기존 되묻기 카드는 모델 턴을 히스토리에 넣기 전에 돌아오므로(`AIAssistant.swift:425-431`) "도구 결과 → 사용자" 순서를 이미 쓰는 경로가 없고, 백엔드 수용은 미관측이다. 깨질 때의 경로가 적혀 있다(plan.md:102-103) |
| D-6 후보 노출 | **(b) 결함** | (a) 성립. (b)는 H-5의 수용인데 REQ-001 수용 목록·AC-001 (5)에 없다(D3). D-10 (b)와 함께 고르면 캡션이 거짓이 된다(D2) |
| D-7 왕복 재확인 | 성립 | (b)를 전제가 거짓이라는 근거와 함께 거뒀다. (a)(c) 성립. 단 (a)를 D-10 (b)와 함께 고르면 REQ-009가 충족 불가능하다(D2 — 결함의 자리는 D-10 (b) 쪽) |
| D-8 머무는 반복 | 성립 | 권장안 (a)가 극성 규칙으로 AC-012 (1)의 ✗ 0과 함께 선다. 재현되지 않을 때의 처리도 적혀 있다(plan.md:131) |
| D-9 적용 범위 | 성립 | 1회차와 같음 |
| D-10 문안 | **(b) 결함** | (a) 성립 — 원문이 SPEC 안에 있고 신호가 기계로 판정되며 기준값이 맞다(원칙 문장의 과장은 D6, 선택). (b)는 D-7 (a)·D-6 (b)와 양립하지 않는다(D2) |
| (누락) | — | 게이트가 다뤄야 하는데 빠진 결정은 없다. D4(REQ-013 경로 목록)는 결정이 아니라 작성 수리다 |

## Recommendation

FAIL. 필수 통과 실패는 MP-7(게이트 표식)뿐이고, 그 밖에 차단 결함 셋(D2~D4)이 남았다. 셋 다 작고, 권장안 경로에서 발동하는 것은 D4 하나다.

**manager-spec(게이트 전에 권함 — D2·D3은 선택지 문장이라 운영자가 고르기 전에 고쳐야 한다):**
1. plan.md:156-158 D-10 (b)에 D-7 (a)·D-6 (b)와의 관계를 적거나 (b)를 D-6 (a)·D-7 (c)와의 조합으로 한정하고, AC-005 (5)·AC-007 (2)에 (D-10 (b)) 분기를 plan과 같게 넣는다(D2).
2. spec.md:142 REQ-001 수용 목록과 acceptance.md:59-60 AC-001 (5)에 "D-6 (b)의 H-5"를 더하고, plan.md:114 D-6 (b)의 "바뀌는 것"에 `AB-H05 [수용]`을 적는다(D3).
3. spec.md:174 REQ-013 sync 목록에 manager-spec 재위임으로 들어오는 SPEC-UIKIT-005/007 본문 인용 줄을 넣는다(D4). 게이트 결과와 같은 개정에 넣어도 된다.
4. 선택 결함(D5~D12)은 오케스트레이터 재량이다. 싸게 고칠 수 있는 것은 D5(표지 한 줄)·D7(근거 문구)·D8(정의 한 줄)이다. 이 목록만으로 FAIL을 만들지 않았다.

**리드:**
1. 위 1·2가 반영된 뒤 D-1~D-10과 Tier M을 `AskUserQuestion`으로 정한다(D1). 1·2가 반영되지 않은 채 게이트를 연다면, 최소한 D-10 (b)와 D-6 (b)를 고를 때의 제약을 선택지 설명에 적어 둔다.
2. 결정 결과를 manager-spec에 넘겨 표식을 채택 사실로 바꾸고 결정 번호가 붙은 절을 확정하게 한다.

**3회차(마지막):** 표식 제거와 D2~D4의 차분, 게이트 결과로 확정된 REQ·AC 절의 회귀만 본다. 3회 상한이므로 3회차가 FAIL이면 PASS-with-debt · 범위 축소 · 사용자 명시 연장 가운데 하나를 리드가 운영자에게 묻는다.

## 검증 증거 (이 감사가 `2313e38` 트리에서 직접 실행)

| 대상 | 명령 | 관측 |
|---|---|---|
| 트리 | `git rev-parse --short HEAD` · `git branch --show-current` · `git log --oneline aa7b792..HEAD` | `2313e38` · `WT-place-resolution` · `2313e38 docs(t16): … plan 0.1.1` / `e1a40a6 wip(t16) …` |
| 추적 | `git ls-files .moai/specs/SPEC-UIKIT-008/ .moai/reports/t16/ .moai/reports/plan-audit/SPEC-UIKIT-008*` · `git show --stat 2313e38` | 네 SPEC 파일 · 렌즈 둘 · `t16/progress.md` · 1회차 보고서 / plan 커밋 7파일 +1615 |
| REQ·AC | `grep -n '^- \*\*REQ-'` · `grep -n '^## AC-'` | 15(:142~:178) · 15(:47~:252) |
| MP-7 | `grep -rn '\[NEEDS CLARIFICATION' .moai/specs/SPEC-UIKIT-008/` | plan.md :55·:67·:76·:90·:97·:110·:116·:126·:135·:142 |
| D7 | 검증 명령(참조 SPEC 추출 → `grep -m1 '^status:'`) | 003·005·007 completed · ASK-001 draft · 008 draft, 미발견 0 |
| D8 | `grep -c 'syscall'` 네 파일 | 0·0·0·0 |
| 린트 | `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` | `✓ No findings — all SPEC documents are valid` |
| 주석·호출 | `grep -n 'isSamePlace(origin, dest)\|가드는 create_schedule 경로 전용' Shared/AIAssistant.swift` | `:1492` · `:1812` · `:1869` |
| D-7 (b) 전제 | `awk 'NR>=336 && NR<=346'` | `statedArguments`가 mode·buffer·notify 셋만 채운다 |
| 반복 카드 | `awk 'NR>=515 && NR<=532'` | `:520` unknownPlace만 · `:521-522` 출발지 · `:525` `stayingRecurrence` 억제 · `:530` weeks — 같은 이름 줄 없음 |
| 왕복 캡션 | `awk 'NR>=549 && NR<=563'` | `:560` 고정 문장 "미리 정해진 출발지가 맞는지 …" — 값 없음 (D2) |
| 후보·같은 이름 캡션 | `awk 'NR>=716 && NR<=740'` | `:730` `'\(query)'가 여러 줄에 …` · `:735` `… 아래 후보에서 골라 주세요.` (D2) |
| 기준선 신호 | `grep -c` 10종(AIAssistant) + EditCard·EditCardView 각 1종 | 1·1·1·0·1·0·1·1·0·0 / EditCard 주석 1 / U-2 캡션 0 — SPEC 기재값과 일치 |
| resolveOrigin | `grep -n 'resolveOrigin(\|resolveOriginAdoption('` head · `git show aa7b792:… \| grep -n 'resolveOrigin('` | head `:1459`·`:1648`·`:1786`(Adoption) · `:2380`(true) / base `:1323`·`:1486`·`:1612`·`:2162` |
| D-5 (a) 전제 | `awk 'NR>=398 && NR<=440'` AIAssistant · `awk 'NR>=160 && NR<=215' proxy/src/index.js` | 되묻기 카드는 `:428-431`에서 모델 턴을 넣기 전에 반환 · 변환부 `:176-209`는 순서 검사 없이 평평한 배열 |
| 인용 계수 | `grep -o 'AIAssistant\(\.swift\)\{0,1\}:[0-9]\{1,4\}'` · 같은 명령 `GuardDriver` | CHECKLIST 14/1 · plan 4/0 · 005 spec 6/0 · plan 1/0 · acceptance 0/0 · progress 3/0 · 007 spec 1/0 · plan 0/0 · progress 0/0 (007 acceptance 없음) |
| GuardDriver 좌표 | `grep -n 'setenv("CFFIXED_USER_HOME"'` head · base | `:275` · `:264` |
| `:1654` 인용 | `grep -n '1654' plan.md CHECKLIST.md` · `git show aa7b792:… \| sed -n '1652,1655p'` | 루트 `plan.md:562` · `CHECKLIST.md:535` / base `:1654` = "(`isSamePlace` 가드는 create_schedule 경로 전용)" |
| 005 좌표 | `grep -n ':748\|:1297\|:1613\|:2322\|:2371\|:2393' SPEC-UIKIT-005/acceptance.md` · `sed -n '245,262p'` | `:135-138` Given · `:251` 7번("지금은 … 거절") · `:259` 9번("가드가 없으므로") |
| 005 §3 | `sed -n '234,242p' SPEC-UIKIT-005/spec.md` | `:237` "가드는 `create_schedule` 경로 전용이다" · `:238` "넓히지 않는다" |
| AC-011 (1) | 예외 명령 그대로 · 예외 없이 | 0줄(exit 0) · 7줄 |
| AC-010 (3) | 정규식에 `.gray` 한 줄 · Theme 줄·`.grayscale` · 섞인 한 줄 | 1 · 0 · 0 (D10) |
| 이름 규칙 | 모의 로그에 `grep -c '✓ AB-H01'` · `grep -c '✓ AB-H[0-9][0-9] \[수용\]'` | 1 · 1 |
| 드라이버 라벨 | `grep -o '"AA-[0-9]\{1,2\}…' Tools/GuardDriver.swift` · `awk 'NR>=28 && NR<=34'` | AA-1~AA-8만 있다(`AA-1` 패턴 충돌 없음) · `:31` `✓ \(label)` |
| 경고 로그 | `grep -c 'warning:'` · `grep 'warning:' \| grep -c '^/'` on `compile-{base,head}.log` | 24/24 · 12/12, 나머지는 `` `- warning: `` 캐럿 줄 |
| 교차 모델 | `mcp__moai__audit_multi`(gates claude required · codex off · glm advisory) | claude fail · glm inconclusive(fail-open) · 종합 fail · 이견 없음 |

## Gaps (미검증)

- 드라이버·`xcodebuild`·`npm test`는 **실행하지 않았다.** 경고 로그는 `.moai/state/verify/t16-plan/`의 오케스트레이터 산출물을 읽은 것이다.
- 렌즈 보고서 두 파일은 이번에도 읽지 않았다. SPEC이 인용한 렌즈 절 번호가 그 내용을 담는지는 대조하지 않았다.
- SPEC-UIKIT-005 `spec.md`의 파일명 토큰 6건이 §1(`c5396b3` 고정)과 §3(살아 있는 인용) 가운데 어디에 속하는지 건별로 분류하지 않았다. sync 원장의 몫이다.
- 맨몸 `:N` 인용의 전수 계수는 하지 않았다(REQ-015가 sync에 맡긴 일).
- D-5 (a)의 백엔드 수용, 카카오 실제 응답, 모델 행동은 관측하지 않았다.
- 루트 `plan.md:230-233`의 토큰 측정법과 `day-close-20260924.md` 인용은 이번 회차에 다시 대조하지 않았다(1회차에 대조, 이번 개정이 바꾸지 않음).
- `mcp__moai__spec_audit`는 주 체크아웃을 읽으므로 쓰지 않았다(오케스트레이터 지시). 린트는 워크트리 CLI로 대신했다.
- glm 보조 감사는 응답 내용이 없어 결론을 내지 못했다(fail-open).

## Residual-risk (잔여 위험)

- MP-7은 게이트가 열리기 전까지 모든 plan 감사에서 FAIL을 낸다. 3회 상한 안에 PASS를 받으려면 게이트 결과를 반영한 개정이 3회차 전에 들어와야 한다.
- 극성 규칙은 run의 기록 규율에 기댄다. M1의 ✗ 줄을 §E.2에 적지 않고 `[수용]`으로 바로 쓰면 재현 증거가 사라지지만, AC-001 (5)가 §E.2의 ✗ 줄을 요구하므로 판정 단계에서는 잡힌다.
- 인용 원장 방식은 t15에서 두 감사가 모두 0을 보고했던 실패를 겪었다. 범주·계수는 보강됐지만 맨몸 `:N`의 행 기본 파일 해석과 "대상 제거·재작성" 행의 문장 처리(D8)는 sync 때 처음 실측된다.
- 이름은 다르고 좌표만 같은 머무는 반복('집'/'우리집')에서 카드가 수단을 묻고 실행부는 구간을 만들지 않는 차이는 SPEC이 받아들인 잔여 위험이다(spec.md:164, 코드 주석 `:716-719`).

🗿 MoAI
