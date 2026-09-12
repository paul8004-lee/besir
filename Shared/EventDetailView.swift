import SwiftUI
import CoreLocation

struct EventDetailView: View {
    /// 푸시 시점에 전달된 값(폴백). 실제로는 store에서 최신 값을 읽는다.
    private let passedEvent: ScheduledEvent
    @EnvironmentObject var store: Store
    @EnvironmentObject var location: LocationManager

    init(event: ScheduledEvent) { self.passedEvent = event }

    /// 항상 store의 최신 일정을 사용한다. (편집으로 수단 등을 바꿔도 즉시 반영)
    private var event: ScheduledEvent {
        store.events.first { $0.id == passedEvent.id } ?? passedEvent
    }

    private static let fullFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h시 mm분"; return f
    }()
    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h시 mm분"; return f
    }()
    /// 경로 안내 단계 옆에 붙는 짧은 시각("오후 3:05").
    private static let shortTimeFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h:mm"; return f
    }()

    @Environment(\.dismiss) private var dismiss

    @State private var routeSegments: [RouteSegment] = []
    @State private var transitSteps: [TransitStep] = []
    @State private var showingEdit = false
    @State private var showingDeleteMenu = false
    @State private var showingDeleteConfirm = false
    @State private var calendarStatus = ""
    @State private var addingToCalendar = false

    // 주변 맛집 추천(be full sir).
    @State private var nearby: [NearbyPlace] = []
    @State private var nearbyCategory: MealCategoryFilter = .restaurant
    @State private var loadingNearby = false
    @State private var nearbyLoaded = false

    private var destCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: event.destination.latitude, longitude: event.destination.longitude)
    }

    /// 이 일정의 출발지 좌표(저장된 출발지 우선, 없으면 현재 위치).
    private var originCoord: CLLocationCoordinate2D? {
        if let o = event.origin {
            return CLLocationCoordinate2D(latitude: o.latitude, longitude: o.longitude)
        }
        return location.originCoordinate
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                mapView
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                departureCard

                transitItinerary

                calendarButton

                nearbySection

                detailRows
            }
            .padding(24)
        }
        .background(Theme.bg)
        .navigationTitle(event.title)
        // 처음 표시 + 일정의 수단·출발지·목적지가 바뀔 때마다 경로 재로딩.
        .onChange(of: transitTaskKey, initial: true) { Task { await loadTransitPath() } }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: { Label("편집", systemImage: "pencil") }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEventView(editing: event)
        }
    }

    // MARK: - 주변 맛집 추천 (be full sir)

    /// 목적지 좌표를 기준으로 주변 음식점·카페를 보여준다.
    /// 화면을 열자마자 부르지 않고 사용자가 펼쳤을 때만 조회한다 — 일정 상세를 열 때마다
    /// 장소 검색 API를 쓰면 낭비이고, 대부분은 경로만 확인하고 닫는다.
    @ViewBuilder
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("목적지 주변", systemImage: "fork.knife")
                    .font(.headline)
                Spacer()
                if loadingNearby { ProgressView().controlSize(.small) }
                Button(nearbyLoaded ? "새로고침" : "추천 보기") {
                    Task { await loadNearby() }
                }
                .buttonStyle(.borderless)
                .disabled(loadingNearby)
            }

            if nearbyLoaded {
                Picker("종류", selection: $nearbyCategory) {
                    ForEach(MealCategoryFilter.allCases) { c in
                        Label(c.title, systemImage: c.systemImage).tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: nearbyCategory) { Task { await loadNearby() } }

                if nearby.isEmpty && !loadingNearby {
                    Text("주변 1km 안에서 찾지 못했어요.")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    ForEach(nearby) { item in
                        nearbyRow(item)
                    }
                }
            } else {
                Text("'\(event.destination.name)' 주변의 \(nearbyCategory.title)을(를) 찾아드려요.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func nearbyRow(_ item: NearbyPlace) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: nearbyCategory.systemImage)
                .foregroundStyle(Theme.activity)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.place.name).font(.subheadline).bold()
                HStack(spacing: 6) {
                    if !item.category.isEmpty {
                        Text(item.category).font(.caption).foregroundStyle(.secondary)
                    }
                    if let d = item.distanceText {
                        Text("· \(d)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if !item.place.address.isEmpty {
                    Text(item.place.address).font(.caption2).foregroundStyle(.tertiary).lineLimit(1)
                }
            }
            Spacer()
            if let urlString = item.url, let url = URL(string: urlString) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadNearby() async {
        loadingNearby = true
        nearby = await store.placeSearch.nearbyPlaces(category: nearbyCategory, near: destCoord)
        loadingNearby = false
        nearbyLoaded = true
    }

    /// 일정의 이동수단·출발지·목적지가 바뀌면 경로를 다시 불러오기 위한 키.
    /// 수단(mode)을 포함해야 편집으로 수단을 바꿨을 때 즉시 경로가 갱신된다.
    private var transitTaskKey: String {
        let o = originCoord
        return "\(event.id)-\(event.mode.rawValue)-\(o?.latitude ?? 0),\(o?.longitude ?? 0)-\(destCoord.latitude),\(destCoord.longitude)"
    }

    @ViewBuilder
    private var mapView: some View {
        if store.config.hasKakaoJs {
            KakaoMapView(jsKey: store.config.kakaoJsKey,
                         origin: originCoord,
                         destination: destCoord,
                         destinationName: event.destination.name,
                         mode: event.mode,
                         segments: routeSegments)
        } else {
            RouteMapView(origin: originCoord,
                         destination: destCoord,
                         destinationName: event.destination.name)
        }
    }

    @ViewBuilder
    private var calendarButton: some View {
        Group {
            if store.config.hasGoogleCalendar {
                if event.googleEventId != nil {
                    Label("구글 캘린더에 등록됨", systemImage: "checkmark.circle.fill")
                        .font(.callout).foregroundStyle(.green)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            Task { await addToGoogleCalendar() }
                        } label: {
                            Label(addingToCalendar ? "추가 중…" : "구글 캘린더에 추가",
                                  systemImage: "calendar.badge.plus")
                        }
                        .disabled(addingToCalendar)
                        if !calendarStatus.isEmpty {
                            Text(calendarStatus).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func addToGoogleCalendar() async {
        addingToCalendar = true
        calendarStatus = ""
        defer { addingToCalendar = false }
        await store.pushToCalendar(eventID: event.id)
        if event.googleEventId == nil {
            calendarStatus = "추가 실패 — 구글 로그인을 확인하세요."
        }
    }

    private func loadTransitPath() async {
        routeSegments = []
        transitSteps = []
        guard let origin = originCoord else { return }
        switch event.mode {
        case .transit:
            guard store.config.hasProxy else { return }
            let plan = await store.directions.transitPlan(from: origin, to: destCoord)
            routeSegments = plan.segments
            transitSteps = plan.steps
        case .car:
            routeSegments = await store.directions.carRouteSegments(from: origin, to: destCoord)
        case .walk:
            routeSegments = await store.directions.walkRouteSegments(from: origin, to: destCoord)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(event.destination.name, systemImage: "flag.fill")
                .font(.title2).bold()
            if !event.destination.address.isEmpty {
                Text(event.destination.address).foregroundStyle(.secondary)
            }
            Label("도착 \(Self.fullFmt.string(from: event.arrivalDate))", systemImage: "clock")
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var departureCard: some View {
        if let dep = event.departureDate, let travel = event.travelSeconds {
            let minutes = Int((travel / 60).rounded())
            let isPast = dep < Date()
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: event.mode.systemImage)
                    Text("\(event.mode.title)로 약 \(minutes)분")
                        .font(.headline)
                    Spacer()
                }
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    Text("출발 시각")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Self.timeFmt.string(from: dep))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(isPast ? .red : .green)
                }
                if isPast {
                    Text("⚠️ 이미 출발 시각이 지났습니다.")
                        .font(.caption).foregroundStyle(Theme.warn)
                } else {
                    Text("출발까지 \(relativeText(to: dep)) 남음 · \(event.notifyLeadMinutes)분 전 알림 예약됨")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(18)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        } else {
            Label("이동시간을 계산하지 못했습니다. (출발지/대중교통 정보 확인)",
                  systemImage: "exclamationmark.triangle")
                .foregroundStyle(Theme.activity)
                .padding()
        }
    }

    /// 대중교통 환승 안내: 어떤 노선을 몇 시에 타는지 단계별로 보여준다.
    @ViewBuilder
    private var transitItinerary: some View {
        if event.mode == .transit, !transitSteps.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("이동 경로", systemImage: "arrow.triangle.turn.up.right.diamond")
                        .font(.headline)
                    Spacer()
                    if event.departureDate != nil {
                        Text("예상 시각")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 6)

                ForEach(Array(transitSteps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step,
                            at: stepStartTime(index),
                            isLast: index == transitSteps.count - 1)
                }

                Text("ODsay 실시간 시간표가 아닌 평균 소요시간 기준 예상값입니다.")
                    .font(.caption2).foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding(18)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func stepRow(_ step: TransitStep, at time: Date?, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: step.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(hex: step.color), in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(minHeight: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.headline).font(.callout).bold()
                Text(step.detail).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.top, 3)

            Spacer(minLength: 8)

            if let time {
                Text(Self.shortTimeFmt.string(from: time))
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.top, 5)
            }
        }
    }

    /// index번째 단계가 시작되는 예상 시각 = 출발 시각 + 앞선 단계들의 소요시간 합.
    private func stepStartTime(_ index: Int) -> Date? {
        guard let departure = event.departureDate else { return nil }
        let elapsed = transitSteps.prefix(index).reduce(0) { $0 + $1.minutes }
        return departure.addingTimeInterval(Double(elapsed) * 60)
    }

    /// recurrenceId가 없어도(옛날에 반복 대신 낱개로 여러 날 따로 만들어진 경우 등) 제목이 완전히
    /// 같은 일정이 여러 건 있으면 그것도 "일괄 삭제" 대상으로 봐준다 — recurrenceId만 보면 이런
    /// 낱개 중복들은 하나씩만 지울 수 있어 여러 건을 한 번에 정리할 방법이 없었다.
    private var sameTitleEvents: [ScheduledEvent] {
        store.events.filter { $0.title == event.title }
    }

    private var detailRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("이동 수단", "\(event.mode.title)")
            row("도착 여유(버퍼)", "\(event.bufferMinutes)분")
            row("알림", "출발 \(event.notifyLeadMinutes)분 전")
            if event.recurrenceId != nil {
                Label("반복 일정", systemImage: "repeat")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button(role: .destructive) {
                    if event.recurrenceId != nil || sameTitleEvents.count > 1 {
                        showingDeleteMenu = true
                    } else {
                        showingDeleteConfirm = true
                    }
                } label: {
                    Label("일정 삭제", systemImage: "trash")
                }
            }
            .padding(.top, 8)
        }
        .confirmationDialog("반복 일정을 어떻게 삭제할까요?", isPresented: $showingDeleteMenu, titleVisibility: .visible) {
            Button(event.recurrenceId != nil ? "전체 반복 일정 삭제" : "같은 제목 일정 모두 삭제(\(sameTitleEvents.count)건)",
                   role: .destructive) {
                if let rid = event.recurrenceId {
                    store.deleteRecurringSeries(rid)
                } else {
                    for e in sameTitleEvents { store.deleteEvent(e) }
                }
                dismiss()
            }
            Button("이 일정만 삭제", role: .destructive) {
                store.deleteEvent(event)
                dismiss()
            }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("이 일정을 삭제할까요?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                store.deleteEvent(event)
                dismiss()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(.secondary)
            Spacer()
            Text(v).bold()
        }
        .font(.callout)
    }

    private func relativeText(to date: Date) -> String {
        let secs = Int(date.timeIntervalSinceNow)
        let m = secs / 60
        if m < 60 { return "\(m)분" }
        return "\(m / 60)시간 \(m % 60)분"
    }
}

extension Color {
    /// 노선 색상 문자열("#00A84D")을 Color로. 지도 폴리라인과 같은 값을 공유한다.
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let value = UInt64(cleaned, radix: 16) ?? 0
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
