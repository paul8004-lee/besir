# SPEC-UIKIT-008 — progress.md

칸반 카드 t16 · C7 장소 해석 UX. 2026-09-26 plan 레인이 시작했다. 워크트리는 `.claude/worktrees/t16`(branch `WT-place-resolution`),
base `aa7b792`(= `origin/master`), HEAD `e1a40a6`(이전 세션의 미커밋 후보 구현을 보존한 WIP 체크포인트).

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **pending** — `plan.md` §2의 결정 10건(D-1~D-10)과 Tier M 확인이 남아 있다. 이 신호가 여는 다음 단계는 run 착수가 아니라 착수 승인 게이트다.
- **부류 재분류.** 후보의 자기 기록 `.moai/reports/t16/progress.md:6`은 "부류: Class B(SPEC 없음, plan 건너뜀)"이다. 운영자가 **Class C(plan → run → sync)**로 바꿨고
  리드가 전했다. 그 파일은 고치지 않았다(`git diff --quiet e1a40a6 -- .moai/reports/t16/progress.md` — 이 레인은 그 경로에 쓰지 않았다). 정정은 이 줄이 맡는다.
- **운영자 결정 (a), 리드 전달**: 이 트리를 유지하고 diff를 보존(`e1a40a6`)하며, SPEC은 diff를 **후보 구현**으로 다룬다. U-2 범위는 SPEC이 권고하고 운영자가 게이트에서 정한다(D-1).
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
- **H-1~H-10 — 재현되지 않았다.** 전부 코드 추적이다. run M1이 첫 관측이 된다(REQ-001).
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
- 사용자가 후보 카드를 두고 새 발화로 넘어가면 카드는 취소되지만 히스토리에는 "카드가 자동 진행된다"는 도구 결과가 남을 수 있다(ai 렌즈 잔여 위험 — D-4·D-5가 문구를 사실로 바꾸면 줄어든다).
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
