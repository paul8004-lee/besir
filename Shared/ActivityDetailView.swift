import SwiftUI
import CoreLocation

/// 활동(체류형) 블록의 정보 보기·편집 화면. 이동 구간(ScheduledEvent)과 달리 경로·수단이 없어
/// EventDetailView보다 훨씬 단순하다(제목·장소·시작/종료 시각만 편집).
struct ActivityDetailView: View {
    let activityId: UUID
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var locationName: String = ""
    @State private var locationAddress: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var showingDeleteMenu = false
    @State private var showingDeleteConfirm = false

    // 주변 맛집 추천(be full sir) — 실기기 테스트 피드백으로 이동 일정 상세에서 옮겨옴:
    // "식사하는 곳"인 활동 쪽에 있는 게 "이동하는 중"인 쪽보다 자연스럽다는 의견.
    @State private var nearby: [NearbyPlace] = []
    @State private var nearbyCategory: MealCategoryFilter = .restaurant
    @State private var loadingNearby = false
    @State private var nearbyLoaded = false

    private var activity: ActivityBlock? {
        store.activities.first { $0.id == activityId }
    }

    private var placeCoord: CLLocationCoordinate2D? {
        guard let loc = activity?.location else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("제목") {
                    TextField("제목", text: $title)
                }
                Section("장소") {
                    TextField("장소 이름", text: $locationName)
                    if !store.favorites.isEmpty {
                        Menu {
                            ForEach(store.favorites) { fav in
                                Button(fav.label) {
                                    locationName = fav.place.name
                                    locationAddress = fav.place.address
                                }
                            }
                        } label: {
                            Label("즐겨찾기에서 선택", systemImage: "star")
                        }
                    }
                }
                Section("시간") {
                    DatePicker("시작", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("종료", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                }
                if activity?.recurrenceId != nil {
                    Section {
                        Text("반복 일정의 한 회차입니다. 여기서 저장하면 이 날짜만 바뀝니다.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if placeCoord != nil {
                    nearbySection
                }
                Section {
                    Button("삭제", role: .destructive) {
                        if activity?.recurrenceId != nil {
                            showingDeleteMenu = true
                        } else {
                            showingDeleteConfirm = true
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("활동 편집")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("반복 일정을 어떻게 삭제할까요?", isPresented: $showingDeleteMenu, titleVisibility: .visible) {
                Button("전체 반복 일정 삭제", role: .destructive) { deleteWholeSeries() }
                Button("이 일정만 삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            }
            .confirmationDialog("이 활동을 삭제할까요?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard let a = activity else { return }
        title = a.title
        locationName = a.location?.name ?? ""
        locationAddress = a.location?.address ?? ""
        startDate = a.startDate
        endDate = a.endDate
    }

    private func save() {
        guard let a = activity else { return }
        let place = locationName.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil
            : Place(name: locationName, address: locationAddress,
                    latitude: a.location?.latitude ?? 0, longitude: a.location?.longitude ?? 0)
        // updateActivity가 아니라 modifyActivity를 쓴다 — 그래야 이 활동에 묶인 이동 구간도
        // 같이 옮겨진다(예전엔 여기서 시각을 고쳐도 이동 블록이 제자리에 남았다).
        store.modifyActivity(id: a.id,
                             newTitle: title,
                             newStart: startDate,
                             newEnd: endDate,
                             newPlace: place)
        dismiss()
    }

    private func delete() {
        guard let a = activity else { return }
        store.deleteActivity(a)
        dismiss()
    }

    private func deleteWholeSeries() {
        guard let rid = activity?.recurrenceId else { return }
        store.deleteRecurringSeries(rid)
        dismiss()
    }

    // MARK: - 주변 맛집 추천 (be full sir)

    /// 활동 장소 좌표를 기준으로 주변 음식점·카페를 보여준다.
    /// 펼쳐야만 조회한다 — 상세를 열 때마다 장소 검색 API를 쓰면 낭비다.
    @ViewBuilder
    private var nearbySection: some View {
        Section("주변") {
            HStack {
                Label("맛집 추천", systemImage: "fork.knife")
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
                Text("'\(activity?.location?.name ?? "이 장소")' 주변의 \(nearbyCategory.title)을(를) 찾아드려요.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
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
        guard let coord = placeCoord else { return }
        loadingNearby = true
        nearby = await store.placeSearch.nearbyPlaces(category: nearbyCategory, near: coord)
        loadingNearby = false
        nearbyLoaded = true
    }
}
