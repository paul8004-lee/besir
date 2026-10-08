# SPEC 감사 보고서: SPEC-UIKIT-012

Iteration: 3/3 (마지막 회차 — 에스컬레이션 보고 포함)
Verdict: FAIL — **STOP**(점수 회귀 0.80 → 0.71)
Overall Score: 0.71

- **문서 판정(게이트 표식 제외): FAIL** — 차단 결함 3건(major 2 · minor 1)이 남았다. 셋 다 0.3.0 개정이 새로 들여왔다(R3-1 자정 0시 경계, R3-2 AC-007 대조가 헛돈다, R3-3 드롭 재절단이 스냅숏을 읽는다).
- **게이트 상태**: D-3(최소 길이)·D-6(구글)·D-8(SPEC-UIKIT-009)은 물을 준비가 됐다. **D-4(자정)는 지금 문구로는 묻지 않는 것이 좋다** — 권장값 안에 R3-1 결함이 있고, "자정 넘기기" 질문이 권장 규칙의 실제 범위(이미 넘은 구간을 되돌리는 것도 막고, 늦은 저녁 활동의 연장을 수십 분 단위로 자른다)를 운영자에게 보여 주지 않는다(G-1).
- **MP-7 원문 결과: FAIL** — `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` → `plan.md:54`·`:62`·`:77`·`:91`, `research.md:97`·`:98`·`:99`·`:100`(8줄, 4주제, 이번 회차 실측 `wc -l` = 8). `spec.md`·`acceptance.md`는 0건. 명확화 게이트 발견 — 착수 승인에서 AskUserQuestion으로 닫을 몫이다.

추론 맥락은 배제했다(M1 Context Isolation — 호출자가 보낸 기능 요약은 판정 근거로 쓰지 않고 다섯 파일과 코드만 읽었다). 워크트리 `.claude/worktrees/t43`, HEAD `b59fcaa`, `git status`에 SPEC 디렉터리와 1·2회차 보고서만 미추적(코드 무변경). 1·2회차 보고서는 해소 대조에만 썼다. 줄번호는 이번 회차에 `awk 'NR==…'`·`grep -n`으로 다시 쟀다. 결함 주장 둘은 도구로 재현했다 — R3-1은 `Store.overlapsDay` 본문을 그대로 옮긴 `swift -e` 실행, R3-2는 macOS `awk` 직접 실행. 드라이버·iOS 빌드·시뮬레이터는 돌리지 않았다. 프로젝트 설정에 `audit_model`이 없어 교차 모델 감사는 하지 않았다(Claude 단독).

## Must-Pass Results

- [PASS] MP-1 REQ 번호: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → REQ-001~014 연속·중복 없음(spec.md:102~144). AC-001~012 연속(`grep -c '^## AC-' acceptance.md` = 12).
- [PASS] MP-2 GEARS(요구사항 층에서만 판정): REQ-001·002·010·011 "When …, the store shall"(spec.md:102·104·132·134), REQ-005·009 "While …"(:110·:126), 나머지 "The … shall (not)"(:106·:108·:116·:118·:120·:138·:142·:144). AC의 Given-When-Then은 검증 층이라 여기서 판정하지 않았다.
- [PASS] MP-3 프런트매터: spec.md:2~13에 12필드 — `version: "0.3.0"`, `status: draft`, `created`/`updated` "2026-10-08", `priority: P1`, `lifecycle: spec-anchored`, `tags` 쉼표 문자열. 거부 별칭 없음.
- [N/A] MP-4 언어 중립성: Swift 단일 언어 iOS 앱 SPEC.
- [PASS] MP-5 D7: 본문 참조 SPEC-UIKIT-009(32회)·011(3회) 모두 `status: completed`(각 spec.md 실측). retired/superseded/archived 없음. 009의 부분 대체는 spec.md:89·178, plan.md:89~93에 기록.
- [PASS] MP-6 D8: `grep -c syscall` 다섯 파일 모두 0.
- [FAIL] MP-7 명확화 게이트: 위 원문 결과(의도된 게이트 — 문서 판정에서는 제외).

## Category Scores

| 차원 | 점수 | 띠 | 근거 |
|---|---|---|---|
| Clarity | 0.75 | 0.75 | REQ-007(spec.md:118)의 "두 끝이 각자 날짜에 머물면 닿는 날의 집합이 같다"가 0시 경계에서 거짓(R3-1). HISTORY ④(spec.md:27)와 REQ-004(:108)의 출발 없는 동률 서술이 엇갈림(R3-4). 나머지 REQ는 한 가지로 읽힌다 |
| Completeness | 0.75 | 0.75 | 절 구성 완비(HISTORY :21, 배경 :43, 요구 :94, 불변 :146, 범위 밖 H3 4개 :160~:175, 결정 :180), sync 수리 목록은 이번 `rg` 대조에서 빠짐 없음. 다만 드래그 중 저장소가 바뀌는 경우의 잔여 위험이 없고(R3-3), AF-018-08~10·23의 연결 모양이 적혀 있지 않다(R3-5) |
| Testability | 0.50 | 0.50 | AC-007의 소유 조회 대조가 정규식 오류로 늘 0을 낸다(R3-2). AF-018-10 기대값이 결함 동작을 못박고, AF-018-23은 자기가 주장하는 성질(나열·`span`)을 재지 않는다(R3-1). 나머지 AF는 손 계산과 일치 |
| Traceability | 1.0 | 1.0 | REQ 14개가 AC 매트릭스(acceptance.md:13~26)에 모두 나오고 모든 AC가 존재하는 REQ를 가리킨다. AF-018-01~23 23개 모두 acceptance.md에 나온다(`grep -o 'AF-018-[0-9][0-9]' acceptance.md \| sort -u` = 23) |

조화평균 4 / (1/0.75 + 1/0.75 + 1/0.50 + 1/1.0) = **0.71**. 2회차 0.80보다 낮다 → LEAN 규약의 **STOP 신호**. 회귀 원인은 0.3.0 개정이 새로 만든 결함(R3-1·R3-2)이다.

## A. 2회차 결함(N-1~N-15)과 1회차 연쇄 결함의 해소 대조

| 결함 | 판정 | 근거(이번 회차 실측) |
|---|---|---|
| N-1 화면 밖 이동 | **해소, 회귀 유발** | REQ-007이 "두 끝이 각자 지금 날짜에 머문다"로 바뀌어(spec.md:118, plan.md:64) 2회차 사례(23:50→00:10, +15)는 +5로 막힌다 — 손 계산 일치. 그러나 도착이 **자기 날짜의 0시 정각**으로 오는 끌기를 허용해 새 결함을 낳았다(R3-1, 실행 재현) |
| N-2 프레임마다 조회 | 해소(잔여 R3-2·R3-3) | `onBegin`에서 한 번 구해 `ActiveDrag`에 담고(plan.md:68, spec.md:126), 후보를 같은 반복·같은 날로 좁힌다(spec.md:108, plan.md:47). 좁히기의 결과 동치는 코드로 확인 — 명시 갈래 `linkedLegs`는 `linkedActivityId == a.id`인 구간만 돌려주므로 연결 없는 구간을 담을 수 없고(`Store.swift:400-402`·`:1416-1420`), 추정 갈래는 같은 날 도착만 본다(`:1430`). 다만 이를 못박는 G 대조가 헛돈다(R3-2), 드롭 재해석이 스냅숏을 읽는다(R3-3) |
| N-3 S-6 기대 | 해소(잔여 경미 R3-7) | 공식 Δ = 5·⌊(24:00 − A − 1분)/5⌋(acceptance.md:219). A = 22:52 → 65 → 23:57, 22:55 → 60 → 23:55, 23:03 → 55 → 23:58 — 초 단위 버림(REQ-008)으로 다시 계산해도 같다. A가 24:00 이후가 되는 경우(이동 90분 이상)의 안내는 없다 |
| N-4 REQ-003 충돌 | 해소 | spec.md:106 — 반복 대상 회차와 알림 식별자 재배정(`Store.swift:1534`·`:1538`)을 예외로 적었다 |
| N-5 출발 없는 동률 | 해소(대안 채택, 잔여 R3-4) | 권고(앵커 시각 사용)와 반대로 "출발이 없으면 동률 불성립 → 소유 없음"을 택하고(spec.md:108, plan.md:47) AF-018-21 (b)로 단언했다. HISTORY ④(spec.md:27)는 "앵커 시각으로 적어"라고 써서 본문과 엇갈린다 |
| N-6 주입 여유 0 | 해소 | plan.md:120 — 여유 20·출발 = 도착 − 1200초 − 20분 대입. AF-018-11·13·21 (a) 기대 "20→5·도착 고정·출발 +15"를 `adjustBuffer`(`Store.swift:1451-1473`)로 손 계산해 일치 |
| N-7 86,400초 | 해소 | plan.md:120·acceptance.md:104 — `date(byAdding: .day, value: 60)` 뒤 하루 시작 |
| N-8 구글 대조 | 해소 | acceptance.md:183·:192. 기준 `awk '/func adjustTravelLeg/,…' \| grep -c 'enqueueCalendarUpload\|removeFromCalendar\|googleEventId'` — progress.md 0.3.0 표 `0` |
| N-9 AC-010 범위 | 해소(잔여 경미 R3-8) | acceptance.md:176 — 새 함수마다 `awk`, 갈래별 저장은 읽기 판정. 출력 디렉터리가 없다(`ls .moai/state/verify/t43` → 없음) |
| N-10 구간 없는 회차 | 해소 | spec.md:132 "shall skip an occurrence that has no such leg without editing that occurrence", plan.md:83 |
| N-11 수리 목록 | 해소 | plan.md:93·:168. 이번 `rg` 대조(옛 의미 문구 · `D-6 (a)` · `adjustTravelLeg`)에서 목록 밖 자리는 기록 보고서(`.moai/reports/t17/*`)와 참으로 남는 `AIAssistant.swift:2583`뿐이다 |
| N-12 시뮬레이터 | 해소(잔여 R3-7) | S-12(acceptance.md:226), S-13(:227), S-9 앞 반복 삭제(:222) |
| N-13 AF-018-17 | 해소 | plan.md:142, acceptance.md:160 — 표지 불변 회귀 핀, 대화상자 키는 G 대조 |
| N-14 앞선 참조 | 해소 | plan.md:120 |
| N-15 D-3 대안 | 해소 | plan.md:54, research.md:97 — 5분이면 드래그 최소 길이와 그리기 최소 높이를 나눈다 |
| D-3(1회차) → N-2·N-5 | 해소 | 위 N-2·N-5 |
| D-5·D-10(1회차) → N-3 | 해소 | 위 N-3 |
| D-6·D-7(1회차) → N-1 | **해소, 회귀 유발** | 위 N-1 → R3-1 |
| D-21(1회차, 부분) | 해소 | 위 N-11 |

같은 결함이 세 회차 내내 그대로 남은 정체(stagnation)는 없다. 다만 **자정 한계(D-5 → D-7 → N-1 → R3-1)는 네 번째 모양으로 결함이 이어졌다** — 규칙을 날짜 경계로 정의하는 방식 자체가 나열 판정(반열린 구간)과 맞지 않기 때문이다. 아래 R3-1의 수정은 그 불일치를 없애는 쪽으로 적었다.

## B. 코드에서 독립적으로 다시 유도한 결과

### B-1 자정 규칙(REQ-007)과 `span(for event:on:)`

- 나열 판정은 반열린 구간이다: `Store.overlapsDay`는 `start < d.end && end > d.start`(`Shared/Store.swift:38-41`), 계산된 구간은 `listedSpan`(`Shared/Models.swift:219`)을 거쳐 `isListed`(`:229`)가 이것을 부른다. 그래서 **도착이 정확히 D+1 0시인 구간은 D+1에 나열되지 않는다.**
- REQ-007은 "00:00 belongs to the day it starts"(spec.md:118)라 도착 D+1 0시를 D+1 날짜로 친다. 두 규약이 0시에서 갈린다.
- 재현(`swift -e`, `overlapsDay` 본문 복사): 출발 D 23:50·도착 D+1 00:10 → 나열 D·D+1 모두 true. −10(AF-018-10의 −15 기대값) 뒤 도착 == D+1 0시, "같은 날짜" true, 나열 D true · **D+1 false**. 다음 끌기의 하한 = (D+1 0시 − 도착) = **0분**.
- 화면 결과: D+1 화면에서 오는 편을 위로 끄는 동안 미리보기는 `depMin = 0`, `arrivalMin = 0`, `natural = 0 < 16` → 출발 고정 분기 `(0, 16)`(`Shared/ContentView.swift:576-580`·`:589`) — 하루 위쪽 16분짜리 토막이 그려지고, 놓으면 그 날 목록(`:87-89`)에서 블록이 사라진다. D-4가 버린 안의 사유("끄는 블록이 화면에서 사라진다", plan.md:64)와 같은 증상이다.
- 이어서 **위로는 다시 끌 수 없다**(하한 0). 활동을 오는 편으로 줄이는 길이 영구히 막힌다. 실제 이동시간이 분 단위로 떨어지면(출발 23:40 + 25분 = 00:05) −5 한 번에 이 상태가 된다.
- 하루짜리 구간·출발 0시·밤샘 활동 가는 편은 문제없다: AF-018-08 +35(23:55), 09 −20(00:00 — 출발 0시는 그날에 나열됨, `start < d.end`), 10 +5 · 밤샘 −30 모두 손 계산과 나열 판정이 일치한다.
- 출발 없는 경고 블록: 앵커 하루에만 나열되고 `span`은 날짜로 자르지 않으므로(`:559-566`, `Models.swift:230`) 전체 높이 문제가 생기지 않는다. 규칙이 앵커와 도착을 같은 값으로 두 번 재는 것도 무해하다.
- 20분 미만 활동: REQ-006이 줄이기를 0으로 막는다(AF-018-07 일치). 다만 그리기 최소 높이 20(`:555`) 때문에 활동 길이가 20분을 넘을 때까지 오는 편 미리보기가 활동 아래 끝을 "따라가지" 않고 겹쳐 보인다 — 지금의 그리기 규칙이 낳는 모양이라 결함으로 올리지 않고 잔여 위험으로 적는다.
- DST: 한국 표준시는 일광절약시간이 없다. 규칙은 `Calendar` 날짜로 재므로 DST 날에도 하루 경계는 맞다. `minutesSinceMidnight`의 벽시계 분 환산(`:523-526`)은 기존 동작이다.
- **과도한 제약의 정량 예**(게이트 G-1의 근거): ① 활동 21:00–23:00 + 귀가 40분(도착 23:40) → 오는 편으로 늘릴 수 있는 최대 +15(23:15). ② 활동 21:00–23:30 + 귀가 45분(도착 00:15) → 늘리기 최대 +25, 줄이기 최대 −15, 그리고 −15 뒤 도착이 0시 정각이 되어 이후 줄이기 영구 불가(R3-1). ③ 출발 23:50·도착 00:10 구간을 23:55 도착으로 되돌리는 것(자정을 다시 안 넘게)도 막힌다 — D 화면에서는 블록이 계속 보이는데도 그렇다. 규칙의 근거 중 "같은 날 추정이 깨진다"(spec.md:79)는 **추정(반복) 구간에만** 참이다. 명시 연결 구간의 소유는 `linkedActivityId`로 찾으므로(REQ-004 (a), `Store.swift:415-418`) 날짜와 무관하다.

### B-2 소유를 드래그 값에 담는 설계(N-2)

- `ActiveDrag`는 `Equatable`이 아니고, 쓰이는 곳은 `activeDrag != nil` 비교(`ContentView.swift:332`·`:408`·`:494`), `blockId`, `finalizeDrag(drag)`뿐이다. 히트 테스트·배치는 `ActiveDrag.Kind`만 쓴다(`:715`·`:753`). 새 필드를 `Kind`가 아니라 `ActiveDrag`에 두고 기본값을 주면 멤버별 초기화(`:460`)도 그대로 컴파일된다 — 다른 사용처 영향 없음. 히트 테스트는 `onBegin`·탭에서만 돌아 끄는 동안 영향이 없다.
- **두 소유가 갈릴 수 있다.** 앱이 활성화될 때마다 `Task`가 `syncWithGoogle` → `processSharedInbox` → `refreshUpcomingEstimates` → `rescheduleNearestNotifications`를 차례로 기다려 저장소를 고친다(`Shared/App.swift:96-104`). 네트워크 대기 뒤 메인 액터로 돌아와 고치므로 손가락이 눌린 동안이나 반복 대화상자가 떠 있는 동안 끼어들 수 있다. `refreshUpcomingEstimates`는 출발 120분 이내 구간만 다시 추정하고(`Store.swift:1547-1549`) — 정확히 "지금 끄는 저녁 구간"이 대상이다.
- 갈렸을 때: ① `finalizeDrag`는 `onBegin`에서 뜬 구간 **값**을 그대로 넘긴다(`ContentView.swift:460`·`:780`·`:783`). REQ-008이 약속한 "확정 때 다시 자르기"(spec.md:120 근거 "대화상자가 떠 있는 동안 상태가 바뀐 경우를 막고")는 드롭이 저장소의 현재 구간을 id로 다시 읽을 때만 성립하는데, 그렇게 하라는 문장이 없다(R3-3). 재추정으로 도착이 23:40 → 23:55로 바뀐 뒤 옛 값 기준 +15를 확정하면 도착 00:10 — REQ-007 위반이고, 추정 구간이면 연결이 끊긴다. ② 드롭 때 소유가 사라지면 소유 없는 경로가 **이미 소유 한계로 잘린** Δ를 받는다. ③ 드롭 때 소유가 생기면 재절단으로 0이 되어 "놓았는데 아무 일도 없다". 데이터 손상은 없지만 plan.md:69의 "같은 함수라 시작 때와 같은 결과다"는 일반적으로 거짓이다.
- `syncWithGoogle`은 gid가 이미 있는 원격 레코드를 건너뛴다(`Store.swift:1725` 이벤트, `:1762` 활동) — 드래그로 바꾼 로컬 시각을 다음 동기화가 옛 원격 시각으로 되돌리지 않는다. D-6 권장안의 전제를 이번 회차에 직접 확인했다(research.md:9가 "오케스트레이터 열람"으로 넘긴 항목).

### B-3 반복 일괄 순서와 알림

- 계획(plan.md:84): 회차마다 한계 → `shiftEvent` → 활동 가장자리, 루프 뒤 정렬(시작이 바뀐 경우) · `saveActivities()` 한 번 · "전체"면 `rescheduleNearestNotifications()` 한 번(`events = updated` `:1541`, `save()` `:1542`), "이 일정만"이면 `save()` 한 번.
- `shiftEvent`(`:1439-1447`)는 회차마다 개별 알림을 다시 건다(`rescheduleNotification` `:1476-1484`). "전체"면 26주에서 일시적으로 64건을 넘는 `add`가 생기지만 곧 `cancelAll`(`NotificationManager.swift:55-57`)이 지우고 가까운 60건을 다시 건다. 같은 모양이 이미 `addRecurringEvents`(회차마다 `applyCached…`가 예약 `:1495`·`:1508` → `rescheduleNearestNotifications` `:989`)에 있다. `center.add`(완료 콜백 비동기)와 `removeAllPending` 사이의 순서는 문서 보증을 찾지 못했다 — 선례와 같은 잔여 위험이다.
- "이 일정만": `shiftEvent`가 옛 id를 취소하고 새 id를 담은 뒤 `save()`가 그 값을 저장한다 — `notificationId`와 실제 예약이 맞는다. 그 회차가 가까운 60건 밖이었다면 61번째 예약이 생기는 것은 `moveActivity`와 같은 기존 동작이다.
- 결론: 순서는 안전하다(새 결함 없음).

### B-4 역방향 조회 · 반복 범위 · `packingGroups`

- AI 반복 생성(`AIAssistant.swift:2314-2376`): 체류 = `title`·장소 `dest`·출근 도착 시각~복귀 출발 시각, 점심시간 = `"\(title) - 점심시간"`·장소 `lunchPlace ?? dest`(`:2371`). 점심 장소가 있으면 주장이 겹치지 않고, 없으면 체류·점심시간이 출근·복귀를 함께 주장해 동률 규칙이 체류를 고른다 — AF-018-20 기대 일치.
- 점심 장소 이름이 회사와 같은 경우(예: 같은 이름 즐겨찾기): 체류의 정방향 오는 편은 도착이 이른 "점심 후 복귀"가 된다(`sameDay.first`, 이벤트가 도착순 정렬 `Store.swift:980`). 이때 진짜 복귀를 끌면 후보 0 → 소유 없음(지금 동작). 데이터 손상은 없고 "모호하면 추측하지 않는다"와 맞다.
- 첫 추정이 실패하면 그 반복의 모든 오는 편 회차가 출발 nil이다(`addRecurringEvents`: `cachedTravelSeconds == nil`이면 `applyCached…`를 건너뜀 `Store.swift:964-975`). 점심시간 활동이 회사에 있는 반복에서는 가는 편은 새 의미, 오는 편은 동률 불성립으로 옛 의미가 된다 — 비대칭(R3-4).
- `packingGroups`(`:438-452`)의 덮어쓰기(`:447-448`)로 화면 묶음은 점심시간, 드래그 소유는 체류가 될 수 있다. 체류는 따로 낱개가 되어 묶음 항목과 나란히 놓이는 기존 배치가 끄는 동안에도 그대로 유지된다(가장자리가 맞닿을 뿐 겹치지 않음). 범위 밖(spec.md:170)·잔여 위험(plan.md:185) 처리에 동의한다.
- 반복 "전체"에서 끈 회차의 정방향 같은 역할 구간은 반드시 끈 구간과 같다(후보 조건이 "정방향 결과가 그 구간을 담는다"이므로). 다른 회차는 정방향 조회 결과를 쓰며, 이것은 `moveActivity`와 같은 코드라 일관된다.

### B-5 0.3.0 개정이 들여온 새 불일치(읽기 대조)

- REQ-007 근거의 "닿는 날 집합 불변"(spec.md:118)·acceptance.md:95 "끌기 전 나열된 모든 날에서 블록이 계속 보인다"·AF-018-23의 "`span`이 나열된 날 밖의 블록을 받는 경우가 없다"(acceptance.md:102) — 0시 경계에서 거짓(R3-1).
- AC-007 G 대조의 `for` 루프(acceptance.md:143) — 정규식 오류로 헛돈다(R3-2).
- plan.md:69 "같은 함수라 시작 때와 같은 결과다" vs spec.md:120 "상태가 바뀐 경우를 막고"(R3-3).
- HISTORY ④(spec.md:27) vs REQ-004(spec.md:108)(R3-4).
- progress.md:13 `plan_status`가 아직 "0.2.0(감사 1회차 반영)"(R3-9).
- 계수: REQ 14 · AC 12 · AF-018 01~23(plan.md 23종) · 추가 20 → T = B + 20(plan.md:150, acceptance.md:198) — 재계산 일치. 바뀐 인용 전부(ContentView `:26`·`:87`·`:95`·`:458-466`·`:531`·`:540`·`:555`·`:576-580`·`:600-603`·`:711-734`·`:767-786`·`:778`, Store `:38`·`:60-62`·`:286`·`:378-380`·`:415-418`·`:436`·`:438-452`·`:481-482`·`:520`·`:1384-1410`·`:1414-1433`·`:1439-1447`·`:1454`·`:1519-1543`·`:1534`·`:1538`, Models `:165`·`:191`·`:205-206`·`:210-213`·`:388-395`, AIAssistant `:2321`~`:2376`·`:2582-2586`, GuardDriver `:306`·`:3637-3653`·`:3806-3817`·`:3823-3824`·`:4274`·`:4286-4294`·`:4321`·`:5360`, 루트 `plan.md:190`·`:458`, `CHECKLIST.md:93`·`:196`·`:202`·`:284`·`:313`)를 실측해 모두 맞음을 확인했다. `wc -l` 1828 · 972 · 5366, `ls Shared | wc -l` 27도 일치.

## C. 드라이버 검증 가능성

- 결정성: 새 픽스처는 `afInjectedLeg`(`GuardDriver.swift:3806-3817`)와 `ActivityBlock` 직접 주입이라 네트워크를 타지 않는다. 드라이버 바이너리는 번들 식별자가 없어 알림 센터가 nil이고(`NotificationManager.swift:10-13`) `schedule`이 nil을 돌려주므로, "전체" 경로의 `rescheduleNearestNotifications`가 부르는 `Date()`·`cancelAll`이 결과를 흔들지 않는다. 기준일은 `Date()` + 60일의 하루 시작이고 시각 비교는 같은 날 안의 상대값이라 실행일에 따라 갈리지 않는다(한국 표준시 기준).
- AF-018-04~22: Store의 소유 조회·한계 함수를 비공개로 두지 않으면(plan.md:50) 모두 쓸 수 있다. AF-018-19의 6레코드×2회차, 21 (b)의 `departure: nil` 복귀(`travelSeconds = nil` → `failedBlockAnchor` = 도착)도 기존 도우미로 만들 수 있다.
- **AF-018-23**: 유효 Δ 결과로 옮긴 두 끝의 날짜 대조는 쓸 수 있다. 그러나 **`span` 대조는 쓸 수 없다** — `span`은 `ContentView`의 private 함수이고 드라이버 컴파일 목록(`CLAUDE.md` 빌드 블록)에 `ContentView.swift`가 없다. 날짜 대조만으로는 R3-1을 잡지 못한다(−10 결과가 "같은 날짜"로 통과). `ScheduledEvent.isListed(on:calendar:)`(`Models.swift:229`, MainActor — 드라이버 main에서 호출 가능)로 "끌기 전 나열된 모든 날에 계속 나열된다"를 재면 `span`이 받는 목록과 같은 판정을 재게 된다(R3-1 수정에 포함).
- 공유 저장소 간섭: AF-018 절(`:3637-3683`) 뒤 저장소는 `:3783-3784`에서 비워진다. 그 사이에 저장소 전체를 건드리는 호출은 AF-010-10의 `refreshUpcomingEstimates()`(`:3770`) 하나이고, 이것은 지금부터 120분 이내 출발만 다시 추정한다(`Store.swift:1547-1549`, 네트워크). 기준일 +60일 규칙(plan.md:120)이 지켜지면 새 픽스처는 대상이 아니다 — 간섭 낮음. 그 규칙을 바꾸면 결정성이 깨진다는 점만 적어 두면 된다(R3-10).

## D. 계약 · 범위

- 출발 산식·평행이동 산술 새 복제 없음: `shiftEvent` 재사용(plan.md:84-85), AC-010의 `addingTimeInterval(-` 기준 **5**(이번 회차 실측 `5`).
- 상수 단일 출처: 최소 길이 20은 Store 하나(REQ-006, AC-004 G). 다만 **5분 단위가 두 곳**이 된다 — 제스처 반올림(`ContentView.swift:465`)과 Store 한계 함수의 0 쪽 5분 내림(REQ-008). 제스처 단위를 바꾸면 Store 내림이 따라가지 않는다(R3-6, 계약 5).
- 소스 3파일(REQ-014), 새 `Shared/` 파일 없음 → `xcodegen` 불필요, `Task` 금지(REQ-012, AC-010), 맥 빌드·검증 없음 — 문서상 일치. `span`·`ActiveDrag`·뷰 도우미는 `#if os(iOS)` 밖의 공유 코드라 맥 컴파일에도 들어간다(맥은 `activeDrag`가 늘 nil이라 동작은 같다). 맥 컴파일 성공은 정책상 확인하지 않는다 — 미검증으로 적는다.
- sync 수리 목록: B-5 N-11 대조로 완비.
- 시간 추정·번역투: `grep -c '축\|기둥\|검증경제'` 네 파일 0. "일 걸/며칠" 류 0. `spec.md`·`acceptance.md`에 `[NEEDS CLARIFICATION` 0.

## E. 시뮬레이터 스크립트

- 사람만 볼 수 있는 항목이 들어 있다: 끄는 느낌·배치(S-1·S-3·S-5·S-8), 튐(S-1·S-5·S-6), 대화상자(S-7·S-8), 한계(S-5·S-6·S-13), 실제 알림(S-11), 구글 화면(S-12), 자정 걸친 구간의 두 화면(S-13).
- 기계로 잴 수 있는 것: S-2·S-4의 최종 시각은 드라이버가 재지만 다음 단계의 출발점이라 남길 만하다.
- 빈 곳(R3-7): ① S-11은 S-1·S-3 직후 상태를 보라는데 그 상태는 S-2·S-4가 이미 되돌렸다(acceptance.md:210 "앞 단계 결과 위에서 이어간다"와 충돌). ② 상세 화면에는 "알림 시각"이 없고 "출발 N분 전"만 있다(`EventDetailView.swift:352`) — 사전 조건(:210)과 S-11의 "상세의 알림 시각"은 출발 시각 − N분으로 계산해야 한다. ③ S-6에 "A가 24:00 전(이동 90분 미만)" 조건이 없다. ④ 모레 화면에서 오는 편을 **위로** 끄는 단계가 없어 R3-1이 사람 확인에도 걸리지 않는다.

## Defects Found

R3-1. MIDNIGHT-ZERO-BOUNDARY — spec.md:118(REQ-007 "00:00 belongs to the day it starts"와 집합 불변 근거), plan.md:64·:135(AF-018-10 "−15 → −10, 도착 00:00")·:148(AF-018-23), acceptance.md:95·:101·:102 / `Shared/Store.swift:38-41`, `Shared/Models.swift:219`·`:229`, `Shared/ContentView.swift:576-580`·`:589`·`:87-89` — 자정을 걸친 구간의 도착을 자기 날짜의 0시 정각으로 끄는 것을 규칙이 허용한다. 나열은 반열린 구간이라 그 구간은 D+1 목록에서 빠지고, D+1 화면 미리보기는 0~16분 토막이 됐다가 놓으면 사라지며, 이후 위로 끄는 하한이 0이 되어 그 활동은 오는 편으로 다시 줄일 수 없다(`swift -e` 재현). AF-018-10이 이 동작을 기대값으로 못박고, AF-018-23은 날짜만 대조해 이 결함을 통과시킨다. — Severity: major — Class: blocking — Required fix: REQ-007에 "도착 날짜가 출발 날짜보다 뒤인 구간은 새 도착이 그 날의 0시보다 **엄격히 뒤**에 머문다"를 더한다(나열 판정 `overlapsDay`의 반열린 규약과 같게). AF-018-10 −15의 기대를 **−5**(출발 23:45·도착 00:05)로 고친다(Δ > −10 → 정수 분 −9 → 0 쪽 5분 내림 −5). AF-018-23은 날짜 대조 대신 "끌기 전 `isListed(on:)`가 참이던 모든 날에서 옮긴 구간도 `isListed(on:)`가 참"을 `allSatisfy`로 잰다(`span` 대조라는 표현은 지운다 — 드라이버가 `ContentView`를 컴파일하지 않는다). acceptance.md:95와 spec.md:118의 집합 불변 문장을 이 규약으로 고친다. 시뮬레이터에 S-13 뒤 "모레 화면에서 같은 구간을 위로 1시간 끈다 → 도착이 0시 직후에서 멈추고 모레 화면에 블록이 남는다"를 더한다.

R3-2. AC007-AWK-VACUOUS — acceptance.md:143 / (macOS `awk` 실행) — `for f in 'span(for activity' 'span(for event' 'dragOffsetMinutes(forEvent' …; do awk "/func ${f}/,…"`는 괄호가 이스케이프되지 않아 `awk: syntax error in regular expression func span(for activity`로 실패하고, 빈 입력에 `grep -c`가 `0`을 찍는다. 기대값이 0이라 구현이 `span` 안에서 소유 조회를 불러도 **언제나 통과**한다 — N-2 수정의 유일한 기계 증거가 헛돈다. 도우미가 `func`가 아닌 계산 속성이면 넷째 패턴도 빈 범위다. — Severity: major — Class: blocking — Required fix: 루프를 풀어 함수마다 `awk '/func span\(for activity/,/^    }$/' …`처럼 작은따옴표 안에서 괄호를 이스케이프해 적고, 각 범위에 양성 대조 `… | wc -l`(기대 1 이상, 기준 트리 `span(for event` 35줄 실측)를 함께 둔다. 도우미 이름 패턴은 `func legDragShift\|var legDragShift`로 둔다.

R3-3. DROP-RECLAMP-SNAPSHOT — spec.md:120(REQ-008), plan.md:48·:69("같은 함수라 시작 때와 같은 결과다"), plan.md:185(잔여 위험) / `Shared/ContentView.swift:460`·`:780`·`:783`, `Shared/App.swift:96-104`, `Shared/Store.swift:1547-1549` — 드롭은 `onBegin` 때 뜬 구간 값을 받는다. REQ-008의 근거("상태가 바뀐 경우를 막고")는 드롭이 저장소의 현재 구간을 다시 읽을 때만 성립하는데 요구사항에 그 문장이 없다. 활성화 때의 동기화·재추정이 드래그 중에 끼어들 수 있고, 재추정 대상(출발 120분 이내)이 곧 끄는 저녁 구간이다. 소유가 시작과 드롭에서 갈리는 경우(사라짐 → 잘린 Δ가 소유 없는 경로로, 생김 → 0이 되어 무동작)도 잔여 위험에 없다. — Severity: minor — Class: blocking — Required fix: REQ-008에 "the drop shall re-read the dragged leg by its id from the stored schedule and compute the owner and the limits from the current stored values"를 더한다(`adjustTravelLeg` 서명은 그대로, 본문 첫 줄에서 id로 다시 읽는다). plan.md:69의 "같은 결과다"를 "저장소가 그 사이 바뀌지 않았다면 같은 결과다"로 고치고, plan §7에 두 갈림 경우를 적는다.

R3-4. FAILED-RETURN-TIE — spec.md:27(HISTORY ④ "앵커 시각으로 적어")·:108(REQ-004 "a missing departure never equals"), plan.md:47, acceptance.md:62 / `Shared/Models.swift:204-213`, `Shared/Store.swift:964-975` — 모델 문서는 출발 nil인 출발 기준 회차의 앵커를 도착 시각으로 정의하는데(곧 그 회차의 출발), SPEC은 그 값을 동률에 쓰지 않는다. 첫 추정이 실패한 반복에서 점심시간이 회사에 있으면 가는 편은 새 의미, 오는 편은 옛 의미가 되는 비대칭이 생긴다. HISTORY 문구는 본문과 반대로 읽힌다. — Severity: minor — Class: optional — Required fix: (권장) 동률의 구간 쪽 값을 `failedBlockAnchor`로 두고 AF-018-21 (b)의 기대를 "소유 = 체류, 끝 +15"로 바꾼다. 지금 선택을 유지하면 HISTORY ④를 "출발 없는 오는 편은 동률에서 제외한다"로 고치고 비대칭을 plan §7에 적는다.

R3-5. FIXTURE-LINK-SHAPE — plan.md:133~135·:148, acceptance.md:99~102 — AF-018-08~10·23이 연결 방식(명시/추정)과 소유 활동의 길이를 말하지 않는다. 자정을 걸친 오는 편은 추정으로는 소유되지 않으므로(같은 날 대조 `Store.swift:1430`) 추정 픽스처로 쓰면 소유 없는 경로를 타 단언 의도가 바뀐다. AF-018-23은 활동이 짧으면 최소 길이 한계가 격자를 지배해 자정 한계를 재지 못한다. — Severity: minor — Class: optional — Required fix: 네 단언 모두 "`afInjectedLeg(linked: <활동 id>, recurrence: nil)` 명시 연결"과 활동 시각(예: 23의 하루짜리 구간은 길이 3시간 이상)을 적는다.

R3-6. STEP-CONSTANT-TWICE — spec.md:120(REQ-008 "multiple of 5 minutes") / `Shared/ContentView.swift:465` — 5분 단위가 제스처 반올림과 Store 내림 두 곳에 산다(계약 5). — Severity: minor — Class: optional — Required fix: 단위를 Store 상수 하나로 두고 제스처가 그것을 읽는다고 plan §3에 적는다(최소 길이 상수와 같은 처리).

R3-7. SIM-SCRIPT-GAPS-3 — acceptance.md:210·:219·:224·:227 / `Shared/EventDetailView.swift:352` — S-11이 이미 되돌린 상태를 가리키고, 상세에 없는 "알림 시각"을 읽게 하며, S-6에 A < 24:00 조건이 없고, 0시 경계 위로 끌기 단계가 없다. — Severity: minor — Class: optional — Required fix: S-11의 확인을 S-1·S-3 단계 안으로 옮기거나 "S-1을 다시 한다"를 적고, "알림 시각 = 상세의 출발 시각 − 'N분 전'"으로 적는다. S-6에 "A가 내일 24:00 전이 아니면 S-13으로 넘어간다"를 더한다. R3-1의 시뮬레이터 단계를 더한다.

R3-8. AC-COMMAND-HYGIENE — acceptance.md:179·:200 — `.moai/state/verify/t43/`가 없어 첫 리디렉션이 실패한다(`ls` 실측 없음). `git diff --name-only b59fcaa HEAD`는 커밋 전 변경과 미추적 새 파일(`Tools/` 쪽)을 보지 못한다. — Severity: minor — Class: optional — Required fix: 앞에 `mkdir -p .moai/state/verify/t43`, 범위 대조는 `git diff --name-only b59fcaa -- …`와 `git status --porcelain -- Shared Tools proxy project.yml`을 함께 쓴다.

R3-9. STALE-STATUS-LINES — progress.md:13, spec.md:199 — `plan_status`가 "0.2.0", 관련 문서에 2회차 보고서가 없다. — Severity: minor — Class: optional — Required fix: 0.3.0과 review-2·review-3 경로로 고친다.

R3-10. FIXTURE-HORIZON-NOTE — plan.md:120 / `Tools/GuardDriver.swift:3770`·`:3783-3784`, `Shared/Store.swift:1547-1549` — AF-018 픽스처는 저장소 초기화(`:3783`) 전까지 남고, 그 사이 AF-010-10이 저장소 전체에 `refreshUpcomingEstimates()`(120분 이내 출발, 네트워크)를 부른다. 지금의 +60일 기준일이면 무해하지만 그 이유가 문서에 없다. — Severity: minor — Class: optional — Required fix: plan §5 기준일 문장에 "지금부터 2시간 안의 픽스처를 두지 않는다 — 뒤 절의 재추정(네트워크)이 그것을 건드린다"를 한 줄 더한다.

### 게이트 상태 발견(문서 판정 제외)

G-1. GATE-D4-FRAMING — plan.md:62·:221·:226, research.md:98, spec.md:79 — 게이트 질문은 "자정 넘기기 — 권장 막기"인데, 권장 규칙은 ① 이미 자정을 넘은 구간을 넘지 않게 되돌리는 것도 막고 ② 늦은 저녁 활동의 연장을 귀가 도착까지 남은 분으로 자른다(B-1 정량 예: 23:00 끝 + 귀가 40분 → 최대 +15). 막는 근거인 같은 날 추정(spec.md:79)은 반복 추정 구간에만 해당하고 명시 연결 구간에는 해당하지 않는다. `CLAUDE.md` "카드 착수 전 설명" ①이 요구하는 구체 예시가 §9 ②에 없다. — Severity: major(게이트 준비도) — Required fix: 착수 승인 질문에 B-1의 예 ①②③과 대안을 함께 보인다. 대안 예: "추정 구간은 도착이 소유 활동 시작일에 머문다, 명시 구간은 끄는 화면의 날과 계속 겹치기만 하면 된다" — 이 안은 R3-1 문제도 같은 반열린 규약으로 풀린다. spec.md:79의 근거 문장은 "반복 추정 구간에서"로 좁힌다.

## Regression Check

| 이전 결함 | 상태 | 근거 |
|---|---|---|
| N-1 | 해소, 회귀(R3-1) | B-1 |
| N-2 | 해소(잔여 R3-2·R3-3) | A표 |
| N-3 | 해소 | acceptance.md:219 |
| N-4 | 해소 | spec.md:106 |
| N-5 | 해소(대안, 잔여 R3-4) | spec.md:108 |
| N-6~N-15 | 해소 | A표 |
| D-1(MP-7 게이트) | 미해소 — 의도된 게이트 | plan.md:54·62·77·91 |

세 회차 점수: 0.60 → 0.80 → **0.71**. 마지막 회차가 앞 회차보다 낮아 **STOP 신호**를 낸다. 무조건 4회차로 가지 말 것을 권한다.

## Recommendation (에스컬레이션 — 3회차 FAIL)

오케스트레이터가 사용자에게 세 갈래를 제시한다: (1) **PASS-with-debt** — 아래 차단 3건을 manager-spec이 고친 뒤 이 보고서의 결함 목록만으로 범위를 좁힌 확인(재감사가 아닌 델타 대조)을 거쳐 착수 승인으로 간다, (2) 범위 축소 — 자정 한계(REQ-007)를 이 카드에서 떼어 "자정 근처 구간은 지금처럼 소유 없는 동작"으로 두고 별도 카드로 넘긴다, (3) 명시적 반복 연장.

manager-spec이 고칠 순서:

1. R3-1: REQ-007에 "자정을 걸친 구간의 도착은 그 날 0시보다 엄격히 뒤"를 더하고 AF-018-10 −15 → −5, AF-018-23을 `isListed` 대조로, acceptance.md:95·spec.md:118의 집합 불변 문장을 고친다.
2. R3-2: AC-007 루프를 이스케이프된 개별 `awk`로 풀고 양성 대조를 붙인다.
3. R3-3: REQ-008에 "드롭은 구간을 id로 다시 읽어 현재 값으로 소유·한계를 구한다"를 더하고 plan.md:69·§7을 고친다.
4. 선택: R3-4~R3-10.
5. 착수 승인: 게이트 4주제를 AskUserQuestion으로 닫되, D-4는 G-1의 예시와 대안을 함께 보인다(MP-7).

결함 이력(세 회차): 1회차 22건(D-1~D-22) → 2회차 15건(N-1~N-15) → 3회차 10건 + 게이트 1건(R3-1~R3-10, G-1). 자정 한계는 매 회차 모양을 바꿔 남았다(D-5·D-7 → N-1 → R3-1) — 날짜 경계 규약(닫힌 시작)과 나열 판정(반열린 끝)이 맞지 않는 것이 공통 원인이다.

## 감사가 관측하지 못한 것

드라이버·iOS 빌드·시뮬레이터를 돌리지 않았다 — 기준 트리의 `498/498`과 AF-018 ✓/✗ 열은 코드 읽기 예상이다. R3-1은 `Store.overlapsDay` 본문을 복사한 독립 실행으로 재현했고 앱 화면에서는 보지 않았다(미리보기 토막과 사라짐은 `span` 코드에서 유도). R3-3의 "드래그 중 동기화가 끼어든다"는 코드 구조(활성화 `Task`의 await 뒤 메인 액터 변경)에서 유도한 가능성이고 실제 타이밍은 관측하지 않았다. 카카오 경로의 이동시간이 분 단위로 떨어지는지는 확인하지 않았다(R3-1이 실제 기기에서 얼마나 자주 나는지가 여기에 달렸다). `UNUserNotificationCenter`의 `add`와 `removeAllPending` 처리 순서는 문서 보증을 찾지 못했다. 공유 코드 변경 뒤 맥 컴파일 성공 여부는 정책상 확인하지 않았다. 공유 상수의 메인 액터 격리 경고는 빌드 전 가설로 남는다. 이 워크트리에 `.claude/rules/moai/workflow/spec-workflow.md`가 없어 Tier M 통과 기준값을 읽지 못했다 — 판정은 차단 결함 유무로 냈다.

🗿 MoAI
