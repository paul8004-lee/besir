# SPEC-UIKIT-008 — progress.md

칸반 카드 t16 · C7 장소 해석 UX. 2026-09-26 plan 레인이 시작했다. 워크트리는 `.claude/worktrees/t16`(branch `WT-place-resolution`),
base `aa7b792`(= `origin/master`), HEAD `e1a40a6`(이전 세션의 미커밋 후보 구현을 보존한 WIP 체크포인트).

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **resolved 2026-09-26** — 운영자가 정했고 칸반 리드가 이 plan 세션에 전했다. **이 세션은 운영자의 답을 직접 보지 않았다** — 아래 목록은 리드의 전달이다.
  채택: D-1 (a) U-2를 이 카드에 넣고 편집기가 열린 동안 강조를 끄며 "지금 고른 곳" 캡션 · D-2 (a) 판정 술어는 이름만 본다 · D-3 (a) 후보 카드가 비운 키를 기록하고 확인 때 그 키에 싣는다 ·
  D-4 (a) 카드는 첫 모호 호출에만, 뒤 호출에는 사실대로 · D-5 (a) 후보 카드가 서면 턴을 끝낸다 · D-6 (a) 카드가 뜰 때 후보 줄 편집기를 연다 · D-7 (a) 왕복이면 늘 묻는다 ·
  D-8 운영자 자신의 문구(아래 원문) · D-9 (a) 등록 경로 셋만 · D-10 (a) 제안 문안 원문 그대로 · Tier M 유지. 반영 자리는 `plan.md` §2 표다.
- d8_interpretations: **confirmed 2026-09-26** — 운영자의 답을 칸반 리드가 전했다(**이 세션은 직접 보지 않았다**). I-1·I-2는 적은 대로, I-3은 **거부**("한 번짜리 활동까지"),
  I-4는 운영자 문구, I-5 (a) · I-6 (a). 번역 규칙이 계약·파일 한도에 걸리는 곳의 경계 B-1~B-3과 한 번짜리 판정 범위 T-1은 **리드 확인 포인트**다(아래 0.1.4 개정).
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

#### 그은 경계와 고른 판정 — **리드 확인 포인트**(다르면 REQ-010·AC-008·스크립트 3·12~16을 개정한다)

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
- **경계 B-1~B-3 · 해석 T-1 — 리드 확인 전이다**(위 0.1.4 표).
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

_<pending run-phase>_

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_

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
