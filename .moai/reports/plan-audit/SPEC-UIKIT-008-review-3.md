# SPEC Review Report: SPEC-UIKIT-008
Iteration: 3/3
Verdict: PASS
Overall Score: 0.89

감사 대상 트리: `.claude/worktrees/t16` (branch `WT-place-resolution`, HEAD `47c40f5` = 0.1.5 커밋). Tier M이므로 `spec.md`(249줄) · `plan.md`(242줄) · `acceptance.md`(377줄)를 모두 읽었고 `progress.md`(224줄)는 대조용으로 읽었다. `research.md`는 없다. 코드는 후보 커밋과 같다 — `git diff --quiet e1a40a6 -- Shared Tools proxy project.yml` → exit 0.

M1 맥락 격리: 작성자의 추론 맥락은 받지 않았다. 호출자가 준 것은 점검 범위와 커밋 정보뿐이며, "운영자가 결정했다"는 서술은 증거로 쓰지 않았다(리드 전달이라 이 트리에서 확인할 수 없다 — § Gaps).

**기준 커밋 바로잡기.** 호출자는 2회차 대상을 0.1.2(`d0a2c60`)로 적었지만, 2회차 보고서 머리말과 `progress.md:211`에 따르면 2회차가 감사한 것은 0.1.1(`2313e38`)이고 `d0a2c60`은 2회차 결함을 고친 개정이다. 그래서 D2~D4의 해소는 `2313e38` 이후의 변화(0.1.2 수리 + 0.1.3 게이트 채택)로 판정했고, 새 차분은 요청대로 `d0a2c60..HEAD`(0.1.3 · 0.1.4 · 0.1.5)를 중심으로 보았다.

교차 모델: 주 체크아웃 `workflow.yaml:77-82` — `audit.model: multi`, claude required · codex off · glm advisory. `mcp__moai__audit_multi` → claude `pass`, glm `inconclusive`("z.ai response carried no content", fail-open). 종합 `pass`, 이견 없음.

## 결론 먼저

- **남은 차단 결함은 없다.** must-pass 일곱 개가 모두 PASS 또는 N/A이고, 2회차의 차단 결함 D1(게이트 표식)·D2·D3·D4가 모두 해소됐다.
- 새 차분 — 게이트 표식을 채택 사실로 바꾼 것, 운영자 문구 D-8을 REQ-010 "머무는 요청"으로 옮긴 것, B-1·B-2를 후속 카드 t30으로 넘긴 것 — 은 요구사항끼리, 요구사항과 AC 사이, AC와 시뮬레이터 스크립트 사이에서 서로 맞는다. 결정 조건이 붙은 분기는 HISTORY 행에만 남고 REQ·AC에는 하나도 없다.
- 이번 회차 결함 10건은 모두 **선택(optional)**이다. 넷(D1~D4)은 run 착수 전에 싸게 고칠 수 있고, 나머지는 기록된 부채로 넘겨도 판정에 영향이 없다.
- 점수는 0.89로 2회차와 같다. Tier M 통과선 0.80을 넘고, 하락이 아니므로 STOP 신호는 없다.

## Must-Pass Results

- [PASS] **MP-1 REQ 번호 일관성** — `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:147)부터 REQ-015(:183)까지 15건, 빈 번호·중복 없음, 세 자리 채움 일관. `grep -c` = 15. AC도 `grep -c '^## AC-' acceptance.md` = 15(:48~:265)로 Tier M 상한 16 아래다.
- [PASS] **MP-2 GEARS 형식 (요구사항 층 `REQ-XXX` 기준으로 판정)** — 15건 모두 `shall` 구조의 Ubiquitous · Event-driven · State-driven · Unwanted 패턴 또는 그 복합형이다. 새로 쓴 REQ-010(:169)은 "When a creation call is a staying request — … — the card shall …; when …, the executor shall …; … shall never be confirmed …; … and no source comment shall state …"의 Event-driven + Unwanted 복합문이고, REQ-001(:147)은 Ubiquitous + Event-driven이다. 0.1.1의 "Where D-6 (a) is chosen" 같은 결정 조건절은 모두 사라졌다. `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` → `✓ No findings — all SPEC documents are valid`. AC는 검증 층이므로 Given-When-Then 여부를 여기서 채점하지 않았다(Group 4에서 따로 봄). REQ-010의 원자성은 선택 결함 D7로 두었다.
- [PASS] **MP-3 YAML 프런트매터** — spec.md:1-17. 필수 12필드: `id: SPEC-UIKIT-008` · `title` 따옴표 · `version: "0.1.5"` · `status: draft` · `created`/`updated: "2026-09-26"` · `author: "manager-spec"` · `priority: P1` · `phase: "Phase 1.7 — 일정·활동 화면 UI 통일"`(단계명 금지값 아님) · `module: "shared-ui"` · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부되는 별칭 없음. `tier: M`은 선택 필드다. `related_specs`·`kanban_card`는 관례로 유지(선택 결함 D10).
- [N/A] **MP-4 언어 중립성** — 단일 언어(Swift) 앱 SPEC이다. 다언어 도구 서술이 없다.
- [PASS] **MP-5 D7 교차 SPEC** — 세 파일(spec·plan·acceptance)에서 참조를 뽑아 상태를 읽었다: SPEC-ASK-001 `draft` · SPEC-UIKIT-003 `completed` · SPEC-UIKIT-005 `completed` · SPEC-UIKIT-007 `completed` · SPEC-UIKIT-008(자기 자신) `draft`. retired·superseded·archived가 없고 찾지 못한 참조도 없다. BLOCKING 없음. 새로 생긴 외부 참조 t30은 SPEC이 아니라 칸반 카드이며, `moai todo`에 `t30 queued C21 AI 카드 문법 통일 — t16에서 이관된 운영자 결정 B-1·B-2 …`로 실재한다.
- [PASS] **MP-6 D8 교차 플랫폼** — `grep -c 'syscall'` → spec 0 · plan 0 · acceptance 0 · progress 0. 자동 통과.
- [PASS] **MP-7 명확화 게이트** — `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` → plan.md 일치 0건, research.md는 파일 없음(exit 2는 없는 파일 경고 때문이다). `progress.md:8` `kickoff_gate: resolved 2026-09-26`. progress.md의 `NEEDS CLARIFICATION` 문자열 셋(:47·:83·:216)은 대괄호 표식이 아니라 그 표식을 세던 명령의 기록이다. 2회차의 표식 10건(plan.md :55~:142)은 `plan.md` §2 채택 표(:57-69)로 바뀌었다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.85 | 0.75~1.0 사이 | 결정 분기가 걷혀 REQ마다 해석이 하나다 — REQ-002(:151) "name only", REQ-006(:159) "visible on first render", REQ-009(:167) 캡션·미선택. REQ-010(:169)은 머무는 요청의 두 모양을 인자로 정의해 판정이 기계적이다. 감점: 한 번짜리 활동에서 50 m 판정이 어디까지 걸리는지가 §3(:203)과 어긋나게 읽힐 수 있다(D1), T-1·B-3은 명시 답변 없이 채택됐다(D6), REQ-010이 한 문장에 여덟 절을 싣는다(D7) |
| Completeness | 0.90 | 0.75~1.0 사이 | HISTORY 0.1.0~0.1.5(:23-30) · 성격·예산 §0 · 배경 §1 · 요구사항 §2 · AC(acceptance.md) · Out of Scope H3 10개와 글머리표(:187-231) · 결정 해소 §4 · 프런트매터 12필드. t30 이관의 비용 근거가 코드 좌표와 함께 §3(:210-216)에 있고 좌표를 이 트리에서 확인했다. 감점: 이관 근거 한 줄이 같은 문서의 다른 근거와 어긋난다(D4) |
| Testability | 0.85 | 0.75~1.0 사이 | AC마다 기대값이 하나이고 절 수 선언("아홉이 동시에" 등)이 실제 항목 수와 모두 같다. 새 문자열 신호가 D-10 채택 원문과 부분 일치로 맞물린다(AC-005 (5)·AC-007 (2)·AC-008 (2)). 새 계약과 맞서는 기존 단언을 전수로 짚었다 — 드라이버의 `drvAsk("create_activity"`·`drvAsk("create_recurring_schedule"` 호출 11곳을 열어 보니 머무는 요청 판정에 걸리는 것은 AA-4 첫 단언(:1888-1890)과 O-6 첫 단언(:1595-1597) 둘뿐이고, SPEC이 적은 목록과 같다. 감점: O-6 교체로 한 조합의 회귀 방지선이 사라진다(D2), AC-008 (7) 끝 문장이 검사할 수 없는 포괄 주장이다(D3), 50 m 절의 한 갈래에 AC가 없다(D5), 2회차 D10 이월(D9) |
| Traceability | 0.95 | 0.75~1.0 사이 | `plan.md:19-20` 대응표와 `acceptance.md:22-38` 매트릭스가 15쌍 모두 일치한다. 새 동작이 모두 AC에 닿는다 — 끝 시각 선행 → AC-008 (7)·스크립트 15, 한 번짜리 머무는 요청 → AC-008 (5)·스크립트 3·16, "이동 없음" → AC-008 (2)(3)(5)·AC-003 5·10번, 다른 출발지 뒤 수단·여유·알림 → AC-008 (4)(5)·스크립트 14·16, REQ-008 제외 신호 → AC-006 (5). `plan.md` §2 "반영 자리" 열의 스크립트 번호(2·17~20, 3·12~16, 11 등)가 스크립트 본문과 맞는다. 감점: 2회차 D9 이월(run의 SPEC 디렉터리 제한을 보는 AC 없음 — D8) |

집계: 조화평균 4 / (1/0.85 + 1/0.90 + 1/0.85 + 1/0.95) = 4 / 4.5167 = **0.89**. Tier M 통과선 0.80을 넘는다. 2회차 0.89와 같아 점수 하락 STOP 신호는 없다.

## Defects Found (structured defect-list)

**차단 결함 없음.** 아래 10건은 모두 선택(optional)이다. D1~D4는 run 착수 전에 한 문단 이하로 고칠 수 있다.

D1. REQ-010-one-shot-50m-vs-§3-exclusion — spec.md:L169 · L203 — REQ-010은 "when the user's pick … resolves within 50 m of the destination or the activity place, the executor shall create the activity … and no travel legs"를 요구하고, §3은 `isSamePlace`를 "머무는 요청 카드에서 고른 출발지가 활동 장소와 같은지 보는 한 번짜리 활동 실행부"에만 쓰며 "편도·왕복 활동의 0분 구간을 막는 일반 가드로 넓히지 않는다"고 한다. 그런데 확인 뒤 실행부가 받는 인자는 `travel_from_query`에 고른 값이 들어간 평범한 편도 호출과 모양이 같아, 실행부에 50 m 검사를 넣는 가장 쉬운 구현은 곧 편도 활동 전반의 일반 가드가 된다. 반복 쪽은 이미 그렇게 일반적으로 걸려 있고(`:1812`, 잔여 위험 '집'/'우리집'), "반복도 단일과 같은 절차"라는 번역 규칙은 같은 일반화를 가리킨다. 어느 쪽이 의도인지 AC가 고정하지 않는다 — AC-008 (5)의 양성 대조에는 "이름은 다르고 좌표가 같은 편도 활동"이 없다. — Severity: minor — Class: optional(두 구현 모두 조용한 오등록을 만들지 않는다 — 물은 값이 쓰이지 않거나 0분 구간이 남을 뿐이다) — Required fix: 둘 중 하나를 고른다. (가) 확인 경로에서만 판정한다 — "후보가 머무는 요청 카드였고 고른 출발지가 50 m 안이면 확인 때 '이동 없음' 토큰으로 바꿔 싣는다"를 REQ-010 근거에 적고, AC-008 (5) 양성 대조에 "`travel_from_query` `우리집`(좌표는 `집`과 같음)·`place_query` `집` → 기존 편도 카드, 실행하면 가는 이동 1건"을 더한다. (나) 일반화를 받아들인다 — §3(:203)의 "편도 … 일반 가드로 넓히지 않는다"를 "거절 가드로 넓히지 않는다(50 m 안이면 이동 없이 활동만 만드는 것은 머무는 요청과 같은 처리)"로 고치고 잔여 위험에 한 줄 더한다.

D2. O-6-replacement-drops-unknown-place-coverage — acceptance.md:L164 · Tools/GuardDriver.swift:L1592-1597 — O-6 첫 단언의 입력은 즐겨찾기에 없는 `회사`를 장소로 둔 이동 없는 활동이고, 지키는 것은 "못 푸는 장소면 활동 장소 줄이 뜬다"(위치 없이 조용히 등록되던 자리, 주석 :1590-1591)다. AC-008 (5)는 이 단언을 빼고 즐겨찾기 `집`을 쓰는 `AB-H11`로 대신하라고 한다. 그러면 "머무는 한 번짜리 활동 + 못 푸는 장소" — 수리 뒤 카드에 장소 줄과 출발지 줄이 함께 서는, 새 계약에서 가장 복잡한 조합 — 의 단언이 하나도 남지 않는다. 못 푸는 장소 줄 자체는 O-6 둘째 단언(:1605, 왕복)이 덮지만 머무는 요청 맥락은 아니다. — Severity: minor — Class: optional — Required fix: AC-008 (5)의 "빼고 대신한다"를 "기대 키를 새 계약으로 고쳐 남긴다 — `Set(keys) == ["place_query", "travel_from_query"]`, 장소 줄의 캡션은 못 푸는 장소 문구, 출발지 줄에 `이동 없음`"으로 바꾸고, AC-012 (1)의 뺀 수·더한 수 기록을 그에 맞춘다.

D3. staying-end-time-overclaim — plan.md:L173 · acceptance.md:L171 — `plan.md:173`은 다른 출발지를 고른 뒤의 경로에 대해 "끝 시각은 출발지 카드보다 먼저 받으므로 이 경로에는 늘 있다"고 쓰고, AC-008 (7)은 "어느 경로로도 머무는 요청이 활동 없이 이동 구간만으로 등록되지 않는다"로 끝난다. 그러나 수단·여유·알림을 받는 두 번째 카드는 모델의 재호출에 기대고(I-1), 재호출 인자는 모델이 만든다. 통근 호출에서 `return_time`은 선택이라 모델이 빠뜨리면 실행부는 가는 구간만 만든다 — B-3(:108)이 스스로 "출발지를 실제 장소로 바꾼 반복 호출은 … 통근 호출과 인자로 구별되지 않는다"고 적은 바로 그 모양이다. REQ-010의 "staying request" 정의(같은 값)로 보면 재호출은 머무는 요청이 아니므로 요구사항 위반은 아니지만, "늘 있다"는 모델 행동에 대한 관측되지 않은 전제이고, AC-008 (7) 끝 문장은 드라이버가 판정할 수 없는 포괄 주장이다. — Severity: minor — Class: optional — Required fix: `plan.md:173`의 "늘 있다"를 "사용자가 답한 끝 시각을 모델이 재호출에 옮겨야 있다 — 빠뜨리면 가는 구간만 생기는 모양이 남는다(잔여 위험, 결과 문구에는 드러난다)"로 고치고, AC-008 (7) 끝 문장을 "위 두 경로(반복·한 번짜리)에서 레코드 0건"으로 좁히거나 지운다. 스크립트 14에 "등록 결과에 활동 블록 12건이 있는지 적는다"를 한 줄 더하면 사람 증거로 닫힌다.

D4. t30-rationale-declaration-conflict — spec.md:L221 vs L215 · progress.md:L128 · plan.md:L104 — §3의 끝 시각·오는 편 절(:221)은 "반복 선언에 오는 편 도착지 키가 없어 '같은 질문'을 두 도구에 걸려면 선언을 바꿔야 한다(REQ-013, AC-011 (4))"고 쓰지만, 바로 위 t30 절(:215)은 "선언 키는 어느 경로에도 늘지 않는다"고 하고, 0.1.5 비용 측정(`progress.md:128`)은 "카드가 묻는 키는 선언하지 않는 것이 설계다(드라이버 (e) `Tools/GuardDriver.swift:763-769`)"라고 근거를 댄다 — 이 트리에서 (e)는 `weeks` 등 카드가 묻는 키가 선언에 없음을 단언한다. 카드 전용 키로 오는 편 도착지를 받는 길이 있으므로 :221의 "선언을 바꿔야 한다"는 뒤의 측정과 맞지 않는다. REQ·AC에는 영향이 없고(범위 밖 결정은 운영자 결정으로 선다), t30이 이 근거를 물려받는다는 점에서만 문제다. — Severity: minor — Class: optional — Required fix: :221(과 `plan.md:104`의 (가))을 "오는 편 도착지를 두 도구에서 묻는 줄은 카드 전용 키와 실행부 경로가 새로 필요해 이 카드의 크기를 넘는다 — 경계 B-1, t30으로 이관"으로 고친다.

D5. REQ-010-50m-different-name-pick-untested — spec.md:L169 · acceptance.md:L158-159 · Shared/AIAssistant.swift:L1624 · L1767 — REQ-010의 "resolves within 50 m" 갈래 가운데 AC가 보는 것은 문자열이 목적지와 같은 선택(`집`)뿐이다(AC-008 (3)(5)). 운영자 문구가 가리키는 장면 — 집에 있는 사용자가 "현재 위치"를 고르는 경우 — 처럼 이름은 다르고 좌표가 50 m 안인 선택은 어떤 AC에도 없다. 그리고 두 실행부 모두 `missingAskedArguments`(한 번짜리 :1624, 반복 :1767)가 장소 해석·`isSamePlace`(:1812)보다 **먼저** 돈다. 문자열이 다르면 카드 판정이 머무는 요청으로 보지 않아 수단·여유·알림을 요구하며 멈출 가능성이 높다 — 결과는 불필요한 질문 한 번이고 오등록은 아니다. — Severity: minor — Class: optional — Required fix: AC-008 (3)에 "드라이버에서 현재 위치를 목적지 좌표로 두고 `현재 위치`를 고르면 활동 블록만 생기고 수단·여유·알림을 묻지 않는다"를 더하거나, 드라이버가 현재 위치를 고정할 수 없다면 이 갈래를 잔여 위험으로 `plan.md` §3에 적는다.

D6. T-1-B-3-adopted-on-silence — progress.md:L15 · plan.md:L109 · spec.md:L30 — 해석 T-1(한 번짜리 머무는 요청의 판정 범위 — 이동을 말하지 않은 모든 활동에 출발지 카드가 선다)과 경계 B-3(끝 시각 선행)은 "리드에게 확인용으로 제시 — 명시 답변 없음, 이의 없음"으로 채택됐다. SPEC이 이를 숨기지 않고 세 곳에 적은 것은 좋다. 다만 T-1은 사용자 체감이 큰 동작이다(`plan.md:174` — 식사 기록 활동에도 카드가 선다). 침묵은 동의의 증거가 아니다. — Severity: minor — Class: optional(표식이 아니므로 MP-7 대상이 아니고, SPEC 작성 결함도 아니다) — Required fix: 리드가 착수 승인(plan→run HUMAN GATE)의 `AskUserQuestion`에 T-1·B-3 확인을 한 문항으로 넣는다. SPEC 문서는 고칠 필요가 없다.

D7. REQ-010-atomicity (2회차 D11 흡수) — spec.md:L169 — REQ-010 한 문장에 카드(출발지 줄·미선택·캡션·"이동 없음"·수단 비요청), 실행부(이동 없음·50 m·다른 출발지 대기), 확정 금지, 끝 시각 선행, 도구 결과 문구, 활동 없는 구간 금지, 점심 인자, 소스 주석까지 여덟 절이 실리고 주어가 넷(card·executor·assistant·tool result/source comment)이다. AC-008 아홉 절이 절마다 대응하므로 판정은 가능하다. REQ 예산이 15/16이라 둘 이상으로 나누면 상한에 닿는 사정도 이해된다. — Severity: minor — Class: optional — Required fix: 조치하지 않아도 판정에 영향이 없다. 나눈다면 소스 주석 절(2회차 D11)과 점심 인자 절을 REQ-013의 금지 목록·REQ-011 옆으로 옮기는 정도가 예산을 늘리지 않는 길이다.

D8. SPEC-dir-run-restriction-unverified (2회차 D9 이월) — spec.md:L179 · acceptance.md:L207 — REQ-013은 run 단계에서 이 SPEC 디렉터리의 변경을 `progress.md` §E.2·§E.3과 frontmatter `status`·`updated`로 제한하지만, AC-011 (1)은 디렉터리 전체를 예외로 뺀다. — Severity: minor — Class: optional(오케스트레이터 지시로 유지) — Required fix: 2회차 D9와 같다(plan 최종 SHA 기준 `git diff --name-only`로 `progress.md`·`spec.md`만, `spec.md` 헝크는 frontmatter 두 줄뿐임을 보는 절).

D9. AC-010(3)-mixed-line-underinclusive (2회차 D10 이월) — acceptance.md:L197 — `grep -v 'Theme\.'`가 줄 단위라 한 줄에 Theme 토큰과 직접 색이 섞이면 빠진다. 이번 개정에서 바뀌지 않았다. — Severity: minor — Class: optional(유지) — Required fix: 2회차 D10과 같다.

D10. frontmatter-nonschema-fields (1회차 D18 → 2회차 D12 → 이번) — spec.md:L15-16 — `related_specs`·`kanban_card`는 스키마의 선택 필드 목록 밖이다. 린트는 통과한다. 세 회차 내내 같은 모양으로 남았으므로 정체 규칙에 문자 그대로 걸리지만, 이것은 이해 부족에서 온 진척 없음이 아니라 HISTORY 0.1.1에 적힌 의도적 관례(SPEC-UIKIT-005·007과 같음)다. 선택 결함이라 M6에 따라 차단으로 올리지 않는다. — Severity: minor — Class: optional — Required fix: 관례로 유지한다면 조치 없음.

(이 목록에 차단 항목이 없으므로 수리 경로를 강제하지 않는다. D1~D4를 반영한다면 manager-spec 한 번의 짧은 개정으로 끝나며, 3회 상한이 찼으므로 그 개정은 재감사 대상이 아니라 오케스트레이터의 기록 부채 처리로 다룬다.)

## Regression Check (Iteration 2+ only)

2회차 결함 12건:

- 2회차 D1 MP-7 게이트 표식 — **RESOLVED**: `grep -rn '\[NEEDS CLARIFICATION' plan.md` 0건, research.md 없음. `plan.md` §2(:49-69)가 채택 표로 바뀌었고 채택하지 않은 안은 "결정 기록"(:111-125)에만 있다. `progress.md:8` `kickoff_gate: resolved`.
- 2회차 D2 D-10 (b)가 D-7 (a)·D-6 (b)와 양립 불가 — **RESOLVED**: 0.1.2가 (b)의 문장을 고쳤고(HISTORY :27), 게이트가 D-10 (a) · D-6 (a) · D-7 (a)를 골랐다(`plan.md:64-65·68`). (b)는 결정 기록(:121·:125)으로만 남는다. AC-005 (5)(:119-120)와 AC-007 (2)(:143-144)는 분기 없이 (a) 원문 하나를 기대한다. REQ-009(:167) "the row's caption shall name the filled value"는 채택 원문 `'Y'에서 출발하는지 한 번 더 골라 주세요`(`plan.md:133`)로 충족 가능하다. 후보 트리 기준값을 다시 확인했다 — `:560` 고정 문장 "미리 정해진 출발지가 맞는지 …"(AC-007 (2)가 0을 요구).
- 2회차 D3 D-6 (b)가 수용 목록 밖의 H-5 수용 — **RESOLVED**: 게이트가 D-6 (a)를 골라 H-5의 바라는 동작(`startsOpen == true`, AC-005 (1) :113)이 그대로 선다. REQ-001(:147)의 수용은 H-9(I-5) 하나, 경로 제거는 H-3(D-5 (a)) 하나이고 AC-001 (5)(:60-63)과 같다.
- 2회차 D4 REQ-013 sync 목록이 재위임 편집을 막음 — **RESOLVED**: REQ-013(:179)에 "through `manager-spec` re-delegation, the citation lines of the SPEC-UIKIT-005 and SPEC-UIKIT-007 `spec.md`·`plan.md`·`acceptance.md` that REQ-015 names (including the `c5396b3` anchors)"가 들어갔고, AC-011 (1)(:210-211)과 AC-013 (5)(:255-257)가 같은 범위를 쓴다. 근거 끝 문장("sync 레인이 직접 고치지 않는다")도 그대로다 — 편집 주체와 경로 허용이 갈렸다.
- 2회차 D5 AC-005 (2)의 D-3 (c) 표지 — **RESOLVED(해당 없음)**: D-3 (a)가 채택돼 분기가 사라졌다. AC-005 (2)(:114-115)는 세 도구 모두를 기대한다.
- 2회차 D6 D-10 (a) 조사 원칙 과장 — **RESOLVED**: `plan.md:138` "값이 들어가는 자리에서는 따옴표 바로 뒤에 받침 따라 모양이 바뀌는 조사를 붙이지 않는다(REQ-008은 같은 이름 줄 캡션에 이를 건다)". 새 캡션의 `'이동 없음'을`·`'가는 편 없음'을`은 값이 아닌 고정 문구라 원칙과 맞는다.
- 2회차 D7 REQ-015 근거 문구 — **RESOLVED**: spec.md:183 "이 SPEC의 스크립트 7·8번 … SPEC-UIKIT-005 AC-009 7·9번 단계를 현재 트리 기준으로 다시 적으므로", AC-013 (5)(:257-258)도 같다. SPEC-UIKIT-005 `acceptance.md:248`(7번)·`:255`(9번, 왕복)을 읽어 이 SPEC의 스크립트 7·8번과 같은 입력임을 확인했다.
- 2회차 D8 옮겨 적은 인용 문장 — **RESOLVED**: REQ-015(:183) "living documents … shall update that sentence to match while completed SPEC bodies keep it and record it in the ledger", AC-013 (2)(:251-252).
- 2회차 D9 run 단계 SPEC 디렉터리 제한 — **UNRESOLVED(선택, 지시로 유지)**: 이번 D8.
- 2회차 D10 AC-010 (3) 섞인 줄 — **UNRESOLVED(선택, 지시로 유지)**: acceptance.md:197에 `grep -v 'Theme\.'` 그대로. 이번 D9.
- 2회차 D11 REQ-010 주석 절 문체 — **UNRESOLVED(선택)**: 이번 D7에 흡수.
- 2회차 D12 비스키마 필드 — **유지(관례)**: 이번 D10.

정체 점검: 세 회차 모두에 같은 모양으로 나온 결함은 비스키마 필드 하나이고, 의도적 관례라 "진척 없음" 표식을 달지 않는다(D10). 차단 결함 가운데 세 회차를 버틴 것은 없다.

## 새 차분 점검 (요청 항목 2 · 3)

| 영역 | 판정 | 근거 |
|---|---|---|
| 게이트 표식 → 채택 사실 | 성립 | `plan.md:57-69` 채택 표, 반영 자리 열의 REQ·AC·스크립트 번호가 본문과 일치. REQ·AC의 결정 조건절 잔재 검색(`D-n (b)`·`(c)`·`Where D-`) → HISTORY 행(:26-27)에만 남는다 |
| D-8 운영자 문구 → REQ-010 | 성립 · 경미 | 머무는 요청을 인자로 정의(반복 = 같은 값, 한 번짜리 = 장소 있음·오는 편 없음·가는 편 비었거나 같은 값). REQ-008 제외 신호(:165)·REQ-009 발동 조건(오는 편 있음, :167)과 서로 겹치지 않는다. 운영자 첫 문장의 "오는 편" 되묻기가 한 번짜리에서 빠진 것은 B-1로 명시하고 t30으로 넘겼다. 50 m 절의 범위(D1)·검증(D5)·"늘 있다"(D3)는 선택 |
| H-11 신설·확장 | 성립 | §1.5 H-11(:136)의 근거 좌표 `:549-550`·`:521-529`·AA-4 `:1888-1890`·O-6 `:1595-1597`을 이 트리에서 확인. 후보 트리에서 `'이동 없음'` 0건이므로 M1 재현(✗)이 확정적이다 — REQ-001의 "재현 안 되면 고치지 않는다"와 충돌할 여지가 없다 |
| 드라이버 단언 충돌 전수 | 성립 · 경미 | `drvAsk` 활동·반복 호출 11곳 중 머무는 요청에 걸리는 것은 AA-4 첫 단언·O-6 첫 단언뿐 — SPEC 목록과 같다(`rBase` :846은 오는 편 있음, `t1` :1009는 출발지 없음, `z8Args` :1637은 다른 값). O-6 처리 방식은 D2 |
| t30 이관 | 성립 · 경미 | 카드가 큐에 실재. §3 t30 절의 비용 좌표(`EditCard.swift:119`·`:165-169`·`:240`, `AIAssistant.swift:871-875`·`:1049-1051`, `AIChatView.swift:125-133`, `EditCardView.swift:223-228`, `AddActivityView.swift`의 `fields.insert`/`removeAll` :190-325)를 확인. 선언 근거 한 줄의 어긋남은 D4 |
| 스크립트 재배열 | 성립 | AC-014 = 1~16, AC-015 = 17~20(매트릭스 :37-38, 본문 :262·:267). 초기화 시점(:287)·새 대화 예외(13번)·전사 단계(3·4·11·12·14·15·16)가 단계 내용과 맞는다. 12번의 결과 문구 "한 장소 반복 활동 … 이동 구간은 만들지 않았어요"는 후보 코드 `:1829`의 문구와 같다 |
| 이미 건전했던 절의 회귀 | 없음 | REQ-002~007·011~015, AC-001·002·004·005·007·009~013의 판정 명령이 바뀌지 않았거나 분기만 걷혔다. AC-011 (1)을 HEAD에서 돌리면 0줄(예외 없이 돌리면 8줄 — 렌즈 둘 · 감사 보고서 둘 · SPEC 네 파일). 0.1.3~0.1.5 커밋은 SPEC 디렉터리 네 파일만 바꿨다 |

## Recommendation

**PASS.** must-pass 일곱 개의 근거:

1. MP-1 — REQ-001~015가 빈 번호·중복 없이 `spec.md:147-183`에 있다.
2. MP-2 — 15건 모두 GEARS 패턴(복합형 포함)이고 결정 조건절이 사라졌다. 린트 `--strict` 무결.
3. MP-3 — 12필드가 올바른 타입으로 있다(spec.md:2-13).
4. MP-4 — 단일 언어 SPEC이라 해당 없음.
5. MP-5 — 참조 SPEC 넷이 completed/draft이고 폐기·대체 상태가 없다.
6. MP-6 — `syscall` 0건.
7. MP-7 — plan.md에 표식 0건, research.md 없음, 게이트 해소 기록 있음.

**차단 결함은 남아 있지 않다.** 2회차 차단 결함 D1~D4는 모두 해소됐고, 이번 회차 결함 10건은 모두 선택이다.

오케스트레이터 재량(선택):
1. run 착수 전에 manager-spec에 D1~D4를 한 번에 맡기면 싸다 — D1은 50 m 판정의 자리를 한 줄로 정하고 AC-008 (5)에 양성 대조 하나, D2는 O-6 기대 키 교체, D3은 "늘 있다" 한 구절과 AC-008 (7) 끝 문장, D4는 §3 근거 한 줄. 3회 상한이 찼으므로 이 개정은 재감사 없이 기록 부채 처리(PASS-with-debt 기록)로 다룬다.
2. 리드는 착수 승인 게이트에서 T-1·B-3을 명시적으로 확인한다(D6).
3. D5는 드라이버가 현재 위치를 고정할 수 있는지에 따라 AC 한 줄 또는 잔여 위험 한 줄로 닫는다.
4. D7~D10은 기록된 부채로 넘겨도 된다.

## 검증 증거 (이 감사가 `47c40f5` 트리에서 직접 실행)

| 대상 | 명령 | 관측 |
|---|---|---|
| 트리 | `git rev-parse --show-toplevel` · `git branch --show-current` · `git log --oneline -8` | `…/worktrees/t16` · `WT-place-resolution` · `47c40f5`(0.1.5) · `d8d68db`(0.1.4) · `d3a304d`(0.1.3) · `d0a2c60`(0.1.2) · `2313e38`(0.1.1) · `e1a40a6`(wip) |
| 코드 불변 | `git diff --quiet e1a40a6 -- Shared Tools proxy project.yml; echo $?` | `0` |
| REQ·AC | `grep -n '^- \*\*REQ-'` · `grep -n '^## AC-'` · `grep -c` 둘 | :147~:183 · :48~:265 · `15` · `15` |
| MP-7 | `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` | 일치 없음 · `research.md: No such file`(exit 2) |
| D8 | `grep -c 'syscall'` 네 파일 | `0 0 0 0` |
| 린트 | `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` | `✓ No findings — all SPEC documents are valid` |
| 프런트매터 | `sed -n '1,17p' spec.md \| grep -E '^(id\|title\|…\|tier):'` | 12필드 + `tier: M` |
| D7 | 세 파일 참조 추출 → `grep -m1 '^status:'` | ASK-001 draft · UIKIT-003/005/007 completed · 008 draft · 미발견 0 |
| t30 | `moai todo \| grep t30` | `t30 queued C21 AI 카드 문법 통일 — t16에서 이관된 운영자 결정 B-1·B-2 …` |
| 범위 | AC-011 (1) 명령 그대로 · 예외 없이 · `git show --name-only` 커밋 넷 | 0줄(exit 0) · 8줄 · 네 커밋 모두 SPEC 디렉터리(`d0a2c60`만 2회차 보고서 추가) |
| 분기 잔재 | `grep -noE 'D-[0-9]+ \((b\|c)\)\|Where D-' spec.md acceptance.md` | spec.md :26·:27(HISTORY)뿐 |
| AIAssistant 좌표 | `sed -n` — :285 · :292 · :549-550 · :556-562 · :1264 · :1610 · :1624 · :1767 · :1814 · :1848-1864 · :1808-1829 | `cancelPendingAsk()` · `repairDanglingToolTurn()` · `guard outbound \|\| back else { break }` · 고정 캡션 · `end_iso` 필수 · 활동 정보 부족 문구 · `missingAskedArguments`(활동 · 반복) · `return_time에 넣어` 문구 · 복귀 구간 + 활동 블록 · "한 장소 반복 활동 … 이동 구간은 만들지 않았어요" |
| 탈출 칩 방식 | `sed -n '636,648p'` · `grep -n '가는 편 없음\|noOutboundToken'` | `outboundOriginField`가 내부 토큰 칩을 AIAssistant 안에서 붙인다(:644, :2600) — "이동 없음"도 같은 방식으로 선언된 파일 집합 안에서 가능 |
| t30 비용 좌표 | `sed -n` — AIAssistant :871-875 · :1049-1051, EditCard :119 · :165-169 · :240 · :263 · :313-315, AIChatView :125-133, EditCardView :223-228 · :240-242, Store :628 · `grep -n 'fields.insert\|removeAll' AddActivityView.swift` | 서술과 일치 · AI 카드에 `chooseTimePlain` 없음 · 멤버십 조작은 AddActivityView :190~:325 |
| 드라이버 단언 | `sed -n` GuardDriver :1580-1600 · :1876-1900 · :763-769 · `grep -n 'drvAsk("create_activity"\|drvAsk("create_recurring_schedule"'` | O-6 첫 단언 `== ["place_query"]`(입력 `회사` — 못 푸는 장소) · AA-4 첫 단언 `== ["weeks"]` · (e) 카드 키 선언 금지 · 11곳 중 충돌 둘 |
| 005 원문 | `sed -n '245,262p' .moai/specs/SPEC-UIKIT-005/acceptance.md` | 7번(같은 이름 일정) · 9번(왕복 활동 세 줄) — 이 SPEC 스크립트 7·8번과 같은 입력 |
| 교차 모델 | `mcp__moai__audit_multi`(claude required · codex off · glm advisory) | claude pass · glm inconclusive(fail-open) · 종합 pass · 이견 없음 |

## Gaps (미검증)

- **운영자 결정의 원문** — 게이트 채택, D-8 문구, 해석 I-1~I-6의 답, B-1·B-2 분리 결정은 모두 칸반 리드의 전달이고 이 트리에는 SPEC이 옮겨 적은 문장만 있다. 이 감사는 옮겨 적은 내용끼리의 일관성만 판정했고, 운영자가 실제로 그렇게 답했는지는 확인하지 않았다. t30 카드 본문의 운영자 원문도 `moai todo` 한 줄 요약(잘림)만 읽었다.
- 드라이버·`xcodebuild`·`npm test`·시뮬레이터는 **실행하지 않았다.** plan 단계 산출물이므로 판정 대상이 아니다.
- D-5 (a)의 전제(도구 결과 턴 뒤 사용자 턴을 프록시·백엔드가 받는가)는 여전히 미확인이다. SPEC은 run 착수 전 확인과 깨질 때의 블로커 경로를 적었다(REQ-005).
- 렌즈 보고서 두 파일은 이번에도 읽지 않았다. SPEC이 인용한 절 번호가 그 내용을 담는지는 대조하지 않았다.
- `AddActivityView.swift:169-326`이 "토글 멤버십이 있는 유일한 자리"라는 주장은 그 파일 안의 조작 위치만 확인했고, `ActivityDetailView.swift` 등 다른 수동 화면에 같은 조작이 있는지는 전수로 보지 않았다(t30 근거라 이 SPEC의 판정과 무관).
- 루트 `plan.md:230-233` 토큰 측정법, 인용 계수(CHECKLIST 14 등)는 이번 차분이 바꾸지 않아 다시 재지 않았다(2회차에 측정).
- `mcp__moai__spec_audit`는 주 체크아웃을 읽으므로 쓰지 않았다(호출자 지시). 린트는 워크트리 CLI로 대신했다.
- glm 보조 감사는 2회차와 마찬가지로 응답 내용이 없어 결론을 내지 못했다(fail-open).

## Residual-risk (잔여 위험)

- 머무는 요청의 다른 출발지 경로는 두 번째 카드를 모델 재호출에 기댄다. 재호출에서 `weeks`(선언 밖)가 빠지면 '반복 기간'을 다시 묻고(H-9와 같은 모양, 수용), `return_time`이 빠지면 가는 구간만 생긴다(D3). 둘 다 결과 문구나 카드로 드러나며 조용하지는 않다.
- 이동을 말하지 않은 한 번짜리 활동마다 출발지 카드가 선다(T-1). 운영자가 고른 동작이지만 명시 확인은 없었다(D6). 식사 기록처럼 이동과 무관한 활동에서 불편으로 돌아올 수 있다.
- 끝 시각 문장 되묻기와 한 번짜리 오는 편 부재는 중간 동작이다. t30이 닫기 전까지는 AC-009 7번 실패와 같은 모양(카드 없이 글로 이어지는 대화)이 남는다(`plan.md:176-177`).
- 극성 규칙은 run의 기록 규율에 기댄다. M1의 ✗ 줄을 §E.2에 적지 않고 `[수용]`·`[경로 제거]`로 바로 쓰면 재현 증거가 사라지지만, AC-001 (5)가 ✗ 줄을 요구하므로 판정 단계에서 잡힌다.
- 인용 원장 방식은 t15에서 두 감사가 모두 0을 보고한 실패를 겪었다. 맨몸 `:N`의 행 기본 파일 해석과 "대상 제거·재작성" 행의 문장 처리는 sync 때 처음 실측된다.

🗿 MoAI
