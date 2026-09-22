import SwiftUI
import CoreLocation

/// 활동(체류형) 블록의 정보 보기·편집 화면. 이동 구간(ScheduledEvent)과 달리 경로·수단이 없어
/// EventDetailView보다 훨씬 단순하다(제목·장소·시작/종료 시각만 편집).
struct ActivityDetailView: View {
    let activityId: UUID
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    // 편집값 넷(제목·장소·시작·종료)은 전부 카드(card.fields)에 산다 — 옛 load()의 되읽기와
    // 저장 버튼의 판정이 카드 생성 한 번으로 대체된다(REQ-020). 화면이 들고 있는 것은 카드가
    // 가질 수 없는 것뿐: 좌표 사전, 검색 묶음, 주변 맛집, 삭제 대화상자.
    @State private var card: EditCard?
    /// 칩·후보를 탭한 순간 좌표까지 확정된 장소(이름 → 장소). chosen은 이름만 담으므로 여기서
    /// 되찾는다 — AddEventView.confirmedPlaces와 같은 형태고, 지연 해석 함수는 만들지 않는다
    /// (계약 5: 만들면 resolvePlace의 세 번째 구현이 된다).
    @State private var confirmedPlaces: [String: Place] = [:]
    /// 카드 검색 에디터의 묶음(350ms 지연·취소·같은 질의 스킵). 지연 상수는 이 타입이 단독으로
    /// 소유한다 — 화면이 들고 있으면 카카오 할당량 정책이 두 벌이 된다.
    @State private var placeDebounce = PlaceSearchDebouncer()
    @State private var showingDeleteMenu = false
    @State private var showingDeleteConfirm = false

    // 주변 맛집 추천(be full sir) — 실기기 테스트 피드백으로 이동 일정 상세에서 옮겨옴:
    // "식사하는 곳"인 활동 쪽에 있는 게 "이동하는 중"인 쪽보다 자연스럽다는 의견.
    @State private var nearby: [NearbyPlace] = []
    @State private var nearbyCategory: MealCategoryFilter = .restaurant
    @State private var loadingNearby = false
    @State private var nearbyLoaded = false

    /// "장소 없음" 칩의 값. 장소 없는 활동도 편집할 수 있어야 하는데 isReady는 모든 줄의 chosen을
    /// 전수로 보므로, 이 칩이 없으면 장소를 지운 편집을 저장할 수 없다. Store에는 절대 흘러가지
    /// 않고 save()에서 nil로 풀린다.
    private static let noPlaceMarker = "__no_place__"

    private var activity: ActivityBlock? {
        store.activities.first { $0.id == activityId }
    }

    private var placeCoord: CLLocationCoordinate2D? {
        guard let loc = activity?.location else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 카드는 이 자리에 무조건 둔다 — Group·AnyView·가변 .id로 감싸면 줄 에디터의
                    // 지역 상태가 매번 새 UUID로 앉아 장소 이름을 한 글자도 못 친다. nil→값 전이는
                    // .task가 딱 한 번 일으킨다.
                    if let card {
                        EditCardView(card: card, busy: false, actions: actions,
                                     chrome: EditCardChrome(header: nil, confirmTitle: nil))
                    }
                    if activity?.recurrenceId != nil {
                        Text("반복 일정의 한 회차입니다. 여기서 저장하면 이 날짜만 바뀝니다.")
                            .font(.footnote).foregroundStyle(Theme.muted)
                    }
                    if placeCoord != nil {
                        nearbySection
                    }
                    Button("삭제", role: .destructive) {
                        if activity?.recurrenceId != nil {
                            showingDeleteMenu = true
                        } else {
                            showingDeleteConfirm = true
                        }
                    }
                }
                .padding(24)
            }
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
                    Button("저장") { save() }.disabled(!(card?.isReady ?? false))
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
        // 카드는 저장된 활동에서 정확히 한 번 만든다 — 이후로는 줄을 제자리에서 고친다.
        .task { bootstrap() }
        // 시트가 내려가도 예약돼 있던 검색은 350ms 뒤 그대로 나간다 — 사라진 화면의 결과를 위해
        // 네트워크를 태우지 않는다는 정리 계약의 폼 쪽 이행이다(AddEventView와 같은 판단).
        .onDisappear {
            var d = placeDebounce
            d.cancelAll()
            placeDebounce = d
        }
    }

    /// 카드 뷰가 부르는 동작을 화면의 함수로 잇는 어댑터. rechooseTimeBasis·chooseTime는 이
    /// 카드에 기준 있는 시각 줄이 하나도 없어 올 수 없는 경로다 — 서명 채움일 뿐이고, 기준 없는
    /// 줄의 확정은 chooseTimePlain으로 간다.
    private var actions: EditCardActions {
        EditCardActions(
            chooseValue: { choose(field: $0, value: $1) },
            rechooseTimeBasis: { _, _ in },
            chooseTime: { _, _, _ in false },
            chooseTimePlain: { chooseTimePlain(field: $0, date: $1) },
            choosePlace: { choosePlace(field: $0, place: $1) },
            searchPlaces: { searchPlaces(field: $0, text: $1) },
            submitCustom: { submitCustom(field: $0, text: $1) },
            // 카드 쪽 확인 버튼은 크롬으로 꺼져 있지만 동작 자체는 화면의 저장이 곧 확인이다.
            confirm: { save() }
        )
    }

    // MARK: - 카드 만들기

    /// 화면이 뜨는 동안 딱 한 번, 저장된 활동에서 카드를 만든다. 편집 화면이므로 모든 줄이
    /// chosen으로 seed된다 — 기본값으로 덮으면 편집이 값을 조용히 바꾸는 게 된다.
    private func bootstrap() {
        guard card == nil, let a = activity else { return }
        // 즐겨찾기는 칩을 만드는 시점에 좌표까지 확정해 둔다 — 탭 순간에 되찾기만 한다.
        for fav in store.favorites { confirmedPlaces[fav.label] = fav.place }
        if let loc = a.location { confirmedPlaces[loc.name] = loc }
        card = EditCard(fields: [
            .init(key: "title", kind: .title, label: "제목", options: [], allowsCustom: true,
                  chosen: a.title),
            .init(key: "location_query", kind: .place, label: "장소", options: placeOptions,
                  allowsCustom: true, chosen: a.location?.name ?? Self.noPlaceMarker),
            // 활동의 시작·종료는 도착/출발 기준을 갖지 않는 시각이다(REQ-020) — 접두 없는 ISO로
            // seed하고 기준 칩도 생기지 않는다.
            .init(key: "start_iso", kind: .datetime, label: "시작", options: [], allowsCustom: false,
                  chosen: BesirTime.isoFormatter.string(from: a.startDate), anchored: false),
            .init(key: "end_iso", kind: .datetime, label: "종료", options: [], allowsCustom: false,
                  chosen: BesirTime.isoFormatter.string(from: a.endDate), anchored: false),
        ])
    }

    /// 장소 줄의 칩: 즐겨찾기 + "장소 없음".
    private var placeOptions: [EditField.Option] {
        store.favorites.map { .init(label: $0.label, value: $0.label) }
            + [.init(label: "장소 없음", value: Self.noPlaceMarker)]
    }

    // MARK: - 칩 선택 · 확정

    /// 칩을 탭했을 때. 이 카드에는 딸린 줄이 없어 값만 적으며, 장소가 바뀌면 주변 맛집 결과를
    /// 낡은 채로 두지 않는다.
    private func choose(field: UUID, value: String) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return }
        let key = c.fields[i].key
        let previous = c.fields[i].chosen
        c.fields[i].chosen = value
        if key == "location_query", previous != value {
            // 좌표가 달라질 장소를 골랐다는 뜻이다 — 비우지 않으면 저장 뒤 새 장소 이름 아래
            // 옛 장소의 식당이 남는다(§1.2의 결함이 형태만 바꿔 살아남는 경로, REQ-021).
            nearby = []
            nearbyLoaded = false
        }
        card = c
    }

    /// 검색 후보를 탭했을 때 — 이름은 chosen에, 좌표는 이 순간 확정한다(REQ-021). 옛 폼은 이름만
    /// 고르고 좌표는 옛 장소 것을 그대로 써서 "집"을 "회사"로 고치면 이름만 회사였다.
    private func choosePlace(field: UUID, place: Place) {
        confirmedPlaces[place.name] = place
        choose(field: field, value: place.name)
    }

    /// 직접입력(제목). 범위 밖은 받지 않는다 — 거절 표시는 카드 뷰가 띄운다. 장소 줄은 검색
    /// 에디터라 여기 오지 않는다.
    @discardableResult
    private func submitCustom(field: UUID, text: String) -> Bool {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }),
              let value = c.fields[i].accepts(text) else { return false }
        c.fields[i].chosen = value
        card = c
        return true
    }

    /// 기준 없는 시각 줄의 확인. 종료 줄은 시작보다 뒤여야 한다 — 옛 DatePicker의 in: startDate...
    /// 예방이 카드 문법에서는 확인 시점의 거절로 바뀐다(REQ-030(a)). 거절 문구에 유효 범위를
    /// 나열하지 않는 것은 프로젝트 규칙이다. false를 돌려주면 카드 뷰가 거절 문법을 띄운다.
    @discardableResult
    private func chooseTimePlain(field: UUID, date: Date) -> Bool {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return false }
        if c.fields[i].key == "end_iso",
           let startRaw = chosenIn("start_iso", c),
           let start = BesirTime.parseDatetime(startRaw)?.date,
           date <= start {
            c.fields[i].note = "종료는 시작보다 뒤여야 해요"
            card = c
            return false
        }
        c.fields[i].chosen = BesirTime.isoFormatter.string(from: date)
        // 거절 사유는 유효 확정과 함께 지운다 — 남아 있으면 방금 고른 값도 거절된 것처럼 보인다
        c.fields[i].note = nil
        if c.fields[i].key == "start_iso",
           let ei = c.fields.firstIndex(where: { $0.key == "end_iso" }),
           let endRaw = c.fields[ei].chosen,
           let end = BesirTime.parseDatetime(endRaw)?.date,
           end <= date {
            // 시작을 종료 뒤로 옮기면 확정된 종료는 무효가 된다 — 옛 폼이 종료>시작 판정으로
            // 저장을 막던 것의 계승. 줄 문법에서는 chosen을 비워 isReady를 다시 잠근다.
            c.fields[ei].chosen = nil
            c.fields[ei].note = "종료는 시작보다 뒤여야 해요"
        }
        card = c
        return true
    }

    // MARK: - 장소 검색

    /// 카드 검색 에디터의 입력. 묶음 정책(350ms 지연·취소·같은 질의 스킵)은 공용 디바운서가
    /// 단독으로 소유한다 — 이 화면이 지연 시간을 들면 카카오 할당량 정책이 두 벌이 된다.
    /// 검색 기준점은 없다 — 이 화면이 장소 후보를 우선할 근거 지점이 없다.
    private func searchPlaces(field: UUID, text: String) {
        var deb = placeDebounce
        switch deb.gate(field, text) {
        case .clear:
            placeDebounce = deb
            setLookup(field, .idle)
        case .skip:
            placeDebounce = deb
        case .fire(let q):
            placeDebounce = deb
            setLookup(field, .searching)
            var armed = placeDebounce
            armed.arm(field, q) {
                let found = await self.store.placeSearch.search(q, near: nil)
                guard !Task.isCancelled else { return }
                self.finishPlaceSearch(field: field, query: q, found: found)
            }
            placeDebounce = armed
        }
    }

    /// 완료 기록(noteDone)이 상태 반영보다 먼저다 — 이 순서를 바꾸면 첫 검색이 도는 중에 같은
    /// 질의를 다시 쳤을 때 유일한 결과가 버려지고 줄이 "찾는 중"에 갇힌다.
    private func finishPlaceSearch(field: UUID, query: String, found: [Place]) {
        var deb = placeDebounce
        deb.noteDone(field, query)
        placeDebounce = deb
        setLookup(field, found.isEmpty ? .empty
                  : .results(Array(found.prefix(AIAssistant.maxPlaceSuggestions))))
    }

    /// 검색 상태를 줄에 얹는다. await에서 돌아온 뒤 id로 다시 찾는다 — 줄이 없어졌으면 조용히
    /// 버린다(위험 부류 H1과 같은 이유로 잡아둔 자리에 쓰지 않는다).
    private func setLookup(_ field: UUID, _ lookup: EditField.Lookup) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return }
        c.fields[i].lookup = lookup
        card = c
    }

    // MARK: - 읽기 보조

    private func field(_ key: String) -> EditField? {
        card?.fields.first { $0.key == key }
    }

    private func chosenIn(_ key: String, _ c: EditCard) -> String? {
        c.fields.first(where: { $0.key == key })?.chosen
    }

    /// 줄의 chosen 이름으로 확정된 장소를 되찾는다 — "장소 없음" 칩은 좌표 사전에 없는 값이라 nil.
    private func confirmedPlace(_ key: String) -> Place? {
        field(key)?.chosen.flatMap { confirmedPlaces[$0] }
    }

    // MARK: - 저장 · 삭제

    private func save() {
        // 카드가 다 차 있어도 시각 해석은 여기서 한다 — isReady는 줄의 chosen만 본다.
        guard let a = activity,
              let start = field("start_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date,
              let end = field("end_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date else { return }
        // updateActivity가 아니라 modifyActivity를 쓴다 — 그래야 이 활동에 묶인 이동 구간도
        // 같이 옮겨진다(예전엔 여기서 시각을 고쳐도 이동 블록이 제자리에 남았다).
        store.modifyActivity(id: a.id,
                             newTitle: field("title")?.chosen ?? "",
                             newStart: start,
                             newEnd: end,
                             // 장소는 고른 시점에 좌표까지 확정된 것만 흘러간다 — "장소 없음" 칩은
                             // 좌표 사전에 없는 값이라 여기서 nil로 풀린다(REQ-021).
                             newPlace: confirmedPlace("location_query"))
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
    /// 좌표는 저장된 활동(store)의 것을 읽는다 — 카드에서 고른 중간값이 아니라 저장 결과가
    /// 근거여야 한다(REQ-021의 무효화 판단도 이 좌표 기준으로 짝지어 있다).
    @ViewBuilder
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주변").font(.headline)
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
