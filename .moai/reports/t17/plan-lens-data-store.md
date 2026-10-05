# t17 plan 렌즈 1 — 데이터 모델 · Store 연계 (읽기 전용 조사)

기준 트리: `b2c3987`(master, 워크트리 `t17` 시작점). 조사는 읽기 전용 Explore 에이전트가 했고, 이 문서는 그 보고를 옮긴 것이다.
**`[재측]` 표지가 붙은 줄은 오케스트레이터가 이 트리에서 명령으로 다시 재서 맞다고 확인한 것**이고, 표지가 없는 줄은 렌즈의 코드 읽기 그대로다(가설로 취급).
표지가 붙은 재측 명령: `sed -n`으로 해당 범위 열람, `grep -rn linkedActivityId Shared/ ShareExtension/ Tools/ proxy/ | wc -l`(= 18).

## 1. 한 줄 요약

- 연결은 **한 방향 포인터**다. `ScheduledEvent.linkedActivityId`(`Shared/Models.swift:190`)가 이동 구간에서 활동을 가리킨다. `ActivityBlock`(`:498-513`)에는 구간을 가리키는 필드가 없다 — 구간은 `events`를 훑어 `linkedActivityId == activity.id`로 찾는다(`Store.swift:374`, `:1120`). `[재측]`
- **구간의 역할(가는 편/오는 편)은 저장되지 않는다.** `anchor`(`.arrival` = 가는 편, `.departure` = 오는 편, `nil` = arrival로 취급)가 유일한 판별이다. 제목 접미 " (복귀)"는 이름 관례일 뿐이다(`Store.swift:222`).
- **연결을 거는 길은 하나다**: `addActivityWithTravel`(`Store.swift:189-230`)이 `addEvent(linkedActivityId:)`(`:581`, `:591`)를 호출한다(`:217` 가는 편, `:225` 오는 편). 반복 경로가 만드는 구간에는 없다. `[재측]`(대입은 `:591` 한 곳, 호출 인자는 `:217`·`:225`)
- **시간을 고쳐도 연결 필드는 산다.** `updateEvent`(`:945-992`)는 저장된 레코드 통째 복사본(`:958`)에서 시작해 `linkedActivityId`를 대입하지 않는다. `[재측]` 끊기는 건 **결합**이다: 활동이 그 수정을 따라오지 않고, `anchor`가 뒤집힐 수 있고, 출발지·도착지가 활동 장소와 대조되지 않는다.
- **오는 편을 나중에 만드는 데 새 Store 함수는 필요 없다** — `addEvent`가 이미 `linkedActivityId`·`anchor: .departure`를 받는다. 다만 UI도 AI 도구도 이 호출을 하지 않는다(찾은 명령: `grep -rn "linkedActivityId" Shared ShareExtension Tools`가 준 대입 자리는 `:591` 하나).
- **삭제는 비대칭이다.** 낱개 `deleteActivity`는 구간을 같이 지우고(`:371-384`), 일괄 `deleteActivities`(`:1303-1313`, AI 경로)는 지우지 않는다. `deleteEvent`는 활동에 손대지 않는다. `[재측]`
- **줄어듦 연동(요구 4)은 구현돼 있지 않다.** 활동 이동은 구간을 평행이동시키고, 구간 드래그·수정은 활동을 건드리지 않으며, "줄이는" 논리는 어디에도 없다.

## 2. 모델 (`Shared/Models.swift`)

`ScheduledEvent`(`:154-200`, Codable, 합성 디코더 — `init(from`·`CodingKeys`·`func encode` 없음):

| 필드 | 줄 | 뜻 |
|---|---|---|
| `title` | 156 | 가는 편 = 활동 제목, 오는 편 = "<제목> (복귀)" |
| `origin: Place?` | 158 | 옛 데이터라 옵셔널 |
| `arrivalDate` | 161 | arrival 기준이면 고정값, departure 기준이면 출발+이동+버퍼로 재계산(`Store.swift:1033`, `:1205`) |
| `bufferMinutes` | 165 | departure 기준이면 0 강제(`Store.swift:589`, `:964`) |
| `notifyEnabled: Bool?` | 169 | nil = 켜짐(`wantsNotification` `:193`) |
| `syncToCalendar: Bool?` | 171 | nil = 참(`wantsCalendarSync` `:195`) |
| `departureDate` / `travelSeconds` | 173 / 175 | 스냅샷. nil = 이동시간 계산 실패 |
| `notificationId` / `googleEventId` | 177 / 179 | `googleEventId`가 "올렸다"의 단일 출처 |
| `recurrenceId` | 185 | 반복 그룹 |
| `linkedActivityId: UUID?` | 190 | 구간 → 활동 포인터. 주석(`:186-189`)이 "옛 반복 구간은 nil이고 `Store.linkedLegs`가 추정한다"고 적는다 |
| `anchor: ScheduleAnchor?` | 199 | nil = arrival |

`ActivityBlock`(`:498-513`): `id, title, location, startDate, endDate, recurrenceId, googleEventId, calendarUpload, syncToCalendar` — **구간을 가리키는 필드 없음.**

**저장·마이그레이션 위험.** 저장은 `events.json`(`Store.swift:1487-1492`, 읽기 `:1494-1498`)·`activities.json`(`:386-391`, `:393-397`).
- **옵셔널 필드 추가는 안전**하다(옛 JSON에서 nil). `Models.swift:181-183` 주석이 같은 말을 한다.
- **비옵셔널 필드는 기본값이 있어도 위험**하다 — 합성 디코더가 `keyNotFound`를 던지고, `load()`·`loadActivities()`는 `guard let … try? decode … else { return }`(`:1495-1496`, `:394-395`)라 **배열이 조용히 빈 채로 남고 다음 `save()`가 파일을 `[]`로 덮어쓴다.** 일정 전체의 조용한 영구 손실이다.
- `ScheduleAnchor`에 케이스를 더하면 `switch event.anchor ?? .arrival` 자리(`Store.swift:747`, `:1154`, `:1259`)를 모두 고쳐야 하고 다운그레이드가 깨진다.

**구글 캘린더 왕복은 연결을 싣지 않는다.** `eventBody(for:)`(`GoogleCalendarService.swift:169-200`)가 쓰는 키는 `besir, mode, buffer, notify, title, arrival, dest*, origin*`뿐이다 — `linkedActivityId`·`anchor`·`recurrenceId`·`notifyEnabled`·`syncToCalendar`가 없다. `[재측]` `parse`(`:202-225`)는 그 없이 이벤트를 재구성하고, `syncWithGoogle`이 가져온 이벤트에 `applyEstimate`를 걸어(`Store.swift:1400`) `anchor = .arrival`로 굳힌다(`:996`). 다른 기기에서 가져온 구간은 연결이 없고 오는 편도 도착 기준이 된다.

## 3. Store 함수

- **`addActivityWithTravel`(`:189-230`)**: 활동을 먼저 추가·저장(`:201-205`). `location == nil`이면 `(activity.id, 0)`으로 돌아와 `travelFrom`·`returnTo`가 조용히 무시된다(`:211`). 가는 편 = `addEvent(… arrivalDate: startDate, anchor: .arrival, linkedActivityId:, buffer:)`(`:213-220`), 오는 편 = `addEvent(title: "<제목> (복귀)", origin: place, destination: to, arrivalDate: endDate, anchor: .departure, bufferMinutes: 0, linkedActivityId:)`(`:221-228`; departure 기준이면 `arrivalDate` 인자는 사실상 출발 시각 `:599`, `:601`). 반환 `made`는 시도한 수이지 이동시간 계산에 성공한 수가 아니다(`:219`, `:227`). **`await addEvent`가 두 번 이어지고 그 사이 활동 존재를 다시 보지 않는다**(`:214`, `:222`) — 첫 await 동안 사용자가 활동을 지우면 둘째 구간이 매달린 `linkedActivityId`로 만들어진다(추론).
- **`updateActivity`(`:276-293`)**: 레코드를 바꾸고 구글 재등록. 구간에 손대지 않는다. **바깥 호출자 0곳**(`modifyActivity`가 `:323`에서만 부른다) — 죽은 코드 신호이나 고치기 전에 확인 필요.
- **`modifyActivity`(`:301-330`)**: 시작이 다르면 `moveActivity(current, byMinutes:, wholeSeries: false)`(`:310-315`)로 활동+양쪽 구간 평행이동. 그다음 제목·장소·끝(`:318-323`) 후 `updateActivity`. 끝이 달라졌으면 `realignReturnLeg`(`:326-328`) — `events.first { linkedActivityId == id && anchor == .departure }`만 `shiftEvent`(`:333-340`), 없으면 조용히 돌아온다. **`newPlace`가 `nil`이면 "그대로 둠"이다**(`:321` `if let newPlace, …`) — 상세 화면의 "장소 없음" 칩은 장소를 지우지 못한다. `[재측]` **모양이 나쁜 가장자리**: `:322`는 `newEnd <= startDate`를 활동에서 거절하는데 `:326`은 그래도 오는 편을 `newEnd`에 재정렬한다 — 잘못된 끝 시각이 오는 편을 활동 끝에서 조용히 떼어낸다. 카드 UI는 막지만(`ActivityDetailView.swift:223-229`) AI 경로(`AIAssistant.swift:2816-2822`)는 닿는다. `[재측]` 부분(코드 열람) — 제목 변경이 구간 제목을 바꾸지 않고 장소 변경이 구간 출발지·도착지를 바꾸지 않는다.
- **`deleteActivity`(`:371-384`)**: 활동 제거 → 저장 → `linkedActivityId == activity.id`인 구간 제거(알림 취소·식사 정리·구글 gid 삭제). 주석(`:368-370`): 반복 일정이 만든 구간은 명시적 연결이 없어 건드리지 않고 "반복 전체 삭제로 처리"한다. `[재측]` **일괄 `deleteActivities`(`:1303-1313`)는 연쇄가 없다** — AI 경로(`AIAssistant.swift:2909`)에서 구간이 매달린 채 남는다. AI는 제목이 같은 구간만 지우므로(`:2903-2909`) `modifyActivity`로 활동 제목이 바뀐 뒤에는 구간이 고아가 된다. `[재측]`
- **`addEvent`(`:572-610`)**: `linkedActivityId`를 대입(`:591`), 추정 경로는 `(anchor, travelSecondsHint)`로 갈림(`:595-602`), 정렬·저장(`:603-605`), 구글 업로드 큐(`:606-608`). `rescheduleNearestNotifications`는 부르지 않는다(반복 경로만 `:693`) — 낱개 추가·수정은 알림 64건 창을 다음 포어그라운드 청소까지 넘길 수 있다(`App.swift:26`, `:104`).
- **`updateEvent`(`:945-992`)**: 위 §1. 추정 재계산 뒤 **await 전 스냅샷을 되쓴다**(`:979-980`) — 그 사이 다른 경로가 바꾼 필드(드래그의 `shiftEvent`, 업로드가 채운 gid)는 사라진다. 구글 gid를 메모리에서만 비우고 `save()`를 부르지 않는다(`:988`; 저장은 `enqueueCalendarUpload` 경로에서만). 이동시간 계산이 실패하면 멀쩡하던 `departureDate`·`travelSeconds`를 지우고 오류를 안 보인다(`applyEstimate` `:998-1000`). `[재측]`(열람) 나머지는 렌즈의 추론.
- **`moveActivity`(`:1065-1086`)**: `linkedLegs(for:)`의 (도착형, 출발형)을 `shiftEvent`로 옮기고 활동을 평행이동. **구간은 평행이동될 뿐 크기가 바뀌지 않으며, 캘린더 재업로드가 전혀 없다**(`shiftEvent`·`adjustBuffer`·`moveActivity` 모두 `removeFromCalendar`·`enqueueCalendarUpload` 없음) — 끌어서 옮기면 구글 캘린더가 옛 시각으로 남는다(기존 결함, 이 카드의 원인은 아님).
- **`linkedLegs(for:)`(`:1118-1131`, `private`)**: 명시적 연결이 있으면 그것(도착형 = 첫 arrival, 출발형 = 첫 departure — 같은 역할이 둘이면 뒤엣것은 안 움직인다). 없으면 `recurrenceId`+같은 날+장소 이름으로 추정(옛 반복 데이터). 추정은 이름 대조이고 날짜는 `arrivalDate` 기준이라 자정을 넘는 오는 편을 놓친다. `[재측]`
- **`adjustTravelLeg`(`:1091-1114`)**: 활동에 안 닿는다. `.departure` 구간은 `shiftEvent`(통째 이동 — 활동 끝과 사이가 벌어진다), `.arrival` 구간은 `adjustBuffer`(도착 고정, 버퍼 0…180 클램프 `:1158`) — 지금 있는 "줄임"에 가장 가까운 동작이다. `[재측]`
- **`conflicts`(`:514-533`)**: 같은 `recurrenceId`만 제외한다. 활동과 연결된 구간은 반복 그룹이 아니라서 **자기 활동과 겹친 것으로 보고될 수 있다**(맞닿음은 엄격 부등호라 충돌이 아니다). `[재측]`
- **`deleteEvent`/`deleteEvents`(`:1273-1300`)**: 이벤트만 지운다(알림·식사·구글 포함). 활동·짝 구간에 손대지 않는다. `[재측]`
- **알림 창**: `rescheduleNearestNotifications(limit: 60)`(`:1217-1241`) — await 없이 동기.

## 4. 렌즈가 받은 구체 질문의 답

(a) `updateEvent`가 시간을 고치면 `linkedActivityId`는 산다(`:958`, 대입 없음). 실제로 깨지는 것: 활동이 안 따라옴 · `anchor` 뒤집힘(카드의 `arr:`/`dep:` 접두 `EditCard.swift:63-96` → `AddEventView.swift:708` → `linkedLegs`의 역할 판별) · 출발지·도착지·제목 자유 수정(제목이 바뀌면 AI의 제목 대조 삭제·수정이 놓친다) · 충돌이 자기 활동과 겹침으로 보고됨.
(b) 나중에 구간을 만드는 길: 없다. 재료는 있다 — `addEvent(title: "<제목> (복귀)", origin: activity.location, arrivalDate: activity.endDate, anchor: .departure, bufferMinutes: 0, linkedActivityId: activity.id)`가 `:221-227`을 재현한다. 지킬 것: 같은 역할 구간이 둘이면 `linkedLegs`·`realignReturnLeg`가 `.first`만 쓴다 · 활동 존재 재확인이 없다 · 폼 경로에는 50 m 같은 장소 가드가 없다(`isSamePlace`는 `AIAssistant.swift` 안 `private static`, 사용처 `:1348`, `:1779`, `:1968`, `:2192`).
(c) 삭제: 위 §3. 낱개 = 연쇄 있음, 일괄 = 없음, 구간 삭제 = 그것만. UI에서 구간 삭제는 `EventDetailView.swift:355-390` — "같은 제목 일정 모두 삭제"가 제목이 같은 모든 이벤트를 지운다(`:331-333`, `:373`).
(d) 반복: 반복 경로(`addRecurringEvents`·`addRecurringActivities`·AI `create_recurring_schedule`, `AIAssistant.swift:2199-2270`)는 `linkedActivityId`를 안 건다 — 공유하는 건 `recurrenceId`뿐. 명시적 연결과 `recurrenceId`+이름 추정은 **서로 겹치지 않는 두 메커니즘**이다. 회차 하나 수정은 형제를 안 건드린다. 드래그는 "이 회차만/전체"를 묻는다(`ContentView.swift:778-793`).
(e) AI 경로가 부르는 것: `create_activity` → `addActivityWithTravel`(`:2005`) · `create_schedule` → `addEvent`(연결 없음 `:1825`) · `update_schedule` → 활동은 `modifyActivity`(`:2821`), 구간은 `modifyEvent`(`:2839`, `anchor = newAnchor ?? current.anchor ?? .arrival` — `new_arrival_iso`가 오는 편을 arrival로 뒤집는다) · `delete_schedule` → `deleteEvents`+`deleteActivities`(`:2908`, `:2909`). `executeUpdateSchedule`은 둘 이상 맞으면 거절한다(`:2799-2806`) — 활동과 가는 편이 같은 제목·같은 날이라 구간 있는 활동은 사실상 항상 2건 이상이고, "묶인 이동 구간도 같이 옮겼어요"(`:2826`)는 거의 닿지 않는다(추론).

## 5. 호출자 (바뀌면 번지는 범위)

| 함수 | 호출자 |
|---|---|
| `addActivityWithTravel` | `FullSirView.swift:463` · `AddActivityView.swift:523` · `AIAssistant.swift:2005` |
| `addEvent` | `AddEventView.swift:737` · `AIAssistant.swift:1825` · `Store.swift:214`, `:222` |
| `updateEvent` | `AddEventView.swift:731` · `Store.swift:356`(`modifyEvent`) |
| `modifyEvent` | `AIAssistant.swift:2839` |
| `modifyActivity` | `ActivityDetailView.swift:322` · `AIAssistant.swift:2821` |
| `moveActivity` | `Store.swift:313` · `ContentView.swift:780`, `:783` |
| `adjustTravelLeg` | `ContentView.swift:788`, `:791` |
| `deleteActivity` | `ActivityDetailView.swift:334` |
| `deleteActivities` | `AIAssistant.swift:2909` · `Store.swift:1321`(테스트용 임시) |
| `deleteEvent` / `deleteEvents` | `EventDetailView.swift:373`, `:378`, `:385` / `AIAssistant.swift:2908` · `Store.swift:1320` |
| `deleteRecurringSeries` | `ActivityDetailView.swift:340` · `EventDetailView.swift:371` |
| `linkedLegs`(private) | `Store.swift:1075` 하나 |
| `realignReturnLeg`(private) | `Store.swift:327` 하나 |
| `store.conflicts` | `AddEventView.swift:692` · `AIAssistant.swift:1803`, `:2042`, `:2849` |

`linkedActivityId` 전체 사용처는 **18곳**(`Models` 1 · `Store` 9 · `AIAssistant` 3 · `ContentView` 1 · `AddActivityView` 1(주석) · `GuardDriver` 3, ShareExtension·proxy 0). 드라이버가 읽는 자리: `Tools/GuardDriver.swift:922`, `:955`, `:1437`(`:922-934`는 오는 편을 `title.contains("(복귀)")`·버퍼 0·수단으로 단언 — 제목 관례에 기댄다). `[재측]`

`AIAssistant.swift:2038`은 `store.events.filter { linkedActivityId != nil && departureDate != nil }.suffix(madeLegs)`로 방금 만든 구간이 아니라 **저장소의 마지막 N개 연결 구간**을 본다(활동 id는 `:2005`에 이미 있다). `[재측]`

## 6. 이 카드가 바꾸면 닿는 암묵 계약과 위험

1. 역할 = anchor이지 제목이 아니다(`GuardDriver.swift:922-934`가 제목 관례에도 기댄다). anchor가 nil이면 arrival(`Store.swift:1122`, `:1259`).
2. **활동당 역할별 구간 하나** — `linkedLegs`·`realignReturnLeg`가 `.first`를 쓴다.
3. 오는 편 버퍼 0 — `addEvent`(`:589`)·`updateEvent`(`:964`)가 강제하고 드라이버가 검사한다(`GuardDriver.swift:929-931`).
4. **활동이 이동의 주인이다** — `moveActivity`는 구간을 옮기고 그 반대는 없다.
5. `googleEventId`가 "올렸다"의 단일 출처 — `calendarUpload`에 세 번째 상태를 더하면 `enqueueCalendarUpload`(`:817-852`)·`pushToCalendar`(`:876-909`)·`reconcileActivities`(`:1462-1475`)를 함께 고친다.
6. Store가 단일 허브 — 출발 시각 산식이 이미 세 벌이다(`@MX:DEBT` `:1008-1011`).
7. **비옵셔널 필드 추가 금지**(§2). 옵셔널만.
8. 자정 넘김: 추정 경로는 `arrivalDate`의 날로 매칭해 넘어가는 오는 편을 놓친다(`:1128`); 명시적 경로는 날짜와 무관하다.
9. 이동시간 계산 실패: `applyEstimate`는 `departureDate`·`travelSeconds`를 nil로 둔다(`:1006`), `applyDepartureAnchoredEstimate`는 길이 0 구간을 남긴다(`:1031`) — 충돌 검사(`:529`)·새로고침(`:1252`)·알림(`:1224`)·`adjustBuffer`(`:1152`)가 건너뛰고, `addActivityWithTravel`은 그래도 만든 것으로 센다.
10. 과거 출발 알림 생략: `NotificationManager.swift:21`이 지난 시각에 nil을 돌려주고 구간은 `notificationId == nil`로 남는다.
11. 하나의 편집이 **두 레코드를 건드리게 되면** `updateEvent`의 옛 스냅샷 되쓰기와 저장 안 된 gid 비우기(위 §3)가 더 위험해진다.
12. `ContentView.swift:651`이 연결된 구간의 제목을 시간표에서 숨긴다 — 연결을 풀면 제목이 다시 나타난다.
13. 다중 await 생성(`addActivityWithTravel`형)은 트랜잭션이 없어 동시 삭제가 고아를 남긴다.

**찾지 못한 것 / 안 읽은 것**: Store 연계를 검사하는 테스트 대상은 `Tools/GuardDriver.swift` 밖에 없다. `CHECKLIST.md`·`STATUS.md`·`plan.md`는 이 렌즈가 읽지 않았다. 빌드·테스트를 돌리지 않았다.
