# SPEC 감사 보고서: SPEC-UIKIT-012

Iteration: 1/3
Verdict: FAIL
Overall Score: 0.60

작성 근거에서 저자 추론 맥락은 배제했다(M1 Context Isolation). 기준 트리 `b59fcaa`(워크트리 `.claude/worktrees/t43`, 브랜치 `WT-leg-drag-resize`)에서 코드와 다섯 산출물을 직접 읽고 줄번호를 `grep -n`·`cat -n`으로 다시 쟀다. 드라이버·빌드·시뮬레이터는 돌리지 않았다(감사는 읽기 전용).

판정은 두 갈래로 FAIL이다. ① MP-7 — 게이트 표식 8건이 남아 있다(설계상 의도된 것이지만 방화벽 규칙상 실패). ② 그와 별개로, 코드 대조에서 **설계 결함 6건(blocker)** 이 나왔다. 반복 일괄의 대상 범위가 점심 활동까지 휩쓸고, 역방향 조회가 유일하지 않으며, 옛 의미로 생긴 틈을 가진 데이터에서 REQ-001이 스스로 모순되고, 자정 한계의 경계값이 REQ-007이 막으려던 바로 그 고장을 일으키며, 미리보기가 끄는 동안 반폭으로 갈라진다. 게이트 4건을 닫는 것만으로는 통과하지 않는다.

## Must-Pass Results

- [PASS] MP-1 REQ 번호 일관성: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → REQ-001~014 연속, 중복·공백 없음(spec.md:96~138). AC-001~012 연속(acceptance.md:28~181).
- [PASS] MP-2 GEARS 형식(요구사항 층만 판정): REQ-001·002·010·011 "When …"(spec.md:96·98·126·128), REQ-005·009 "While …"(:104·:120), 나머지 "The … shall (not)"(:100·102·110·112·114·132·136·138). AC는 검증 층이라 이 항목에서 판정하지 않았다. 다만 REQ-006의 "but may grow"(:110)는 규범문 안의 비형식 조동사다(D-17, 경미).
- [PASS] MP-3 프런트매터: spec.md:2~13에 12개 필드 모두 있음 — `id`·`title`·`version: "0.1.0"`(따옴표 semver)·`status: draft`·`created`·`updated`·`author`·`priority: P1`·`phase`·`module`·`lifecycle: spec-anchored`·`tags`(쉼표 문자열). 거부 별칭(`created_at` 등) 없음.
- [N/A] MP-4 언어 중립성: Swift 단일 언어 iOS 앱 SPEC.
- [PASS] MP-5 D7 교차 SPEC: 참조는 SPEC-UIKIT-009(`status: completed`, SPEC-UIKIT-009/spec.md:5)·SPEC-UIKIT-011(`status: completed`). retired/superseded/archived 없음. 009의 부분 대체는 spec.md:83·165·plan.md:74~78에 기록돼 있다.
- [PASS] MP-6 D8 플랫폼: `grep -n syscall` 다섯 파일 0건.
- [FAIL] MP-7 명확화 게이트: `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` → plan.md:48·54·66·76, research.md:86~89 — 8건(같은 4주제). **명확화 게이트 발견**: 오케스트레이터가 착수 승인 전에 AskUserQuestion으로 해소해야 한다. 아래 D-2·D-3·D-4·D-5·D-6·D-7은 이 4건 밖에서 운영자가 정해야 할 결정을 더한다.

## Category Scores

| 차원 | 점수 | 기준 띠 | 근거 |
|---|---|---|---|
| Clarity | 0.50 | 0.50 | REQ-004 "the activity of that recurrence"(spec.md:102)가 두 활동이 같은 구간을 주장할 때 정의되지 않음(D-3) · REQ-001 "move end by Δ"와 "departure equals the new activity end"(spec.md:96)가 틈 있는 데이터에서 양립 불가(D-4) · REQ-007 경계 포함 여부(spec.md:112) · D-4 산식이 출발 nil 구간에서 미정(plan.md:56) |
| Completeness | 0.75 | 0.75 | 절 구성은 갖췄다(HISTORY spec.md:21, 배경 :41, 요구 :88, 불변 :140, 범위 밖 :151~165의 H3 3개). 그러나 결정 목록(spec.md:171~180)에 운영자가 화면에서 마주칠 결정 4건이 빠졌다(D-2·D-4·D-5·D-6) |
| Testability | 0.50 | 0.50 | AF-018-14·17이 네트워크(MapKit)에 닿는다(D-8) · AF-018-08 기대와 S-6 기대가 서로 반대(D-5) · AC-006·AC-007의 구조 대조 일부가 기준 트리에서도 실패할 수 없음(D-19) · S-6 픽스처가 실제 이동시간에 따라 결과가 갈림(D-10) |
| Traceability | 0.75 | 0.75 | 모든 REQ가 AC 매트릭스에 1회 이상 나온다(acceptance.md:13~26). 다만 REQ-003의 "출발 산식 복제 금지"를 재는 AC가 없다 — plan.md:149가 AC-006·007 grep을 근거로 대지만 두 AC의 명령은 산식을 세지 않는다(D-18) |

## Defects Found

D-1. MP7-CLARIFY — plan.md:48·54·66·76, research.md:86~89 — `[NEEDS CLARIFICATION]` 8건(최소 길이·자정·구글·SPEC-009). 명확화 게이트. — Severity: critical — Class: blocking — Required fix: 착수 승인 라운드에서 4주제를 운영자가 정하고 표식을 확정 문구로 바꾼다. 같은 라운드에 D-2·D-4·D-5·D-6의 결정도 함께 올린다(D-15).

D-2. SERIES-SCOPE — spec.md:126(REQ-010), plan.md:72(D-7) — "전체"가 **그 반복의 모든 활동**의 같은 역할 구간에 적용된다. 그런데 AI 반복 생성은 출근·복귀·점심 이동·점심 후 복귀 구간과 `체류`·`점심시간` 활동을 **한 recurrenceId**로 만든다(`Shared/AIAssistant.swift:2321`의 `let recurrenceId = leg1.recurrenceId`, 같은 값 전달 :2336·:2344·:2359·:2364·:2376). 그래서 출근(가는 편)을 끌고 "전체"를 고르면 모든 `점심시간` 활동의 시작과 `점심 이동` 구간까지 Δ만큼 옮겨진다. 지금 코드는 이를 막으려고 앵커+목적지/출발지 이름으로 대상을 거른다(`Shared/Store.swift:1392-1395`). S-8(acceptance.md:198)과 AF-018-16(plan.md:120)은 점심 없는 단일 활동 반복만 쓰므로 이 결함을 잡지 못한다. — Severity: critical — Class: blocking — Required fix: 일괄 대상은 지금과 같은 역할 필터(`Store.swift:1392-1395`)로 구간을 고른 뒤 각 구간의 소유 활동을 REQ-004 함수로 찾는 꼴로 정의한다(소유 활동이 없으면 그 회차는 REQ-005 동작). AF를 하나 더해 "출근·복귀·점심 왕복이 한 recurrenceId인 2회차 반복에서 출근 '전체' −15 → 점심시간 활동·점심 구간 바이트 불변"을 단언하고, S-8에 점심 포함 변형을 둔다.

D-3. REVERSE-NONUNIQUE — spec.md:102(REQ-004), plan.md:44(D-2), research.md:46 — 역방향을 "`estimatedLegs(for: a)`가 그 구간을 담는 활동"으로 정의했지만 (a) 그런 활동이 둘일 수 있다: 점심 장소가 없거나 해석에 실패하면 점심시간 활동의 장소가 목적지(회사)가 되고(`AIAssistant.swift:2371` `location: lunchPlace ?? dest`), `estimatedLegs`는 같은 날 같은 recurrenceId·같은 장소 이름의 `.first`를 고르므로(`Store.swift:1430-1432`) `체류`와 `점심시간`이 똑같이 출근·복귀 구간을 주장한다. REQ-004는 단수 "the activity"라 선택 규칙이 없고, D-2의 일괄 경로에서는 같은 구간이 두 번 옮겨진다. (b) 정방향과 어긋난다: `linkedLegs`는 명시적 구간이 있으면 추정을 보지 않는데(`Store.swift:1414-1421`), 역방향은 `estimatedLegs`를 바로 부르므로 명시 구간이 있는 반복 활동(옛 데이터 — `Store.swift:477-482`가 허용)에 그 날의 추정 구간까지 소유 활동으로 묶는다. 그러면 활동 드래그(`moveActivity`)는 그 구간을 옮기지 않는데 구간 드래그는 활동을 옮긴다. — Severity: major — Class: blocking — Required fix: 역방향을 "같은 recurrenceId의 활동 a 가운데 `linkedLegs(for: a)`가 그 구간 id를 담는 것"으로 바꿔 정방향과 같은 규칙을 읽게 한다. 후보가 둘 이상이면 `legAnchor(role:activity:)`(`Store.swift:378-380`)가 구간의 앵커 시각과 정확히 같은 활동을 고르고, 그래도 둘 이상이면 소유 활동 없음(REQ-005)으로 처리한다고 명시한다. 드라이버에 "두 활동이 같은 구간을 추정하는 반복" 단언을 더한다.

D-4. LEGACY-GAP — spec.md:96(REQ-001)·:100(REQ-003) — REQ-001은 "끝을 Δ 옮기고 구간을 Δ 평행이동"하면 "출발 = 새 끝"이 된다고 쓰지만, 이는 출발 = 끝인 데이터에서만 참이다. 기준 트리의 의미(SPEC-UIKIT-009 plan.md:139 D-6 (a) "오는 편을 끌면 … 활동 끝과 틈이 벌어지고")로 이미 틈이 생긴 오는 편이 실데이터에 있다 — 운영자의 시뮬레이터 스크립트 18(SPEC-UIKIT-009 acceptance.md:456)이 바로 그 틈을 만들었다. 그런 구간을 끌면 "끝 += Δ"(틈 유지)와 "출발 = 새 끝"(틈 닫힘, 끝이 G+Δ 튐)이 서로 다른 결과다. SPEC 어디에도 이 경우가 없고, 시뮬레이터 사전 조건(acceptance.md:187 "일정 모두 삭제")이 그 데이터를 지워 사람 확인도 닿지 않는다. — Severity: major — Class: blocking — Required fix: 운영자 결정 게이트를 하나 더한다(권장안을 제안으로 표기: 틈 유지 — 끝·구간 모두 Δ). REQ-001 문장을 "the gap between the activity end and the leg departure unchanged"로 바꾸거나 반대 안을 택하고, AF를 추가해 틈 30분인 오는 편 +15의 기대를 못박는다.

D-5. MIDNIGHT-INCLUSIVE — spec.md:112(REQ-007), plan.md:56·112(AF-018-08), acceptance.md:94·196 — 오는 편의 한계가 "다음 날 0시를 **넘지 않는다**"라 도착 = 다음 날 0시가 허용되고, AF-018-08의 기대도 "+30(도착이 다음 날 0시)"이다. 그런데 추정 연결은 `cal.isDate($0.arrivalDate, inSameDayAs: activity.startDate)`로 대조하므로(`Store.swift:1430`) 도착이 정확히 0시인 반복 회차의 오는 편은 활동과의 추정 연결을 잃는다 — REQ-007이 근거로 든 "다음 드래그에서 다시 잇지 못한다"(spec.md:73)가 경계에서 그대로 일어난다. 또 S-6의 기대 "상세의 도착이 다음 날로 넘어가지 않았다"(acceptance.md:196)는 AF-018-08의 기대와 정면으로 어긋난다. — Severity: major — Class: blocking — Required fix: 한계를 "도착 < 다음 날 0시"(반열린)로 바꾸고 0 쪽 5분 내림을 적용한다(AF-018-08 기대는 +25, 도착 23:55). REQ-007·plan D-4 산식·AC-005·S-6을 같은 값으로 맞춘다.

D-6. PREVIEW-LANE-SPLIT — spec.md:120(REQ-009), plan.md:62(D-5), acceptance.md:127~133 — 끌리는 구간은 "지금의 평행이동 미리보기(`offsetY`)를 그대로" 쓰고 활동만 `span`에서 늘린다. 그런데 배치(`positionedBlocks`, `ContentView.swift:711-733`)는 구간의 **저장된** 범위(`span(for event:)`, offsetY 이전)로 칸을 짠다. 오는 편 +30이면 활동 범위가 14:30까지 늘어나 구간의 저장 범위 14:00~14:30과 겹치고, 같은 묶음 구성원이 겹치면 나란히 반폭으로 그린다는 규칙(`Models.swift:388-395` `overlapSlots`의 @MX:NOTE, SPEC-UIKIT-009 REQ-017)이 발동한다. 결과: **모든 연결 구간 드래그에서** 끄는 동안 활동과 구간이 반폭으로 갈라졌다가 놓는 순간 전폭으로 돌아온다. REQ-008이 막으려는 "손을 놓는 순간 블록이 튄다"가 코드로 예측되는데, SPEC은 이를 "떨림은 기기 확인 위험(S-8)"으로 사람 관찰에 넘겼다. AC-007의 구조 대조는 이 결함을 잡지 못한다. — Severity: major — Class: blocking — Required fix: 끌리는 구간의 Δ도 `span(for event:on:)` 안에서 날짜 자르기 전에 더하고, `offsetY`의 구간 가산을 없앤다(활동 드래그의 `offsetY` 경로는 그대로) — 그러면 렌더·배치·높이가 같은 범위를 읽는다. REQ-009와 plan D-5 문장을 고치고, AC-007에 "드래그 중 배치의 칸 범위 = 놓은 뒤 칸 범위"를 보이는 판정(드라이버로 `ScheduleLogic.overlapSlots` 입력을 재현하거나 S 항목에 반폭 여부를 명시 기대로)을 둔다.

D-7. MIDNIGHT-DAY-KEY — spec.md:112, plan.md:56 — 가는 편 한계는 "활동 **끝**날의 0시", 오는 편 한계는 "활동 **시작**날의 다음 날 0시"로 잡혀 있다. 자정을 넘는 활동(예: 22:00~06:00 야간 근무)에서는 가는 편 출발(전날 21시대)이 이미 끝날 0시보다 이르므로 `min(0, 끝날0시 − 출발)` = 0 → 위로 끌기(길게 하기)가 전부 막히고, 오는 편 도착도 이미 다음 날이라 아래로 끌기가 막힌다. 두 방향 모두 자정을 건너지 않는데도 막힌다. 왜 가는 편만 끝날을 기준으로 삼는지 근거가 없고, 자정을 넘는 **활동**을 다루는 AF가 없다(AF-018-10은 넘은 **구간**만). — Severity: major — Class: blocking — Required fix: 각 구간의 기준일을 그 구간이 붙은 활동 가장자리의 날로 정의한다(가는 편 = 활동 시작날, 오는 편 = 활동 끝날 다음 날 0시, D-5의 반열린 규칙 적용). 추정 연결의 같은 날 규칙과 충돌하는 반복 회차는 이미 `@MX:WARN`(Store.swift:436) 대상이라 별도로 적는다. 자정을 넘는 활동 픽스처로 AF를 하나 더한다.

D-8. DRIVER-NETWORK — acceptance.md:151(AC-009/AF-018-14)·:146(AF-018-17) — AF-018-14는 "`travelSecondsHint` 없음 → 미계산" 구간을 쓰라고 한다. 그러나 `addEvent`는 힌트가 없으면 `applyEstimate`를 기다리고(`Store.swift:896-897`), 드라이버는 프록시를 비우므로 `DirectionsService.estimate`가 MapKit으로 내려간다(`Shared/DirectionsService.swift:29-31`). 즉 결과가 Apple 네트워크에 달려 경고 블록이 안 될 수 있다. AF-018-17이 이름으로 부르는 `addRecurringEvents`도 첫 회차에서 같은 추정을 기다리고(`Store.swift:960`), 과거 시각은 건너뛰며(`:951` `anchorTime > Date()`), 끝에서 `rescheduleNearestNotifications`(`:989`)까지 돈다. 지금 드라이버는 `addRecurringEvents`를 한 번도 부르지 않는다(`grep -n addRecurringEvents Tools/GuardDriver.swift` 0건). acceptance.md:5의 "결정적, 네트워크 없음"과 어긋난다. 게다가 AF-018-17은 기준·완성 트리 모두에서 참이고, 대화상자(`ContentView.swift:778`, private 뷰)는 드라이버가 닿지 못하므로 REQ-011의 "dialog shall continue to appear"를 실제로 재지 않는다. — Severity: major — Class: blocking — Required fix: 미계산·반복 구간은 기존 도우미 `afInjectedLeg`(`Tools/GuardDriver.swift:3806`, `departure: nil`이면 `travelSeconds = nil`)로 만든다. AF-018-17은 빼거나 "주입한 추정 구간의 recurrenceId가 보존된 채 드롭 후에도 남는다" 같은 실패 가능한 단언으로 바꾸고, 대화상자 키는 S 항목으로 옮긴다.

D-9. FAILED-LEG-CLAMP — plan.md:56, plan.md:62 — 가는 편 자정 한계 산식이 "구간 출발"을 쓰는데 이동시간 미계산 가는 편은 `departureDate`가 nil이다(`Models.swift:210-213` — 앵커는 도착). D-5는 경고 블록에도 같은 의미를 적용한다고 하면서(AF-018-14) 이 구간의 한계 계산을 정의하지 않았다. — Severity: minor — Class: blocking — Required fix: 출발이 nil이면 한계 기준을 `failedBlockAnchor`(도착)로 잡는다고 D-4에 한 줄 적고, AF-018-14에 위쪽(−) 끌기 한 경우를 더한다.

D-10. SIM-S6-FRAGILE — acceptance.md:196 — `야간` 23:00~23:30, 회사→집 실제 이동시간이 30분 이상이면 오는 편 도착이 이미 다음 날이라, 끌기가 처음부터 0으로 막히고 "자정 직전에서 멈춘다"·"도착이 다음 날로 넘어가지 않았다"가 둘 다 거짓이 된다. 결과가 그날의 경로 추정에 달린다. — Severity: major — Class: blocking — Required fix: 활동 시각을 22:00~22:30처럼 이동시간과 무관하게 여유가 남는 값으로 바꾸고, 기대를 D-5의 반열린 경계(도착 23:55 이하)로 적는다.

D-11. REQ008-SCOPE — spec.md:114(REQ-008) vs spec.md:104(REQ-005)·acceptance.md:199(S-9) — REQ-008은 모든 드롭에 "유효 Δ = 미리보기 값 = 적용 값"을 요구하지만, 연결 없는 도착 기준 구간은 `clampBuffer`로 실제 변위가 달라진다(S-9가 "놓으면 10분 자리로 돌아온다"고 스스로 적음). 문서 안의 모순이다. — Severity: minor — Class: blocking — Required fix: REQ-008의 주어를 "a leg with an owning activity"로 좁힌다.

D-12. CITATION-ERRORS — 아래 줄번호가 틀렸다(기준 트리 실측, `cat -n`/`grep -n`):
  - `adjustTravelLeg`의 저장 `:1408` → 실제 **`:1409`**(`:1408`은 for 블록의 닫는 괄호): spec.md:59, spec.md:126, research.md:23, acceptance.md:168, progress.md:30.
  - "`:1401` 루프" → 루프 시작은 **`:1400`**(`for t in targets {`), `:1401`은 `if anchorKind`: acceptance.md:168.
  - 드라이버 종료 코드 `:307` → **`:306`**(`else { code = drvFail > 0 ? 1 : 0 }`; `:307`은 주석): spec.md:136, plan.md:124, progress.md:36.
  - `rescheduleNearestNotifications` `:1519-1544` → **`:1519-1543`**: spec.md:75.
  - `shiftEvent` `:1439-1448` → **`:1439-1447`**: spec.md:67.
  - `zeroUpdateIssue` 주석 `:2583-2586` → 주석은 **`:2582-2586`**: spec.md:77, plan.md:93, research.md:70, progress.md:34.
  - 루트 plan.md:190: research.md:8은 "앞 260자", plan.md:136은 "앞 300자"를 봤다고 서로 다르게 적고, 수리를 "옛 의미 서술이 **있으면** 고친다"로 미뤘다. 실제로 그 칸 끝에 "이동 블록만 옮기면 활동은 고정하고 버퍼만 조정"이 **있다**(`sed -n 190p plan.md`). SPEC이 거짓을 단정하지는 않았지만, 확인 가능한 사실을 조건문으로 남겼다.
  그 밖의 인용(ContentView `:176-182`·`:180-181`·`:458`·`:463-466`·`:470`·`:514-521`·`:531`·`:540`·`:543-556`·`:555`·`:558-592`·`:595-603`·`:711`·`:753`·`:767-786`·`:778`·`:780`·`:783`·`:899`, `:87`·`:95`; Store `:10`·`:14`·`:62`·`:134`·`:282`·`:286`·`:378-380`·`:415-418`·`:436`·`:481-482`·`:581`·`:868`·`:924`·`:955`·`:1304`·`:1361-1382`·`:1387-1410`·`:1404`·`:1406`·`:1414-1422`·`:1427-1433`·`:1446`·`:1451-1473`·`:1454`·`:1462`·`:1523`·`:1541`·`:1542`·`:1744`; Models `:165`·`:191`; 드라이버 `:3637`·`:3638-3653`·`:3666`·`:3675`·`:4321`·`:5360`; 보고서 `:23`·`:65`; SPEC-009 plan `:135-143`·spec `:158`·`:160`·acceptance `:318-319`·`:456`·design `:126`·`:190`·`:209`; CHECKLIST `:93`·`:196`·`:202`·`:284`·`:313`; 루트 plan `:458`)은 맞았다. 계수도 맞았다: REQ 14·AC 12, `wc -l` 1828·972·5366, `ls Shared | wc -l` 27, `grep -c 'Task {' Store.swift` 8, `grep -c 'drvCheck(' GuardDriver.swift` 513, `498/498`은 plan.md:458·CHECKLIST.md:284 각 1회, AF-018-04~18은 15개. — Severity: minor — Class: blocking — Required fix: 위 항목을 실측값으로 고치고, plan.md §6의 :190 행을 "칸 끝의 '이동 블록만 옮기면 활동은 고정하고 버퍼만 조정'을 새 의미로 고친다"로 확정한다.

D-13. DRIVER-COUNT — plan.md:124, acceptance.md:174 — T = B + 15는 AF-018-04~18이 **각각 drvCheck 한 번, 한 번만 실행**될 때만 맞다. 그런데 AF-018-07(+5와 −15)·AF-018-10(늦추기·되돌리기)·AF-018-17(두 성질)은 행동이 둘이고, AC-006은 AF-018-06~10에 "유효 Δ 함수 반환값 = 실제 변위" 대조를 "함께" 얹는다(acceptance.md:107). 따로 쓰면 수가 늘어난다. — Severity: minor — Class: blocking — Required fix: "AF 번호 하나 = 조건 안이 아닌 drvCheck 호출 하나(복합 조건은 &&로 묶는다)"를 plan.md §5에 명시한다.

D-14. BATCH-DUP — plan.md:72(D-7), spec.md:126 — 일괄 경로는 `shiftEvent`를 쓰지 않고 "복사본 위의 평행이동"으로 시각을 옮긴다. 그러면 도착·출발 +Δ 산술이 `shiftEvent`(`Store.swift:1442-1445`)와 일괄 경로에 두 벌이 된다(계약 5). 활동 가장자리 이동도 단일 경로·일괄 경로에 각각 생긴다. 또 REQ-010은 "events를 한 번 쓴다"고 하지만 복사본 대입 뒤 `rescheduleNearestNotifications`가 다시 `events = updated`(`:1541`)를 하므로 대입은 두 번이다(`save()`는 한 번). — Severity: minor — Class: blocking — Required fix: 구간 평행이동과 활동 가장자리 이동을 각각 Store의 순수 함수 하나로 두고 두 경로가 함께 부른다고 적는다. REQ-010의 "write"를 "persist(save()·saveActivities() 각 한 번)"로 정확히 쓴다. 복사본 대입이 `rescheduleNearestNotifications` 호출 **앞**이어야 함(그 함수가 `self.events`를 복사해 읽는다 `:1523`)을 D-7에 적는다.

D-15. MISSING-GATES — plan.md:36~78, spec.md:171~180 — 운영자가 정할 결정이 게이트 4건뿐이라고 했지만, 화면에서 바로 보이는 결정이 더 있다: 옛 틈 데이터(D-4), 점심 포함 반복의 "전체" 범위(D-2), 자정을 넘는 활동(D-7), 끄는 동안의 배치(D-6). 권장 기본값 4건 자체는 대체로 방어 가능하다 — 20분은 화면 최소 높이와 같은 값이라 근거가 있고(ContentView.swift:531·555), 구글 미반영은 `moveActivity`와 같은 물려받은 갭이다. 다만 D-4(자정)의 권장값은 D-5·D-7 때문에 지금 문구로는 고장을 낸다. — Severity: major — Class: blocking — Required fix: 위 네 결정을 plan.md §2에 〔제안〕 게이트로 더하고 착수 승인 라운드에 함께 올린다.

D-16. NONISOLATED-CONST — plan.md:86(새 상수) — Store는 `@MainActor`이고, 화면 쪽 `private static let minActivityMinutes`(`ContentView.swift:531`)가 Store 상수를 읽게 되면 격리 경고가 날 수 있다. 같은 이유로 기존 `maxBufferMinutes`는 `nonisolated static let`이다(`Store.swift:60-61`). 무경고 빌드 게이트(REQ-014)에 걸린다. — Severity: minor — Class: blocking — Required fix: 새 최소 길이 상수를 `nonisolated static let`으로 둔다고 plan.md §3에 적는다.

D-17. REQ006-MAY — spec.md:110 — "but may grow"는 규범문 안의 비형식 조동사다. — Severity: minor — Class: optional — Required fix: "…shall not shrink further, and a lengthening drop shall be applied unchanged by this limit"처럼 shall로 쓴다.

D-18. REQ003-NO-AC — spec.md:100, plan.md:149 — "출발 산식 복제 금지"를 재는 구조 대조가 없다. plan §7은 AC-006·AC-007 grep을 근거로 대지만 두 명령은 산식을 세지 않는다. — Severity: minor — Class: blocking — Required fix: AC-010에 `grep -c 'addingTimeInterval(-' Shared/Store.swift`의 기준값(양성 대조)과 기대값(증가 0)을 더한다.

D-19. WEAK-G — acceptance.md:112·120·130·169 — (a) `grep -c 'startOfDay\|minActivityMinutes - \|20 - ' ContentView.swift`는 기준 0, 기대 0이라 실패할 수 없고 `dateInterval(of: .day…)` 같은 다른 표기를 못 잡는다. (b) `inSameDayAs: activity.startDate` 계수는 글자 그대로의 복제만 잡는다. (c) `git diff | grep func offsetY…`는 SPEC 스스로 맥락 줄 한계를 인정했다. (d) 강제 언래핑 정규식은 `!=` 제외를 명령에 넣지 않았다. — Severity: minor — Class: optional — Required fix: (a)(b)는 행동 단언(D)이 주 증거임을 표에 명시하고 회귀선으로만 분류, (d)는 `grep -v '!='`를 명령에 넣는다.

D-20. SIM-GAPS — acceptance.md:185~200 — (a) S-5의 "S-2와 같은 조작으로 14:00까지 되돌린다"는 틀렸다(S-2는 위로 30분; 13:20에서 14:00으로는 아래로 40분). (b) 오는 편 출발 알림 시각(오는 편도 `shiftEvent`로 재예약)이 S-10에 없다. (c) 되돌리기(undo)가 없다는 사실을 운영자 기대로 적지 않았다. (d) 옛 틈 데이터·점심 포함 반복 항목이 없다(D-2·D-4). — Severity: minor — Class: blocking((a)) / optional((b)~(d)) — Required fix: (a)를 고치고 (b)(d)를 항목으로 더한다.

D-21. DOC-REPAIR-LIST — plan.md:128~137, plan.md:78 — sync 수리 목록에 빠진 자리: `CHECKLIST.md:93` D8의 근거 "시뮬(2026-10-05) 18번"(틈 의미를 확인한 스크립트라 새 의미의 근거가 아님), `Shared/Models.swift:391` @MX:NOTE의 "오는 편을 활동 안쪽으로 끌어 들인 구간"(연결 구간에선 더 생기지 않음 — 파일은 안 고치더라도 드리프트로 기록), 드라이버 AF-018 머리 주석 `Tools/GuardDriver.swift:3637` "전부 기준 ✓", SPEC-UIKIT-009의 `spec-compact.md`·`research.md`(D-8 "대체되는 자리"에 없음). `AIAssistant.swift:2582-2586`·`GuardDriver.swift:614`의 주석은 연결 없는 반복 구간이 여전히 `adjustBuffer`를 타므로 참으로 남는다는 SPEC의 판단(spec.md:77)은 코드로 확인했다(`Store.swift:1406` 유지, AI 반복에서 `return_time` 없는 경우 활동이 생기지 않음 `AIAssistant.swift:2331`). STATUS.md에는 해당 서술이 없다(`grep` 0건). — Severity: minor — Class: optional — Required fix: plan.md §6·D-8 표에 위 네 자리를 더한다.

D-22. CLAMP-DETAILS — plan.md:50·58 — (a) D-3 산식은 오는 편 쪽 한 방향("하한 = min(0, 20 − 길이)")만 적었고 가는 편의 대칭식(Δ ≤ max(0, 길이 − 20))이 없다. (b) 초 단위가 섞인 시각(구글 가져오기 등)에서 분 환산이 내림인지 반올림인지 미정 — 반올림이면 D-5 경계를 넘을 수 있다. (c) 반복 대화상자가 떠 있는 동안 상태가 바뀌면(포그라운드 재예약 등) 적용 시점에 한계를 다시 재는지 미정. — Severity: minor — Class: optional — Required fix: 대칭식과 "초 단위는 0 쪽으로 내린 뒤 5분 내림", "적용 시 Store가 같은 함수로 다시 자른다(상태가 같으면 결과가 같다)"를 D-3·D-5에 한 줄씩 적는다.

## 확인 결과 — 지시된 6개 점검

1. **인용·계수**: D-12에 틀린 6종을 적었다. 나머지는 실측과 일치. 드라이버 하한 498은 문서 하한이고 코드가 강제하지 않는다는 SPEC의 서술(plan.md:124)은 `Tools/GuardDriver.swift:304-306`과 일치. 루트 plan.md:190에 대해 SPEC이 거짓을 단정하지는 않았으나 조건문으로 미뤘다(D-12). 명시 구간과 반복 활동에 대한 서술(spec.md:71, research.md:51-52)은 맞다 — `Store.swift:481`은 명시 구간이 **없을 때만** 거절하고, 명시 구간은 `addEvent` 경로라 recurrenceId가 없다(`:887`이 유일한 linkedActivityId 대입, recurrenceId 대입은 `:955`뿐). 대화상자 키 결론은 세 종류 모두 성립한다: 반복 활동의 명시 구간 → 키 없음 → "이 일정만"; 추정 구간 → 키 있음; 연결 없는 반복 구간 → 키 있음 → 지금 경로. 다만 그 결론을 드라이버가 재지는 못한다(D-8).
2. **추적성·형식·검증 가능성**: 추적 OK(REQ-003 일부 제외 D-18). GEARS PASS. 드라이버로 쓸 수 없는/결정적이지 않은 AC: AF-018-14·17(D-8). 기준 트리에서도 참인 단언: AF-018-11·12·13·15·17(특성화로서 의도된 것 — 11·12는 수리 전 관측 순서가 맞다), G 대조 일부(D-19). 서로 모순되는 기대: AF-018-08 vs S-6(D-5).
3. **설계 깨기**: 20분 미만 활동(AF-018-07) 산술은 맞다. 33분 활동의 오는 편 −30 → 한계 −13 → 0 쪽 내림 −10 → 23분, 문제없음. 00:40 활동 가는 편 −30 → −10(AF-018-09) 맞고, 출발 정확히 0시는 반열린 나열(`Store.swift:38-41`)로 전날에 나오지 않는다. 오는 편 도착 정확히 0시는 나열은 괜찮지만 추정 연결이 깨진다(D-5). 자정을 넘는 활동은 두 방향이 잠긴다(D-7). DST는 한국 표준시에 없고 `Calendar.current` 하루 시작 사용 지시가 있다 — 수용. 이동시간 0·미계산 구간(D-9). 회차 길이 제각각(AF-018-16)은 산술 맞음(25분 → −5). 역방향 조회 유일성(D-3), 다음 날 도착 오는 편(`@MX:WARN` :436)은 D-5·D-7과 얽힌다. 매달린 연결은 `activity(forLeg:)`가 nil(`:415-418`)이라 REQ-005로 떨어진다 — 수용. 단일 저장: `rescheduleNearestNotifications`가 `cancelAll` 뒤 가장 가까운 60건을 다시 걸고 `save()`까지 하므로(`:1533-1542`) 일괄 경로의 별도 `save()` 생략은 안전하다. `shiftEvent`의 개별 재예약을 일괄 경로에서 쓰지 않는 것도 `cancelAll`과 충돌하지 않는다(쓰더라도 곧 취소된다). 동기 경로라 `await` 인덱스 무효화는 없다. 정렬은 일괄에만 있고 단일에는 없다(D-14의 이웃 — 역방향 동률 규칙을 `.first`에 맡기면 순서가 결과를 바꾼다, D-3). 미리보기 = 확정은 배치에서 깨진다(D-6). 히트 테스트는 `onBegin`·탭에서만 쓰여(`ContentView.swift:459`·`:473`) 드래그 중 영향 없음.
4. **계약·범위**: 소스 3파일·새 파일 0·xcodegen 불필요·맥 빌드 없음·`Task` 없음은 설계상 지켜진다(드래그 오버레이는 `#if os(iOS)` 안 `ContentView.swift:449-481`·`:849-972`). 출발 산식 넷째 복제는 없으나 평행이동 산술 이중화 위험(D-14). 최소 길이 단일 출처는 격리 지정이 필요(D-16). 수리 목록 누락(D-21). SPEC-UIKIT-009 무수정은 동결 SPEC 원칙상 방어 가능 — D-8 게이트로 운영자 확인.
5. **열린 질문**: 게이트 4건으로는 부족하다(D-15). 시뮬레이터 스크립트 보강(D-10·D-20).
6. **문체**: `grep '축\|기둥'` — acceptance.md:215의 "축소"뿐(비유어 아님). 시간 추정 없음(plan.md:22 명시). XML 태그 없음(progress.md의 `_<pending run-phase>_`는 템플릿 자리표시). REQ 본문 영어는 SPEC-UIKIT-011과 같은 관례다. 번역투 결함 없음.

## 감사가 관측하지 못한 것

- `.claude/rules/moai/workflow/spec-workflow.md`가 이 워크트리에 없어(`No such file or directory`) Tier M 통과 기준값을 읽지 못했다. 판정은 MP-7과 blocking 결함으로 이미 FAIL이라 결과에는 영향이 없다.
- 프로젝트 설정에서 `audit_model`을 찾지 못해 교차 모델(codex/glm) 감사는 돌리지 않았다(Claude 단독).
- D-16(격리 경고)은 빌드로 확인하지 않은 가설이다. run이 iOS 빌드 로그로 확인할 것.
- D-6의 반폭 분할은 `overlapSlots` 규칙을 코드로 읽은 추론이다. 화면 관측은 하지 않았다 — 고치기 전 S 항목이나 드라이버의 배치 입력 재현으로 확인하라.

## Recommendation

manager-spec이 고칠 순서:

1. D-2: REQ-010·D-7의 일괄 대상을 "지금의 역할 필터(`Store.swift:1392-1395`)로 고른 구간 → 각자의 소유 활동"으로 다시 정의하고, 점심 포함 반복 AF와 S 변형을 더한다.
2. D-3: REQ-004를 `linkedLegs` 기반 역방향 + `legAnchor` 동률 규칙 + 모호하면 소유 없음으로 바꾼다.
3. D-4·D-7·D-6: 운영자 결정 게이트 셋을 더하고(D-15), 각 결정의 REQ 문장·AF를 맞춘다. D-6은 구간 Δ를 `span(for event:)` 안으로 옮기는 안을 〔제안〕으로 적는다.
4. D-5·D-9·D-10: 오는 편 한계를 반열린으로, 출발 nil 기준을 명시하고, AF-018-08을 +25로, S-6 픽스처를 22:00대로 바꾼다.
5. D-8: AF-018-14·17의 픽스처를 `afInjectedLeg`로 바꾸고 AF-018-17을 실패 가능한 단언으로 고친다.
6. D-11~D-14·D-16·D-18: 문장·인용·계수·상수 격리를 고친다.
7. 선택: D-17·D-19~D-22.
8. 마지막으로 착수 승인 라운드에서 plan.md §2의 게이트(기존 4 + 신규 4)를 AskUserQuestion으로 닫는다(D-1).

🗿 MoAI
