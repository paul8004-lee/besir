import SwiftUI
import CoreLocation

struct AddEventView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var location: LocationManager
    @Environment(\.dismiss) private var dismiss

    /// 편집할 기존 일정. nil이면 새 일정 추가.
    var editing: ScheduledEvent? = nil
    @State private var didLoadEditing = false

    @State private var title = ""

    // 출발지
    @State private var originPlace: Place?
    @State private var originQuery = ""
    @State private var originResults: [Place] = []
    @State private var originSearching = false

    // 목적지
    @State private var query = ""
    @State private var results: [Place] = []
    @State private var selectedPlace: Place?
    @State private var searching = false

    @State private var arrivalDate = Date().addingTimeInterval(3600)
    @State private var departureDate = Date().addingTimeInterval(3600)
    /// 사용자가 "도착 시각"과 "출발 시각" 중 어느 쪽을 직접 입력했는지에 따라 자동으로 정해진다
    /// (별도 선택 메뉴 없음) — 출발/도착 행 중 탭한 쪽이 기준이 된다.
    @State private var anchor: ScheduleAnchor = .arrival
    @State private var mode: TransportMode = .transit
    @State private var bufferMinutes = 5
    @State private var notifyLeadMinutes = 10

    @State private var notifyEnabled = true
    @State private var syncToCalendar = true

    @State private var estimates: [TransportMode: TravelEstimate] = [:]
    @State private var estimating = false
    @State private var saving = false

    private var originCoord: CLLocationCoordinate2D? {
        originPlace.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleField
                    originSection
                    destinationSection
                    if selectedPlace != nil && originPlace != nil {
                        arrivalSection
                        conflictWarning
                        modeSection
                        optionsSection
                    }
                }
                .padding(24)
            }
            Divider()
            footer
        }
        .background(Theme.bg)
        #if os(macOS)
        .frame(width: 640, height: 780)
        #endif
        .task {
            loadEditingIfNeeded()
            await prefillOrigin()
        }
    }

    private var header: some View {
        HStack {
            Text(editing == nil ? "새 일정" : "일정 편집").font(.title2).bold()
            Spacer()
            Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("일정 제목").font(.headline)
            TextField("예: 친구와 저녁 약속", text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - 출발지

    private var originSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("출발지").font(.headline)
            if let o = originPlace {
                HStack {
                    Image(systemName: "location.fill").foregroundStyle(Theme.travel)
                    VStack(alignment: .leading) {
                        Text(o.name).bold()
                        if !o.address.isEmpty {
                            Text(o.address).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("변경") { originPlace = nil; originResults = []; estimates = [:] }
                        .buttonStyle(.borderless)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Button { useCurrentAsOrigin() } label: {
                    if location.isLocating {
                        HStack { ProgressView().controlSize(.small); Text("현재 위치 확인 중…") }
                    } else {
                        Label("현재 위치 사용", systemImage: "location.fill")
                    }
                }
                .disabled(location.isLocating)
                favoriteChips { selectOrigin($0) }
                HStack {
                    TextField("또는 출발지 검색 (예: 집, 회사)", text: $originQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { runOriginSearch() }
                    Button { runOriginSearch() } label: {
                        if originSearching { ProgressView().controlSize(.small) }
                        else { Image(systemName: "magnifyingglass") }
                    }
                }
                ForEach(originResults, id: \.name) { place in
                    Button { selectOrigin(place) } label: {
                        HStack {
                            Image(systemName: "mappin.circle")
                            VStack(alignment: .leading) {
                                Text(place.name)
                                Text(place.address).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }

    // MARK: - 목적지

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("목적지").font(.headline)
            if selectedPlace == nil {
                favoriteChips { place in
                    selectedPlace = place
                    Task { await recomputeEstimates() }
                }
            }
            HStack {
                TextField("장소·주소 검색 (예: 강남역, 서울시청)", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runSearch() }
                Button { runSearch() } label: {
                    if searching { ProgressView().controlSize(.small) }
                    else { Image(systemName: "magnifyingglass") }
                }
            }
            if let p = selectedPlace {
                HStack {
                    Image(systemName: "flag.fill").foregroundStyle(Theme.warn)
                    VStack(alignment: .leading) {
                        Text(p.name).bold()
                        Text(p.address).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("변경") { selectedPlace = nil; estimates = [:] }
                        .buttonStyle(.borderless)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(results, id: \.name) { place in
                    Button {
                        selectedPlace = place
                        results = []
                        Task { await recomputeEstimates() }
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle")
                            VStack(alignment: .leading) {
                                Text(place.name)
                                Text(place.address).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
    }

    /// 출발/도착 시각 중 사용자가 실제로 편집한 쪽만 기준(anchor)이 되고, 나머지 한쪽은 이동시간이
    /// 계산된 뒤에만 예상값을 보여준다(그 전엔 "설정 안 함" — 아직 정해지지 않은 값을 미리 보여주면
    /// 혼동만 준다). 별도 선택 메뉴 없이 어느 필드를 만졌는지로 자동 결정된다.
    private var arrivalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            timeRow(kind: .departure, label: "출발 시각", date: $departureDate)
            timeRow(kind: .arrival, label: "도착 시각", date: $arrivalDate)
            Text(anchor == .arrival
                 ? "도착 시각을 기준으로 출발 시각을 역산합니다."
                 : "출발 시각을 기준으로 도착 시각을 순산합니다(귀가처럼 출발이 우선일 때). 버퍼는 적용되지 않습니다.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    /// anchor와 같은 쪽이면 실제 편집 가능한 DatePicker를, 다른 쪽이면 탭해서 기준을 바꾸는
    /// 읽기 전용 행을 보여준다(이동시간 계산 전엔 "설정 안 함"만 표시).
    @ViewBuilder
    private func timeRow(kind: ScheduleAnchor, label: String, date: Binding<Date>) -> some View {
        if anchor == kind {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.headline)
                DatePicker("", selection: date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    #if os(macOS)
                    .datePickerStyle(.field)
                    #else
                    .datePickerStyle(.compact)
                    #endif
                    .labelsHidden()
            }
        } else {
            Button {
                anchor = kind
            } label: {
                HStack {
                    Text(label).font(.headline).foregroundStyle(.primary)
                    Spacer()
                    if let preview = computedPreview(for: kind) {
                        Text(preview).foregroundStyle(.secondary)
                    } else {
                        Text("설정 안 함").foregroundStyle(.tertiary)
                    }
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// 지금 입력값 그대로 저장하면 겹치게 되는 기존 블록.
    /// 이동시간을 아직 모르면(장소 미선택·계산 실패) 차지할 범위를 알 수 없어 빈 배열.
    private var currentConflicts: [Store.Conflict] {
        guard let secs = estimates[mode]?.duration else { return [] }
        let dep: Date
        let arr: Date
        switch anchor {
        case .arrival:
            arr = arrivalDate
            dep = arrivalDate.addingTimeInterval(-secs - Double(bufferMinutes) * 60)
        case .departure:
            dep = departureDate
            arr = departureDate.addingTimeInterval(secs)
        }
        return store.conflicts(departure: dep, arrival: arr,
                               recurrenceId: editing?.recurrenceId,
                               excludingEventId: editing?.id)
    }

    /// 겹침은 막지 않고 알려만 준다 — 일부러 겹치게 잡는 경우도 있어서(잠깐 빠져나갔다 오기 등)
    /// 저장을 막으면 오히려 불편하다.
    @ViewBuilder
    private var conflictWarning: some View {
        ConflictBanner(title: "기존 일정과 시간이 겹쳐요",
                       conflicts: currentConflicts,
                       formatter: depFmt)
    }

    /// anchor가 아닌 쪽 필드에 보여줄 예상값. 이동시간이 아직 없으면(장소 미선택 등) nil.
    private func computedPreview(for kind: ScheduleAnchor) -> String? {
        guard let secs = estimates[mode]?.duration else { return nil }
        switch kind {
        case .arrival:
            guard anchor == .departure else { return nil }
            return depFmt.string(from: departureDate.addingTimeInterval(secs))
        case .departure:
            guard anchor == .arrival else { return nil }
            return depFmt.string(from: arrivalDate.addingTimeInterval(-secs - Double(bufferMinutes) * 60))
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("이동 수단").font(.headline)
                if estimating { ProgressView().controlSize(.small) }
                Spacer()
                Button { Task { await recomputeEstimates() } } label: {
                    Image(systemName: "arrow.clockwise")
                }.buttonStyle(.borderless).help("소요시간 다시 계산")
            }
            HStack(spacing: 10) {
                ForEach(TransportMode.allCases) { m in
                    modeCard(m)
                }
            }
        }
    }

    private func modeCard(_ m: TransportMode) -> some View {
        let est = estimates[m]
        let selected = mode == m
        return Button {
            mode = m
        } label: {
            VStack(spacing: 6) {
                Image(systemName: m.systemImage).font(.title2)
                Text(m.title).font(.caption)
                Text(est?.durationText ?? "—")
                    .font(.headline)
                    .foregroundStyle(est?.isAvailable == true ? .primary : .secondary)
                if let s = est?.source {
                    Text(s).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? AnyShapeStyle(.tint.opacity(0.18)) : AnyShapeStyle(.quaternary),
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(selected ? Theme.travel : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 출발 시각이 기준(anchor == .departure)이면 도착 여유를 둘 필요가 없다(도착은 그냥
            // 출발 + 이동시간) — 그래서 버퍼 조절은 도착 기준일 때만 보여준다.
            if anchor == .arrival {
                Stepper("도착 여유(버퍼): \(bufferMinutes)분", value: $bufferMinutes, in: 0...60, step: 5)
            }
            Toggle("출발 알림 받기", isOn: $notifyEnabled)
            if notifyEnabled {
                Stepper("출발 \(notifyLeadMinutes)분 전에 알림", value: $notifyLeadMinutes, in: 0...60, step: 5)
            }
            if store.config.hasGoogleCalendar && store.config.autoAddToCalendar {
                Toggle("구글 캘린더에도 등록", isOn: $syncToCalendar)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("취소") { dismiss() }
            Button {
                Task { await save() }
            } label: {
                if saving { ProgressView().controlSize(.small) }
                else { Text(editing == nil ? "추가" : "저장") }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canSave)
        }
        .padding()
    }

    private var canSave: Bool {
        selectedPlace != nil && originPlace != nil && !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var depFmt: DateFormatter {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d (E) a h시 mm분"; return f
    }

    /// 즐겨찾기 장소를 가로 칩으로 보여준다(있을 때만).
    @ViewBuilder
    private func favoriteChips(onSelect: @escaping (Place) -> Void) -> some View {
        if !store.favorites.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.favorites) { fav in
                        Button(fav.label) { onSelect(fav.place) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - 동작

    /// 편집 모드면 기존 일정 값으로 폼을 채운다.
    private func loadEditingIfNeeded() {
        guard let e = editing, !didLoadEditing else { return }
        didLoadEditing = true
        title = e.title
        originPlace = e.origin
        selectedPlace = e.destination
        arrivalDate = e.arrivalDate
        departureDate = e.departureDate ?? e.arrivalDate
        anchor = e.anchor ?? .arrival
        mode = e.mode
        bufferMinutes = e.bufferMinutes
        notifyLeadMinutes = e.notifyLeadMinutes
        notifyEnabled = e.wantsNotification
        syncToCalendar = e.wantsCalendarSync
        Task { await recomputeEstimates() }
    }

    /// 화면이 뜨면 현재 위치를 출발지 기본값으로 채운다(최대 5초 대기).
    private func prefillOrigin() async {
        guard originPlace == nil else { return }
        if location.currentLocation == nil { location.useCurrentLocation() }
        for _ in 0..<25 {
            if let c = location.currentLocation {
                originPlace = Place(name: location.currentPlaceName ?? "현재 위치",
                                    address: "", latitude: c.latitude, longitude: c.longitude)
                await recomputeEstimates()
                return
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func useCurrentAsOrigin() {
        if let c = location.currentLocation {
            originPlace = Place(name: location.currentPlaceName ?? "현재 위치",
                                address: "", latitude: c.latitude, longitude: c.longitude)
            Task { await recomputeEstimates() }
        } else {
            location.useCurrentLocation()
            Task { await prefillOrigin() }
        }
    }

    private func selectOrigin(_ place: Place) {
        originPlace = place
        originResults = []
        Task { await recomputeEstimates() }
    }

    private func runOriginSearch() {
        guard originQuery.count >= 2 else { return }
        originSearching = true
        Task {
            let found = await store.placeSearch.search(originQuery, near: location.currentLocation)
            await MainActor.run { originResults = found; originSearching = false }
        }
    }

    private func runSearch() {
        guard query.count >= 2 else { return }
        searching = true
        Task {
            let found = await store.placeSearch.search(query, near: originCoord ?? location.currentLocation)
            await MainActor.run { results = found; searching = false }
        }
    }

    private func recomputeEstimates() async {
        guard let place = selectedPlace, let origin = originCoord else { return }
        estimating = true
        let dest = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        let all = await store.directions.estimateAll(from: origin, to: dest)
        await MainActor.run {
            estimates = all
            estimating = false
        }
    }

    private func save() async {
        guard let place = selectedPlace, let origin = originPlace else { return }
        saving = true
        // anchor == .arrival이면 arrivalDate가, .departure면 departureDate가 "기준 시각"이다
        // (store 쪽 arrivalDate 파라미터는 그 기준 시각을 받아 안에서 방향에 맞게 처리한다).
        let anchorDate = anchor == .arrival ? arrivalDate : departureDate
        if let e = editing {
            await store.updateEvent(id: e.id,
                                    title: title,
                                    origin: origin,
                                    destination: place,
                                    arrivalDate: anchorDate,
                                    mode: mode,
                                    bufferMinutes: bufferMinutes,
                                    notifyLeadMinutes: notifyLeadMinutes,
                                    anchor: anchor,
                                    notifyEnabled: notifyEnabled,
                                    syncToCalendar: syncToCalendar)
        } else {
            await store.addEvent(title: title,
                                 origin: origin,
                                 destination: place,
                                 arrivalDate: anchorDate,
                                 mode: mode,
                                 bufferMinutes: bufferMinutes,
                                 notifyLeadMinutes: notifyLeadMinutes,
                                 anchor: anchor,
                                 notifyEnabled: notifyEnabled,
                                 syncToCalendar: syncToCalendar)
        }
        saving = false
        dismiss()
    }
}

/// 겹치는 일정을 알려주는 배너. 이동 일정 화면과 활동 화면이 같은 모양을 쓰므로 한 곳에 둔다
/// (두 화면에 복제해두면 문구·색을 고칠 때 한쪽만 고치는 실수가 난다).
struct ConflictBanner: View {
    let title: String
    let conflicts: [Store.Conflict]
    /// 시각 표기에 쓸 포맷터. nil이면 시각 없이 제목만 보여준다.
    var formatter: DateFormatter? = nil

    var body: some View {
        if !conflicts.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.warn)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline).bold()
                    ForEach(Array(conflicts.enumerated()), id: \.offset) { _, c in
                        Text(label(for: c)).font(.caption).foregroundStyle(.secondary)
                    }
                    Text("그래도 저장할 수 있어요. 겹치지 않게 하려면 시각을 조정하세요.")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(10)
            .background(Theme.warnFill, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func label(for c: Store.Conflict) -> String {
        guard let formatter else { return c.title }
        return "\(c.title) · \(formatter.string(from: c.start)) ~ \(formatter.string(from: c.end))"
    }
}
