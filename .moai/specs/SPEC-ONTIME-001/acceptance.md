# SPEC-ONTIME-001 — acceptance.md (as-built)

각 AC는 spec.md의 REQ 그룹(§2.1~§2.9) 1개씩에 대응한다. ✅는 이미 코드로 만족된 것(파일 근거 인용), ⬜는 미확인(실기기 재검증 필요, plan.md §2 리스크 항목).

## AC 매트릭스

| AC | 대응 REQ | 상태 |
|---|---|---|
| AC-001 | REQ-001~003 | ✅ |
| AC-002 | REQ-010~011 | ✅ |
| AC-003 | REQ-020~022 | ✅ |
| AC-004 | REQ-030 | ✅ |
| AC-005 | REQ-040~043 | ✅ |
| AC-006 | REQ-050~053 | ✅ |
| AC-007 | REQ-060~063 | ✅ |
| AC-008 | REQ-070~071 | ✅ |
| AC-009 | REQ-080~081 | ✅ |
| AC-010 (리스크) | REQ-081 (plan.md §2 M10) | ⬜ |
| AC-011 (리스크) | REQ-001 / REQ-053 (plan.md §2 M11) | ⬜ |

## AC-001 — 일정 등록·이동시간 역산 ✅

- **Given** 사용자가 `AddEventView`에서 목적지가 있는 일정을 등록하려 하고
- **When** 도착시각 또는 출발시각 중 하나만 입력하면(`ScheduleAnchor` 자동 추론)
- **Then** `Store`가 도착시각 − 이동시간 − 버퍼로 출발시각을 계산해 출발 알림을 예약하고, 이동시간 계산이 실패하면 크래시 대신 고정 높이 "실패" 블록을 렌더링하며, 시간이 겹치면 등록을 막지 않고 배너만 띄운다. (출발시각 산식의 소유처는 `Store`이고, `ContentView.span(for:)`은 렌더 기하 전용이다 — AC-006/AC-011 참고.)
- 근거: `Shared/Store.swift`(`applyEstimate(to:)` `:795`, `adjustBuffer(_:deltaMinutes:)` `:943`, `applyCachedArrivalEstimate(to:travelSeconds:source:)` `:972` — 셋 다 `arrivalDate.addingTimeInterval(-travel - buffer*60)`), `Shared/ContentView.swift`(`Self.failedBlockHeight` `:518`), `Shared/AddEventView.swift`(겹침 배너), `Shared/NotificationManager.swift`

## AC-002 — 즐겨찾기 장소 ✅

- **Given** 사용자가 `FavoritesView`에 장소를 저장해 두었고
- **When** `AddEventView`에서 출발지/목적지를 고르거나 AI 채팅에서 장소명을 애매하게 말하면
- **Then** 즐겨찾기 칩이 원탭 선택으로 뜨고, "집"으로 라벨된 즐겨찾기가 AI의 기본 홈 참조로 쓰인다.
- 근거: `Shared/AddEventView.swift:389`(`private func favoriteChips(onSelect:)`), `Shared/Store.swift:12`(`@Published var favorites: [FavoritePlace]`), `Shared/Models.swift:118`(`struct FavoritePlace`), `Shared/AIAssistant.swift:1477`(즐겨찾기 "집" 폴백), `Shared/FavoritesView.swift`(즐겨찾기 편집 화면)

## AC-003 — 복합 반복 출퇴근 일정 ✅

- **Given** 사용자가 매주 평일 출퇴근 반복 일정을 요청하고(수동 또는 AI 채팅)
- **When** `Store.addRecurringEvents`(이동 구간)/`Store.addRecurringActivities`(활동 블록)가 실행되면 — AI 채팅 경로라면 툴 `create_recurring_schedule` → 핸들러 `AIAssistant.executeCreateRecurringSchedule`을 거쳐 같은 `Store` 함수로 내려온다
- **Then** 출근+퇴근 왕복 이동이 하나의 `recurrenceId`로 `Store.maxRecurrenceWeeks` 한도(현재 **26주**)까지 생성되고, `lunch_place_query`가 지정되고 장소 검색이 성공하면 점심 왕복 이동이 추가되며(미지정이거나 검색 실패면 이동 구간 없이 점심 활동 블록만 생성 — **장소가 같은지는 비교하지 않는다**), 반복 중 하나를 수정/삭제하면 "전체" vs "이 일정만"을 명시적으로 묻는다.
- 근거: `Shared/Store.swift:35`(`static let maxRecurrenceWeeks = 26`), `:565`(`addRecurringEvents`, 한도 적용 `:577`), `:185`(`addRecurringActivities`, 한도 적용 `:194`), `Shared/AIAssistant.swift:535`(툴 선언 `create_recurring_schedule`)·`:892`(`executeCreateRecurringSchedule`)·`:956-976`(점심 **이동 구간** 분기)·`:977`(점심 활동 블록은 분기 밖이라 항상 생성), `Shared/ContentView.swift`/`Shared/ActivityDetailView.swift`/`Shared/EventDetailView.swift`(`confirmationDialog`)

## AC-004 — 카카오맵 경로선 렌더링 ✅

- **Given** 경로가 해석된 일정의 상세 화면을 열고
- **When** 사용자가 상세 화면을 표시하면
- **Then** `KakaoMapView`/`RouteMapView`가 `LocalMapServer`를 통해 경로 폴리라인을 렌더링한다.
- 근거: `Shared/KakaoMapView.swift` / `Shared/RouteMapView.swift`, `Shared/LocalMapServer.swift`

## AC-005 — 구글 캘린더 양방향 동기화 ✅

- **Given** 로컬에서 일정/활동을 생성·삭제하고
- **When** `syncWithGoogle()`이 실행되면
- **Then** 로컬 변경이 구글 캘린더로 전파되고(reminders 비활성 고정), 삭제는 tombstone(`deleted_gcal_ids.json`)을 거쳐 리마인더가 재유입되지 않으며, 원격에서 사라진 tombstone id는 원격-부재가 확인된 뒤에만 tombstone 목록에서 제거된다.
- 근거: `Shared/GoogleCalendarService.swift`(`createEvent(for:)`, `deleteEvent(id:)`, `clearReminders(id:)`), `Shared/Store.swift`(`removeFromCalendar(_:)`, `syncWithGoogle()`, `reconcileActivities(remote:tombstones:)`, `deletedGoogleEventIds`)

## AC-006 — 통합 스와이프 캘린더 UI ✅

- **Given** 사용자가 `ContentView`에서 월/주/일 뷰를 오가며
- **When** 좌우로 스와이프하거나 블록을 꾹 눌러 드래그하면
- **Then** 별도 탭 전환 없이 `SwipePager`로 인접 날짜/주/월로 이동하고, `RescheduleOverlay`가 5분 단위로 블록을 재조정하며(반복 일정이면 AC-003의 확인 다이얼로그가 뜸), 활동-이동 블록이 연동 이동하고, 자정을 넘는 블록도 렌더/히트테스트가 어긋나지 않는다.
- 근거: `Shared/ContentView.swift` — `SwipePager`(`:770`), `span(for:)`(`:522`/`:530`), `private struct RescheduleOverlay: UIViewRepresentable`(`:856`, 별도 파일이 아니라 `ContentView.swift` 안에 있다), 5분 단위 스냅(`:453`)

## AC-007 — AI 채팅 CRUD + 장기 기억 ✅

- **Given** 사용자가 AI 채팅으로 일정 CRUD·식사 추천·이동시간 확인·기억 저장/삭제를 요청하고
- **When** `AIAssistant`가 Gemini `generateContent` 와이어 포맷으로 11개 툴 중 하나를 호출하면
- **Then** 충돌 시 `on_conflict` 재질의, 5건 초과 삭제 시 `confirm_many` 재확인을 반복 질문 없이 처리하고, 대화 이력·장기 기억이 재설치 후에도 남으며, 툴 호출 실패 시 이력이 실패 이전 상태로 롤백된다.
- 근거: `Shared/AIAssistant.swift`(11개 툴 선언, `ai_history.json`, `ai_memory.json`), `proxy/src/index.js`(와이어 포맷 변환)

## AC-008 — Share Extension ✅

- **Given** 사용자가 카카오톡 등 다른 앱에서 텍스트/이미지를 besir로 공유하고
- **When** 앱이 다음 포그라운드 진입 시 `SharedInbox.drain()`을 실행하면
- **Then** 공유 내용이 AI 채팅으로 전달되어 채팅 화면이 자동으로 열리고, 등록 자체는 성공했는데 확인 메시지 API만 실패한 경우에는 실패로 오표시되지 않는다.
- 근거: `ShareExtension/ShareViewController.swift:51`(`SharedInbox.enqueue(text:imageData:mimeType:)` 호출), `Shared/SharedInbox.swift:20`(`enqueue`)·`:28`(`drain`)·`:17`(`pendingShares.json`), `Shared/App.swift`(포그라운드 진입 시 drain), `Shared/AIAssistant.swift:223`(`isPresented = true` — 채팅 화면 자동 오픈)

## AC-009 — 백그라운드 동기화·알림 한도 ✅

- **Given** 앱이 백그라운드로 전환되거나 반복 일정이 생성되고
- **When** `BGAppRefreshTask`가 실행되거나 `rescheduleNearestNotifications`가 호출되면
- **Then** 부팅 후 한 번이라도 잠금 해제했다면 그 뒤로는 잠금 상태에서도 Keychain의 구글 OAuth 토큰을 읽어 동기화를 수행하고, 항상 가장 임박한 최대 60건만 로컬 알림으로 유지해 iOS 64건 한도를 넘지 않는다.
- 근거: `Shared/App.swift:14`(`enum BackgroundSync` — 별도 파일이 아니다)·`:16`(`taskIdentifier = "com.iseongmin.besir.sync"`)·`:41`(`BGAppRefreshTaskRequest`), `Shared/GoogleCalendarService.swift:380`(`Keychain`의 `accessibility = kSecAttrAccessibleAfterFirstUnlock`, 의미는 주석 `:377-379`), `Shared/Store.swift:998`(`rescheduleNearestNotifications(limit: Int = 60)`)

## AC-010 — 알림 예약 갱신 회귀 확인 ⬜ (리스크, 미확인)

- **Given** 최근 2차 코드 점검에서 `rescheduleNearestNotifications`가 기존 예약을 전부 지웠다 새로 까는 방식으로 수정되었고
- **When** 반복 일정을 새로 생성하거나 앱이 백그라운드↔포그라운드를 반복 전환하면
- **Then** 알림이 유실 없이 정상적으로 재예약되어야 한다 — **아직 실기기 라이브 재확인 전**(빌드·설치까지만 완료).
- 완료 조건: 실기기에서 반복 전환 3회 이상 + 반복 일정 생성 후 알림이 실제로 수신되는지 확인.

## AC-011 — 렌더/히트테스트 통합 회귀 확인 ⬜ (리스크, 미확인)

- **Given** `ContentView.span(for:)`로 렌더링과 히트테스트가 단일 함수로 통합되었고
- **When** 자정을 넘는 블록이나 겹친 블록을 탭·드래그하면
- **Then** 탭한 블록의 상세정보가 정확히 뜨고 드래그 재조정도 렌더링 위치와 어긋나지 않아야 한다 — **아직 실기기 라이브 재확인 전**.
- 완료 조건: 실기기에서 자정 걸친 일정 탭/드래그 + 겹친 블록 탭 시 올바른 상세정보 확인.

## Definition of Done (이 SPEC 기준)

- AC-001~009: 이미 충족(코드 근거로 확인됨) — 이번 라운드에서는 추가 작업 없음.
- AC-010, AC-011: 다음에 실기기를 만질 때 확인 필요. 확인 전까지 이 SPEC은 `status: draft`(spec.md 참고)로 유지하고, 확인되면 `in-progress`/`completed`로 전환할 근거가 된다.
- 새 요구사항이 추가되면 spec.md에 새 REQ를 추가하고, 이 문서에도 대응 AC를 추가한다(기존 AC 번호는 변경하지 않음).
