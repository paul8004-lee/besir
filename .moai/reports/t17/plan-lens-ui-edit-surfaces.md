# t17 plan 렌즈 2 — 편집 화면 · 생성 카드 문법 (읽기 전용 조사)

기준 트리: `b2c3987`. 읽기 전용 Explore 에이전트의 보고를 옮겼다. `[재측]`은 오케스트레이터가 이 트리에서 명령으로 다시 재서 맞다고 확인한 줄이다.
**렌즈 오류 정정 한 건**: 보고 머리말은 "`EditCardView(` 호출 5곳"이라 했으나 목록은 4곳이고, `grep -rn "EditCardView(" Shared/`가 4줄(`AIChatView:110`, `AddEventView:68`, `ActivityDetailView:64`, `AddActivityView:72`)을 낸다. `[재측]` 이 SPEC은 4로 적는다.

## 1. 머리 발견

1. `EditCard`·`EditCardView`·`EditCardChrome`·`EditCardActions`는 이미 편집 화면 셋과 AI 채팅이 함께 쓴다(호출 4곳). 카드 단위로 더 옮길 것은 없다. `[재측]`
2. **이동 구간의 문법(줄)은 공유돼 있지 않다.** `AddActivityView`의 뷰 로컬 상태와 private 함수에 있다. SPEC-UIKIT-003 REQ-011이 구간을 "줄 소속"으로 흡수했고(`.moai/specs/SPEC-UIKIT-003/spec.md:97`) 추출된 것은 없다.
3. **연결된 이동 구간과 활동을 잇는 UI 경로는 없다.** `linkedActivityId`를 읽는 UI는 `ContentView:651`(시간표 블록의 제목 숨김) 하나뿐이다. `AddEventView`·`EventDetailView` 안 활동 참조는 `grep -c "activities\|ActivityBlock\|activityId\|linkedActivityId"` = **0**·**0**이다. `[재측]`
4. **운영자의 두 삭제 규칙은 Store에 이미 있다**(명시적 연결 구간 한정): 활동 삭제는 연결 구간을 지우고(`Store.swift:371-384`), `deleteEvent`는 그 이벤트만 지운다(`:1273-1282`). `[재측]` 틈은 §8 (d)와 데이터 렌즈 §3.

## 2. `EventDetailView`(430줄) — 이동 구간 상세

- 보여주는 것(본문 `:52-94`): 머리(도착지 이름·주소·도착 시각 `:190-200`), 지도(`:57-62`, `:103-117`), 출발 카드(`:202-248` — 수단·분, 큰 출발 시각, 알람 상태 캡션), 환승 일정(`:250-319`), 구글 캘린더 버튼(`:121-157`), 읽기 전용 상세 줄(`:335-390` — 수단·버퍼·알림·"반복 일정" 배지).
- **여기서 시간을 고칠 수 없다.** 모든 값이 `Text`다. 편집 진입은 툴바 "편집"(`:86-90`)뿐이고 `.sheet { AddEventView(editing: event) }`(`:91-93`)를 연다. 즉 이동 구간의 시간 수정은 `AddEventView` 편집 모드로 간다.
- Store 호출: `pushToCalendar(eventID:)`(`:163`), `deleteRecurringSeries(rid)`(`:371`), `deleteEvent(e)`를 `sameTitleEvents`에 대해 루프(`:373`), `deleteEvent(event)`(`:378`, `:385`), `directions.*`(`:173`, `:180`, `:184`).
- 삭제 UI(`:355-364`): `recurrenceId != nil || sameTitleEvents.count > 1`이면 메뉴(`:367-382`), 아니면 확인 창(`:383-389`). **`sameTitleEvents`(`:331-333`)는 제목 문자열 동등**이며 `linkedActivityId`를 보지 않는다 — 연결된 가는 편은 활동과 같은 제목이라(`Store.swift:214`) "같은 제목 일정 모두 삭제"가 **다른 활동의 연결 구간까지 쓸어갈 수 있다**. 오는 편은 "<제목> (복귀)"라 비켜간다(`:222`).
- 삭제 버튼은 카드 밖에 둔 의도적 배치(`:337-338`, SPEC-UIKIT-004 AC-006 8·9행).
- 연결된 활동은 **표시도 이동도 없다.**
- 상태: `transitTask`(`:35`)는 취소-교체 경로 조회(t12 패턴), `transitTaskKey`(`:98-101`)로 재무장.

## 3. `ActivityDetailView`(444줄) — 활동 상세·편집

- `NavigationStack` 안 `EditCardView`(`:63-66`), `chrome: EditCardChrome(header: nil, confirmTitle: nil)`, 툴바 "닫기"·"저장"(`:89-96`, 저장은 `card?.isReady`일 때만).
- 줄 4개(`bootstrap()` `:141-162`, 전부 `chosen`으로 시드 — 편집 모드): `title`(`:152`) · `location_query`("장소 없음" 칩 `noPlaceMarker` `:45`, `:147-150`, `:164-168`) · `start_iso`(`:157`)·`end_iso`(`:159`, 둘 다 `anchored: false`).
- 시간 편집은 `chooseTimePlain`(`:221-246`): 끝은 시작보다 뒤여야 하고, 시작이 끝을 넘으면 `end.chosen`을 비워 `isReady`를 다시 잠근다.
- 저장(`:315-330`): `store.modifyActivity(id:newTitle:newStart:newEnd:newPlace:)` 후 `dismiss()`. 주석(`:320-321`) — `updateActivity` 대신 이것을 써서 묶인 구간이 같이 움직인다.
- 삭제: `store.deleteActivity(a)`(`:334`, 연결 구간 연쇄), `store.deleteRecurringSeries(rid)`(`:340`), 삭제 버튼 `:74-81`, 시리즈 메뉴는 `recurrenceId != nil`일 때만(`:97-101`).
- **연결 구간은 표시도 편집도 없고, 오는 편 추가 수단도 없다.** `choose()`의 문서 주석이 "이 카드에는 딸린 줄이 없어"(`:172`)라 적는다. 이 파일은 `store.events`를 읽지 않는다.
- **잠복 결함(코드 읽기, 미실행)**: "장소 없음" 칩이 `confirmedPlace(...) == nil`(`:328`)을 낳고, `Store.modifyActivity`가 nil `newPlace`를 "그대로 둠"으로 본다(`Store.swift:321`) — 장소가 있는 활동에서 "장소 없음"을 골라도 지워지지 않는다. `[재측]`(`:321`)
- 부가: "주변 맛집"(`:350-417`, `nearbyTask` 취소 패턴 `:421-443`).

## 4. `AddActivityView`(630줄) — 생성 카드 문법

- 표시: 머리 "새 활동"(`:96-103`), 스크롤 안 `EditCardView` 하나(`:71-74`), 바닥 취소/추가(`:496-512`). macOS 프레임 560×640(`:83`), `.task { bootstrap() }`(`:86`).
- 기본 줄(`bootstrap()` `:125-152`): `title`(`startsOpen` `:130`) · `location_query`(kind `.place`, "장소 없음" 칩, 안내 "장소를 정하면 이동도 함께 만들 수 있어요" `:134-135`) · `start_iso`·`end_iso`(둘 다 `anchored:false` `:138-141`) · `calendar_sync` 토글(`hasGoogleCalendar && autoAddToCalendar`일 때만 `:145-150`).
- **구간 줄이 서고 빠지는 자리는 전부 `choose(field:value:place:)`(`:169-267`)**이고 `fields.insert`/`removeAll`/`remove` 자리가 정확히 11곳이다: `:190`, `:198`, `:219`, `:227`, `:241`, `:248`, `:257`, `:261`, `:315`, `:318`, `:325`.
  - 실제 장소를 고르면(`:183-194`) `end_iso` 뒤에 토글 줄 둘: `outbound_enabled` "가는 이동 (활동 시작에 맞춰 도착)"·`return_enabled` "오는 이동 (활동 끝나면 출발)" — `legToggleRow`(`:330-334`), 칩 만들기/안 만들기, `"false"`로 시드.
  - "장소 없음"(`:195-203`)은 `rememberTravelValues`·`forgetPlaces` 후 구간·알림 키 9개를 전부 뺀다.
  - `outbound_enabled == "true"`(`:206-221`)는 `outboundRows`(`:336-351`)를 넣는다: `origin_query`(place)·`outbound_mode`(mode)·`buffer_minutes`("가는 편 도착 여유"). 중복 삽입 가드, 기억한 값 재시드(`:212-218`), `ensureNotifyRows`. `"false"`(`:222-230`)는 값을 기억하고 3줄을 빼며 오는 편도 꺼져 있으면 알림 줄도 뺀다.
  - `return_enabled`(`:232-251`)도 같은 모양 — `returnRows`(`:353-361`): `return_query`·`return_mode`.
  - `notify_enabled`(`:252-263`)가 `notify_lead_minutes`를 토글. 알림 줄은 `ensureNotifyRows`(`:310-319`)·`removeNotifyRows`(`:322-326`)·`notifyToggleRow`(`:363-367`)·`notifyLeadRow`(`:371-376`).
- **뷰 로컬 상태**: `@State` 18개, 파일 안 private 함수·변수 49개. `card`·`confirmedPlaces: [UUID: Place]`(`:23`)·`favoritePlaces`(`:27`)·`placeDebounce`(`:31`)·`saving`(`:32`), 기억값 9개(`rememberedOutboundOrigin/OriginPlace/Mode`·`rememberedBuffer`·`rememberedReturnTo/ToPlace/Mode`·`lastNotifyOn`·`lastNotifyLead` `:37-55`) + `calendarDefault`.
- **재사용 vs 로컬**:
  - 그대로 재사용: `EditCard`·`EditField`(`.toggle`·`.mode` 포함)·`EditCardView`·`EditCardActions`·`PlaceSearchDebouncer`.
  - **복사돼 있고 공유되지 않음**: `searchPlaces`·`finishPlaceSearch`·`setLookup`·`confirmedPlace`·`chosenIn`·`chooseTimePlain`·`submitCustom`·`choosePlace` — `AddActivityView:385-473` ↔ `ActivityDetailView:221-290` ↔ `AddEventView:360-440`(줄 단위 바이트 대조는 안 했다).
  - 구간 전용·추출 안 됨: 줄 빌더(`legToggleRow`·`outboundRows`·`returnRows`·`notifyToggleRow`·`notifyLeadRow`), 소속 논리(`choose` 케이스·`ensureNotifyRows`·`removeNotifyRows`), 기억값 관리(`rememberTravelValues`·`rememberOutboundOrigin`·`rememberReturnTo`·`reseed`·`forgetPlaces`).
  - **줄 키 어휘가 AI 카드와 다르다**: AI 카드는 `travel_from_query`·`return_to_query`(`AIAssistant.swift:567-568`, `:678`, `:704`), 생성 카드는 `outbound_enabled`·`origin_query`·`return_query`. 공유하려면 어느 어휘가 이기든지 서로 사상해야 한다(t30의 몫).
- **저장 `save()`(`:516-542`)**: `await store.addActivityWithTravel(...)`에 `location: confirmedPlace("location_query")`, `travelFrom`(`outboundOn`일 때만)·`returnTo`(`returnOn`일 때만), `outboundMode`·`returnMode`·`bufferMinutes`, `notifyLeadMinutes`·`notifyEnabled`·`syncToCalendar`를 넘긴다.
- **Store 뒤편**: 가는 편 `anchor: .arrival`·활동 시작에 도착·버퍼 사용·제목 = 활동 제목(`Store.swift:214-218`), 오는 편 `anchor: .departure`·활동 끝에 출발·버퍼 0·제목 "<제목> (복귀)"(`:222-226`), 둘 다 `linkedActivityId: activity.id`. `location == nil`이면 구간 없이 돌아온다(`:211`).
- `PlaceField`(`:548-630`)는 옛 독립 구조체로 `FullSirView:107`, `:366`, `:379`에서만 쓰인다. `FullSirView:463`이 네 번째 `addActivityWithTravel` 호출 자리다.

## 5. `AddEventView`(781줄) — 이동 일정 생성·편집

- 한 화면이 생성·편집 둘 다(`editing: ScheduledEvent?` `:10`, 머리 "새 일정"/"일정 편집" `:117`, 바닥 "추가"/"저장" `:132`).
- 줄: 고정 `title`(`:185`)·`origin_query`(`:187`, `chosen: editing?.origin?.name` `:188`)·`destination_query`(`:189`), 출발·도착이 둘 다 정해진 뒤 나타나는 `arrival_iso`·`mode`·`buffer_minutes`·`notify_enabled`·`notify_lead_minutes`·(선택) `calendar_sync`(`ensureGatedRows` `:213-229`, `gatedRows` `:240-269`). 시간 줄은 **anchored**(출발 기준/도착 기준 칩, `arr:`/`dep:` 접두 — `editingDatetime` `:233-238`, `EditCardView:194-204`).
- AddActivityView와의 차이: 활동+구간이 아니라 단일 이동 이벤트를 만든다 · 이동시간 추정 표시(`estimateAll`·`estimates`·`estimatesFor`·`restartEstimates`·`recomputeEstimates` `:518-554`) · 수단 칩 부가 정보(`syncFieldExtras` `:558-634`) · "현재 위치" 칩(`:445-510`) · `ConflictBanner`(`:71-73`)와 "소요시간 다시 계산"(`:76-85`).
- 저장 `save()`(`:699-745`): 편집은 `store.updateEvent(...)`(`:731-735`), 생성은 `store.addEvent(...)`(`:737-741`, `linkedActivityId` 인자 없음 → nil).
- `ConflictBanner`(`:750-781`)는 독립 구조체이고 호출은 `AddEventView:71` 하나다. Theme 토큰만 쓴다(`Theme.warn` `:759`, `Theme.warnFill` `:771`). 문서 주석은 이동·활동 두 화면용이라 하나(`:748-749`) 실제로는 이동만 먹인다. 충돌은 `store.conflicts(departure:arrival:recurrenceId:excludingEventId:)`(`:692`)에서 온다.
- **편집 모드는 활동을 모른다.** 활동을 보여주지도 바꾸지도 못하고 `linkedActivityId`를 넘기지도 않는다 — `updateEvent`가 그 필드를 보존하는 건 저장된 레코드의 복사본에서 시작하기 때문일 뿐이다.

## 6. `EditCard.swift`(356줄)·`EditCardView.swift`(538줄)

- `EditCard.swift`: `BesirTime`(`:13-97`) · `EditField`(`:109-226`, kind `.place .mode .buffer .notify .weeks .title .datetime .toggle` `:113-119`) · `EditCard`(`:232-247`, `fields`·`isReady`; `parts`/`stated`/`clearedKeys`는 AI 전용 `:236-244`) · `EditCardChrome`(`:253-256`) · `EditCardActions`(`:261-274`, 클로저 8개) · `PlaceSearchDebouncer`(`:287-356`). **SwiftUI를 import하지 않는다**(머리 주석 `:7-8`) — 가드 드라이버가 `Shared/EditCard.swift`를 컴파일하므로(`CLAUDE.md` 빌드 절) 이 파일에 옮겨 넣는 것은 SwiftUI-free여야 한다.
- `EditCardView.swift`: 값 뷰(`card`·`busy`·`actions` 주입, `chrome` 기본은 AI 문구 `:16`). 자체 초안 상태(`customOpen`·`draft`·`rejected`·`draftBasis`·`draftDate` `:20-27`). 줄마다 칩 흐름, 시간 줄은 `DatePicker` 편집기(`:225-258`), 장소 검색 편집기(`:320-354`), 텍스트 편집기(`:383-400`). `ChipFlow`(`:490`).
- **`isReady`(`EditCard.swift:246`)** = `fields.allSatisfy { $0.chosen != nil }` — 모든 줄이 값을 가져야 하므로 토글 줄은 시드해야 한다(주석 `:117`). "장소 없음" 표지가 필요한 이유다. **줄을 배열에서 빼면 준비를 막지 않고, 있는데 nil이면 막는다.**
- 사용처: AI 채팅(`AIChatView:110`, AI 기본 크롬 + 어댑터 `:128-137`), `AddEventView:68`·`AddActivityView:72`·`ActivityDetailView:64`(셋 다 `EditCardChrome(header: nil, confirmTitle: nil)`이라 카드가 머리·확인 버튼을 그리지 않고 화면이 소유). `[재측]`(호출 4곳)
- **구간 편집 문법을 얹을 수 있는가?** 예 — 구간은 줄 소속이라 컴포넌트 표면이 늘지 않는다(SPEC-UIKIT-003 REQ-011). 막는 것은 컴포넌트가 아니라 (가) 공유된 줄 빌더·소속 논리가 없다는 것 (나) 활동에 구간을 나중에 붙이고 고치는 Store 진입점이 없다는 것.
- `EditCardView.departureAnchored`(`:77-80`)는 `anchored == true`인 줄만 읽는다 — 활동 시간 줄(unanchored)은 버퍼 흐림에 영향이 없다. 구간 시간 줄(anchored)을 활동 시작·끝 줄(unanchored)과 한 카드에 두면 흐림이 **첫 anchored `.datetime` 줄**(`first(where:)`)만 따른다.

## 7. 편집기가 열리는 자리

| 편집기 | 호출 자리 |
|---|---|
| `EventDetailView(event:)` | `ContentView:133` (`selection` 시트 `:127-141`, `NavigationStack` 안) |
| `ActivityDetailView(activityId:)` | `ContentView:147` (`selectedActivityId` 시트 `:142-149`) |
| `AddEventView()` | `ContentView:151` (`showingAdd`) |
| `AddActivityView()` | `ContentView:154` (`showingAddActivity`) |
| `AddEventView(editing:)` | `EventDetailView:92` (`showingEdit`) |
| "+" 메뉴 | `ContentView:226-233` "이동 일정 추가"→`showingAdd`, "활동 추가"→`showingAddActivity` |

`selection`·`selectedActivityId`를 정하는 탭: `ContentView:480-481`, `:618`(활동), `:641`·`:674`(이동). **시간표에서 구간→활동으로 건너뛰는 길이 없다**; `EventDetailView`↔`ActivityDetailView` 사이 이동도 양방향 모두 없다.

## 8. 문법 대조표 · 구체 답

| | 활동 생성(`AddActivityView`) | 이동 생성(`AddEventView`, `editing == nil`) | 활동 편집(`ActivityDetailView`) | 이동 편집(`AddEventView`, `editing != nil`) |
|---|---|---|---|---|
| 편집 가능 | 제목·장소·시작·끝·캘린더 동기화 + 구간 줄(가는/오는 토글, 출발지, 가는 편 수단·여유, 도착지, 오는 편 수단, 알림 토글·리드) | 제목·출발지·도착지 → 시간(anchored)·수단·버퍼·알림·캘린더 | 제목·장소("장소 없음" 포함)·시작·끝 | 제목·출발지·도착지·시간(anchored)·수단·버퍼·알림·캘린더 |
| 읽기 전용 | 없음 | 없음 | 반복 안내(`:67-70`) | 없음. 연결된 활동은 보이지 않음 |
| Store 호출 | `addActivityWithTravel` | `addEvent` | `modifyActivity`; 삭제 `deleteActivity`/`deleteRecurringSeries` | `updateEvent`; 삭제 `deleteEvent`/`deleteRecurringSeries` |
| 활동과의 연결 | `linkedActivityId` 구간을 만든다 | 없음(nil) | 묶인 구간을 옮기고 재정렬(`Store.swift:309-329`) | 필드는 보존되나 **무시**: 활동은 그대로 |

시간 줄은 표면마다 다르다: 활동 시작·끝은 unanchored(접두 칩 없음, `chooseTimePlain`), 이동 시간은 anchored(출발/도착 기준 칩, `chooseTime`).

**(a) 이동 구간의 시간을 고치면 활동과 갈라지는 이유** — 호출 사슬: `EventDetailView:88-93` 시트 → `AddEventView(editing:)` → `AddEventView.save`(`:699-745`)가 `arrival_iso`를 해석(`:703`)해 `store.updateEvent`(`:731`) → `Store.updateEvent`(`:945-992`)가 제목·출발지·도착지·`arrivalDate`·수단·버퍼·알림을 덮어쓰고(`:958-967`) 추정을 다시 계산하고(`:970-977`) 되쓰고(`:979-982`) 구글을 재등록한다(`:985-991`). **데이터 연결은 끊기지 않는다**(`linkedActivityId`는 `addEvent` `:591`에서만 대입되고 `grep -rn "linkedActivityId = nil\|linkedActivityId: nil" Shared`는 아무것도 못 찾는다). 깨지는 것은 **결합**이다: `updateEvent`가 `modifyActivity`·`moveActivity`·`realignReturnLeg`를 부르지 않는다 → 가는 편이 더는 활동 시작에 도착하지 않을 수 있고 오는 편이 활동 끝에 출발하지 않을 수 있다. 카드가 출발지·도착지·anchor까지 바꾸게 하는데 활동 장소와 대조하지 않는다. 이후 `moveActivity`는 같은 변위로 구간을 옮겨 어긋난 오프셋을 굳히고(`Store.swift:1074-1078`), `realignReturnLeg`는 `anchor == .departure`인 구간만 재정렬하며(`:334`), `linkedLegs`는 명시적 연결 중 첫 arrival·첫 departure만 고르므로(`:1118-1124`) anchor 칩을 뒤집으면 구간이 조회에서 바뀌거나 사라진다. AI 경로도 같다: `AIAssistant.swift:2839` → `modifyEvent` → `updateEvent`(`Store.swift:345-365`). (코드 읽기, 미실행.) `[재측]`(`updateEvent` 전문 열람·활동 참조 0)

**(b) 생성 카드의 구간 줄과 통합 편집 화면이 공유할 수 있는 최소 조각** — 그대로 재사용: `EditCardView`·`EditCard`·`EditField`(`.toggle`·`.mode`)·`EditCardActions`·`PlaceSearchDebouncer`·`ConflictBanner`. 추출 필요: 줄 빌더(`legToggleRow` `:330`·`outboundRows` `:336`·`returnRows` `:353`·`notifyToggleRow` `:363`·`notifyLeadRow` `:371` — `notifyLeadRow`는 `AddEventView:279-284`에 같은 선택지로 이미 하나 더 있다), 소속 논리(`choose`의 `outbound_enabled`·`return_enabled`·`notify_enabled` 케이스 `:205-263`·`ensureNotifyRows` `:310`·`removeNotifyRows` `:322`), 기억값 관리(`@State` 9개 + 도우미 5개). 제약: `EditCard.swift`로 옮기면 SwiftUI-free여야 한다; 기억값 도우미가 뷰의 `confirmedPlaces` `@State` 사전에 기대므로 그 사전을 실은 값 타입이 필요하다. 기존 구간을 고치려면 시드는 `ScheduledEvent`(수단·버퍼·anchor·`notifyLeadMinutes`·`wantsNotification`)에서 온다 — `AddEventView.gatedRows(seeding:)`(`:273-277`)가 같은 일을 한다. 나중에 오는 편을 붙이려면 Store 진입점이 필요하다 — `addEvent(..., linkedActivityId:)`가 받으므로 얇은 래퍼면 된다(`grep -n "func addLeg\|func addReturn" Shared/*.swift` → 없음).

**(c) 지켜야 할 UI 계약** —
- **Theme 토큰**: `Theme.bg/raised/ink/muted/faint/line/travel/travelFill/travelInk/activity/warn/warnFill/nowLine`(`Theme.swift:21-50`), 반경 `Theme.radius` = 3(`:55`). 여섯 파일 위반 검사(`Color(`·`.foregroundColor(.`·`.background(.`·`.foregroundStyle(.<이름>)`): `EventDetailView:289` `.foregroundStyle(.white)`(노선 뱃지, 주석 `:287-288`의 문서화된 예외, plan.md t14 행 `:451` "노선색 뱃지 white"), `:291` `.background(Color(hex: step.color), in: Circle())`(API 노선색), `:61` `RoundedRectangle(cornerRadius: 12)`(지도 클립, 주석 `:59-60` · SPEC-UIKIT-004 D-4 #2 · plan t14 "지도 클립 12"), `EditCardView:289`·`:475` `Color.clear`(투명 — 무해). 나머지 파일은 0. 기타: `Color(hex:)` 확장(`EventDetailView:420-430`), 고정 글꼴(`EventDetailView:286`·`:221`, `@ScaledMetric` `:38`), 이모지 "⚠️"(`EventDetailView:225`).
- **접근성 패턴**: 아이콘 전용 검색 버튼은 `.accessibilityLabel("장소 검색")`(`AddActivityView:596`, 쌍둥이 `FavoritesView:59`), 스피너로 접히는 버튼은 라벨 유지(`AddActivityView:508` "추가", `AddEventView:137`), `EditCardView` 줄은 `.accessibilityElement(children: .contain)` + 메모를 이은 줄 라벨(`:158-160`)·칩의 `.isSelected`(`:292`)·확인 힌트(`:480`)·"진행 중"(`:99`)·후보 행 라벨(`:377`), `EventDetailView:237`·`:318`의 `.combine` 묶음(SPEC-UIKIT-004 REQ-023). 새 아이콘 전용·스피너 접힘 컨트롤은 명시 라벨이 필요하다.
- 계약 5: `confirmedPlace`·시간 해석·anchor 사상의 두 번째 구현은 위반이다. 해석·서식은 `BesirTime`이 소유한다.

**(d) 삭제 연계 — 이미 있는 것과 틈**: "이동 삭제는 그것만" = `deleteEvent`(`Store.swift:1273-1282`)가 그 이벤트와 알람·캘린더 항목만 지운다(확인 `[재측]`). `EventDetailView` 안 예외 둘 — "같은 제목 일정 모두 삭제" 루프(`:373`)는 제목이 같은 모든 이벤트(연결 구간 포함)를 지우고, `deleteRecurringSeries`(`:371`)는 `recurrenceId` 기준이라 연결과 무관하다. "활동 삭제 시 연계 이동도 삭제" = `deleteActivity`(`:371-384`)가 명시적 연결 구간을 지우고 알림·구글 항목도 정리한다(`[재측]`). `deleteRecurringSeries`(`:703-722`)는 `recurrenceId`로 이벤트·활동을 지우며 `linkedActivityId`를 보지 않는다 — `addActivityWithTravel` 구간은 `recurrenceId`가 없고 반복 경로도 아니라서 단일 활동에는 틈이 없다. `deleteActivities`(`:1303`)는 이 렌즈가 끝까지 읽지 않았고 오케스트레이터가 읽어 연쇄 없음을 확인했다. `[재측]`

## 9. plan.md 제약 (SPEC-UIKIT-004~008 · t16·t17·t30 행)

`grep -n "t17\|t30" plan.md | head -30`은 아무 것도 못 찾았다(카드 표가 t16과 t23에서 멈춘다 `:437-453`).
- t3(`SPEC-UIKIT-003`, `:440`): 활동 화면들이 구간을 "컴포넌트 옵션"으로 흡수하기로 했으나 REQ-011이 줄 소속을 택했다(`.moai/specs/SPEC-UIKIT-003/spec.md:97`) — 구간 문법이 `EditCard`에 없는 이유.
- t4(`SPEC-UIKIT-004`, `:439`): `EventDetailView`의 삭제 버튼은 카드 컨테이너 밖에 둔다(스펙 8·9행, `EventDetailView:337-338`). SPEC-UIKIT-004 REQ-030이 "삭제 분기"(단일/반복/같은 제목)를 잃으면 안 되는 어포던스로 적었다.
- t7(`SPEC-UIKIT-007`, `:443`, `:565`): 출발지 시드 줄 `chosen: editing?.origin?.name`(`AddEventView:188`) — 편집 시드를 손대도 유지. 후속 O-1(`Store.modifyEvent`가 nil 출발지를 도착지로 대체, `Store.swift:358`)이 열려 있고 `modifyEvent`를 부르는 통합 편집 경로에 그대로 나타난다.
- t16(`SPEC-UIKIT-008`, `:453`): AI 카드의 왕복 가는 편 줄과 "가는 편 없음" 칩. AI 카드의 구간 키(`travel_from_query`·`return_to_query`)는 생성 카드(`outbound_enabled`·`origin_query`·`return_query`)와 다르다 — 공유 문법은 어느 어휘가 이기는지 정해야 한다(t30의 이웃).
- t5(`SPEC-UIKIT-006`, `:442`): 죽은 코드 정리 — 추출 뒤 안 쓰는 구간 도우미를 남기지 않는다. plan.md `:105`와 t5 각주는 "나중에 UI에서 쓸 것"을 죽은 코드 보존 사유로 거절했다 — 쓰이지 않는 어포던스를 더하지 않는다.
- t14(`:451`): Theme 청소 — `.secondary`·`.tertiary`를 쓸어냈으므로 새 UI는 Theme 토큰만.
- 모든 계획 행이 시뮬레이터·실기기 단계를 운영자 몫으로 적고 기계 초록은 끝이 아니라고 한다(프로세스 메모).

## 10. 위험과 열린 질문

1. **통합 편집이 어디 사는가**: `AddEventView` 편집 모드에 연결 활동 인식을 더한다 / `ActivityDetailView`에 구간 줄을 더한다 / 새 공유 컴포넌트. 증거상 `ActivityDetailView`+구간 줄이 더 짧은 길이다 — 이미 카드 문법과 생성 줄이 있다(설계 판단, 검증한 사실이 아님).
2. `modifyActivity`가 장소를 못 지운다(`Store.swift:321`) — 편집에서 "장소 없음"은 조용한 무동작. 구간 출발·도착까지 고치는 통합 화면은 장소가 바뀔 때 구간이 어떻게 되는지 정의해야 한다(`modifyActivity`는 구간 끝점에 손대지 않는다).
3. 나중에 오는 편을 붙이려면 새 Store 진입점이 필요하다 — 이미 있는 것으로는 `addActivityWithTravel`(활동까지 만든다)뿐.
4. 연결된 구간에 대한 `updateEvent`: 연결 구간의 시간 편집을 막거나 활동 인식 함수로 돌린다. `adjustTravelLeg`(`Store.swift:1091`)는 직접 드래그에 대해 이미 규칙이 있다 — 활동과 맞닿은 쪽을 고정하고 변화를 버퍼가 흡수한다(`:1088-1090`). 시간 줄 편집도 같은 규칙을 따를 수 있다.
5. `linkedLegs`의 anchor 분류(`Store.swift:1122-1123`): 통합 화면이 anchor 변경을 허용하면 `moveActivity`·`realignReturnLeg`에 구간이 안 보이게 된다.
6. 같은 제목 일괄 삭제(`EventDetailView:331-333`, `:373`)가 다른 활동의 연결 구간을 칠 수 있다.
7. 가드 드라이버 컴파일 집합: `EditCard.swift`는 SwiftUI를 import할 수 없다.
8. `FullSirView:463`은 네 번째 `addActivityWithTravel` 호출 자리다 — UI 통합과 무관하나 같은 Store 함수를 공유한다.

**찾지 못한 것 / 안 읽은 것**: `grep -n "t17\|t30" plan.md` → 없음. `AIAssistant`의 카드 조립 코드는 깊게 읽지 않았다(t30 렌즈). 세 편집 화면의 복사된 도우미 본문을 바이트 단위로 대조하지 않았다. 빌드·테스트를 돌리지 않았다.
