import Foundation
import CoreLocation

/// 이동 수단.
enum TransportMode: String, Codable, CaseIterable, Identifiable {
    case car        // 자동차
    case transit    // 대중교통
    case walk       // 도보

    var id: String { rawValue }

    var title: String {
        switch self {
        case .car: return "자동차"
        case .transit: return "대중교통"
        case .walk: return "도보"
        }
    }

    var systemImage: String {
        switch self {
        case .car: return "car.fill"
        case .transit: return "tram.fill"
        case .walk: return "figure.walk"
        }
    }
}

/// 특정 수단의 소요시간 추정 결과.
struct TravelEstimate: Identifiable {
    let mode: TransportMode
    /// 소요 시간(초). 계산 불가하면 nil.
    let duration: TimeInterval?
    /// 거리(m). 알 수 없으면 nil.
    let distance: Double?
    /// 데이터 출처 표기 (예: "카카오", "ODsay", "Apple 지도", "추정").
    let source: String

    var id: String { mode.rawValue }

    var isAvailable: Bool { duration != nil }

    /// "23분" 형태 문자열.
    var durationText: String {
        guard let duration else { return "정보 없음" }
        let minutes = Int((duration / 60).rounded())
        if minutes < 60 { return "\(minutes)분" }
        return "\(minutes / 60)시간 \(minutes % 60)분"
    }
}

/// 대중교통 경로의 한 구간(도보/지하철/버스)을 색과 좌표열로 표현.
enum RouteMode: String {
    case walk, subway, bus, car
}

struct RouteSegment {
    let mode: RouteMode
    let color: String   // hex, 예: "#00A84D"
    let coords: [CLLocationCoordinate2D]
}

/// 대중교통 경로 안내의 한 단계(도보 이동 / 버스·지하철 탑승).
struct TransitStep: Identifiable {
    let id = UUID()
    let kind: RouteMode
    /// 노선 이름("1호선", "101번"). 도보 구간은 빈 문자열.
    let line: String
    /// 승차 정류장·역 이름. 도보는 출발 지점.
    let from: String
    /// 하차 정류장·역 이름. 도보는 도착 지점.
    let to: String
    let minutes: Int
    /// 지나는 역·정류장 수(대중교통 구간만).
    let stationCount: Int?
    let color: String   // hex
}

extension TransitStep {
    var systemImage: String {
        switch kind {
        case .walk: return "figure.walk"
        case .subway: return "tram.fill"
        case .bus: return "bus.fill"
        case .car: return "car.fill"
        }
    }

    /// "도보 5분" / "1호선 탑승" / "101번 버스 탑승"
    var headline: String {
        switch kind {
        case .walk: return "도보 \(minutes)분"
        case .bus: return "\(line) 버스 탑승"
        default: return "\(line) 탑승"
        }
    }

    /// "시청역까지 이동" / "시청역 → 종로3가역 · 3개 역 · 8분"
    var detail: String {
        if kind == .walk { return "\(to)까지 이동" }
        let unit = kind == .subway ? "개 역" : "개 정류장"
        let count = stationCount.map { " · \($0)\(unit)" } ?? ""
        return "\(from) → \(to)\(count) · \(minutes)분"
    }
}

/// 좌표가 있는 장소.
/// Hashable인 이유: 장소 검색 결과 목록은 이름이 겹칠 수 있어(같은 상호의 다른 지점) 좌표까지
/// 포함한 값 전체로 구분해야 ForEach에서 두 곳이 한 줄로 합쳐지지 않는다.
struct Place: Codable, Equatable, Hashable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
}

/// 즐겨찾기 장소(집·회사 등 자주 쓰는 곳). 일정 추가 시 빠른 선택, AI 파싱 시 목적지 이름 해석에 쓰인다.
struct FavoritePlace: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var place: Place
}

/// 캘린더 업로드가 아직 안 끝났거나 실패했다는 기록.
///
/// **성공은 여기 두지 않는다** — 성공의 단일 출처는 `googleEventId`다(계약 5). 성공을 이쪽에도
/// 적으면 업로드 직후 앱이 죽었을 때 두 값이 어긋나고, 어느 쪽을 믿을지가 화면마다 갈린다.
///
/// 왜 필요한가: 등록은 로컬에서 끝나고 업로드는 뒤따라 돈다. 그 사이의 "아직 안 올라감"과
/// "올리다 실패함"이 사용자에게 서로 다르게 보이지 않으면, 빠른 "등록 완료"만 남고
/// 캘린더가 비어 있는 것을 아무도 모른다 — 이번 결함이 더 나빠질 뿐이다.
enum CalendarUploadState: String, Codable {
    /// 올릴 차례를 기다리는 중이거나 올리는 중.
    case pending
    /// 시도했고 실패했다(미연결·취소·네트워크 등). 재시도 대상.
    case failed

    var title: String {
        switch self {
        case .pending: return "캘린더에 올리는 중이에요"
        case .failed:  return "캘린더에 못 올렸어요"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "arrow.triangle.2.circlepath"
        case .failed:  return "exclamationmark.triangle.fill"
        }
    }
}

/// 등록된 일정.
struct ScheduledEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    /// 출발지(일정 추가 시 지정). 옛 일정은 nil일 수 있음.
    var origin: Place?
    var destination: Place
    /// 도착해야 하는 시각.
    var arrivalDate: Date
    /// 선택한 이동 수단.
    var mode: TransportMode
    /// 도착 시 여유로 둘 버퍼(분). 출발 시각 = 도착 - 이동시간 - 버퍼.
    var bufferMinutes: Int
    /// 출발 시각 몇 분 전에 알릴지(분).
    var notifyLeadMinutes: Int
    /// 이 일정의 출발 알림을 켤지. 옛 데이터는 nil이고 켜진 것으로 본다(`wantsNotification`).
    var notifyEnabled: Bool?
    /// 이 일정을 구글 캘린더에 올릴지. nil(옛 데이터)이면 전역 설정(autoAddToCalendar)을 따른다.
    var syncToCalendar: Bool?
    /// 계산된 출발 시각(스냅샷).
    var departureDate: Date?
    /// 계산에 사용된 이동시간(초) 스냅샷.
    var travelSeconds: TimeInterval?
    /// 예약된 알림 식별자.
    var notificationId: String?
    /// 구글 캘린더에 등록된 경우 그 이벤트 ID(동기화·삭제 전파용).
    var googleEventId: String?
    /// 캘린더 업로드 진행 상태. nil = 올릴 일이 없거나(연동 꺼짐·미연결·이 일정만 제외) 이미 끝났다.
    /// 옛 데이터의 JSON에는 이 키가 아예 없다 — Optional이라 합성된 디코더가 그대로 nil로 읽는다
    /// (기본값을 가진 비-Optional로 만들면 옛 파일이 통째로 디코딩 실패해 일정이 사라진다).
    var calendarUpload: CalendarUploadState?
    /// 반복 일정으로 한 번에 생성된 경우 같은 값을 공유(그룹 일괄 삭제용). 단발성 일정은 nil.
    var recurrenceId: UUID?
    /// 이 이동 구간이 딸려 있는 활동 블록(ActivityBlock.id).
    /// 값이 있으면 그 활동을 옮길 때 이 구간도 같이 움직인다 — 수동으로 만든 활동과 이동을
    /// 묶어두기 위한 명시적 연결이다. 반복 일정으로 만든 옛 데이터는 nil이고, 그쪽은
    /// `Store.linkedLegs`가 recurrenceId+날짜+장소명으로 추정해 처리한다.
    var linkedActivityId: UUID?

    /// 알림을 예약해야 하는지(옛 데이터는 켜진 것으로 취급).
    var wantsNotification: Bool { notifyEnabled ?? true }
    /// 구글 캘린더에 올려도 되는지(옛 데이터는 전역 설정을 따르므로 true).
    var wantsCalendarSync: Bool { syncToCalendar ?? true }

    /// 이 일정의 시각 기준. nil(옛 데이터)은 .arrival과 동일하게 취급.
    /// 실시간 재계산(refreshUpcomingEstimates) 시 어느 방향으로 계산해야 하는지 판단하는 데 쓰인다.
    var anchor: ScheduleAnchor?
}

/// 일정의 시각 기준. `.arrival`은 도착 시각이 고정값(출발 시각을 역산), `.departure`는 출발 시각이
/// 고정값(도착 시각을 순산) — 예: 퇴근/복귀처럼 "이 시각에 출발"이 우선인 경우.
enum ScheduleAnchor: String, Codable {
    case arrival, departure
}

// MARK: - 일정 판단 로직(순수 함수)

/// 저장·네트워크 없이 **판단만** 하는 로직 모음.
/// Store 안에 두면 알림·파일·캘린더에 얽혀 따로 검증하기 어려워서, 입력만 받아 결과를 내는
/// 형태로 떼어 놓았다(Store의 같은 이름 메서드가 이걸 호출한다).
enum ScheduleLogic {

    /// 어떤 시간대 앞뒤로 사용자가 있을/가야 할 장소를 기존 일정에서 추정한다.
    /// 활동 블록(그 장소에 머무는 시간)을 먼저 보고, 없으면 이동 일정의 목적지를 본다.
    static func surroundingPlaces(start: Date,
                                  end: Date,
                                  activities: [ActivityBlock],
                                  events: [ScheduledEvent],
                                  home: Place?)
    -> (before: (place: Place, label: String)?, after: (place: Place, label: String)?) {
        var before: (Place, String)?
        if let a = activities.filter({ $0.startDate <= start && $0.location != nil })
            .max(by: { $0.startDate < $1.startDate }), let p = a.location {
            before = (p, a.title)
        } else if let e = events.filter({ $0.arrivalDate <= start })
            .max(by: { $0.arrivalDate < $1.arrivalDate }) {
            before = (e.destination, e.title)
        } else if let home {
            before = (home, "집")
        }

        var after: (Place, String)?
        if let a = activities.filter({ $0.startDate >= end && $0.location != nil })
            .min(by: { $0.startDate < $1.startDate }), let p = a.location {
            after = (p, a.title)
        } else if let e = events.filter({ $0.arrivalDate >= end })
            .min(by: { $0.arrivalDate < $1.arrivalDate }) {
            after = (e.destination, e.title)
        } else if let home {
            after = (home, "집")
        }
        return (before, after)
    }

    /// 일정을 지울 때 **같이 지워야 할 식사 기록**의 id.
    /// 아직 오지 않은 식사만 대상이다 — 이미 지난 식사는 "실제로 먹은 기록"이라 남긴다.
    static func mealsToRemove(meals: [MealLog],
                              eventIDs: Set<UUID>,
                              activityIDs: Set<UUID>,
                              now: Date) -> Set<UUID> {
        Set(meals.filter { meal in
            let linked = (meal.scheduledEventId.map { eventIDs.contains($0) } ?? false)
                || (meal.activityId.map { activityIDs.contains($0) } ?? false)
            guard linked else { return false }
            // 계획 시각을 모르면 기록 시각으로 판단한다(수동 기록은 plannedAt이 없다).
            return (meal.plannedAt ?? meal.loggedAt) > now
        }.map { $0.id })
    }
}

// MARK: - 반복 규칙 · 공휴일

/// 반복 일정이 실제로 어느 날짜에 생기는지 정하는 규칙.
/// 예전엔 "요일 목록"만 있어서 매주 반복밖에 못 했다 — 격주·월 단위·공휴일 제외를 여기로 모았다.
struct RecurrenceRule {
    /// 반복 요일(1=일 … 7=토, `Calendar.component(.weekday:)` 기준).
    var weekdays: Set<Int>
    /// 1=매주, 2=격주, 3=3주마다…
    var everyNWeeks: Int = 1
    /// 월 단위 반복: 그 달의 몇 번째 해당 요일인지(1~4, -1=마지막). nil이면 주 단위 반복.
    var nthWeekOfMonth: Int?
    /// 한국 공휴일은 건너뛴다.
    var skipHolidays: Bool = false

    /// `startDate`부터 `weeks`주 동안 이 규칙에 맞는 날짜를 만든다.
    func dates(from startDate: Date, weeks: Int, calendar: Calendar = .current) -> [Date] {
        guard !weekdays.isEmpty else { return [] }
        let n = max(1, everyNWeeks)
        // 격주 간격은 "주의 시작(일요일)" 기준으로 센다 — 시작일이 주 중간이어도 간격이 어긋나지 않게.
        let baseWeek = calendar.dateInterval(of: .weekOfYear, for: startDate)?.start ?? startDate
        var out: [Date] = []
        for offset in 0..<(max(1, weeks) * 7) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
            guard weekdays.contains(calendar.component(.weekday, from: day)) else { continue }
            if n > 1 {
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day
                let weeksApart = (calendar.dateComponents([.day], from: baseWeek, to: weekStart).day ?? 0) / 7
                guard weeksApart % n == 0 else { continue }
            }
            if let nth = nthWeekOfMonth, !Self.isNthWeekday(day, nth: nth, calendar: calendar) { continue }
            if skipHolidays, KoreanHolidays.isHoliday(day, calendar: calendar) { continue }
            out.append(day)
        }
        return out
    }

    /// 그 달의 n번째 같은 요일인지. `nth == -1`이면 "마지막".
    static func isNthWeekday(_ date: Date, nth: Int, calendar: Calendar = .current) -> Bool {
        if nth == -1 {
            guard let next = calendar.date(byAdding: .day, value: 7, to: date) else { return false }
            return calendar.component(.month, from: next) != calendar.component(.month, from: date)
        }
        return (calendar.component(.day, from: date) - 1) / 7 + 1 == nth
    }
}

/// 한국 공휴일 판정.
///
/// 음력 공휴일(설날·부처님오신날·추석)은 **표를 하드코딩하지 않고** Foundation의 음력 달력
/// (`.chinese` — 한국 음력과 같은 삭망월 체계)으로 계산한다. 해마다 표를 갱신할 필요가 없다.
///
/// 대체공휴일은 단순화했다: 대상 공휴일이 토·일이거나 다른 공휴일과 겹치면 다음 평일 하루를
/// 더한다. 신정·현충일은 대체공휴일 대상이 아니라 제외한다.
enum KoreanHolidays {
    /// 연도별 yyyyMMdd 키 집합 캐시(한 해치를 만들 때 음력 탐색으로 365일을 훑으므로 재사용).
    private static var cache: [Int: Set<Int>] = [:]

    static func isHoliday(_ date: Date, calendar: Calendar = .current) -> Bool {
        let year = calendar.component(.year, from: date)
        return keys(year: year, calendar: calendar).contains(dayKey(date, calendar))
    }

    /// 그 해 공휴일 목록(오름차순). 확인·표시용.
    static func dates(year: Int, calendar: Calendar = .current) -> [Date] {
        keys(year: year, calendar: calendar).sorted().compactMap {
            calendar.date(from: DateComponents(year: $0 / 10000, month: ($0 / 100) % 100, day: $0 % 100))
        }
    }

    private static func dayKey(_ date: Date, _ calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
    }

    private static func keys(year: Int, calendar: Calendar) -> Set<Int> {
        if let cached = cache[year] { return cached }
        var days: Set<Int> = []
        var substitutable: [Date] = []   // 대체공휴일 대상
        func add(_ d: Date?) { if let d { days.insert(dayKey(d, calendar)) } }
        func solar(_ m: Int, _ d: Int) -> Date? {
            calendar.date(from: DateComponents(year: year, month: m, day: d))
        }

        // 양력 고정 공휴일.
        for (m, d) in [(1, 1), (3, 1), (5, 5), (6, 6), (8, 15), (10, 3), (10, 9), (12, 25)] {
            let date = solar(m, d)
            add(date)
            // 신정(1/1)·현충일(6/6)은 대체공휴일 대상이 아니다.
            if let date, !(m == 1 && d == 1), !(m == 6 && d == 6) { substitutable.append(date) }
        }
        // 음력 공휴일. 설날·추석은 전날~다음날까지 사흘.
        if let seollal = lunar(year: year, month: 1, day: 1, calendar: calendar) {
            for off in -1...1 {
                let date = calendar.date(byAdding: .day, value: off, to: seollal)
                add(date); if let date { substitutable.append(date) }
            }
        }
        if let buddha = lunar(year: year, month: 4, day: 8, calendar: calendar) {
            add(buddha); substitutable.append(buddha)
        }
        if let chuseok = lunar(year: year, month: 8, day: 15, calendar: calendar) {
            for off in -1...1 {
                let date = calendar.date(byAdding: .day, value: off, to: chuseok)
                add(date); if let date { substitutable.append(date) }
            }
        }

        // 대체공휴일: 토·일이거나 이미 다른 공휴일과 겹치면 다음 평일 하루를 더한다.
        for date in substitutable.sorted() {
            let weekday = calendar.component(.weekday, from: date)
            let overlaps = substitutable.filter { dayKey($0, calendar) == dayKey(date, calendar) }.count > 1
            guard weekday == 1 || weekday == 7 || overlaps else { continue }
            var probe = date
            for _ in 0..<10 {
                guard let next = calendar.date(byAdding: .day, value: 1, to: probe) else { break }
                probe = next
                let wd = calendar.component(.weekday, from: probe)
                if wd != 1, wd != 7, !days.contains(dayKey(probe, calendar)) {
                    days.insert(dayKey(probe, calendar)); break
                }
            }
        }

        cache[year] = days
        return days
    }

    /// 그 해 안에서 음력 (month, day)에 해당하는 양력 날짜(윤달 제외).
    private static func lunar(year: Int, month: Int, day: Int, calendar: Calendar) -> Date? {
        var lunarCal = Calendar(identifier: .chinese)
        lunarCal.timeZone = calendar.timeZone
        guard let jan1 = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) else { return nil }
        for offset in 0..<366 {
            guard let d = calendar.date(byAdding: .day, value: offset, to: jan1) else { continue }
            guard calendar.component(.year, from: d) == year else { break }
            let c = lunarCal.dateComponents([.month, .day, .isLeapMonth], from: d)
            if c.month == month, c.day == day, c.isLeapMonth != true { return d }
        }
        return nil
    }
}

// MARK: - be full sir (식사)

/// 식사를 어떤 방식으로 해결했는지/할 것인지.
enum MealCategory: String, Codable, CaseIterable, Identifiable {
    case diningOut  // 외식
    case delivery   // 배달
    case cooking    // 요리

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diningOut: return "외식"
        case .delivery: return "배달"
        case .cooking: return "요리"
        }
    }

    var systemImage: String {
        switch self {
        case .diningOut: return "fork.knife"
        case .delivery: return "bag.fill"
        case .cooking: return "frying.pan.fill"
        }
    }
}

/// 주변 추천에서 찾을 장소 종류. 카카오 로컬의 category_group_code에 대응한다.
enum MealCategoryFilter: String, CaseIterable, Identifiable {
    case restaurant, cafe

    var id: String { rawValue }
    /// 카카오 로컬 카테고리 코드.
    var code: String { self == .restaurant ? "FD6" : "CE7" }
    /// 카카오 키워드 검색은 query가 비면 안 돼서 카테고리 이름을 그대로 넣는다.
    var query: String { self == .restaurant ? "음식점" : "카페" }
    var title: String { self == .restaurant ? "맛집" : "카페" }
    var systemImage: String { self == .restaurant ? "fork.knife" : "cup.and.saucer.fill" }
}

/// 주변 검색 정렬 기준.
/// 카카오 로컬이 지원하는 건 이 둘뿐이다 — **평점순은 만들 수 없다**(이 API가 평점을 주지 않는다).
/// `accuracy`는 카카오의 자체 순위로, 많이 찾는 곳이 위로 오는 경향이 있어 평점순의 대용에 가깝다.
enum NearbySort: String, CaseIterable, Identifiable {
    case distance, accuracy
    var id: String { rawValue }
    var title: String { self == .distance ? "거리순" : "정확도순" }
}

/// 주변 검색 결과 한 건(거리·업종·연락처까지 포함).
struct NearbyPlace: Identifiable {
    var id: String { "\(place.name)-\(place.latitude)-\(place.longitude)" }
    let place: Place
    /// "한식", "초밥,롤" 같은 세부 업종.
    let category: String
    let distanceMeters: Int?
    let phone: String?
    /// 카카오맵 상세 페이지 주소.
    let url: String?

    /// "230m" / "1.4km"
    var distanceText: String? {
        guard let d = distanceMeters else { return nil }
        return d < 1000 ? "\(d)m" : String(format: "%.1fkm", Double(d) / 1000)
    }
}

/// 한 끼 식사 기록. be full sir의 추천 이력이자, 나중에 be rich sir(지출)와 이어질 접점이다.
///
/// 일정(ScheduledEvent)과는 별개의 데이터다 — 식사는 "무엇을 먹었나"의 기록이고, 그 식당까지
/// 가는 이동은 기존 일정 파이프라인이 담당한다. 추천을 골라 실제 일정으로 등록한 경우에만
/// `scheduledEventId`로 둘을 연결한다(Phase 1 Day 10).
struct MealLog: Identifiable, Codable {
    var id: UUID = UUID()
    var category: MealCategory
    /// 식당명(외식·배달) 또는 메뉴명(요리).
    var title: String
    /// 식당 위치. 배달·요리는 대개 nil.
    var place: Place?
    /// 예상 비용(원). 모르면 nil — 나중에 be rich sir 예산 연동에 쓴다.
    var estimatedCost: Int?
    /// 이 식사로 등록된 이동 일정이 있으면 그 id(추천 → 일정 등록 연결용).
    var scheduledEventId: UUID?
    /// 이 식사로 만든 활동 블록(식사 시간)의 id. 일정을 지우면 이 기록도 같이 지우는 데 쓴다.
    var activityId: UUID?
    /// 계획된 식사 시각(등록해둔 경우). 아직 안 먹은 일정을 지울 때 기록도 지울지 판단한다.
    var plannedAt: Date?
    /// 기록한 시각.
    var loggedAt: Date = Date()
}

/// 이동이 아니라 "그 장소에 머무는 활동"(수업·근무·점심 등)을 나타내는 시간 블록.
/// ScheduledEvent(이동+도착 알람)와 달리 이동시간 계산·알림이 없는 순수 시간표 항목이다.
struct ActivityBlock: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var location: Place?
    var startDate: Date
    var endDate: Date
    /// 반복 일정 그룹(ScheduledEvent의 recurrenceId)과 공유 — 같이 일괄 삭제된다.
    var recurrenceId: UUID?
    var googleEventId: String?
    /// 캘린더 업로드 진행 상태. 이동 구간(ScheduledEvent)과 같은 이유·같은 규칙이다.
    var calendarUpload: CalendarUploadState?
    /// 이 활동을 구글 캘린더에 올릴지. nil(옛 데이터)이면 전역 설정을 따른다.
    var syncToCalendar: Bool?

    var wantsCalendarSync: Bool { syncToCalendar ?? true }
}
