# SPEC 검토 보고서: SPEC-UIKIT-007
Iteration: 3/3
Verdict: PASS
Overall Score: 0.90

> 작성자 추론 맥락은 전달되지 않았다(M1 Context Isolation). 호출자가 준 사실 — 게이트 결과(D-1 (a) · D-2 (a) · Tier S, O-1은 카드 아님), 2회차 상태가 `8cbb499`에 커밋됐다는 것, N2를 권고와 다르게 처리했다는 것 — 은 무엇을 볼지 정하는 데만 썼다. 판정은 트리에서 다시 확인한 것으로만 내렸다.
> 범위: `git diff 8cbb499 -- .moai/specs/SPEC-UIKIT-007/`(3파일, +72/−65)의 델타, 그 회귀, must-pass 전 항목 재판정. `Shared/`·`proxy/`·`project.yml`·`CHECKLIST.md`는 `73ceb43`과 같다 — 작업 트리 기준 `git diff --quiet 73ceb43 -- …` exit 0, 커밋 기준 `git diff --quiet 73ceb43 8cbb499 -- …` exit 0.
> 교차 모델: `audit_multi`(claude required · codex off · glm advisory) → overall `approve`. GLM은 세 회차 연속 `inconclusive`(fail-open)라 판정은 claude 단독이다.

**PASS의 근거.** must-pass 일곱 가운데 적용 대상 여섯이 모두 PASS다(MP-4는 N/A). 점수 0.90은 Tier S 통과선 0.75를 넘고, 2회차 0.89에서 내려가지 않았다. 앞 회차 blocking 결함은 모두 해소됐다. 이번에 새로 찾은 항목 중 R1은 blocking이다. 다만 R1은 **이 SPEC의 AC 판정을 바꾸지 않는** 자리 운영 문제라 판정을 막지 않는다(판정은 M6에 따라 must-pass와 점수에 묶인다). 대신 **M3 시뮬레이터 자리 전에 반드시 반영**해야 한다. 문서에 한 문단을 넣는 일이고 REQ·AC는 그대로이므로 재감사는 필요 없다. 반영 여부는 grep 한 번으로 확인할 수 있다.

## Must-Pass Results

- [PASS] **MP-1 REQ 번호**: `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:92)~REQ-008(:110). HISTORY 행이 하나 늘어 한 줄씩 밀렸을 뿐, 연속이고 중복이 없다.
- [PASS] **MP-2 GEARS 형식** — *판정 층위: 요구사항 층(`spec.md` §2 :92-110)만.* 다시 쓴 두 건을 확인했다. REQ-005(:102)는 조건절을 걷고 Unwanted("The change shall not add a second 'the origin is set' check … ; the origin row's `chosen` shall remain the only such truth")가 됐다. REQ-008(:110)은 Event-driven("When the card is about to leave run, … shall carry … ; when Part A lands in outcome (다), the fix commit shall be reverted …")이다. REQ-007(:108)은 Unwanted를 유지했다. 나머지 다섯 건은 바뀌지 않았다. 구성은 Event-driven 3 · State-driven 1 · Where 1 · Ubiquitous 1 · Unwanted 2다.
- [PASS] **MP-3 frontmatter**: 12/12 필드. `version: "0.1.1"`(따옴표 semver)로 올렸고, HISTORY :26에 0.1.1 행이 있다. `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` → `✓ No findings — all SPEC documents are valid`.
- [N/A] **MP-4 언어 중립성**: 단일 언어(Swift) 앱이다.
- [PASS] **MP-5 D7**: 참조 SPEC-UIKIT-002·003·005·006은 모두 `completed`다. 새 참조는 없다.
- [PASS] **MP-6 D8**: `grep -c 'syscall'` → 0·0·0.
- [PASS] **MP-7 명확화 게이트**: `grep -n '\[NEEDS CLARIFICATION' plan.md` → 출력 없음, exit 1. `grep -c 'NEEDS CLARIFICATION' plan.md spec.md progress.md` → 0·0·0. `research.md`는 없다. 결정은 plan.md §2(:42-61)에 결정 사실과 채택하지 않은 안으로 남았다. 운영자의 답은 리드가 전한 것으로 기록돼 있다(:44-46 "이 plan 세션은 운영자의 답을 직접 보지 않았고, 리드의 전달로 기록한다"). 이 감사도 운영자의 답을 직접 보지 않았다 — 아래 Gaps.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.85 | 0.75~1.0 사이 | 조건부 요구사항이 사라졌다(REQ-005 :102, REQ-008 :110, §3.1 머리말 :118, §4 :211-213). N1 해소 — 감사 보고서 예외가 규범 문장에 들어갔다(:108 "with plan-audit reports under `.moai/reports/plan-audit/` excepted"). 남은 것: REQ-007이 run에 연 루트 `plan.md` 범위를 정의하는 말이 셋 흐리다(R2). |
| Completeness | 0.95 | 1.0 대역 | 1·2회차의 유일한 완전성 감점이던 "D-1 (b)면 AC-002 값이 '바뀐다'뿐"이 D-1 (a) 확정으로 사라졌다. 필수 절은 모두 있다(HISTORY :21-26, 배경, 요구사항 :88-110, AC :116-150, `### Out of Scope —` 4개). O-1의 처분도 적혔다(:196, plan.md :58-59). |
| Testability | 0.85 | 0.75~1.0 사이 | N4 해소 — AC-005(:138)에 "(가)의 통과 조건"·"(가)·(나) 공통 통과 조건"·"기록 값"이 따로 적혔다. N3 해소 — AC-002(:126)가 병합이 들어온 경우의 기준을 정했다. 감점: AC-002가 루트 `plan.md` 헝크의 범위를 판정하지 않고 기록만 요구한다(R2-③). ±2분 허용치는 여전히 가정이다. |
| Traceability | 0.95 | 1.0 대역 | AC 헤더(:120-148)와 plan.md:18-19 매핑은 바뀌지 않았고 서로 맞는다. REQ-007에 새로 생긴 절("root `plan.md` limited to … this card's items")은 AC-002의 기록 요구로만 이어진다(R2-③). |

집계: 조화평균 4 / (1/0.85 + 1/0.95 + 1/0.85 + 1/0.95) = 4 / 4.4582 = **0.90**. 2회차(0.89)보다 내려가지 않았으므로 STOP 신호는 없다. Tier S 통과선 0.75 이상이다.

## REQ-007 · AC-002 정합성 판정 (호출자 요청)

**결론: 경로 수준에서는 정합하고, N2 권고와 다르게 처리한 결정도 타당하다.** N2는 optional이었다. 그리고 `CLAUDE.md:23`("작업 시작 전 해당 Day 항목을 읽고, 계획이 실제와 달라지면 **그 자리에서 이 파일을 갱신**한다")은 사용자의 상시 지시라 감사자 권고보다 앞선다. 인용한 줄과 문구는 워크트리 `CLAUDE.md`에서 대조했고 일치한다.

- **정합한 부분.** 세 문서가 같은 경로 경계를 말한다.
  - REQ-007(:108)의 run 경계: `Shared/AddEventView.swift` · SPEC 디렉터리 · 루트 `plan.md`(이 카드 항목의 계획-실제 갱신)
  - AC-002(:126): 첫째 명령의 허용 경로가 같은 셋이고, 그 밖의 경로는 FAIL이다.
  - plan.md §5(:116): 범위 행이 같다.
  - 감사 보고서 예외는 REQ의 규범 문장과 AC의 `':!.moai/reports/plan-audit'` 제외가 같은 말을 한다(N1 해소). 이 예외는 실제로 필요하다 — `8cbb499`가 이미 `.moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md`·`-review-2.md`를 커밋했다(`git show --stat 8cbb499`).
  - "후속 17을 닫는 일은 여전히 sync의 몫"(:108)과 AC-008(1)도 서로 맞는다.
- **흐린 부분 셋(R2, optional).** 경로 경계는 분명한데, 그 안에서 루트 `plan.md`의 **내용 범위**를 정하는 말이 흐리다.
  1. REQ-007 근거가 범위로 든 "§Phase 1.7 표의 t7 행"이 아직 없다. 표(루트 plan.md:423-430)에는 t1·t2·t4·t3·t6·t5 행만 있고, `grep -n 't7' plan.md` → 출력이 없다. 따라서 "갱신"은 사실상 행 추가다.
  2. 후속 14를 "이 카드 항목"으로 들었지만, 같은 SPEC의 두 곳은 그것을 카드 밖이라고 한다 — spec.md:217 "(후속 14 — 같은 화면의 인접 결함, **이 카드 밖**)", plan.md:138 "강등된 항목이라 **건드리지 않는다**". 줄 수가 바뀔 때 후속 14의 `AddEventView` 인용을 옮기는 일(AC-008 (2))만 이 카드 몫이라는 뜻으로 읽힌다. 그렇다면 문장에 그렇게 적는 편이 낫다.
  3. AC-002는 루트 `plan.md`가 나오면 "이 카드 항목만 건드렸는지 `progress.md` §E.2에 적는다"고만 한다. 카드 밖 항목을 건드렸을 때 FAIL인지는 정하지 않는다. REQ-007은 "shall not"인데 그 절의 위반이 AC에서 통과/실패로 이어지지 않는다. 더불어 t6 `27d35a5` 같은 **새 발견 항목 추가**가 "이 카드 항목"에 드는지 — `CLAUDE.md:23`을 들여온 바로 그 경우다 — 도 문장이 말하지 않는다.
- 셋 모두 구현자가 잘못 행동하게 만들 정도는 아니다. run 레인은 건드린 것을 기록하고, 판정은 증거를 읽는 리드의 몫이다(kanban-dispatch § Completion is read). 그래서 optional로 둔다.

## Defects Found (structured defect-list)

R1. sitting-contaminates-SPEC-UIKIT-005-AC-009 — spec.md:L158·L185, plan.md:L35 — D-2 (a)로 확정된 한 자리 순서는 `dd-a`(수정 전 빌드)에서 SPEC-UIKIT-005 AC-009를 먼저 돌린다. 그런데 AC-009에는 **저장된 이동 일정의 출발지를 눈으로 확인하는 단계**가 있다 — SPEC-UIKIT-005 `acceptance.md:241-242`(5번 "그 일정을 탭 → 출발지와 목적지가 주소까지 서로 다른 두 스타벅스다"), `:254`(8번 "만든 일정을 탭 → 출발지·목적지가 주소까지 서로 다르다"), `:263`("그 일정을 탭 → 출발지가 `집`이고 '스타벅스'가 아니다").
- **상세 화면에는 출발지 이름이 없다.** 이 SPEC 스스로 §1.6이 그렇게 적었고, `EventDetailView.swift`에서 이름·주소를 그리는 것은 목적지뿐이다(:172-175). 출발지는 지도의 좌표로만 쓰인다(:40-44·:94·:100).
- **그래서 출발지를 확인하는 자연스러운 길은 편집 시트다.** 그런데 `dd-a`의 편집 시트는 저장된 출발지를 **절대 보여줄 수 없다.** 이것이 이 카드가 고치는 결함 그 자체다(§1.2 — 출발지 줄이 비었다가 5초 안에 현재 위치로 덮이거나, 권한이 없으면 빈 채 남는다).
- 결과적으로 운영자가 `dd-a`에서 AC-009의 그 단계들을 편집 시트로 확인하면, t7의 결함을 t6의 실패로 잘못 셀 수 있다. P0(:158)이 막으려던 "가짜 음성"의 다른 모양이다.
- SPEC-UIKIT-003 AC-010은 해당하지 않는다. 활동 화면에는 같은 결함이 없고(§1.4), 이동 일정은 새 일정 폼(13번)만 연다.
- **코드 읽기 판정이다.** AC-009 테스터가 출발지를 무엇으로 확인할지는 그 AC가 정하지 않았고, 시뮬레이터로 관측하지도 않았다.

— Severity: minor — Class: blocking(이 SPEC의 AC 판정과는 무관하다. M3 자리 전에 반영) — Required fix: §3.2 "함께 돌리기"(:185)와 plan.md M3(:35)에 한 문단을 넣는다. "`dd-a`에는 이 카드의 결함이 살아 있다. SPEC-UIKIT-005 AC-009에서 저장된 일정의 출발지를 확인하는 단계(5·8번과 :263)는 편집 시트로 판정하지 않는다 — 지도의 출발점이나 소요시간으로 판정하거나, 그 단계만 파트 B 뒤에 `dd`에서 확인한다. `dd-a`의 편집 시트에서는 '저장'을 누르지 않는다(현재 위치로 덮어써 저장된다)." 반영 확인: `grep -n 'AC-009' spec.md plan.md`에 이 경고가 찍히는지 본다. 재감사는 필요 없다.

R2. REQ-007-plan-md-scope-wording — spec.md:L108·L126 — 위 "REQ-007 · AC-002 정합성 판정"의 ①~③. — Severity: minor — Class: optional — Required fix: REQ-007 근거를 "이 카드 항목 = 후속 17, 이 카드가 run 중 새로 발견한 항목(추가), §Phase 1.7 표의 t7 행(없으면 추가), 그리고 줄 수가 바뀐 경우 후속 14·17의 `AddEventView` 인용"으로 고친다. AC-002의 괄호에 "이 카드 항목 밖의 헝크가 하나라도 있으면 FAIL"을 더한다. run 디스패치에 적어 넘겨도 된다.

## Regression Check (Iteration 2+ only)

2회차 결함 목록(`SPEC-UIKIT-007-review-2.md`):

- D1 (MP-7 게이트 표식 3건): **RESOLVED** — `grep -n '\[NEEDS CLARIFICATION' plan.md` exit 1. 결정은 plan.md §2(:42-61)에 결정 사실·채택하지 않은 안·출처(리드 전달)와 함께 기록됐다. 권고한 후속 편집도 모두 이루어졌다 — REQ-005 무조건형(:102), REQ-008 D-2 의존 제거(:110), §3.1 머리말(:118), §4(:211-213), AC-001의 "확정된 D-1 (a)"(:122). D-1 (b) 분기 문구는 남아 있지 않다.
- N1 (감사 보고서 예외가 비규범 꼬리에만): **RESOLVED** — :108 규범 문장에 들어갔다.
- N2 (run 중 루트 `plan.md` 갱신과 AC-002): **RESOLVED — 권고와 다른 방식, 수용.** run에 루트 `plan.md`를 열었다(:108·:126, plan.md:116). 정합성 판정은 위 절에 있고, 흐린 말은 R2로 넘겼다.
- N3 (고정 기준 `73ceb43`과 병합): **RESOLVED** — :126 "카드 브랜치에 병합이 들어오면 `git merge-base origin/master HEAD`가 찍는 커밋을 기준으로 대조하고, 그 사실과 SHA를 `progress.md` §E.2에 적는다". plan.md:116도 같다.
- N4 (AC-005 조건과 기록 값): **RESOLVED** — :138. (가)로 분류됐는데 조건이 깨지면 FAIL이고 리드에게 보고한다는 처리까지 적혔다.
- N5 (progress.md 자기참조 기록): **RESOLVED** — 표식 계수 줄에서 패턴 문자열을 뺐다. `8cbb499`에서는 1이었다는 정정도 남겼다(progress.md:136-138). 이 감사가 다시 센 값도 0·0·0으로 기록과 같다. :38의 "추적 대상"은 "무시 목록 밖 — `.gitignore`에 없어 커밋하면 diff에 잡힌다"로 고쳐졌다.

1회차 결함(`-review-1.md`)의 회귀:
- D2~D9·D11~D13은 이번 델타로 되돌아간 것이 없다. REQ 번호 001~008 유지, AC 헤더와 매핑표 무변경, N₀·두 형태 칩·`약 Z분`(±2분)·AC-003 기계 신호의 본문은 diff에서 건드리지 않았다.
- D10(부분, 수용)·D14(plan.md §4로 이관)·D15(유지)는 그대로다.

정체 판정: 세 회차 연속 무변경인 결함은 없다. D1은 이번 회차에 해소됐다.

## Recommendation

**PASS.** must-pass 근거:
- MP-1 — REQ-001~008이 연속이다(:92-110).
- MP-2 — 요구사항 8건이 모두 GEARS 문형이다. 다시 쓴 REQ-005·REQ-008 포함.
- MP-3 — 12/12 필드, `version: "0.1.1"`, lint 통과.
- MP-5 — 참조 넷이 모두 `completed`다.
- MP-6 — syscall 0건.
- MP-7 — 게이트 표식이 plan.md·spec.md·progress.md에서 모두 0건이다.

run 디스패치 전에 할 일:
1. **R1(blocking, 자리 운영).** M3의 한 자리가 시작되기 전에 §3.2 "함께 돌리기"와 plan.md M3에 `dd-a` 경고 한 문단을 넣는다. manager-spec이 문서만 고치거나 리드가 run 디스패치에 적어 넘긴다. REQ·AC가 그대로라 재감사는 필요 없다.
2. **R2(optional).** REQ-007 근거의 "이 카드 항목" 정의와 AC-002의 FAIL 조건. 같은 편집에서 처리하거나 run 레인에 맡긴다.
3. 3회차가 상한이다. 이 판정은 PASS이므로 retry 루프는 여기서 끝난다.

## 검증 증거 (이 회차에 직접 돌린 명령)

| 주장 | 명령 | 관측 |
|---|---|---|
| 기준·델타 | `git log --format='%h %s' -4` · `git status --short` · `git diff --stat 8cbb499 -- .moai/specs/SPEC-UIKIT-007/` | HEAD `8cbb499` · SPEC 3파일 `M` · 3 files, +72/−65 |
| 8cbb499 내용 | `git show --stat 8cbb499` | SPEC 3파일 + `SPEC-UIKIT-007-review-1.md`·`-review-2.md` |
| 소스 무변경 | `git diff --quiet 73ceb43 -- Shared/ proxy/ project.yml CHECKLIST.md` · `git diff --quiet 73ceb43 8cbb499 -- …` | exit 0 · exit 0 |
| MP-1·헤더 | `grep -n '^- \*\*REQ-' spec.md` · `grep -n '^#### AC-' spec.md` | REQ-001~008(:92-110) · AC-001~008(:120-148), 헤더의 REQ 목록 무변경 |
| MP-3 | `moai spec lint …/spec.md` · frontmatter `version`·`updated`·`status` | `✓ No findings` · `"0.1.1"`·`"2026-09-23"`·`draft` |
| MP-7 | `grep -n '\[NEEDS CLARIFICATION' plan.md` · `grep -c 'NEEDS CLARIFICATION' plan.md spec.md progress.md` | exit 1 · 0·0·0 |
| MP-5·MP-6 | 참조 추출 + `status:` · `grep -c 'syscall'` | 002·003·005·006 `completed` · 0·0·0 |
| `CLAUDE.md:23` | `awk 'NR>=20 && NR<=26' CLAUDE.md` | :23 "…계획이 실제와 달라지면 **그 자리에서 이 파일을 갱신**한다." 일치 |
| R2-① | `grep -n 't7' plan.md` · Phase 1.7 표 | 출력 없음 · :423-430에 t1·t2·t4·t3·t6·t5 |
| R2-② | `grep -n '후속 14' spec.md plan.md` | spec.md:217 "이 카드 밖" · plan.md:138 "건드리지 않는다" · spec.md:108 "이 카드 항목(후속 14·17 …)" |
| R1 | `grep -n 'address\|\.name\|origin' Shared/EventDetailView.swift` · SPEC-UIKIT-005 `acceptance.md` AC-009(:218~) · SPEC-UIKIT-003 `acceptance.md` AC-010 | 상세는 목적지 이름·주소만(:172-175), 출발지는 좌표(:40-44) · AC-009 :241-242·:254·:263이 저장된 출발지를 확인 · AC-010은 활동과 새 일정 폼뿐 |
| 기반 커밋 | `git merge-base --is-ancestor d5203cb 73ceb43` · `… 84328e3 73ceb43` | 둘 다 exit 0(t3·t6 수정이 `dd-a`에 들어 있음) |
| 교차 모델 | `mcp__moai__audit_multi` | overall `approve`, glm `inconclusive`(fail-open) |

**미검증(Gaps).**
- 운영자의 게이트 결정은 직접 보지 않았다. SPEC이 "리드 전달"로 기록한 것을 확인했을 뿐이고, MP-7은 산출물의 표식만 본다.
- R1은 코드 읽기 판정이다 — AC-009 테스터가 출발지를 무엇으로 볼지는 그 AC가 정하지 않았다.
- 빌드·`npm test`·시뮬레이터·가드 드라이버는 금지 조건대로 돌리지 않았다.

**잔여 위험.**
- 파트 A가 (다)로 나올 가능성은 REQ-008이 처리한다.
- ±2분 허용치는 실측값이 아니다.
- 결함의 존재는 여전히 코드 읽기와 이력 대조로만 뒷받침되며, 첫 관측은 파트 A다.
- GLM이 세 회차 모두 응답하지 않아 전 회차가 단일 모델 판정이다.
