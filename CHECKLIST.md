# besir 사용자 요구사항 체크리스트

사용자가 besir의 **전체 기능**을 써보면서 마주칠 수 있는 상황을 모아, **현재 코드가 실제로
처리 가능한지** 검증한 표.

**2026-10-06 UI통일 Day 닫기 판 (ux-check 재생성).** 트리 `master @ 4987e2d`(t42 병합 포함).
이 판은 표를 처음부터 다시 만들었다. 바꾼 원칙은 둘이다.

1. **모든 인용에 파일 이름을 붙였다.** 옛 판은 `:123` 같은 맨몸 인용이 앞에 나온 파일을 잇는
   규칙이었고, 그 규칙이 카드마다 인용을 엉뚱한 파일로 귀속시켰다(t5·t6·t15·t16·t17 sync가 모두
   같은 부류를 고쳤다). 이번 판의 인용은 전부 `파일.swift:줄` 꼴이라 줄 하나하나가 기계로 대조된다.
   좌표는 옛 판에서 옮겨 적지 않고 HEAD에서 심볼을 grep으로 다시 찾아 적었다. 세는 명령과 대조
   결과는 `.moai/reports/day-close-2026-10-06/ux-check.md`에 있다.
2. **옛 판의 카드별 기준선 문단(t1~t17)과 2026-09-16·09-24 요약·확인 목록은 옮기지 않았다.**
   그 문단들은 그날 좌표의 기록이라 현재 줄과 대조하면 전부 어긋난 인용으로 잡힌다. 원문은
   `git show 4987e2d:CHECKLIST.md`로 그대로 볼 수 있다. 행은 하나도 빼지 않았다 — 옛 판의 모든 행
   번호가 이 판에 있고, 이전 회차의 ⚠️·❌·— 전부의 재판정은 ux-check.md의 "이전 회차 대비" 표에 있다.

## 근거 등급

- 「드:X절」 — 가드 드라이버 X절이 모델 없이 실제 실행 경로를 돌려 단언. 이 판의 기준선은 이 회차
  재실행 **492/492, exit 0**(실제 지원 디렉터리 대조 통과)이다.
- 「빌드」 — iOS 빌드 초록(새 DerivedData, 소스 경고 0). **컴파일만 증명한다.**
- 「시뮬(2026-10-05) n번」 — 운영자가 iPhone 17 Pro 시뮬레이터에서 4묶음 런북 n번을 실행하고 "같음"으로
  기록한 것(`.moai/reports/2026-10-05-sim-4bundle-result.md`, 빌드 `cc3d921`). 전사가 붙은 단계는
  도구 호출 인자까지 남아 있다.
- 「리드 전달(2026-10-06)」 — AC-014 6번을 t42 빌드에서 운영자가 다시 실행해 통과했다는 사실을 리드가
  이 검사에 전달했다. **저장소에 그 재실행의 원문 기록은 없다**(ux-check.md 4절).
- 「리드 기록(2026-09-24)」 — 2026-09-24 저녁 시뮬레이터 14항목 세션 결과를 리드가 운영 메모에 남긴
  것. 저장소 원문은 없다.
- 「관찰(날짜)」 — 실기기·시뮬레이터에서 이름 붙은 증거(토큰·인용 문구·특정 장소)와 함께 확인됨.
- 「사용자 보고」 — 통과라는 답만 있고 개별 증거가 없다. 관찰보다 약하다.
- 「문자열」 — 프롬프트 문구의 **존재** 확인. 행동 검증이 아니다.
- 「코드 읽기」 — 읽어서 세운 판단. 실행으로 재현하지 않았다.

범례: ✅ 됨 · ⚠️ 부분적/우회 필요/앱이 강제 못 함/검증 수단 부족 · ❌ 안 됨 · — 일부러 넣지 않음.
✅라도 기기 미관찰이면 근거에 그대로 적는다 — "드라이버가 증명"과 "기기에서 봤다"는 다른 말이다.

현재 AI 도구 9개: `create_schedule`, `create_activity`, `create_recurring_schedule`,
`update_recurring_schedule`, `update_schedule`, `list_schedules`, `recommend_meal`,
`check_travel_time`, `delete_schedule`(분기 `AIAssistant.swift:1705-1716`).

---

## A. 단발성 일정 만들기

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| A1 | "내일 3시까지 강남역 가야 해" | ✅ | `create_schedule(arrival_iso)` — 기준 결정 `AIAssistant.swift:1729-1737`, 출발 역산은 `Store.swift:1308` 한 곳. 출발지와 목적지가 50 m 안이면 등록 거부(`isSamePlace` 가드 `AIAssistant.swift:1782-1784`, 판정 `AIAssistant.swift:2920-2924`). 〔빌드·코드〕 |
| A2 | "6시에 집에서 바로 출발할래" | ✅ | `departure_iso` 갈래 `AIAssistant.swift:1733-1734`, 출발 기준이면 여유 0 강제(`AIAssistant.swift:1742`·`Store.swift:885`). 〔드:V절 ①-3〕 |
| A3 | "8시부터 10시까지 강남에서 친구 만나" (머무는 활동만) | ✅ | 머무는 한 번짜리는 끝 시각을 카드보다 먼저 받고(`AIAssistant.swift:563`) 출발지 줄 하나만 띄운다('이동 없음' 칩 — `AIAssistant.swift:590-601`). 다른 출발지를 고르면 두 번째 카드가 수단·여유·알림을 묻는다. 이동이 없으면 수단 줄이 안 생긴다(`AIAssistant.swift:602-603`). 〔드:T절 D2 + 시뮬(2026-10-05) 3번·16번 — 16번 전사: `travel_from_query=회사` → 활동 1건 + 가는 이동 1건, 오는 이동 없음〕 |
| A4 | "가서 놀고 집까지 오는 것도 잡아줘" | ✅ | `create_activity(travel_from_query, return_to_query)` — 선언 `AIAssistant.swift:1545-1546`. 왕복이면 채워 온 출발지도 다시 묻고 캡션을 단다(`AIAssistant.swift:611-621`, 문구 `AIAssistant.swift:840-842`). '가는 편 없음' 토큰은 실행부가 구간을 만들지 않는 값으로 읽는다(`AIAssistant.swift:1940`). 〔드:R절 + 관찰(2026-09-16) car/transit 한 호출 + 시뮬(2026-10-05) 11번 — 전사: `travel_from_query=__no_outbound_leg__` → 오는 이동 1건만〕 |
| A5 | "다음 주 화요일 오후 2시 병원" | ✅ | 시스템 프롬프트에 현재 시각 주입(`AIAssistant.swift:1442`·`AIAssistant.swift:1457`) + 상대 표현 규칙 4(`AIAssistant.swift:1465`) + `parseDate`(`AIAssistant.swift:3245-3257`). 〔빌드·코드〕 |
| A6 | 카톡 일정표 스크린샷 공유 | ✅ | 공유 확장이 앱 그룹 큐에 넣고(`ShareViewController.swift:34-52`, `SharedInbox.swift:20-25`) 앱이 활성화될 때 꺼내 `handleShared`로 넘긴다(`App.swift:96-99`·`App.swift:124-131`, `AIAssistant.swift:284-292`). 여러 건이어도 카드는 한 장(`pendingAsk` `AIAssistant.swift:859-880`). 〔관찰(2026-09-10)〕 — 응답 중 도착 시의 유실 가설은 S8 |
| A7 | 한 번에 여러 일정 등록 | ✅ | `runLoop`이 한 턴에 여러 도구 호출을 처리(5회 상한 `AIAssistant.swift:391`). 〔빌드·코드〕 |
| A8 | "지금 출발하면 몇 시에 도착해?" (등록 없이 조회만) | ✅ | `check_travel_time`(`AIAssistant.swift:2759-2781`) — 세 수단을 한 번에. 출발지 폴백(즐겨찾기 '집' → 현재 위치)이 살아 있는 유일한 곳(`orDefault: true` 호출 `AIAssistant.swift:2762`, 폴백 `AIAssistant.swift:2974-2978`). 〔빌드·코드〕 |
| A9 | 등록 결과에 적용된 여유·알림이 바로 보임 | ✅ | 요약이 출발지·수단·여유·알림을 적는다(`AIAssistant.swift:1847-1853`). 요약은 `addEvent`가 돌려준 방금 만든 일정을 읽는다(`AIAssistant.swift:1828`, 반환 `Store.swift:905`) — 결함 J(같은 이름 늦은 회차 시각을 말함) 수리. 〔드:J절 + 사용자 보고(2026-09-16)〕 |

## B. 반복 일정

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| B1 | "매주 평일 9시~6시 회사" | ✅ | `executeCreateRecurringSchedule`(`AIAssistant.swift:2115`) — 출근·복귀·활동 블록. 요일 3개 이상 + 주기 인자면 되묻기(`recurringArgumentIssue` `AIAssistant.swift:2354`). 〔드:T절 D1 + 관찰(2026-09-16) `origin_query=__current_location__` + 시뮬(2026-10-05) 4번·14번 — 14번 전사: 총 33건(등원 11·복귀 11·블록 11)〕 |
| B2 | "월수금만" | ✅ | `weekdays` 읽기 `AIAssistant.swift:2118`. 〔빌드·코드〕 |
| B3 | "점심에 밖에서 먹어" | ✅ | `lunch_place_query`(`AIAssistant.swift:2244-2250`) — 비워 두면 이동 생략. 점심 장소는 되묻기 카드를 열지 않고 모호해도 첫 후보를 쓴다(Q7과 같은 평탄화, 결과 문구에 이름이 드러난다). 〔빌드·코드〕 |
| B4 | "6개월간 계속" | ✅ | 최대 26주(`Store.swift:47`). 기간은 카드의 반복 기간 줄(`weeksField` `AIAssistant.swift:735`). 생성부 이중 상한(`Store.swift:250`·`Store.swift:936`). 선언 밖 `weeks`는 정화가 버린다(`sanitizeModelArgs` `AIAssistant.swift:975`). 〔드:T절 D1 + 시뮬(2026-10-05) 4번(반복 기간 줄)〕 |
| B5 | "매월 첫째 주 월요일" | ✅ | `nthWeekArgument`(`AIAssistant.swift:2313`)가 유일한 읽기 지점. 0은 "매월 아님". 〔빌드·코드〕 |
| B6 | "격주로" | ✅ | `everyNWeeksArgument`(`AIAssistant.swift:2333`). 〔빌드·코드〕 |
| B7 | "공휴일은 빼고" | ✅ | `skip_holidays`(`AIAssistant.swift:2144`) → `KoreanHolidays`(`Models.swift:510`). 2026·2027 대조는 과거 스크립트. 〔빌드·코드〕 |
| B8 | "매주 월수금 집에서 점심 먹어" — 끝 시각을 말 안 함 | ✅ | 머무는 반복은 끝 시각을 카드보다 먼저 묻는다(`AIAssistant.swift:540`, 안내 `stayingEndAsk` `AIAssistant.swift:2076`). 〔시뮬(2026-10-05) 15번 — 전사: 첫 호출 `return_time` 비어 있음 → 모델이 "몇 시까지" 질문 → `return_time=13:00` 재호출 → 8건〕 |
| B9 | 한 장소에 머무는 반복(이동 없음) | ✅ | 출발지 줄의 '이동 없음' 토큰(`AIAssistant.swift:2990`, 줄 `AIAssistant.swift:544-550`). 정화는 반복 도구의 이 토큰만 목적지로 되돌려 머무는 신호를 살린다(`AIAssistant.swift:987-992`). 〔시뮬(2026-10-05) 12번 — 전사: `origin_query=__no_travel__` → 활동 11건, 이동 구간 0〕 |

## C. 조회

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| C1 | "지금 등록된 일정 뭐 있어?" | ✅ | `executeListSchedules`(`AIAssistant.swift:2560`) — `[반복 n]` 번호(`seriesTag` `AIAssistant.swift:2632-2637`) + 회차 수 + 안내문(`AIAssistant.swift:2683`). 빈 결과엔 전체 건수·가장 가까운 일정(`AIAssistant.swift:2595-2600`). 〔드:T절 D3〕 |
| C2 | "오늘/이번 주 일정만 알려줘" | ✅ | 범위 판정 `AIAssistant.swift:2568-2575`. "이번 주"는 오늘이 들어가는 주(규칙 4, `AIAssistant.swift:1466`). 〔빌드·코드〕 |
| C3 | "내일 몇 시에 나가야 해?" | ✅ | 출력에 출발 시각(`leg()` `AIAssistant.swift:2624-2626`). 계산 실패 회차 표지(`AIAssistant.swift:2647`) — 단 표지 판정이 시간표와 다르다(plan.md 후속 21). 〔빌드·코드〕 |
| C4 | "이번 주에 몇 건 있어?" | ✅ | C2와 동일. 〔빌드·코드〕 |

## D. 수정

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| D1 | "방금 만든 반복 일정 자동차로 바꿔줘" | ✅ | `lastRecurrenceId`를 대화 기록과 함께 저장(`AIAssistant.swift:146-149`). `update_recurring_schedule` → `updateRecurringSeries`(`Store.swift:1024`). 〔빌드·코드 + 시뮬(2026-10-05) 13번 "같은 대화 후속 — 수단 바꾸기"〕 |
| D2 | "저번 주에 만들어둔 반복 일정 자동차로 바꿔줘" (앱 재시작 후) | ⚠️ | 목록 번호 다리 — 번호 배정(`AIAssistant.swift:2632-2637`)·무효 번호 거부(`AIAssistant.swift:2396-2404`)·번호 없으면 이 대화의 그룹(`AIAssistant.swift:2408`). 모델이 [n]을 `series_number`에 넣는 것: **리드 기록(2026-09-24)** — 14항목 세션 1번에서 `series_number=1` 관측(대화 복사). 〔드:T절 D3 + 리드 기록(2026-09-24) — 저장소 원문 없음 → ⚠️로 되돌림(리드, 2026-10-06). 재관측 조건: 반복 일정 수정을 두 대화에 나눠 요청할 때 대화 복사로 series_number 확인〕 |
| D3 | "도착 여유 20분으로 늘려줘" (반복 그룹) | ✅ | 0이 오면 되묻는다(`zeroUpdateIssue` `AIAssistant.swift:2471`), 확인은 앱이 물은 조합의 `confirm_zero`만(`AIAssistant.swift:2477`). 〔드:B·N절〕 |
| D4 | "그 약속 4시로 미뤄줘" | ✅ | `executeUpdateSchedule`(`AIAssistant.swift:2785`) — 여러 건이면 고치지 않고 날짜를 요구(`AIAssistant.swift:2802-2808`, 규칙 `AIAssistant.swift:1489`). 〔빌드·코드〕 |
| D5 | "장소 바꿔줘" / "제목 바꿔줘" | ✅ | `new_place_query`(`AIAssistant.swift:2812-2813`)·활동 갈래(`AIAssistant.swift:2816-2828`) — 활동을 고치면 묶인 구간이 따라온다(`realignLegs` `Store.swift:581`). 〔빌드·코드〕 |
| D6 | 회차마다 여유를 따로 바꾼 시리즈에 "전체 여유 0으로" | ✅ | 0 판정이 시리즈 전체 값을 본다(`AIAssistant.swift:2502-2506`). 〔드:N절〕 |
| D7 | 모델이 말도 안 되는 값을 보내도 (여유 -5분 등) | ✅ | `clampBuffer`·`clampNotifyLead`(`Store.swift:62`·`Store.swift:66`)를 네 경로가 쓴다: 단발 `AIAssistant.swift:1742-1743`·활동 `AIAssistant.swift:2012-2013`·반복 `AIAssistant.swift:2146-2147`·수정 `Store.swift:1041-1042`. 〔드:O절〕 |
| D8 | 화면에서 블록 드래그로 시간 이동 | ✅ | 꾹 눌러 드래그(0.35초, `ContentView.swift:1062-1064`). 반복이면 "전체/이 일정만"(`ContentView.swift:183-188`, 적용 `ContentView.swift:912`·`ContentView.swift:920`). 〔빌드·코드 + 시뮬(2026-10-05) 18번〕 |
| D9 | 화면에서 활동을 고치면(시간·장소·이동 줄) 이동이 활동에서 떨어지지 않는다 | ✅ | 이동 상세의 편집은 연결된 구간이면 활동 편집 카드를 연다(`EventDetailView.swift:94`, 조회 `Store.swift:415`). 활동 카드는 생성 카드와 같은 구간 줄 문법(`LegCardForm.seeded` `EditCard.swift:566`, 줄 키 `EditCard.swift:255`), 시간은 활동에서 유도. 저장 순서: `modifyActivity`(`Store.swift:311`) → 제거 → `realignLegs`(`Store.swift:581`) → `LegSavePlanner`(`EditCard.swift:627`)의 수정·추가(`ActivityDetailView.swift:311`). 오는 이동을 나중에 더하기(`addLeg` `Store.swift:461`). 연결 없는 반복 회차는 구간 줄이 없다(`EditCard.swift:319`). 〔드:AF·AG절 + 시뮬(2026-10-05) AC-023 1~13번 전부 같음〕 |
| D10 | 활동 장소를 '장소 없음'으로 / 종료를 시작 이전으로 저장 | ✅ | `modifyActivity(clearPlace:)`(`Store.swift:311`) — 장소를 지우면 연결 구간도 지운다. 종료 ≤ 시작이면 종료·구간 그대로. 〔드:AF-004〕 |
| D11 | 이동시간을 못 구한 채 저장 | ⚠️ | 안내 '이동시간을 계산하지 못했어요'(`ActivityDetailView.swift:384`), 구간 연산 결과 `LegOutcome`(`Store.swift:366`). **끝점이 그대로인 nil 구간은 다시 저장해도 재추정되지 않는다**(plan.md 후속 30). 화면 문구·시트는 오프라인이 필요해 **실기기 이월**(AC-023 13a·AC-024 20). 〔드:AF-003-06·AF-010·AH-010〕 |

## E. 삭제

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| E1 | "강남 약속 취소해줘" | ✅ | `delete_schedule` — 텍스트로 확인받고 한 번만 호출(규칙 `AIAssistant.swift:1493-1494`). 〔빌드·코드〕 |
| E2 | "반복 일정 전체 삭제" | ✅ | `executeDeleteSchedule`(`AIAssistant.swift:2866`) — 일괄 삭제 `AIAssistant.swift:2911-2912`. 〔빌드·코드〕 |
| E3 | "이번 주 화요일 것만 빼줘" | ✅ | `date` + `whole_series:false` — 날짜 없으면 되묻는다(`AIAssistant.swift:2902-2903`). 〔빌드·코드〕 |
| E4 | "오늘 일정 다 지워줘" | ✅ | 낱개 5건 초과면 `confirm_many` 재확인(`AIAssistant.swift:2898-2899`). 〔빌드·코드〕 |
| E5 | 삭제한 게 동기화로 되살아남 | ✅ | 삭제 묘비 `deleted_gcal_ids.json`(`Store.swift:83`), 묘비를 먼저 쓰는 `removeFromCalendar`(`Store.swift:97`). 〔빌드·코드〕 |
| E6 | 활동을 지우면(낱개·일괄) 딸린 이동도 함께 | ✅ | `deleteActivity`(`Store.swift:677`)·`deleteActivities`(`Store.swift:1607`)가 `deleteActivitiesCore`(`Store.swift:1614`)·`removeExplicitLegs`(`Store.swift:1630`)를 공유. 〔드:AF-012·AF-005〕 |
| E7 | 활동 삭제 확인에 딸린 이동 수가 보인다 | ✅ | '이 활동과 딸린 이동 N건을 삭제할까요?'(`ActivityDetailView.swift:426`, 건수 `Store.swift:422`). 〔드:AF-014 + 시뮬(2026-10-05) AC-023 10·11번〕 |
| E8 | 이동만 지우면 그것만, 같은 제목 일괄 삭제는 연결된 이동을 쓸지 않는다 | ✅ | `Store.sameTitleSweep(for:)`(`Store.swift:428`)가 연결 구간을 모음에서 뺀다(호출 `EventDetailView.swift:340`). 〔드:AF-013 + 시뮬(2026-10-05) AC-023 8·13번〕 |

## F. 충돌·시간 계산

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| F1 | 기존 일정과 겹치면 알려주기 | ✅ | `Store.conflicts`(`Store.swift:810-829`) — 등록 전에 검사. 첫 호출의 `on_conflict`는 앱이 물은 조합일 때만 답으로 친다(`ConflictAsk` `AIAssistant.swift:111-115`, 판정 `AIAssistant.swift:1793-1795`, 소비 `AIAssistant.swift:1841`). 〔드:S절 + 사용자 보고(2026-09-16) + 리드 기록(2026-09-24) 4번〕 |
| F2 | "늦게 도착해도 되니 끝나고 바로 출발" | ✅ | `late_arrival` — 겹침 끝 시각 출발 전환(`AIAssistant.swift:1808-1812`), 늦는 분까지 요약(`AIAssistant.swift:1854-1856`). 〔드:S절 C3〕 |
| F3 | "겹쳐도 그냥 등록해" | ✅ | `ignore` — 물은 뒤에만 통과(`AIAssistant.swift:1801`). 〔드:S절 C2〕 |
| F4 | 실시간 교통상황 반영 | ✅ | `refreshUpcomingEstimates`(`Store.swift:1547-1573`) — 출발 2시간 이내 재계산, 앱 활성화마다(`App.swift:101`). 반복은 첫 회차만 조회 후 복사(`Store.swift:944`). 〔빌드·코드〕 |
| F5 | 수동(+ 메뉴)으로 만들 때도 충돌 경고 | ✅ | `ConflictBanner`(사용 `AddEventView.swift:71-72`, `currentConflicts` `AddEventView.swift:677`, 선언 `AddEventView.swift:750`). 저장은 막지 않는다. 〔빌드·코드〕 |
| F6 | 활동 블록끼리 겹침 경고 | — | 일부러 넣지 않음(2026-09-11 사용자 결정). 활동과 함께 만든 **이동**의 겹침은 문구로 알린다(`AIAssistant.swift:2040-2051`) — 다만 그 구간을 `.suffix(madeLegs)`로 되찾는 방식이라 엉뚱한 구간을 볼 수 있다(plan.md 후속 29). |
| F7 | 저장 버튼을 빠르게 두 번 눌러도 일정이 두 배로 생기지 않음 | ✅ | `AddEventView.swift:138`·`AddActivityView.swift:274`의 `saving` 게이트. 〔빌드·코드 — 이중 탭 화면 실측은 시뮬레이터 목록 (b)〕 |

## G. 요청마다의 값 · 앱 주도 되묻기 카드

되묻는 주체가 모델이 아니라 **앱**이다. 이 모델은 선언된 선택 인자를 비워두지 못하고 전부
채운다. 그래서 이동수단·도착 여유·알림·반복 기간은 툴 선언에 없다(`AIAssistant.swift:1507-1511`).
선언에서 빼도 모델은 보낼 수 있다 — 방어는 `sanitizeModelArgs`(`AIAssistant.swift:975`, 호출
`AIAssistant.swift:434`, 화이트리스트는 선언에서 `AIAssistant.swift:1007-1017`)다.

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| G1 | "자동차로 가자"·"여유 20분"처럼 말한 값 | ✅ | 문장 파서(`statedArguments` `AIAssistant.swift:349-355` → `fillStated` `AIAssistant.swift:1021-1038`). 발화마다 병합(`AIAssistant.swift:302`), 툴 실행 시 소거(`AIAssistant.swift:1704`), 실패 시 유지(`AIAssistant.swift:319-322`), 새 대화 초기화(`AIAssistant.swift:228`). 카드에 "말씀하신 대로"(`EditCardView.swift:50`). 〔드:Q절 + 리드 기록(2026-09-24) 3번〕 |
| G2 | 값을 안 말하면 아무 값이나 넣지 않고 물어봄 | ✅ | 부재는 카드 줄(`askFields` `AIAssistant.swift:485-638`), 부재 판정은 빈 문자열도 비었다로(`filled` `AIAssistant.swift:486-489`). 카드 미통과 호출은 `missingAskedArguments`(`AIAssistant.swift:1688-1695`). 〔드:T절·W1 + 관찰(2026-09-16)〕 |
| G3 | "앞으로 자동차로 해줘" (기억 요청) | ✅ | 기억은 없다 — 규칙 7(`AIAssistant.swift:1471`)이 미래 약속을 금지. 〔드:Q절·U절(문자열) + 관찰(2026-09-16) 모델 응답 인용〕 |
| G4 | 빠진 값이 여러 개면 한 번에 묻기 | ✅ | 카드 한 장(`pendingAsk` `AIAssistant.swift:859-880`). 〔드:P절〕 |
| G5 | 확인 버튼을 누르면 딱 한 번 등록 | ✅ | `confirmAsk`(`AIAssistant.swift:1183`) → `resolvePendingAsk`(`AIAssistant.swift:1207`) → `runToolCalls`(`AIAssistant.swift:463`). 〔드:P절·V절 ①-2〕 |
| G6 | 칩에 없는 값 직접 입력 | ✅ | `submitCustom`(`AIAssistant.swift:1146`) — 빈 값·범위 밖 거부. 장소 줄은 `[장소 검색]`(P1). 이동수단 줄엔 직접입력 없음(`modeField` `AIAssistant.swift:711-715`). 〔드:V절 ①-1〕 |
| G7 | "여유 없이" — 진짜 0분 | ✅ | 여유 줄의 `0분` 칩(`bufferField` `AIAssistant.swift:719-724`), 알림 줄의 0은 출발 시각 알림(`notifyField` `AIAssistant.swift:728-733`). 〔드:P절〕 |
| G8 | 왕복은 가는 편·오는 편을 따로 | ✅ | `가는 편`·`오는 편` 수단 줄(`AIAssistant.swift:624-625`). 〔드:R절 + 관찰(2026-09-16)〕 |
| G9 | 머무는 활동에 교통 질문 안 함 | ✅ | 머무는 한 번짜리는 출발지 줄만(`AIAssistant.swift:590-601`), 교통은 다른 출발지를 고른 뒤 두 번째 카드가. 복귀만 있는 호출도 여유를 미리 묻는다(`AIAssistant.swift:629-633`). 〔드:T절 D2 + 시뮬(2026-10-05) 3번·16번〕 |
| G10 | 출발지를 안 말했을 때 | ⚠️ | **앱이 강제할 수 없다(2026-09-16 사용자 결정 — 프롬프트 전용).** 출발지 줄은 `origin_query`가 비었을 때만 뜨고(`AIAssistant.swift:511-512`), 이 인자는 선언돼 있어(`AIAssistant.swift:1521`) 모델이 지어내 보내면 우회된다. 규칙 3(`AIAssistant.swift:1462-1463`)〔문자열〕. 최소 방어: 채워 온 값의 맥락 줄(`filledValueLabels` `AIAssistant.swift:886-910`), 50 m 가드(`AIAssistant.swift:1782`). **지어낸 출발지가 검색에 성공하면 조용히 등록되는 경로는 열려 있다** — t42 이후엔 그 검색이 모호하면 후보 카드로 멈춘다(Q2). |
| G11 | 반복 일정처럼 줄이 다섯 이상이면 | ✅ | 행을 숨기지 않는다 — 칩 줄바꿈(`ChipFlow` `EditCardView.swift:490-538`), 칩 높이 `@ScaledMetric`(`EditCardView.swift:32`). 〔빌드 + 드:V절·Z절〕 |
| G12 | 카드가 떠 있는데 다른 얘기를 함 | ✅ | 새 발화가 카드를 무효로(`cancelPendingAsk` `AIAssistant.swift:1367`, 호출 `AIAssistant.swift:296`). 〔드:Q절·P절 P-6〕 |
| G13 | 카드를 반쯤 고른 채 앱 종료 | ✅ | 보류 카드는 디스크에 남지 않음(`saveHistory` 필터 `AIAssistant.swift:143-145`). 〔드:Q절〕 |
| G14 | "그거 기억해줘"/"잊어버려" | ✅ | 기억 기능이 없다 — `remember_fact`·`forget_fact` 코드 참조 0건(남은 1건은 주석 `AIAssistant.swift:2461`). 〔드:Q절 + 관찰(2026-09-16)〕 |
| G15 | "일정 생성" 한마디로, 탭만으로 완결 (①) | ⚠️ | 카드가 제목·목적지·시각까지 묻는다(`AIAssistant.swift:505-527`, required 비움 `AIAssistant.swift:1533`). 모델이 툴을 부르게 하는 것은 규칙 8(`AIAssistant.swift:1472`) **프롬프트뿐** — 수용된 갭. 〔문자열 + 리드 기록(2026-09-24) 2번 통과〕 |
| G16 | 시각 줄 — 도착 기준인지 출발 기준인지 내가 정함 | ✅ | 기준 칩 2개 + DatePicker(`EditCardView.swift:190-258`), 기준 없으면 확인 잠김(`EditCardView.swift:235-249`), 재탭 접두 교체(`tapBasis` `EditCardView.swift:179-184` → `rechooseTimeBasis` `AIAssistant.swift:1174`). 출발 기준이면 여유 줄 흐림(`EditCardView.swift:149-156`)·실리지 않음(`AIAssistant.swift:1251-1256`). 〔드:V절 + 사용자 보고〕 |
| G17 | 즐겨찾기에 없는 일반명사로 장소를 말했다 ("회사"·"학교") | ✅ | `genericPlaceWords`(`AIAssistant.swift:3043`) — `placeNotFound`(`AIAssistant.swift:2931-2941`)와 같은 목록. 생성 경로 게이트(`AIAssistant.swift:3092`), 생성 호출점 `AIAssistant.swift:1768`·`AIAssistant.swift:1931`·`AIAssistant.swift:1952`·`AIAssistant.swift:2174`·`AIAssistant.swift:2250` + 출발지 `AIAssistant.swift:2972`. **한계**: 목록은 스냅숏(`AIAssistant.swift:3041-3042`), `update_schedule`의 `new_place_query`(`AIAssistant.swift:2813`)는 같은 노출이 남아 있다. 〔드:Y절·Z절 + 관찰(2026-09-16) '사무실'→'가산3차 SK V1센터'〕 |

## H. 알림

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| H1 | "출발 30분 전에 알려줘" | ✅ | 발화값은 파서(`AIAssistant.swift:352-353`), 안 말했으면 알림 줄(`AIAssistant.swift:728-733`). "알림 필요 없어"면 줄이 안 생김(`AIAssistant.swift:499`). 〔빌드·코드 — 실제 수신은 실기기 목록〕 |
| H2 | "이 일정은 알림 필요 없어" | ✅ | `notify_enabled`(`AIAssistant.swift:1837`) + 토글. 예약은 `scheduleDepartureNotification`(`Store.swift:1337-1347`) 한 곳. 〔빌드·코드〕 |
| H3 | 반복 일정 뒤쪽 회차 알림 누락 (iOS 64건 한도) | ✅ | `rescheduleNearestNotifications(limit: 60)`(`Store.swift:1519-1543`) — 앱 활성화(`App.swift:104`)·백그라운드 작업(`App.swift:26`)에서 다시 채운다. 〔빌드·코드〕 |
| H4 | besir에서만 알림(캘린더 앱 중복 제거) | ✅ | `reminders` 해제 + PATCH(`GoogleCalendarService.swift:78`·`GoogleCalendarService.swift:151-152`·`GoogleCalendarService.swift:198`). 〔빌드·코드 — 캘린더 앱 모습은 실기기 목록〕 |
| H5 | 알림 권한을 거부했을 때 앱이 알려준다 | ⚠️ | 권한 결과는 `NotificationManager.authorized`(`NotificationManager.swift:7`·`NotificationManager.swift:24`)에 기록되지만 **읽는 곳이 0곳**이다(이 회차 grep — 위 두 줄 외 `authorized` 일치는 위치 권한뿐). `schedule`은 `center.add` 실패와 무관하게 id를 돌려준다(`NotificationManager.swift:44-47`). 거부 상태에서도 상세 화면은 "예약됨"을 말할 수 있다. 〔코드 읽기 + grep — t15 sync가 남긴 후속과 같은 사안〕 |
| H6 | 이미 지난 출발 시각이면 알림이 안 걸린다는 걸 화면이 말한다 | ⚠️ | 과거 시각은 예약하지 않고(`NotificationManager.swift:34`), 상세 화면의 `alarmStatus`가 꺼짐·예약됨·과거 거부·64건 창 밖 대기를 갈라 말한다(`EventDetailView.swift:403`, 표시 `EventDetailView.swift:237`). 화면 문구는 **실기기 이월**(AC-024 20a — 알림 예약은 시뮬레이터에서 증명되지 않는다). 〔빌드·코드〕 |

## I. 연동

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| I1 | 구글 캘린더 자동 등록 | ✅ | 업로드는 등록 뒤의 직렬 큐(`enqueueCalendarUpload` `Store.swift:1113-1148`). 상세는 N절. 〔빌드·코드 + 드:N절〕 |
| I2 | "이건 캘린더에 올리지 마" | ✅ | `wantsCalendarSync`(`Models.swift:196`·`Models.swift:706`) + AI `add_to_calendar`(`AIAssistant.swift:1838`·`AIAssistant.swift:2015`). 큐·푸시가 건별 존중(`Store.swift:1121`·`Store.swift:1180`). 〔빌드·코드〕 |
| I3 | 앱 안 켜도 동기화 | ⚠️ | `BGTaskScheduler`(`App.swift:20`·`App.swift:43`) — 실행 시점은 iOS가 정하고 강제 종료 뒤엔 돌지 않는다. 〔빌드·코드〕 |
| I4 | "근처 맛집 추천해줘" | ✅ | `executeRecommendMeal`(`AIAssistant.swift:2693`) — 반경 0이면 1000 m(`AIAssistant.swift:2698`). 〔빌드·코드〕 |

## J. 맛집 추천 (be full sir)

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| J1 | 일정 상세에서 목적지 주변 맛집 보기 | ✅ | 활동 상세 "주변 맛집"(`ActivityDetailView.swift:441`) → `PlaceSearch.nearbyPlaces`(`ActivityDetailView.swift:530`). 〔빌드·코드〕 |
| J2 | 카페도 보기 | ✅ | 음식점(FD6)/카페(CE7) 갈래(`FullSirView.swift:253`). 〔빌드·코드〕 |
| J3 | 업종·거리·주소 확인 | ✅ | 결과 행의 업종·거리·주소. 〔빌드·코드〕 |
| J4 | 카카오맵에서 자세히 보기 | ✅ | 각 행의 링크(`FullSirView.swift:222-223`). 〔빌드·코드〕 |
| J5 | 주변에 결과가 없을 때 | ✅ | "주변 1km 안에서 찾지 못했어요."(`ActivityDetailView.swift:472`). 〔빌드·코드〕 |
| J6 | 추천을 골라 일정으로 등록 | ✅ | "식사 일정으로 추가"(`FullSirView.swift:392`) → `addActivityWithTravel`(`FullSirView.swift:463`) + `MealLog.activityId`(`FullSirView.swift:477-480`). AI는 `log_as_meal`(`AIAssistant.swift:2018-2021`). 〔빌드·코드〕 |
| J7 | 먹은 것 기록 | ✅ | "먹었어요"(`FullSirView.swift:230-233`) + "최근 먹은 것"(`FullSirView.swift:281`). 일정 삭제 시 안 먹은 기록도 제거(`removeUpcomingMeals` `Store.swift:733`). 〔빌드·코드〕 |
| J8 | 예산 기반 추천 | ❌ | be rich sir(Phase 3) 이후. |
| J9 | 배달·요리 카테고리 | ❌ | 열거형만 있고(`Models.swift:604-605`) 만드는 경로가 없다 — Day 8(조사 Day) 결정 대기. |
| J10 | AI에게 메뉴 추천받기 | ✅ | `recommend_meal` — keyword 재검색(`AIAssistant.swift:2694`), 시각만 말하면 그 장소 주변. 〔관찰(2026-09-15)〕 |
| J11 | 홈에서 서비스 선택 | ✅ | `RootView` 서비스 카드(`RootView.swift:103`). 〔빌드·코드〕 |

## K. 화면 조작

| # | 상황 | 상태 | 근거 |
|---|---|---|---|
| K1 | 월간 ⇄ 주간+일간 전환 | ✅ | 헤더 버튼(`ContentView.swift:236-244`), 상태 `isMonthExpanded`(`ContentView.swift:22`), 주간 스트립(`ContentView.swift:329`). 〔빌드·코드〕 |
| K2 | 월간·주간·일간 좌우 스와이프 | ✅ | `SwipePager`(`ContentView.swift:791`). 〔빌드·코드〕 |
| K3 | 스와이프 중 날짜가 잘못 선택됨 | ✅ | 탭 문턱 `@GestureState`(`ContentView.swift:34`). 〔빌드·코드〕 |
| K4 | 블록 위에서 세로 스크롤 | ✅ | UIKit 오버레이가 스크롤 팬과 동시 인식(`ContentView.swift:966-967`). 〔빌드·코드〕 |
| K5 | 블록 탭 → 상세 | ✅ | 렌더와 히트테스트가 `span(for:on:)`(`ContentView.swift:620`·`ContentView.swift:656`)과 칸 함수(`Models.swift:395`·`Models.swift:314`)를 공유 — 렌더 `columnFrame`(`ContentView.swift:878`), 히트 `block(atX:)`(`ContentView.swift:893`). 〔드:AH-016 + 시뮬(2026-10-05) 16번〕 |
| K6 | 겹친 블록 중 짧은 것 선택 | ✅ | 지속시간 최소 우선(`ContentView.swift:756-762`). 〔빌드·코드〕 |
| K7 | 꾹 눌러 드래그로 시간 이동 | ✅ | D8과 같다(`ContentView.swift:912`·`ContentView.swift:920`). 〔빌드·코드〕 |
| K8 | 활동을 옮기면 묶인 이동도 이동 | ✅ | `linkedActivityId`(`Models.swift:191`) + `linkedLegs`(`Store.swift:1414-1434`), 카드 저장은 `realignLegs`(`Store.swift:581`) — 끝점이 그대로면 저장된 이동시간을 쓴다(`legAnchor` `Store.swift:378`, 연산 `Store.swift:461`·`Store.swift:523`·`Store.swift:567`). 〔드:AF절 + 시뮬(2026-10-05) 5·6번(AC-023)〕 |
| K9 | 자정을 넘기는 블록 표시 | ✅ | 나열(`ContentView.swift:94-95` → `isListed` `Models.swift:229`, 활동은 `ContentView.swift:107` → `Store.swift:38`) + 그리는 날로 자르기(`ContentView.swift:620`·`ContentView.swift:656`) + 점(`recomputeDaysWithSchedule` `Store.swift:134`, `listedSpan` `Models.swift:219`). 〔드:X절·AH-010 (12)(13) + 리드 기록(2026-09-24) 6번 — 단 그 관찰은 t17 이전 빌드다. t17 이후 화면의 자정 넘는 오는 편은 **실기기 이월**(AC-024 21)〕 |
| K10 | 빠르게 연속 스와이프 | ⚠️ | `asyncAfter(0.22)`(`ContentView.swift:828`·`ContentView.swift:835`) 경합 가능 — 재현 안 됨. 〔코드 읽기〕 |
| K11 | 겹친 블록 — 활동과 그 이동 블록이 함께 줄어든다 | ✅ | `Store.packingGroups`(`Store.swift:438`)가 구간 → 활동 대응을, `ScheduleLogic.overlapSlots`(`Models.swift:395`)가 두 단계 칸을 정한다. 〔드:AH-015·016·017 + 시뮬(2026-10-05) AC-024 14~19번 전부 같음〕 |
| K12 | 이동시간을 못 구한 구간 — 앵커 시각에서 아래로 경고 블록 하나 | ⚠️ | `failedBlockAnchor`(`Models.swift:210`) 하나가 블록 선택(`ContentView.swift:509`)·세로 자리(`ContentView.swift:564`)·나열(`Models.swift:229`)·점(`Store.swift:134`)을 정한다. 화면 확인은 오프라인이 필요해 **실기기 이월**(AC-023 13a·AC-024 20·20b — 시뮬레이터의 네트워크 차단이 MapKit 시스템 데몬을 막지 못한다). 〔드:AH-010 (5)–(8)(11)–(13)〕 |
| K13 | 오는 편 이동 블록을 아래로 끌면 활동이 그만큼 길어지고, 가는 편을 끌면 활동 시작이 바뀐다 | ✅ | 활동에 연결된 구간을 끌면 활동 가장자리가 따라 움직인다 — 오는 편은 끝, 가는 편은 시작, 구간은 통째로(`adjustTravelLeg` `Store.swift:1418` → `applyLinkedLegDrag` `Store.swift:1454`, 소유 조회 `owningActivity` `Store.swift:429`, 한계 `effectiveDragMinutes` `Store.swift:1523`). 연결 없는 구간은 예전대로 여유·출발 시각만 바뀐다(`adjustBuffer` `Store.swift:1648`·`shiftEvent` `Store.swift:1636`). 운영자 요청(시뮬 18번 메모) — **카드 t43**(SPEC-UIKIT-012). 〔드:AF-018-02~27·AF-015-09·11·12 — 드라이버 522/522·exit 0. **시뮬레이터 미관측**: 끄는 중 미리보기·24:00 아래 연장·가장자리 자동 스크롤·5분 블록 탭은 S-1~S-18 운영자 몫〕 |

## L. 연동·예외 상황

| # | 상황 | 상태 | 근거 |
|---|---|---|---|
| L1 | 구글 캘린더 등록·삭제 전파 | ✅ | `syncWithGoogle`(`Store.swift:1665-1736`) + 묘비. 앱 활성화마다(`App.swift:98`). 〔빌드·코드〕 |
| L2 | 캘린더에 중복 생성 | ✅ | `reconcileActivities`(`Store.swift:1744-1805`) + `fetchBesirItems`. 〔빌드·코드〕 |
| L3 | 캘린더 앱에서 알림 중복 | ✅ | `reminders` 해제 + PATCH(`GoogleCalendarService.swift:151-152`, 동기화 2-4단계 `Store.swift:1785-1789`). 〔빌드·코드〕 |
| L4 | 삭제한 일정이 되살아남 | ✅ | `deleted_gcal_ids.json`(`Store.swift:83`). 〔빌드·코드〕 |
| L5 | 앱 안 켜도 동기화 | ⚠️ | I3과 같은 사실(`App.swift:20`·`App.swift:43`). 〔빌드·코드〕 |
| L6 | 다른 앱에서 텍스트·이미지·URL 공유 | ✅ | 이미지·텍스트·URL 세 갈래(`ShareViewController.swift:40-49`) → 앱 그룹 큐 → `processSharedInbox`(`App.swift:124-131`). 〔관찰(2026-09-10)〕 |
| L7 | 이동시간 계산 실패 | ✅ | 등록 요약이 "출발·도착 시각이 비어 있어요"(`AIAssistant.swift:1852`), 목록 표지(`AIAssistant.swift:2647`), 시간표 경고 블록(K12). 〔빌드·코드〕 |
| L8 | 장소 검색 결과 0건 | ✅ | 카드의 장소 검색 줄 "후보를 찾지 못했어요…(인터넷이 끊겨 있을 때도 이렇게 보여요)"(`EditCardView.swift:345`). AI 경로는 `placeNotFound`(`AIAssistant.swift:2931-2941`). 〔빌드·코드 + 드:P절〕 |
| L9 | 위치 권한 거부 | ⚠️ | 안내는 나온다 — 수동 추가 화면(`AddEventView.swift:630`), AI 경로(`AIAssistant.swift:1763`·`AIAssistant.swift:2714`), 맛집 화면(`FullSirView.swift:101`). **설정 앱으로 가는 연결은 없다**(`openSettingsURLString` grep 0건). 출발지는 검색으로 우회. 〔빌드·코드〕 |
| L10 | 오프라인 | ⚠️ | 로컬 데이터 정상. 콜드 스타트 오프라인에서 일정이 지워지던 X1은 수리됐다 — 조회 실패를 예외로(`GoogleCalendarService.swift:106-128`), sync 조기 복귀(`Store.swift:1694-1697`). 250건 초과 페이지 순회(`GoogleCalendarService.swift:135-144`). 이동시간·AI는 실패 문구만. **오프라인 런타임은 실기기 이월**(AC-023 13a·AC-024 20·20b). 〔빌드·코드·드:X2절〕 |
| L11 | AI 일일 할당량 소진 | ✅ | `classify`(`AIAssistant.swift:1419-1433`) — 429 + OpenAI 마커 조합만 쿼터, 재시도 중단(`AIAssistant.swift:1403`), 안내문(`AIAssistant.swift:329-336`). 〔빌드 — 미관찰, 실기기 목록(기회)〕 |
| L12 | 앱 강제 종료 후 복귀 | ✅ | JSON 영속화(`Store.swift:70-81`), 카드 보류 중 종료(`AIAssistant.swift:143-145`). 〔빌드 + 드:Q절〕 |
| L13 | 기기 잠금 중 백그라운드 동기화 | ✅ | 키체인 `AfterFirstUnlock`(`GoogleCalendarService.swift:407`). 〔빌드·코드 — 잠금 상태 실동작은 실기기 목록〕 |
| L14 | 모델이 터무니없이 긴 기간을 보냈을 때 (end_iso 9999년 등) | ✅ | 366일 상한(`Store.swift:54`, 걷기 `Store.swift:161-176`) + 생성 시점 가드(`AIAssistant.swift:1919-1921`). 〔드:W2·W3〕 |
| L15 | 이동 질의를 장소로 못 찾았을 때 조용히 넘어가지 않음 | ✅ | 비어 있지 않은 질의의 해석 실패를 모아(`AIAssistant.swift:1985-1999`) 요약 끝에 ⚠️(`AIAssistant.swift:2055-2057`). '가는 편 없음'·빈 값은 실패로 세지 않는다(`AIAssistant.swift:1989`). 〔드:Y절 M + 사용자 보고(2026-09-16)〕 |

---

*(M절은 비어 있다 — 결함 M의 행은 L15다. N·O·P는 2026-09-16 결함 글자에서 따왔다.)*

## N. 캘린더 업로드 상태

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| N1 | 일정 등록이 즉시 끝난다 (58건 반복도 기다리지 않음) | ✅ | 등록은 로컬에서 끝내고(`Store.swift:902-905`) 업로드는 뒤에서 직렬로(`Store.swift:1113-1148`, 앞 작업 대기 `Store.swift:1141-1147`). 〔드:N절 + 관찰(2026-09-16) "눈에 띄게 빨라졌어요"〕 |
| N2 | 올라가는 중·실패가 보이고 다시 시도할 수 있다 | ✅ | 일정 상세의 pending·failed + "구글 캘린더에 추가"(`EventDetailView.swift:128-152`), 설정의 합계 + "다시 시도"(`SettingsView.swift:54-67`, `Store.swift:1162-1165`). 요약의 대기 문구 `calendarPendingNote`(`AIAssistant.swift:1868-1872`, 호출 `AIAssistant.swift:1857`·`AIAssistant.swift:2059`). 〔드:N절 N-3·P절 P-7 — 화면 전환 목격은 실기기 목록〕 |
| N3 | 계정이 연결돼 있지 않으면 쓰기를 시도하지 않음 | ✅ | `googleConnected`(`Store.swift:790`) 게이트: 큐 `Store.swift:1114`·푸시 `Store.swift:1176`·`Store.swift:1211`·수정 `Store.swift:1073`·`Store.swift:1281`. 〔드:N절 N-1〕 |
| N4 | 상태의 진실 — 성공은 어디에 기록되나 | ✅ | `CalendarUploadState`는 pending·failed 둘뿐(`Models.swift:133-152`), 성공의 단일 출처는 gid(`Store.swift:1188`·`Store.swift:1221`). 옛 JSON 호환(`Models.swift:184`). 〔드:N절 N-3·N-4〕 |

## O. 일반명사를 말했을 때 대화가 끊기지 않음

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| O1 | 즐겨찾기 없는 일반명사를 말했을 때 카드로 | ✅ | 값이 차 있어도 앱이 못 풀면 그 줄이 카드에(`unknownPlace` `AIAssistant.swift:494-497` → `AIAssistant.swift:509-512`), 캡션 `unknownPlaceNote`(`AIAssistant.swift:3061-3063`). 〔드:Z절 + 관찰(2026-09-16)〕 |
| O2 | 카드에서 고르면 그 값으로 정확히 1회 등록 | ✅ | `resolvePendingAsk`(`AIAssistant.swift:1207`) 1회. 〔드:Z절 + 관찰(2026-09-16)〕 |
| O3 | 카드를 지나지 않은 호출은 여전히 막힘 | ✅ | creation 게이트(`AIAssistant.swift:3092`)·`placeNotFound`(`AIAssistant.swift:2931`), note 줄은 "비어 있음"으로 세지 않음(`AIAssistant.swift:1693`). 〔드:Z절 O-5〕 |
| O4 | 활동·반복 일정도 같다 | ✅ | 활동 세 장소 줄(`AIAssistant.swift:566-568`), 반복 목적지 줄(`AIAssistant.swift:543`). 사용자가 말한 출발지에는 '가는 편 없음' 칩을 붙이지 않는다(`AIAssistant.swift:701-703`). 〔드:Z절 O-6·O-8〕 |

## P. 장소 줄 — 검색해서 고르기

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| P1 | 장소를 검색해서 고른다 | ✅ | `[장소 검색]` 칩(`EditCardView.swift:131`), 후보 편집기(`EditCardView.swift:320-354`), 후보 행(`EditCardView.swift:357-378`), 5건 상한(`AIAssistant.swift:1097`). 〔드:P절 + 관찰(2026-09-16)〕 |
| P2 | 일반명사 거절과 검색은 다르다 — 기준은 좌표 | ✅ | 자유 텍스트로 일반명사 확정은 거절(`AIAssistant.swift:1154-1157`), 후보에서 고른 이름은 통과(`choose(field:place:)` `AIAssistant.swift:1063-1067`). 〔드:P절 + 관찰(2026-09-16)〕 |
| P3 | 고른 지점이 그대로 등록된다 (이름이 재검색되지 않음) | ✅ | 열쇠는 인자에, 좌표는 `confirmedPlaces`(`AIAssistant.swift:57`). 이름이 겹치면 `confirmedPlaceKey`(`AIAssistant.swift:1083`)가 갈라 준다. 실행부는 고른 좌표 그대로(`AIAssistant.swift:3087`). 즐겨찾기가 이긴다. 〔드:P절〕 |
| P4 | 한글을 빨리 쳐도 검색이 폭주하지 않는다 | ✅ | 350 ms 묶음(`searchPlaces` `AIAssistant.swift:1104`, 상수 `EditCard.swift:741`) + 같은 질의 재호출 차단(`EditCard.swift:764`). 〔드:P절 P-4·P-5〕 |
| P5 | 카드가 사라진 뒤 돌아온 결과·0건 처리 | ✅ | 줄 id로 자리를 다시 찾아 없으면 버린다(`setLookup` `AIAssistant.swift:1131`). 0건·오프라인 문구 L8. 〔드:P절 P-6〕 |
| P6 | 장소 검색을 다시 열면 옛 선택 강조가 남지 않는다 (U-2) | ✅ | 열린 동안 그 줄의 칩 강조를 끄는 판정 한 자리(`EditCardView.swift:89`). 〔시뮬(2026-10-05) AC-015 17~20번 네 화면 전부 같음〕 |

## Q. 장소 채택 · AI 카드의 질문 (t16 · t42 · t47 · t30)

검색에서 온 장소는 사용자가 후보에서 고를 때만 확정된다(t47 — 운영자 원칙, 2026-10-06). 결과가 하나뿐이고
이름이 같아도 묻고, 접미를 뗀 재검색·병합은 없다. 즐겨찾기·같은 대화에서 이미 고른 장소·현재 위치만 묻지
않는다. 판정은 `placeAdoptionDecision` 하나 — 결과가 있으면 언제나 후보 카드, 없으면 실패다.

**이 절의 Q1~Q8·Q16은 t47 sync(2026-10-07)가 `83ac07f` 좌표로 다시 썼다.** 파일의 나머지 `AIAssistant.swift`
인용은 아직 `4987e2d` 좌표라 t44가 한 번에 다시 잇는다 — 이 행들은 이미 새 좌표이므로 그 원장이 건너뛴다
(`.moai/reports/t47/sync-doc-ledger.md`).

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| Q1 | "스타벅스 홍대점까지 가야 해" — 말한 지점이 후보에 나온다 | ⚠️ | 후보는 카카오 원결과 그대로다 — 접미를 뗀 재검색·병합은 지웠다(운영자 ⑤: 제공자 개선과 충돌하지 않게). 풀네임이 카카오에서 빗나가면 후보에 그 지점이 없을 수 있고, 그때는 카드의 장소 검색칸으로 사용자가 직접 찾는다(후보가 얹히고 검색칸이 처음부터 열려 있다 — `AIAssistant.swift:1021-1022`). 질의당 검색 호출은 하나다(`AIAssistant.swift:3224`). 〔드:AI절 AI-16(제공자 순서) + 구조 대조(`placeSearch.search(` 2곳) — 실제 카카오 목록은 시뮬레이터 S-2가 첫 관측, 미관찰. 옛 관찰: 후보가 '스타벅스 대학로점' 하나뿐(시뮬(2026-10-05) 6번 다름)〕 |
| Q2 | "스타벅스 강남점에서 출발" — 비슷한 지점이 여럿이면 조용히 정하지 않고 묻는다 | ✅ | 검색 결과가 있으면 언제나 후보 카드(`placeAdoptionDecision` `AIAssistant.swift:3239-3246`). 출발지도 같은 사다리(`resolveOriginAdoption` `AIAssistant.swift:3089`), 보류 카드 `parkForUnclearPlaces`(`AIAssistant.swift:992-1040`). 〔드:AI절 AI-1·AI-3 + 시뮬(2026-10-06) 6번 — t42 빌드에서 두 줄 후보 관측, t47 빌드 재관찰은 S-1 — 옛 관찰: '케이스퀘어강남점'으로 자동 확정(시뮬(2026-10-05) 6번)〕 |
| Q3 | 이름을 정확히 말했거나 지점이 하나뿐이어도 묻는다 | ✅ | 운영자 원칙(2026-10-06): 검색에서 온 장소는 사용자가 고를 때만 확정된다. 정확 일치·유일 일치 갈래는 지웠고 결과 하나도 후보 카드다(`AIAssistant.swift:3239-3246`). **옛 요구("정확히 말하면 묻지 않는다")는 운영자 지시로 폐기됐다.** 〔드:AI절 AI-2·AI-4·AI-5·AI-14 — 결과 1건의 실제 화면은 시뮬레이터 S-4, 미관찰〕 |
| Q4 | "강남역 가야 해" — 노선이 둘인 역 | ✅ | 노선마다 칩이 따로 뜬다 — 좌표 근접으로 합치지 않는 것이 의도다(운영자가 t45의 "같은 장소로 본다"는 전제를 거부, 2026-10-06). 이름+같은 좌표인 완전 중복만 하나로 접힌다(`AIAssistant.swift:3241-3244`). **2026-10-06 관측**: 노선 갈림으로 후보 카드가 뜬다(`.moai/reports/2026-10-05-sim-4bundle-result.md` §2026-10-06). 〔드:AI절 AI-4 + 시뮬 관측(t42 빌드)〕 |
| Q5 | 같은 지점인지의 판정 | ✅ | 이름 포함·좌표 근접으로 두 결과를 한 지점으로 보는 갈래가 없다. 후보 중복 제거는 이름+정확 좌표 하나뿐이고(`AIAssistant.swift:3241-3244`), 확정 사전의 50 m 판정(`confirmedPlaceKey` `AIAssistant.swift:1165`)은 사용자가 고른 같은 자리를 가르는 다른 질문이다. 〔드:AI절 AI-1·AI-3·AI-4 + 구조 대조(판정 본문의 `isSamePlace`·`.contains(` 0) — plan.md 후속 31 닫힘〕 |
| Q6 | 같은 이름의 두 지점이 후보에 둘 다 나온다 | ✅ | 중복 제거 키가 이름+정확 좌표라 같은 이름 다른 좌표가 각각 칩이 된다(`AIAssistant.swift:3241-3244`). 두 줄이 같은 이름 다른 좌표를 골라도 확정 열쇠가 가른다(`confirmedPlaceKey` `AIAssistant.swift:1165`). 〔드:AI절 AI-15·AI-20 — 실제 카카오 응답의 같은 이름 지점·주소가 빈 칩은 미관찰(디자인 렌즈 D-12, 가설) — plan.md 후속 32 닫힘〕 |
| Q7 | 조회·수정·점심 경로도 모호하면 묻는다 | ⚠️ | 묻는다 — 수정의 새 장소(`AIAssistant.swift:2952-2958`), 반복 점심(해석을 첫 저장 앞으로 옮겼다: 보류 `AIAssistant.swift:2307-2310` < 첫 저장 `AIAssistant.swift:2314`), 식사 추천 기준 장소(`AIAssistant.swift:2805-2818`), 이동시간 출발지·목적지(`AIAssistant.swift:2874-2901`). 평탄화 래퍼 둘은 지웠다. 줄 재료는 `placeRow(key:tool:)`(`AIAssistant.swift:775-785`). **⚠️인 이유**: 드라이버는 보류된 카드에서 시작해(`drvPark`) "검색 → 보류" 첫 실행을 지나지 않는다(`adoptPlace`에 검색 주입 지점이 없다 — plan.md 후속 35). 순서는 구조 대조·코드 읽기뿐이고 동작은 시뮬레이터 S-7·S-8·S-11·S-12가 첫 관측이다. 〔드:AI절 AI-18~22 + 구조 대조 AC-008·AC-010 — plan.md 후속 33 닫힘〕 |
| Q8 | 나쁜 망에서 장소 해석이 너무 오래 걸리지 않는다 | ⚠️ | 재시도 조건은 없어졌다 — 질의당 장소 검색 호출은 하나다(`AIAssistant.swift:3224`). 남은 대기는 그 호출 안에서 카카오가 실패한 뒤 MapKit으로 넘어가는 폴백 한 번이다(`PlaceSearch.swift:13-18`). plan.md 후속 34는 재시도 부분이 해당 없어졌다. 〔가설 — 대기 시간 미측정〕 |
| Q9 | 후보에서 고른 뒤 확정 칩을 다시 탭해 다른 후보로 바꾼다 | ⚠️ | 화면으로 확인된 적 없다 — 시뮬(2026-10-05) 2번은 후보 칩이 하나뿐이라 **구조적으로 건너뜀**. Q1 수리로 후보가 여럿 나오는 질의가 생겼으니 다시 돌릴 수 있다. 〔미관찰〕 |
| Q10 | 출발지·목적지를 둘 다 물을 때 출발지 줄이 먼저 | ❌ | 지금은 목적지 줄이 먼저 붙는다(`AIAssistant.swift:509-512` — 목적지 `AIAssistant.swift:509`, 출발지 `AIAssistant.swift:511`). 운영자 요청(시뮬 7번 메모) — **카드 t30 ④**. 〔코드 읽기〕 |
| Q11 | AI 카드에서 '가는 편 없음'을 고르면 가는 편 이동수단 줄이 사라진다 | ❌ | 카드 줄은 호출 인자로 한 번 정해져 선택에 따라 줄지 않는다 — 왕복이면 가는 편 수단 줄이 늘 붙는다(`AIAssistant.swift:622-625`). 실행부가 구간을 안 만들 뿐이다. 운영자 요청(시뮬 11번-②) — **카드 t30 ⑤**(수동 편집 카드는 이미 그렇게 한다 — `EditCard.swift:359`). 〔코드 읽기〕 |
| Q12 | 같은 이름을 여러 줄에 말함 ("스타벅스 가야 해, 스타벅스에서 출발") | ✅ | 같은 검색어가 두 장소 줄에 오면 값이 있어도 줄을 띄워 지점을 고르게(`AIAssistant.swift:516-523`, 활동 세 줄 `AIAssistant.swift:576-584`, 캡션 `AIAssistant.swift:847-849`). 〔시뮬(2026-10-05) 7번·8번〕 |
| Q13 | 왕복에서 출발지를 말했는데 가는 편 출발지를 다시 묻는 이유가 보인다 | ✅ | 설계된 재확인 — 캡션이 채워 온 값을 적는다(`AIAssistant.swift:617-619`, 문구 `AIAssistant.swift:840-842`). 〔시뮬(2026-10-05) 11번 — 운영자 질문에 답변 완료〕 |
| Q14 | '현재 위치'에서 출발해 검색한 장소로 가는 활동 | ⚠️ | **기록만 한 관찰**(시뮬(2026-10-05) 16a): `travel_from_query=__current_location__` + 후보 선택으로 고른 `place_query=스타벅스 대학로점` → **물음 없이 활동 + 가는 이동(자동차)이 바로 등록**됐다(기대 I-1은 물음 발생 — 시뮬레이터가 좌표를 줘서 풀린 것으로 추정, 토큰 해석 `AIAssistant.swift:1948-1951`). 이어 모델이 **`update_schedule`을 같은 인자로 2회 재시도**했다(도구 결과가 date 추가를 안내했는데 따르지 않음 — 안내 `AIAssistant.swift:2805-2807`). 카드 아님. |
| Q15 | 등록이 끝났는데 모델이 결과를 부정하지 않는다 | ⚠️ | 시뮬(2026-10-05) 14번 전사: 통근 33건이 기대대로 등록된 뒤 모델이 "요청과 다르게 등록됐어요… 전체 삭제하고 다시 등록할까요?"라고 말했다. 앱이 막을 수 없는 모델 멘트(프롬프트 영역). 〔관찰 — 기록만〕 |
| Q16 | 수정·조회 카드가 "등록"이라고 말하지 않는다 | ✅ | **병합 전 수리 완료** — 1차(`7dbcd9d`, 운영자 확정 문구): 확인 버튼이 카드를 만든 도구를 따르고(등록하기·고치기·조회하기 — `AIChatView.swift:112-114` → `pendingConfirmTitle` `AIAssistant.swift:967`), 버린 카드 말풍선(`AIAssistant.swift:1456`)과 이미 열린 카드 가드(`AIAssistant.swift:1000-1006`)가 **열린 카드의 도구**로 동사를 고른다(`toolName` `AIAssistant.swift:978`). 2차 마이크로 수리(운영자 확정 ①, 2026-10-07): 혼합 턴 버튼 회귀 닫힘 — `creatingTools` 상수(`AIAssistant.swift:974`)가 두 벌 리터럴을 묶고 `toolName`이 생성 도구를 먼저 본다. 가드 첫머리 동사(옛 ②)는 운영자가 사양대로 유지 확정. 〔드:Q16절 승격 6건 포함 **498/498**(`gate-q16micro-driver.log`) — 버튼 글자 화면은 시뮬레이터 S-7·S-11·S-12, 미관찰〕 |

## S. 즐겨찾기 · 설정 · 공유 · 출시 전 제거

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| S1 | 집·회사를 즐겨찾기에 추가 | ✅ | 이름 + 장소 검색(2글자 이상 — `FavoritesView.swift:94-95`) → `addFavorite`(`FavoritesView.swift:87-92` → `Store.swift:761`), 저장 `favorites.json`(`Store.swift:74`). 〔빌드·코드〕 |
| S2 | 즐겨찾기 삭제 | ✅ | 삭제 버튼(`FavoritesView.swift:36`) → `Store.swift:766`. 〔빌드·코드〕 |
| S3 | 즐겨찾기 이름만 말해도 그 장소로 | ✅ | 사다리 첫 단(`locallyResolvedPlace` `AIAssistant.swift:1358`, `AIAssistant.swift:3087`), 프롬프트에 즐겨찾기 이름 주입(`AIAssistant.swift:1444-1445`). 〔시뮬(2026-10-05) 10번 "즐겨찾기 이름 — 양성 대조"〕 |
| S4 | 캘린더 자동 등록 켜고 끄기 | ✅ | 설정 토글(`SettingsView.swift:18`). 〔빌드·코드〕 |
| S5 | 구글 계정 연결·끊기 | ✅ | 연결(`SettingsView.swift:41-42`)·끊기(`SettingsView.swift:33-34`). 〔빌드·코드 — 실제 OAuth는 실기기 목록〕 |
| S6 | 출시 빌드에 테스트용 버튼이 없다 | ⚠️ | 아직 있다: 설정의 "일정 모두 삭제"(`SettingsView.swift:72-86` → `Store.swift:1648`), 채팅의 대화 복사(`AIChatView.swift:56` → `AIAssistant.swift:246`). `⚠️ 테스트용 임시` 표지 2건(grep). 출시 전 제거 대상(CLAUDE.md). 〔grep〕 |
| S7 | 공유한 내용이 앱을 열 때 처리된다 | ✅ | 앱 활성화마다 큐를 비워 처리(`App.swift:96-99`, `SharedInbox.swift:28-33`). 〔관찰(2026-09-10)〕 |
| S8 | AI가 답하는 중에 공유한 항목이 도착해도 사라지지 않는다 | ⚠️ | `drain()`이 큐 파일을 먼저 지우고(`SharedInbox.swift:31`) `handleShared`는 응답 중이면 그냥 돌아간다(`AIAssistant.swift:285`) — 그 사이 도착한 항목은 안내 없이 버려질 수 있다. 〔**코드 읽기 가설 — 재현 안 함**, code-safety 판정 대상〕 |

---

## 요약 — 2026-10-06 (UI통일 Day 닫기)

집계는 ux-check.md의 세는 명령 출력이다(표 행의 상태 칸을 기계로 셌다).

**t47 sync(2026-10-07) 갱신**: Q1~Q8을 t47 동작으로 다시 쓰고 Q16(수정·조회 카드 문구 — 병합 전 수리 뒤 sync 2차에서 ⚠️)을 더했다. 위 집계 줄의 Q 항목은 이 갱신 뒤 값이며 나머지 행의 상태는 Day 닫기 판 그대로다.

**이번 Day에 관찰로 닫힌 것**: 편집 카드 통일 화면(D9·E7·E8 — AC-023 1~13), 묶음 배치(K11 —
AC-024 14~19), 장소 검색 재오픈 강조(P6 — AC-015), AI 카드 1~16a 중 6번(Q1·Q2 — 리드 전달).

**⚠️ 현존**: D11·K12·L10(오프라인 화면 — 실기기), H5(알림 권한 거부 무고지), H6(지난 출발 알림 화면 — 실기기),
G10·G15(프롬프트 전용), I3·L5(iOS 백그라운드 시점), K10(스와이프 경합), L9(설정 연결 없음),
Q1·Q7·Q8·Q9(장소 채택 — t47 뒤: 실제 카카오 목록·"검색 → 보류" 첫 실행 미관찰), Q16(t47 카드 문구 — 혼합 턴·가드 첫머리·드라이버 단언 없음), Q14·Q15(모델 행동 관찰), S6(테스트용 버튼), S8(공유 유실 가설).
**❌ 현존**: J8·J9(계획된 뒤 Day), Q10·Q11(t30). (K13은 t43 sync에서 ❌ → ✅ — 드라이버 522/522, 시뮬레이터 미관측이라 화면 동작은 S-1~S-18 운영자 몫.)

## 확인 목록

### (a) 이 회차가 직접 검증한 것 — 사용자 행동 필요 없음

드라이버 492/492·exit 0·실제 데이터 대조 통과 · iOS 새 DerivedData 빌드 `BUILD SUCCEEDED`
(SwiftCompile 42, 소스 경고 0) · 프록시 7/7 · 이 표의 인용 전수 기계 대조 · grep 확인(AI 도구 9개,
알림 권한 읽는 곳 0, 설정 연결 0, 테스트용 표지 2, 스와이프 지연 0.22 두 곳). 명령과 출력은
ux-check.md 2절.

### (b) 시뮬레이터(iPhone 17 Pro)에서 운영자가 — 시뮬레이터로 되는 것

1. **[Q9 — AC-014 2번 재실행]** 초기화: 새 대화. `내일 오후 5시까지 스타벅스 홍대점 가야 해, 집에서 출발, 대중교통, 여유 10분, 10분 전 알림`
   → 후보 카드에서 홍대 지점 하나를 고른 뒤 그 **확정 칩을 다시 탭** → 후보 목록이 다시 열리고 다른 지점으로 바꿀 수 있다.
   실패: 탭해도 아무 반응이 없거나, 바꾼 뒤 등록 요약의 목적지가 처음 고른 지점이다.
2. **[Q4 — H-2 관측]** 새 대화. `내일 오후 3시까지 강남역 가야 해, 집에서 출발` → 목적지가 후보 카드로 뜨는지,
   뜬다면 후보 이름이 어떤 모양인지(예: '강남역 2호선'·'강남역 신분당선')를 그대로 적어 온다. 판정은 리드 몫이다.
3. **[F7]** 수동 추가 화면에서 값을 전부 채운 뒤 저장 버튼을 빠르게 두 번 → 일정 1건만. 실패: 같은 일정 2건.
4. **[G16 잔여]** 시각 줄에서 값을 확정한 뒤 기준 칩을 다시 탭해 반대 기준으로 재확정 → 시각 칩을 다시 열면 바퀴가 확정된 시각에 앉는다.
5. **[L12·G13]** 카드를 반쯤 고른 채 시뮬레이터에서 앱을 강제 종료 → 재시작 → 반쯤 고른 카드·등록 잔재가 없다.
6. **[A9 — 2026-09-24 목록 5번 이월]** 같은 제목·목적지로 늦은 회차를 먼저 등록하고 이른 회차를 나중에
   → 두 번째 요약이 **이른 회차의 시각**을 말한다. 실패: 늦은 회차의 시각을 말한다.
7. **[L15 — 같은 목록 7번 이월]** 왕복 만들기에서 가는 편 출발지에 즐겨찾기·목록 밖 일반명사(예: `학원`)
   → 요약에 `⚠️ … 찾지 못해 그 부분은 만들지 못했어요`. 실패: 성공 문구만 나온다.
8. **[N2 — 같은 목록 10번 이월]** 구글 계정을 연결한 상태에서 일정 등록 → 일정 상세의 "올리는 중" 표시가
   "등록됨"으로 바뀌고 설정의 대기 합계가 줄어든다.
9. **[AC-009 13번 — 같은 목록 14번 이월]** 보임새 대조 문구를 리드가 다시 설명한 뒤 판정.
10. **[t47 — AC-012·013]** SPEC-UIKIT-011 시뮬레이터 스크립트 S-1~S-12(`.moai/specs/SPEC-UIKIT-011/acceptance.md` 「시뮬레이터 스크립트」). 각 단계는 새 대화로 시작하고 "같음/다름 + 화면 메모"로 적는다. 실제 카카오 목록·카드 장수·확인 뒤 모델 발화·수정/조회 카드의 버튼 글자(Q16)를 처음 보는 자리다.

### (c) 실기기 전용 — 명령으로도 시뮬레이터로도 확인할 수 없는 것

배포 전제: 서명 팀 재결정(운영 메모 — DFEME8ZQT9 계정 없음, 배포는 Y54D2W4F4T 오버라이드)은 리드 몫이다.
항목별 절차·기대·실패 모양은 ux-check.md "실기기에서 직접 확인해야 할 목록"에 있다.

1. 출발 알림 실제 수신(앱 백그라운드·기기 잠금 포함)
2. 지난 출발 시각 일정의 알림 상태 문구 — AC-024 20a(H6)
3. 오프라인에서 가는 이동 추가 → 안내 + 경고 블록 — AC-023 13a(D11·K12·L10)
4. 오프라인에서 오는 이동 추가 → 경고 블록 — AC-024 20(K12)
5. 계산된 오는 이동이 곧 출발할 때 오프라인 재활성화 → 경고 블록 하나 — AC-024 20b(K12)
6. 자정을 넘는 오는 이동(이동시간 계산됨) — AC-024 21(K9)
7. t42 후보 카드의 실제 모습(후보 칩 줄·캡션·여러 지점)
8. 구글 캘린더 앱에서 보이는 모습 + 다른 기기 전파 + 업로드 상태 전환(N2)
9. 다크 모드에서의 지하철 노선 이름·색
10. VoiceOver 낭독 4종 + 이동 줄(AC-024 22) + AC-010 16번
11. 큰 글자(Dynamic Type)에서 카드·칩 줄바꿈
12. 제스처 감각 — 꾹 눌러 드래그, 직접입력(여유·알림 분)의 불편 여부
13. 대중교통 단계 시각 표기(`shortTimeFmt`) 렌더링
14. AI 일일 할당량 소진 안내문(기회 되면)
15. 카드 크롬의 실제 질감(raised + 스트로크)
16. 일정 편집 뒤 출발 알림 재예약·구글 캘린더 항목 반영(t7 실기기 셋 중 iOS 둘 — 맥 편집 시트는 iOS 전용 방침으로 보류)
