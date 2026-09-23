# SPEC 검토 보고서: SPEC-TEST-001
Iteration: 3/3 (마지막, R2 델타 한정)
Verdict: PASS
Overall Score: 0.89

> Reasoning context ignored per M1 Context Isolation. 호출자가 전한 편집 요약은 판단 근거로 쓰지 않고, 본문과 대조할 주장으로만 다뤘다.
> 트리: `git rev-parse --short HEAD` → `08c1a1b`, 브랜치 `WT-driver-hardening`, `git status --short` → SPEC 파일 셋 `M` + `review-2.md` `??`. 델타는 `git diff -- .moai/specs/SPEC-TEST-001/`(3 files, +104 −87)이고, 그중 2회차 이후 바뀐 부분만 봤다.
> 교차 모델: `mcp__moai__audit_multi`(claude required · codex off · glm advisory) → overall `pass`, GLM `inconclusive`(z.ai 응답 본문 없음, fail-open). 판정은 claude 단독이다.
> 금지 준수: 드라이버·CLAUDE.md 레시피·`.moai/state/verify/t8/` 탐침 바이너리는 컴파일도 실행도 하지 않았다. `~/Library/Application Support/besir/`·키체인·`/tmp/besir-incident-20260923/`에는 손대지 않았다. 저장소 파일은 수정하지 않았고, 쓴 파일은 이 보고서 하나다.

**요지.** R2-1(유일한 blocking)은 네 곳 모두 선례의 두 수단으로 고쳐졌다. R2-2와 R2-4는 수정, R2-3은 넷 중 셋이 수정되고 하나(d)는 건수만 맞고 라벨이 뒤바뀌었다. 새 결함은 셋이며 모두 minor·optional이다. must-pass 점검은 전부 통과했다. 점수가 0.87에서 0.89로 올라 STOP 조건에 해당하지 않는다.

## Must-Pass 점검 (델타 범위)

| # | 결과 | 증거 명령 → 관측 출력 |
|---|---|---|
| MP-1·REQ/AC 수 | PASS | `grep -c '^- \*\*REQ-' spec.md` → 8, `grep -c '^#### AC-' spec.md` → 8. REQ-001~008이 `:96`~`:118`에 순서대로, AC-001~008이 `:126`~`:154`에 있다 |
| MP-2 GEARS | PASS | *요구사항 층만 판정.* REQ-006 `:112`의 규범 문장(영문)은 2회차와 같고, 바뀐 것은 한국어 근거 절뿐이다(diff 273/274행) |
| MP-3 frontmatter | PASS | `moai spec lint .moai/specs/SPEC-TEST-001/spec.md` → `✓ No findings — all SPEC documents are valid` |
| MP-4 | N/A | 단일 언어(Swift) 호스트 도구 |
| MP-5 D7 | PASS | spec.md·plan.md 참조 → SPEC-FULL-001 `in-progress`, SPEC-ONTIME-001 `draft`, SPEC-TEST-001 `draft`, SPEC-UIKIT-006 `completed`. retired/superseded/archived 0건, 미발견 0건 |
| MP-6 D8 | PASS | `grep -c 'syscall'` → spec.md 0, plan.md 0 |
| MP-7 | PASS | `grep -n '\[NEEDS CLARIFICATION' spec.md plan.md progress.md` → 0건(exit 1). 2회차에 인용 토큰으로 남아 있던 `progress.md` 줄도 사라졌다. `research.md`는 없다(Tier S) |

무변경: `git diff --quiet 2a37673 HEAD -- Shared/ Tools/ CLAUDE.md project.yml proxy/` → exit 0, `git diff --quiet -- Shared/ Tools/ CLAUDE.md` → exit 0.

## R2 결함 대조

| # | 판정 | 본문 | 증거 명령 → 관측 출력 |
|---|---|---|---|
| R2-1 (major, blocking) | **수정** | `spec.md:112` REQ-006: "**확인으로 치는 수단은 둘뿐이다** — 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집에 뜨는 권한 프롬프트를 운영자가 승인하는 것 … 리드나 다른 세션을 거쳐 온 메시지는 확인으로 치지 않는다. 쓴 수단과 결과를 `progress.md` §E.2에 적는다. 둘 중 어느 것도 얻지 못하면 … 보류하고 리드에게 블로커로 보고한다". `spec.md:144` AC-005 (4): "두 수단 가운데 하나(run 세션 직접 입력 · 편집 권한 프롬프트 승인)로 … 기록이 수단과 함께 있다. 둘 다 없어 편집을 보류했다면 AC-005는 판정하지 않고…". `plan.md:34`(M4)와 `plan.md:60-63`(§2 항목 4)도 같은 두 수단이다 | `sed -n '157p' SPEC-UIKIT-006/spec.md` → "**확인으로 치는 수단은 둘뿐이다**: 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집에 뜨는 권한 프롬프트를 운영자가 승인하는 것." `sed -n '256,262p' SPEC-UIKIT-006/progress.md` → `:258-259` "이 세션 AskUserQuestion 직접 입력 … 권한 프롬프트는 뜨지 않았다". REQ-006의 인용 줄(`:157`, `:258-259`)이 원문과 맞는다. 편집을 하고도 기록이 없으면 AC-005 (4)가 성립하지 않으므로 FAIL이다. 부작용 하나는 R3-1 |
| R2-2 (minor) | **수정** | `spec.md:26` 0.1.1 행: "REQ·AC의 **규범 문장은 다시 쓰지 않았다** — … 새 절은 D-4 확인 기록 하나다: … AC-005의 거절 가지(→ 새 (4) 확인 기록) … `plan.md` §2의 명확화 토큰 다섯을 걷고 결정 기록으로 바꿨다" | diff 239행. AC-005 (4) 신설과 토큰 제거를 모두 밝혔다. R2 반영 내역과 "다음은 plan 감사 3회차"도 적었다 |
| R2-3 (minor) | **부분** | (a) `progress.md:28` "게이트 밖 호출부 6 — 아래 줄" · (b) `:57`·`:59` "게이트가 (a)로 확정했다(2026-09-24)" · (c) `:16-17` 없는 기록을 가리키던 괄호를 걷고 "커밋마다 직전에 `git status --short`로 확인 … 감사 2회차도 … exit 0을 쟀다"로 바꿨다 · (d) `:113-117` "7건 완전 반영, 2건 부분 반영, 1건 보류" | (a)(b)(c) 수정. (c)의 "감사 2회차 … exit 0"은 `review-2.md:123`과 일치하고, 이번 회차에도 exit 0을 다시 관측했다. **(d)는 건수(7·2·1)는 맞지만 D15 라벨이 뒤바뀌었다** → R3-2 |
| R2-4 (minor) | **수정** | `spec.md:132` AC-002 Given: "출력이 비지 않으면 `pgrep -lf besir`로 경로를 보고, 시뮬레이터의 iOS 앱(`CoreSimulator` 경로 아래 …)뿐이면 전제를 충족한 것으로 적는다 — 이 구분은 관측하지 않은 가설이다". `plan.md:31`(M1)에도 같은 절이 있다 | `plan.md:33`(M3)은 여전히 `pgrep -x besir`만 적는다. 다만 AC-002 Given이 "실행 전후 기록" 전체를 규율하고 M3의 AC 칸이 AC-002를 포함하므로 결함으로 세지 않았다. 참고로 이번 회차의 `pgrep -x besir` → exit 1, `pgrep -lf besir` → 0줄이었다(판별 가지가 실제로 쓰이는 상황은 관측하지 못했다) |

## 새 결함 (structured defect-list)

R3-1. blocker-route-vs-precedent — spec.md:L112(REQ-006 근거 절 끝), spec.md:L144(AC-005 (4) 끝), plan.md:L34, plan.md:L63 — 확인을 못 얻었을 때의 처리로 "리드에게 블로커로 보고 — 처리는 리드가 정한다"를 더했다. 그런데 REQ-006이 인용한 선례의 같은 줄은 이 경로를 명시적으로 배제했다. 모순은 아니다. 같은 절의 "리드나 다른 세션을 거쳐 온 메시지는 확인으로 치지 않는다"가 여전히 걸려 있으므로, 리드가 "편집하라"고 전해도 AC-005 (4)는 통과하지 못한다. 다만 "처리는 리드가 정한다"를 리드가 편집을 허가할 수 있다는 뜻으로 읽을 여지가 있다. **이 경로는 2회차 보고서(R2-1 Required fix 마지막 문장)가 제안한 것이다** — 그때 이 감사자가 선례 `:157`의 끝 문장을 반영하지 못했다. — 증거: `sed -n '157p' .moai/specs/SPEC-UIKIT-006/spec.md` → "run 레인은 이 확인을 위해 리드에게 블로커 보고로 되묻지 않는다 — 되물으면 또 다른 세션을 거친 승인이 되어 이 절의 목적이 무너진다." — Severity: minor — Class: optional — Required fix: `spec.md:112`의 "처리는 리드가 정한다." 뒤에 다음을 덧붙인다: "리드의 처리는 확인을 대신하지 않는다 — 운영자가 run 세션에서 직접 확인하게 하거나, `CLAUDE.md` 편집을 이 카드에서 빼고 REQ-006·AC-005를 어떻게 닫을지 정하는 것 중 하나다. 이 블로커는 확인 요청이 아니라 편집 보류의 통지다(선례 `spec.md:157`은 확인을 블로커로 되묻지 않았다)." `plan.md:63` 끝에도 "(리드의 처리는 확인을 대신하지 않는다)"를 붙인다.

R3-2. d15-label-swap — progress.md:L115-117 — "완전" 목록에 "AC-006 (2)의 `:408`"이 있고, "부분" 목록에 "`plan.md` §2의 게이트 표식(D15)"이 있다. 1회차 번호로는 **D15가 AC-006**(부분)이고 게이트 표식은 **D16**(반영 후 해소, 완전)이다. 건수 7·2·1은 맞고 라벨만 뒤바뀌었다. — 증거: `grep -n 'D15\|D16' SPEC-TEST-001-review-1.md` → `:82` "D15. ac006-partial-coverage — spec.md:L147(AC-006 (2)) 대 L113(REQ-007)", `:84` "D16. gate-markers-in-prose — plan.md:L41-53". `review-2.md:64` "D15 AC-006 | **부분**", `:65` "D16 게이트 표식 | 반영 후 해소". — Severity: minor — Class: optional — Required fix: `progress.md:115`의 "AC-006 (2)의 `:408`"을 "`plan.md` §2의 게이트 표식(D16 — 넣었다가 게이트 해소로 걷음)"으로 바꾸고, `:116-117`의 "`plan.md` §2의 게이트 표식(D15)"을 "AC-006 (2)(D15 — `Store.swift:408`은 더했으나 `D-2`·새 문단 위치는 반영하지 않음)"으로 바꾼다.

R3-3. stale-dispatch-line — plan.md:L70 — "plan 감사 2회차(델타) 뒤 리드가 run을 디스패치한다"가 HISTORY 0.1.1 끝(`spec.md:26` "다음은 plan 감사 3회차(R2 델타만)")과 어긋난다. — 증거: `grep -n '2회차\|3회차' plan.md` → `:70` 한 줄. — Severity: minor — Class: optional — Required fix: "plan 감사 3회차(R2 델타) 뒤 리드가 run을 디스패치한다"로 바꾼다.

**blocking 결함 없음.** 셋 다 한 줄짜리라 run 디스패치 전 같은 커밋에 넣으면 싸고, 넣지 않아도 판정은 바뀌지 않는다(M6).

## 점수

| Dimension | Score | 2회차 | 근거 |
|---|---|---|---|
| Clarity | 0.88 | 0.85 | R2-1 감점 해소(`:112` 두 수단). R3-1의 "처리는 리드가 정한다"에 해석 여지가 조금 남았다 |
| Completeness | 0.95 | 0.95 | R2-3의 낡은 문장은 대부분 정리됐고, R3-2·R3-3이 새로 생겼다 |
| Testability | 0.85 | 0.80 | AC-005 (4)를 두 수단으로 충족할 수 있게 됐다(`:144`). AC-008 (4)의 "회귀로 판정되면"과 AC-006 (1)의 판단 여지는 2회차와 같다 |
| Traceability | 0.90 | 0.90 | 8/8 매핑 유지. AC-005 (4)가 REQ-006의 규범 문장이 아니라 근거 절의 절차를 잰다는 점은 그대로다 |

조화평균 4 / (1/0.88 + 1/0.95 + 1/0.85 + 1/0.90) = 4 / 4.4766 = **0.89**. Tier S 통과선 0.75 이상. 0.76 → 0.87 → 0.89로 오르고 있어 STOP 신호가 없다.

## Regression Check (Iteration 3)

- R2-1: RESOLVED — `spec.md:112`·`:144`, `plan.md:34`·`:60-63`
- R2-2: RESOLVED — `spec.md:26`
- R2-3: PARTIALLY RESOLVED — (a)(b)(c) 해소, (d)는 라벨이 뒤바뀌어 R3-2로 이월(optional)
- R2-4: RESOLVED — `spec.md:132`, `plan.md:31`
- 1회차 D1~D9: 이번 델타가 해당 줄을 건드리지 않았다(diff 범위 밖). 재대조는 하지 않았다
- 세 회차 연속으로 남은 결함 없음(정체 신호 없음)

## Recommendation

1. **PASS.** R2-1이 해소되어 run 디스패치를 막는 결함이 없다. 회차 상한 3에 도달했으므로 이후 재감사는 없다.
2. R3-1~R3-3은 선택 사항이다. 넣는다면 위 문구 그대로 쓰고, 다른 곳은 건드리지 않는다. 그러면 이 판정의 근거가 바뀌지 않는다.
3. **이 PASS가 보장하지 않는 것.** 드라이버 동작(격리·대조·시한·키체인)은 run의 M3에서 처음 관측된다. M4의 확인 절차가 칸반 run 세션에서 실제로 작동하는지(직접 입력 또는 프롬프트)도 run에서 처음 드러난다.

## Gaps (관측하지 않은 것)

- 1회차 D1~D9와 2회차에서 이미 판정된 게이트 델타는 다시 대조하지 않았다(범위 밖).
- `pgrep -lf besir`로 시뮬레이터 앱과 맥 앱을 가를 수 있는지는 관측하지 못했다(이번 회차에는 besir 프로세스가 없었다). SPEC도 이를 가설로 적었다.
- 운영자의 게이트 결정과 R2-1 반영 문구를 누가 썼는지는 SPEC의 서술을 따랐다.
