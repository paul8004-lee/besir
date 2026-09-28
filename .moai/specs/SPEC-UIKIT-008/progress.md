# SPEC-UIKIT-008 — progress.md

칸반 카드 t16 · C7 장소 해석 UX. 2026-09-26 plan 레인이 시작했다. 워크트리는 `.claude/worktrees/t16`(branch `WT-place-resolution`),
base `aa7b792`(= `origin/master`), HEAD `e1a40a6`(이전 세션의 미커밋 후보 구현을 보존한 WIP 체크포인트).

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **resolved 2026-09-26** — 운영자가 정했고 칸반 리드가 이 plan 세션에 전했다. **이 세션은 운영자의 답을 직접 보지 않았다** — 아래 목록은 리드의 전달이다.
  채택: D-1 (a) U-2를 이 카드에 넣고 편집기가 열린 동안 강조를 끄며 "지금 고른 곳" 캡션 · D-2 (a) 판정 술어는 이름만 본다 · D-3 (a) 후보 카드가 비운 키를 기록하고 확인 때 그 키에 싣는다 ·
  D-4 (a) 카드는 첫 모호 호출에만, 뒤 호출에는 사실대로 · D-5 (a) 후보 카드가 서면 턴을 끝낸다 · D-6 (a) 카드가 뜰 때 후보 줄 편집기를 연다 · D-7 (a) 왕복이면 늘 묻는다 ·
  D-8 운영자 자신의 문구(아래 원문) · D-9 (a) 등록 경로 셋만 · D-10 (a) 제안 문안 원문 그대로 · Tier M 유지. 반영 자리는 `plan.md` §2 표다.
- d8_interpretations: **confirmed 2026-09-26** — 운영자의 답을 칸반 리드가 전했다(**이 세션은 직접 보지 않았다**). I-1·I-2는 적은 대로, I-3은 **거부**("한 번짜리 활동까지"),
  I-4는 운영자 문구, I-5 (a) · I-6 (a). 번역 규칙이 계약·파일 한도에 걸리는 곳의 경계 B-1~B-3과 한 번짜리 판정 범위 T-1은 0.1.4에서 리드 확인 포인트로 적었고 0.1.5에서 해소됐다(다음 줄).
- boundaries: **resolved 2026-09-26** — B-1·B-2는 운영자 결정(칸반 리드 전달, **이 세션은 직접 보지 않았다**): 분리(a) — 0.1.4 경계 동작(한 번짜리 편도, 끝 시각 문장 되묻기)을
  **중간 동작**으로 유지하고 완전한 동작은 후속 카드 **t30**(C21 AI 카드 문법 통일)으로 이관. T-1·B-3은 **리드에게 확인용으로 제시 — 명시 답변 없음, 이의 없음**. 파일 4개·Tier M 유지.
- (게이트 전 기록) kickoff_gate: pending — `plan.md` §2의 결정 10건(D-1~D-10)과 Tier M 확인이 남아 있었다. 그 신호가 연 다음 단계는 run 착수가 아니라 착수 승인 게이트였다.
- **부류 재분류.** 후보의 자기 기록 `.moai/reports/t16/progress.md:6`은 "부류: Class B(SPEC 없음, plan 건너뜀)"이다. 운영자가 **Class C(plan → run → sync)**로 바꿨고
  리드가 전했다. 그 파일은 고치지 않았다(`git diff --quiet e1a40a6 -- .moai/reports/t16/progress.md` — 이 레인은 그 경로에 쓰지 않았다). 정정은 이 줄이 맡는다.
- **운영자 결정 (a), 리드 전달**: 이 트리를 유지하고 diff를 보존(`e1a40a6`)하며, SPEC은 diff를 **후보 구현**으로 다룬다. U-2 범위는 SPEC이 권고하고 운영자가 게이트에서 정한다(D-1) — 게이트에서 D-1 (a)(이 카드에 넣는다)로 정해졌다.
- 산출물: `spec.md` · `plan.md` · `acceptance.md` · `progress.md`(이 파일). Tier M의 세 파일 + 진행 기록이다.
- 작성 주체: 네 파일 모두 `manager-spec`(서브에이전트)이 썼다. 이 SPEC 디렉터리 밖에는 쓰지 않았고, 빌드·드라이버·커밋을 하지 않았다(오케스트레이터 지시).
- 신호 줄(`plan_complete_at`·`plan_status`)은 이 레인이 적지 않는다 — plan 감사 뒤 오케스트레이터가 §F.1 뒤에 붙인다.

### 0.1.1 개정 — plan 감사 1회차 반영 (2026-09-26)

- 입력: `.moai/reports/plan-audit/SPEC-UIKIT-008-review-1.md`(FAIL 0.77). 고친 결함 번호와 자리는 `spec.md` HISTORY 0.1.1 행에 있다. 코드와 이 SPEC 밖 파일은 무변경이고,
  REQ 15 · AC 15 · 게이트 표식 10건(MP-7 — 리드가 게이트에서 푼다)은 그대로다.
- **D8 — 오케스트레이터 결정(이 레인의 결정이 아니다).** 렌즈 보고서 둘(`.moai/reports/t16/plan-lens-ai-tooling.md`·`plan-lens-ui-design.md`)은 **이 SPEC이 절 번호로 인용하는
  연구 입력**이라 plan 커밋에 이 SPEC 디렉터리·plan 감사 보고서(`.moai/reports/plan-audit/SPEC-UIKIT-008-*`)와 함께 넣는다. 워크트리를 폐기해도 연구 입력이 남게 하기 위해서다.
  그래서 REQ-013 예외 목록에 넣었고, AC-011 (1)은 `e1a40a6` 기준으로 이 plan 단계 경로를 뺀 뒤 판정한다.
- **추적되지 않는 빌드 로그.** 워크트리 루트의 `build-ios.log`·`build-mac.log`는 이전 세션이 남긴 것이고 `.gitignore`에 없으며(`git check-ignore -v build-ios.log` exit 1)
  **커밋하지 않는다**(오케스트레이터 지시). 모든 범위 AC는 커밋끼리 비교하므로(`git diff <커밋> HEAD`) 이 파일들에 걸리지 않고, `git status`를 판정에 쓰는 AC는 없다.
- **부류 재분류(Class B → C)**는 위 줄 그대로다. 이전 기록 `.moai/reports/t16/progress.md`는 이번 개정에서도 쓰지 않았다.

| 개정 때 이 레인이 돌린 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `grep -n 'private static func statedArguments' Shared/AIAssistant.swift` · `awk 'NR>=330 && NR<=358'` | `:338` 선언, 본문이 `mode_this_time`·`buffer_minutes`·`notify_lead_minutes` 셋만 읽는다(`:339-342`) | D5 — `plan.md` D-7 (b) 거둠 |
| `grep -n 'isSamePlace(origin, dest)\|가드는 create_schedule 경로 전용' Shared/AIAssistant.swift` | `:1492` · `:1812` · `:1869` | D7 — spec §1.4·§3, REQ-010 |
| `git show c5396b3:Shared/AIAssistant.swift \| sed -n '748p;1297p;1613p'` · `grep -c 'confirmedPlaces\[place.name\] = place'`(aa7b792 / head) | `confirmedPlaces[place.name] = place` · `if Self.isSamePlace(origin, dest) {` · 전용 주석 / `0` · `0` | D7 — REQ-015 base 고정 규칙 |
| `sed -n '133,139p' .moai/specs/SPEC-UIKIT-005/acceptance.md` · `sed -n '234,242p' .moai/specs/SPEC-UIKIT-005/spec.md` | AC-005 Given의 여섯 좌표 · §3 "넓히지 않는다"(`:237`) | D7 |
| `grep -o 'GuardDriver\(\.swift\)\{0,1\}:[0-9]\{1,4\}' CHECKLIST.md plan.md <005·007 문서> \| sort \| uniq -c` · `grep -n 'setenv("CFFIXED_USER_HOME"' Tools/GuardDriver.swift`(head / base) | `1 CHECKLIST.md:GuardDriver.swift:264`(`:619`) · head `:275` / base `:264` | D9 — REQ-015·AC-013 (1) |
| `grep -c 'warning:' compile-head.log` · `grep 'warning:' compile-head.log \| grep -c '^/'` | `24` · `12`(진단 12 + 캐럿 문맥 12) | D22 — REQ-014·AC-012 (2) |
| `git show aa7b792:Shared/AIAssistant.swift \| grep -n 'resolveOrigin('` · `awk 'NR>=2579 && NR<=2600'` | base 호출 `:1323`·`:1486`·`:1612`(기본값)·`:2162`(`true`) · head 사다리 `:2589-2593` | D20 — REQ-013 |
| `grep -n 'missingAskedArguments(tool: "create_recurring_schedule"' Shared/AIAssistant.swift` | `:1767` | D21 — `plan.md` §3 |
| AC 명령 모의 실행: `printf '+ .foregroundStyle(.gray)\n+ .foregroundStyle(Theme.muted)\n…' \| grep -v 'Theme\.' \| grep -cE '…'` · 주석 줄 걸러내기 · `printf '  ✓ AB-H01 x\n  ✓ AB-H10 y\n' \| grep -c '✓ AB-H01'` · `grep -c '✓ AB-H[0-9][0-9] \[수용\]'` | `1`(심은 한 줄만) · `+    var x = 1`만 남음 · `1` · `1` | AC-010 (3) 양성 대조 · AC-011 (1) · AC-001 (5)·AC-003 |
| 새 문자열 신호의 후보 트리 기준값 `grep -c`: `이동 없이 한 곳에서` · `첫 검색 결과가 말씀하신` · `가드는 create_schedule 경로 전용` · `에서 출발하는지 한 번 더 골라 주세요` · (EditCardView) `새로 고르지 않으면 그대로예요` | `0` · `1` · `1` · `0` · `0` | AC-005 (5)·AC-007 (2)·AC-008 (2)(6)·AC-010 (3) |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -c 'NEEDS CLARIFICATION' plan.md` · `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` | `15` · `15` · `10` · `✓ No findings` | §0 예산 · MP-7 표식 유지 |

### 0.1.3 개정 — 착수 승인 게이트 반영 (2026-09-26)

- 입력: 리드가 전한 게이트 결과(위 kickoff_gate 줄). `plan.md` §2의 게이트 표식 10건을 채택 사실로 바꾸고, 채택하지 않은 안은 `plan.md` §2 "결정 기록"에만 남겼다.
  REQ·AC·스크립트의 분기를 모두 걷어 AC마다 기대값이 하나다. 고친 REQ와 AC는 `spec.md` HISTORY 0.1.3 행에 있다. 코드와 이 SPEC 밖 파일은 무변경이다.
- **D-8 운영자 문구(리드 전달 원문, 두 번째 제출이 확정본)**:
  "집에서 점심식사와 같은 일정은 활동 블록으로 생성. 따라서 가는 편 오는 편 이동일정을 선택하지 않은 활동 일정이 되어 해당 사항을 되물어야 함." +
  "집에서 점심식사라 하더라도 현재 위치가 집이 아닌 다른 곳이면 출발지 = 목적지라 확정할 수 없음. 따라서 출발지 또한 물어봐야 함."
  리드 종합: 머무는 요청은 활동 블록이 되지만 출발지 = 목적지는 조용히 가정하거나 확정하지 않는다 — 카드가 출발지를 묻고(또는 명시적 "이동 없음" 선택지를 주고) 사용자의
  선택만이 그것을 확정한다. 후보의 현재 동작(같은 값이면 출발지를 묻지 않고 줄을 억제하며 이동 구간을 만들지 않는다)은 결함 H-11로 적었다(REQ-001·AC-001, 스크립트 12·14).

#### D-8 번역의 해석 — **확인됨 (2026-09-26, 리드 전달 — 이 세션은 운영자의 답을 직접 보지 않았다)**

0.1.3에서 이 레인이 고른 해석을 리드 확인 대상으로 적었고, 운영자가 아래처럼 답했다. 반영은 0.1.4(아래)다.

| 해석 | 0.1.3에 적은 해석 | 운영자의 답 | 0.1.4 반영 자리 |
|---|---|---|---|
| **I-1** 수단·여유·알림을 언제 받나 | 같은 값 카드에서는 묻지 않고, 다른 출발지를 고르면 `missingAskedArguments`로 멈춘 뒤 모델 재호출의 두 번째 카드가 묻는다. 기본값으로 채우지 않는다 | **확정**(적은 대로) | REQ-010 · AC-008 (4)(5) · 스크립트 14·16 |
| **I-2** "이동 없음" 선택지 | 출발지 줄에 새로 생기는 칩. 내부 토큰으로 실려 선언 키는 늘지 않는다 | **확정**(적은 대로) | REQ-010 · AC-008 (2)(3)(5) · AC-003 5·10번 · 스크립트 3·12·16 |
| **I-3** 적용 범위 | 반복 도구에만 건다 | **거부** — "한 번짜리 활동까지" | REQ-010(머무는 요청) · REQ-008 · H-11 · AC-006 (5) · AC-008 (5) · 스크립트 3·16 · spec §3·`plan.md` §6에서 범위 밖 항목 삭제 |
| **I-4** 다른 출발지를 고른 반복 | 통근 경로, 끝 시각이 없으면 가는 구간만 | **운영자 문구**: "끝 시각 없는 경우에는 되물어서 활동일정 생성. 기본적으로 반복 일정이더라도 단일 일정과 같은 프로세스. 반복 된다는 점만 차이가 있는 것." | "가는 구간만" 갈래 삭제 · 끝 시각 선행(REQ-010 · AC-008 (7) · 스크립트 15) · "반복도 단일과 같은 절차"를 I-3 확장의 번역 규칙으로 |
| **I-5** 기간 이중 질문(H-9) | 잔여 위험으로 수용 — `AB-H09 [수용]` | **(a)** 적은 대로 | REQ-001 · AC-001 (5) · AC-008 (8) |
| **I-6** 출발지 줄 캡션 | `'Y'에서 출발하는지 골라 주세요. 이동이 필요 없으면 '이동 없음'을 고르면 돼요.` | **(a)** 원문 그대로 | `plan.md` §2 D-10 표 · AC-008 (2)(5) · 스크립트 12·16 |

- **따라 바뀐 계약 하나(I-2의 결과)**: 머무는 반복은 출발지 선택을 거쳐서만 실행부에 닿으므로, 두 키가 같은 모호한 질의로 실행부에 오는 상태는 카드로 닿지 않는다.
  REQ-003의 머무는 반복 조합을 "출발지 `이동 없음` 뒤 목적지 모호"로 바꿨고(AC-003 10번), 두 키 상태는 드라이버 직접 호출 전용 잔여 위험으로 `plan.md` §3에 적었다.
- **D-5 (a)의 전제는 여전히 미확인이다**(아래 Gaps). 깨지면 run이 블로커를 돌려주고 리드가 D-5를 다시 묻는다(REQ-005).

| 0.1.3 개정 때 이 레인이 돌린 명령(HEAD `d0a2c60` = 0.1.2 커밋) | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git diff --quiet e1a40a6 -- Shared Tools proxy project.yml; echo $?` | `0` — 코드는 후보 커밋 그대로 | 줄번호 기준 |
| `awk 'NR==285\|\|NR==291' Shared/AIAssistant.swift` · `grep -n 'repairDanglingToolTurn' Shared/AIAssistant.swift` | `:285 cancelPendingAsk()` · `:291 for (k, v) in Self.statedArguments(from: text)` · 호출 `:164`·`:292`, 선언 `:198` | `plan.md` §2 D-5 — 인용을 `:292`로 바로잡았다 |
| `awk 'NR==1767\|\|NR==1848\|\|NR==1864' Shared/AIAssistant.swift` | `missingAskedArguments(tool: "create_recurring_schedule"` · `// 2) 복귀(귀가) 구간 …` · `activityCount += activityLeg` | I-1 · I-4 |
| `awk 'NR>=1888 && NR<=1890' Tools/GuardDriver.swift` | `AA-4: 출발지=목적지 반복은 기간 줄만 묻는다…` · `Set(…) == ["weeks"]` | AC-008 (1) — 새 계약과 맞서는 단언 |
| 새 문자열 신호의 후보 트리 기준값 `grep -c`: `이동 없음` · `'이동 없음'을 고르면 돼요` · (EditCardView) `지금 고른 곳` · `이동 없이 한 곳에서` | `0` · `0` · `0` · `0` | I-2 · AC-008 (2) · AC-010 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -c 'NEEDS CLARIFICATION' plan.md` | `15` · `15` · `0` | `plan.md` §0 예산 · 게이트 표식 해소 |

### 0.1.4 개정 — D-8 해석 확인 반영 (2026-09-26)

- 입력: 리드가 전한 운영자의 답(위 d8_interpretations 줄과 표). 커밋된 기준은 `d3a304d`(0.1.3). 코드와 이 SPEC 밖 파일은 무변경이고, 고친 곳은 `spec.md` HISTORY 0.1.4 행에 있다. REQ 15 · AC 15 그대로다.
- **번역 규칙**: I-4 운영자 문구의 "반복 일정이더라도 단일 일정과 같은 프로세스"를 I-3 확장에 그대로 썼다 — 두 도구가 같은 것을 같은 방식으로 묻는다: 끝 시각(없으면 먼저) → 출발지 줄(이동 없음,
  미리 선택 없음) → 다른 출발지를 고르면 이동수단·도착 여유·알림. 선언된 run 파일 집합(`Shared/AIAssistant.swift`·`Tools/GuardDriver.swift`·`Shared/EditCardView.swift`·`Shared/EditCard.swift` 주석 한 줄)은 넓히지 않았다.

#### 그은 경계와 고른 판정 — 0.1.4에 리드 확인 포인트로 적은 표(해소는 아래 0.1.5 개정)

| 번호 | 무엇 | 왜 여기서 멈췄나 | 걸린 자리 |
|---|---|---|---|
| **T-1** 한 번짜리 머무는 요청의 판정 | `place_query`가 있고 `return_to_query`가 없으며 `travel_from_query`가 비었거나 `place_query`와 같은 값인 `create_activity`. 모델이 값을 보내지 않았으면 출발지 줄에 캡션을 달지 않는다(평범한 부재 줄의 관례 `:558-560`) | 운영자 문구의 "가는 편 오는 편 이동일정을 선택하지 않은 활동 일정"을 호출 인자로 옮긴 모양이다. 편도(`travel_from_query`가 다른 값)·왕복(`return_to_query` 있음)·장소 없는 활동은 이미 이동을 정했거나 이동이 성립하지 않아 뺐다 | REQ-010 · AC-008 (5) · 스크립트 3·16 |
| **B-1** 오는 편의 비대칭 | 다른 출발지를 고른 뒤 반복은 오는 구간을 만들고(통근 경로, `:1848-1864`) 한 번짜리는 만들지 않는다(편도 경로) — 묻는 것은 같다 | 같게 하려면 (가) 두 도구가 오는 편을 따로 묻는다 — 반복 선언에 오는 편 도착지 키가 없어 선언이 바뀐다(REQ-013, AC-011 (4)) — 또는 (나) 한 번짜리가 고른 출발지로 돌아오는 구간까지 만든다 — 왕복 재확인(REQ-009)이 두 번째 카드에서 방금 고른 출발지를 다시 묻고, 그 예외에는 카드 선택을 기억하는 새 상태가 든다 | REQ-010 · AC-008 (4)(5) · 스크립트 14·16 |
| **B-2** 끝 시각은 되묻는 문장으로 | 카드 줄이 아니라 모델이 사용자에게 묻는다. 도구 결과는 모델이 채우라고 권하지 않는다 | 시각 줄은 `EditField` 해석·`EditCardView` 편집기 변경이라 `EditCard.swift` 주석 한 줄을 넘는다. 한 번짜리 경로도 이미 이렇다(`:1264` `end_iso` 필수, 빠지면 `:1610` 문구) | REQ-010 · AC-008 (7) · spec §3 |
| **B-3** 끝 시각을 출발지보다 먼저 | 머무는 요청에 끝 시각이 없으면 카드를 띄우지 않고 먼저 받는다 | 출발지를 실제 장소로 바꾼 반복 호출은 끝 시각이 선택인 통근 호출과 인자로 구별되지 않는다 — 머무는 신호가 보일 때 받아야 "가는 구간만" 등록이 생기지 않는다 | REQ-010 · AC-008 (7) · 스크립트 15 |

- **새로 맞서게 된 드라이버 단언**: O-6 첫 단언(`Tools/GuardDriver.swift:1595-1597`, 이동 없는 활동의 기대 키 `["place_query"]`)이 AA-4 첫 단언과 같은 이유로 새 계약과 맞선다 — 빼고 `AB-H11`로 대신한다(AC-008 (5), AC-012 (1)).
- **잔여 위험 둘**: 이동을 말하지 않은 한 번짜리 활동마다 카드가 선다(운영자가 고른 동작, 식사 기록 활동 포함) · `create_activity` 선언이 `end_iso`를 요구해 모델이 묻지 않고 지어낼 수 있다(`plan.md` §3).

| 0.1.4 개정 때 이 레인이 돌린 명령(HEAD `d3a304d` = 0.1.3 커밋) | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git diff --quiet e1a40a6 -- Shared Tools proxy project.yml; echo $?` | `0` | 줄번호 기준 |
| `awk 'NR==549\|\|NR==550' Shared/AIAssistant.swift` · `awk 'NR>=558 && NR<=560'` | `let outbound = filled("travel_from_query"), back = filled("return_to_query")` · `guard outbound \|\| back else { break }` · 부재 줄 캡션 관례 주석과 `f.note` | H-11 · T-1 |
| `awk 'NR==1264\|\|NR==1610\|\|NR==1624' Shared/AIAssistant.swift` | `"required": ["title", "start_iso", "end_iso"]` · `"활동 정보가 부족합니다. 제목과 시작·종료 시각을 다시 확인해 주세요."` · `missingAskedArguments(tool: "create_activity"` | B-2 · AC-008 (5)(7) |
| `awk 'NR>=1595 && NR<=1596' Tools/GuardDriver.swift` | `O-6: 이동 없는 활동도 못 푸는 장소면 활동 장소 줄이 뜬다(이동 줄은 그대로 없다)` · `== ["place_query"]` | AC-008 (5) — 새 계약과 맞서는 단언 |
| `grep -n 'drvExecuteTool("create_activity"' Tools/GuardDriver.swift` 후 각 호출 열람 | `:1221`·`:1227`(장소 없음) · `:1390`·`:1404`(이동 있음) — 머무는 요청 판정에 걸리지 않는다 | T-1 영향 범위 |

### 0.1.5 개정 — 경계 해소: 분리 (2026-09-26)

- 입력: 리드가 전한 운영자 결정 두 번. (1) B-1은 나열한 안이 아니라 운영자 문구(단일·반복 AI 카드에 활동 추가 카드와 같은 가는/오는 이동 생성 줄, 반복이라는 점만 차이), B-2는 (b) 카드 시각 줄.
  (2) 그 비용 측정(아래)을 본 뒤 **분리(a)**. 두 번 모두 이 세션은 운영자의 답을 직접 보지 않았다. 운영자 원문은 후속 카드 t30 본문에 있고, 이 SPEC은 카드 번호와 한 줄 요약만 둔다.
- 기준 `d8d68db`(0.1.4). REQ-010·AC-008·스크립트의 계약은 바꾸지 않았고, 경계를 적은 근거 문장만 해소로 바꿨다. spec §3에 t30 범위 밖 절, `plan.md` §6에 t30, `plan.md` §3에 잔여 위험(문장 되묻기 = AC-009 7번 실패와 같은 모양)을 더했다.

| 번호 | 해소 | 근거 |
|---|---|---|
| **T-1** 한 번짜리 머무는 요청의 판정 | 0.1.4 그대로 | 리드에게 확인용으로 제시 — 명시 답변 없음, 이의 없음 |
| **B-1** 오는 편의 비대칭 | 편도를 **중간 동작**으로 유지 — 완전한 동작(가는/오는 이동 생성 줄)은 t30 | 운영자 결정, 후속 카드 t30으로 이관 |
| **B-2** 끝 시각은 문장으로 되묻기 | 문장 되묻기를 **중간 동작**으로 유지 — 카드 시각 줄 (b)는 t30 | 운영자 결정, 후속 카드 t30으로 이관 |
| **B-3** 끝 시각을 출발지보다 먼저 | 0.1.4 그대로 | 리드에게 확인용으로 제시 — 명시 답변 없음, 이의 없음 |

**비용 측정(0.1.5 1단계 — 편집 전, 기준 `d8d68db`, 코드는 `e1a40a6`과 같음)**
- 줄 종류는 있다: 토글 `EditCard.swift:119`, 기준 없는 시각 `:165-169`·`chooseTimePlain` `:263`·편집기 갈래 `EditCardView.swift:240-242` — 수동 카드가 쓴다(`AddActivityView.swift:138-141`·`:330-334`).
- 없는 것: 토글에 따른 줄 멤버십은 `AddActivityView.swift:169-326`에만 있다 · AI 카드 `choose`는 값만 적는다(`AIAssistant.swift:871-875`) · `isReady`는 모든 줄을 요구한다(`EditCard.swift:240`) ·
  확인 주입은 `askFields`가 다시 구한 키에만 싣는다(`AIAssistant.swift:1049-1051`) · AI 카드는 `chooseTimePlain`을 잇지 않았다(`AIChatView.swift:125-133`, 기본값 false) · 시각 편집기는 날짜+시각이다(`EditCardView.swift:223-228`).
- 선언 변경은 필요 없다: 카드가 묻는 키는 선언하지 않는 것이 설계다(드라이버 (e) `Tools/GuardDriver.swift:763-769`). `Store.addRecurringEvents`는 호출마다 출발·도착·수단을 받는다(`Store.swift:628`).
- 파일: 경로 A = 무거움 2(`AIAssistant`·`GuardDriver`) + 가벼움 3(`EditCard`·`EditCardView`·`AIChatView`)이지만 `AddActivityView.swift:169-326`의 규칙을 둘째 자리에 적어 계약 5 위반 ·
  경로 B = 무거움 4(+`EditCard`·`AddActivityView`) + 가벼움 2로 한 Day 한도(3~4) 끝. 새 소스 파일은 없다. 후보 diff가 이미 577줄(`git diff --numstat aa7b792 e1a40a6` → 333+64 · 179+1)이라
  추정 증분 300~350줄(측정 아님)을 더하면 Tier M 상한(1000)에 닿거나 넘는다.

### 관측된 증거 — 이 레인이 `e1a40a6`에서 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` · `git log --oneline -3` | `e1a40a6` · `WT-place-resolution` · `e1a40a6 wip(t16) …` / `aa7b792 docs(t15) …` | 기준 트리 |
| `git diff --quiet e1a40a6 -- Shared Tools proxy project.yml; echo $?` | `0` — 작업 트리 = 후보 커밋 | 기준 트리 |
| `git diff --numstat aa7b792 e1a40a6` | `91 0 .moai/reports/t16/progress.md` · `333 64 Shared/AIAssistant.swift` · `179 1 Tools/GuardDriver.swift` | spec §0 Tier |
| `wc -l` 네 파일 · `git show aa7b792:<파일> \| wc -l` | AIAssistant 2753(base 2484) · GuardDriver 1991(1813) · EditCardView 528(528) · EditCard 350(350) | spec §0 |
| `git diff -U0 aa7b792 e1a40a6 -- Shared/AIAssistant.swift \| grep '^@@'` · `\| grep -c '^@@'` | 첫 헝크 `@@ -494,0 +495,11 @@` … 마지막 `@@ -2433,5 +2706,0 @@` · **35** | REQ-015 비균일 오프셋 |
| `grep -n 'func parkForUnclearPlaces\|func resolvePendingAsk\|func askFields\|func searchTopClearlyMatches\|func adoptPlace\|enum PlaceAdoption\|func stayingRecurrence\|func filledValueLabels\|…' Shared/AIAssistant.swift` | `:360` statedLabels · `:374` runLoop · `:380` 루프 상한 · `:445` runToolCalls · `:467` askFields · `:639` outboundOriginField · `:687` placeRow · `:700` searchBoundPlace · `:708` repeatedSearchQuery · `:720` stayingRecurrence · `:729`·`:734` 캡션 · `:764` filledValueLabels · `:786` parkForUnclearPlaces · `:913` confirmedPlaceKey · `:1033` resolvePendingAsk · `:1398` missingAskedArguments · `:1409` executeTool · `:2538` isSamePlace · `:2568`·`:2579` resolveOrigin(·Adoption) · `:2625` unresolvedGenericPlace · `:2645` PlaceAdoption · `:2653` adoptPlace · `:2685` searchTopClearlyMatches · `:2701` resolveDestination | spec §1.2·§1.4 |
| `awk` 열람: `:374-445` · `:467-816` · `:1033-1060` · `:1398-1416` · `:1455-1494` · `:1622-1700` · `:1750-1845` · `:1874-1880` · `:2021-2060` · `:2425-2436` · `:2645-2710` | 렌즈 좌표를 이 트리에서 재확인 — 비우기 `:796`, 중복 가드 `:790-792`, 재계산 주입 `:1050-1051`, `note == nil` 필터 `:1403`, `statedArgs = [:]` `:1414`, `:1760` 반복 정보 부족 문구, 머무는 반복 `:1812-1830`, 반복 수정 거짓 문구 `:2058`, 수정 경로 `:2430-2431` | spec §1.3·§1.4·§1.5 |
| `grep -n 'parkForUnclearPlaces(\|adoptPlace(\|isSamePlace(\|lastRecurrenceId\|new_place_query\|resolveOrigin(\|…' Shared/AIAssistant.swift` | 실행부 갈래 `:1457-1485`·`:1630-1661`·`:1784-1805` · 거절 `:1492` · 머무는 반복 `:1812`·`:1825` · 점심 `:1879` · 조회 `:2321`·`:2380`·`:2383` · 수정 `:2431` | spec §1.2 |
| `grep -n 'orDefault: false\|orDefault: true' Shared/AIAssistant.swift` | `:2380` 하나(`true`) | REQ-013 죽은 분기 |
| `grep -n '"weeks"' Shared/AIAssistant.swift` | `:530` · `:677` · `:1954` — 선언에 없음 | H-9 |
| `awk 'NR>=130 && NR<=155'` · `'NR>=1825 && NR<=1865'` · `'NR>=1925 && NR<=1991' Tools/GuardDriver.swift` · `grep -n 'AA-[0-9]…' Tools/GuardDriver.swift` | `drvTopMatches` `:137`(주소 기본값 `""`) · `drvPark` `:143` · `drvResolvePendingAsk` `:152` · AA절 머리 `:1826` · '강남' `:1834-1835` · AA-2 즐겨찾기 `:1856-1863`(`회사`/`집`) · AA-6·7 `:1925-1966`(create_schedule 목적지만) | spec §1.4 · REQ-008 · AC-002·006 |
| `awk` `Shared/EditCardView.swift` `:1-8`·`:64-72`·`:110-135`·`:312-320`·`:412-428` · `grep -n 'private func chip(\|…'` · `awk 'NR>=158 && NR<=166' Shared/EditCard.swift` | 머리말 `:3-5` · onAppear 씨앗 `:68-70` · 값 칩 `:116` · 검색 값 칩 `:122-123`(`selected: true`) · 편집기 `:132` · `chip()` `:265` · `placeSearchEditor` `:316` · `openCustom` `:416` · `startsOpen` `:164`(주석 `:160-163` "AI 카드는 전부 기본값 false라 무변화다") | spec §1.4 U-2·수렴 3 |
| `grep -rn 'EditCardView(' Shared/` | `AIChatView.swift:106` · `AddEventView.swift:68` · `AddActivityView.swift:72` · `ActivityDetailView.swift:64` | REQ-012 |
| `grep -n 'func recurringSeries' -A4 Shared/Store.swift` · `grep -n 'func updateRecurringSeries' Shared/Store.swift` · `grep -n 'func deleteEverythingForTesting' -A9 Shared/Store.swift` | `:698-700` events만 거른다 · `:728` · `:1319-1326` 즐겨찾기를 지우지 않는다 | H-8 · 스크립트 P1 |
| 오케스트레이터 로그 읽기: `grep -E '통과$\|대조 통과' .moai/state/verify/t16-plan/gd-head.log` · `gd-base.log` | head `241/241 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` / base `217/217 통과` · 같은 대조 줄 | spec §0 · AC-012 기준선 |
| `grep -c '\*\* BUILD SUCCEEDED \*\*'` · `grep 'warning:' \| grep -c '\.swift'` · `grep -c '^SwiftCompile'` on `build-ios.log`·`build-mac.log` (같은 폴더) | 1 / 1 · 0 / 0 · 42 / 38 | AC-012 기준선 |
| `grep -c 'warning:'` on `compile-base.log`·`compile-head.log` | 24 · 24 | AC-012 (2) |
| `grep -o 'AIAssistant\(\.swift\)\{0,1\}:[0-9]\{1,4\}' <문서> \| wc -l` | CHECKLIST 14 · 루트 plan 4 · 005 spec 6 · 005 plan 1 · 005 acceptance 0 · 005 progress 3 · 007 spec 1 · 007 plan 0 · 007 progress 0 · GuardDriver 0 | REQ-015 · AC-013 |
| 기준선 신호 `grep -c`: `startsOpen`(AIAssistant) · `guard tool == "create_schedule"` · `AI 카드는 전부 기본값 false`(EditCard) · `return_time에 넣어` · `가 여러 줄에 같은 이름으로 왔어요` · `미리 정해진 출발지가 맞는지` · 튜플 타입 | 0 · 1 · 1 · 1 · 1 · 1 · AIAssistant 4 / GuardDriver 1 | AC-005~008·011 |
| `awk 'NR==1193 \|\| NR==1273' Shared/AIAssistant.swift` · `grep -n '4,425\|o200k' plan.md` | 머무는 반복 프롬프트 줄 · `origin_query` 설명 · 루트 `plan.md:230`(4,425)·`:232-233`(측정법) | REQ-010 · REQ-014 |
| `sed -n '528,536p' CHECKLIST.md` | C7 항목에 t7발 O-1 가설 동봉 | spec §3 O-1 |
| `moai todo \| grep t16` | `t16 queued C7 장소 해석 UX — U-4 … + AC-009 7·9 … + U-2 … + 관측 추가(2026-09-24 시뮬레이터 14항목) …` | spec §1.1 |
| `ID="SPEC-UIKIT-008"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` · `ls .moai/specs \| grep -c SPEC-UIKIT-008` | `PASS` · `0`(중복 없음) | frontmatter `id` |
| `grep -n 'enum TransportMode' -A8 Shared/Models.swift` · `awk 'NR>=2021 && NR<=2060' Shared/AIAssistant.swift` | `car`·`transit`·`walk` 셋(`:5-8`) · 반복 수정은 `mode`·`buffer`·`notify`가 모두 nil이면 `:2047` 가드에서 먼저 끝난다 | AC-009 입력(`mode: "car"`) · 스크립트 13번 |
| `moai spec lint --json \| python3 -c '…UIKIT-008 필터'` · `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` | 워크트리 전체 7건(전부 다른 SPEC, advisory) 중 SPEC-UIKIT-008 **0건** · `✓ No findings` | frontmatter·Out of Scope·GEARS 린트 |
| `git check-ignore -v .moai/state/verify/t16-plan/gd-head.log` · `git check-ignore -v build-ios.log; echo $?` | `.gitignore:28:**/.moai/state/` · exit `1`(워크트리 루트 빌드 로그는 무시 목록 밖, 추적 안 됨) | 증거 보존 · plan §3 커밋 주의 |

### 렌즈·기록과 어긋난 자리

1. **반복 정보 부족 문구의 줄.** ai 렌즈는 `:1756`을, ui 렌즈는 `:1760`을 적었다. `grep -n '반복 일정 정보가 부족합니다' Shared/AIAssistant.swift` → **`:1760`**(문구), 가드는 그 위 `:1754-1759`다. spec은 `:1760`으로 적었다. 결론은 같다.
2. **`placeSearchEditor` 범위.** 이전 기록 §6의 `:316-318`은 선언 머리 세 줄이다(ui 렌즈 §1.1). 선언은 `:316`이다.
3. **U-2 생산자.** 이전 기록 §6의 처방("`:116` 한 줄")은 관측 경로를 놓친다 — 관측 경로의 생산자는 `:122-123`이다(ui 렌즈 §1.1). spec은 두 생산자를 한 술어로 묶게 했다.
4. **"뷰 수정 없이 렌더된다(빌드 무경고로 확인)".** 이전 기록 §6의 이 문장은 빌드가 증명할 수 있는 범위를 넘는다(ai 렌즈 A-1 (f)) — 후보는 렌더되지만 보이지 않는다(H-5).

### Gaps — plan이 돌리지 않은 것 (증거 없음 ≠ 통과)

- **프록시 `npm test` — 미실행.** `git diff --name-only aa7b792 e1a40a6`에 `proxy/`가 없어 오케스트레이터도 이 레인도 돌리지 않았다. 이전 기록의 "7/7"은 관측되지 않은 채다. run·sync가 돌린다(REQ-014).
- **드라이버·빌드 — 이 레인은 실행하지 않았다.** 수치는 오케스트레이터가 이 세션에서 돌려 남긴 로그를 읽은 것이다. 드라이버 컴파일 경고 **집합의 동일성**은 오케스트레이터의 관측이고, 이 레인은 건수(24/24)만 확인했다.
- **H-1~H-11 — 재현되지 않았다.** 전부 코드 추적이다(H-11은 0.1.3에서 D-8로 결함이 됐다). run M1이 첫 관측이 된다(REQ-001).
- **D-8 해석 I-1~I-6 — 확인됐다(2026-09-26, 리드 전달).** 이 세션은 운영자의 답을 직접 보지 않았다.
- **경계 B-1~B-3 · 해석 T-1 — 해소됐다(0.1.5).** B-1·B-2는 중간 동작 유지·t30 이관(운영자 결정, 리드 전달), T-1·B-3은 명시 답변 없이 이의 없음.
- **t30의 비용 추정 — 측정이 아니다.** 경로 A·B의 증분 300~350줄은 수동 카드의 멤버십 구간(208줄, 측정)에서 어림한 값이다.
- **카카오 실제 응답 — 미관측.** 선릉·정릉의 주소 문자열과 '스타벅스 홍대점'의 첫 결과는 어느 렌즈도 보지 않았다. AC-002의 주소 픽스처는 가정이다.
- **모델 행동 — 미관측.** 같은 이름·머무는 반복 인자를 모델이 프롬프트대로 보내는지, 후보 카드 뒤에 재호출하는지는 시뮬레이터 몫이다(AC-014).
- **D-5 (a)의 전제 — 미확인.** 도구 결과 턴 뒤에 사용자 턴이 오는 히스토리를 프록시·백엔드가 받아들이는지 확인하지 않았다.
- ~~D-7 (b)의 전제 — 미확인.~~ **0.1.1에서 확인했다 — 거짓이다**(`statedArguments` `:338-344`는 출발지를 읽지 않는다). 그래서 D-7 (b)를 게이트 목록에서 거뒀다(감사 1회차 D5).
- **맨몸 `:N` 인용 수 — 미측정.** 파일명 있는 토큰만 셌다. sync가 행의 기본 파일로 풀어 센다(REQ-015).
- **토큰 — 이 레인은 재지 않았다.** 증분 +123은 ai 렌즈의 측정(tiktoken `o200k_base`, base·head 같은 방법)이고, 이전 기록은 +122다. 절대값(4,425 대 3,824)은 풀리지 않았다.
- **MCP `spec_audit` — 이 SPEC을 보지 못했다.** `mcp__moai__spec_audit(filter_spec: SPEC-UIKIT-008)` → `total_specs: 0`. MCP 서버가 주 체크아웃을 읽는 것으로 보인다(추론). 린트는 워크트리 CLI로 대신 확인했다(위 표).
- **시뮬레이터·macOS 동작 — 미관측.**

### 잔여 위험

- 드라이버 초록이 사람 증거를 대신하지 못한다 — 후보 트리가 그 증거다(241/241 초록 + 렌즈 결함).
- 판정 술어의 낱말·접미어 규칙은 정적이다. 표기 차이에서 거짓 되묻기와 거짓 채택이 남는다. 브랜드 단일어는 늘 채택된다(spec §3).
- 사용자가 후보 카드를 두고 새 발화로 넘어가면 카드는 취소되지만 히스토리에는 "카드가 자동 진행된다"는 도구 결과가 남을 수 있다(ai 렌즈 잔여 위험 — D-4 (a)·D-5 (a)가 문구를 사실로 바꾸고 턴을 끝내 줄어든다).
- 워크트리 루트의 추적 안 된 `build-ios.log`·`build-mac.log`가 쓸어 담기 스테이징에 섞일 수 있다 — 경로 지정 스테이징으로 막는다.

## §E.2 Run-phase Evidence

### M1 — 재현 먼저 (REQ-001, 2026-09-26)

- **관측 트리: `c405ff5`** — `Shared/ = e1a40a6 바이트 동일 확인 exit 0`(아래 명령 표). 재현 절은 `Tools/GuardDriver.swift` AB절 하나에만 더했다(기존 AA·O 단언 무변경).
- 단언은 전부 **바라는 동작**이다(REQ-001 극성 규칙): 후보에서 ✗ = 재현, ✓ = "재현 안 됨". 관측 동작 특성화 재작성(H-9 `[수용]` I-5 · H-3 `[경로 제거]` D-5 (a))은 수리 커밋 몫이다.
- **결과: 가설 열한 개 전부 재현됐다**(가설마다 ✗ ≥ 1). "재현 안 됨" 가설 0건. 막힌(blocked) 가설 0건 — 전부 드라이버 표면(drvPark·drvAsk·drvExecuteTool·drvResolvePendingAsk·drvUpdate·drvCreateRecurring)에서 닿았다.
- **`P/T 통과` 줄 원문: `251/279 통과`** · 드라이버 exit **1**(이 단계의 기대값 — `P/T 통과` 줄이 찍혔으므로 컴파일 실패가 아니다). T = 241(base) + 38(더한 단언) − 0(뺀 단언) = 279 · P = 251(✗ 28).
- `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`(샌드박스·실제 지원 디렉터리 대조). 정상 종료라 샌드박스는 스스로 지웠다(`ls -d $TMPDIR/besir-gd-*` → 없음).
- **AC-012 장부(더한 단언 38 · 뺀 단언 0)**: `AB-H01`(9줄 — §1.3 조합 아홉; AC-003 10번 조합과 5번의 최종 모양은 수리 때 회귀 방지선으로 더한다) · `AB-H02`(3) · `AB-H03`(2) · `AB-H04`(2) · `AB-H05`(1) · `AB-H06`(2) · `AB-H07`(3) · `AB-H08`(3) · `AB-H09`(1) · `AB-H10`(1) · `AB-H11`(11).
- 로그: `.moai/state/verify/t16/m1-driver.log`(드라이버) · `.moai/state/verify/t16/m1-compile.log`(컴파일 경고).

#### 가설별 관측 — ✓/✗ 줄 원문 (`c405ff5`, `Shared/` = `e1a40a6`)

| 가설 | 단언 줄 원문(✓/✗ 그대로) | 판정 |
|---|---|---|
| H-1 확인 주입 | `✓ AB-H01 create_schedule origin_query` · `✓ AB-H01 create_schedule destination_query` · `✓ AB-H01 create_recurring_schedule origin_query` · `✗ AB-H01 create_recurring_schedule destination_query`(`reply=반복 일정 정보가 부족합니다. 제목, 목적지, 반복 요일, 도착 시각을 다시 확인해 주세요. events=0`) · `✗ AB-H01 create_activity place_query`(`location=nil reply=활동 블록 등록 완료 — 'AB-활동장소주입', 3월 16일 (화) 오전 10시 0분 ~ 3월 16일 (화) 오후 12시 0분.`) · `✓ AB-H01 create_activity travel_from_query 왕복` · `✗ AB-H01 create_activity travel_from_query 편도`(`legs=0 reply=… 가는 이동 없이 성공 등록`) · `✗ AB-H01 create_activity return_to_query`(`복귀legs=0 reply=활동 블록 등록 완료 — 'AB-복귀지주입', 장소 '회사', … 가는 이동 1건도 활동에 묶어서 만들었어요(도보).`) · `✓ AB-H01 한 호출 두 키 동시 모호` | **재현** — §1.3이 예측한 4·5·7·8번 조합에서 고른 값이 버려졌다(5·7·8은 성공 문구를 동반한 조용한 실패). 1·2·3·6·9번 조합과 두 키 동시 모호는 주입이 이미 작동한다(재현 안 됨 — 이 조합들을 근거로 코드를 바꾸지 않는다). 5·7·8의 조용한 형태는 §1.3의 "missingAskedArguments가 막는다"(수단을 비워 둔 호출)보다 조용한 쪽이다 — 이 모델은 선언된 선택 인자를 비워두지 못해 수단이 찬 채로 오는 게 실제 모양이고 그때 버림은 드러나지 않는다 |
| H-2 다중 호출 | `✗ AB-H02 두 번째 모호 호출 안내가 자동 진행을 말하지 않는다` · `✗ AB-H02 두 번째 모호 호출이 미등록·카드 뒤 재호출 안내를 받는다`(둘 다 상세 원문: `이미 같은 질문의 카드가 열려 있어요. 사용자가 카드에서 고르면 그 값으로 자동으로 진행돼요 — 인자를 바꾸지 말고 기다려.`) · `✓ AB-H02 후보 카드는 한 장이다` | **재현** — 거짓 "자동 진행" 안내 그대로. 카드 한 장은 이미 지켜진 부분(재현 안 됨) |
| H-3 보류 뒤 이중 등록 | `✗ AB-H03 카드가 열린 동안 재호출이 등록되지 않는다`(`events=1`) · `✗ AB-H03 한 요청이 두 건이 되지 않는다`(`events=2 reply=등록 완료 — 제목 'AB-이중등록', '집' → '스타벅스 홍대입구역점', … 출발 3월 17일 (수) 오후 2시 27분 → 도착 3월 17일 (수) 오후 6시 0분…`) | **재현** — 같은 요청의 레코드 2건. 턴 종료(runLoop)는 드라이버가 못 지나가는 경로라 실행부 수준에서만 관측했다(임무 지시대로) |
| H-4 '강남' 판정 | `✗ AB-H04 '강남'→선릉과정릉(선릉로 주소)은 맞지 않는다`(`match=true — 주소의 '강남구'가 이름 낱말을 만족시켰다`) · `✗ AB-H04 '강남'→선릉과정릉(삼성동 주소)도 맞지 않는다`(`match=true — 판정은 주소를 보지 않아야 하므로 두 주소의 결과가 같다`) | **재현** — 실제 주소 모양에서 채택된다(2026-09-24 관측 경로). AA-1의 빈 주소 단언이 지나치던 자리다 |
| H-5 후보 노출 | `✗ AB-H05 후보 줄이 첫 렌더에 열려 있다`(`startsOpen=false`) | **재현** |
| H-6 맥락 줄 | `✗ AB-H06 활동 후보 카드 맥락 줄에 제목이 있다`(`stated=[]`) · `✗ AB-H06 반복 후보 카드 맥락 줄에 제목이 있다`(`stated=[]`) | **재현** — 활동·반복 후보 카드의 맥락 줄이 비어 있다 |
| H-7 왕복 캡션 | `✗ AB-H07 왕복 가는 편 줄 캡션이 채워 온 값(집)을 적는다`(`note=미리 정해진 출발지가 맞는지 골라 확인해 주세요. 가는 이동이 필요 없으면 '가는 편 없음'을 골라 주세요.`) · `✓ AB-H07 왕복 가는 편 줄은 선택된 채 시작하지 않는다` · `✓ AB-H07 왕복 가는 편 줄에 '가는 편 없음' 칩이 있다` | **재현** — 캡션이 카드에 없는 값을 가리킨다. 줄 자체·칩·미리 선택 없음은 이미 작동한다(재현 안 됨) |
| H-8 반복 수정 거짓 문구 | `✗ AB-H08 거짓 '이미 삭제' 문구가 없다` · `✗ AB-H08 바꿀 이동 구간이 없다고 사실을 말한다`(둘 다 상세 원문: `그 반복 일정을 더 이상 찾을 수 없어요(이미 삭제됐을 수 있어요).`) · `✓ AB-H08 활동 블록 수가 그대로다` | **재현** — 거짓 문구 그대로. 활동 블록 불변은 이미 지켜진다(재현 안 됨) |
| H-9 기간 이중 질문 | `✗ AB-H09 weeks 없는 재호출에 '반복 기간' 줄이 다시 서지 않는다`(`keys=["weeks"]`) | **재현** — 수리 때 `AB-H09 [수용]`(I-5) 특성화로 바뀐다(REQ-001) |
| H-10 점심 인자 버림 | `✗ AB-H10 머무는 반복 결과가 버린 점심 인자를 말한다`(`reply=등록 완료 — 'AB-낮식사' 한 장소 반복 활동 4건(12:00~13:00, 장소 '집'). 이동 구간은 만들지 않았어요. 전체를 지우려면 아무 일정이나 열어 '반복 일정 전체 삭제'를 눌러주세요.`) | **재현** — `lunch_place_query`·`lunch_start`·`lunch_end`를 실어도 요약에 점심 언급이 없다(제목에 '점심'을 쓰지 않아 판정 오염을 막았다) |
| H-11 머무는 요청 출발지 | `✗ AB-H11 머무는 반복 카드가 출발지 줄을 띄운다`(`keys=["weeks"]`) · `✗ AB-H11 반복 출발지 줄에 '이동 없음' 선택지가 있다`(`options=[]`) · `✗ AB-H11 반복 출발지 줄 캡션이 모델 값(집)을 적는다`(`note=nil`) · `✓ AB-H11 반복 카드는 수단·여유·알림을 묻지 않는다` · `✗ AB-H11 이동 없는 한 번짜리 활동이 출발지 줄을 띄운다`(`keys=[]` — 카드가 아예 안 선다) · `✗ AB-H11 한 번짜리 출발지 줄에 '이동 없음' 선택지가 있다` · `✗ AB-H11 같은 값(집) 한 번짜리가 출발지 줄을 띄운다`(`keys=["mode_this_time", "buffer_minutes", "notify_lead_minutes"]`) · `✗ AB-H11 같은 값 출발지 줄 캡션이 모델 값(집)을 적는다` · `✗ AB-H11 같은 값 출발지 줄에 '이동 없음' 선택지가 있다` · `✗ AB-H11 못 푸는 장소 활동은 장소 줄+출발지 줄이 함께 선다`(`keys=["place_query"]`) · `✗ AB-H11 못 푸는 장소 출발지 줄에 '이동 없음' 선택지가 있다` | **재현** — 네 모양(반복 · 한 번짜리 travel_from 비움 · 같은 값 · 못 푸는 장소) 모두 출발지 줄·'이동 없음'이 없다. 수단·여유·알림 억제(반복)만 이미 작동한다(재현 안 됨) |

#### 관측이 spec §1.5 예측을 구체화한 한 곳 (모순 아님)

- **H-11 같은 값(집/집) 한 번짜리**: §1.5의 예측은 "이동 줄 없이 곧바로 실행"인데, 관측은 `keys=["mode_this_time", "buffer_minutes", "notify_lead_minutes"]` — 후보는 이 호출을 **편도**로 취급해 수단·여유·알림 카드를 세운다(이 행의 `travel_from_query`가 차 있어 :549의 guard를 통과한다). 예측의 "이동 줄 없이"는 모델이 `travel_from_query`를 비워 보낸 모양이고, 같은 값을 채워 보낸 모양은 이렇게 다르게 드러난다 — 어느 쪽도 출발지를 묻지 않고 '이동 없음'이 없다는 점에서 H-11 결함은 같다. 수리 시 이 모양이 편도 카드(기존 경로)로 빠지지 않는지 같은 단언이 지킨다.

#### 시험 설계 결함 3건(가설 관측이 아니라 픽스처 오류 — 최종 관측 전에 고쳤다)

1. 조합2·조합9가 조합1 이벤트와 같은 날짜(3/15)라 **겹침 가드**(`on_conflict`)에 막혀 주입이 아니라 충돌로 ✗가 났다 → 날짜를 3/18·3/19로 분리.
2. AB-H03 재호출(15:00)과 확인(18:00)의 창이 도보 추정(3시간대) 때문에 겹쳐 둘째 건이 막혀 "1건"으로 관측됐다 → 재호출을 09:00으로 옮겨 `events=2` 관측 확보.
3. AB-H10 제목 'AB-점심버림'의 "점심"이 요약(제목 인용)에 새어 거짓 ✓가 났다 → 제목을 'AB-낮식사'로.

#### M1 때 이 레인이 돌린 명령

| 명령 | 관측된 출력 |
|---|---|
| `git branch --show-current && git rev-parse --short HEAD` | `WT-place-resolution` · `c405ff5` |
| `git diff --quiet e1a40a6 -- Shared/ Tools/; echo $?`(착수 전) | `0` — 코드는 후보 그대로 |
| `git diff --quiet e1a40a6 -- Shared/; echo $?`(재현 절 추가 뒤) | `0` — `Shared/`는 끝까지 `e1a40a6` 바이트 동일 |
| `git diff --quiet e1a40a6 -- proxy/ project.yml; echo $?` | `0` |
| `grep -c 'warning:' .moai/state/verify/t16-plan/compile-head.log`(base) · `grep -c 'warning:' .moai/state/verify/t16/m1-compile.log` | `24` · `24` — 재현 절이 경고를 0줄 더했다(AC-012 (2)의 전제) |
| `CLAUDE.md` 드라이버 블록(§D) → `.moai/state/verify/t16/m1-driver.log` | exit `1` · `251/279 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` |
| `grep -c '✗ AB-H' m1-driver.log` · `grep -c '✓ AB-H' m1-driver.log` | `28` · `10` |
| `ls -d $TMPDIR/besir-gd-*` | 없음(정상 종료 정리) |

### M2 — 데이터 흐름 (REQ-003·004·005, 2026-09-26)

- **관측 트리: 이번 커밋**(아래 커밋 SHA). 변경은 `Shared/AIAssistant.swift`·`Tools/GuardDriver.swift` 두 파일, 관측 로그는 `.moai/state/verify/t16/m2-driver.log`·`m2-compile.log`.
- **결과: `258/278 통과`** · 드라이버 exit **1**(M3/M4 대상 20건이 여전히 ✗ — 중간 기대값). `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`. 샌드박스 정상 정리(`ls -d $TMPDIR/besir-gd-*` → 없음).
- **AC-012 장부(뺀 2 · 더한 1)**: 뺀 것 — `AB-H03 카드가 열린 동안 재호출이 등록되지 않는다`·`AB-H03 한 요청이 두 건이 되지 않는다`(M1에서 AB-H03은 **두 줄**이었다). 더한 것 — `AB-H03 [경로 제거] 실행부 직접 주행에서만 두 건이 된다` 한 줄. 임무 지시는 "뺀 1 · 더한 1"로 적었으나 실제로는 뺀 2 · 더한 1이다(임무 문안이 AB-H03을 한 단언으로 세었고, M1 원장은 2줄로 섰다 — 이 줄이 그 차이를 기록한다). T = 241 + 38 − 2 + 1 = **278**.

#### (a) D-5 (a) 전제 확인 — 코드 증거로 닫았다 (착수 전, D-5 코드를 쓰기 전)

| # | 확인한 인용 | 이 트리에서의 관측 |
|---|---|---|
| 1 | `Shared/AIAssistant.swift:198-201` `repairDanglingToolTurn()` + 호출 :164·:292 | function 턴으로 끝난 히스토리에 model 확인 턴("네, 확인했어요.")을 끼운다. submit의 호출(:292)은 사용자 턴을 contents에 넣는(:300) **앞**에 무조건 지나므로, [function → model → user] 순서가 요청으로 나가기 전에 만들어진다 ✓ |
| 2 | `proxy/src/index.js:167-222` `toResponsesRequest` | 순서 보존 1:1 매핑(model functionCall → function_call; function → function_call_output; user → user items). 재정렬·거부 분기 없음 ✓ |
| 3 | "거부했다" 주석(`Shared/AIAssistant.swift:161-162`·`:410-412`) | 둘 다 **삭제된 Workers AI**의 role 순서 거부 이야기다 — `proxy/src/index.js`에서 `proxyWorkersAI`·`toOpenAIRequest`·`toGeminiShape`·`WORKERS_AI_MODEL` grep 0건, `proxy/wrangler.toml:5`가 [ai] 바인딩 제거(2026-09-13)를 확인. 현재 백엔드는 `proxyOpenAI`(:224, `/v1/responses`, `gpt-5.6-luna`, effort medium) ✓ |
| 4 | 더 강한 근거 | 2회 이상 도구를 도는 턴은 오늘도 매번 function 턴으로 끝나는 히스토리로 callAI를 부른다(runLoop의 둘째 호출) — 수리 뒤 모양([function_call_output → model → user])은 그보다 표준적이다 ✓ (코드 구조 사실) |

- **갭(정직하게)**: 이 정확한 히스토리를 실은 라이브 요청은 보내지 않았다 — 코드 증거로 닫았고 할당량은 쓰지 않았다(드라이버는 프록시 설정을 비운다). 모델 루프 실동작은 AC-014 시뮬레이터 몫이다.
- **전제는 깨지지 않았다** — 블로커 없이 D-5 코드를 썼다(REQ-005).

#### (b) 수리별 증거 — M1 ✗ → M2 ✓ (원문)

| 가설 | M1 ✗ 원문(관측 트리 `c405ff5`) | M2 ✓ 원문 | 수리 자리 |
|---|---|---|---|
| H-1 조합4 | `✗ AB-H01 create_recurring_schedule destination_query`(`reply=반복 일정 정보가 부족합니다. 제목, 목적지, 반복 요일, 도착 시각을 다시 확인해 주세요. events=0`) | `✓ AB-H01 create_recurring_schedule destination_query` | D-3 — `parkForUnclearPlaces` :806(줄 공장 askFields를 **비우기 전 인자**로)·:808(비우기=기록), `resolvePendingAsk` :1067-1073(빈 키 선주입) |
| H-1 조합5 | `✗ AB-H01 create_activity place_query`(`location=nil reply=활동 블록 등록 완료 — 'AB-활동장소주입', 3월 16일 (화) 오전 10시 0분 ~ 3월 16일 (화) 오후 12시 0분.`) | `✓ AB-H01 create_activity place_query` | 같음 |
| H-1 조합7 | `✗ AB-H01 create_activity travel_from_query 편도`(`legs=0 reply=… 가는 이동 없이 성공 등록`) | `✓ AB-H01 create_activity travel_from_query 편도` | 같음 |
| H-1 조합8 | `✗ AB-H01 create_activity return_to_query`(`복귀legs=0 reply=활동 블록 등록 완료 — 'AB-복귀지주입', 장소 '회사', … 가는 이동 1건도 활동에 묶어서 만들었어요(도보).`) | `✓ AB-H01 create_activity return_to_query` | 같음 + 카드가 확인 뒤 호출 모양(왕복)의 줄(가는 편 출발지 재확인·가는/오는 편 수단)까지 함께 묻는다 — 드라이버 조합8 픽스처가 그 줄들을 같이 고른다 |
| H-2 | `✗ AB-H02 두 번째 모호 호출 안내가 자동 진행을 말하지 않는다` · `✗ AB-H02 두 번째 모호 호출이 미등록·카드 뒤 재호출 안내를 받는다`(둘 다 상세 원문: `이미 같은 질문의 카드가 열려 있어요. 사용자가 카드에서 고르면 그 값으로 자동으로 진행돼요 — 인자를 바꾸지 말고 기다려.`) | 두 줄 모두 ✓ | D-4 — `parkForUnclearPlaces` :798-800, 새 문구 `등록하지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. 사용자가 그 카드에서 고르면 그 등록만 진행돼요. 이 호출은 카드가 끝난 뒤에 인자를 바꾸지 말고 다시 호출해.`("자동으로 진행" 부재 · "등록하지 않았"·"다시 호출" 있음 — 단언이 그대로 판정) |
| H-3 | `✗ AB-H03 카드가 열린 동안 재호출이 등록되지 않는다`(`events=1`) · `✗ AB-H03 한 요청이 두 건이 되지 않는다`(`events=2 reply=등록 완료 — 제목 'AB-이중등록', '집' → '스타벅스 홍대입구역점', …`) | `✓ AB-H03 [경로 제거] 실행부 직접 주행에서만 두 건이 된다` — **경로 제거(D-5 (a))** | D-5 — 아래 (c) |

- **남은 ✗ 20줄(전부 M3/M4 대상 — 중간 기대값)**: `AB-H04`×2 — M3(REQ-002 D-2 이름만 판정) · `AB-H05`×1·`AB-H06`×2·`AB-H07 캡션`×1 — M4(REQ-006 D-6 · REQ-007 · REQ-009 D-7) · `AB-H08`×2 — M4(REQ-011) · `AB-H09`×1 — M4 수용(I-5) 재작성 대상 · `AB-H10`×1·`AB-H11`×10 — M4(REQ-010 '이동 없음' 출발지 줄).
- **M2 도중 잡은 자기 결함 1건(기록)**: 빈 값 판정을 `??` 한 줄로 쓰면 `(a ?? b) == nil`로 해석돼 값이 있는 키까지 "안 비었다"로 읽혀, 첫 드라이버 실행에서 조합 4·5·7·8이 그대로 ✗로 나왔다(254/278). `if let`으로 펴서 고쳤고 `resolvePendingAsk` 주석에 근거를 남겼다 — 재현 절이 수리 자체의 회귀도 잡는다는 원칙(REQ-001)의 M2 사례다.

#### (c) AB-H03 [경로 제거] 재작성 기록 (REQ-001)

- `AB-H03 카드가 열린 동안 재호출이 등록되지 않는다` + `AB-H03 한 요청이 두 건이 되지 않는다`(바라는 동작 2줄) → `AB-H03 [경로 제거] 실행부 직접 주행에서만 두 건이 된다`(특성화 1줄, `h3Total == 2`).
- **경로 제거(D-5 (a))** — 경로를 없앤 코드 자리:
  - `runLoop` — **`Shared/AIAssistant.swift:441`** `if bubbles.contains(where: { $0.ask != nil }) { return }`(도구 실행(`runToolCalls` :434) 뒤, 모델 재호출(`for` 루프의 다음 `callAI`) **앞**). 후보 카드가 도구 실행 안에서 서면 그 턴이 끝난다 — 같은 턴의 모델 재호출(인자를 바꾼 이중 등록의 진입로)이 구조적으로 없다.
  - `submit()` — **`:285` `cancelPendingAsk()`**(새 발화가 열린 카드를 접는다)·**`:292` `repairDanglingToolTurn()`**(function 턴으로 끝난 히스토리를 고쳐 다음 요청이 [function_call_output → model → user]로 나간다 — 전제 (a)).
- 드라이버는 모델 루프를 지나지 못하므로(프록시 설정을 비운다), 실행부를 직접 몰 때의 잔상(등록 2건)을 특성화로 적었다 — 앱에서는 위 두 자리로 그 경로에 닿을 수 없다.

#### (d) 드라이버 수치 (AC-012 장부용)

- `258/278 통과` · exit 1 · `grep -c '✗ AB-'` = **20**(M1 28 → 뒤집힘 6 + 제거된 AB-H03 ✗ 2). 비-AB 회귀 0건.
- 뒤집힘(✗→✓) 6줄: AB-H01 조합 4·5·7·8 + AB-H02 두 줄. AB-H03은 재작성(뺀 2 · 더한 1 — 위 장부 줄).
- 컴파일 경고: `grep -c 'warning:' .moai/state/verify/t16/m2-compile.log` = **24**(base와 동일 — 진단 12 + 캐럿 문맥 12, MapKit·CoreLocation 지원중단(deprecation) 경고로 전부 `DirectionsService.swift`·`LocationManager.swift` 것).
- 로그: `.moai/state/verify/t16/m2-driver.log` · `.moai/state/verify/t16/m2-compile.log`.

#### (e) AC-004 (2) 코드 대조 줄

- **`runLoop` — `Shared/AIAssistant.swift:441`** `if bubbles.contains(where: { $0.ask != nil }) { return }`: 도구 실행 중 후보 카드가 서면 그 턴에서 모델을 다시 부르지 않고 돌아오는 자리. 카드 아래 모델 말풍선이 붙지 않는다(:428-431 ask 카드 경로와 같은 모양 — 카드는 `parkForUnclearPlaces` :820이 빈 말풍선과 함께 단다).
- 재호출 경로 제거의 짝: `submit()` :285 `cancelPendingAsk()`(새 발화가 열린 카드를 접는다 — spec REQ-005 근거의 `:285`).

### M3 — 판정 술어 (REQ-002, 2026-09-26)

- **관측 트리: 이번 커밋**(아래 커밋 SHA). 변경은 `Shared/AIAssistant.swift`·`Tools/GuardDriver.swift`(+이 progress.md), 관측 로그는 `.moai/state/verify/t16/m3-driver.log`·`m3-compile.log`.
- **결과: `261/279 통과`** · 드라이버 exit **1**(M4 대상 18건이 여전히 ✗ — 중간 기대값). `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`. 샌드박스 정상 정리(`ls -d $TMPDIR/besir-gd-*` → 없음). 비-AB 회귀 0건 — ✗ 줄 중 비-AB는 AB절 배너 문장(✗ 문자를 안내에 포함) 1줄뿐이고 M2 로그와 같은 모양이다.

#### (a) 술어 변경 — 결과 이름만 본다 (D-2 (a))

- `Shared/AIAssistant.swift` `searchTopClearlyMatches`(정의 **:2714**, 호출처 :2702 하나뿐):
  - 옛: `let haystack = (result.name + " " + result.address).replacingOccurrences(of: " ", with: "")` — 이름 뒤 주소를 이어붙여 낱말을 찾았다.
  - 새: `let haystack = result.name.replacingOccurrences(of: " ", with: "")`(**:2715**) — 결과 이름만 판정한다.
- 주석도 같이 뒤집었다 — 옛은 "주소도 함께 보는 건 거짓 되묻기를 줄이기 위해서다(건물명 결과는 이름에 없는 낱말이 주소에 있는 경우가 흔하다)"였고, 새는 "판정이 주소를 안 보는 건 주소 낱말이 가짜 답을 만들었기 때문이다 — '강남'으로 말한 자리에서 주소의 '강남구'가 낱말을 만족시켜 '서울선릉과정릉'이 조용히 채택됐다(2026-09-24 관측). 주소로 말한 질의는 후보 카드에서 한 번 더 고른다".
- 토큰 규칙('점'·'역' 접미어 제거·2글자 하한·띄어쓰기 제거)과 `adoptPlace` 사다리(:2681, 검색 갈래 :2691-2704)·`maxPlaceSuggestions`·후보 카드 경로는 무변경(REQ-013).

#### (b) 픽스처 변경 — AA-1 (AC-002)

| 픽스처 | 옛 | 새 | 장부 |
|---|---|---|---|
| 강남 | `drvTopMatches("강남", name: "서울선릉과정릉") == false` — 주소 인자 없음(옛 `:1835`) | 두 줄: `drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 선릉로100길 1") == false` · `drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 삼성동 131") == false` | **뺀 1 · 더한 2** |
| 테헤란로 | `drvTopMatches("테헤란로 152", name: "OO빌딩", address: "서울 강남구 테헤란로 152") == true`(문구 "이름에 없는 낱말이 주소에 있으면 거짓 되묻기하지 않는다", 옛 `:1841`) | 같은 픽스처에 `== false` — 문구 "주소로만 말한 질의('테헤란로 152')는 물어본다(이름만 본다)" | **뺀 1 · 더한 1** |
| 회귀(기대값 무변경) | 주소 인자 없음 | '스타벅스 홍대점'→'스타벅스 대학로점'에 `address: "서울 종로구 대학로 116"`(NOT match) · →'스타벅스 홍대입구역점'에 `address: "서울 마포구 양화로 165"`(match)을 얹었다. '홍대역'→'홍대입구역'(match)은 무변경 — AC-002 (3)이 이 픽스처에는 주소를 명시하지 않는다 | 0(줄 수 무변경) |

#### (c) AB-H04 ✗ → ✓ (원문 — 단언 코드는 M1 그대로, 통과만 뒤집혔다)

- M1 ✗(관측 트리 `c405ff5`, §E.2 M1 표): `✗ AB-H04 '강남'→선릉과정릉(선릉로 주소)은 맞지 않는다`(`match=true — 주소의 '강남구'가 이름 낱말을 만족시켰다`) · `✗ AB-H04 '강남'→선릉과정릉(삼성동 주소)도 맞지 않는다`(`match=true — 판정은 주소를 보지 않아야 하므로 두 주소의 결과가 같다`)
- M3 ✓(이번 커밋): `✓ AB-H04 '강남'→선릉과정릉(선릉로 주소)은 맞지 않는다` · `✓ AB-H04 '강남'→선릉과정릉(삼성동 주소)도 맞지 않는다`
- `drvCheck`가 상세 문구를 ✗일 때만 찍으므로(`Tools/GuardDriver.swift:32`) 재현용 상세는 ✓ 줄에 남지 않는다 — AB절 코드는 무변경.

#### (d) 드라이버 수치 · AC-012 장부 · grep 증명

- `261/279 통과` · exit 1 · `grep -c '✗ AB-'` = **18**(M2 20 → AB-H04 두 줄 뒤집힘). 잔여 내역: H05×1·H06×2·H07×1·H08×2·H09×1·H10×1·H11×10 — 전부 M4 대상(중간 기대값). `grep '✗' <드라이버 로그> | grep -c 'AA-1\|AB-H04'` = **0**(AC-002 (3)).
- **AC-012 장부(누적 더한 42 · 뺀 4)**: M3 차분 — 뺀 2(강남 1 · 테헤란로 1) · 더한 3(강남 2 · 테헤란로 1). T = 241 + 42 − 4 = **279**(M1 +38/−0 · M2 +1/−2 · M3 +3/−2).
- **AC-002 (1) grep 증명** — `grep -n 'drvTopMatches("강남"' Tools/GuardDriver.swift` → 네 줄 모두 `address:`를 싣는다:
  - `:1837  AIAssistant.drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 선릉로100길 1") == false)`(AA-1)
  - `:1839  AIAssistant.drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 삼성동 131") == false)`(AA-1)
  - `:2198  let h4a = AIAssistant.drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 선릉로100길 1")`(AB-H04)
  - `:2201  let h4b = AIAssistant.drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 삼성동 131")`(AB-H04)
- 컴파일 경고: `grep -c 'warning:' .moai/state/verify/t16/m3-compile.log` = **24**(base·M1·M2와 동일).
- 로그: `.moai/state/verify/t16/m3-driver.log` · `.moai/state/verify/t16/m3-compile.log`.

#### M3 때 이 레인이 돌린 명령

| 명령 | 관측된 출력 |
|---|---|
| `git branch --show-current && git rev-parse --short HEAD`(착수 전) | `WT-place-resolution` · `a18154d` |
| `grep -n 'func searchTopClearlyMatches\|drvTopMatches("강남"\|테헤란로' Shared/AIAssistant.swift Tools/GuardDriver.swift`(착수 전) | `Shared/AIAssistant.swift:2713`(술퍼 정의) · `Tools/GuardDriver.swift:1835`(강남, 주소 없음) · `:1841`(테헤란로 `== true`) · `:2194`·`:2197`(AB-H04) — `:1687`(사무실 픽스처)은 오탐(테헤란로 1, 이번 대상 아님) |
| `CLAUDE.md` 드라이버 블록(§D) — stderr을 `m3-compile.log`로 | 컴파일 exit `0` · `warning:` 24줄 |
| `/tmp/gd > .moai/state/verify/t16/m3-driver.log` | exit `1` · `261/279 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` |
| `grep -c '✗ AB-' m3-driver.log` · `grep '✗' m3-driver.log \| grep -c 'AA-1\|AB-H04'` | `18` · `0` |
| `ls -d $TMPDIR/besir-gd-*` | 없음(정상 종료 정리) |

### M4 — 카드 표면 · 머무는 요청 (REQ-006~011, 2026-09-26)

- **관측 트리: 이번 커밋**(아래 커밋 SHA). 변경은 `Shared/AIAssistant.swift`·`Tools/GuardDriver.swift`·`Shared/EditCard.swift`(주석만 — AC-011 (1) 필터 0줄)+이 progress.md, 관측 로그는 `.moai/state/verify/t16/m4-driver.log`·`m4-compile.log`.
- **결과: `296/296 통과` · 드라이버 exit 0 · `✗ AB-` 0.** `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`. 샌드박스 정상 정리(`ls -d $TMPDIR/besir-gd-*` → 없음). `grep -c '✗'` 1줄은 AB절 배너 문장(✗ 문자를 안내에 포함)이고 M2·M3 로그와 같은 모양이다.

#### (a) M3 ✗ 18줄 → 전부 ✓ (원문)

| 가설 | M3 ✗ (§E.2 M1 표 참조 — 단언 코드는 그대로) | M4 ✓ 원문 |
|---|---|---|
| H-5 | `✗ AB-H05 후보 줄이 첫 렌더에 열려 있다`(`startsOpen=false`) | `✓ AB-H05 후보 줄이 첫 렌더에 열려 있다` |
| H-6 ×2 | `✗ AB-H06 활동 후보 카드 맥락 줄에 제목이 있다`(`stated=[]`) · `✗ AB-H06 반복 후보 카드 맥락 줄에 제목이 있다` | 둘 다 ✓ (같은 이름) |
| H-7 | `✗ AB-H07 왕복 가는 편 줄 캡션이 채워 온 값(집)을 적는다` | `✓ AB-H07 왕복 가는 편 줄 캡션이 채워 온 값(집)을 적는다` |
| H-8 ×2 | `✗ AB-H08 거짓 '이미 삭제' 문구가 없다` · `✗ AB-H08 바꿀 이동 구간이 없다고 사실을 말한다` | 둘 다 ✓ |
| H-9 | `✗ AB-H09 weeks 없는 재호출에 '반복 기간' 줄이 다시 서지 않는다` | **재작성** — 아래 (b) |
| H-10 | `✗ AB-H10 머무는 반복 결과가 버린 점심 인자를 말한다` | `✓ AB-H10 머무는 반복 결과가 버린 점심 인자를 말한다` |
| H-11 ×10 | 머무는 반복 카드 출발지 줄·'이동 없음'·캡션 ×3, 한 번짜리(비움) 출발지 줄·선택지 ×2, 같은 값 출발지 줄·캡션·선택지 ×3, 못 푸는 장소 장소+출발지 줄·선택지 ×2 (전부 ✗) | 전부 ✓ (M1 표의 줄 이름 그대로) — `✓ AB-H11` 11줄(수단·여유·알림 억제 회귀 방지선 포함) |

#### (b) 단언 원장 — M4 차분 **뺀 2 · 더한 19** (누적 더한 61 · 뺀 6, T = 241 + 61 − 6 = **296**)

- **뺀 2**: `AB-H09 weeks 없는 재호출에 '반복 기간' 줄이 다시 서지 않는다`(바라는 동작 원문 — 아래 재작성) · `AA-4: 출발지=목적지 반복은 기간 줄만 묻는다(수단·여유·알림 안 묻는다)`(새 계약과 맞선다 — AC-008 (1) 지시대로 제거, `AB-H11`이 대신한다. AA-4 둘째 단언 "다른 장소 반복은 수단·여유·알림을 묻는다"는 그대로 ✓).
- **더한 19**:
  1. `AB-H09 [수용] weeks 없는 재호출에도 '반복 기간' 줄이 다시 선다` — **재현됨 — 수용(I-5)**. M1 ✗ 줄(`keys=["weeks"]`)을 관측 동작 특성화로 재작성했다(REQ-001 극성 규칙). `grep -c '✓ AB-H09 \[수용\]'` = 1.
  2. `AB-H01 머무는 반복 목적지 모호('이동 없음' 뒤)` — **AC-003 10번 조합**(수리 때 추가하는 회귀 방지선). 레코드는 활동 블록뿐, 장소 = 둘째 후보, 이동 없음 뒤 후보 카드는 `{destination_query}`만 묻는다(I-1).
  3~6. `AB-H06 일정 후보 카드 맥락 줄에 제목이 있다` · `AB-H06 일정 실행 전 카드 맥락 줄에 제목이 있다` · `AB-H06 활동 실행 전 카드 맥락 줄에 제목과 묻지 않는 장소가 있다` · `AB-H06 반복 실행 전 카드 맥락 줄에 제목과 묻지 않는 장소가 있다` — REQ-007의 3도구 × 2경로 여섯 단언을 갖춘다(AC-005 (2), 기존 활동·반복 후보 카드 둘과 합쳐 `grep -c '✓ AB-H06'` = 6).
  7~10. `AB-REQ008` 넷 — 같은 즐겨찾기 이름(집/집) 제외 · 이번 대화 확정 장소 이름 제외 · 반복의 같은 검색어는 머무는 출발지 줄(AC-006 (5)) · 한 번짜리 같은 검색어는 값 캡션 출발지 줄(AC-006 (5)).
  11~19. `AB-REQ010` 아홉 — '이동 없음' 확인(활동 블록만·그룹 묶임, AC-008 (3)) · 다른 출발지 수단·여유·알림 공백 0건 블록(I-1) · 셋을 갖춘 통근 등록(가는+오는+활동) · `return_time` 누락 재호출 특성화(가지만·복귀 문구 없음 — 감사 3회차 D3 잔여 위험의 검사) · 한 번짜리 '이동 없음'(활동 1·이동 0) · 한 번짜리 다른 출발지 블록 · 한 번짜리 편도 등록(가는 1·오는 0 — 경계 B-1) · 끝 시각 없는 반복(카드 nil·`사용자에게`·0건) · 끝 시각 없는 한 번짜리(같음) — AC-008 (4)(5)(7).
- **O-6 첫 단언 — 뺀 0 · 더한 0(기대만 교체)**: 이름 `O-6: 이동 없는 활동도 못 푸는 장소면 활동 장소 줄이 뜬다(이동 줄은 그대로 없다)` → `O-6: 못 푸는 장소의 이동 없는 활동은 장소 줄과 출발지 줄이 함께 뜬다(머무는 요청)`. 옛 기대 `fields.map(\.key) == ["place_query"]` → 새 기대 `Set(keys) == ["place_query", "travel_from_query"]` + 출발지 줄에 `이동 없음` 옵션(AC-008 (5), 감사 3회차 D2의 보존 지시).

#### (c) 수리별 코드 자리 · grep 증명 (임무 지시 전부, 관측 수치)

| 대상 | 관측 |
|---|---|
| REQ-006 — `grep -c 'startsOpen' Shared/AIAssistant.swift` | **1**(후보 줄 `f.startsOpen = true`, parkForUnclearPlaces). `grep -c 'AI 카드는 전부 기본값 false' Shared/EditCard.swift` = **0**(주석 교체 — D-6 (a)). 캡션: `첫 검색 결과가 말씀하신` = **0**, `검색 결과가 말씀하신 지점인지 확실하지 않아요` = **1**, `아래 후보에서 맞는 곳을 골라 주세요` = **1** |
| REQ-007 — `grep -c 'guard tool == "create_schedule"' Shared/AIAssistant.swift` | **0**(< 1). 맥락 줄 단일 함수 `filledValueLabels`(정의 **:868**)이 세 도구를 담당하고 `pendingAsk`(실행 전)·`parkForUnclearPlaces`(후보)가 같은 함수를 부른다. 드라이버 `grep -c '✓ AB-H06'` = **6** |
| REQ-008 — 옛/새 캡션 | `가 여러 줄에 같은 이름으로 왔어요` = **0**, `이 다른 줄에도 있어요. 이 줄에 맞는 지점을 골라 주세요.` = **1**. 제외 신호 세 가지(즐겨찾기 `searchBoundPlace` · 확정 `confirmedPlaces` · 머무는 신호 `stayingOneShotActivity`가 같은 이름 줄을 건너뛴다)+반복 도구는 애초에 같은 이름 줄이 없다 |
| REQ-009 — 옛/새 캡션 | `미리 정해진 출발지가 맞는지` = **0**, `에서 출발하는지 한 번 더 골라 주세요` = **1**(`roundTripOriginNote`). 칩 `가는 편 없음`·미리 선택 없음·사무실 unknown 무칩 회귀는 기존 단언(O-6 3·4번, AB-H07)이 지킨다 |
| REQ-010 — 문구 | `'이동 없음'을 고르면 돼요` = **1**(stayingOriginNote, I-6 원문), `이동 없이 한 곳에서` = **0**, `return_time에 넣어` = **0**(< 1 — `stayingEndAsk`가 arg를 보간하므로 리터럴이 사라졌고, 문장은 `사용자에게 물어`를 포함한다), `가드는 create_schedule 경로 전용` = **0**(주석 교체 자리 **:2070** — `isSamePlace`의 사용처(create_schedule 거절 · 머무는 요청 판정)를 적는다, AC-008 (9)) |
| REQ-010 — 새 지점 | `noTravelToken` **:2818**(카드 전용 토큰, 선언 키 무변경) · `stayingRecurrenceSignal` **:788** · `stayingOneShotActivity` **:797**(T-1) · `stayingOriginField` **:807**(I-2 칩) · `stayingEndAsk` **:1908**(B-2·B-3) · `makeStayingRecurrence` **:1916**(두 신호가 같은 길 — 계약 5) · 50 m 교체는 **두 곳**(M7 — 확인 때 `stayingTokenForColocatedPick`이 주입 전 판정·좌표로 먼저 굳히고, `executeCreateActivity`의 머무는 신호 게이트가 좌표를 미리 못 얻은 경로의 방어선이다. 편도 실행부 일반 가드는 여전히 없음 — AC-008 (5) 양성 대조 `AC-D5`·`AB-REQ010 한 번짜리 다른 출발지`가 지킨다) |
| REQ-011 — AB-H08 | `executeUpdateRecurringSchedule` — 번호 없는 호출이 lastRecurrenceId의 그룹을 겨누는데 events에 그 rid가 없고 activities에만 있으면 "바꿀 이동 구간이 없어요" 사실 문구(`이동 구간` 포함, `이미 삭제됐을 수 있어요` 부재). `Shared/Store.swift` 무변경(`git diff aa7b792 -- Shared/Store.swift` 빈 출력) |
| AC-002 (3) 회귀 | `grep '✗' m4-driver.log \| grep -c 'AA-1\|AB-H04'` = **0** |
| 선언 무변경(REQ-013) | M4 diff(`e1a40a6` → HEAD)에서 `"type"`·`"required"`·`"enum"`·`"properties"`·`functionDeclarations` 줄 변경 **0**. `grep -c '"type": "[a-z]'` = **0**. aa7b792 → HEAD의 선언 영역 차이는 후보(e1a40a6)의 `origin_query` 설명 한 줄뿐(§1.2 "선언 설명 :1273" — 이 카드의 출발점이 채택한 diff) |
| 컴파일 경고 | `grep -c 'warning:' m4-compile.log` = **24**(base·M1·M2·M3와 동일 — 진단 12 + 캐럿 문맥 12) |

#### (d) M4 도중 잡은 자기 결함 1건(기록)

- **토큰이 실린 재호출에서 답을 받은 줄이 다시 서나**: 첫 실행(290/296)에서 `AB-H01 create_activity place_query`·한 번짜리 확인·R절 "편도로 만들어진다" 세 곳이 "가는 편 출발지이(가) 비어 있어요"로 막혔다. 원인 — 출발지 줄의 값이 내부 토큰(`이동 없음`/`가는 편 없음`)이면 캡션이 nil이 되고, note 없는 줄을 `missingAskedArguments`가 "비어 있다"로 세어 등록을 막았다. 수리 — 토큰은 이미 답이므로 그 줄을 다시 띄우지 않는다(askFields 두 갈래에 같은 판정). 재현 절이 수리 자체의 회귀도 잡는다는 원칙(REQ-001)의 M4 사례다.

#### M4 때 이 레인이 돌린 명령

| 명령 | 관측된 출력 |
|---|---|
| `git branch --show-current && git rev-parse --short HEAD`(착수 전) | `WT-place-resolution` · `433439c` |
| `grep -c '✗ AB-' .moai/state/verify/t16/m3-driver.log`(착수 전) | `18` |
| `CLAUDE.md` 드라이버 블록 → `m4-compile.log` / `m4-driver.log` | 컴파일 exit 0 · warning 24줄(1차 컴파일은 `from` let 상수 오류 1건 → `pickedFrom` 국소 바인딩으로 수정) · 1차 실행 `290/296` exit 1(위 (d)) → 최종 **exit 0 · `296/296 통과` · `[실제 데이터] 대조 통과`** |
| `grep -c '✓ AB-H01\|✓ AB-H06\|✓ AB-H11\|✓ AB-REQ008\|✓ AB-REQ010' m4-driver.log` | `10` · `6` · `11` · `4` · `9` |
| `ls -d $TMPDIR/besir-gd-*` | 없음(정상 종료 정리) |

### M5 — U-2 재오픈 강조 끄기 · 한 술어 · 현재 값 캡션 (REQ-012, AC-010, 2026-09-26)

- **관측 트리: 이번 커밋**(아래 커밋 SHA). 변경은 `Shared/EditCardView.swift`+이 progress.md뿐이고 관측 로그는 `.moai/state/verify/t16/m5-ios.log`. 드라이버 컴파일 집합(EditCard+AIAssistant+GuardDriver)에 이 파일이 없어 드라이버는 돌리지 않았다 — 권위 빌드 게이트는 M6이다.
- **LOC**: `wc -l` 528 → **538**(순증 +10 — plan §0 예상 "≤ 10줄" 경계 안). diff `+12/-2`(뺀 2는 같은 줄 안 교체 — 값 칩·검색 고른 칩). 세 덩어리: `fieldRow` 머리의 술어 let(+4) · 두 칩 호출 줄내 교체(±2) · `placeSearchEditor` 머리의 캡션(+6).

#### (a) AC-010 넷 — 관측 수치

| 조항 | 관측 |
|---|---|
| (1) 한 술어, 두 생산자 | 식 `let placeSearchOpen = field.kind == .place && customOpen.contains(field.id)` — 계산 자리 **:89** 하나(`fieldRow` 머리; 이 식은 파일에 이곳에만 산다). 그 결과를 읽는 두 칩 호출: 값 칩 **:120** `chip(option.label, selected: field.chosen == option.value && !placeSearchOpen, detail: option.detail)` · 검색으로 고른 칩 **:127** `chip(typed, selected: !placeSearchOpen) { openCustom(field) }`(aa7b792 좌표 :116·:122-123). 편집기가 열린 valued 장소 줄에서는 이 줄의 어떤 칩도 selected로 그려지지 않는다("장소 검색" 칩 :131은 원래 상수 false). |
| (2) `chip()` 무변경 | `sed -n '/private func chip(/,/^    }$/p'`를 `git show aa7b792:Shared/EditCardView.swift`판과 현행 파일에서 추출 → `diff` **빈 출력** · `cmp` **무출력**(양쪽 25줄). |
| (3) 캡션 + 토큰 | `grep -c '새로 고르지 않으면 그대로예요' Shared/EditCardView.swift` = **1**(:324, `placeSearchEditor` 머리 — 편집기가 열린 줄에 값이 있을 때만; X는 `field.chosenLabel`, D-10 표 원문 `지금 고른 곳: X. 새로 고르지 않으면 그대로예요.`). 색 파이프 양성 대조 `printf '+ .foregroundStyle(.gray)\n' \| grep -v 'Theme\.' \| grep -cE 'Color[.(]\|\.(gray\|black\|white\|red\|blue\|green\|orange\|yellow\|primary\|secondary\|tertiary)\b\|cornerRadius: [0-9]'` = **1**(대조 작동), 실제 `git diff aa7b792 HEAD -- Shared/EditCardView.swift \| grep '^+'`에 같은 파이프 = **0**(더한 줄은 `.font(.caption).foregroundStyle(Theme.muted)`뿐 — 토큰 경유). |
| (4) 화면별 코드 없음 | `git diff --name-only aa7b792 HEAD -- Shared/AIChatView.swift Shared/AddEventView.swift Shared/AddActivityView.swift Shared/ActivityDetailView.swift` = **0줄** — 네 화면(AIChatView :106 · AddEventView :68 · AddActivityView :72 · ActivityDetailView :64)이 공유 카드 하나로 다 같이 받는다. |

#### (b) iOS 빌드 연기(선택 smoke) — 로그 `.moai/state/verify/t16/m5-ios.log`

`iPhone 17 Pro` 시뮬레이터, `-derivedDataPath build`: exit **0** · `BUILD SUCCEEDED` · `grep "warning:" \| grep -v appintentsmetadataprocessor \| sort -u` **빈 출력**(무경고). 새 DerivedData 양측(ios+macOS) 빌드는 M6 게이트가 권위다 — 이 smoke는 컴파일 확인일 뿐.

#### M5 때 이 레인이 돌린 명령

| 명령 | 관측된 출력 |
|---|---|
| `git branch --show-current && git rev-parse --short HEAD`(착수 전) | `WT-place-resolution` · `56d5e5a` |
| `git diff aa7b792 HEAD -- Shared/EditCardView.swift \| wc -l`(착수 전) | `0`(baseline 좌표 유효) |
| `grep -n 'selected: true' Shared/EditCardView.swift`(착수 전) | `:123`(텍스트 줄 검색 고른 칩 — 수리 대상) · `:206`(시각 줄 확정 칩 — M5 범위 밖, 무변경) |
| `grep -rn 'EditCardView(' Shared/` | `AIChatView.swift:106` · `AddEventView.swift:68` · `AddActivityView.swift:72` · `ActivityDetailView.swift:64` |
| `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | exit 0 · BUILD SUCCEEDED · 무경고(위 (b)) |

### M6 — 죽은 가지·튜플 별칭·토큰 쌍·게이트 4종 (REQ-013·014, AC-011·012, 2026-09-26)

- **경과**: ai-tooling 스폰으로 시작해 **사용량 한도(429, 리셋 13:01:54)로 도중에 끊겼다** — 끊긴 시점의 몫(죽은 가지·튜플 별칭·드라이버 재실행 `296/296`)은 온전했고, 오케스트레이터가 나머지(토큰 쌍·기준선 교체·게이트 재실행·기록)를 직접 마쳤다(운영자 지시 "계속 진행해줘").
- **죽은 가지(REQ-013 (6))**: `resolveOrigin` 선언에서 `orDefault: Bool = false` 기본값을 걷었다(호출은 `:2601`의 `orDefault: true` 하나). `orDefault: true` 사다리(빈 값 → 집 → 현재 위치)와 `resolveOriginAdoption`의 기본 경로(선언 `:2803`, HEAD 호출 `:1603`·`:1803`·`:2001`)는 잔존 — 헌 좌표(:1459 등)는 후보 트리 기준이었으니 ai-tooling 렌즈 ③이 바로잡았다. 후보 카드 맥락 줄의 늘 빈 앞 항도 제거(`statedLabels() +` 삭제, 이유 주석 — 실행부 안에서만 열리는 카드라 그 항은 늘 빈 배열이었다).
- **튜플 별칭(권고, AC-011 (6))**: `typealias UnclearPlaceList` — 반복 5자리 → 1(정의 자체 1, GuardDriver 0).
- **토큰 쌍(REQ-014, plan.md:230-233 방법)**: 해니스 `.moai/state/verify/t16/tokmain.swift`(cat 연결 + 같은-파일 extension으로 private 접근 + 드라이버와 같은 임시 홈·프록시/토큰 비움) — **base `aa7b792` = 3,824**(시스템 1,704 + 툴 2,120) · **최종 트리 = 3,946**(1,771 + 2,175) · **증분 +122**. 안정성: 최종 트리 2회 실행 sha256 일치(±4 지터는 직렬화 방식 고정으로 소멸). 산출물 `token-base.{raw,txt}`·`token-final.{raw,txt}`·`token-pair.json`. base 3,824는 이전 기록의 base 3,824와 정확히 일치 — 같은 방법임이 여기서 확정됐고, 옛 4,425(2026-09-15)는 그날 트리의 값(툴 2,899 vs 지금 2,120)이었다. 루트 `plan.md` 기준선 행(:230)을 3,824로 교체하고 본문 언급(:364)도 같이 갱신했다.
- **게이트 — 판정 레인(오케스트레이터)이 최종 트리에서 직접 실행**(AC-012; 에이전트 기록 전재 아님):

| 게이트 | 명령/로그 | 관측 |
|---|---|---|
| 드라이버 | CLAUDE.md 레시피 → `gate-compile.log`·`gate-driver.log` | 컴파일 exit 0 · **드라이버 exit 0** · `296/296 통과` · `[실제 데이터] 대조 통과` (T = 241 + 61 − 6) |
| 컴파일 경고 집합 | `grep 'warning:'` → 메시지 본문 추출 → 정렬 → base(`t16-plan/compile-base.log`)판과 `diff` | **무출력 — 24줄 동일**(좌표 정규화 첫 시도는 파일 경로 접두 차만 나와 본문 기준으로 재판정) |
| iOS | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t16/dd build` → `ios.log` | `** BUILD SUCCEEDED **` 1 · `.swift` 경고 **0** · `^SwiftCompile` 42 · exit 0 |
| macOS | 같은 경로 `-scheme besir-macOS` → `macos.log` | `** BUILD SUCCEEDED **` 1 · `.swift` 경고 **0** · `^SwiftCompile` 38 · exit 0 |
| 프록시 | `npm --prefix proxy test` | **7/7 통과** · exit 0 |

- **보안 가드언 판정 반박 기록**: 런 중 sql-injection(high) 지적이 떴다 — 이 코드베이스에 SQL은 없고(JSON 영속화) `grep -rc 'SELECT \|INSERT INTO\|DELETE FROM' Shared/AIAssistant.swift Shared/Store.swift` = **0/0**. 거짓 양성으로 기각한다.
- **커밋**: `fix(SPEC-UIKIT-008): M6 죽은 가지 정리·토큰 쌍 측정 — 기준선 3,824 (card t16)` — `Shared/AIAssistant.swift` · `Tools/GuardDriver.swift` · 루트 `plan.md` · 이 파일 + run 게이트 감사 보고서(`.moai/reports/plan-audit/SPEC-UIKIT-008-2026-09-26.md`, plan 커밋의 보고서 동반 관례).

### M6 렌즈 — 3종 판정과 F-1 수리 (2026-09-26)

| 렌즈 | 판정 | 보고서 |
|---|---|---|
| code-safety | **FAIL(차단 1·선택 3) → F-1 수리로 차단 소멸**(아래) | `.moai/reports/t16/run-lens-code-safety.md` |
| ui-design | PASS(차단 0·선택 2) | `.moai/reports/t16/run-lens-ui-design.md` |
| ai-tooling | PASS(차단 0·선택 4) | `.moai/reports/t16/run-lens-ai-tooling.md` |

- **F-1(차단) — 수리됨**: D-5 턴 종료 가드가 `runLoop`의 runToolCalls 뒤(:446)에만 있고 **확인 경로**(confirmAsk → resolvePendingAsk 실행부에서 후보 카드#2 — AC-003 10번·스크립트 3·4번 길)에 없어, 카드#2 아래 모델 말풍선(AC-004 (2) 사람 절 위반)·이중 등록 창이 열렸다. 드라이버가 못 본 이유: `drvResolvePendingAsk`가 confirmAsk를 우회한다. **수리**: confirmAsk의 `resolvePendingAsk()` 뒤에 같은 가드를 거울(한 줄 + 이유 주석, `Shared/AIAssistant.swift:1147-1150`). 코드 대조로 닫는다(드라이버가 이 창을 지나지 못함).
- **선택 처리**: code-safety F-2(혼합 배치에서 첫 등록 문구가 카드 확인 전까지 안 보임)·F-3(중복 가드 문구 "같은 질문"이 다른 질의에도) — 후보, 기록만. F-4(`noTravelToken` 히스토리 에코 — 재호출에 실리면 머무는 반복으로 굳을 수 있음) — 잔여 위험, t30·실기기 확인. ui 선택 2(debouncer 창에서 캡션만 남아 "아래 후보"가 일시 거짓 — plan §3 잔여의 날 선 것 · callAI 실패 폴백에 신규 문구 노출 확대). ai 선택 4 중 ①(배너 ✗)·③(§E.2 좌표 혼용)은 `a9c63a5`에서 고쳤고 ②(AA-4 문장의 "+1" 착지 이름은 AB-H01 계열)·④(카드 열림 인라인 판정 9곳 — 관용구, 계약 위반 아님)은 기록만.
- **게이트 재실행(F-1 수리 뒤 최종 트리, 판정 레인 직접)**:

| 게이트 | 로그 | 관측 |
|---|---|---|
| 드라이버 | `gate3-compile.log`·`gate3-driver.log` | 컴파일 exit 0 · 드라이버 **exit 0** · `296/296 통과` · **`grep -c '✗'` = 0** · `[실제 데이터] 대조 통과` |
| 컴파일 경고 | `gate3-compile.log` | **24줄**(base와 동일 수) |
| iOS | `ios-final.log`(새 DerivedData 재생성) | `** BUILD SUCCEEDED **` 1 · `.swift` 경고 **0** · `^SwiftCompile` 42 · exit 0 |
| macOS | `macos-final.log` | `** BUILD SUCCEEDED **` 1 · `.swift` 경고 **0** · `^SwiftCompile` 38 · exit 0 |
| 프록시 | `npm --prefix proxy test`(dbdb5b9 시점, 이후 proxy 무변경) | 7/7 통과 · exit 0 |

### M7 — sync 1차 FAIL 수리 — D1~D5 · R1 · R6 (2026-09-28, run 레인 복귀)

sync 1차 판정(`7a1b171` — `.moai/reports/t16/sync-verdict.md` §2·§3)의 차단 다섯와 포함 권고 둘을 같은 커밋에서 닫는다. 관측 트리는 **이번 커밋**, 변경은 `Shared/AIAssistant.swift`·`Shared/EditCard.swift`·`Tools/GuardDriver.swift`+이 progress.md. 선언·프록시 무변경(diff `proxy/`·`project.yml` 0줄, 툴 JSON·시스템 프롬프트 줄 0줄 — REQ-013 유지).

#### (a) 수리 — 코드 자리와 이유

| id | 수리 | 자리 |
|---|---|---|
| D1 | 세 내부 토큰의 값 판정을 단일 출처로 묶고(`isInternalPlaceToken`) stated 맥락 줄(`filledValueLabels.add`)이 세 토큰을 모두 거른다 — `__current_location__`·`__no_outbound_leg__`이 "말씀하신 대로" 줄에 찍히던 것(S-1) | AIAssistant |
| D2·D3 | 확인 경로의 출발지 줄 주입이 **주입 전** 호출 모양으로 머묿을 확인하고, 고른 값(즐겨찾기·확정 장소·현재 위치)이 그 호출의 활동 장소·목적지와 50 m 안이면 `noTravelToken`으로 바꿔 싣는다(`stayingTokenForColocatedPick`) — 주입 뒤 인자로 판정하면 문자열 비교가 먼저 편도로 뒤집혀 missingAskedArguments에 막히거나(S-3) 거짓 실패 문구가 나갔다(S-2). 좌표는 로컬 두 단(`locallyResolvedPlace` — 즐겨찾기→확정 사전, `adoptPlace`가 같은 두 단으로 시작해 계약 5 유지)과 `currentPlace()`에서만 얻고, 못 얻으면 실행부의 기존 50 m 절이 방어선으로 남는다. 편도(create_schedule)에는 이 판정이 없다 | AIAssistant·resolvePendingAsk |
| D4 | 후보 카드가 인자를 비운 키를 `EditCard.clearedKeys`로 기록하고 확인 경로의 사전 주입을 **그 키로 한정** — 카드가 비우지 않은 빈 키(같은 턴 다른 호출의 place_query)에 고른 값이 실려 장소 없던 활동이 남의 장소로 등록되던 것(S-4). 실행 전 카드는 비운 키가 없으므로 사전 주입이 원래 목적(주입 전 재계산 — H-1 조합8)인 후보 카드에만 작동한다 | EditCard·AIAssistant |
| D5 | AC-008 (5) 양성 대조 단언 — 좌표가 '집'과 같은 두 번째 즐겨찾기('우리집') 픽스처 + **모델이 보낸** '우리집' 편도 → 가는 이동 1건(`AC-D5`) | GuardDriver AC절 |
| R1 | `sanitizeModelArgs`가 **값** 정화를 함께 한다 — 내부 토큰은 카드가 정화 뒤에 얹히는 앱 문법이라 모델 턴의 토큰은 전부 히스토리 에코고, 키만 거르면 에코가 머무는 신호로 굳는다(REQ-010 "선택으로만 확정") | AIAssistant |
| R6 | 주석 두 곳 — `isSamePlace` 사용처 나열(다섯 곳 — create_schedule 거절·활동 50 m 절·반복 갈래·확정 열쇠·카드 확인 교체)과 ask 카드 경로 좌표(`:433-436`) | AIAssistant |

#### (b) AC절 단언 14 — 원장 T = 241 + 61 − 6 + 14 = **310**

`AC-D1`×2(stated에 `__` 없음 — 현재 위치·가는 편 없음) · `AC-D2`×2(출발지 줄만 묻는다·같은 이름 선택 — 활동만+`찾지 못해` 부재) · `AC-D3`×5(우리집·현재 위치(좌표 주입 `drvSeedCurrentLocation`)·반복 우리집 — 활동만, 수단·여유·알림 미질의 포함) · `AC-D4`×4(두 호출 — A 고른 장소·B 장소 없이 등록, 변형 — B 거절 없음, 카드 줄 모양 2) · `AC-D5`(모델이 보낸 우리집 편도 — 가는 이동 1건) · `AC-R1`×2(토큰 값 정화로 소멸·부재 줄 재등장).

#### (c) 게이트 — 판정 레인이 수리 트리(8ad3abd)에서 직접 재실행, 로그 보존

로그는 `.moai/state/verify/t16/gate4-*`(2026-09-28 15:05-06, 첫 보고 후 리드 지적으로 재실행한 판 — 첫 실행은 /tmp에만 남아 증거 결손이었다).

| 게이트 | 로그 | 관측 |
|---|---|---|
| 드라이버 | `gate4-compile.log`·`gate4-driver.log` | CLAUDE.md 레시피 · 컴파일 exit 0 · 경고 **24**(base 집합과 동일 수) · 드라이버 **exit 0**(로그 말미 에코 포함) · **`310/310 통과`** · `grep -c '✗'` = 0 · `[실제 데이터] 대조 통과` · 샌드박스 잔존 0(중간 1회 실행에서 C·J절 환경 전제 8줄이 일시 네트워크로 빨간 사례 — 재실행으로 소멸, AC절과 무관) |
| iOS | `gate4-ios.log`(새 DerivedData `dd4`) | exit 0 · `BUILD SUCCEEDED` · `.swift` 경고 **0** |
| macOS | `gate4-macos.log`(같은 `dd4`) | exit 0 · `BUILD SUCCEEDED` · `.swift` 경고 **0**(appintentsmetadataprocessor 1줄은 기존 동종) |
| 프록시 | `gate4-proxy.log` | `npm --prefix proxy test` — exit 0 · **7/7 통과** |

#### (d) sync 재현 하네스 재실행(판정문 §2의 repro — 수리 트리에서)

S-1(토큰 stated 노출)·S-2(거짓 실패)·S-3b(우리집 → 활동만)·S-4(B 오염 `location=회사` → `location=nil`)·S-4v(B 거절 → 등록) — **전부 뒤집힘**. 단 **S-3a('현재 위치')는 이 하네스에서 여전히 막힌 문구**로 나온다 — repro는 LocationManager에 좌표를 심지 않아 `currentPlace()`가 nil이어서 교체가 일어나지 않는 것이고, 이 경로는 좌표 주입으로 잰 `AC-D3 현재 위치 선택(좌표 주입)` 단언이 통과한 것이 증거다. 재심사에서 repro S-3a를 읽을 때 이 각주를 함께 읽는다.

## §E.3 Run-phase Audit-Ready Signal

- run_status: **audit-ready**
- run_complete_at: 2026-09-26
- run 커밋: `0a3f59e`(M1 재현 절 — `draft → in-progress` 전이) · `a18154d`(M2 데이터 흐름) · `433439c`(M3 판정 술어) · `56d5e5a`(M4 카드 표면·머무는 요청) · `a73b6c2`(M5 U-2) · `dbdb5b9`(M6 죽은 가지·토큰 쌍 — 기준선 3,824) · `a9c63a5`(AB절 배너 ✗ 제거) · run 종결 커밋(F-1 가드 + 이 절 — SHA는 리드 보고에 명시)
- AC 행렬: **AC-001 ✅**(11/11 재현, 극성 규칙·`[수용]` 1·`[경로 제거]` 1, M1 커밋 소스 경로 GuardDriver 하나) · **AC-002 ✅**(이름만 판정, 강남 주소 픽스처 4줄 모두 address, AB-H04 ✓) · **AC-003 ✅**(`✓ AB-H01` 10/10 조합) · **AC-004 🟡**(기계 몫 ✓ — AB-H02 ✓·AB-H03 [경로 제거] ✓·가드 자리 runLoop :446 + confirmAsk 거울 ; 사람 몫 AC-014 1번 대기) · **AC-005 🟡**((1)(2)(3)(5) 기계 ✓ — startsOpen·맥락 줄 단일 함수·grep 신호 ; (4) 사람 대기) · **AC-006 ✅**(음성·양성 대조) · **AC-007 ✅**(왕복 줄·캡션) · **AC-008 ✅**(아홉 절 — AB-H11 10줄·끝 시각 선행·점심 고지·주석 교체·return_time 특성화) · **AC-009 ✅**(AB-H08·Store diff 빈 출력) · **AC-010 ✅**(술어 한 자리·chip() cmp·양성 대조·4화면 0줄) · **AC-011 ✅**(범위·계약 8절 — 판정 레인 직접 대조) · **AC-012 ✅**(게이트 4종 + 토큰 쌍 3,824→3,946(+122)·기준선 교체·경고 집합 동일) · **AC-013 ⬜**(sync — 인용 재사상·원장·양성 대조) · **AC-014 ⬜**(사람 전용 — 시뮬레이터 1~16번, 빌드는 최종 커밋 `ios-final.log`의 것) · **AC-015 ⬜**(사람 전용 — 17~20번)
- 게이트 최종 수치(판정 레인 직접, 최종 트리): 드라이버 `296/296 통과` · exit 0 · `grep -c '✗'` = 0 · 실제데이터 대조 통과 · 컴파일 경고 24(base 동일) · iOS `BUILD SUCCEEDED` 무경고(42) · macOS 무경고(38) · 프록시 7/7 · 토큰 쌍 산출물 `.moai/state/verify/t16/token-pair.json`
- **M7 갱신(2026-09-28, sync 1차 FAIL 수리 뒤)**: sync 판정 `7a1b171`의 D1~D5·R1·R6를 수리(§E.2 M7) — 드라이버 **`310/310 통과`**(T = 241 + 61 − 6 + **14**) · exit 0 · `✗` 0 · 실제데이터 대조 통과 · iOS·macOS 무경고 · 프록시 7/7 — 게이트 로그는 `.moai/state/verify/t16/gate4-*.log`(§E.2 M7 (c)). AC-008 (5)의 양성 대조 증거 결손(D5)은 `AC-D5` 단언으로 채웠다. sync 재현 하네스의 S-1·S-2·S-3b·S-4·S-4v 뒤집힘 확인(S-3a 각주는 §E.2 M7 (d)). **상태: sync 재심사 대기**(판정문 §8 순서 3 — 재현 하네스 재실행·게이트 독립 재실측).
- 렌즈: code-safety **차단 1(F-1) → 수리로 소멸** + 선택 3 기록 · ui-design PASS + 선택 2 · ai-tooling PASS + 선택 4(①③은 수리) — 보고서 `.moai/reports/t16/run-lens-{code-safety,ui-design,ai-tooling}.md`
- 잔여(이 카드 밖으로 넘기는 것): F-2·F-3(선택)·F-4(`noTravelToken` 에코 — 잔여 위험) · ui 선택 2(debouncer 창·폴백 도달) · ai 선택 ②④ · 브랜드 단일어 채택 한계(spec §3) · 한 번짜리 오는 편 부재·끝 시각 문장 되묻기(t30 중간 동작) · 시뮬레이터·실기기 사람 증거(AC-014·015·기기 확인 목록)
- 운영자 지시(리드 전달, 2026-09-26): run 완료 후 정지 — 다음 단계는 sync가 아니라 운영자 재개 지시.
- 리드 지시(2026-09-28): sync 1차 FAIL(`7a1b171`)로 run 복귀 — D1~D5 + R1 포함(값 정화) + R6 수리 뒤 §E.2·§E.3 갱신과 통지까지.

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_

- **sync 1차 판정 — FAIL(2026-09-28, sync 레인)**: 코드 차단 4(D1~D4) · 증거 결손 1(D5 — AC-008 (5) `우리집` 양성 대조 단언 부재).
  판정문 `.moai/reports/t16/sync-verdict.md`, 렌즈 원문 `.moai/reports/t16/sync-lens-{code-safety,ai-tooling}.md`, 증거 `.moai/state/verify/t16-sync/`.
  게이트 다섯·토큰 쌍은 격리 사본에서 독립 재실측으로 통과(드라이버 `296/296` · base `217/217` · 경고 집합 동일 · iOS 42/macOS 38 Swift 경고 0 · 프록시 7/7 · 3,824→3,946).
  이 절의 닫힘 신호(`sync_commit_sha` 등)는 수리 뒤 재심사가 채운다 — 판정문 §8의 순서.
- **sync 2차 재심사 — FAIL(2026-09-28, sync 레인, 대상 `894fdc1` = 코드 `8ad3abd`)**: 코드 차단 6(E1~E6 — 수리가 만든 회귀 둘: E1 값 정화가 앱이 지시한 재호출의 '이동 없음'을 지움 ·
  E2 확인 대기 중 새 대화 시 버린 등록 완료) · 증거 1(E7 AC-D5 좌표) · SPEC 1(E8 AC-011 (1)(5) 기계 판정 실패 — `manager-spec` 개정 필요). 1차 결함의 좁은 재현 경로(S-1·S-2·S-3b·S-4·S-4v)는
  닫혔고 §E.2 M7 (d)의 S-3a 각주는 받아들였다(좌표를 심은 S-3a+ 활동만). 판정문 §R2, 렌즈 원문 `sync-lens-{ai-tooling,code-safety}-r2.md`, 증거 `.moai/state/verify/t16-sync/r2/`.
  게이트는 격리 사본에서 전부 통과(드라이버 `310/310` · 경고 집합 동일 · iOS 42/macOS 38 Swift 경고 0 · 프록시 7/7 · 3,824→3,946).

## §F Phase 4 Mode Selection

- 2026-09-26 run 레인 오케스트레이터가 첫 run 스폰 전에 적는다.
- 입력: tier M · 파일 4(무거움 2 — `AIAssistant.swift` 2753줄·`Tools/GuardDriver.swift` 1991줄, 가벼움 2 — `EditCardView.swift`·`EditCard.swift` 주석 한 줄) · 도메인 = 코딩 집중(AI 도구 실행부·드라이버·공유 SwiftUI 뷰) · 동시성 이득 낮음(코딩 과제 병렬성 경고) · Agent Teams 전제 없음(명시 요청 없음)
- 평가: direct ✗(Tier M 다중 파일 의미 변경) · **serial ✓**(마일스톤별 순차 스폰 — 코딩 집중 과제의 기본) · fanout ✗(연구 중심 아님, 같은 파일의 순차 편집) · sweep ✗(30+ 파일 기계 변환 아님) · agent-team ✗(명시 요청 없음)
- Decision: serial
- 근거: 수리 전부가 AIAssistant/GuardDriver의 한 논리로 엮여 있다 — M2(데이터 흐름)가 M3(판정)·M4(카드 표면)의 전제라 순차가 안전하고, 쓰기 스폰 동시 2개 금지 규칙과도 일치한다. M6의 읽기 전용 렌즈 3종(code-safety·ui-design·ai-tooling)만 마지막에 병렬로 돌린다.

## §F.1 plan 감사 기록

- **1회차 — FAIL 0.77**(Tier M 통과선 0.80 미달) — `.moai/reports/plan-audit/SPEC-UIKIT-008-review-1.md`. must-pass 실패는 MP-7 하나이고 그것은 게이트 표식(리드 몫)이다.
  작성 결함 D2~D9·D12(차단)와 D11·D13·D14(권고 선택)를 0.1.1에서 고쳤고, 한 줄 수리로 D15~D17·D19~D22를 함께 반영했다. D18은 프로젝트 관례로 두었다. 2회차는 이 차분과 회귀만 본다.
- **2회차 — FAIL 0.89**(통과선 0.80 넘음, 점수 상승이라 STOP 신호 없음) — `.moai/reports/plan-audit/SPEC-UIKIT-008-review-2.md`, 대상 `2313e38`(0.1.1 커밋). 1회차 결함 22건은
  모두 해소 판정(D1 게이트 표식은 설계상 유지, D18은 관례 유지). must-pass 실패는 MP-7뿐이다. 새 차단 결함 셋 — D2(D-10 (b)가 D-7 (a)·D-6 (b)와 양립 불가) · D3(D-6 (b)가 수용 목록 밖의
  H-5 수용) · D4(REQ-013 sync 경로 목록이 REQ-015·AC-013 (5)의 편집을 막음) — 와 선택 D5·D7·D8을 **0.1.2**에서 고쳤다(`spec.md` HISTORY 0.1.2). 나머지 선택 D6·D9~D12는 오케스트레이터
  지시대로 두었다. 3회차(마지막)는 게이트 표식의 해소와 D2~D4의 차분, 게이트 결과로 확정된 절의 회귀만 본다.
- 0.1.2 개정 때 이 레인이 돌린 명령: `grep -c '아래 후보에서 골라 주세요' Shared/AIAssistant.swift` → `1`(후보 트리 `:735` — AC-005 (5)의 D-10 (b)+D-6 (b) 분기 기준값) ·
  `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -c 'NEEDS CLARIFICATION' plan.md` · `moai spec lint --strict .moai/specs/SPEC-UIKIT-008/spec.md` — 출력은 오케스트레이터 보고에 적었다.
- **게이트 해소 반영 — 0.1.3**(2026-09-26, 감사 회차 아님). 리드가 전한 게이트 결과로 MP-7 표식 10건을 채택 사실로 바꾸고 분기를 걷었다(위 §E.1 0.1.3 개정).
  3회차(마지막)가 볼 차분: 표식 해소(`grep -c 'NEEDS CLARIFICATION' plan.md` = 0) · D-8 번역(REQ-010 · AC-008 · AC-003 10번 · 스크립트 12~15) · H-11 · 해석 I-1~I-6(리드 확인 대상) ·
  스크립트 번호 이동(U-2 16~19, AC-014 1~15 · AC-015 16~19).
- **D-8 해석 확인 반영 — 0.1.4**(2026-09-26, 감사 회차 아님, 기준 `d3a304d`). 리드가 전한 답: I-1·I-2 확정 · I-3 거부(한 번짜리 활동까지) · I-4 운영자 문구 · I-5 (a) · I-6 (a).
  3회차(마지막)가 볼 차분: REQ-010(머무는 요청 — 두 도구, 끝 시각 선행) · REQ-008 제외 신호 · H-11 확장 · AC-003 5번 · AC-006 (5) · AC-008(아홉 절) · AC-012 (1) ·
  스크립트 3·15·16(새 한 번짜리 활동) · U-2 17~20 · 경계 B-1~B-3과 해석 T-1(리드 확인 포인트).
- **경계 해소 — 0.1.5**(2026-09-26, 감사 회차 아님, 기준 `d8d68db`). 운영자 결정(리드 전달): B-1·B-2는 분리 — 중간 동작 유지, 후속 카드 t30으로 이관. T-1·B-3은 리드에게
  확인용으로 제시 — 명시 답변 없음, 이의 없음. 계약(REQ-010·AC-008·스크립트)은 무변경. 3회차(마지막)가 볼 차분: spec §3 t30 절 · `plan.md` §2 경계 해소 문장 · §3 잔여 위험 · §6 t30.
- **3회차 — PASS 0.89**(`.moai/reports/plan-audit/SPEC-UIKIT-008-review-3.md`, 대상 `47c40f5` = 0.1.5 커밋). 차단 결함 없음, must-pass 일곱 PASS/N/A, 2회차 차단 D1~D4 해소. 선택 10건 가운데
  D1~D4를 **0.1.6**에서 PASS 뒤에 반영했다(재감사 없음 — 3회 상한, SPEC-UIKIT-007 0.1.2와 같은 기록 부채 처리): D1 50 m 판정 범위와 양성 대조 · D2 O-6 첫 단언을 기대 키 교체로 보존 ·
  D3 재호출의 `return_time` 누락을 잔여 위험과 특성화 절로 · D4 "선언을 바꿔야 한다"를 "카드 전용 키·실행부 경로, 선언 키는 늘지 않는다"로(0.1.4 B-1 행의 같은 문장도 이 기준으로 읽는다). **D5~D10은 기록된 부채**다.
  감사 권고 D6(T-1·B-3은 명시 답변 없이 채택)은 리드가 착수 승인 게이트에서 확인할 수 있는 항목이다 — SPEC 변경은 필요 없다.
- **세 회차 요약**: 0.77 FAIL → 0.89 FAIL(MP-7 게이트 표식 + 차단 3) → 0.89 PASS.

- plan_complete_at: 2026-09-26T11:34:53+09:00
- plan_status: audit-ready
- **run 게이트(Phase 1) — PASS(델타 리뷰)**(2026-09-26, `.moai/reports/plan-audit/SPEC-UIKIT-008-2026-09-26.md`). 스킵 요건의 해시 불일치(3회차 PASS는 `47c40f5` = 0.1.5 판정, 현 트리 `c405ff5` = 0.1.6 — `audit_cache` 계산 해시 `a9e59c69…`로 조회 hit 없음)로, 3회 상한을 존중해 전체 재감사 대신 0.1.6 차분만 집중 리뷰했다. 판정: 델타 PASS — 3회차 PASS 0.89 ≥ 0.80(Tier M) 지위 유지, 차단 0건 · 선택 3건(R1 `plan.md` §0 표 한 줄 — 리드 재량으로 남김, AC-012 (1) 일반 공식이 커버 · R2·R3 기록만). 판정을 같은 해시로 캐시에 저장했다.
