# t17 plan 렌즈 3 — 타임라인 블록 배치 · 겹침 (읽기 전용 조사)

기준 트리: `b2c3987`(`ContentView.swift` 980줄, `wc -l`). 읽기 전용 Explore 에이전트의 보고를 옮겼다. `[재측]`은 오케스트레이터가 이 트리에서 다시 재서 맞다고 확인한 줄이다.

## 0. 결론

- 활동 블록과 이동 블록은 **한 번의 배치**(`positionedBlocks`, `Shared/ContentView.swift:699-742`)를 지난다. 그 배치는 어느 블록이 한 묶음인지 모른다.
- **배치에서 연결을 읽는 곳이 없다.** `linkedActivityId`는 `ContentView.swift`에 딱 한 번(`:651`) 나오고 구간 제목을 숨기는 데만 쓰인다. 배치·`columnFrame`·히트테스트는 연결을 보지 않는다. `[재측]`(`grep -n linkedActivityId Shared/ContentView.swift` → `:651` 한 줄)
- **구간이 안 줄어드는 이유**: 활동과 자기 구간은 끝점에서 정확히 맞닿는다(구간 끝 = 활동 시작). 무리 끊기 판정이 `<=`라 서로 다른 무리가 된다. 셋째 블록이 활동에만 겹치면 활동만 2열이 된다 — 운영자가 말한 결함이다. `[재측]`(`:730`의 `columnEnds.allSatisfy({ $0 <= item.start })`)
- **고칠 자리**: `positionedBlocks` 안, Store 데이터만의 순수 함수로. `columnFrame`·`blockView`·`block(atX:)`가 모두 그 출력을 읽으므로 나머지는 안 바꿔도 된다(§4).

## 1. 하루 시간표 동작

**하루 데이터**: `events(on:)`(`:87-95`)가 `store.events`를 `Store.overlapsDay`(`Shared/Store.swift:38-41`)로 거르고 `arrivalDate`로 정렬 — 자정을 넘는 구간은 양쪽 날에 든다. `activities(on:)`(`:100-108`)는 같고 `startDate`로 정렬. `hasEvents(on:)`(`:112`)는 `Store.daysWithSchedule` 캐시를 읽고 블록 배치와 무관하다.

**페이지 구성 `dayTimetableContent(for:)`(`:418-500`)**: `:419-421`에서 `dayEvents`·`dayActivities`·`placed = positionedBlocks(...)`. 렌더는 `:438-443` — `ZStack` 안 `ForEach(placed)` 하나, 블록마다 `columnFrame(p, total: geo.size.width)` 후 `blockView(...).frame(width: f.width).offset(x: f.x, y: offsetY(for: p))`. 한 번의 통과가 두 종류를 다 그린다. `blockView`(`:505-513`)는 `p.kind`로 갈린다: 활동 → `activityBlockView`(`:596-621`), `departureDate`가 있는 이벤트 → `travelBlockView`(`:644-677`), 없는 이벤트 → `failedEstimateBlockView`(`:627-642`). 두 블록 뷰 모두 `.frame(maxWidth: .infinity)`라 폭은 `:441`의 `.frame(width: f.width)`에서만 정해진다.

**`span(for:on:)` — 블록 기하의 단일 출처**: 활동 판(`:542-555`) 시작을 자정으로 잘라(`:545-546`) 끝도(`:547-548`), 최소 높이는 `max(minActivityMinutes = 20, end - start)`(`:554`, 상수 `:533`). 이벤트 판(`:557-583`) — `departureDate`가 없으면 도착 시각 아래 고정 높이 실패 블록(`:558-562`, 높이 상수 `:536`), 있으면 `[dep, arrival]`을 하루로 자른다(`:567-569`) — **구간의 span에는 버퍼가 들어 있다**(`departureDate = arrival - travel - buffer` `Store.swift:1161`). 최소 높이 16(상수 `:534`). 도착 기준은 위쪽으로(`:582`), 출발 기준은 아래쪽으로(`:579-581`) 자란다. 호출자: 렌더 높이 `:598`·`:646`, 배치 입력 `:704`·`:708`. 히트테스트는 `span`을 직접 부르지 않고 `positionedBlocks`가 `span`에서 복사한 `p.start`·`p.minutes`를 읽는다 — 렌더와 히트테스트가 한 출처를 공유한다.

**배치 알고리즘 `positionedBlocks`(`:699-742`)** `[재측]`(전문 열람):
- 입력(`:702-712`): `Item`은 id·kind·start·end. 활동을 먼저(`:703-706`), 이벤트를 뒤에(`:707-710`), 정렬 키는 `start` 그다음 `end`(`:711`).
- 루프(`:728-739`): `:730`이 **모든 열이 이미 끝났을 때만** 새 무리를 시작한다(`columnEnds.allSatisfy { $0 <= item.start }` 후 `flush()`). 아니면 비어 있는 첫 열에 넣고(`:732-734`), 없으면 새 열을 연다(`:735-737`).
- `flush()`(`:717-726`): 무리 구성원 전원에게 `columns = columnEnds.count` — **그 블록과 겹치는 블록 수가 아니라 무리 전체의 최대 동시 열 수**다.
- 결과: 맞닿기만 한(`end == start`) 블록은 같은 무리가 되지 않는다. 서로 직접 겹치지 않아도 셋째 블록이 이으면 같은 무리가 되어 둘 다 좁아진다. `PositionedBlock`(`:683-690`)은 `kind`·`start`·`minutes`·`column`·`columns`를 담고 `kind`가 `ScheduledEvent`·`ActivityBlock` 전체를 들고 있어 배치 시점에 `linkedActivityId`를 새 조회 없이 쓸 수 있다.
- 프레임 `columnFrame`(`:745-750`): `columns == 1`이면 `(0, total)`, 아니면 3pt 간격에 `width = (total - 3*(n-1))/n`, `x = column*(width+3)`.

**히트테스트 `block(atX:y:in:)`(`:759-773`)**: 렌더와 같은 `placed`를 읽고 `minutes >= p.start, minutes <= p.start + p.minutes`(`:763`)를 검사, `columns > 1`이면 정규화된 칸(`lo = column/columns`, `hi = lo + 1/columns` `:764-768`)을 본다 — **3pt 간격을 포함하지 않는다.** 렌더 왼쪽 가장자리는 `c*(T+g)/n`, 히트테스트는 `c*T/n`이라 어긋남이 `c*g/n`(3pt 미만). 열 수학을 중복한 다른 곳은 없으나 작은 기존 렌더/히트 불일치다 — 배치를 건드릴 때 하나의 공유 칸 함수로 합칠 만하다. 동률은 가장 짧은 블록이 이긴다(`:769-770`), 범위 검사는 양끝 포함이라 14:00에 끝나는 구간과 14:00에 시작하는 활동이 둘 다 분(840)에 맞고 짧은 쪽이 이긴다. x는 `RescheduleOverlay.normalizedX`에서 0..1로 온다(`:941-944`). iOS 배선 `:454-486` — 오버레이가 ZStack 전체를 덮고(`:461`) `onBegin`(`:463-467`)·`onTap`(`:477-483`)이 모두 `block(atX:...)`를 부른다. 오버레이가 터치를 가로채므로 블록별 `.onTapGesture`(`:618`, `:641`, `:674`)는 iOS에서 죽은 코드다(주석 `:616-617`, `:624-626`, `:672-673`).

**`SwipePager`(`:799-855`)**: 앞·현재·뒤 세 페이지(`:813-815`), 페이지마다 `dayTimetableContent`를 돌려 `positionedBlocks`가 렌더당 세 번 돈다. `DragGesture(minimumDistance: 12)`(`:821-852`), `activeDrag != nil`이면 잠긴다(`isLocked` `:803`). 블록 폭과 무관.

**`RescheduleOverlay`·드래그 재배치(`:885-979`, iOS 전용)**: 0.35초 길게 누르기(`:907`) → `onBegin`이 `block(atX:...)`로 `activeDrag`를 정하고(`:463-467`), `onChange`가 5분 단위로 맞추고(`:468-471`), `onEnd`가 `finalizeDrag`를 부른다(`:472-476`). **드래그가 연결된 짝을 움직이는가**: 활동을 끌면 `store.moveActivity`(`:780`, `:783`)가 `linkedLegs(for:)`(`Store.swift:1065-1084`)로 양쪽 구간을 옮긴다. 구간을 끌면 `store.adjustTravelLeg`(`:788`, `:791`; `Store.swift:1091-`) — 활동은 안 움직이고, 출발 기준은 `shiftEvent`, 도착 기준은 `adjustBuffer`. 끄는 동안은 잡은 블록만 오프셋이 걸리고(`dragOffsetMinutes(forActivity:)`·`dragOffsetMinutes(forEvent:)` `:586-594`가 id로만 맞춘다, `offsetY` `:516-523`), 짝 구간은 놓을 때까지 그대로다. `placed`는 뷰 본문에서 저장된 데이터로 계산되므로(`:421`) 끄는 도중 열 배치는 바뀌지 않는다.

**순서·z-order**: 그리는 순서는 `placed`의 순서(`start` 오름차순 다음 `end` 오름차순 `:711`) — 나중에 시작하는 블록이 위. `(start, end)`가 같으면 정렬에 좌우된다(Swift `sort`는 안정 정렬을 문서로 보장하지 않고 활동이 먼저 append된다 `:703-710`). "지금" 선(`:446-452`)은 블록 위에 그려지고 `allowsHitTesting(false)`.

## 2. 실례

| 블록 | 구간(자정부터 분) |
|---|---|
| O 가는 편 13:30–14:00 | 810–840 |
| A 활동 14:00–15:00 | 840–900 |
| U 무관 블록 14:10–14:50 | 850–890 |
| R 오는 편 15:00–15:30 | 900–930 |

U는 `ScheduledEvent`든 `ActivityBlock`이든 같은 `items` 배열에 들어가(`:703-710`) 결과가 같다. 어느 span도 최소 높이에 걸리지 않는다(U 40분, 구간 30분). 정렬(`:711`)은 O, A, U, R.

루프(`:728-739`) 추적: (1) O — `columnEnds` 비어 열 0 개설, `[840]`. (2) A — `allSatisfy(<= 840)` 참(`:730`)이라 `flush()`가 O를 `columns = 1`로 내보내고 비운 뒤 A가 열 0, `[900]`. (3) U(시작 850) — 900 ≤ 850 거짓이라 flush 없음, 빈 열도 없어 열 1 개설, `[900, 890]`. (4) R(시작 900) — 두 끝이 ≤ 900이라 `flush()`가 A를 2열 중 0, U를 2열 중 1로 내보내고 R이 열 0, 마지막 `flush()`(`:740`)가 R을 1열 중 0으로 내보낸다.

결과: O = 1열 중 0(전폭) · A = 2열 중 0(반폭 왼쪽) · U = 2열 중 1(반폭 오른쪽) · R = 1열 중 0(전폭).

**구간이 안 줄어드는 이유**: 배치가 `linkedActivityId`를 보지 않는다. 구간이 활동이 시작하는 순간에 끝나고 `allSatisfy { $0 <= item.start }`(`:730`)가 그것을 "겹치지 않음"으로 보므로 각 구간이 자기 혼자 1열 무리다. **거울 사례**(U가 구간에만 겹침): U를 13:40–13:50으로 두면 O와 U가 2열 무리가 되고 A는 전폭이다 — "둘 중 하나라도 줄면 연계도 같이 줄도록"의 나머지 반쪽. **구간이 자기 활동과 같은 무리가 되는 경우**: 20분보다 짧은 활동은 20분으로 부풀려지고(`:554`) 활동의 실제 끝에 출발하는 오는 편이 부푼 활동 블록과 겹친다. 16분보다 짧은 구간은 활동 쪽으로 부푼다(`:579-582`) — 설계상 활동에서 먼 쪽으로 부풀어 가는 편에는 일어나지 않는다.

## 3. `linkedActivityId`가 쓰이는 곳

- 렌더: `grep -rn linkedActivityId Shared/ContentView.swift` → `:651` `let showsTitle = event.linkedActivityId == nil` 한 줄. 구간 제목을 숨기는 것뿐이고 배치·`columnFrame`·`block(atX:)`에서는 쓰지 않는다. `[재측]`
- 정의: `Shared/Models.swift:190`, 문서 주석 `:186-189`. 생성: `Store.addActivityWithTravel`(`:179-236`)이 두 구간에 건다(`:217` 가는 편, `:225` 오는 편), `addEvent`는 인자를 받아 대입한다(`:581`, `:591`).
- Store의 다른 사용: `deleteActivity` `:368-374`, `realignReturnLeg` `:334`, `linkedLegs(for:)` `:1118-1131`(private — 명시적 연결 먼저 `:1120-1124`, 없으면 `recurrenceId`+같은 날+장소 이름으로 옛 반복 데이터 추정 `:1126-1130`). AI: `AIAssistant.swift:2038`, `:2057`, `:2826`(렌더용 아님).
- **반복 일정 틈**: 반복 경로가 만든 구간(`Store.swift:638-659`)은 `recurrenceId`만 있고 `linkedActivityId`가 없다. 대입은 `addActivityWithTravel` 경로(`:217`, `:225`)뿐이다. 그래서 `linkedActivityId`만으로 묶는 배치는 반복 구간을 놓친다 — 덮으려면 `private`인 `linkedLegs`를 다시 써야 한다. `[재측]`(대입 자리 확인)

## 4. 알고리즘 수준의 최소 변경 (설명만, 코드 없음)

수정은 전부 `positionedBlocks`(`:699-742`) 안에 있어야 한다. Store 데이터만의 순수 함수이므로 렌더와 히트테스트가 `PositionedBlock`으로 함께 받는다.

- **A안 — 묶음을 한 열로 채운 뒤 펼친다**: 활동마다 활동+구간의 합집합을 한 배치 항목으로 만든다(구간은 `linkedActivityId`로 묶고 옛 데이터는 `Store.linkedLegs` 추정으로). 그 묶음 항목을 기존 열 알고리즘으로 배치하고 구성원 전원에게 묶음의 `column`·`columns`를 준다.
  - 장점: 묶음이 같은 폭·같은 x를 구조적으로 보장한다; 거울 사례(U가 구간에만 겹침)도 셋을 함께 좁힌다; `columnFrame`·`block(atX:)`는 안 바꿔도 된다.
  - 단점: 묶음 span이 13:30–15:30으로 어느 단일 블록보다 넓다 — 13:35의 무관한 블록이 다른 열로 밀리고 만나지도 않는 활동까지 좁힌다(요청한 동작이지만 필요 이상의 폭을 쓴다); 단독 활동·단독 구간에는 대체 항목이 필요하다; 구간이 활동과 이어져 있지 않으면(옛·추정 데이터) 합집합이 그 사이 틈까지 막아 폭이 낭비된다; 묶음의 최소 높이 처리는 원시 날짜가 아니라 이미 부푼 `span` 값으로 만들어야 한다.
- **B안 — 기존 배치를 두고 후처리**: 연결 묶음마다 구성원 전원의 `columns`를 묶음 최대로 올리고 각자의 `column`은 유지한다. 무리는 시간상 서로 떨어져 있어 `columns`를 올려도 다른 블록과 충돌하지 않는다.
  - 장점: 가장 작은 diff, 배치 루프 무변경.
  - 단점: 구성원이 다른 x에 놓일 수 있다(예: 구간이 2열 중 0, 활동이 2열 중 1); 같은 열 번호를 강제하면 구간의 자기 무리 안 다른 블록과 충돌할 수 있다; 구간이 자기 무리가 3열인데 2열로 올리려면 덮어쓰지 않고 최대를 취해야 한다; 올려진 블록 옆에 빈 열이 남는다; 한 활동의 구간이 더 큰 무리 안에 있으면 고정점 검사가 필요하고, 최대를 묶음 전체에서 취해야 거울 사례가 풀린다.
- **C안 — 맞닿음을 겹침으로 (`:730`과 `:732`의 `<=`를 `<`로)**: 그것만으로 부족하다 — 연결된 것만이 아니라 등을 맞댄 모든 쌍이 한 무리가 된다.
- **중복 위험(계약 5, `CLAUDE.md`의 "같은 계산을 두 곳에 두지 않는다")**: 묶음·폭 계산은 이미 공유 생산자인 `positionedBlocks`에만 있어야 하고 `blockView`·`columnFrame`·`block(atX:)`에 두면 안 된다. `block(atX:)`는 3pt 간격 없이 가로 칸을 다시 유도한다(`:764-768` 대 `:745-750`) — 폭이 균일하지 않게 되면(예: 불균등 폭) 이 기존 불일치가 커진다. 새 폭 체계는 `columnFrame`과 `block(atX:)`가 함께 쓰는 **하나의 칸 함수**에서 나와야 한다. 연결 검출은 `Store.linkedLegs`(또는 그에 상응하는 공개 함수)를 재사용해야 하고 뷰에서 추정을 두 번째로 만들면 안 된다.
- **검증 제약**: 지금 테스트는 이 파일을 컴파일하지 못한다(§6).

## 5. 블록을 배치하는 다른 뷰

`grep -rln "hourHeight\|Widget\|WidgetKit" Shared ShareExtension project.yml Tools` → `Shared/ContentView.swift`뿐. `grep -rn "ActivityBlock\|ScheduledEvent" Shared/*.swift | grep -v "Store.swift\|Models.swift\|AIAssistant.swift"`의 나머지는 시간표가 아니다: 상세·편집 화면(`ActivityDetailView.swift:4`·`:47`, `EventDetailView.swift`, `AddEventView.swift:10`·`:233`·`:273`), `FullSirView.swift:77`(`upcomingEvents` — 목록), 구글 캘린더 동기화(`GoogleCalendarService.swift`). 위젯 대상도 다른 캘린더·시간표 뷰도 없다(`ShareExtension/`은 `ShareViewController.swift`뿐). 주·월 격자는 블록이 아니라 점을 그린다(`:285-372`, `daysWithSchedule`) — 영향 없음. **`ContentView.dayTimetableContent` 하나만 고치면 된다.**

## 6. 기존 테스트·드라이버

`grep -rn "overlap\|span(for" Tools/ Shared/ proxy/`는 시간표 열 배치를 검사하는 것을 못 찾는다. `Tools/GuardDriver.swift`는 `Store.overlapsDay`·`dayKeys`·`daysWithSchedule`만 검사한다(X절 `:1274-1318`). 그 절의 주석(`:1274-1278`)이 "드라이버가 컴파일하지 못한다"고 `ContentView.swift`의 `span(for:on:)`에 대해 적는다. `CLAUDE.md` 빌드 절이 드라이버 컴파일 집합을 `EditCard.swift`·`AIAssistant.swift`·`GuardDriver.swift` + `Store`·`Models`·`Config`·`PlaceSearch`·`DirectionsService`·`LocationManager`·`NotificationManager`·`GoogleCalendarService`·`SharedInbox`로 못박고 `ContentView.swift`는 없다. **그래서 드라이버는 `positionedBlocks`·`columnFrame`·`block(atX:)`를 지금 모양으로 돌릴 수 없다. 배치를 `Store`/`Models`의 순수 함수(예: `ScheduleLogic`, `Models.swift:~207` 같은)로 빼야만 시험할 수 있다.** `CHECKLIST.md:325`(K5)는 히트테스트와 렌더가 `span(for:on:)`를 공유한다고 적고 `:329`(K9)는 잘린 블록의 높이·위치가 실기기 전용이며 자동 증거가 없다고 적는다. 열 배치용 CHECKLIST 행은 없다(`grep "겹치\|나란히" CHECKLIST.md` 없음). Xcode 테스트 대상이 없다(`grep test project.yml`·`ls Tests` 빈 결과).

## 7. macOS와 iOS 차이

`grep -c "#if os"` = 4(`:2-4`, `:195-207`, `:454-486`, `:857-980`): `:2-4` iOS UIKit import; `:195-207` macOS 전용 도구 모음 동기화 버튼(시간표 영향 없음); `:454-486`·`:857-980` iOS 전용 `RescheduleOverlay`(길게 누르기 드래그와 좌표 탭이 `block(atX:)`를 통한다). `positionedBlocks`·`columnFrame`·`span`·블록 뷰는 두 플랫폼이 그대로 공유한다 — 배치 수정은 양쪽에 닿는다. macOS에서는 블록별 `.onTapGesture`(`:618`, `:641`, `:674`)가 살아 있고 드래그 재배치는 없다(`block(atX:)`는 컴파일되나 안 쓰인다). macOS 탭 대상은 SwiftUI 프레임을 따라 간격을 포함하고 iOS는 `block(atX:)`를 따라 제외한다. 플랫폼 분기는 필요 없다.

## 이 렌즈 기준 손댈 파일

`Shared/ContentView.swift`(`positionedBlocks` `:699-742`, 선택적으로 `columnFrame` `:745-750`과 `block(atX:)` `:759-773`이 함께 쓰는 칸 함수) · `Shared/Store.swift`(`linkedLegs` `:1118-1131`이 private — 공개하거나 공유 묶음 함수를 더해야 옛 반복 구간도 묶인다) · `Shared/Models.swift:190` · `Tools/GuardDriver.swift`(배치를 컴파일되는 순수 함수로 뺀 경우에 한해 새 절).
