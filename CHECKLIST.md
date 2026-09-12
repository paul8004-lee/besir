# besir 사용자 요구사항 체크리스트

사용자가 besir의 **전체 기능**을 써보면서 마주칠 수 있는 상황을 모아, **현재 코드가 실제로
처리 가능한지** 검증한 표. 2026-09-11 기준(Phase 1 Day 7 — 맛집 추천까지 반영).

범례: ✅ 됨 · ⚠️ 부분적/우회 필요 · ❌ 안 됨

현재 AI 도구 10개: `create_schedule`, `create_activity`, `create_recurring_schedule`,
`update_schedule`, `update_recurring_schedule`, `list_schedules`, `check_travel_time`,
`delete_schedule`, `remember_fact`, `forget_fact`

---

## A. 단발성 일정 만들기

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| A1 | "내일 3시까지 강남역 가야 해" | ✅ | `create_schedule(arrival_iso)` — 이동시간 역산해 출발 시각 계산 |
| A2 | "6시에 집에서 바로 출발할래" | ✅ | `create_schedule(departure_iso)` — 출발 기준, 버퍼 0 |
| A3 | "8시부터 10시까지 강남에서 친구 만나" | ✅ | `create_activity` — 주황색 활동 블록 |
| A4 | "가서 놀고 집까지 오는 것도 잡아줘" | ✅ | `create_activity(travel_from_query, return_to_query)` — 활동+이동 2건이 **서로 묶여서** 생성 |
| A5 | "다음 주 화요일 오후 2시 병원" | ✅ | 시스템 프롬프트에 현재 시각 주입 + `parseDate` |
| A6 | 카톡 일정표 스크린샷 공유 | ✅ | Share Extension → `handleShared` → 이미지 파싱 |
| A7 | 한 번에 여러 일정 등록 | ✅ | `runLoop`이 한 턴에 여러 툴 호출 처리 |
| A8 | "지금 출발하면 몇 시 도착해?" (등록 없이 조회만) | ✅ | `check_travel_time` — 등록 없이 소요시간·도착 시각만 계산 |

## B. 반복 일정

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| B1 | "매주 평일 9시~6시 회사" | ✅ | `create_recurring_schedule` — 출근·복귀·활동 블록 자동 생성 |
| B2 | "월수금만" | ✅ | `weekdays` |
| B3 | "점심에 밖에서 먹어" | ✅ | `lunch_place_query` — 점심 왕복 이동 + 점심 활동 블록 |
| B4 | "6개월간 계속" | ✅ | **최대 26주(약 6개월)**로 확대(`Store.maxRecurrenceWeeks`). 그 이상은 회차마다 구글 API를 한 번씩 부르는 구조상 무리 — RRULE 도입이 필요 |
| B5 | "매월 첫째 주 월요일" | ✅ | `nth_week_of_month`(1~4, -1=마지막) — `RecurrenceRule` |
| B6 | "격주로" | ✅ | `every_n_weeks`(2=격주) |
| B7 | "공휴일은 빼고" | ✅ | `skip_holidays` — `KoreanHolidays`. 음력 공휴일은 표가 아니라 `.chinese` 달력으로 계산해 연도 갱신 불필요. 대체공휴일은 단순화 규칙 |

## C. 조회

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| C1 | "지금 등록된 일정 뭐 있어?" | ✅ | `list_schedules` |
| C2 | "오늘/이번 주 일정만 알려줘" | ✅ | `list_schedules(from_date, to_date)` 날짜 범위 필터 추가 |
| C3 | "내일 몇 시에 나가야 해?" | ✅ | 출력이 "8:30 출발 → 9:00 도착" 형태로 **출발 시각 포함** |
| C4 | "이번 주에 몇 건 있어?" | ✅ | C2와 동일 |

## D. 수정

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| D1 | "방금 만든 반복 일정 자동차로 바꿔줘" | ✅ | `lastRecurrenceId`를 대화 기록과 함께 저장 — 앱을 껐다 켜도 유지 |
| D2 | "도착 여유 20분으로 늘려줘" | ✅ | D1과 동일 |
| D3 | "그 약속 4시로 미뤄줘" | ✅ | `update_schedule(new_arrival_iso / new_departure_iso)` |
| D4 | "장소 바꿔줘" / "제목 바꿔줘" | ✅ | `update_schedule(new_place_query, new_title, new_mode)`. 활동은 `new_start_iso`/`new_end_iso`로 옮기며 **묶인 이동도 따라 움직임** |
| D5 | 화면에서 블록 드래그로 시간 이동 | ✅ | 꾹 눌러 드래그. 반복이면 "전체/이 일정만" 선택 |

## E. 삭제

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| E1 | "강남 약속 취소해줘" | ✅ | `delete_schedule(title_query)` — 확인 후 삭제 |
| E2 | "반복 일정 전체 삭제" | ✅ | 제목 일치분만 삭제(다른 구간 보호) |
| E3 | "이번 주 화요일 것만 빼줘" | ✅ | `date` + `whole_series:false` |
| E4 | "오늘 일정 다 지워줘" | ✅ | `date`만으로도 삭제 가능(제목·날짜 중 최소 하나 필요). 5건 초과면 재확인 요구 |
| E5 | 삭제한 게 동기화로 되살아남 | ✅ | 삭제 묘비(`deleted_gcal_ids.json`)로 해결 |

## F. 충돌·시간 계산

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| F1 | 기존 일정과 겹치면 알려주기 | ✅ | `Store.conflicts` — `create_schedule`이 등록 전에 검사 |
| F2 | "늦게 도착해도 되니 끝나고 바로 출발" | ✅ | `on_conflict:"late_arrival"` |
| F3 | "겹쳐도 그냥 등록해" | ✅ | `on_conflict:"ignore"` |
| F4 | 실시간 교통상황 반영 | ✅ | 출발 2시간 이내 일정은 앱 진입 시 재계산 |
| F5 | 수동(+ 메뉴)으로 만들 때도 충돌 경고 | ✅ | `AddEventView`에 겹침 경고 배너 추가(저장은 막지 않음 — 일부러 겹치는 경우가 있어서) |
| F6 | 활동 블록끼리 겹침 경고 | — | **일부러 넣지 않음**(2026-09-11 사용자 결정). 두 활동을 동시에 해야 하는 경우가 정상이라 경고가 방해가 된다. 이동 구간 충돌(F1)만 경고한다 |

## G. 기억·개인화

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| G1 | "나 주로 차로 다녀" 기억 | ✅ | `remember_fact` → `ai_memory.json`, 대화 초기화와 무관하게 유지 |
| G2 | 설정값 임의 추측 방지 | ✅ | 시스템 프롬프트가 이동수단·버퍼·알림을 반드시 묻게 강제 |
| G3 | "그거 잊어버려" | ✅ | `forget_fact(fact_query / all)` |

## H. 알림

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| H1 | "출발 30분 전에 알려줘" | ✅ | `notify_lead_minutes` |
| H2 | "이 일정은 알림 필요 없어" | ✅ | `ScheduledEvent.notifyEnabled` + AI `notify_enabled` + `AddEventView` 토글. 알림 예약 코드 5곳을 `scheduleDepartureNotification` 하나로 합치면서 한 곳에서 처리 |
| H3 | 반복 일정 뒤쪽 회차 알림 누락 | ✅ | iOS 64건 제한 대응(`rescheduleNearestNotifications`) |
| H4 | besir에서만 알림(캘린더 앱 중복 제거) | ✅ | 구글 이벤트 `reminders` 해제 + 기존 항목도 동기화 시 정리 |

## I. 연동

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| I1 | 구글 캘린더 자동 등록 | ✅ | `autoAddToCalendar` |
| I2 | "이건 캘린더에 올리지 마" (건별 선택) | ✅ | `syncToCalendar`(이동·활동 양쪽) + AI `add_to_calendar` + 화면 토글 |
| I3 | 앱 안 켜도 동기화 | ⚠️ | 백그라운드 동기화 있으나 **iOS가 실행 시점 결정**, 강제 종료 시 미실행 |
| I4 | "근처 맛집 추천해줘" | ✅ | `recommend_meal` 툴(J10) + 일정 상세 "목적지 주변"(J1) + be full sir 화면 |

## J. 맛집 추천 (be full sir, Day 7)

| # | 사용자 요구 | 상태 | 근거 |
|---|---|---|---|
| J1 | 일정 상세에서 목적지 주변 맛집 보기 | ✅ | `EventDetailView` "목적지 주변" 섹션 → `PlaceSearch.nearbyPlaces` (카카오 `category_group_code=FD6`, 목적지 좌표 1km, 거리순) |
| J2 | 카페도 보기 | ✅ | 맛집/카페 세그먼트(`MealCategoryFilter` FD6/CE7) |
| J3 | 업종·거리·주소 확인 | ✅ | "한식 · 230m" + 도로명 주소 |
| J4 | 카카오맵에서 자세히 보기 | ✅ | 각 행의 `place_url` 링크 |
| J5 | 주변에 결과가 없을 때 | ✅ | "주변 1km 안에서 찾지 못했어요" 빈 상태(크래시 없음) |
| J6 | 추천을 골라 일정으로 등록 | ✅ | `FullSirView` → "일정으로 추가" → `Store.addEvent` + `MealLog.scheduledEventId` 연결 (Day 10 예정이었으나 UI 분리와 함께 선반영) |
| J7 | 먹은 것 기록(`MealLog`) | ✅ | `FullSirView`의 "먹었어요" + "최근 먹은 것" 목록(삭제 가능) |
| J10 | AI에게 메뉴 추천받기 | ✅ | `recommend_meal` — "1시 점심시간에 일식", "일식 중 초밥"처럼 키워드를 좁혀도 그대로 검색. 시각만 말하면 그때 있을 장소를 기준으로 |
| J11 | 홈에서 서비스 선택 | ✅ | `RootView` — be on-time sir / be full sir 카드 |
| J8 | 예산 기반 추천 | ❌ | be rich sir(Phase 4) 이후 |
| J9 | 배달·요리 카테고리 | ❌ | **Day 8이 조사 Day** — 오픈 API 유무 확인 후 결정 |

## K. 화면 조작

| # | 상황 | 상태 | 근거 |
|---|---|---|---|
| K1 | 월간 ⇄ 일간 전환 | ✅ | 헤더 화살표 버튼 |
| K2 | 월간·주간·일간 좌우 스와이프 | ✅ | `SwipePager` |
| K3 | 스와이프 중 날짜가 잘못 선택됨 | ✅ | `@GestureState`로 "한 번이라도 움직였는지" 추적 |
| K4 | 블록 위에서 세로 스크롤 | ✅ | UIKit `shouldRecognizeSimultaneouslyWith` |
| K5 | 블록 탭 → 상세 | ✅ | 좌표 기반 히트테스트(`span(for:)`) |
| K6 | 겹친 블록 중 짧은 것 선택 | ✅ | 지속시간 최소 우선 |
| K7 | 꾹 눌러 드래그로 시간 이동 | ✅ | 반복이면 "전체/이 일정만" 확인 |
| K8 | 활동을 옮기면 묶인 이동도 이동 | ✅ | `linkedActivityId` |
| K9 | 자정을 넘기는 블록 표시 | ✅ | `span(for:)`이 도착일 0시부터 그림 |
| K10 | 빠르게 연속 스와이프 | ⚠️ | `SwipePager`의 `asyncAfter(0.22)` 경합 가능 — 실사용 재현 안 됨 |

## L. 연동·예외 상황

| # | 상황 | 상태 | 근거 |
|---|---|---|---|
| L1 | 구글 캘린더 등록·삭제 전파 | ✅ | `syncWithGoogle` + 삭제 묘비 |
| L2 | 캘린더에 중복 생성 | ✅ | `reconcileActivities` |
| L3 | 캘린더 앱에서 알림 중복 | ✅ | `reminders` 해제 + 기존 항목 PATCH |
| L4 | 삭제한 일정이 되살아남 | ✅ | `deleted_gcal_ids.json` 묘비 |
| L5 | 앱 안 켜도 동기화 | ⚠️ | 백그라운드 실행 시점은 iOS가 결정, 강제 종료 시 미실행 |
| L6 | 다른 앱에서 텍스트·이미지 공유 | ✅ | Share Extension → `handleShared` |
| L7 | 이동시간 계산 실패 | ✅ | 빨간 블록으로 표시(숨기지 않음), 탭·삭제 가능 |
| L8 | 장소 검색 결과 0건 | ✅ | 빈 목록, 크래시 없음 |
| L9 | 위치 권한 거부 | ⚠️ | 출발지 수동 지정으로 우회 가능하나 안내 문구는 약함 |
| L10 | 오프라인 | ⚠️ | 로컬 데이터는 정상, 이동시간·AI는 실패 문구만 |
| L11 | AI 일일 할당량 소진 | ✅ | 초기화 시각·대안 안내(재시도 안 함) |
| L12 | 앱 강제 종료 후 복귀 | ✅ | 모든 상태가 JSON 영속화 |
| L13 | 기기 잠금 중 백그라운드 동기화 | ✅ | 키체인 `AfterFirstUnlock` |


---

## 요약 — 2026-09-11 (Day 7 완료 시점)

**A~I의 ❌를 전부 해결했고, Day 7(맛집 추천)으로 I4까지 닫았다.**
남은 ❌는 **뒤 Day에 계획된 작업 2개뿐**(J9 = Day 8 조사, J8 = Phase 4). J6·J7(추천→일정 등록,
식사 기록)은 Day 10 예정이었으나 UI 분리 작업과 함께 앞당겨 반영했다.

| 항목 | 해결 |
|---|---|
| A8 이동시간만 조회 | `check_travel_time` 도구 |
| B5 월 단위 반복 | `RecurrenceRule.nthWeekOfMonth` |
| B6 격주 | `RecurrenceRule.everyNWeeks` |
| B7 공휴일 제외 | `KoreanHolidays` — 음력은 `.chinese` 달력으로 계산(표 하드코딩 없음), 대체공휴일 포함 |
| D1·D2 반복 수정이 대화 내에서만 | `lastRecurrenceId` 영속화 |
| F6 활동끼리 겹침 | `activityConflicts` — 다른 장소일 때만 경고 |
| G3 기억 삭제 | `forget_fact` 도구 |
| H2 알림 끄기 | `notifyEnabled` + 알림 예약 코드 5곳 → 1곳 통합 |
| I2 건별 캘린더 제외 | `syncToCalendar`(이동·활동) |

**2026-09-11 추가 반영**: 가는 편·오는 편 이동수단 개별 선택, 활동 겹침 경고 제거(사용자 결정),
`recommend_meal` AI 툴, be on-time sir / be full sir **화면 분리**(`RootView` 홈 + `FullSirView`).

**함께 한 간결성 정리**: 알림 예약 6줄이 추정 함수 5곳에 복사돼 있던 것을
`scheduleDepartureNotification` 하나로 합쳤다(H2를 넣으려면 원래 5곳을 똑같이 고쳐야 했다).
반복 날짜 생성 로직도 `addRecurringEvents`/`addRecurringActivities`에 중복돼 있던 것을
`RecurrenceRule.dates(from:weeks:)` 한 곳으로 모았다.

## 검증 방법
- 도구 목록·파라미터·필수값은 `Shared/AIAssistant.swift`의 `toolsJSON()`과 각 `execute*` 함수를 직접 읽어 확인.
- 충돌 판정 규칙은 경계 조건 8가지를 별도 스크립트로 검증(인접·같은 반복그룹·포함관계 등) — 전부 통과.
- 한국 공휴일 계산은 2026·2027년을 실제 값과 대조해 검증(설날 2026-02-17 / 추석 2026-09-25 /
  부처님오신날 2026-05-24, 대체공휴일 포함) — 전부 일치.
- ✅ 중 **2026-09-10에 추가·보강된 것은 전부 빌드·설치만 완료, 실사용 확인 전**이다
  (A2·A3·A4·A8·B4·B5·B6·B7·C2~C4·D1~D4·E4·F1·F2·F3·F5·F6·G3·H2·I2).
