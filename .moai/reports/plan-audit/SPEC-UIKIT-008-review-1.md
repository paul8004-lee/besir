# SPEC Review Report: SPEC-UIKIT-008
Iteration: 1/3
Verdict: FAIL
Overall Score: 0.77

감사 대상 트리: `.claude/worktrees/t16` (branch `WT-place-resolution`, HEAD `e1a40a6`, base `aa7b792`). SPEC 디렉터리는 아직 추적되지 않은 상태(`?? .moai/specs/SPEC-UIKIT-008/`)이며, 네 파일(`spec.md` 225줄 · `plan.md` 223줄 · `acceptance.md` 310줄 · `progress.md` 89줄)을 모두 읽었다. Tier M이므로 `design.md`·`research.md`는 입력이 아니다.

M1 맥락 격리: 작성자의 추론 맥락은 전달되지 않았다. 오케스트레이터 지시(작업 트리 지정, `D-n` 게이트 표식 분류)만 따랐고, 그 지시는 MP-7의 **성격 규정**에만 반영했다 — 판정 자체는 바꾸지 않았다.

교차 모델: 설정은 `audit.model: multi`(codex off · glm advisory, 주 체크아웃 `workflow.yaml:77-82`). `mcp__moai__audit_multi` → claude FAIL, glm `inconclusive`("z.ai response carried no content", fail-open). 종합 FAIL, 이견 없음.

**FAIL의 성격.** 두 갈래다. ① MP-7은 작성 결함이 아니라 **착수 승인 게이트가 아직 열리지 않았다는 신호**다 — 결정 10건이 규약대로 `plan.md` §2에만 표식으로 있고, 리드가 게이트에서 풀면 해소된다. ② 그와 별개로 작성 결함이 있다. 요구사항끼리의 충돌 둘(REQ-008↔REQ-010, REQ-001↔REQ-014), 사실과 다른 전제를 가진 결정 선택지 하나(D-7 (b)), 판정을 틀리게 내는 AC 명령 하나(AC-003), 완료된 SPEC-UIKIT-005 인용을 재사상하는 규칙의 구멍 하나(REQ-015·AC-013)가 무겁다. 점수 0.77도 Tier M 통과선 0.80 아래다.

SPEC의 실측 품질은 높다. 아래 §검증 증거처럼 SPEC이 든 코드 좌표를 주요 절마다 이 트리에서 다시 대조했고, **대조한 좌표는 전부 맞았다**(§0 표의 diff·길이·헝크 수, §1.2~§1.5의 함수·줄 좌표, §1.3 여덟 조합의 판정 근거 줄, REQ 근거의 grep 계수, `plan.md` §5 기준선, 스크립트 사전 조건의 좌표). 결함은 측정이 아니라 **요구사항 사이의 관계와 검증 명령의 설계**에 있다.

## Must-Pass Results

- [PASS] **MP-1 REQ 번호 일관성** — `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:140)부터 REQ-015(:176)까지 15건, 빈 번호·중복 없음, 세 자리 채움 일관. `grep -c` = 15, AC도 `grep -c '^## AC-' acceptance.md` = 15(:42~:213)로 Tier M 상한 16 아래다.
- [PASS] **MP-2 GEARS 형식 (요구사항 층 기준으로 판정)** — REQ 15건 모두 `shall` 구조이고 When/While/Where/shall not 패턴 또는 그 복합형이다. 예: REQ-004(:148) "While a candidate card is open, … shall not receive …", REQ-012(:168) "Where U-2 is in this card's scope, while the place-search editor is open …, no chip … shall render as selected". `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` → `✓ No findings`. 규범 문장에서 should/may 검색은 REQ-011 인용부("may have been deleted") 한 건뿐이다. 경미 사항 둘 — REQ-014(:174)의 "Before the card leaves run …"는 다섯 패턴의 키워드가 아닌 시간 한정절이고, REQ-006(:152)은 "Where — D-6"로 표시했지만 본문에 Where 절이 없다(선택형 서술). 둘 다 선택 결함으로 D17에 두었다. AC는 검증 층이라 Given-When-Then으로 따로 채점했다(Group 4).
- [PASS] **MP-3 YAML 프런트매터** — spec.md:1-17. 필수 12필드가 모두 있다: `id: SPEC-UIKIT-008` · `title` 따옴표 · `version: "0.1.0"` · `status: draft` · `created`/`updated: "2026-09-26"` · `author` · `priority: P1` · `phase: "Phase 1.7 — …"`(단계명 금지값 아님) · `module: "shared-ui"` · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부되는 별칭(`created_at`·`labels` 등) 없음. `tier: M`은 선택 필드다. `related_specs`·`kanban_card`는 스키마 목록 밖이지만 SPEC-UIKIT-007과 같은 선례이고 린트가 통과한다(선택 결함 D18).
- [N/A] **MP-4 언어 중립성** — 단일 언어(Swift) 앱 SPEC이다. 다언어 도구 서술이 없다.
- [PASS] **MP-5 D7 교차 SPEC** — 참조 SPEC 넷: SPEC-UIKIT-003 `completed` · SPEC-UIKIT-005 `completed` · SPEC-UIKIT-007 `completed` · SPEC-ASK-001 `draft`. retired·superseded·archived가 없어 BLOCKING은 없다. 단 SPEC-UIKIT-005와의 **내용 수준 불일치**는 따로 있다(D7, Group 6).
- [PASS] **MP-6 D8 교차 플랫폼** — `grep -c 'syscall'` → spec 0 · plan 0 · acceptance 0 · progress 0. 자동 통과.
- [FAIL] **MP-7 명확화 게이트** — *clarification gate finding*. `grep -rn '\[NEEDS CLARIFICATION' .moai/specs/SPEC-UIKIT-008/` → `plan.md` :55 D-1 · :66 D-2 · :75 D-3 · :86 D-4 · :93 D-5 · :102 D-6 · :108 D-7 · :115 D-8 · :122 D-9 · :129 D-10(10건). `spec.md`·`acceptance.md`에는 없다(관례대로). `research.md`는 없다. `progress.md:8` `kickoff_gate: pending`. **분류: 게이트 표식(착수 승인 게이트의 소유자는 칸반 리드)이며 manager-spec의 작성 결함이 아니다.** 리드가 `AskUserQuestion`으로 풀기 전에는 착수 승인이 진행될 수 없다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.70 | 0.50~0.75 사이 | 해석이 갈리는 REQ가 셋이다. REQ-008(:158)의 적용 도구 범위가 REQ-010(:162)의 머무는 반복 신호와 충돌(D2), REQ-010의 좌표 조건이 실행 전 카드를 지배(D3), REQ-001(:140)의 단언 극성이 수용 결정과 어긋남(D4). 나머지 12건은 한 가지로 읽힌다 — 예: REQ-003(:146)의 조합 목록, REQ-013(:172)의 경로 목록 |
| Completeness | 0.85 | 0.75~1.0 사이 | HISTORY(:21-25) · 성격·예산(§0 :27-46) · 배경(§1 :48-134) · 요구사항(§2 :136-176) · AC(acceptance.md) · Out of Scope H3 7개와 글머리표(:180-210) · 프런트매터 12필드 모두 있음. 감점: 연구 입력(렌즈 보고서 둘)이 추적되지 않아 보존이 보장되지 않고(D8), REQ-015 기준 계수가 GuardDriver 인용을 빠뜨림(D9) |
| Testability | 0.70 | 0.50~0.75 사이 | AC-003 계수 명령이 AB-H10과 충돌해 판정을 틀리게 낸다(D6). AC-008 (5)와 AC-012 (1)이 동시에 참일 수 없다(D4). AC-011 (1)의 기준점이 plan 커밋을 포함한다(D8). AC-013 (2)에 대상이 사라진 인용의 범주가 없다(D7). D-10의 문자열 신호가 정의되지 않았다(D12). 반면 AC-001·002·005~007·009·010의 명령은 이 트리에서 의도대로 작동함을 확인했다 |
| Traceability | 0.85 | 0.75~1.0 사이 | 모든 REQ에 AC가 있고(plan.md:19-20 대응표, acceptance.md:17-33 매트릭스), 모든 AC가 존재하는 REQ를 가리킨다. 감점: 두 대응표의 불일치(AC-014의 REQ-004), AC-003 제목 "여덟"과 본문 "열"(D14), REQ 본문이 아니라 근거에만 있는 조건을 검사하는 AC 하위 항목(AC-006 (4)·AC-010 (2)·AC-011 (6) — D12·D15) |

집계: 조화평균 4 / (1/0.70 + 1/0.85 + 1/0.70 + 1/0.85) = 4 / 5.2101 = **0.77**. Tier M 통과선 0.80 미달.

## Defects Found (structured defect-list)

D1. MP-7-clarification-gate — plan.md:L55·L66·L75·L86·L93·L102·L108·L115·L122·L129 — 결정 D-1~D-10의 `[NEEDS CLARIFICATION]` 10건이 미해소다(`progress.md:8` `kickoff_gate: pending`). — Severity: critical — Class: blocking(**게이트 표식 — 소유자는 칸반 리드, 작성 결함 아님**) — Required fix: (1) 리드가 착수 승인 게이트에서 D-1~D-10과 Tier M 확인을 `AskUserQuestion`으로 결정한다. 그 전에 아래 D5·D12(선택지 자체의 결함)를 먼저 고쳐 운영자가 성립하지 않는 안을 고르지 않게 한다. (2) 결정 뒤 manager-spec이 각 표식을 채택 사실로 바꾸고, "Where — D-n" 조건부 REQ(002·006·009·010·012)와 결정 번호가 붙은 AC 절(AC-002 (2)(3)·004·005 (1)·006 (4)·007 (2)·008 (2)(5)·010·015)을 채택안 하나로 확정한다.

D2. REQ-008-scope-contradiction — spec.md:L158 vs L162 — REQ-008은 "one creation call"이 같은 검색 이름을 두 키 이상에 실으면 줄을 띄우라고 하는데, REQ-002(:144)가 정의한 등록 경로에는 `create_recurring_schedule`이 들어 있다. 그 도구에서 출발지·목적지의 같은 값은 **머무는 반복의 신호**다(`Shared/AIAssistant.swift:1193` 프롬프트 "origin_query와 destination_query에 같은 장소를 넣어라", `:1273` 선언 설명, `:720-725` `stayingRecurrence`). 따라서 "매주 … 스타벅스 홍대점에서 공부"처럼 검색에 맡겨지는 이름으로 머무는 반복을 요청하면, REQ-008은 두 지점을 따로 고르라는 같은 이름 줄을 요구하고 REQ-010은 이동 없는 활동 블록을 요구한다. 후보 구현은 같은 이름 줄을 `create_schedule`(:495-505)·`create_activity`(:537-548)에만 두었고(반복 분기 :517-530에는 없음), AC-006도 그 둘만 시험한다 — REQ 문언만 넓다. — Severity: major — Class: blocking — Required fix: REQ-008의 주어를 "`create_schedule` or `create_activity` call"로 좁히고, "`create_recurring_schedule`에서 출발지·목적지의 같은 값은 REQ-010의 머무는 반복 신호이며 이 규칙에서 제외한다"를 한 문장으로 넣는다.

D3. REQ-010-trigger-layer — spec.md:L162 — "When the origin and destination … resolve to places within 50 m …, the executor shall … and the card shall not ask for mode, buffer, or notification lead". 좌표 해석은 실행 때 일어나고(`:1812` `isSamePlace`), 카드는 그보다 먼저 문자열 비교로 억제된다(`:525` `stayingRecurrence`). 코드 주석(`:716-719`)이 그 어긋남을 명시적으로 받아들인다 — "집/우리집처럼 다른 이름의 같은 좌표 … 카드는 수단을 묻고 실행부는 구간을 안 만든다". 문언대로면 후보도, 권장안 D-8 (a)도 이 REQ를 만족하지 못한다. — Severity: minor — Class: blocking — Required fix: 두 조건으로 가른다. "When `origin_query` and `destination_query` carry the same value, the card shall not ask for mode, buffer, or notification lead; when they resolve within 50 m, the executor shall create activity blocks only …". 이름은 다르고 좌표만 같은 경우는 코드 주석과 같은 결론으로 잔여 위험에 적는다.

D4. REQ-001-assertion-polarity — spec.md:L140 · L174, acceptance.md:L141 · L186 — REQ-001은 "재현 단언이 후보에서 통과하면 재현 안 됨"으로 정의한다. 즉 단언은 **바라는 동작**을 적는다. 그런데 게이트가 고치지 않고 받아들이기로 하는 가설에서는 이 정의가 REQ-014와 양립하지 않는다. 권장안 D-8 (a)에서 H-9는 "기록만" 한다(AC-008 (5)). 바라는 동작으로 적으면 ✗가 끝까지 남아 AC-012 (1) `grep -c '✗' = 0`이 실패한다. 관측 동작으로 적으면 후보에서 ✓가 나와 REQ-001이 "재현 안 됨"을 기록하게 하는데, H-9의 예측(spec.md:128 "weeks 없는 재호출 인자에 기간 줄이 선다")이 바로 그 관측이다 — 기록이 거짓이 된다. D-2 (c)의 H-4, D-5 (c)의 H-3도 같은 모양이다. — Severity: major — Class: blocking — Required fix: REQ-001에 극성 규칙을 넣는다. (a) 고칠 가설의 단언은 바라는 동작을 적는다(후보 ✗ = 재현). (b) 게이트가 수용으로 정한 가설은 관측 동작을 적는 **특성화 단언**으로 두고, 이름에 표지를 붙이며(예: `AB-H9 [수용]`), §E.2에 "재현됨 — 수용(D-n)"으로 기록한다. AC-008 (5)와 AC-001 (4)를 이 규칙에 맞춘다.

D5. D-7(b)-false-premise — plan.md:L112 — D-7 (b)는 "발화 파서(`statedArguments`)가 출발지를 읽는다"를 전제로 두고 "확인하지 않았다"고 적었다. 이 트리에서 확인하면 전제는 **거짓**이다: `Shared/AIAssistant.swift:338-344` `statedArguments`는 `mode_this_time`·`buffer_minutes`·`notify_lead_minutes` 셋만 읽고 출발지를 읽지 않는다. (b)를 고르면 발화에서 출발지를 읽는 새 기능이 필요한데, 이를 담는 REQ가 없고 AC-007의 "발화 픽스처 추가"는 시험할 대상이 없다. — Severity: major — Class: blocking(결정 선택지 결함 — 게이트 전에 고칠 것) — Required fix: D-7 (b)에 `:338-344` 인용과 함께 "전제가 이 트리에서 거짓 — 고르면 출발지 발화 파싱이라는 새 동작이 필요하고 그 REQ·AC를 새로 써야 한다(파일은 AIAssistant 안이지만 범위가 는다)"를 적거나, (b)를 거둔다.

D6. AC-003-grep-prefix-collision — acceptance.md:L80 (명명 규칙 L12-13) — 드라이버는 단언을 `"  ✓ \(label)"`로 찍는다(`Tools/GuardDriver.swift:31`). `grep -c '✓ AB-H1'`은 `AB-H10 …` 줄도 센다. H-10은 AC-008 (3)이 요구하는 단언이라 반드시 생긴다. 결과: ≥ 10 조건이 H-1이 아닌 줄로 채워질 수 있고, `grep '✗' <로그> | grep -c 'AB-H1'`은 AB-H10의 실패를 AC-003 실패로 센다. 판정이 양방향으로 틀릴 수 있다. — Severity: major — Class: blocking — Required fix: 명명 규칙(L12-13)을 두 자리 채움(`AB-H01`~`AB-H10`)으로 바꾸고 AC-002 (3)·AC-003의 명령을 그에 맞추거나, 경계를 명시한다: `grep -cE '✓ AB-H1( |:)'`.

D7. REQ-015-005-remap-and-isSamePlace-widening — spec.md:L176, acceptance.md:L202 · L205-206 — 두 문제가 한 자리에 겹친다.
  (i) REQ-015는 "SPEC-UIKIT-005 AC-009의 `:1297`·`:1613`"만 교정 대상으로 지목하지만, 같은 두 토큰이 005 `acceptance.md:135-138`(AC-005 Given)에도 있고, 그 Given의 나머지 넷(`:748`·`:2322`·`:2371`·`:2393`)도 전부 `c5396b3` 좌표다(`git show c5396b3:Shared/AIAssistant.swift` → `:748` `confirmedPlaces[place.name] = place`, `:1297` `if Self.isSamePlace(origin, dest) {`, `:1613` "…create_schedule 경로 전용" 주석). 이 Given은 005가 고치기 **전**의 결함 상태를 적은 문장이고, 가리키던 원문 일부는 005의 수리로 사라졌다 — `grep -c 'confirmedPlaces\[place.name\] = place'` → aa7b792 0 · head 0. REQ-015의 "지문으로 찾아 교체"는 이런 행을 풀 수 없고, AC-013 (2)의 "불일치 0"에는 "대상 원문이 사라졌거나 이 카드가 바꾼 행"이라는 범주가 없어 충족 불가능하다.
  (ii) 후보는 `create_recurring_schedule`에 두 번째 `isSamePlace(origin, dest)` 호출을 넣었다(`:1812`, create_schedule은 `:1492`). 그래서 `:1869` 주석 "(`isSamePlace` 가드는 create_schedule 경로 전용)"은 문자 그대로는 더 이상 참이 아니다. 같은 주석을 루트 `plan.md:562`·`CHECKLIST.md:535`(base 좌표 `:1654`)·005 AC-009(:259의 `:1613`)가 인용한다. AC-013 (5)는 005 인용을 이 주석으로 다시 가리키게 하므로, 거짓이 된 문장을 인용하는 결과가 된다. 또 005 `spec.md:237-240`(§3, §1이 아니라 재정렬 대상)은 "create_recurring_schedule·create_activity에 없다 … 넓히지 않는다"라고 적었는데, 이 SPEC은 그 적용 확대를 조정하지 않았다(§1.4 :112는 isSamePlace 본문과 create_schedule 거절이 무변경이라고만 적는다).
  — Severity: major — Class: blocking — Required fix: (a) AC-013 (2)에 원장 범주 "대상 제거·재작성" 행을 추가한다(행이 새 원문과 그것을 바꾼 REQ 또는 커밋을 적고 바이트 대조에서 빠지되 목록에는 남는다). (b) 005 AC-005 Given처럼 수리 전 상태를 적은 문장은 재사상하지 않고 `c5396b3` 고정 표기를 달게 한다(편집은 manager-spec 재위임 — REQ-015가 이미 정한 경로). REQ-015의 "AC-009의 `:1297`·`:1613`" 지목도 이 규칙에 맞춰 다시 쓴다. (c) §1.4 또는 §3에 "REQ-010의 머무는 반복 분기가 `create_recurring_schedule`에 isSamePlace의 두 번째 사용처를 만든다 — 005 §3의 '넓히지 않는다'는 그 카드의 범위 판단이었다"를 적고, `:1869` 주석 교정을 run 범위(REQ-013의 AIAssistant.swift 안)에 명시한다. AC-013 (5)는 교정된 주석을 대상으로 삼는다.

D8. AC-011(1)-baseline-and-lens-reports — acceptance.md:L168, spec.md:L172 · L25 · L219 — AC-011 (1)은 `git diff --name-only e1a40a6 HEAD`로 경로 범위를 본다. 그런데 plan 산출물은 `e1a40a6` **뒤에** 커밋된다. 이 SPEC이 연구 입력으로 절 번호까지 인용하는 렌즈 보고서 둘(`.moai/reports/t16/plan-lens-ai-tooling.md`·`plan-lens-ui-design.md`)은 지금 추적되지 않고 무시 목록에도 없다(`git check-ignore -v` exit 1, `git status` `??`). plan 커밋이 이들을 담으면 REQ-013 목록 밖 경로가 되어 AC-011 (1)이 거짓 FAIL을 낸다. 담지 않으면 인용된 연구 입력이 워크트리 폐기와 함께 사라진다(증거 보존 규칙 위반). — Severity: minor — Class: blocking — Required fix: plan 커밋이 두 렌즈 보고서를 버전 관리에 넣는다고 명시하고, REQ-013의 예외 목록에 `.moai/reports/t16/plan-lens-*.md`를 plan-audit 보고서와 나란히 추가한다. 또는 AC-011 (1)의 기준점을 plan 커밋 SHA로 옮긴다.

D9. REQ-015-GuardDriver-count-omitted — spec.md:L176, acceptance.md:L200-201 — REQ-015는 `Tools/GuardDriver.swift` 인용도 재사상 대상으로 두지만, 착수 시점 계수는 AIAssistant 토큰만 적었다(14 · 4 · 6 · 1 · 3 · 1 — 이 트리에서 재현해 일치). GuardDriver 파일명 토큰은 `CHECKLIST.md:619` `GuardDriver.swift:264` 1건이 있고, 이미 후보가 밀어냈다: base `:264` = `setenv("CFFIXED_USER_HOME", …)`, head `:264` = 주석 줄, `setenv`는 `:275`(드라이버 헝크 `@@ -135,0 +136,11 @@` 외 4개). t15에서 파일명 계수 18이 실제 87이었던 것과 같은 과소 산정의 입구다. — Severity: minor — Class: blocking — Required fix: REQ-015 근거와 AC-013 (1)에 GuardDriver 파일명 토큰 계수(`grep -o 'GuardDriver\(\.swift\)\{0,1\}:[0-9]\{1,4\}' <문서> | wc -l` → CHECKLIST 1, 나머지 0)와 명령을 추가한다.

D10. D-5(a)-premise-no-fallback — plan.md:L95-97 — D-5 (a)의 전제(도구 결과 턴 뒤에 사용자 턴이 오는 히스토리를 프록시·백엔드가 받아들임)는 게이트 **뒤** run 착수 전에 확인하게 되어 있다. 같은 모양의 순서 오류가 Workers AI 시절 실제로 났다(`AIAssistant.swift:408-412` 주석). 전제가 깨졌을 때의 경로(블로커 반환 뒤 재질문인지, (b)로 넘어가는지)가 없어 AC-004 (2)의 분기가 run 도중 비게 된다. — Severity: minor — Class: optional — Required fix: "전제가 깨지면 run은 블로커를 돌려주고 리드가 D-5를 (b) 권장으로 다시 묻는다" 한 줄을 D-5 (a)에 붙인다.

D11. D-3(c)·D-5(c)·D-1(c)-effect-lists-incomplete — plan.md:L83-84 · L100 · L62-63, acceptance.md:L154 · L215 · L244-246 — "바뀌는 것"이 AC 쪽 변경을 빠뜨렸다. D-3 (c)는 AC-003 조합 3~8·10과 스크립트 3·4번의 기대 변경을, D-5 (c)는 AC-004 (2)를 적지 않았다. D-1 (c)는 plan이 "REQ-012·AC-010·AC-015 삭제"라고 적는데 acceptance는 AC-010을 "EditCardView diff 빈 출력"으로 바꾸고 AC-015를 "해당 없음"으로 둔다. 스크립트 2번에는 D-1 (c)일 때의 기대가 없다. — Severity: minor — Class: optional — Required fix: 각 선택지의 "바뀌는 것"에 해당 AC 절과 스크립트 번호를 적고, D-1 (c)의 처리를 한 가지로 통일한다.

D12. D-10-strings-undefined — plan.md:L129-134, acceptance.md:L241 · L263-264 · L120 — D-10 (a)는 ui 렌즈 §2.1의 문안을 가리킬 뿐 SPEC 안에 문자열이 없다. 스크립트 1·7번의 "캡션은 D-10 문구다"는 SPEC 산출물만으로 판정할 수 없다. plan은 "바뀌는 것: AC-005·006·007·008의 문자열 신호"라고 적지만 AC-005와 AC-008에는 D-10 문자열 신호가 없다 — 후보 캡션에서 구현 용어("첫 검색 결과", `:735`)를 빼는 것과 머무는 반복의 "이동 없이 한 곳에서"를 기계로 보는 명령이 없다. AC-006 (4)(조사·줄표)는 어느 REQ도 요구하지 않는 성질을 검사한다 — REQ-008은 "a caption stating why it is asked"까지만 요구한다. — Severity: minor — Class: blocking(선택지가 AC를 판정 불능으로 남김) — Required fix: 게이트 뒤 채택 문자열을 `plan.md` §2(또는 acceptance.md)에 원문으로 적고, AC-005·AC-008에 `grep` 신호를 더한다. 조사·줄표 규칙은 REQ-006의 캡션 절이나 REQ-008에 한 구절로 올린다.

D13. REQ-014-pass-count-net-vs-gross — spec.md:L174, acceptance.md:L186 — "241 plus the assertions it added"는 순증인지 총 추가인지 정하지 않았다. AC-002 (1)은 주소 없는 '강남' 단언(`GuardDriver.swift:1834-1835`)을 주소 있는 둘로 바꾸게 하고, REQ-013은 죽은 경로 제거를 요구하므로 기존 단언이 빠질 수 있다. 그러면 "241 + 추가 수"와 T가 어긋난다. — Severity: minor — Class: optional — Required fix: "T = 241 − 뺀 수 + 더한 수, 뺀·더한 단언 이름을 §E.2에 적는다"로 바꾼다.

D14. AC-003-title-and-trace-map — acceptance.md:L69 · L75 · L32, plan.md:L19-20 — AC-003 제목은 "여덟 조합"인데 본문은 "조합은 열 개다". 매트릭스는 AC-014를 REQ-002~011에 대응시키지만 스크립트에 REQ-004(한 턴 다중 호출)를 시험하는 단계가 없고, plan 대응표는 REQ-011→AC-009만 적어 스크립트 13번(REQ-011)을 빠뜨린다. — Severity: minor — Class: optional — Required fix: 제목을 "열 조합"으로, 매트릭스를 "REQ-002·003·005~011"로, plan 대응표에 011→014를 더한다.

D15. AC-sub-criteria-beyond-REQ-text — acceptance.md:L159 · L177 — AC-010 (2)(`chip()` 무변경)와 AC-011 (6) 후반(튜플 타입 반복 감소)은 REQ 본문이 아니라 근거(spec.md:168 · 172)에만 있는 조건을 검사한다. REQ-013 본문의 "no caller reaches" 조건은 반복된 튜플 타입과 무관하다. — Severity: minor — Class: optional — Required fix: 두 조건을 REQ-012·REQ-013 본문의 한 구절로 올리거나, AC에서 "권고"로 낮춘다.

D16. REQ-011-underspecified — spec.md:L164, acceptance.md:L147-150 — "state a true fact about that group"은 어떤 사실이든 만족한다. AC-009는 거짓 문구의 부재와 블록 수만 보고, 스크립트 13번은 "취지"로 판정한다. 트리거 "after a staying recurrence was created"도 그 뒤에 다른 반복이 생긴 경우를 가르지 않는다(`lastRecurrenceId`는 마지막 그룹을 가리킨다, `:1825`·`:1841`). — Severity: minor — Class: optional — Required fix: "shall state that the group has no travel legs to change" 수준으로 좁히고, 트리거를 "while the most recent recurrence (`lastRecurrenceId`) is a staying group"으로 바꾼다.

D17. GEARS-style-nits — spec.md:L152 · L174 — REQ-006은 "Where — D-6" 표지에 Where 절이 없고, REQ-014는 "Before …" 한정절로 시작한다. 린트는 통과한다. — Severity: minor — Class: optional — Required fix: 게이트 뒤 REQ-006을 채택안 하나의 Ubiquitous 문장으로 확정하고, REQ-014를 "When the card is about to leave run, and again when it is about to leave sync, …"로 바꾼다.

D18. frontmatter-nonschema-fields — spec.md:L11 · L15-16 — `related_specs`·`kanban_card`는 스키마의 선택 필드 목록 밖이고, `module: "shared-ui"`는 실제 경로(`Shared/`)가 아니다. SPEC-UIKIT-007과 같은 선례이고 린트가 통과하므로 MP-3 판정에는 영향이 없다. — Severity: minor — Class: optional — Required fix: 프로젝트 관례로 유지한다면 조치 없음. 스키마에 맞추려면 `module: "Shared"`로 바꾼다.

D19. AC-010(3)-color-grep-underinclusive — acceptance.md:L160 — `Color(\|\.secondary\|\.tertiary\|cornerRadius: [0-9]`는 `Color.gray`·`.foregroundColor(.gray)`·`.black`·`.white` 같은 직접 색을 놓치고 양성 대조가 없다(계약 6 점검 명령). — Severity: minor — Class: optional — Required fix: 추가된 줄에서 `Theme\.`을 거치지 않는 색 사용(`Color[.(]`, `\.(gray|black|white|red|blue|green|orange|yellow|primary|secondary|tertiary)\b`)을 찾고, 심은 위반 한 줄로 양성 대조를 돌리게 한다.

D20. REQ-013-dead-path-wording — spec.md:L172 — `resolveOrigin`의 `orDefault: false` 경로는 후보가 **들인** 것이 아니라 **죽게 만든** 것이다. base에서는 `:1323`·`:1486`·`:1612`가 그 경로를 불렀고, 후보가 셋을 `resolveOriginAdoption`으로 옮겨 호출처가 `:2380`(`true`) 하나만 남았다. 같은 REQ가 "resolveOrigin 폴백 사다리를 약화하지 않는다"고도 하므로, 제거 대상이 매개변수 기본값의 false 갈래뿐이고 `orDefault: true` 사다리(집 → 현재 위치, `:2589-2593`)는 남긴다는 점을 적어야 한다. — Severity: minor — Class: optional — Required fix: 근거 문장을 "후보가 호출처를 옮겨 죽게 된 경로"로 고치고 보존 대상을 명시한다.

D21. staying-card-divergent-picks — spec.md:L146 — D-3 (a)로 주입을 고친 뒤 머무는 반복 카드의 두 줄에서 사용자가 **서로 다른** 후보를 고르면 `stayingRecurrence`가 false로 바뀌고, 카드가 묻지 않았던 수단·여유·알림을 `missingAskedArguments`가 요구하며 막는다(`:525`·`:1767`). 조용한 실패는 아니지만 REQ-003은 이 결과를 정하지 않는다. AC-003 조합 10은 같은 후보를 고르므로 해당하지 않는다. — Severity: minor — Class: optional — Required fix: 잔여 위험 한 줄로 기록하거나, 머무는 반복 카드에서 두 줄을 한 줄로 묶는 안을 후속으로 둔다.

D22. compile-warning-count-wording — spec.md:L174 — "the base's 24"는 경고 24건이 아니라 `grep -c 'warning:'` 24줄이다. 실측: 진단 줄 12 + 캐럿 문맥 줄 12(`compile-head.log`), 전부 `DirectionsService.swift`·`LocationManager.swift`의 MapKit·CoreLocation 폐기 경고다. 집합 대조 방법 자체는 유효하다(정규화 후 base·head 동일 확인). — Severity: minor — Class: optional — Required fix: "grep 24줄(진단 12)"로 적는다.

(FAIL 판정 시 이 목록이 수리 경로다. 2회차 감사는 이 목록의 차분과 회귀 점검으로 한정한다. 판정 권한은 감사자에게 있다.)

## 착수 게이트 결정 점검 (D-1~D-10, 요청 항목)

| 결정 | 판정 | 근거 |
|---|---|---|
| D-1 U-2 범위 | 성립 · 경미 | (a)(b)(c)가 모두 구현 가능하고 AC-010·015가 분기를 갖는다. (c)의 처리가 plan·acceptance 사이에서 어긋난다(D11) |
| D-2 판정 술어 | 성립 | 술어 코드(`:2685-2694`)를 따라가면(코드 추적, 미실행): 이름+주소일 때 '강남' 대 `서울 강남구 선릉로100길 1` → 맞음(현행), (a) 이름만 → 안 맞음, (b) 행정구역 예외 → 안 맞음. '홍대'·'테헤란로 152' 회귀 기대(AC-002 (3))도 세 안 각각에서 SPEC의 기대와 일치한다. (c)를 고르면 D4 극성 규칙이 필요하다 |
| D-3 주입 수리 | 성립 · 경미 | 코드 추적으로는 (a)가 §1.3 여덟 조합을 모두 닫는다 — 특히 조합 8(`return_to_query`)은 주입된 값이 `back`을 되살려 `:567` 수단 줄 요구가 사라진다. (c)의 "바뀌는 것"이 불완전(D11). 서로 다른 후보 선택은 D21 |
| D-4 다중 호출 | 성립 | `:790-792` 가드와 `:1034` `lastIndex`가 인용과 일치. (a)에서 AC-004 (1)의 "둘째 호출 레코드 없음"은 `drvPark` 경로에서 원래 참이라 사실상 문구 검사만 남는다(판정은 가능) |
| D-5 보류 뒤 루프 | 성립 · 경미 | (a)의 전제는 미확인이며 깨질 때의 경로가 없다(D10). (c)의 효과 목록 불완전(D11) |
| D-6 후보 노출 | 성립 | `startsOpen`(`EditCard.swift:164`)·씨앗(`EditCardView.swift:68-70`)·주석(`EditCard.swift:160-163`)이 인용과 일치. `grep -c 'startsOpen' Shared/AIAssistant.swift` = 0 |
| D-7 왕복 재확인 | **(b) 결함** | (b)의 전제가 이 트리에서 거짓이다(D5). (a)(c)는 성립 |
| D-8 머무는 반복 | **(a)가 D4를 부른다** | 권장안 (a)는 H-9를 "기록만" 하는데, REQ-001 극성 정의와 REQ-014의 ✗ 0 조건이 함께 설 수 없다(D4). (b)(c)의 Tier·범위 경고는 적절히 적혀 있다 |
| D-9 적용 범위 | 성립 | `:2430-2431`·`:1876-1878`·C11이 인용과 일치 |
| D-10 문안 | **AC 판정 불능** | 채택 문자열이 SPEC 밖에 있고, plan이 말한 AC 신호가 AC-005·008에 없다(D12) |
| (누락) | — | 게이트가 다뤄야 하는데 빠진 결정은 없다고 본다. D2(REQ-008 범위)와 D7(isSamePlace 적용 확대 조정)은 결정이 아니라 작성 수리로 처리할 수 있다 |

## Regression Check (Iteration 2+ only)

1회차라 해당 없음.

## Recommendation

FAIL. 리드와 manager-spec의 몫을 나눈다.

**리드(게이트 전):**
1. D5를 먼저 고치게 한다 — D-7 (b)의 전제가 거짓이라는 사실(`AIAssistant.swift:338-344`)이 선택지에 적히기 전에는 운영자에게 D-7을 묻지 않는다.
2. D-8 (a)를 권장안으로 제시하려면 D4의 극성 규칙이 먼저 들어가야 한다. 그렇지 않으면 권장안이 AC-012 (1)과 충돌한다.
3. 위 둘이 반영되면 D-1~D-10과 Tier M을 `AskUserQuestion`으로 결정하고, 결과를 manager-spec에 넘긴다(D1).

**manager-spec(작성 수리 — 게이트 결과와 같은 개정에 넣을 수 있다):**
1. REQ-008(:158)의 적용 도구를 `create_schedule`·`create_activity`로 좁히고 머무는 반복 신호를 제외한다(D2).
2. REQ-010(:162)의 트리거를 카드(문자열 같음)와 실행부(50 m)로 가른다(D3).
3. REQ-001(:140)에 단언 극성 규칙과 수용 가설의 특성화 단언 표기를 넣고, AC-001 (4)·AC-008 (5)를 맞춘다(D4).
4. D-7 (b)(plan.md:112)의 전제를 사실대로 고치거나 거둔다(D5).
5. AC-003(acceptance.md:80)의 계수 명령과 명명 규칙(:12-13)을 AB-H10과 충돌하지 않게 고친다(D6).
6. REQ-015(:176)·AC-013 (2)(5)에 "대상 제거·재작성" 원장 범주와 수리 전 상태 문장의 `c5396b3` 고정 규칙을 넣고, isSamePlace의 두 번째 사용처(`:1812`)와 `:1869` 주석 교정을 §1.4/§3과 run 범위에 적는다(D7).
7. 렌즈 보고서 두 파일의 버전 관리 여부를 정하고 REQ-013 예외 목록 또는 AC-011 (1) 기준점을 고친다(D8).
8. REQ-015 근거와 AC-013 (1)에 GuardDriver 토큰 계수를 더한다(D9).
9. 게이트 뒤 D-10 채택 문자열을 SPEC 안에 원문으로 적고 AC-005·008에 문자열 신호를 더한다(D12).
10. 선택 결함(D10·D11·D13~D22)은 같은 개정에서 싸게 고칠 수 있는 것(D11·D13·D14)만 권한다. 나머지는 오케스트레이터 재량이다 — 이 목록만으로 FAIL을 만들지 않았다.

2회차는 D1~D9·D12의 차분과, 개정이 새로 만든 REQ·AC 문장의 회귀만 본다.

## 검증 증거 (이 감사가 `e1a40a6` 트리에서 직접 실행)

| 대상 | 명령 | 관측 |
|---|---|---|
| 트리 | `git rev-parse --show-toplevel` · `git branch --show-current` · `git rev-parse --short HEAD` | `…/worktrees/t16` · `WT-place-resolution` · `e1a40a6` |
| 작업 트리 = 후보 | `git diff --stat e1a40a6 -- Shared Tools proxy project.yml` | 무출력 |
| §0 수치 | `git diff --numstat aa7b792 e1a40a6` · `wc -l` · `git show aa7b792:<f> \| wc -l` · `git diff -U0 … \| grep -c '^@@'` | 333/64 · 179/1 · 91/0 / 2753(2484) · 1991(1813) · 528(528) · 350(350) / 35, 첫 헝크 `@@ -494,0 +495,11 @@` |
| REQ·AC | `grep -n '^- \*\*REQ-'` · `grep -n '^## AC-'` | 15(:140~:176) · 15(:42~:213) |
| MP-7 | `grep -rn '\[NEEDS CLARIFICATION' .moai/specs/SPEC-UIKIT-008/` | plan.md :55·:66·:75·:86·:93·:102·:108·:115·:122·:129 |
| D7 | `grep -m1 '^status:'` 네 SPEC | 003·005·007 completed · ASK-001 draft |
| D8 | `grep -c 'syscall'` 네 파일 | 0·0·0·0 |
| 린트 | `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` | `✓ No findings` |
| 함수 좌표 | `grep -n 'func parkForUnclearPlaces\|…'` | `:360`·`:374`·`:445`·`:467`·`:639`·`:687`·`:700`·`:708`·`:720`·`:764`·`:786`·`:819`·`:913`·`:927`·`:1033`·`:1398`·`:1409`·`:2178`·`:2538`·`:2568`·`:2579`·`:2625`·`:2645`·`:2653`·`:2685`·`:2701` — spec·progress와 일치 |
| §1.3 판정 근거 | `awk` `:467-579`·`:786-810`·`:1033-1075`·`:1398-1500`·`:1622-1700`·`:1748-1885` | `:491`·`:493` 빈 값 줄 · `:520`·`:534` unknownPlace만 · `:550` guard · `:556` 왕복 줄 · `:567` 수단 줄 · `:796` 비우기 · `:1050-1051` 재계산 주입 · `:1403` note 필터 · `:1414` statedArgs 비움 · `:1667-1668` 빈 값 비실패 · `:1760` 문구 · `:1812-1830` 머무는 반복 — 여덟 조합 예측과 일치 |
| 수정·조회 경로 | `awk` `:2021-2062`·`:2374-2386`·`:2425-2436`·`:2566-2600`·`:2620-2707` | `:2058` 거짓 문구 · `:2380` 유일 호출(`true`) · `:2430-2431` 첫 결과 · `:2686` 이름+주소 이어 붙이기 |
| 드라이버 | `awk` `GuardDriver.swift` `:28-33`·`:80-100`·`:128-160`·`:1822-1870` · `grep -n 'drvTopMatches("강남"'` | `:31` `✓ \(label)` 형식 · `:88-91` drvAsk가 정화를 탄다 · `:137` 주소 기본값 `""` · `:143`·`:152` · `:1835` 주소 없음 · `:1858-1864` 회사/집 |
| 뷰 | `awk` `EditCardView.swift` `:1-8`·`:62-72`·`:108-136`·`:262-268`·`:314-318` · `EditCard.swift` `:155-168`·`:305-320` · `grep -rn 'EditCardView('` | `:3-5`·`:68-70`·`:116`·`:122-123`·`:132`·`:265`·`:316` · `:160-164`·`:313-315` · 네 화면 :106·:68·:72·:64 |
| 기준선 신호 | `grep -c` 7종 | startsOpen 0 · `guard tool == "create_schedule"` 1 · EditCard 주석 1 · `return_time에 넣어` 1 · 같은 이름 캡션 1 · `미리 정해진 출발지가 맞는지` 1 · 튜플 4/1 · 소문자 타입 0 |
| 무변경 본문 | `sed -n '/<선언>/,/^    }$/p'`를 base와 해시 대조 | sanitizeModelArgs · isSamePlace · executeListSchedules 모두 SAME |
| 인용 계수(REQ-015) | `grep -o 'AIAssistant\(\.swift\)\{0,1\}:[0-9]\{1,4\}' <문서> \| wc -l` | CHECKLIST 14 · plan 4 · 005 spec 6·plan 1·acceptance 0·progress 3 · 007 spec 1·plan 0·progress 0 (일치) |
| GuardDriver 인용 | 같은 명령, `GuardDriver` | CHECKLIST 1(`:619` → `:264`), 나머지 0 · base `:264` setenv / head `:275` |
| 005 좌표 | `git show c5396b3:Shared/AIAssistant.swift` · `git show aa7b792:…` 의 `:748`·`:1297`·`:1613`·`:2322`·`:2371`·`:2393` | c5396b3에서는 여섯 모두 Given의 서술과 일치, aa7b792에서는 여섯 모두 다른 줄 · `grep -c 'confirmedPlaces\[place.name\] = place'` aa7b792 0 · head 0 |
| isSamePlace 호출 | `grep -n 'isSamePlace(origin, dest)\|가드는 create_schedule 경로 전용'` | head `:1492`·`:1812` 호출, `:1869` 주석 / aa7b792 `:1338` 호출, `:1654` 주석 |
| D-7 (b) 전제 | `awk 'NR>=330 && NR<=356'` | `statedArguments`는 mode·buffer·notify만 읽는다 |
| 토큰 방법 | `sed -n '228,234p' plan.md` | `:230` 4,425 · `:231-233` 측정법 |
| 증거 보존 | `git check-ignore -v` 렌즈 보고서·SPEC·감사 보고서 · `git ls-files .moai/reports/` | 셋 다 무시 목록 밖(exit 1) · plan-audit 보고서와 `t16/progress.md`만 추적 |
| plan 게이트 로그 | `grep -E '통과$\|대조 통과' gd-head.log gd-base.log` · 빌드 로그 `grep -c` · 경고 집합 `diff` | 241/241 · 217/217 · 대조 통과 / BUILD SUCCEEDED 1·1, `.swift` 경고 0·0, SwiftCompile 42·38 / 경고 줄 24·24(진단 12 + 문맥 12), 정규화 집합 동일 |

## Gaps (미검증)

- 드라이버·`xcodebuild`·`npm test`는 **실행하지 않았다.** 드라이버·빌드 수치는 `.moai/state/verify/t16-plan/`의 오케스트레이터 로그를 읽은 것이다.
- 렌즈 보고서 두 파일(`.moai/reports/t16/plan-lens-*.md`)은 읽지 않았다. SPEC이 인용한 렌즈 절 번호(A-1 (b)~(g), §2.1 등)가 실제로 그 내용을 담는지는 대조하지 않았다.
- `.moai/reports/day-close-20260924.md` §6·§7, SPEC-UIKIT-003 AC-010, 공용 메모리 항목의 내용 인용은 대조하지 않았다.
- SPEC이 든 인용 토큰을 **전수** 대조하지는 않았다. 주요 절 전부를 대조했고(위 표), 어긋난 것은 없었다. 스크립트 단계의 기대 문구(예: 12번 "한 장소 반복 활동 12건")는 코드 문구(`:1829`)와 모양만 맞춰 보았고 건수 계산은 검증하지 않았다.
- D-5 (a)의 프록시 전제, 카카오 실제 응답, 모델 행동은 이 감사도 관측하지 않았다.
- `mcp__moai__spec_audit`는 주 체크아웃을 읽으므로 쓰지 않았다(오케스트레이터 지시). 린트는 워크트리 CLI로 대신했다.

## Residual-risk (잔여 위험)

- 판정 술어의 정적 규칙은 D-2의 어느 안에서도 표기 차이에 따른 거짓 되묻기·거짓 채택을 남긴다. 브랜드 단일어는 늘 채택된다(spec §3 :194-196이 이미 적음).
- D4의 극성 규칙이 들어가도 특성화 단언은 "현 상태가 계속된다"를 고정할 뿐 사용자 경험을 보증하지 않는다. H-9의 이중 질문은 사람 증거(스크립트 14번)로만 닫힌다.
- AC-013의 원장 방식은 t15에서 두 감사가 모두 0이라 보고했던 실패를 겪었다. 이번 개정이 범주(D7 (a))와 계수(D9)를 보강해도, 맨몸 `:N`의 행 기본 파일 해석은 sync 때 처음 실측된다.

🗿 MoAI
