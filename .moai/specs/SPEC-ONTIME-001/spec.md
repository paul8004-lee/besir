---
id: SPEC-ONTIME-001
title: "be on-time sir — 일정·이동시간·출발알람·캘린더 동기화 (as-built)"
version: "0.2.3"
status: draft
created: "2026-09-12"
updated: "2026-09-15"
author: "manager-spec"
priority: P1
phase: "v0.1.1 target"
module: "be-on-time-sir"
lifecycle: spec-anchored
tags: "be-on-time-sir, calendar-sync, ai-assistant, retroactive-baseline"
tier: L
---

# SPEC-ONTIME-001 — be on-time sir (as-built 베이스라인)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-12 | 최초 작성 — 이미 완성·상용 중인 be on-time sir의 현재 동작을 GEARS로 정식화(as-built). plan.md §1/§6 Phase 0.5, CLAUDE.md 계약, 코드베이스(Store/ContentView/AIAssistant/GoogleCalendarService 등) 직접 확인 근거 |
| 0.2.0 | 2026-09-13 | plan-audit FAIL(0.55, Tier L 통과선 0.85) 지적 반영 — 코드와 어긋난 서술 4건 정정(반복 한도 12주→`maxRecurrenceWeeks` 26주, 점심 이동 생략 조건, REQ-001의 출발시각 단일 출처, `AfterFirstUnlock` 의미 반전) + 깨진 파일·심볼 인용 교체 + CLAUDE.md 계약 2·3·5후반·6을 Out of Scope에 명시 |
| 0.2.1 | 2026-09-14 | 미검증이던 REQ 17건을 함수 본문과 1:1 대조 — 15건은 근거 일치 확인, 2건 정정. REQ-060은 삭제된 Workers AI 경로를 인용하고 있어(커밋 `860e121`이 유발한 드리프트) 현행 단일 백엔드 상태로 교체, REQ-042는 재업로드가 `autoAddToCalendar`·`wantsCalendarSync` 두 게이트에 걸렸다는 사실을 누락해 보강 |
| 0.2.2 | 2026-09-15 | 커밋 `545704c` + 작업 트리 변경(`confirm_zero`, `series_number`, `recommend_meal`의 `radius_meters` 0 처리)을 함수 본문 대조 반영 — REQ-062에 0 되묻기(되묻은 `(recurrenceId, buffer, notify)` 조합에만 `confirm_zero` 인정, 이미 0인 값은 복원 탈출구 없음)와 번호 불일치 시 `list_schedules` 재호출 안내, `[반복 n]` 그룹 번호 매기기·`series_number:0` 폴백을 추가. REQ-061의 11개 툴은 변동 없음 확인. `AIAssistant.swift`가 이 변경들로 66줄 늘며 밀린 인용 줄번호를 REQ-011/021/060과 acceptance.md AC-002/003/008에서 실측 재정렬 |
| 0.2.3 | 2026-09-15 | 배포 전 코드세이프티 검토가 같은 파일에 추가한 3건 행동 변경을 REQ-062에 반영 — 수정 결과 문구가 시리즈 첫 회차 제목으로 대상을 밝힘(`:1229-1232`), 이동 일정이 모두 지워진 그룹에는 번호를 붙이지 않음(`updatableRids` `:1449`, 번호 없는 줄 `:1471-1474`), `[n]` 안내 문장을 20줄 캡를 통과한 줄 기준으로 게이팅(`:1483-1485`). 같은 변경으로 밀린 인용 재정렬 — REQ-062 내부 6곳, REQ-011 `:1767→:1786`, REQ-021 `isSamePlace` `:1729→:1748`, acceptance.md AC-002·AC-007. REQ 25건·툴 11개 변동 없음 확인 |

## 0. 이 SPEC의 성격

**이 문서는 사전 설계 문서가 아니라 as-built 베이스라인이다.** be on-time sir는 besir 다섯 서비스 중 유일하게 완성된 서비스로, 여러 세션에 걸쳐 이미 상용 수준으로 동작 중이다. 아래 REQ는 "앞으로 만들 것"이 아니라 "지금 코드가 실제로 하는 것"을 GEARS 문형으로 정리한 것이며, 각 REQ는 실제 파일·함수명을 인용해 코드와 1:1로 대응시켰다. 향후 `/moai run SPEC-ONTIME-001`을 돌리면 순수 신규 구현보다는 **검증(라이브 재확인) + 리스크 항목 해소**가 작업의 대부분을 차지할 것으로 예상한다(이 SPEC의 `plan.md §2 남은 리스크`(M10/M11), 그리고 `plan.md §1` M6 행 참고).

## 1. 배경

사업계획서상 다섯 서비스(be on-time/full/healthy/rich/fun sir) 중 be on-time sir가 **다른 4개 서비스 전부와 연결되는 허브**다(위치+일정을 축으로 운동·식사·지출·여가를 추천). 핵심 계산은 **출발 시각 = 도착 시각 − 이동시간 − 버퍼**이며, 이 값으로 로컬 알림을 예약한다. be full sir(식사/맛집, Phase 1 진행 중)가 이미 이 서비스의 `Store.addActivityWithTravel`을 재사용하고 있어, be on-time sir의 as-built 계약을 명문화해두는 것이 다음 서비스들의 회귀 방지에도 필요하다.

## 2. 요구사항 (GEARS)

> REQ 번호는 **§2.N 대역식**이다 — §2.1→001번대, §2.2→010번대, …, §2.9→080번대로 각 하위 절에 하나의 대역을 배정했고, 연속 번호가 아니다. 대역 사이의 빈 번호는 REQ 누락이 아니라 그 절에 추가 REQ가 붙을 자리다. acceptance.md와 plan.md의 REQ 범위 표기가 이 대역에 의존하므로 재번호하지 않는다.

### 2.1 일정 등록 및 이동시간 역산 (핵심 계산)

- **REQ-001 (Ubiquitous)**: The `Store` shall own the departure-time computation `arrival time − travel time − buffer` and shall schedule the departure notification from the resulting value. 이 산식은 `Shared/Store.swift`의 세 경로 — `applyEstimate(to:)`(`:795`), `adjustBuffer(_:deltaMinutes:)`(`:943`), `applyCachedArrivalEstimate(to:travelSeconds:source:)`(`:972`) — 에 `arrivalDate.addingTimeInterval(-travel - buffer*60)` 형태로 각각 들어 있다(as-built: 한 함수로 모여 있지 않다). **주의**: 이 REQ는 렌더링 기하와 무관하다. 렌더 위치·높이와 히트테스트의 단일 출처는 REQ-053의 `ContentView.span(for:)`이며(CLAUDE.md 계약 5가 말하는 단일 출처도 이쪽이다), 두 "단일 출처" 주장은 서로 다른 계산을 가리키므로 섞지 않는다.
- **REQ-002 (Event-driven)**: **When** a user manually creates a schedule with a destination via `AddEventView`, the component shall support both arrival-anchored and departure-anchored input (`ScheduleAnchor`, auto-inferred from which date field is filled first), resolve travel time via `DirectionsService`/`ODsay`, and schedule a departure-time local notification through `NotificationManager`.
- **REQ-003 (Event-detected)**: **When** travel-time calculation fails, the `ScheduledEvent` shall render as a fixed-height "실패" block (`Self.failedBlockHeight`) rather than an infinite-loading or crashing state; **when** a new schedule's time window overlaps an existing one, `AddEventView` shall present a non-blocking informational overlap banner rather than preventing registration.

### 2.2 즐겨찾기 장소

- **REQ-010 (Ubiquitous)**: The `Store` shall persist a `favorites: [FavoritePlace]` array (`Shared/Store.swift:12`의 `@Published var favorites`; 타입은 `Shared/Models.swift:118`의 `struct FavoritePlace`), each entry pairing a user-chosen label with a `Place`. 이 배열을 사용자가 편집하는 화면은 `Shared/FavoritesView.swift`다 — 배열의 소유처(Store)와 편집 화면(FavoritesView)은 서로 다른 파일이다.
- **REQ-011 (Where capability gate)**: **Where** favorites exist, `AddEventView`'s origin/destination pickers shall render favorite-place chips (`Shared/AddEventView.swift:389`의 `private func favoriteChips(onSelect:)`) for one-tap selection, and the `AIAssistant` shall treat a favorite labeled "집" as the default home reference when resolving an ambiguous origin/destination in natural-language requests (`Shared/AIAssistant.swift:1786`).

### 2.3 복합 반복 일정 (출퇴근 왕복 + 점심 이동)

- **REQ-020 (Event-driven)**: **When** a user (via manual UI or AI chat) requests a recurring weekday commute schedule, the `Store` shall generate round-trip travel legs (outbound + return) sharing one `recurrenceId` up to the `maxRecurrenceWeeks` cap (`Shared/Store.swift:35`, 현재 **26주**) via `Store.addRecurringEvents` (`Shared/Store.swift:565`, 한도 적용 `:577`) — 활동 블록 쪽 대응 경로는 `Store.addRecurringActivities` (`:185`, 한도 적용 `:194`) — accepting independent `outboundMode`/`returnMode` `TransportMode` values so going and returning transport can differ. 한도 값은 상수가 SSOT이며, 이 문서는 상수를 인용할 뿐 숫자를 복제하지 않는다.
- **REQ-021 (Where capability gate)**: **Where** `lunch_place_query` is given, non-empty, **and** the place search resolves it, the `Store` shall generate an additional round-trip travel leg ("점심 이동" + "점심 후 복귀") under the same `recurrenceId`; **where** `lunch_place_query` is absent/empty **or** the place search fails, no travel leg is generated and only the lunch activity block is created (`Shared/AIAssistant.swift:1029-1063` — 이동 구간 분기는 `:1037-1054`, 점심 활동 블록 생성은 `:1056` `store.addRecurringActivities`로 분기 밖에 있어 항상 실행된다). 장소 동일성 비교는 이 경로에 없다 — 점심 장소로 주 활동과 **같은 장소**를 지정해도 이동 구간은 생성된다. (동일 장소 가드 `AIAssistant.isSamePlace`(`:1748`)는 `create_schedule`의 출발지=목적지 방어(`:805`)에서만 쓰인다.)
- **REQ-022 (Event-driven)**: **When** a user deletes or edits one occurrence of a recurring series (activity or event block), `ContentView`/`ActivityDetailView`/`EventDetailView` shall present a `confirmationDialog` offering "전체 반복 일정 이동(또는 삭제)" vs "이 일정만" as distinct, explicit choices — never applying a whole-series action silently.

### 2.4 카카오맵 경로선 렌더링

- **REQ-030 (Event-driven)**: **When** a schedule with a resolved route is displayed in its detail view, `KakaoMapView`/`RouteMapView` shall render the route polyline via `LocalMapServer`.

### 2.5 구글 캘린더 양방향 동기화

- **REQ-040 (Ubiquitous)**: The `GoogleCalendarService` shall propagate local schedule/activity create and delete operations to the linked Google Calendar (`createEvent(for:)` for `ScheduledEvent`/`ActivityBlock`, `deleteEvent(id:)`), and the `Store` shall route every deletion path through a single function, `removeFromCalendar(_:)`, which records a tombstone in `deleted_gcal_ids.json` (`deletedGoogleEventIds`) before attempting remote deletion.
- **REQ-041 (Event-detected)**: **When** `Store.syncWithGoogle()` finds a remote item absent locally, it shall check the tombstone set first; **when** the id is tombstoned, the item shall NOT be re-imported (prevents a previously-deleted schedule from resurrecting via sync).
- **REQ-042 (Event-driven)**: **When** `syncWithGoogle()` confirms a tombstoned id is genuinely absent from the remote calendar, the `Store` shall clear that id from `deletedGoogleEventIds` (cleanup happens only after remote-absence is confirmed, never immediately after a local delete); **when** `Store.reconcileActivities(remote:tombstones:)` runs, it shall additionally re-upload activities whose remote copy vanished (`Shared/Store.swift:1258-1266` — 원격에서 사라진 활동은 `:1217-1225`에서 `googleEventId`만 비워두고 여기서 다시 올린다. **무조건은 아니다** — `config.autoAddToCalendar`가 켜져 있고 그 활동이 `wantsCalendarSync`일 때만 올라간다), treat a remote item matching an existing activity's title and time within ±60 seconds as a duplicate import (`:1234-1236` — 제목 일치 **그리고** 시작·종료 양쪽이 각각 60초 이내), and delete remote besir-tagged items with no matching local activity (`:1250`).
- **REQ-043 (Ubiquitous)**: Every locally-created besir calendar event/activity shall be created with `reminders: {useDefault: false, overrides: []}`, and any lingering reminder override discovered on a besir-tagged remote item during reconciliation shall be cleared via `clearReminders(id:)`.

### 2.6 통합 스와이프 캘린더 UI

- **REQ-050 (Ubiquitous)**: `ContentView` shall present a single unified month/week/day calendar (no separate mode tabs), using `SwipePager` for finger-tracked left/right navigation between adjacent date/week/month units.
- **REQ-051 (Event-driven)**: **When** the user long-presses and drags a schedule or activity block in the day timetable, `RescheduleOverlay` — `ContentView` 안에 정의된 `private struct RescheduleOverlay: UIViewRepresentable` (`Shared/ContentView.swift:856`, 별도 파일이 아니다) — shall move it in 5-minute increments; **when** the drag targets one occurrence of a recurring group, the confirmation dialog from REQ-022 shall be presented before the move commits.
- **REQ-052 (Event-driven)**: **When** an activity block linked to a travel leg is rescheduled, moving the activity shall also move its linked travel leg; moving only the travel leg shall keep the activity's time fixed and adjust only the buffer.
- **REQ-053 (Ubiquitous)**: `ContentView.span(for:)` (`Shared/ContentView.swift:522`/`:530`) shall be the **single source** for a day-timetable block's vertical span (자정 기준 분 단위의 시작·길이), so rendering position/height and hit-testing never diverge — 자정을 넘는 블록도 그날 자정(1440분)까지만 그려 음수 오프셋이 생기지 않는다. 이 단일-출처 주장은 **렌더 기하에 한정**되며, 출발시각 산식(REQ-001, `Store`)과는 다른 계산이다. CLAUDE.md 계약 5의 "`ContentView.span(for:)`이 단일 출처" 문장이 가리키는 대상이 바로 이 REQ다.

### 2.7 AI 채팅 CRUD + 장기 기억

- **REQ-060 (Ubiquitous)**: The `AIAssistant` shall speak only the Gemini `generateContent` wire format, so that a backend swap requires zero changes to `AIAssistant.swift`, translation living entirely in `proxy/src/index.js`. 이 계약은 `Shared/AIAssistant.swift:9`에 주석으로 명시돼 있고, 형식은 `functionCall`(`:232`)·`functionResponse`(`:238`)·`inlineData`(`:283`)·`candidates`(`:357`)로 실제 사용된다. 계약의 실증: Gemini → Workers AI → OpenAI 세 차례 백엔드를 갈아끼우는 동안 앱 코드는 바뀌지 않았다. **다만 현재 백엔드는 OpenAI 하나뿐이다** — Workers AI 경로는 2026-09-13(커밋 `860e121`) 삭제됐으므로 "두 백엔드 사이 전환"은 더 이상 존재하는 경로가 아니며 폴백도 없다. 백엔드 현황의 SSOT는 `CLAUDE.md`의 "AI 백엔드" 절이다.
- **REQ-061 (Ubiquitous)**: The `AIAssistant` tool loop shall expose exactly these 11 tools: `create_schedule`, `create_activity`, `create_recurring_schedule`, `update_recurring_schedule`, `update_schedule`, `list_schedules`, `recommend_meal`, `check_travel_time`, `remember_fact`, `forget_fact`, `delete_schedule`.
- **REQ-062 (Event-driven)**: **When** `create_schedule` reports a conflict, the assistant shall ask the user to choose `on_conflict: "ignore"` or `"late_arrival"` and re-invoke the same tool with that argument added; **when** `delete_schedule` reports more than 5 non-recurring matches, the assistant shall re-confirm and re-invoke with `confirm_many: true`; **when** `update_recurring_schedule` receives a `buffer_minutes`/`notify_lead_minutes` of `0`, the tool shall return a re-ask that first confirms with the user and offers the series' current value as the restore escape (`zeroUpdateIssue`, `Shared/AIAssistant.swift:1249-1282`), and `confirm_zero: true` shall be honoured **only** for the exact `(recurrenceId, buffer, notify)` combination the app actually asked about (`:1254-1255` — 첫 호출에 모델이 스스로 붙인 확인은 인정하지 않는다); **when** the series' current value is already `0`, the re-ask shall offer no restore escape at all (`:1266-1278` — "그대로 둬라"와 "0으로 바꿔라"가 같은 와이어 값이라, 탈출구를 주면 되묻기만 반복하다 툴 루프 상한에서 끝난다); **when** `update_recurring_schedule` receives a `series_number` matching no listed recurring group, the tool shall direct the model to re-call `list_schedules` and retry with the refreshed number (`:1187-1191`); **when** the update applies, the reply shall name its target by prefixing the series' first-occurrence title — `'출근' 반복 일정 35건을 수정했어요` (`:1229-1232` — 번호를 빼먹은 재호출이 `lastRecurrenceId` 폴백으로 엉뚱한 그룹을 고쳐도 예전 문구에는 대상이 없어 오조준이 사후에 보이지 않았다) — in all cases never re-asking the same question in a loop. 반복 그룹 지정: `list_schedules`는 반복 그룹에 `recurrenceId` 단위로 번호를 매겨 `[반복 n]`/`(활동/반복 n)`로 표시한다(`seriesTag`, `:1438-1444`; 인자 선언 `:637`, 안내 문장 `:1489`) — 한 출퇴근의 등원·복귀·점심 줄이 모두 같은 번호를 달며 번호가 고르는 것은 **그룹 전체**다(일부 구간만 고르는 길은 없다). **단, 번호는 아직 이동 일정(events)이 남아 있는 그룹에만 붙는다**(`updatableRids`, `:1449`) — `updateRecurringSeries`는 events만 갱신하는데 개별 삭제가 짝 활동 블록까지 지우지 않아 이동 구간만 사라진 그룹이 생길 수 있고, 그런 그룹은 번호 없이 "이동 일정이 모두 지워져 시간표 블록만 남았어요(수단·여유·알림을 고칠 게 없어요)" 안내로 표시된다(`:1471-1474`). 한 번 붙은 번호는 대화가 끝날 때까지 그 그룹 전용이고 목록을 다시 그릴 때마다 재발급되지 않는다(`:47-48`, 대화 리셋 시 초기화 `:206-207` — 재발급하면 지워진 그룹의 옛 번호가 엉뚱한 그룹을 가리킨다). `series_number: 0`은 "안 골랐다"로 읽혀 이 대화에서 만든 그룹(`lastRecurrenceId`)으로 폴백한다(`:1194-1196`) — 이 폴백이 번호 도입 전에는 유일한 대상 결정 경로였고, 그래서 다른 대화에서 만든 그룹은 수정할 방법이 없었다. 번호로 지정된 호출의 되묻기 응답에는 `series_number`를 그대로 유지하라는 덧붙임이 붙는다(`:1209-1212` — 빼면 폴백 경로로 흘러 엉뚱한 그룹에 값을 덮어쓴다). `[n]` 안내 문장은 20줄 캡를 **통과한 줄**에 번호 줄이 남아 있을 때만 붙는다(`:1483-1485` — 단발 일정이 앞을 채워 반복 줄이 전부 잘리면 모델에게 인용할 `[n]`이 없는데 안내만 남는다).
- **REQ-063 (Ubiquitous)**: The `AIAssistant` shall persist conversation history to `ai_history.json` and long-term user-stated preferences to `ai_memory.json` via `remember_fact`/`forget_fact`, surviving app relaunch and reinstall; **when** a tool-call turn fails, it shall roll history back to its pre-turn state rather than persisting a broken turn that would repeat the same failure on every subsequent request.

### 2.8 Share Extension (공유 확장)

- **REQ-070 (Event-driven)**: **When** the user shares text or an image from another app (e.g. KakaoTalk) to besir, `ShareViewController` shall extract the text/image and enqueue it via `SharedInbox.enqueue(text:imageData:mimeType:)` into the App Group's `pendingShares.json`; **when** besir next enters the foreground (`scenePhase == .active`), `App.swift` shall drain the inbox (`SharedInbox.drain()`) and forward each item to `AIAssistant`, auto-opening the AI chat view.
- **REQ-071 (Event-detected)**: **When** schedule registration itself succeeds but a secondary confirmation-message API call fails, the app shall NOT display the generic failure message — a successful registration shall be shown as successful.

### 2.9 백그라운드 동기화 및 알림 한도 대응

- **REQ-080 (Ubiquitous)**: `BackgroundSync` — `Shared/App.swift:14`의 `enum BackgroundSync` (별도 파일이 아니다) — shall register a `BGAppRefreshTask` under identifier `com.iseongmin.besir.sync` (`App.swift:16`) at app init and re-schedule it on every background transition (`BGAppRefreshTaskRequest`, `App.swift:41`), and Keychain-stored Google OAuth tokens shall use `kSecAttrAccessibleAfterFirstUnlock` accessibility (`Shared/GoogleCalendarService.swift:380`) so background sync can read them **while the device is locked, provided the device has been unlocked at least once since boot**. (기본값 `kSecAttrAccessibleWhenUnlocked`이면 잠금 중 토큰을 못 읽어 동기화가 통째로 실패한다 — 코드 주석 `GoogleCalendarService.swift:377-379` 참고.)
- **REQ-081 (Ubiquitous)**: `Store.rescheduleNearestNotifications(limit: 60)` shall keep at most `limit` local notifications scheduled at any time, always the soonest-firing ones, to stay under iOS's 64-pending-notification ceiling; it shall re-run whenever a recurring series is created and whenever the app returns to the foreground.

## 3. Out of Scope

### Out of Scope — 미래 서비스 연동

- be full sir/healthy sir/rich sir/fun sir 자체 기능(식사 추천, 운동, 지출, 여가) — 각 서비스는 별도 SPEC(예: SPEC-HEALTHY-001)에서 다룬다. 이 SPEC은 be on-time sir가 그 서비스들에 제공하는 `Store` 배열·`AIAssistant` 툴 확장 지점까지만 다룬다.

### Out of Scope — AI 백엔드 전환 자체

- OpenAI `gpt-5.6-luna` 채택 경위, 프록시 변환 로직(`proxy/src/index.js`)의 세부 구현, 백엔드 모델 선택·비용 최적화는 이 SPEC이 아니라 `CLAUDE.md`/`plan.md` §1의 "AI 백엔드 OpenAI 전환" 항목을 SSOT로 한다. 이 SPEC은 앱 쪽 계약(REQ-060, Gemini 와이어 포맷 고정)만 다룬다.

### Out of Scope — 신규 기능 설계

- 이 문서는 as-built 베이스라인이므로 새 요구사항 설계·아키텍처 변경 제안을 담지 않는다. 추가 요청사항은 사용자 지시에 따라 이 SPEC에 REQ를 덧붙이는 방식(HISTORY에 버전 갱신 기록)으로 확장한다.

### Out of Scope — 실기기 전용 검증

- 실제 알림 수신 타이밍, 제스처 손맛, 캘린더 앱에서 보이는 실제 모습 등 빌드로 검증 불가능한 항목은 acceptance.md에서 ⬜(미확인)으로만 표시하고, 이 SPEC의 완료 조건에 포함하지 않는다(이 SPEC의 `plan.md §2 남은 리스크` M10/M11 참고).

### Out of Scope — 비밀값 관리 (CLAUDE.md 계약 2)

- 카카오·ODsay·OpenAI 키를 앱이 아니라 Cloudflare Worker 시크릿으로만 보관하는 규칙, 그리고 **새 키를 추가할 때 `redactSecrets()`의 목록에도 반드시 넣는 규칙**은 이 SPEC의 REQ로 다루지 않는다. SSOT는 `CLAUDE.md` 계약 2이며 구현 근거는 `proxy/src/index.js:136`의 `redactSecrets(text, env)`다. 이 SPEC은 be on-time sir의 앱 쪽 as-built 동작만 기술하고, 프록시의 비밀값 취급은 REQ 예산(Tier L 상한 25건, 현재 정확히 25건) 밖에 둔다.

### Out of Scope — 색 토큰과 다크 모드 (CLAUDE.md 계약 6)

- 색을 직접 쓰지 않고 전부 `Theme` 토큰을 거치는 규칙, 그리고 다크 모드를 기기 설정에 맡기고 `preferredColorScheme`을 강제하지 않는 규칙은 이 SPEC의 REQ로 다루지 않는다. SSOT는 `CLAUDE.md` 계약 6이며 구현 근거는 `Shared/Theme.swift:15`(주석)과 `enum Theme` 전체다. be on-time sir 화면에도 당연히 적용되지만, 앱 전역 규칙이라 특정 서비스 SPEC이 소유할 범위가 아니다.

### Out of Scope — 로고·앱아이콘 기하 상수 동기화 (CLAUDE.md 계약 5 후반)

- `BesirMark`(`Shared/Theme.swift:117`)와 `Tools/MakeAppIcon.swift`(경고 주석 `:9`)의 좌표·굵기 상수를 **양쪽 동시에** 고쳐야 한다는 규칙은 이 SPEC 범위 밖이다. 계약 5 중 이 SPEC이 담는 것은 `ContentView.span(for:)` 쪽 절반(REQ-053)뿐이다. SSOT는 `CLAUDE.md` 계약 5.

### Out of Scope — `Store` 단일 허브의 금지 불변식 (CLAUDE.md 계약 3)

- "이벤트버스·별도 영속화 레이어를 만들지 않는다"는 **금지** 불변식은 이 SPEC의 REQ로 다루지 않는다. 이 SPEC은 `Store`가 실제로 무엇을 소유하는지(REQ-010, REQ-040~043 등)만 기술하며, 앞으로 무엇을 만들면 안 되는지는 `CLAUDE.md` 계약 3이 SSOT다. 새 서비스 SPEC(예: SPEC-HEALTHY-001)이 이 불변식을 깨는 설계를 제안할 때 걸러야 할 곳도 이 문서가 아니라 계약 3이다.
