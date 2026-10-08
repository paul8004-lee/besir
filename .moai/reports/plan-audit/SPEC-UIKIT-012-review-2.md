# SPEC 감사 보고서: SPEC-UIKIT-012

Iteration: 2/3
Verdict: FAIL
Overall Score: 0.80

- **문서 판정(게이트 표식 제외): FAIL** — 차단 결함 major 3건(N-1·N-2·N-3)과 minor 3건(N-4·N-5·N-6)이 남았다.
- **게이트 상태**: 표식 4주제(D-3 최소 길이 · D-4 자정 · D-6 구글 · D-8 SPEC-UIKIT-009)는 모두 질문이 성립하고 권장 기본값에 근거가 있다. 다른 결정을 막지 않는다. 다만 D-3에서 대안(5분)을 고르면 화면 최소 높이 상수의 단일 출처 설계(REQ-006)가 같이 바뀌어야 하는데 그 처리가 적혀 있지 않고(N-15), D-4의 권장값은 N-1 결함을 품는다.
- **MP-7 원문 결과: FAIL** — `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` → `plan.md:54`·`:62`·`:77`·`:91`, `research.md:97`·`:98`·`:99`·`:100`(8줄, 4주제). `spec.md`·`acceptance.md`는 0건.

추론 맥락은 배제했다(M1 Context Isolation — 호출자가 보낸 기능 요약은 판정 근거로 쓰지 않았다). 워크트리 `.claude/worktrees/t43`, HEAD `b59fcaa`(코드 무변경, `git status`에 SPEC 디렉터리와 1회차 보고서만 미추적). 1회차 보고서는 결함 해소 대조에만 썼다. 줄번호는 이번 회차에 `sed -n`·`grep -n`·`awk`로 다시 쟀다. 드라이버·iOS 빌드·시뮬레이터는 돌리지 않았다. 지역 함수 앞선 참조는 `swiftc`(Apple Swift 6.3.3)로 직접 확인했다(C절).

## Must-Pass Results

- [PASS] MP-1 REQ 번호: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → REQ-001~014 연속·중복 없음(spec.md:101~143). AC-001~012 연속(acceptance.md:28~191).
- [PASS] MP-2 GEARS(요구사항 층에서만 판정): REQ-001·002·010·011 "When …, the store shall"(spec.md:101·103·131·133), REQ-005·009 "While …"(:109·:125), 나머지 "The … shall (not)"(:105·:107·:115·:117·:119·:137·:141·:143). 1회차의 "may grow"는 "shall reject … shall apply"로 바뀌었다(:115). AC는 Given-When-Then 검증 층이라 여기서 판정하지 않았다.
- [PASS] MP-3 프런트매터: spec.md:2~13에 12필드 — `version: "0.2.0"`(따옴표 semver), `status: draft`, `created`/`updated` "2026-10-08", `priority: P1`, `lifecycle: spec-anchored`, `tags` 쉼표 문자열. 거부 별칭 없음.
- [N/A] MP-4 언어 중립성: Swift 단일 언어 iOS 앱 SPEC.
- [PASS] MP-5 D7: 본문 참조 SPEC-UIKIT-009·011 둘 다 `status: completed`(각 spec.md 실측). retired/superseded/archived 없음. 009의 부분 대체는 spec.md:88·177·plan.md:89~93에 기록.
- [PASS] MP-6 D8: `grep -n syscall` 다섯 파일 0건.
- [FAIL] MP-7 명확화 게이트: 위 원문 결과. **명확화 게이트 발견** — 착수 승인 라운드에서 오케스트레이터가 AskUserQuestion으로 닫을 몫이다.

## Category Scores

| 차원 | 점수 | 띠 | 근거 |
|---|---|---|---|
| Clarity | 0.75 | 0.75 | REQ-003(spec.md:105)과 REQ-010(:131)이 글자 그대로는 충돌(N-4). REQ-004 동률 규칙이 출발 없는 경고 블록 오는 편을 다루지 않음(N-5). 나머지 REQ는 한 가지로 읽힌다 |
| Completeness | 0.75 | 0.75 | 절 구성 완비(HISTORY :21, 배경 :42, 요구 :93, 불변 :145, 범위 밖 H3 4개 :159~:174, 결정 :179). sync 수리 목록에 빠진 자리가 남았다(N-11) |
| Testability | 0.75 | 0.75 | S-6 기대값이 일반적인 경우에 틀림(N-3). `afInjectedLeg`의 여유 0 고정 때문에 AF-018-11 기대가 그대로는 도달 불가(N-6). 나머지 AF는 손으로 계산한 기대와 일치(B-2절) |
| Traceability | 1.0 | 1.0 | REQ 14개가 AC 매트릭스(acceptance.md:13~26)에 모두 나오고 모든 AC가 존재하는 REQ를 가리킨다. AF-018-04~22 19개가 AC 본문에 빠짐없이 배정됨(AC-001 04·22, AC-002 05, AC-003 11·12·13·21, AC-004 06·07, AC-005 08·09·10, AC-006 15, AC-008 16~20, AC-009 14) |

## A. 1회차 결함 해소 대조

| 1회차 | 판정 | 근거(이번 회차 실측) |
|---|---|---|
| D-1 MP-7 | 미해소(의도된 게이트) | plan.md:54·62·77·91, research.md:97~100 |
| D-2 반복 범위 | 해소 | REQ-010이 소유 활동과 `recurrenceId`·제목·장소 이름이 같은 활동으로 좁혔다(spec.md:131, plan.md:83). AI 생성에서 체류 제목은 `title`, 점심시간은 `"\(title) - 점심시간"`이라(`Shared/AIAssistant.swift:2340`·`:2371`) 둘이 갈린다. AF-018-19(acceptance.md:147)·S-9(:209) 추가 |
| D-3 역방향 유일성 | 해소, 새 문제 유발 | 명시 → 정방향 `linkedLegs` 후보 → 앵커 동률 → 모호하면 없음(spec.md:107, plan.md:46~48). 점심 장소가 없는 반복에서 체류(09:00 시작)만 출근 도착 09:00과 같아 동률이 풀린다(`AIAssistant.swift:2314`·`:2340`·`:2371`) — AF-018-20 기대와 일치. 대신 후보를 반복 전체에서 훑는 비용을 제스처 프레임마다 치를 수 있다(N-2), 출발 없는 오는 편 동률(N-5) |
| D-4 옛 틈 | 해소 | REQ-001 "existing gap … stays the same"(spec.md:101), D-9(plan.md:95~97), AF-018-22(acceptance.md:38) |
| D-5 자정 포함 경계 | 해소, 새 문제 유발 | 도착 < 다음 날 0시(spec.md:117, plan.md:64). AF-018-08 기대 +35를 손으로 재계산해 맞음을 확인(B-2). 그러나 S-6의 "23:55 이하" 기대가 틀린다(N-3) |
| D-6 미리보기 반폭 | 해소, 새 문제 유발 | 소유 구간 이동을 `span(for event:on:)` 안으로(spec.md:125, plan.md:70~71). 그런데 "자르기 전에 옮긴다"와 REQ-007의 허용 범위가 만나 자정 걸친 구간이 그리는 날 밖으로 완전히 나가면 0~1440분 전체 높이 블록이 그려진다(N-1) |
| D-7 밤샘 활동 잠김 | 해소, 새 문제 유발 | 기준이 구간 자신이 닿은 날로 바뀌어 22:00–다음 날 06:00 활동의 가는 편 −30이 풀린다(AF-018-10, acceptance.md:101). 이 완화가 N-1의 원인이다 |
| D-8 드라이버 네트워크 | 해소(잔여 경미) | `afInjectedLeg`·`ActivityBlock` 직접 주입(plan.md:120), 결정성 grep(acceptance.md:186). 대화상자 키는 `finalizeDrag` 본문 `diff`로 이동(:133~:137·:154). AF-018-17은 픽스처가 넣은 값을 되읽는 회귀 핀으로 남았다(N-13) |
| D-9 출발 nil 한계 | 해소 | "앵커 시각으로 첫 부등식"(plan.md:64, spec.md:117), AF-018-14에 −15(acceptance.md:161). `failedBlockAnchor`는 `Shared/Models.swift:210-213` 실측 일치 |
| D-10 S-6 취약 | 해소, 새 문제 유발 | 22:00–22:30·도착 A 기록·이동 85분 미만 조건(acceptance.md:206). 기대값 문제는 N-3 |
| D-11 REQ-008 범위 | 해소 | "For a leg with an owning activity"(spec.md:119), 소유 없는 구간은 조항 밖이라 명시 |
| D-12 인용 | 해소 | `:1409`(`Store.swift:1409 save()`), 루프 `:1400`, 종료 코드 `GuardDriver.swift:306`, `:1519-1543`, `:1439-1447`, `AIAssistant.swift:2582-2586`(2582 "// 현재 값은…" ~ 2586, 2587 `let series`) 모두 실측 일치. 루트 `plan.md:190` 수리는 무조건으로 바뀌었다(plan.md:163) — 그 줄 끝에 "이동 블록만 옮기면 활동은 고정" 실재 |
| D-13 계수 규칙 | 해소 | plan.md:122 "번호 하나 = 조건·반복 밖에서 한 번 실행되는 `drvCheck` 하나". 기존 AF-018-01~03도 `&&` 한 호출 꼴(`GuardDriver.swift:3660`·`:3669`·`:3678`) |
| D-14 일괄 복제 | 해소 | `shiftEvent` 재사용 + 루프 밖 저장(plan.md:84~85). 순서 안전성은 B-3에서 확인 |
| D-15 게이트 부족 | 거절(대체 처리 수용) | 새 게이트 대신 〔제안〕으로 적용하고 착수 설명 §9 ②에 예시와 함께 나열(plan.md:220~225, progress.md:77). 운영자가 착수 승인에서 볼 수 있으므로 문서 결함으로 보지 않는다 |
| D-16 격리 상수 | 해소(가설 유지) | plan.md:58 〔가설〕 + AC-011 5(acceptance.md:188) 무경고 빌드로 확인 |
| D-17 "may grow" | 해소 | spec.md:115 |
| D-18 REQ-003 AC | 해소(잔여 경미) | AC-010 `grep -c 'addingTimeInterval(-' Shared/Store.swift` 기준 5 — 이번 회차 실측 `5`. 평행이동 산술 복제는 명령 없이 "대입이 없다"는 읽기 기준만 있다(acceptance.md:179) |
| D-19 약한 G | 해소 | 회귀선 분류·D 주 증거 명시(acceptance.md:107·:116), `grep -v '!='` 포함(:172) |
| D-20 시뮬레이터 | 해소 | S-5 "40분 아래로"(acceptance.md:205), S-11 오는 편 알림(:211), 실행 취소 없음(:197), 점심 포함 S-9(:209) |
| D-21 수리 목록 | 부분 해소 | CHECKLIST D8, `Models.swift:391`, 드라이버 `:3637`, SPEC-009 사본 추가(plan.md:161~166·:93). 그러나 새로 빠진 자리가 있다(N-11) |
| D-22 한계 세부 | 해소 | 가는 편 대칭식(plan.md:56), 초 버림 뒤 5분 내림(:64), 확정 때 재적용(spec.md:119) |

## B. 코드에서 독립적으로 다시 유도한 결과

### B-1 역방향 조회

- 명시 연결: `activity(forLeg:)`가 `linkedActivityId`로만 찾고 매달리면 nil(`Shared/Store.swift:415-418`). 명시 구간은 `addEvent` 경로라 `recurrenceId`가 없다(매개변수 `:868`, `recurrenceId` 대입은 `:955` 하나).
- 추정: `linkedLegs`는 명시 구간이 하나라도 있으면 추정을 보지 않는다(`:1416-1420`), 추정은 같은 `recurrenceId`·활동 시작일과 같은 날 도착·장소 이름 대조·`.first`(`:1428-1432`).
- 사례 ① 점심 장소 있음: 출근(도착 기준, 목적지 회사 `AIAssistant.swift:2314`)·복귀(출발 기준, 출발지 회사 `:2332`)·점심 이동(도착 기준, 목적지 식당 `:2355`)·점심 후 복귀(출발 기준, 출발지 식당 `:2360`). 체류(회사)의 추정 = (출근, 복귀), 점심시간(식당)의 추정 = (점심 이동, 점심 후 복귀). 겹치는 주장 없음 → 후보 1개.
- 사례 ② 점심 장소 없음/해석 실패: 점심 구간이 생기지 않고 점심시간 장소 = 회사(`:2371`). 두 활동 모두 (출근, 복귀)를 주장 → 동률 규칙: 출근 도착 09:00 = 체류 시작, 복귀 출발 18:00 = 체류 끝 → 체류. AF-018-20 기대 일치.
- 사례 ③ 경고 블록 오는 편: 반복 뒤 회차 실패 모양은 `departureDate == nil`일 수 있다(`Models.swift:205-206` 주석, `:212`). 동률 비교 "leg departure equals activity end"가 nil에서 거짓이 되어 사례 ②와 겹치면 소유 없음으로 떨어진다(N-5).
- `packingGroups`: 같은 구간을 두 활동이 추정하면 뒤 활동이 덮어쓴다(`Store.swift:447-448`). 활동 배열은 시작순이라 사례 ②에서 화면 묶음은 점심시간, 드래그 소유는 체류가 된다. 끄는 동안 체류와 출근은 맞닿을 뿐 겹치지 않으므로(도착 = 시작) 반폭 분할 규칙(`Models.swift:388-395`)이 발동하지 않는다 — 범위 밖 처리(spec.md:168)와 잔여 위험 기록(plan.md:183)으로 충분하다고 판단한다.

### B-2 유효 Δ 손 계산

| 단언 | 계산 | SPEC 기대 | 판정 |
|---|---|---|---|
| AF-018-06 | L 60, m 20 → Δ ≥ min(0, 20−60) = −40 | −40, 끝 = 시작+20 | 일치 |
| AF-018-07 | L 10 → 가는 편 Δ ≤ max(0, 10−20) = 0 → +5는 0; −15는 늘림이라 무제한 → 25분 | 같음 | 일치 |
| AF-018-08 | 출발 23:00·도착 23:20(`afInjectedLeg` 이동 1200초, 여유 0 — `GuardDriver.swift:3809`·`:3812`). 도착 + Δ < 24:00 → Δ < 40 → 5의 배수 최대 35 → 도착 23:55 | +35, 23:55 | 일치 |
| AF-018-09 | 출발 00:20 → 출발 + Δ ≥ 00:00 → Δ ≥ −20 | −20, 출발 00:00 | 일치 |
| AF-018-10 ① | 출발 23:50·도착 00:10(+1일), +15 → 도착 00:25 < 이틀 뒤 0시, 출발 하한 무관 → 적용 | 적용 | 일치(단, N-1) |
| AF-018-10 ② | 활동 22:00–06:00, 가는 편 출발 21:40 −30 → 21:10 ≥ 당일 0시 → 적용 | 적용 | 일치 |
| AF-018-16 | 60·60·25분, −15 → −15·−15·min(0, 20−25) = −5 | 같음 | 일치 |
| AF-018-22 | 명시 연결, 틈 30, +15 → 끝·출발 함께 +15 | 같음 | 일치 |
| 초 섞인 시각 | 0 쪽 버림은 길이·자정 여유를 모두 줄이는 방향이라 두 한계에서 보수적이다(예: 출발 00:20:30 → −20 → 00:00:30 ≥ 0시) | plan.md:64 | 타당 |
| DST | 한국 표준시 없음. 다만 AC-005가 본보기로 인용한 `GuardDriver.swift:4274`는 `startOfDay + 60 * 86400`이다 | acceptance.md:103 | N-7 |

### B-3 반복 일괄 경로

- `rescheduleNearestNotifications`는 호출 시점에 `var updated = events`를 뜬다(`Store.swift:1523`). 루프의 `shiftEvent`가 이미 `events[idx]`를 제자리 수정한 뒤(`:1442-1446`) 부르므로 낡은 사본이 아니다. `events = updated`(`:1541`) 뒤 `save()`(`:1542`)로 이벤트가 저장된다.
- `cancelAll`은 `removeAllPendingNotificationRequests`(`Shared/NotificationManager.swift:55-57`)다. 앱의 알림 예약 경로는 `scheduleDepartureNotification` 하나(`Store.swift:1337-1347`, `notifications.schedule` 호출은 `:1343`뿐 — `grep` 실측)라 다른 종류의 알림을 지우지 않는다. 같은 모양이 이미 `addRecurringEvents` 끝(`:989`)과 포그라운드 진입(`App.swift:104`)에 있다.
- 따라서 "`shiftEvent` 루프 → `saveActivities()` 한 번 → `rescheduleNearestNotifications()` 한 번, 별도 `save()` 없음"(plan.md:84)은 안전하다. 잔여: `center.add`(비동기 완료)와 `removeAllPending` 사이의 순서는 문서화된 보증이 아니다 — 기존 선례와 같은 위험이다.
- REQ-003의 "shall not change … any other event"는 이 경로가 모든 이벤트의 `notificationId`를 새로 매기는 것(`:1534`·`:1538`)과 글자 그대로 충돌한다(N-4).

### B-4 미리보기

- 지금 `span(for event:on:)`은 출발·도착이 그리는 날이 아니면 각각 0·1440으로 자른다(`Shared/ContentView.swift:576-578`), 그 결과 `natural`이 16분 이상이면 그대로 돌려준다(`:579-580`). 하루 목록은 저장된 날짜로 고른다(`:87-89`, `Models.swift:229-235`).
- REQ-009는 옮긴 시각을 **자르기 전에** 만들라 하고(spec.md:125), REQ-007은 "이미 닿은 날 안"이면 그리는 날을 완전히 벗어나는 이동도 허용한다(spec.md:117). AF-018-10 ①(출발 23:50 D → 00:10 D+1, +15)을 D 화면에서 끌면 옮긴 출발 00:05 D+1·도착 00:25 D+1 → D 화면에서 (0, 1440) — 하루 전체 높이의 이동 블록이 그려진다. 놓으면 그 구간은 D 목록에서 사라진다. 반대로 D+1 화면에서 −Δ도 같다(N-1).
- 소유 조회 비용: REQ-004 (b)는 "그 반복의 활동" 전부의 `linkedLegs`를 부르고, 각 호출은 `explicitLegs`(전 이벤트 필터 `Store.swift:401`)와 `estimatedLegs`(같은 반복 이벤트마다 `isDate` `:1430`)를 돈다 — 반복 활동 수 × 이벤트 수. 26주 평일·점심 포함 반복이면 활동 260 × 반복 이벤트 520 규모다. REQ-008은 제스처 `onChange`마다 Store 한계 함수를 부르게 하고(spec.md:119), REQ-009는 렌더·배치·높이마다 도우미를 읽게 한다. 한 번만 구하라는 지시가 없다 — research.md:48과 plan.md:69는 "드래그 시작 때 한 번 구해 두어도 된다, `ui-design` 몫"으로 열어 두었다(N-2). 프레임 지연 수치는 실측하지 않은 추정이다.
- 본문 안 상태 변경: 도우미와 Store 조회가 읽기 전용이면 문제없다. `activeDrag`는 `@State`(`ContentView.swift:26`)라 읽기만 한다. 한계 함수가 비변경(non-mutating)이어야 한다는 문장은 없지만 REQ-008의 서술상 순수 함수로 읽힌다 — 결함으로 올리지 않는다.
- `dragOffsetMinutes(forEvent:)` 0(plan.md:71)과 `offsetY` 불변(acceptance.md:133)은 서로 맞다 — `offsetY`가 그 함수를 부른다(`ContentView.swift:518`). 히트 테스트는 `onBegin`·탭에서만 쓰여(`:459`·`:473`) 끄는 동안 영향이 없다. 소유 없는 구간의 평행이동 미리보기는 그대로다.

### B-5 대화상자 키

- 반복 활동에 명시 연결된 구간: `recurrenceId == nil` → 대화상자 없음 → "이 일정만"(`ContentView.swift:778`·`:783`). REQ-011과 일치.
- 추정 구간: `recurrenceId` 있음 → 대화상자 → "전체"는 REQ-010.
- 소유 없는 반복 구간(`return_time` 없는 반복은 활동이 없다 `AIAssistant.swift:2331`): 대화상자 → "전체"는 지금의 역할 필터(`Store.swift:1392-1395`) → REQ-005. 일치.

## C. 검증 가능성

- `afInjectedLeg`는 `main()` 안 8칸 들여쓰기의 지역 함수(`GuardDriver.swift:3806-3817`)이고 AF-018 머리(`:3637`)와 같은 범위다. 아무 지역 변수도 붙잡지 않는다. `swiftc -parse-as-library -emit-sil`로 "앞에서 호출 → 뒤에서 선언, 붙잡는 값 없음"은 통과, "뒤에서 선언된 값을 붙잡는 지역 함수의 앞선 호출"은 `closure captures 'y' before it is declared`로 실패함을 확인했다. 따라서 AF-018-04~22는 정의를 옮기지 않고 `afInjectedLeg`를 부를 수 있다 — plan.md:120의 〔가설〕은 닫아도 된다. 단, 새 픽스처가 같은 `main()` 안에서 뒤에 선언된 변수(예: `afCal` `:3823`, `afDay` `:3824`)를 쓰려면 앞으로 끌어와야 한다(일반 변수는 앞선 참조 불가).
- `afInjectedLeg`는 `bufferMinutes: 0`·`notifyLeadMinutes: 0`을 박아 둔다(`:3809`). AF-018-11의 "여유 20→5"(acceptance.md:59)는 주입 뒤 여유·출발을 고쳐야만 도달한다. AF-018-13·21의 "여유 흡수"를 +15로 재면 `clampBuffer(0−15) = 0`이라 흡수와 무동작이 구별되지 않는다(N-6).
- 결정성: 새 단언은 네트워크·추정을 부르지 않게 정의됐다(plan.md:120, acceptance.md:186). 알림은 `notifyEnabled = false`(`:3813`)라 `wantsNotification`이 거짓 → 예약 없음. 날짜는 `Date()`의 날만 쓴다. 공유 `store`에 남는 픽스처가 뒤 절을 흔드는지 살폈다: AF-015는 자기 반복 id로만 대조하고(`:4297`·`:4317`), 이후의 개수 단언은 전후 차이(Δ)로 잰다(`:4095`·`:4160`·`:4191`) — 간섭 위험 낮음.
- 기준 트리 실패 가능성: 02·03·04·05·06~10·14·16·18·19·20·22는 활동이 바뀌어야 참이라 기준에서 ✗가 맞다(지금 `adjustTravelLeg`는 활동을 건드리지 않는다 `Store.swift:1400-1408`). 11·12·13·15·17·21은 회귀 핀·특성화로 명시돼 있다(acceptance.md:59~62·:149, plan.md:136~146).
- T = B + 19: 추가 번호 04~22가 19개이고 번호마다 한 호출이라는 규칙(plan.md:122)이 기존 꼴과 같다. 요약 줄은 `drvPass/drvPass+drvFail`(`GuardDriver.swift:5360`), 단언 함수는 호출마다 1을 더한다(`:34-36`). 종료 코드는 `:303-306`. 산술 성립.

## D. 계약·범위

- 출발 산식 새 복제 없음(`shiftEvent` 재사용, plan.md:85), 최소 길이 상수 단일 정의(spec.md:115, AC-004 G), 소스 3파일·새 파일 없음·`xcodegen` 불필요·맥 빌드 없음(spec.md:143, acceptance.md:187~188), `Task` 금지(spec.md:137). 시간 추정 없음(plan.md:22). `spec.md`·`acceptance.md`에 표식 0건.
- 번역투: `grep -c '축\|기둥'` → spec·plan·acceptance·research 0(progress.md의 2건은 그 명령 문자열 자체).
- sync 수리 목록 대조(`rg --hidden` 실측): 목록에 없는 옛 의미 서술이 남아 있다 — `Shared/Store.swift:520` 주석 "오는 편을 끌어 벌어진 틈은 이 저장으로 닫힌다", SPEC-UIKIT-009 `plan.md:110`("틈이 필요하면 드래그로 만든다")·`:151-152`, `design.md:176`·`:237`, `research.md:87`(N-11). `STATUS.md`에는 해당 서술 없음. `AIAssistant.swift:2583-2584`·`GuardDriver.swift:614`는 소유 없는 반복 구간이 여전히 `adjustBuffer`를 타므로(`Store.swift:1406` 유지) 참으로 남는다는 SPEC 판단(spec.md:82)에 동의한다.

## E. 시뮬레이터 스크립트

- 사람만 볼 수 있는 것: 끄는 느낌·실시간 배치(S-1·S-3·S-5·S-8), 놓을 때 튐(S-1·S-5·S-6), 반복 대화상자(S-7·S-8), 한계(S-5·S-6), 가는 편·오는 편 알림 시각(S-11)이 들어 있다.
- 빠진 것: 캘린더 앱(구글) 화면 — D-6 권장안이면 "구글에는 옛 시각 그대로"를 운영자가 눈으로 확인하는 항목이 없다. 자정 걸친 구간을 끄는 항목이 없어 N-1이 사람 확인에도 걸리지 않는다(N-12).
- 기계로 잴 수 있는 것을 S에 둔 정도: S-2·S-4의 최종 시각은 드라이버가 재지만 다음 단계의 출발점이라 남겨 둘 만하다.
- 기대값 오류: S-6(N-3).

## Defects Found

N-1. CROSS-DAY-PREVIEW — spec.md:117(REQ-007)·:125(REQ-009), plan.md:64·:70, acceptance.md:101(AF-018-10 ①) / `Shared/ContentView.swift:576-580`·`:87-89` — 자정을 걸친 구간을 그리는 날 밖으로 완전히 옮기는 끌기가 REQ-007로 허용되고, REQ-009대로 옮긴 시각을 자르기 전에 넣으면 그 날 화면에서 (0, 1440) 하루 전체 높이 블록이 그려진다. 놓으면 블록이 끌던 화면에서 사라진다 — D-4가 한계를 두는 이유로 든 "자동 스크롤 없음"(plan.md:64)과도 어긋난다. — Severity: major — Class: blocking — Required fix: 〔제안〕 REQ-007에 "끌린 구간은 지금 나열된 모든 날과 계속 겹친다"를 더한다(자정을 걸친 구간은 출발 < 도착 날 0시 < 도착을 유지). AF-018-10 ①의 기대를 다시 계산해 적고(+15 요청 → 출발 23:55 미만이어야 하므로 유효 +5), D+1 화면의 −Δ 대칭 단언을 하나 더하거나 같은 번호에 `&&`로 묶는다. 다른 안(그리는 날과 겹치지 않으면 `span`이 빈 범위를 돌려준다)을 택하면 그 동작을 REQ-009에 적는다.

N-2. OWNER-LOOKUP-PER-FRAME — spec.md:107(REQ-004 (b))·:119(REQ-008)·:125(REQ-009), plan.md:69, research.md:48 / `Shared/Store.swift:401`·`:1416-1432`, `Shared/ContentView.swift:463-466`·`:717`·`:722` — 소유 조회는 반복의 활동 전부 × 이벤트 전부를 훑는데, SPEC은 그것을 제스처 변화마다(한계 함수) 그리고 블록 범위 계산마다(도우미) 읽게 하면서 "한 번만 구한다"를 선택 사항으로 남겼다. 26주 반복에서 끄는 동안 프레임마다 수십만 번의 날짜 비교가 될 수 있다(규모는 코드 구조에서 유도, 시간은 미실측). — Severity: major — Class: blocking — Required fix: plan D-5에 "소유 활동은 `onBegin`에서 한 번 구해 `ActiveDrag`에 담고, 한계 함수와 도우미는 그 값을 받는다"를 결정으로 적는다. REQ-004 (b)의 후보 집합을 "구간 도착과 같은 날 시작하는 그 반복의 활동"으로 먼저 좁힌다고 적는다(추정 대조가 같은 날만 보므로 결과는 같다). 드롭 시 재적용(REQ-008)은 같은 함수를 한 번 더 부르는 것으로 충분하다.

N-3. SIM-S6-EXPECT — acceptance.md:206(S-6)·:223 — 실제 이동시간은 5분 단위가 아니므로 도착 A가 22:52이면 유효 Δ 65 → 도착 23:57이 된다. "23:55 이하에서 멈춘다"는 A가 5분 정렬일 때만 참이라 운영자가 정상 동작을 "다름"으로 적게 된다. — Severity: major — Class: blocking — Required fix: 기대를 "도착이 내일 24:00 전(23:55 이상 24:00 미만 구간 안)에서 멈추고, 도착 − A가 5분의 배수"로 바꾼다. 경계 상황표(:223)의 "23:55에서 멈춤"도 드라이버 픽스처 한정으로 고친다.

N-4. REQ003-VS-REQ010 — spec.md:105·:131 / `Shared/Store.swift:1534`·`:1538` — REQ-003은 드롭이 "any other activity or event"를 바꾸지 않는다고 하는데, REQ-010의 "전체"는 다른 회차 활동을 바꾸고 `rescheduleNearestNotifications`가 모든 이벤트의 `notificationId`를 새로 매긴다. — Severity: minor — Class: blocking — Required fix: REQ-003을 "outside the targets of REQ-010, and apart from notification identifiers re-assigned by the notification refresh"처럼 범위를 한정한다.

N-5. TIEBREAK-NIL-DEPARTURE — spec.md:107, plan.md:47 / `Shared/Models.swift:205-206`·`:212` — 반복 뒤 회차의 경고 블록 오는 편은 `departureDate`가 nil일 수 있는데 동률 규칙은 "구간 출발 == 활동 끝"으로만 적혀 있어 점심 장소 없는 반복에서 소유 없음으로 떨어진다. — Severity: minor — Class: blocking — Required fix: 동률 비교의 구간 쪽 값을 "앵커 시각(출발이 없으면 `failedBlockAnchor`)"으로 적는다. 드라이버 단언은 선택.

N-6. INJECTED-BUFFER-ZERO — plan.md:120, acceptance.md:59·:61·:62 / `Tools/GuardDriver.swift:3809` — `afInjectedLeg`는 여유 0으로 만든다. AF-018-11의 "20→5"는 주입 뒤 `bufferMinutes = 20`과 출발 재설정 없이는 나올 수 없고, AF-018-13·21의 "여유 흡수"를 +15로 재면 무동작과 구별되지 않는다. — Severity: minor — Class: blocking — Required fix: plan §5에 "도착 기준 주입 구간은 여유 20, 출발 = 도착 − 1200초 − 20분으로 고친 뒤 붙인다"를 적고 13·21의 기대를 수치(여유 20→5, 도착 고정)로 적는다.

N-7. FIXTURE-86400 — acceptance.md:103 / `Tools/GuardDriver.swift:4274` — "86,400초 덧셈 금지"라 하면서 본보기로 `startOfDay(for: Date()) + 60 * 86400`을 인용한다. — Severity: minor — Class: optional — Required fix: 픽스처 기준일을 `Calendar.date(byAdding: .day, value: 60, to:)` 뒤 `startOfDay`로 잡는다고 적는다.

N-8. GOOGLE-NO-CHECK — spec.md:137(REQ-012), acceptance.md:24·:165~180 — "구글에 올리지 않는다"를 실패시킬 수 있는 대조가 없다(AC-010은 `Task`·`await`·`try?`만 센다). — Severity: minor — Class: optional — Required fix: 새 함수 본문에서 `grep -c 'enqueueCalendarUpload\|removeFromCalendar'` = 0을 AC-010에 더한다.

N-9. AC010-SLICE — acceptance.md:168~178 — `awk`가 `adjustTravelLeg` 본문만 자르므로 소유 갈래를 별도 Store 함수로 빼면 저장 위치 대조가 그 함수를 보지 못한다. "전체 `save()` 0 · 이 일정만 `save()` 1"은 `grep`으로 갈래를 나눌 수 없어 읽기 판정이다. — Severity: minor — Class: optional — Required fix: run이 §E.2에 적은 새 함수 이름으로 같은 `awk`를 돌리라고 명령에 적고, 갈래별 판정은 읽기 판정임을 표에 적는다.

N-10. SERIES-NO-LEG — spec.md:131 vs plan.md:83 — 같은 역할 구간이 없는 회차를 건너뛴다는 규칙이 plan에만 있다. — Severity: minor — Class: optional — Required fix: REQ-010에 한 구절 더한다.

N-11. DOC-REPAIR-GAPS — plan.md:155~167·:93 — 남은 옛 의미 서술: `Shared/Store.swift:520` 주석, SPEC-UIKIT-009 `plan.md:110`·`:151-152`, `design.md:176`·`:237`, `research.md:87`. — Severity: minor — Class: optional — Required fix: `Store.swift:520`은 이 카드가 고치는 파일이므로 run이 "옛 데이터·연결 없는 구간에서"로 좁혀 고친다고 plan §6에 넣고, 나머지는 D-8 대체 자리 목록에 더한다.

N-12. SIM-GAPS-2 — acceptance.md:199~215 — 구글 캘린더 앱 확인 항목이 없고, 자정 걸친 구간 끌기 항목이 없다. S-9는 S-7 반복이 남은 같은 요일·같은 장소 위에서 진행되어 블록 식별이 헷갈릴 수 있다. — Severity: minor — Class: optional — Required fix: S-12 "구글 캘린더 앱에서 회의 시각이 옛 값 그대로(D-6 권장안 확정 시)"와 N-1 수정 뒤의 자정 끌기 항목을 더하고, S-9 앞에 S-7 반복 삭제를 넣거나 제목으로 고르라고 적는다.

N-13. AF017-TAUTOLOGY — acceptance.md:149, plan.md:142 — 픽스처가 `recurrence: nil`로 만든 값을 되읽는다. 코드 성질을 재지 못한다. 회귀 핀이라고 밝혔으므로 정직하지만 번호 하나가 판별력이 없다. — Severity: minor — Class: optional — Required fix: 유지하려면 "드롭 뒤 두 구간의 `recurrenceId`·`linkedActivityId`가 바뀌지 않는다"만 남기고 대화상자 키 근거는 G 대조로 둔다고 적는다.

N-14. HOISTING-HYPOTHESIS — plan.md:120, progress.md:86 — 〔가설〕로 넘긴 지역 함수 앞선 참조는 이번 감사가 컴파일러로 확인했다(C절). — Severity: minor — Class: optional — Required fix: 확인 결과와 "뒤에 선언된 일반 변수는 앞으로 끌어온다"를 plan §5에 적는다.

N-15. GATE-D3-ALT — plan.md:54~56, spec.md:115 — 대안 5분을 고르면 "화면 최소 높이가 Store 정의를 읽는다"가 그리기 높이를 5분으로 줄이게 된다. 대안 선택 시 상수를 둘로 나눌지가 적혀 있지 않다. — Severity: minor — Class: optional — Required fix: D-3에 "5분을 고르면 드래그 최소 길이 상수와 그리기 최소 높이를 분리한다"를 한 줄 적는다.

## Regression Check

1회차 결함 22건의 처리는 A절 표에 있다. 미해소는 D-1(의도된 게이트) 하나, 대체 처리 수용은 D-15, 부분 해소는 D-21이다. 해소됐지만 새 문제를 낳은 것은 D-3(→N-2·N-5), D-5·D-10(→N-3), D-6·D-7(→N-1)이다. 같은 결함이 그대로 반복된 정체(stagnation)는 없다. 점수는 0.60 → 0.80으로 올랐다(회귀 아님, STOP 신호 없음).

## Recommendation

manager-spec이 고칠 순서:

1. N-1: REQ-007 한계를 "지금 나열된 날과 계속 겹친다"로 좁히거나 `span`의 비겹침 처리를 정하고, AF-018-10 기대를 다시 계산한다.
2. N-2: 소유 조회를 드래그 시작 때 한 번 구하는 것을 결정으로 적고, REQ-004 후보를 같은 날 활동으로 먼저 좁힌다.
3. N-3: S-6 기대를 5분 비정렬 도착에 맞게 고친다.
4. N-4·N-5·N-6: REQ-003 범위 한정, 동률의 앵커 시각, 주입 픽스처 여유값을 적는다.
5. 선택: N-7~N-15.
6. 착수 승인 라운드에서 plan.md §2의 게이트 4주제를 AskUserQuestion으로 닫는다(MP-7).

## 감사가 관측하지 못한 것

드라이버·iOS 빌드·시뮬레이터를 돌리지 않아 기준 트리의 `498/498`과 AF-018 ✓/✗ 열은 코드 읽기 예상으로만 대조했다. N-1의 전체 높이 블록과 N-2의 프레임 지연은 코드 구조에서 유도한 것이고 화면·계측으로 보지 않았다. 공유 상수의 격리 경고(D-16)는 빌드 확인 전 가설이다. `UNUserNotificationCenter`의 `add`와 `removeAllPending` 사이 처리 순서는 문서 보증을 찾지 못했다. 시뮬레이터 S-11의 "상세 화면에 알림 시각이 보이는가"는 상세 뷰를 열람하지 않아 확인하지 못했다. 이 워크트리에 `.claude/rules/moai/workflow/spec-workflow.md`가 없어 Tier M 통과 기준값을 읽지 못했고, 프로젝트 설정에 `audit_model`이 없어 교차 모델 감사(codex·GLM)는 돌리지 않았다(Claude 단독).

🗿 MoAI
