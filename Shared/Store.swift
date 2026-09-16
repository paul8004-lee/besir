import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

/// 앱 전역 상태: 일정 목록, 설정, 영속화.
@MainActor
final class Store: ObservableObject {
    @Published var events: [ScheduledEvent] = [] { didSet { recomputeDaysWithSchedule() } }
    @Published var config: AppConfig
    @Published var favorites: [FavoritePlace] = []
    /// 이동이 아닌 체류형 활동(수업·근무·점심 등) 시간표 블록.
    @Published var activities: [ActivityBlock] = [] { didSet { recomputeDaysWithSchedule() } }
    /// 식사 기록(be full sir). 시간표에 그리는 블록이 아니라 "무엇을 먹었나"의 이력이라
    /// daysWithSchedule에는 넣지 않는다 — 식당까지 가는 이동은 별도 ScheduledEvent가 담당한다.
    @Published var meals: [MealLog] = []
    /// "이 날짜에 일정이 있는가"만 O(1)로 확인하기 위한 캐시(yyyyMMdd 정수 키).
    /// 월간 캘린더 그리드는 이 값만 보고 점을 찍는다 — events/activities 전체를 매 프레임
    /// 스캔하면(특히 좌우 스와이프 애니메이션 중 여러 번 재계산되며) 버벅임이 생겼다.
    /// 키를 DateComponents가 아니라 Int로 두는 이유: 월간 그리드 한 장을 그릴 때만 42칸 ×
    /// 3페이지 = 126번 조회하는데, DateComponents는 옵셔널 필드가 많은 구조체라 해시 계산이
    /// 눈에 띄게 비싸다(스와이프 중 매 프레임 반복됨).
    @Published private(set) var daysWithSchedule: Set<Int> = []

    /// Date → yyyyMMdd 정수 키(daysWithSchedule 조회용).
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    /// [start, end) 반열린 구간이 그 날과 겹치는지. 일간 나열(ContentView.events/activities(on:))과
    /// 월간·주간 점(daysWithSchedule)이 같은 날에 대해 다른 말을 하지 않도록 판정을 이 한 곳에
    /// 둔다(계약 5 — 자정 넘김 결함을 일간만 고쳤을 때 점과 나열이 어긋나며 드러났다).
    /// 반열린 이유: 정확히 0시에 끝나는 구간은 다음 날과 겹친다고 보지 않는다(그릴 분이 0분).
    /// end ≤ start인 깨진 구간은 어느 날과도 겹치지 않는다고 본다 — 호출자의 폴백(앵커 날 하루)과
    /// 함께 쓴다.
    static func overlapsDay(start: Date, end: Date, day: Date, calendar: Calendar = .current) -> Bool {
        guard end > start, let d = calendar.dateInterval(of: .day, for: day) else { return false }
        return start < d.end && end > d.start
    }

    /// 반복 일정을 몇 주까지 만들 수 있는지. 회차 하나가 구글 캘린더 API 호출 한 번이라
    /// (26주 × 평일 × 4구간이면 500번 넘게 순차 호출) 무한정 늘릴 수 없다. 그 이상은 구글의
    /// 반복 이벤트(RRULE)를 써야 하는데, 이 앱은 회차를 개별 일정으로 다루는 구조라 큰 변경이 된다.
    /// nonisolated — maxBufferMinutes와 같은 이유(카드 입력 검증이 메인액터 밖에서 부른다).
    nonisolated static let maxRecurrenceWeeks = 26

    /// 한 구간(활동·이동)이 달력 점 계산에서 하루씩 걷히는 최대 날 수이자, 생성 시점에 활동
    /// 길이로 받아들이는 상한. 두 곳이 **같은 값**이어야 한다 — 걷기 상한만 있으면 상한 넘는
    /// 활동이 "점이 잘린 채" 저장되고, 생성 가드만 있으면 깨진 저장 데이터가 걷기를 비한정으로
    /// 돌린다(AIAssistant.executeCreateActivity가 이 상한으로 거른다).
    /// nonisolated — 실행부(executeCreateActivity)가 static 문맥에서도 읽을 수 있게.
    nonisolated static let maxIntervalDays = 366

    /// 도착 여유의 허용 범위. 음수는 출발을 그만큼 늦추고, 과도한 값은 실수다 — 수동 조정·AI 생성·
    /// AI 수정이 같은 한도를 쓰도록 한곳에 둔다(계약 5. 예전엔 이 식이 세 곳에 복사돼 있었고,
    /// 그래서 AI 생성 경로만 클램프가 빠진 채 남아 있었다).
    /// 카드의 직접입력 검증도 같은 상한을 봐야 한다 — 리터럴로 두 곳에 적으면 한쪽만 바뀐다.
    /// nonisolated인 이유: 카드의 값 검증(AskField.accepts)이 메인액터 격리 밖에서도 불린다.
    nonisolated static let maxBufferMinutes = 180
    static func clampBuffer(_ minutes: Int) -> Int { max(0, min(Self.maxBufferMinutes, minutes)) }

    /// 알림 리드타임은 음수면 "출발한 뒤에 알린다"가 되어 무의미하다. 상한은 두지 않는다 —
    /// "하루 전에 알려줘" 같은 요청이 실재한다.
    static func clampNotifyLead(_ minutes: Int) -> Int { max(0, minutes) }

    let notifications: NotificationManager

    private var eventsURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("events.json")
    }
    private var favoritesURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("favorites.json")
    }
    private var activitiesURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("activities.json")
    }
    private var mealsURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("meals.json")
    }
    private var deletedGIDsURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("deleted_gcal_ids.json")
    }

    /// besir에서 지웠지만 구글 캘린더 쪽 삭제가 아직 확인되지 않은 이벤트 id("묘비").
    ///
    /// 삭제 요청은 네트워크·토큰 문제로 조용히 실패할 수 있는데(`try?` + fire-and-forget),
    /// 그러면 로컬에서만 사라진 일정을 다음 동기화가 "다른 기기에서 새로 추가된 것"으로 오해해
    /// 되살려냈다 — 지운 일정이 계속 살아 돌아오던 원인이다. 원격에서 실제로 사라진 걸 확인할
    /// 때까지 여기 남겨두고, 동기화할 때마다 삭제를 다시 시도하며 그동안 가져오기도 막는다.
    private var deletedGoogleEventIds: Set<String> = []

    /// 구글 캘린더에서 지운다. 먼저 묘비를 남겨(그 사이 동기화가 되살리지 못하게) 실제 삭제를
    /// 시도하고, 묘비는 다음 동기화가 "원격에 정말 없다"를 확인했을 때 정리한다 —
    /// 삭제 성공 직후 바로 지우면, 이미 목록을 받아둔 동기화가 되살릴 틈이 남는다.
    private func removeFromCalendar(_ gids: [String]) async {
        guard !gids.isEmpty else { return }
        deletedGoogleEventIds.formUnion(gids)
        saveDeletedGIDs()
        for gid in gids { try? await gcal.deleteEvent(id: gid) }
    }

    private func saveDeletedGIDs() {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(Array(deletedGoogleEventIds)) {
            try? data.write(to: deletedGIDsURL)
        }
    }

    private func loadDeletedGIDs() {
        guard let data = try? Data(contentsOf: deletedGIDsURL),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else { return }
        deletedGoogleEventIds = Set(decoded)
    }

    init(notifications: NotificationManager) {
        self.notifications = notifications
        self.config = AppConfig.load()
        load()
        loadFavorites()
        loadActivities()
        loadMeals()
        loadDeletedGIDs()
        // 시작 시 동기화는 App의 scenePhase(.active)에서 호출한다(여기서 또 호출하면 중복 위험).
    }

    /// 점(달력 날짜 키)은 일간 나열과 같은 겹침 판정으로 채운다 — 자정을 넘는 블록은 구간이
    /// 걸치는 모든 날에 점이 켜진다. 출발시각이 없는(계산 실패) 일정과 끝≤시작으로 깨진 레코드는
    /// 구간이 없으므로 도착일/시작일 하나만(일간 나열의 폴백과 같은 규칙). 저장·네트워크 호출은
    /// 없고 집합만 다시 만든다 — 반복 그룹이 118건이어도 이 함수 자체는 레코드당 한 번 돈다.
    private func recomputeDaysWithSchedule() {
        let cal = Calendar.current
        var set = Set<Int>(minimumCapacity: events.count + activities.count)
        for e in events {
            if let dep = e.departureDate, e.arrivalDate > dep {
                set.formUnion(Self.dayKeys(start: dep, end: e.arrivalDate, calendar: cal))
            } else {
                set.insert(Self.dayKey(e.arrivalDate, calendar: cal))
            }
        }
        for a in activities {
            if a.endDate > a.startDate {
                set.formUnion(Self.dayKeys(start: a.startDate, end: a.endDate, calendar: cal))
            } else {
                set.insert(Self.dayKey(a.startDate, calendar: cal))
            }
        }
        daysWithSchedule = set
    }

    /// [start, end) 반열린 구간이 걸치는 날들의 키. 후보를 시작일 자정부터 end 직전까지 하루씩
    /// 세되, 넣을지의 최종 판정은 overlapsDay(start:end:day:)가 내린다 — 루프 범위는 후보
    /// 생성일 뿐이라 판정 규칙이 바뀌어도 이 열거가 저절로 따라가고, 두 번째 판정이 생기지
    /// 않는다(계약 5). private가 아닌 이유: 드라이버(W·X절)가 이 열거와 overlapsDay 판정이
    /// 같은 날을 내는지 직접 재는데, private면 타입 선언 범위 밖에서 못 부른다.
    static func dayKeys(start: Date, end: Date, calendar cal: Calendar) -> [Int] {
        var keys: [Int] = []
        var cur = cal.startOfDay(for: start)
        // end의 상한을 검사하는 곳은 없다(AI의 end_iso는 9999년도 parseDate를 통과한다). 이 걷기는
        // activities 배열의 didSet 안에서 돌므로 비한정이면 화면이 얼고, 그 레코드를 지우려 해도
        // 앱이 켜질 때마다 다시 얼어 지울 수도 없다. 정상적인 장기 체류(여행 몇 주)보다 넉넉한
        // 366일에서 끊는다 — 그 너머의 긴 반복은 반복 활동이 담당하는 영역이다.
        while cur < end, keys.count < maxIntervalDays {
            if overlapsDay(start: start, end: end, day: cur, calendar: cal) {
                keys.append(dayKey(cur, calendar: cal))
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cur) else { break }
            cur = next
        }
        return keys
    }

    // MARK: - 활동(체류형) 블록

    /// 여러 요일에 반복되는 활동 블록(수업·근무·점심 등)을 한 번에 생성한다. 이동시간 계산은 없다.
    /// 반복 없는 단발성 활동 블록 하나를 추가한다("+" 메뉴에서 수동으로 만드는 경우).
    func addActivity(title: String, location: Place?, startDate: Date, endDate: Date,
                     syncToCalendar: Bool = true) async {
        var activity = ActivityBlock(title: title, location: location, startDate: startDate, endDate: endDate)
        activity.syncToCalendar = syncToCalendar
        activities.append(activity)
        activities.sort { $0.startDate < $1.startDate }
        saveActivities()
        if config.autoAddToCalendar && syncToCalendar {
            enqueueCalendarUpload(activityIDs: [activity.id])
        }
    }

    /// 활동 블록과 그에 딸린 이동 구간(가는 편·오는 편)을 **한 번에, 서로 묶어서** 만든다.
    ///
    /// 따로 만들면 둘 사이에 아무 연결이 없어서, 나중에 활동 블록을 드래그해 옮겨도 이동 구간은
    /// 제자리에 남는다(사용자가 겪은 문제). 여기서 만든 구간은 `linkedActivityId`로 활동을
    /// 가리키므로 `moveActivity`가 같이 옮기고, 활동을 지우면 같이 지워진다.
    ///
    /// - `travelFrom`: 여기서 출발해 활동 시작 시각까지 도착하는 구간(도착 기준).
    /// - 가는 편·오는 편의 이동수단은 따로 받는다(갈 땐 지하철, 올 땐 택시처럼 다른 경우가 흔하다).
    /// - `returnTo`: 활동 종료 시각에 출발해 여기로 돌아오는 구간(출발 기준, 버퍼 없음).
    /// - 반환값은 만든 활동의 id와 이동 구간 수. **id를 함께 돌려주는 이유**: 호출부가 `await`가 끝난 뒤
    ///   제목·시작시각으로 방금 만든 활동을 되찾다가, 같은 이름·같은 시각 활동이 이미 있으면 엉뚱한 쪽에
    ///   붙고 못 찾으면 연결이 통째로 빠졌다(식사 기록이 일정과 함께 안 지워지는 원인이었다).
    @discardableResult
    func addActivityWithTravel(title: String,
                               location: Place?,
                               startDate: Date,
                               endDate: Date,
                               travelFrom: Place?,
                               returnTo: Place?,
                               outboundMode: TransportMode,
                               returnMode: TransportMode,
                               bufferMinutes: Int,
                               notifyLeadMinutes: Int,
                               notifyEnabled: Bool = true,
                               syncToCalendar: Bool = true) async -> (activityId: UUID, travelLegs: Int) {
        var activity = ActivityBlock(title: title, location: location, startDate: startDate, endDate: endDate)
        activity.syncToCalendar = syncToCalendar
        activities.append(activity)
        activities.sort { $0.startDate < $1.startDate }
        saveActivities()
        if config.autoAddToCalendar && syncToCalendar {
            enqueueCalendarUpload(activityIDs: [activity.id])
        }

        // 이동 구간은 활동 장소를 알아야 만들 수 있다(목적지/출발지가 곧 활동 장소).
        guard let place = location else { return (activity.id, 0) }
        var made = 0
        if let from = travelFrom {
            await addEvent(title: title, origin: from, destination: place,
                           arrivalDate: startDate, mode: outboundMode,
                           bufferMinutes: bufferMinutes, notifyLeadMinutes: notifyLeadMinutes,
                           anchor: .arrival, linkedActivityId: activity.id,
                           notifyEnabled: notifyEnabled, syncToCalendar: syncToCalendar)
            made += 1
        }
        if let to = returnTo {
            await addEvent(title: "\(title) (복귀)", origin: place, destination: to,
                           arrivalDate: endDate, mode: returnMode,
                           bufferMinutes: 0, notifyLeadMinutes: notifyLeadMinutes,
                           anchor: .departure, linkedActivityId: activity.id,
                           notifyEnabled: notifyEnabled, syncToCalendar: syncToCalendar)
            made += 1
        }
        return (activity.id, made)
    }

    /// recurrenceId를 공유하는 ScheduledEvent(이동 구간)와 같이 묶여 일괄 삭제된다.
    @discardableResult
    func addRecurringActivities(title: String,
                                location: Place?,
                                rule: RecurrenceRule,
                                startHour: Int, startMinute: Int,
                                endHour: Int, endMinute: Int,
                                startDate: Date,
                                weeks: Int,
                                recurrenceId: UUID) async -> Int {
        let calendar = Calendar.current
        let cappedWeeks = min(max(weeks, 1), Self.maxRecurrenceWeeks)
        var created: [ActivityBlock] = []
        for day in rule.dates(from: startDate, weeks: cappedWeeks, calendar: calendar) {
            guard let start = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: day),
                  let end = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: day),
                  start > Date(), end > start else { continue }
            created.append(ActivityBlock(title: title, location: location, startDate: start, endDate: end,
                                         recurrenceId: recurrenceId))
        }
        guard !created.isEmpty else { return 0 }
        activities.append(contentsOf: created)
        activities.sort { $0.startDate < $1.startDate }
        saveActivities()
        if config.autoAddToCalendar {
            enqueueCalendarUpload(activityIDs: created.map(\.id))
        }
        return created.count
    }

    /// 활동 블록 정보를 수정한다(제목·장소·시간). 구글 캘린더에 이미 올라가 있었다면 지우고 새로 등록한다.
    func updateActivity(_ updated: ActivityBlock) {
        guard let idx = activities.firstIndex(where: { $0.id == updated.id }) else { return }
        let old = activities[idx]
        activities[idx] = updated
        activities.sort { $0.startDate < $1.startDate }
        saveActivities()
        if let gid = old.googleEventId {
            Task {
                await removeFromCalendar([gid])
                if let newGid = try? await gcal.createEvent(for: updated),
                   let i = activities.firstIndex(where: { $0.id == updated.id }) {
                    activities[i].googleEventId = newGid
                    saveActivities()
                }
            }
        }
    }

    /// 활동 블록의 시간을 옮기고/줄이고, 제목·장소를 바꾼다(주어진 것만).
    ///
    /// **묶인 이동 구간도 같이 맞춘다** — 시작을 옮기면 `moveActivity`가 양쪽 구간을 평행이동하고,
    /// 종료만 바뀌면(식사 시간이 길어지는 등) 복귀 구간의 출발 시각을 새 종료 시각에 다시 붙인다.
    /// 상세 화면에서 시각을 고쳤을 때 이동 블록이 제자리에 남던 문제를 막기 위함.
    @discardableResult
    func modifyActivity(id: UUID,
                        newTitle: String? = nil,
                        newStart: Date? = nil,
                        newEnd: Date? = nil,
                        newPlace: Place? = nil) -> Bool {
        guard let current = activities.first(where: { $0.id == id }) else { return false }
        var changed = false

        // 시작을 옮기는 건 "이동"이므로 moveActivity로 처리해야 딸린 이동 구간이 따라온다.
        if let newStart {
            let delta = Int(newStart.timeIntervalSince(current.startDate) / 60)
            if delta != 0 {
                moveActivity(current, byMinutes: delta, wholeSeries: false)
                changed = true
            }
        }
        // 위에서 옮겼을 수 있으니 최신 값을 다시 읽는다.
        guard var updated = activities.first(where: { $0.id == id }) else { return changed }
        let endBefore = updated.endDate
        if let newTitle, !newTitle.isEmpty, newTitle != updated.title { updated.title = newTitle; changed = true }
        if let newPlace, newPlace != updated.location { updated.location = newPlace; changed = true }
        if let newEnd, newEnd != updated.endDate, newEnd > updated.startDate { updated.endDate = newEnd; changed = true }
        if changed { updateActivity(updated) }

        // 종료 시각이 (시작 이동분과 별개로) 달라졌으면 복귀 구간을 새 종료 시각에 다시 맞춘다.
        if let newEnd, newEnd != endBefore {
            realignReturnLeg(activityId: id, departingAt: newEnd)
        }
        return changed
    }

    /// 활동에 묶인 복귀(출발 기준) 이동 구간의 출발 시각을 주어진 시각으로 옮긴다.
    private func realignReturnLeg(activityId: UUID, departingAt: Date) {
        guard let leg = events.first(where: { $0.linkedActivityId == activityId && $0.anchor == .departure }),
              let dep = leg.departureDate else { return }
        let delta = Int(departingAt.timeIntervalSince(dep) / 60)
        guard delta != 0 else { return }
        shiftEvent(leg.id, byMinutes: delta)
        save()
    }

    /// 이동 일정 하나의 제목·시각·장소·이동수단을 바꾼다(주어진 것만 — 나머지는 그대로 둔다).
    /// 시각을 바꾸면 이동시간을 다시 계산한다.
    @discardableResult
    func modifyEvent(id: UUID,
                     newTitle: String? = nil,
                     newAnchorDate: Date? = nil,
                     newAnchor: ScheduleAnchor? = nil,
                     newDestination: Place? = nil,
                     newOrigin: Place? = nil,
                     newMode: TransportMode? = nil) async -> Bool {
        guard let current = events.first(where: { $0.id == id }) else { return false }
        let anchor = newAnchor ?? current.anchor ?? .arrival
        // 기준이 되는 시각: 도착 기준이면 도착 시각, 출발 기준이면 출발 시각.
        let existingAnchorDate = anchor == .departure ? (current.departureDate ?? current.arrivalDate) : current.arrivalDate
        await updateEvent(id: id,
                          title: newTitle?.isEmpty == false ? newTitle! : current.title,
                          origin: newOrigin ?? current.origin ?? current.destination,
                          destination: newDestination ?? current.destination,
                          arrivalDate: newAnchorDate ?? existingAnchorDate,
                          mode: newMode ?? current.mode,
                          bufferMinutes: current.bufferMinutes,
                          notifyLeadMinutes: current.notifyLeadMinutes,
                          anchor: anchor)
        return true
    }

    /// 활동 블록을 삭제한다. 이 활동에 **묶여서 만들어진** 이동 구간(linkedActivityId)도 같이 지운다 —
    /// 활동만 사라지고 그 활동을 위한 이동만 덩그러니 남으면 시간표가 이상해진다.
    /// 반복 일정이 만든 구간은 명시적 연결이 없으므로 여기서 건드리지 않는다(반복 전체 삭제로 처리).
    func deleteActivity(_ activity: ActivityBlock) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
        let legs = events.filter { $0.linkedActivityId == activity.id }
        if !legs.isEmpty {
            for e in legs { if let nid = e.notificationId { notifications.cancel(id: nid) } }
            let legIDs = Set(legs.map { $0.id })
            events.removeAll { legIDs.contains($0.id) }
            save()
        }
        removeUpcomingMeals(eventIDs: Set(legs.map { $0.id }), activityIDs: [activity.id])
        let gids = ([activity.googleEventId] + legs.map { $0.googleEventId }).compactMap { $0 }
        if !gids.isEmpty { Task { await removeFromCalendar(gids) } }
    }

    private func saveActivities() {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(activities) {
            try? data.write(to: activitiesURL)
        }
    }

    private func loadActivities() {
        guard let data = try? Data(contentsOf: activitiesURL),
              let decoded = try? JSONDecoder().decode([ActivityBlock].self, from: data) else { return }
        activities = decoded
    }

    // MARK: - 식사 기록(be full sir)

    /// 식사 기록을 하나 추가한다. 최신 것이 앞에 오도록 정렬해 "최근 뭘 먹었나"를 바로 볼 수 있게 한다
    /// (추천 시 최근 이력을 참고하고, 같은 걸 연달아 추천하지 않기 위해 필요).
    @discardableResult
    func addMeal(category: MealCategory,
                 title: String,
                 place: Place? = nil,
                 estimatedCost: Int? = nil,
                 scheduledEventId: UUID? = nil,
                 activityId: UUID? = nil,
                 plannedAt: Date? = nil,
                 loggedAt: Date = Date()) -> MealLog {
        let meal = MealLog(category: category, title: title, place: place,
                           estimatedCost: estimatedCost, scheduledEventId: scheduledEventId,
                           activityId: activityId, plannedAt: plannedAt, loggedAt: loggedAt)
        meals.append(meal)
        meals.sort { $0.loggedAt > $1.loggedAt }
        saveMeals()
        return meal
    }

    func updateMeal(_ updated: MealLog) {
        guard let idx = meals.firstIndex(where: { $0.id == updated.id }) else { return }
        meals[idx] = updated
        meals.sort { $0.loggedAt > $1.loggedAt }
        saveMeals()
    }

    func deleteMeal(_ id: UUID) {
        meals.removeAll { $0.id == id }
        saveMeals()
    }


    /// 일정·활동을 지울 때, 거기 딸린 **아직 오지 않은** 식사 기록도 같이 지운다
    /// (이미 지난 식사는 실제로 먹은 기록이라 남긴다 — 판단은 `ScheduleLogic.mealsToRemove`).
    private func removeUpcomingMeals(eventIDs: Set<UUID> = [], activityIDs: Set<UUID> = []) {
        let doomed = ScheduleLogic.mealsToRemove(meals: meals, eventIDs: eventIDs,
                                                 activityIDs: activityIDs, now: Date())
        guard !doomed.isEmpty else { return }
        meals.removeAll { doomed.contains($0.id) }
        saveMeals()
    }

    /// 최근 식사 기록(기본 10건). AI 추천 프롬프트에 넣을 때 길이가 무한정 늘지 않도록 여기서 자른다.
    func recentMeals(limit: Int = 10) -> [MealLog] {
        Array(meals.prefix(limit))
    }

    private func saveMeals() {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(meals) {
            try? data.write(to: mealsURL)
        }
    }

    private func loadMeals() {
        guard let data = try? Data(contentsOf: mealsURL),
              let decoded = try? JSONDecoder().decode([MealLog].self, from: data) else { return }
        meals = decoded.sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - 즐겨찾기 장소

    func addFavorite(label: String, place: Place) {
        favorites.append(FavoritePlace(label: label, place: place))
        saveFavorites()
    }

    func deleteFavorite(_ id: UUID) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
    }

    private func saveFavorites() {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(favorites) {
            try? data.write(to: favoritesURL)
        }
    }

    private func loadFavorites() {
        guard let data = try? Data(contentsOf: favoritesURL),
              let decoded = try? JSONDecoder().decode([FavoritePlace].self, from: data) else { return }
        favorites = decoded
    }

    /// 동기화 동시 실행 방지 플래그(중복 일정 생성 방지). UI 스피너에도 사용.
    @Published private(set) var isSyncing = false

    var directions: DirectionsService { DirectionsService(config: config) }
    var placeSearch: PlaceSearch { PlaceSearch(config: config) }
    var gcal: GoogleCalendarService { GoogleCalendarService(clientID: config.googleClientID) }
    var googleConnected: Bool { config.hasGoogleCalendar && gcal.isConnected }

    // MARK: - 일정 충돌 검사

    /// 새 이동 구간과 시간이 겹치는 기존 블록.
    struct Conflict {
        let title: String
        let start: Date
        let end: Date
        /// 활동 블록이면 true, 이동 구간이면 false.
        let isActivity: Bool
    }

    /// 새 이동 구간(`departure`~`arrival`)과 시간이 겹치는 기존 블록을 찾는다.
    ///
    /// 두 가지는 겹쳐도 충돌로 보지 않는다:
    /// - **경계가 맞닿는 경우**(앞 블록 끝 == 새 블록 시작). 반복 일정이 만드는 "근무 끝나자마자
    ///   복귀 출발" 같은 정상적인 모양이 매번 걸리면 안 된다.
    /// - **같은 반복 그룹끼리**. 근무(09~18) 활동 블록 안에 점심 외출 이동 구간이 들어가는 건
    ///   이 앱이 의도적으로 만드는 모양이다.
    func conflicts(departure: Date, arrival: Date,
                   recurrenceId: UUID? = nil,
                   excludingEventId: UUID? = nil) -> [Conflict] {
        func overlaps(_ s: Date, _ e: Date) -> Bool { s < arrival && departure < e }
        func sameGroup(_ rid: UUID?) -> Bool {
            guard let rid, let recurrenceId else { return false }
            return rid == recurrenceId
        }
        var found: [Conflict] = []
        for a in activities where !sameGroup(a.recurrenceId) {
            guard overlaps(a.startDate, a.endDate) else { continue }
            found.append(Conflict(title: a.title, start: a.startDate, end: a.endDate, isActivity: true))
        }
        for e in events where e.id != excludingEventId && !sameGroup(e.recurrenceId) {
            // 이동시간을 계산 못한 구간은 차지하는 범위를 알 수 없어 검사에서 뺀다.
            guard let dep = e.departureDate, overlaps(dep, e.arrivalDate) else { continue }
            found.append(Conflict(title: e.title, start: dep, end: e.arrivalDate, isActivity: false))
        }
        return found.sorted { $0.start < $1.start }
    }


    /// 어떤 시간대 앞뒤로 사용자가 있을/가야 할 장소를 추정한다(판단은 `ScheduleLogic`이 한다).
    /// 식사 일정을 만들 때 출발지·복귀지를 미리 채워주는 데 쓴다.
    func surroundingPlaces(start: Date, end: Date) -> (before: (place: Place, label: String)?,
                                                       after: (place: Place, label: String)?) {
        ScheduleLogic.surroundingPlaces(start: start, end: end,
                                        activities: activities, events: events,
                                        home: favorites.first { $0.label == "집" }?.place)
    }

    /// 세 수단의 이동시간을 한 번에 구한다(조회 전용).
    func travelEstimates(from origin: Place, to destination: Place) async -> [TransportMode: TravelEstimate] {
        await directions.estimateAll(
            from: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude),
            to: CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude))
    }

    /// 이동시간만 조회한다(일정을 만들기 전에 충돌 여부를 먼저 판단할 때). 실패하면 nil.
    /// 여기서 받은 값을 `addEvent(travelSecondsHint:)`로 넘기면 생성할 때 다시 조회하지 않는다.
    func travelSeconds(from origin: Place, to destination: Place, mode: TransportMode) async -> TimeInterval? {
        await directions.estimate(
            mode,
            from: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude),
            to: CLLocationCoordinate2D(latitude: destination.latitude, longitude: destination.longitude)).duration
    }

    // MARK: - 일정 추가/갱신

    /// 이동시간을 계산하고, 출발/알림 시각을 산정한 뒤 알림을 예약하고 저장한다.
    /// `anchor`가 `.arrival`이면 `anchorDate`는 "도착 시각"(출발을 역산), `.departure`면
    /// "출발 시각"(도착을 순산, 예: 퇴근/귀가) — 퇴근길처럼 출발 시각이 우선인 경우 버퍼가
    /// 의미 없어(도착 여유를 둘 필요가 없음) `.departure`에서는 bufferMinutes를 항상 0으로 둔다.
    /// 방금 만든 일정을 그대로 돌려준다 — 호출자가 제목·목적지로 되찾으면 같은 이름의 더 늦은
    /// 회차(도착일순 정렬이라 `.last`가 집는 쪽)를 집는다(2026-09-16 결함 J). @discardableResult인
    /// 이유: 다리 생성·수동 추가처럼 되찾을 일 없는 호출자가 대부분이라 반환 강제가 소음이 되고,
    /// 반환을 써야 하는 호출자(executeCreateSchedule)가 쓰는지는 드라이버 J절이 지킨다.
    @discardableResult
    func addEvent(title: String,
                  origin: Place,
                  destination: Place,
                  arrivalDate: Date,
                  mode: TransportMode,
                  bufferMinutes: Int,
                  notifyLeadMinutes: Int,
                  anchor: ScheduleAnchor = .arrival,
                  travelSecondsHint: TimeInterval? = nil,
                  linkedActivityId: UUID? = nil,
                  notifyEnabled: Bool = true,
                  syncToCalendar: Bool = true) async -> ScheduledEvent {
        var event = ScheduledEvent(title: title,
                                   origin: origin,
                                   destination: destination,
                                   arrivalDate: arrivalDate,
                                   mode: mode,
                                   bufferMinutes: anchor == .departure ? 0 : bufferMinutes,
                                   notifyLeadMinutes: notifyLeadMinutes)
        event.linkedActivityId = linkedActivityId
        event.notifyEnabled = notifyEnabled
        event.syncToCalendar = syncToCalendar
        // 호출부가 충돌 검사를 위해 이미 이동시간을 조회했다면 그 값을 쓴다(외부 API 중복 호출 방지).
        switch (anchor, travelSecondsHint) {
        case (.arrival, let hint?):
            applyCachedArrivalEstimate(to: &event, travelSeconds: hint, source: "조회됨")
        case (.departure, let hint?):
            applyCachedDepartureEstimate(to: &event, departureDate: arrivalDate, travelSeconds: hint, source: "조회됨")
        case (.arrival, nil): await applyEstimate(to: &event)
        case (.departure, nil): await applyDepartureAnchoredEstimate(to: &event, departureDate: arrivalDate)
        }
        events.append(event)
        events.sort { $0.arrivalDate < $1.arrivalDate }
        save()
        if config.autoAddToCalendar {
            enqueueCalendarUpload(eventIDs: [event.id])
        }
        return event
    }


    /// 반복 일정 한 구간(leg)의 시각 기준.
    /// `.arrival`: "이 시각까지 도착"(기존 방식) — 출발 시각을 역산.
    /// `.departure`: "이 시각에 출발"(복귀/귀가용) — 도착 시각을 순산(출발 + 이동시간).
    enum RecurrenceAnchor {
        case arrival(hour: Int, minute: Int)
        case departure(hour: Int, minute: Int)
    }

    /// 같은 출발지·목적지로 여러 요일에 반복되는 일정 한 구간을 한 번에 생성한다(예: "매주 평일 9시 도착").
    /// 출퇴근처럼 여러 구간(등원+복귀+점심 이동 등)을 한 묶음으로 삭제하려면 같은 `recurrenceId`를 넘긴다
    /// (기본값은 새로 생성 — 호출부가 반환받아 이후 구간 호출에 재사용).
    /// 남용 방지로 `maxRecurrenceWeeks`까지만 생성한다 — 숫자를 여기 적어두면 상수와 어긋난다
    /// (실제로 12주로 적혀 있다가 상수가 26으로 바뀐 뒤에도 남아, SPEC이 이 주석을 옮겨 적었다).
    /// 반환값은 (실제로 생성된 일정 수, 사용된 recurrenceId).
    @discardableResult
    func addRecurringEvents(title: String,
                            origin: Place,
                            destination: Place,
                            rule: RecurrenceRule,
                            anchor: RecurrenceAnchor,
                            startDate: Date,
                            weeks: Int,
                            mode: TransportMode,
                            bufferMinutes: Int,
                            notifyLeadMinutes: Int,
                            recurrenceId: UUID = UUID()) async -> (count: Int, recurrenceId: UUID) {
        let calendar = Calendar.current
        let cappedWeeks = min(max(weeks, 1), Self.maxRecurrenceWeeks)
        let (hour, minute): (Int, Int) = {
            switch anchor {
            case .arrival(let h, let m): return (h, m)
            case .departure(let h, let m): return (h, m)
            }
        }()
        var created: [ScheduledEvent] = []
        // API 사용량 절약: 이동시간은 첫 회차만 실제로 조회하고, 나머지 회차는 그 값을 그대로 복사한다
        // (같은 시간대·같은 경로라 대략 비슷하다고 가정 — 정확한 값은 출발이 임박했을 때
        // refreshUpcomingEstimates()가 그 회차만 다시 조회해 갱신한다).
        var cachedTravelSeconds: TimeInterval?
        var firstAttempted = false
        for day in rule.dates(from: startDate, weeks: cappedWeeks, calendar: calendar) {
            guard let anchorTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  anchorTime > Date() else { continue }
            var event = ScheduledEvent(title: title, origin: origin, destination: destination,
                                       arrivalDate: anchorTime, mode: mode, bufferMinutes: bufferMinutes,
                                       notifyLeadMinutes: notifyLeadMinutes)
            event.recurrenceId = recurrenceId
            switch anchor {
            case .arrival:
                event.anchor = .arrival
                if !firstAttempted {
                    await applyEstimate(to: &event)
                    cachedTravelSeconds = event.travelSeconds
                    firstAttempted = true
                } else if let seconds = cachedTravelSeconds {
                    applyCachedArrivalEstimate(to: &event, travelSeconds: seconds)
                }
            case .departure:
                event.anchor = .departure
                if !firstAttempted {
                    await applyDepartureAnchoredEstimate(to: &event, departureDate: anchorTime)
                    cachedTravelSeconds = event.travelSeconds
                    firstAttempted = true
                } else if let seconds = cachedTravelSeconds {
                    applyCachedDepartureEstimate(to: &event, departureDate: anchorTime, travelSeconds: seconds)
                }
            }
            created.append(event)
        }
        guard !created.isEmpty else { return (0, recurrenceId) }
        events.append(contentsOf: created)
        events.sort { $0.arrivalDate < $1.arrivalDate }
        save()
        if config.autoAddToCalendar {
            // 예전엔 여기서 원격 등록이 끝날 때까지 기다렸다 — 회차마다 순차 1건이라 58회차면
            // 사용자가 그걸 다 기다렸다. 이제 pending만 찍고 돌아가고 업로드는 뒤에서 돈다.
            enqueueCalendarUpload(eventIDs: created.map(\.id))
        }
        // 반복 일정은 회차 수가 많아 그냥 두면 iOS의 64건 제한에 걸려 뒤쪽 회차 알림이 조용히
        // 버려진다 — 가까운 것부터 다시 채워 넣는다(자세한 내용은 아래 함수 주석).
        rescheduleNearestNotifications()
        return (created.count, recurrenceId)
    }

    /// recurrenceId로 반복 그룹의 이동 구간을 도착 순으로 돌려준다 — 멤버십·정렬 판단의 단일 출처(계약 5).
    func recurringSeries(_ recurrenceId: UUID) -> [ScheduledEvent] {
        events.filter { $0.recurrenceId == recurrenceId }.sorted { $0.arrivalDate < $1.arrivalDate }
    }

    /// 반복 일정 그룹 전체를 한 번에 삭제한다(이동 구간 + 활동 블록 + 캘린더·알림 포함).
    func deleteRecurringSeries(_ recurrenceId: UUID) {
        let group = recurringSeries(recurrenceId)
        for e in group {
            if let nid = e.notificationId { notifications.cancel(id: nid) }
        }
        events.removeAll { $0.recurrenceId == recurrenceId }
        save()

        let activityGroup = activities.filter { $0.recurrenceId == recurrenceId }
        activities.removeAll { $0.recurrenceId == recurrenceId }
        saveActivities()
        removeUpcomingMeals(eventIDs: Set(group.map { $0.id }),
                            activityIDs: Set(activityGroup.map { $0.id }))

        let gids = group.compactMap { $0.googleEventId } + activityGroup.compactMap { $0.googleEventId }
        if !gids.isEmpty {
            Task { await removeFromCalendar(gids) }
        }
    }

    /// 반복 일정 그룹 전체의 이동수단·버퍼·알림 리드타임을 바꾸고 이동시간을 다시 계산한다(새로
    /// 만들지 않고 기존 그룹을 그대로 갱신 — AI 채팅에서 "방금 만든 일정 자동차로 바꿔줘" 같은
    /// 수정 요청을 다시 create로 처리하면 중복 생성되므로 이 경로로 처리한다).
    /// 반환값은 갱신된 일정 수(0이면 해당 recurrenceId 없음).
    @discardableResult
    func updateRecurringSeries(_ recurrenceId: UUID,
                               mode: TransportMode?,
                               bufferMinutes: Int?,
                               notifyLeadMinutes: Int?) async -> Int {
        let ids = recurringSeries(recurrenceId).map(\.id)
        guard !ids.isEmpty else { return 0 }

        // API 절약을 위해 첫 회차만 실제로 새 이동시간을 조회하고 나머지는 그 값을 복사한다
        // (addRecurringEvents와 같은 전략).
        var cachedTravelSeconds: TimeInterval?
        var firstDone = false
        for id in ids {
            guard let idx = events.firstIndex(where: { $0.id == id }) else { continue }
            var event = events[idx]
            if let mode { event.mode = mode }
            // 출발 기준(귀가 등) 구간은 버퍼 개념이 없다 — 항상 0으로 강제. 음수 버퍼는 매 회차
            // 늦게 출발하게 만들므로, 수동 조정(adjustBuffer)과 같은 상하한으로 묶는다.
            if let bufferMinutes { event.bufferMinutes = (event.anchor == .departure) ? 0 : Self.clampBuffer(bufferMinutes) }
            if let notifyLeadMinutes { event.notifyLeadMinutes = Self.clampNotifyLead(notifyLeadMinutes) }
            switch event.anchor ?? .arrival {
            case .arrival:
                if !firstDone {
                    await applyEstimate(to: &event)
                    cachedTravelSeconds = event.travelSeconds
                    firstDone = true
                } else if let secs = cachedTravelSeconds {
                    applyCachedArrivalEstimate(to: &event, travelSeconds: secs)
                }
            case .departure:
                if let dep = event.departureDate {
                    if !firstDone {
                        await applyDepartureAnchoredEstimate(to: &event, departureDate: dep)
                        cachedTravelSeconds = event.travelSeconds
                        firstDone = true
                    } else if let secs = cachedTravelSeconds {
                        applyCachedDepartureEstimate(to: &event, departureDate: dep, travelSeconds: secs)
                    }
                }
            }
            // await(이동시간 조회) 사이 동기화·삭제로 배열이 바뀔 수 있으니 쓸 때 id로 다시 찾는다.
            guard let writeIdx = events.firstIndex(where: { $0.id == id }) else { continue }
            events[writeIdx] = event
        }
        events.sort { $0.arrivalDate < $1.arrivalDate }
        save()

        // 구글 캘린더에 이미 올라간 것들은 지우고 갱신본으로 다시 등록.
        // 계정이 연결돼 있을 때만 건드린다 — 미연결이면 원격 삭제가 어차피 실패하는데,
        // 로컬 gid만 비워버리면 나중에 다시 연결했을 때 매핑을 잃어 동기화가 중복을 만든다.
        if googleConnected {
            // gid를 먼저 한 번에 모아 삭제도 한 번에 건넨다 — 건별이면 회차 수만큼 묘비 파일을
            // 쓰고 원격 삭제를 하나씩 기다렸다. 로컬 gid는 삭제 요청 *전에* 비운다: nil인 채로
            // 기다리는 사이 동기화가 돌면 "원격에 없는 gid"를 보고 회차를 통째로 지울 수 있는데,
            // 묘비는 되살림만 막을 뿐 이 제거(syncWithGoogle 1단계)는 못 막는다.
            let gids = ids.compactMap { id in events.first(where: { $0.id == id })?.googleEventId }
            for id in ids {
                if let i = events.firstIndex(where: { $0.id == id }) { events[i].googleEventId = nil }
            }
            await removeFromCalendar(gids)
            if config.autoAddToCalendar {
                enqueueCalendarUpload(eventIDs: ids)
            }
            save()
        }
        // 수정 뒤에도 iOS 알림 64건 한도는 그대로다 — 생성 경로와 같은 이유로 가까운 것부터 다시 채운다.
        rescheduleNearestNotifications()
        return ids.count
    }

    // MARK: - 캘린더 업로드(등록의 임계 경로 밖)

    /// 캘린더 업로드 전용 직렬 작업. 앞 작업을 기다려 두 업로드가 서로 끼어들지 않게 한다.
    private var calendarUploadTask: Task<Void, Never>?

    /// 캘린더 업로드를 등록 **뒤로** 미룬다. 이 함수가 돌아온 시점에 로컬 등록은 이미 끝나 있다.
    ///
    /// **왜 미루나.** 업로드는 건마다 원격 1건이라, 58건짜리 반복을 만들면 사용자가 그걸 다
    /// 기다렸다. 게다가 계정이 연결돼 있지 않으면 `createEvent`가 건마다 로그인 화면을 띄우려
    /// 들었고(`accessToken(allowInteractive: true)`), 전부 실패하는데 그 실패가 조용히 버려졌다.
    ///
    /// **왜 `Task { try? await ... }`가 아닌가.** 실패를 그냥 버리면 빠른 "등록 완료"만 남고
    /// 캘린더가 빈 것을 아무도 모른다 — 지금 결함이 더 나빠질 뿐이다. 그래서 결과를 레코드에
    /// `pending`/`failed`로 남기고(디스크에도), 상세 화면과 설정 화면이 그걸 읽는다.
    ///
    /// **왜 순차인가.** ① 구글은 사용자당 쓰기 할당량이 있어 병렬로 밀면 429/403이 돌아오는데,
    /// 지금 구조에서 그건 재시도가 아니라 `failed` 기록이 된다 — 느린 성공을 보이는 실패로
    /// 바꾸는 셈이다. ② `Store`는 `@MainActor`라 배열 쓰기는 어차피 메인에서만 일어나고,
    /// TaskGroup은 `await` 사이 끼어드는 지점만 늘린다(이 파일이 반복해서 고쳐온 H1 위험).
    /// ③ 임계 경로에서 빠진 지금, 순차 업로드의 대기 시간은 아무도 기다리지 않는다.
    func enqueueCalendarUpload(eventIDs: [UUID] = [], activityIDs: [UUID] = []) {
        guard googleConnected else { return }
        // 요소 단위로 여러 번 고치면 didSet(daysWithSchedule 재계산)이 매번 돈다 —
        // 복사본에서 다 고치고 한 번만 대입한다(rescheduleNearestNotifications와 같은 이유).
        var evs = events
        var evChanged = false
        for id in eventIDs {
            guard let i = evs.firstIndex(where: { $0.id == id }),
                  evs[i].wantsCalendarSync, evs[i].googleEventId == nil else { continue }
            evs[i].calendarUpload = .pending
            evChanged = true
        }
        if evChanged { events = evs; save() }   // pending을 먼저 디스크에 — 여기서 죽어도 "안 올라감"이 남는다

        var acts = activities
        var acChanged = false
        for id in activityIDs {
            guard let i = acts.firstIndex(where: { $0.id == id }),
                  acts[i].wantsCalendarSync, acts[i].googleEventId == nil else { continue }
            acts[i].calendarUpload = .pending
            acChanged = true
        }
        if acChanged { activities = acts; saveActivities() }

        guard evChanged || acChanged else { return }
        // 클로저가 잡아갈 값은 불변으로 고정한다(escaping 클로저의 var 캡처를 피한다).
        let queuedEvents = evChanged ? eventIDs : []
        let queuedActivities = acChanged ? activityIDs : []
        let previous = calendarUploadTask
        calendarUploadTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            await self.pushToCalendar(eventIDs: queuedEvents)
            await self.pushActivitiesToCalendar(queuedActivities)
        }
    }

    /// 아직 캘린더에 못 올린 항목 수(대기 중, 실패). 설정 화면 한 줄의 단일 출처 —
    /// 58건이 한꺼번에 실패하면 상세를 하나씩 열어 보는 방식으로는 아무도 못 본다.
    var calendarUploadPendingCount: Int {
        events.filter { $0.calendarUpload == .pending }.count
            + activities.filter { $0.calendarUpload == .pending }.count
    }
    var calendarUploadFailedCount: Int {
        events.filter { $0.calendarUpload == .failed }.count
            + activities.filter { $0.calendarUpload == .failed }.count
    }

    /// 실패로 기록된 항목만 다시 큐에 넣는다(설정 화면의 "다시 시도").
    func retryFailedCalendarUploads() {
        enqueueCalendarUpload(eventIDs: events.filter { $0.calendarUpload == .failed }.map(\.id),
                              activityIDs: activities.filter { $0.calendarUpload == .failed }.map(\.id))
    }

    /// 일정들을 구글 캘린더에 등록하고 googleEventId를 저장한다(수동 버튼·큐 공용).
    /// 회차마다 save()하면 회차 수만큼 전체 배열을 디스크에 쓴다(34회차 등록이 눈에 띄게 느렸던
    /// 실측의 한쪽 축) — 등록 성공분만 메모리에 반영하고 저장은 마지막에 한 번. 도중에 죽으면 그
    /// 호출의 gid 매핑을 잃어 다음 동기화가 중복을 가져오지만, 반복 등록은 구간(가는 편·오는 편
    /// 등)마다 따로 호출·저장하므로 손실은 최대 한 구간에 묶인다.
    func pushToCalendar(eventIDs: [UUID]) async {
        // 예전엔 `config.hasGoogleCalendar`(= 클라이언트 ID가 설정돼 있나)만 봤다. 그 값은 항상
        // 참이라, 계정이 연결되지 않은 기기에서도 건마다 로그인 시도 + 네트워크 호출이 나갔고
        // 전부 실패했다. 물어야 할 것은 "계정이 실제로 연결돼 있나"다.
        guard googleConnected else { return }
        var changed = false
        for eventID in eventIDs {
            guard let idx = events.firstIndex(where: { $0.id == eventID }),
                  events[idx].wantsCalendarSync else { continue }   // "이건 캘린더에 올리지 마" 존중
            // 이미 gid가 있으면 다시 올리지 않는다 — 큐에 두 번 들어간 건을 또 만들면 중복이 된다.
            guard events[idx].googleEventId == nil else { continue }
            do {
                let gid = try await gcal.createEvent(for: events[idx])
                // await 뒤 배열이 바뀌었을 수 있으니 다시 찾는다 — 없어진 회차는 건너뛴다.
                guard let i = events.firstIndex(where: { $0.id == eventID }) else { continue }
                events[i].googleEventId = gid
                events[i].calendarUpload = nil      // 성공의 단일 출처는 gid다(계약 5)
                // 동기화가 먼저 같은 gid를 가져와 중복이 생겼다면 그쪽을 제거(알림도 취소).
                for dup in events where dup.googleEventId == gid && dup.id != eventID {
                    if let nid = dup.notificationId { notifications.cancel(id: nid) }
                }
                events.removeAll { $0.googleEventId == gid && $0.id != eventID }
                changed = true
            } catch {
                // 실패를 레코드에 남긴다. 예전엔 여기서 조용히 버려서, 캘린더엔 아무것도 없는데
                // 사용자는 "등록 완료"만 보고 이유를 알 길이 없었다.
                if let i = events.firstIndex(where: { $0.id == eventID }) {
                    events[i].calendarUpload = .failed
                    changed = true
                }
            }
        }
        if changed { save() }
    }

    /// 활동 블록을 구글 캘린더에 등록한다.
    /// 생성 경로 세 곳(단발·이동 묶음·반복)이 거의 같은 인라인 블록을 따로 갖고 있어, 실패 기록
    /// 같은 규칙이 한쪽에만 생기기 쉬웠다 — 하나로 합친다(계약 5).
    func pushActivitiesToCalendar(_ activityIDs: [UUID]) async {
        guard googleConnected else { return }
        var changed = false
        for activityID in activityIDs {
            guard let idx = activities.firstIndex(where: { $0.id == activityID }),
                  activities[idx].wantsCalendarSync,
                  activities[idx].googleEventId == nil else { continue }
            do {
                let gid = try await gcal.createEvent(for: activities[idx])
                guard let i = activities.firstIndex(where: { $0.id == activityID }) else { continue }
                activities[i].googleEventId = gid
                activities[i].calendarUpload = nil
                changed = true
            } catch {
                if let i = activities.firstIndex(where: { $0.id == activityID }) {
                    activities[i].calendarUpload = .failed
                    changed = true
                }
            }
        }
        if changed { saveActivities() }
    }

    /// 일정 하나만 등록하는 진입점(수동 버튼·단발 생성) — 묶음 등록의 회차 1짜리 호출이다.
    func pushToCalendar(eventID: UUID) async {
        await pushToCalendar(eventIDs: [eventID])
    }

    /// 기존 일정의 모든 필드를 수정하고, 이동시간·출발시각·알림을 다시 계산한다.
    func updateEvent(id: UUID,
                     title: String,
                     origin: Place,
                     destination: Place,
                     arrivalDate: Date,
                     mode: TransportMode,
                     bufferMinutes: Int,
                     notifyLeadMinutes: Int,
                     anchor: ScheduleAnchor = .arrival,
                     notifyEnabled: Bool? = nil,
                     syncToCalendar: Bool? = nil) async {
        guard let idx = events.firstIndex(where: { $0.id == id }) else { return }
        var event = events[idx]
        event.title = title
        event.origin = origin
        event.destination = destination
        event.arrivalDate = arrivalDate
        event.mode = mode
        event.bufferMinutes = anchor == .departure ? 0 : bufferMinutes
        event.notifyLeadMinutes = notifyLeadMinutes
        if let notifyEnabled { event.notifyEnabled = notifyEnabled }
        if let syncToCalendar { event.syncToCalendar = syncToCalendar }
        switch anchor {
        case .arrival: await applyEstimate(to: &event)
        case .departure: await applyDepartureAnchoredEstimate(to: &event, departureDate: arrivalDate)
        }
        // await(이동시간 조회) 사이 동기화·삭제로 배열이 바뀔 수 있으니 쓸 때 id로 다시 찾는다.
        guard let writeIdx = events.firstIndex(where: { $0.id == id }) else { return }
        events[writeIdx] = event
        events.sort { $0.arrivalDate < $1.arrivalDate }
        save()
        // 캘린더에 등록돼 있던 일정이면 옛 이벤트 삭제 후 갱신본으로 다시 등록.
        // updateRecurringSeries와 같은 이유로 연결돼 있을 때만 gid를 건드린다.
        if googleConnected {
            if let oldGID = event.googleEventId {
                await removeFromCalendar([oldGID])
                if let i = events.firstIndex(where: { $0.id == id }) { events[i].googleEventId = nil }
            }
            if config.autoAddToCalendar { enqueueCalendarUpload(eventIDs: [id]) }
        }
    }

    /// 출발지·목적지·수단으로 이동시간을 계산해 출발시각/알림을 세팅한다(기존 알림은 갱신).
    private func applyEstimate(to event: inout ScheduledEvent) async {
        event.anchor = .arrival
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        event.notificationId = nil
        event.travelSeconds = nil
        event.departureDate = nil
        guard let o = event.origin else { return }
        let estimate = await directions.estimate(
            event.mode,
            from: CLLocationCoordinate2D(latitude: o.latitude, longitude: o.longitude),
            to: CLLocationCoordinate2D(latitude: event.destination.latitude, longitude: event.destination.longitude))
        guard let seconds = estimate.duration else { return }
        event.travelSeconds = seconds
        // @MX:DEBT: 출발시각 산식(도착 − 이동 − 버퍼)이 이 파일 세 곳에 복제돼 있다 —
        //           여기, `adjustBuffer`, `applyCachedArrivalEstimate`.
        // @MX:CEILING: 세 식이 지금은 글자 그대로 동일하다. 버퍼·반올림·타임존 의미가 달라지는 순간 깨진다.
        // @MX:UPGRADE: 버퍼 의미를 바꾸거나 네 번째 호출처가 생기면 Store의 함수 하나로 합친다 (CLAUDE.md 계약 5).
        let departure = event.arrivalDate.addingTimeInterval(-seconds - Double(event.bufferMinutes) * 60)
        event.departureDate = departure
        event.notificationId = scheduleDepartureNotification(
            for: event, departure: departure, travelSeconds: seconds, source: estimate.source)
    }

    /// 출발 시각을 고정하고(예: 근무 종료 후 복귀) 도착 시각을 순산한다(출발 + 이동시간).
    /// `applyEstimate`(도착 역산)의 반대 방향 버전 — 데이터 모델은 동일(arrivalDate/departureDate 둘 다 채움).
    private func applyDepartureAnchoredEstimate(to event: inout ScheduledEvent, departureDate: Date) async {
        event.anchor = .departure
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        event.notificationId = nil
        event.travelSeconds = nil
        event.departureDate = departureDate
        guard let o = event.origin else { return }
        let estimate = await directions.estimate(
            event.mode,
            from: CLLocationCoordinate2D(latitude: o.latitude, longitude: o.longitude),
            to: CLLocationCoordinate2D(latitude: event.destination.latitude, longitude: event.destination.longitude))
        guard let seconds = estimate.duration else { return }
        event.travelSeconds = seconds
        event.arrivalDate = departureDate.addingTimeInterval(seconds + Double(event.bufferMinutes) * 60)
        event.notificationId = scheduleDepartureNotification(
            for: event, departure: departureDate, travelSeconds: seconds, source: estimate.source)
    }

    /// 출발 알림을 예약하고 id를 돌려준다(꺼져 있거나 과거면 nil).
    /// 예전엔 이 6줄이 추정 함수 4곳에 그대로 복사돼 있어, 알림 끄기 같은 변경을 넣으려면
    /// 네 군데를 똑같이 고쳐야 했다 — 한 곳으로 모았다.
    private func scheduleDepartureNotification(for event: ScheduledEvent,
                                               departure: Date,
                                               travelSeconds: TimeInterval,
                                               source: String) -> String? {
        guard event.wantsNotification else { return nil }
        let estimate = TravelEstimate(mode: event.mode, duration: travelSeconds, distance: nil, source: source)
        return notifications.schedule(
            title: "🚶 \(event.title) — 출발 준비",
            body: notificationBody(for: event, estimate: estimate),
            at: departure.addingTimeInterval(-Double(event.notifyLeadMinutes) * 60))
    }

    func notificationBody(for event: ScheduledEvent, estimate: TravelEstimate) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h시 m분"
        let dep = event.departureDate.map { f.string(from: $0) } ?? "-"
        return "\(event.destination.name)까지 \(event.mode.title) \(estimate.durationText). \(dep)에 출발하세요."
    }

    // MARK: - 드래그로 시간 재조정(일간 시간표)

    /// 활동 블록의 시작·종료를 그대로 분 단위로 옮긴다(이동시간 재계산 없음, 순수 이동).
    /// 반복 그룹 전체를 옮기면(wholeSeries) 매 회차 + 그 회차에 연계된 이동 구간까지 같이 옮긴다.
    func moveActivity(_ activity: ActivityBlock, byMinutes minutes: Int, wholeSeries: Bool) {
        guard minutes != 0 else { return }
        let targets: [ActivityBlock]
        if wholeSeries, let rid = activity.recurrenceId {
            targets = activities.filter { $0.recurrenceId == rid }
        } else {
            targets = [activity]
        }
        // 연계된 이동 구간(같은 날·같은 반복그룹에서 이 활동 장소로 오가는 구간)을 먼저(원래 날짜 기준으로) 찾아 옮긴다.
        for a in targets {
            let (arrivalLeg, departureLeg) = linkedLegs(for: a)
            if let arrivalLeg { shiftEvent(arrivalLeg.id, byMinutes: minutes) }
            if let departureLeg { shiftEvent(departureLeg.id, byMinutes: minutes) }
        }
        for t in targets {
            guard let idx = activities.firstIndex(where: { $0.id == t.id }) else { continue }
            activities[idx].startDate = activities[idx].startDate.addingTimeInterval(Double(minutes) * 60)
            activities[idx].endDate = activities[idx].endDate.addingTimeInterval(Double(minutes) * 60)
        }
        saveActivities()
        save()   // shiftEvent는 저장하지 않는다(아래 주석) — 옮긴 이동 구간을 여기서 한 번에 저장.
    }

    /// 이동 구간(ScheduledEvent) 블록 자체를 드래그했을 때: 활동은 그대로 두고, 활동과 맞닿은 쪽
    /// (도착형=도착시각, 출발형=출발시각)은 고정한 채 반대쪽(자유단)을 버퍼로 흡수해 옮긴다.
    /// 반복 그룹 전체(wholeSeries)면 "같은 역할"(같은 anchor + 같은 목적지/출발지)의 회차 전부에 적용.
    func adjustTravelLeg(_ event: ScheduledEvent, byMinutes minutes: Int, wholeSeries: Bool) {
        guard minutes != 0 else { return }
        let anchorKind = event.anchor ?? .arrival
        let roleKey = anchorKind == .arrival ? event.destination.name : (event.origin?.name ?? "")
        let targets: [ScheduledEvent]
        if wholeSeries, let rid = event.recurrenceId {
            targets = events.filter {
                $0.recurrenceId == rid && ($0.anchor ?? .arrival) == anchorKind
                    && (anchorKind == .arrival ? $0.destination.name : ($0.origin?.name ?? "")) == roleKey
            }
        } else {
            targets = [event]
        }
        for t in targets {
            if anchorKind == .departure {
                // 출발 기준 이동 구간은 버퍼가 없다(강제로 0) — 이 블록을 직접 드래그하면
                // 버퍼를 조정하는 게 아니라 출발 시각 자체를 옮긴다(도착은 이동시간만큼 따라감).
                shiftEvent(t.id, byMinutes: minutes)
            } else {
                adjustBuffer(t.id, deltaMinutes: minutes)
            }
        }
        save()   // 회차마다 저장하면(26주 반복이면 130번) 드래그를 놓을 때 눈에 띄게 멈춘다 — 한 번만.
    }

    /// 같은 반복 그룹(activity의 recurrenceId)에서 그 활동과 같은 날, 그 활동 장소로 향하는(도착형)/
    /// 그 활동 장소에서 출발하는(출발형) 이동 구간을 찾는다. 명시적 링크 필드 없이 날짜+장소로 추정한다.
    private func linkedLegs(for activity: ActivityBlock) -> (arrival: ScheduledEvent?, departure: ScheduledEvent?) {
        // 명시적으로 묶인 구간이 있으면 그걸 쓴다(수동으로 활동+이동을 같이 만든 경우).
        let explicit = events.filter { $0.linkedActivityId == activity.id }
        if !explicit.isEmpty {
            return (explicit.first { ($0.anchor ?? .arrival) == .arrival },
                    explicit.first { $0.anchor == .departure })
        }
        // 옛 반복 일정 데이터는 명시적 연결이 없어 날짜+장소로 추정한다.
        guard let rid = activity.recurrenceId, let placeName = activity.location?.name else { return (nil, nil) }
        let cal = Calendar.current
        let sameDay = events.filter { $0.recurrenceId == rid && cal.isDate($0.arrivalDate, inSameDayAs: activity.startDate) }
        let arrivalLeg = sameDay.first { ($0.anchor ?? .arrival) == .arrival && $0.destination.name == placeName }
        let departureLeg = sameDay.first { $0.anchor == .departure && $0.origin?.name == placeName }
        return (arrivalLeg, departureLeg)
    }

    /// 이동시간 재계산 없이 도착·출발 시각을 그대로 분 단위 평행이동한다(알림도 같이 옮김).
    /// 반복 그룹을 옮길 때 회차 수만큼 반복 호출되므로 여기서는 저장하지 않는다 — 호출부가
    /// 루프를 다 돈 뒤 save()를 한 번만 부른다(회차마다 JSON 인코딩+디스크 쓰기를 하면 느림).
    private func shiftEvent(_ id: UUID, byMinutes minutes: Int) {
        guard let idx = events.firstIndex(where: { $0.id == id }) else { return }
        if let nid = events[idx].notificationId { notifications.cancel(id: nid) }
        events[idx].arrivalDate = events[idx].arrivalDate.addingTimeInterval(Double(minutes) * 60)
        if let dep = events[idx].departureDate {
            events[idx].departureDate = dep.addingTimeInterval(Double(minutes) * 60)
        }
        rescheduleNotification(at: idx)
    }

    /// 활동과 맞닿은 쪽(도착형=도착시각, 출발형=출발시각)은 고정하고 버퍼만 바꿔 반대쪽 자유단을 옮긴다.
    /// shiftEvent와 마찬가지로 저장은 호출부가 루프를 마친 뒤 한 번만 한다.
    private func adjustBuffer(_ id: UUID, deltaMinutes: Int) {
        guard let idx = events.firstIndex(where: { $0.id == id }) else { return }
        var event = events[idx]
        guard let travel = event.travelSeconds else { return }   // 이동시간 미계산 상태면 조정 불가
        let newBuffer: Int
        switch event.anchor ?? .arrival {
        case .arrival:
            // 자유단 = 출발시각(= 도착 - 이동 - 버퍼). 드래그로 출발을 deltaMinutes만큼 옮기려면
            // 버퍼는 반대로 변한다(출발을 늦추려면 버퍼가 줄어야 함).
            newBuffer = Self.clampBuffer(event.bufferMinutes - deltaMinutes)
            event.bufferMinutes = newBuffer
            // @MX:DEBT: 출발시각 산식 3중 복제 — 전체 내용은 `applyEstimate(to:)`의 마커 참고.
            event.departureDate = event.arrivalDate.addingTimeInterval(-travel - Double(newBuffer) * 60)
        case .departure:
            // 자유단 = 도착시각(= 출발 + 이동 + 버퍼). 도착을 deltaMinutes만큼 늦추려면 버퍼가 늘어야 함.
            guard let dep = event.departureDate else { return }
            newBuffer = Self.clampBuffer(event.bufferMinutes + deltaMinutes)
            event.bufferMinutes = newBuffer
            event.arrivalDate = dep.addingTimeInterval(travel + Double(newBuffer) * 60)
        }
        events[idx] = event
        rescheduleNotification(at: idx)
    }

    /// 인덱스의 현재 값(도착/출발/알림리드)으로 알림만 다시 예약한다(이동시간 재계산 없음).
    private func rescheduleNotification(at idx: Int) {
        var event = events[idx]
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        event.notificationId = nil
        guard let dep = event.departureDate, let travel = event.travelSeconds else { events[idx] = event; return }
        event.notificationId = scheduleDepartureNotification(
            for: event, departure: dep, travelSeconds: travel, source: "조정됨")
        events[idx] = event
    }

    /// 네트워크 호출 없이, 이미 구한 이동시간(같은 반복 그룹의 첫 회차 값)을 그대로 적용한다.
    private func applyCachedArrivalEstimate(to event: inout ScheduledEvent, travelSeconds: TimeInterval,
                                            source: String = "동일 반복 일정 기준 추정") {
        event.anchor = .arrival
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        event.travelSeconds = travelSeconds
        // @MX:DEBT: 출발시각 산식 3중 복제 — 전체 내용은 `applyEstimate(to:)`의 마커 참고.
        let departure = event.arrivalDate.addingTimeInterval(-travelSeconds - Double(event.bufferMinutes) * 60)
        event.departureDate = departure
        event.notificationId = scheduleDepartureNotification(
            for: event, departure: departure, travelSeconds: travelSeconds, source: source)
    }

    /// 네트워크 호출 없이, 이미 구한 이동시간을 출발-고정형(복귀 등) 회차에 적용한다.
    private func applyCachedDepartureEstimate(to event: inout ScheduledEvent, departureDate: Date,
                                              travelSeconds: TimeInterval,
                                              source: String = "동일 반복 일정 기준 추정") {
        event.anchor = .departure
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        event.travelSeconds = travelSeconds
        event.departureDate = departureDate
        event.arrivalDate = departureDate.addingTimeInterval(travelSeconds + Double(event.bufferMinutes) * 60)
        event.notificationId = scheduleDepartureNotification(
            for: event, departure: departureDate, travelSeconds: travelSeconds, source: source)
    }

    /// iOS는 앱 하나가 예약해둘 수 있는 로컬 알림을 64개까지만 유지하고, 그걸 넘긴 요청은
    /// **조용히 버린다**(가장 먼저 울릴 64개만 남김). 26주짜리 반복 일정을 하루 4구간
    /// (등원·복귀·점심 왕복)으로 만들면 520건이라, 3주쯤 뒤 회차부터는 알림이 아예 오지 않는다 —
    /// 앱은 notificationId를 갖고 있으니 예약된 줄 알지만 실제로는 없는 상태가 된다.
    ///
    /// 그래서 "알림 시각이 가장 가까운 것부터 limit건"만 실제로 예약해두고, 앱이 foreground로
    /// 올 때마다 다시 채워 넣는다(앞쪽 회차가 지나가면 그만큼 뒤쪽 회차가 새로 들어온다).
    func rescheduleNearestNotifications(limit: Int = 60) {
        let now = Date()
        // events를 요소 단위로 여러 번 고치면 didSet(daysWithSchedule 재계산)이 매번 돌아
        // 건수의 제곱에 비례해 느려진다 — 복사본에서 다 고치고 마지막에 한 번만 대입한다.
        var updated = events
        let upcoming = updated.indices.compactMap { i -> (idx: Int, at: Date)? in
            guard updated[i].wantsNotification,
                  let dep = updated[i].departureDate, updated[i].travelSeconds != nil else { return nil }
            let at = dep.addingTimeInterval(-Double(updated[i].notifyLeadMinutes) * 60)
            return at > now ? (i, at) : nil
        }
        .sorted { $0.at < $1.at }
        .prefix(limit)

        notifications.cancelAll()
        for i in updated.indices { updated[i].notificationId = nil }
        for item in upcoming {
            guard let travel = updated[item.idx].travelSeconds,
                  let dep = updated[item.idx].departureDate else { continue }
            updated[item.idx].notificationId = scheduleDepartureNotification(
                for: updated[item.idx], departure: dep, travelSeconds: travel, source: "예약 갱신")
        }
        events = updated
        save()
    }

    /// 출발 시각이 임박한(기본 2시간 이내) 일정들의 이동시간을 실시간으로 다시 조회해 갱신한다.
    /// 반복 일정 생성 때 아낀 API 호출을, 실제로 그 회차가 다가왔을 때만 소비한다. 앱이 foreground될 때 호출.
    func refreshUpcomingEstimates(withinMinutes: Int = 120) async {
        let now = Date()
        let horizon = now.addingTimeInterval(Double(withinMinutes) * 60)
        // 인덱스가 아니라 id로 대상을 잡는다 — 아래 루프는 await로 중단되고, 그 사이 동기화나
        // 사용자의 추가·삭제로 events 배열이 바뀌면 인덱스가 다른 일정을 가리키거나(엉뚱한 일정을
        // 덮어씀) 범위를 벗어나 크래시할 수 있다.
        let targetIDs = events.filter { e in
            guard let dep = e.departureDate else { return false }
            return dep > now && dep <= horizon
        }.map { $0.id }
        guard !targetIDs.isEmpty else { return }
        for id in targetIDs {
            guard let idx = events.firstIndex(where: { $0.id == id }) else { continue }
            var event = events[idx]
            switch event.anchor ?? .arrival {
            case .arrival:
                await applyEstimate(to: &event)
            case .departure:
                guard let dep = event.departureDate else { continue }
                await applyDepartureAnchoredEstimate(to: &event, departureDate: dep)
            }
            // await 후 인덱스를 다시 찾는다(위와 같은 이유).
            guard let writeIdx = events.firstIndex(where: { $0.id == id }) else { continue }
            events[writeIdx] = event
        }
        save()
    }

    func deleteEvent(_ event: ScheduledEvent) {
        if let nid = event.notificationId { notifications.cancel(id: nid) }
        events.removeAll { $0.id == event.id }
        save()
        removeUpcomingMeals(eventIDs: [event.id])
        // 캘린더에서도 삭제(다른 기기로도 전파됨).
        if let gid = event.googleEventId {
            Task { await removeFromCalendar([gid]) }
        }
    }

    /// 여러 일정을 한 번에 삭제한다(알림 취소·캘린더 삭제 포함). 낱개 deleteEvent를 루프로 부르면
    /// 건수만큼 JSON 인코딩+디스크 쓰기 + daysWithSchedule 재계산이 반복돼(AI 일괄 삭제에서 수십 건)
    /// 눈에 띄게 느려진다 — 여기서는 저장·재계산이 한 번만 일어난다.
    func deleteEvents(_ list: [ScheduledEvent]) {
        guard !list.isEmpty else { return }
        let ids = Set(list.map { $0.id })
        for e in list {
            if let nid = e.notificationId { notifications.cancel(id: nid) }
        }
        events.removeAll { ids.contains($0.id) }
        save()
        removeUpcomingMeals(eventIDs: ids)
        let gids = list.compactMap { $0.googleEventId }
        if !gids.isEmpty {
            Task { await removeFromCalendar(gids) }
        }
    }

    /// deleteEvents의 활동 블록 버전.
    func deleteActivities(_ list: [ActivityBlock]) {
        guard !list.isEmpty else { return }
        let ids = Set(list.map { $0.id })
        activities.removeAll { ids.contains($0.id) }
        saveActivities()
        removeUpcomingMeals(activityIDs: ids)
        let gids = list.compactMap { $0.googleEventId }
        if !gids.isEmpty {
            Task { await removeFromCalendar(gids) }
        }
    }

    /// **[테스트용]** 일정·활동·식사 기록을 전부 지운다. 출시 전에 이 함수와 설정의 버튼을 같이 뺀다.
    ///
    /// 낱개 삭제 경로(`deleteEvents`/`deleteActivities`)를 그대로 거치므로 알림 취소·구글 캘린더
    /// 삭제·삭제 묘비까지 정상적으로 처리된다 — 배열만 비우면 캘린더에 찌꺼기가 남는다.
    func deleteEverythingForTesting() {
        deleteEvents(events)
        deleteActivities(activities)
        if !meals.isEmpty {
            meals.removeAll()
            saveMeals()
        }
    }

    /// 도착 시각이 이미 지난(만료) 일정을 한 번에 삭제한다.
    func deleteExpired() {
        let now = Date()
        let expired = events.filter { $0.arrivalDate < now }
        for e in expired {
            if let nid = e.notificationId { notifications.cancel(id: nid) }
        }
        events.removeAll { $0.arrivalDate < now }
        save()
        // 만료 정리는 이미 지난 일정만 지우므로 식사 기록은 건드리지 않는다(실제로 먹은 기록).
        let gids = expired.compactMap { $0.googleEventId }
        if !gids.isEmpty {
            Task { await removeFromCalendar(gids) }
        }
    }

    /// 구글 계정에 연결(로그인)하고 즉시 동기화한다.
    func connectGoogle() async {
        guard config.hasGoogleCalendar else { return }
        try? await gcal.connect()
        await syncWithGoogle()
    }

    /// 구글 캘린더와 동기화: 다른 기기에서 추가/삭제된 besir 일정을 반영한다.
    func syncWithGoogle() async {
        guard config.hasGoogleCalendar, gcal.isConnected else { return }
        guard !isSyncing else { return }   // 동시 실행 방지(중복 일정 생성 차단)
        isSyncing = true
        defer { isSyncing = false }
        #if os(iOS)
        // 동기화 중에 앱이 백그라운드로 가면 그대로 정지돼 캘린더 쓰기가 절반만 끝날 수 있다
        // (중복·누락의 원인) — 마무리할 시간을 요청해둔다.
        let bgAssertion = UIApplication.shared.beginBackgroundTask(withName: "besir.calendar-sync")
        defer { if bgAssertion != .invalid { UIApplication.shared.endBackgroundTask(bgAssertion) } }
        #endif

        // 0) 기존 중복 정리(같은 googleEventId가 여러 개면 하나만 남김).
        var seenGIDs = Set<String>()
        events.removeAll { e in
            guard let g = e.googleEventId else { return false }
            if seenGIDs.contains(g) {
                if let nid = e.notificationId { notifications.cancel(id: nid) }
                return true
            }
            seenGIDs.insert(g); return false
        }
        var seenActivityGIDs = Set<String>()
        activities.removeAll { a in
            guard let g = a.googleEventId else { return false }
            if seenActivityGIDs.contains(g) { return true }
            seenActivityGIDs.insert(g); return false
        }

        guard let remote = try? await gcal.fetchBesirItems() else { save(); return }
        let remoteIDs = Set(remote.events.compactMap { $0.googleEventId })

        // 0-1) besir에서 지운 항목 처리. 아래 "가져오기"보다 반드시 먼저 판단해야 되살아나지 않는다.
        //      묘비 목록은 이 라운드 동안 고정된 스냅샷으로 쓴다(중간에 줄어들면 판단이 흔들린다).
        let tombstones = deletedGoogleEventIds
        let remoteAllIDs = Set(remote.all.map { $0.id })
        // 지웠다고 표시했는데 원격에 아직 남아 있으면, 지난번 삭제 요청이 실패한 것 — 다시 지운다.
        for gid in tombstones.intersection(remoteAllIDs) {
            try? await gcal.deleteEvent(id: gid)
        }
        // 원격에서 실제로 사라진 게 확인된 묘비는 목적을 다했으니 정리한다(무한 누적 방지).
        let confirmedGone = tombstones.subtracting(remoteAllIDs)
        if !confirmedGone.isEmpty {
            deletedGoogleEventIds.subtract(confirmedGone)
            saveDeletedGIDs()
        }

        // 1) 다른 기기에서 삭제된 일정 제거(로컬에 googleEventId가 있는데 원격엔 없음).
        for e in events where e.googleEventId != nil && !remoteIDs.contains(e.googleEventId!) {
            if let nid = e.notificationId { notifications.cancel(id: nid) }
        }
        events.removeAll { $0.googleEventId != nil && !remoteIDs.contains($0.googleEventId!) }

        // 2) 다른 기기에서 추가된 일정 가져오기(원격에 있는데 로컬엔 없음).
        //    매번 현재 localGIDs를 다시 확인해 중복 추가를 방어한다.
        for var r in remote.events {
            guard let gid = r.googleEventId else { continue }
            if events.contains(where: { $0.googleEventId == gid }) { continue }
            if tombstones.contains(gid) { continue }   // besir에서 지운 것은 되살리지 않는다
            await applyEstimate(to: &r)   // 출발시각 계산 + 이 기기에 알림 예약
            events.append(r)
        }
        events.sort { $0.arrivalDate < $1.arrivalDate }

        await reconcileActivities(remote: remote, tombstones: tombstones)
        save()
    }

    /// 활동 블록을 캘린더와 맞춘다. 예전에는 활동을 캘린더에 올리기만 하고 아무도 대조하지 않아서,
    /// googleEventId를 저장하기 전에 앱이 종료되거나 삭제 요청이 조용히 실패하면(`try?`) 캘린더에만
    /// 남는 찌꺼기가 영구히 쌓였다 — besir엔 1건인데 구글/애플 캘린더엔 2건씩 보이던 원인이다.
    ///
    /// besir를 기준으로 삼는다: besir가 모르는 besir 표시 항목은 캘린더에서 지우고, 아직 못 올린
    /// 활동은 올린다. 다른 기기의 besir가 만든 활동은(지우지 않고) 먼저 가져온 뒤 대조한다.
    private func reconcileActivities(remote: (events: [ScheduledEvent],
                                              activities: [ActivityBlock],
                                              all: [GoogleCalendarService.RemoteItem]),
                                     tombstones: Set<String>) async {
        // 2-1) 원격에서 사라진 활동은 로컬의 googleEventId만 지운다 — 활동은 besir가 기준이라
        //      로컬에서 삭제하지 않고, 아래에서 캘린더에 다시 올린다.
        let remoteActivityIDs = Set(remote.activities.compactMap { $0.googleEventId })
        var localActivities = activities
        for i in localActivities.indices {
            if let gid = localActivities[i].googleEventId, !remoteActivityIDs.contains(gid) {
                localActivities[i].googleEventId = nil
            }
        }

        // 2-2) 캘린더에만 있는 활동은 가져온다. 단, 같은 제목·같은 시간대의 활동이 이미 있으면
        //      그건 새 활동이 아니라 중복이므로 가져오지 않는다(아래에서 캘린더 쪽을 지운다).
        for r in remote.activities {
            guard let gid = r.googleEventId else { continue }
            if localActivities.contains(where: { $0.googleEventId == gid }) { continue }
            if tombstones.contains(gid) { continue }   // besir에서 지운 것은 되살리지 않는다
            let isDuplicate = localActivities.contains {
                $0.title == r.title
                    && abs($0.startDate.timeIntervalSince(r.startDate)) < 60
                    && abs($0.endDate.timeIntervalSince(r.endDate)) < 60
            }
            if isDuplicate { continue }
            localActivities.append(r)
        }
        localActivities.sort { $0.startDate < $1.startDate }
        activities = localActivities
        saveActivities()

        // 2-3) besir가 모르는 besir 표시 항목을 캘린더에서 지운다(= 중복·찌꺼기).
        //      위에서 가져올 건 이미 다 가져왔으므로 여기 남은 건 besir에 대응물이 없는 것뿐이다.
        //      besir가 만든 항목(besir=1)만 조회 대상이라 사용자의 다른 캘린더 일정은 건드리지 않는다.
        let claimed = Set(events.compactMap { $0.googleEventId })
            .union(activities.compactMap { $0.googleEventId })
        await removeFromCalendar(remote.all.map { $0.id }.filter { !claimed.contains($0) })

        // 2-4) 알림은 besir 앱에서만 울려야 한다. 알림 해제 설정을 넣기 전 버전이 만든 항목은
        //      구글 캘린더 기본 알림(보통 10분 전)이 남아 있어 애플/구글 캘린더에서도 울렸다.
        for item in remote.all where item.hasReminder && claimed.contains(item.id) {
            try? await gcal.clearReminders(id: item.id)
        }

        // 2-5) 아직 캘린더에 못 올린 활동(등록 중 앱 종료·네트워크 실패, 또는 2-1에서 비운 것)을 올린다.
        guard config.autoAddToCalendar else { return }
        let pendingIDs = activities.filter { $0.googleEventId == nil && $0.wantsCalendarSync }.map { $0.id }
        for id in pendingIDs {
            guard let idx = activities.firstIndex(where: { $0.id == id }) else { continue }
            guard let gid = try? await gcal.createEvent(for: activities[idx]) else { continue }
            // await 뒤에는 배열이 바뀌었을 수 있으니 인덱스를 다시 찾는다.
            guard let writeIdx = activities.firstIndex(where: { $0.id == id }) else { continue }
            activities[writeIdx].googleEventId = gid
        }
        saveActivities()
    }

    // MARK: - 설정

    func updateConfig(_ newConfig: AppConfig) {
        config = newConfig
        config.save()
    }

    // MARK: - 영속화

    func save() {
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(events) {
            try? data.write(to: eventsURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: eventsURL),
              let decoded = try? JSONDecoder().decode([ScheduledEvent].self, from: data) else { return }
        events = decoded.sorted { $0.arrivalDate < $1.arrivalDate }
    }
}
