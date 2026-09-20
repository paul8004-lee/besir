import SwiftUI
import CoreLocation

struct AddEventView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var location: LocationManager
    @Environment(\.dismiss) private var dismiss

    /// 편집할 기존 일정. nil이면 새 일정 추가.
    var editing: ScheduledEvent? = nil

    // 폼의 값은 전부 카드(card.fields)에 산다 — 제출 판정도 card.isReady 하나다(REQ-020). 화면이
    // 들고 있는 것은 카드가 가질 수 없는 것뿐: 좌표 사전, 이동시간 캐시, 진행 깃발, 그리고 줄이
    // 배열에서 빠져 있는 동안 그 값을 기억하는 상태들.
    @State private var card: EditCard?
    /// 칩·후보를 탭한 순간 좌표까지 확정된 장소(이름 → 장소). chosen은 이름만 담으므로 여기서
    /// 되찾는다 — AIAssistant.confirmedPlaces와 같은 형태고, 지연 해석 함수는 만들지 않는다
    /// (REQ-020: 만들면 resolvePlace의 두 번째 구현이 된다).
    @State private var confirmedPlaces: [String: Place] = [:]
    @State private var estimates: [TransportMode: TravelEstimate] = [:]
    @State private var estimating = false
    @State private var saving = false
    /// 알림 줄이 토글 꺼짐으로 배열에서 빠져 있는 동안 마지막 값을 기억한다(REQ-022(b)) — 다시
    /// 켜면 이 값으로 되심는다.
    @State private var lastNotifyLead = "10"
    /// 캘린더 줄이 설정 조건으로 아예 없을 때 저장에 쓸 값. 줄이 화면에 있으면 카드가 정답이다.
    @State private var calendarDefault = true
    /// 상태 래퍼로 감싼 이유: gate·arm·noteDone은 구조체를 고치는 호출이라, 래퍼 저장소를 향해
    /// 복사해 내보냈다 도로 반영해야 이 화면 안에서 정책 상태가 산다.
    @State private var placeDebounce = PlaceSearchDebouncer()

    /// "현재 위치" 칩의 값. AIAssistant.currentLocationToken과 같은 사정(빈 값과의 구분)으로
    /// 내부 토큰을 쓰되, 이 화면의 값은 모델로 흘러가지 않으므로 여기 private로 따로 둔다.
    private static let hereMarker = "__current_location__"

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 카드는 이 자리에 무조건 둔다 — Group·AnyView·가변 .id로 감싸면 줄 에디터의
                    // 지역 상태(draft 등)가 매번 새 UUID로 앉아 장소 이름을 한 글자도 못 친다
                    // (REQ-021(b)). nil→값 전이는 .task가 딱 한 번 일으킨다.
                    if let card {
                        EditCardView(card: card, busy: saving, actions: actions,
                                     chrome: EditCardChrome(header: nil, confirmTitle: nil))
                    }
                    ConflictBanner(title: "기존 일정과 시간이 겹쳐요",
                                   conflicts: currentConflicts,
                                   formatter: BesirTime.compact)
                    // 카드 아래 화면 소유 재계산 — 아이콘 + .help만으로는 iOS VoiceOver에서 이름이
                    // 없는 버튼이어서 글자 라벨을 얻었다(REQ-022(d)).
                    if hasTimeRow {
                        Button {
                            Task { await recomputeEstimates() }
                        } label: {
                            Label("소요시간 다시 계산", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
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
        // 카드는 정확히 한 번 만든다(REQ-021(a)) — 이후로는 줄을 제자리에서 고치거나 넣고 뺀다.
        .task { await bootstrap() }
        // 카드 뷰는 순수 값 뷰라 외부 상태를 스스로 못 본다 — 진행 깃발을 줄의 busy로 명시적으로
        // 잇는다. 잊으면 동작은 돼도 진행 표시가 조용히 안 뜬다(REQ-021(c), 휴면 계약).
        .onChange(of: estimating) { _, on in setBusy(key: "mode", on) }
        .onChange(of: location.isLocating) { _, on in setBusy(key: "origin_query", on) }
    }

    private var header: some View {
        HStack {
            Text(editing == nil ? "새 일정" : "일정 편집").font(.title2).bold()
            Spacer()
            Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding()
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
            .disabled(!(card?.isReady ?? false))
        }
        .padding()
    }

    /// 카드 뷰가 부르는 일곱 동작을 화면의 함수로 잇는 어댑터 — 컴포넌트는 이 묶음 너머를 모른다.
    private var actions: EditCardActions {
        EditCardActions(
            chooseValue: { choose(field: $0, value: $1) },
            rechooseTimeBasis: { rechooseTimeBasis(field: $0, basis: $1) },
            chooseTime: { chooseTime(field: $0, basis: $1, date: $2) },
            choosePlace: { choosePlace(field: $0, place: $1) },
            searchPlaces: { searchPlaces(field: $0, text: $1) },
            submitCustom: { submitCustom(field: $0, text: $1) },
            // 카드 쪽 확인 버튼은 크롬으로 꺼져 있지만 동작 자체는 화면의 저장이 곧 확인이다.
            confirm: { await save() }
        )
    }

    // MARK: - 카드 만들기

    /// 시트가 뜨는 동안 딱 한 번: 카드를 만들고, 편집 모드면 이동시간을 미리 계산해 두고, 출발지가
    /// 비어 있으면(새 일정·옛 일정) 현재 위치로 프리필한다.
    private func bootstrap() async {
        guard card == nil else { return }
        card = buildCard()
        if let e = editing {
            // 줄이 없을 수 있는 값들도 저장에 쓰는 기본값은 이벤트에서 가져온다
            lastNotifyLead = String(e.notifyLeadMinutes)
            calendarDefault = e.wantsCalendarSync
            await recomputeEstimates()
        }
        await prefillOrigin()
    }

    private func buildCard() -> EditCard {
        // 즐겨찾기는 칩을 만드는 시점에 좌표까지 확정해 둔다(REQ-020) — 탭 순간에 되찾기만 한다.
        for fav in store.favorites { confirmedPlaces[fav.label] = fav.place }
        var originOptions = store.favorites.map { EditField.Option(label: $0.label, value: $0.label) }
        originOptions.append(.init(label: "현재 위치", value: Self.hereMarker))
        // 편집 모드는 값이 이미 있으니 에디터를 열어두지 않는다 — startsOpen은 "새 일정마다
        // 반드시 새로 치는 값"(REQ-003)을 위한 깃발이다.
        let fresh = editing == nil
        var fields: [EditField] = [
            .init(key: "title", kind: .title, label: "일정 제목", options: [], allowsCustom: true,
                  chosen: editing?.title, startsOpen: fresh),
            .init(key: "origin_query", kind: .place, label: "출발지", options: originOptions,
                  allowsCustom: true, busy: location.isLocating),
            .init(key: "destination_query", kind: .place, label: "목적지",
                  options: store.favorites.map { .init(label: $0.label, value: $0.label) },
                  allowsCustom: true, chosen: editing?.destination.name, startsOpen: fresh),
        ]
        if let e = editing {
            confirmedPlaces[e.destination.name] = e.destination
            // 옛 일정은 출발지가 nil일 수 있다 — 그러면 시각 줄 이하는 출발지가 정해진 뒤에
            // 생긴다(ensureGatedRows). 그때도 이벤트의 값으로 seed한다.
            if let o = e.origin {
                confirmedPlaces[o.name] = o
                fields.append(contentsOf: gatedRows(
                    datetime: editingDatetime(e), mode: e.mode.rawValue,
                    buffer: String(e.bufferMinutes), notifyOn: String(e.wantsNotification),
                    lead: String(e.notifyLeadMinutes), calendar: String(e.wantsCalendarSync)))
            }
        }
        return EditCard(fields: fields)
    }

    /// 출발지·목적지가 모두 골라지면 시각 줄 이하를 만든다 — 옛 화면의
    /// `if selectedPlace != nil && originPlace != nil` 조건부 섹션이 줄 멤버십으로 사는 자리다.
    private var hasTimeRow: Bool {
        card?.fields.contains { $0.key == "arrival_iso" } ?? false
    }

    private func ensureGatedRows() {
        guard var c = card, !hasTimeRow,
              c.fields.first(where: { $0.key == "origin_query" })?.chosen != nil,
              c.fields.first(where: { $0.key == "destination_query" })?.chosen != nil else { return }
        if let e = editing {
            // 늦게 생기는 줄도 편집 대상의 값으로 seed한다 — 기본값으로 덮으면 편집이 값을
            // 조용히 바꾸는 게 된다.
            c.fields.append(contentsOf: gatedRows(
                datetime: editingDatetime(e), mode: e.mode.rawValue,
                buffer: String(e.bufferMinutes), notifyOn: String(e.wantsNotification),
                lead: String(e.notifyLeadMinutes), calendar: String(e.wantsCalendarSync)))
        } else {
            // 폼의 문서화된 기본값 — 사용자가 보고 바꾸는 값이다(모델이 조용히 정한 값과 다르다)
            c.fields.append(contentsOf: gatedRows(datetime: nil, mode: TransportMode.transit.rawValue,
                                                  buffer: "5", notifyOn: "true", lead: "10",
                                                  calendar: "true"))
        }
        card = c
        syncFieldExtras()
    }

    /// 편집 대상의 시각 줄 값. departure 기준에서 departureDate가 없으면 arrivalDate로 둔다 —
    /// 옛 loadEditing과 같은 판단.
    private func editingDatetime(_ e: ScheduledEvent) -> String {
        if (e.anchor ?? .arrival) == .arrival {
            return "arr:" + BesirTime.isoFormatter.string(from: e.arrivalDate)
        }
        return "dep:" + BesirTime.isoFormatter.string(from: e.departureDate ?? e.arrivalDate)
    }

    private func gatedRows(datetime: String?, mode: String, buffer: String, notifyOn: String,
                           lead: String, calendar: String) -> [EditField] {
        var rows: [EditField] = [
            .init(key: "arrival_iso", kind: .datetime, label: "시각", options: [],
                  allowsCustom: false, chosen: datetime),
            .init(key: "mode", kind: .mode, label: "이동 수단",
                  options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
                  allowsCustom: false, chosen: mode, busy: estimating),
            .init(key: "buffer_minutes", kind: .buffer, label: "도착 여유",
                  options: [.init(label: "0분", value: "0"), .init(label: "10분", value: "10"),
                            .init(label: "20분", value: "20"), .init(label: "30분", value: "30")],
                  allowsCustom: true, chosen: buffer),
            // 토글 줄은 생성 시 chosen을 seed한다 — 안 하면 isReady가 영원히 풀리지 않는다(REQ-001)
            .init(key: "notify_enabled", kind: .toggle, label: "출발 알림 받기",
                  options: [.init(label: "받기", value: "true"),
                            .init(label: "안 받기", value: "false")],
                  allowsCustom: false, chosen: notifyOn),
        ]
        // 알림을 끈 채 저장된 일정을 편집할 때는 리드 줄이 없다(켜면 lastNotifyLead로 돌아온다)
        if notifyOn == "true" { rows.append(notifyLeadRow(chosen: lead)) }
        // 캘린더 줄은 카드 생성 시점의 설정으로 정한다 — 시트가 열려 있는 동안 설정이 바뀌는 경로가
        // 없다(설정을 바꾸는 호출부는 설정 화면 하나).
        if store.config.hasGoogleCalendar && store.config.autoAddToCalendar {
            rows.append(.init(key: "calendar_sync", kind: .toggle, label: "구글 캘린더에도 등록",
                              options: [.init(label: "등록", value: "true"),
                                        .init(label: "안 함", value: "false")],
                              allowsCustom: false, chosen: calendar))
        }
        return rows
    }

    private func notifyLeadRow(chosen: String) -> EditField {
        .init(key: "notify_lead_minutes", kind: .notify, label: "알림",
              options: [.init(label: "출발 시각", value: "0"), .init(label: "10분 전", value: "10"),
                        .init(label: "30분 전", value: "30"), .init(label: "1시간 전", value: "60")],
              allowsCustom: true, chosen: chosen)
    }

    // MARK: - 칩 · 후보 · 직접입력

    /// 칩을 탭했을 때. 값은 줄에 적고, 키에 따라 딸린 일(조건부 줄·재계산·현재 위치 확정)이 따른다.
    private func choose(field: UUID, value: String) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return }
        let key = c.fields[i].key
        c.fields[i].chosen = value
        switch key {
        case "notify_enabled":
            if value == "false" {
                // 끌 때 마지막 값을 화면이 기억한 뒤 줄을 뺀다 — 값까지 지우면 다시 켤 때 처음부터
                if let li = c.fields.firstIndex(where: { $0.key == "notify_lead_minutes" }) {
                    lastNotifyLead = c.fields[li].chosen ?? lastNotifyLead
                    c.fields.remove(at: li)
                }
            } else if !c.fields.contains(where: { $0.key == "notify_lead_minutes" }) {
                let at = c.fields.firstIndex(where: { $0.key == "notify_enabled" }).map { $0 + 1 }
                    ?? c.fields.count
                c.fields.insert(notifyLeadRow(chosen: lastNotifyLead), at: at)
            }
            card = c
        case "origin_query":
            if value == Self.hereMarker, location.currentLocation == nil {
                // 위치를 아직 모르는 동안엔 고른 값으로 남기지 않는다 — chosen이 있으면 isReady가
                // 풀려 저장 버튼이 열리는데 좌표는 없어 save()가 조용히 아무 일도 안 하게 된다.
                // 원본은 제출 판정 식으로 이 창을 잠갔고, 여기서는 미고름으로 같은 잠금을 낸다.
                // 기다림은 줄의 busy(위치 확인 중)가 보여준다.
                c.fields[i].chosen = nil
                card = c
                useCurrentLocationAsOrigin()
            } else {
                card = c
                if value == Self.hereMarker {
                    useCurrentLocationAsOrigin()
                } else {
                    ensureGatedRows()
                    Task { await recomputeEstimates() }
                }
            }
        case "destination_query":
            card = c
            ensureGatedRows()
            Task { await recomputeEstimates() }
        default:
            card = c
            // 여유는 반대쪽 예상 시각에, 수단은 그 계산에 직접 닿는다 — 줄 캡션을 다시 맞춘다
            syncFieldExtras()
        }
    }

    /// 검색 후보를 탭했을 때 — 이름은 chosen에, 좌표는 이 순간 확정한다(REQ-020).
    private func choosePlace(field: UUID, place: Place) {
        confirmedPlaces[place.name] = place
        choose(field: field, value: place.name)
    }

    /// 직접입력. 범위 밖은 받지 않는다 — 거절 표시는 카드 뷰가 띄운다.
    @discardableResult
    private func submitCustom(field: UUID, text: String) -> Bool {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }),
              let value = c.fields[i].accepts(text) else { return false }
        c.fields[i].chosen = value
        card = c
        syncFieldExtras()
        return true
    }

    /// 커밋된 시각의 기준만 바꾼다(같은 시각, 접두만) — 기준 칩을 다시 탭했을 때.
    private func rechooseTimeBasis(field: UUID, basis: ScheduleAnchor) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }),
              let chosen = c.fields[i].chosen,
              let parsed = BesirTime.parseDatetime(chosen) else { return }
        c.fields[i].chosen = (basis == .arrival ? "arr:" : "dep:")
            + BesirTime.isoFormatter.string(from: parsed.date)
        card = c
        syncFieldExtras()
    }

    /// 시각 에디터의 확인. ISO 직렬화는 BesirTime이 단독으로 안다 — 뷰가 형식을 만들지 않는다.
    @discardableResult
    private func chooseTime(field: UUID, basis: ScheduleAnchor, date: Date) -> Bool {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return false }
        c.fields[i].chosen = (basis == .arrival ? "arr:" : "dep:")
            + BesirTime.isoFormatter.string(from: date)
        card = c
        syncFieldExtras()
        return true
    }

    // MARK: - 장소 검색

    /// 카드 검색 에디터의 입력. 묶음 정책(350ms 지연·취소·같은 질의 스킵)은 공용 디바운서가
    /// 단독으로 소유한다 — 이 화면이 지연 시간을 들면 카카오 할당량 정책이 두 벌이 된다.
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
            // 출발지 검색은 현재 위치를, 목적지 검색은 출발지 좌표를 기준 삼는다(원본의 구분).
            // await 전에 값을 잡아둔다 — 기준이 되는 출발지는 도는 사이 바뀔 수 있다.
            let isOrigin = card?.fields.first(where: { $0.id == field })?.key == "origin_query"
            let near: CLLocationCoordinate2D? = isOrigin
                ? location.currentLocation
                : (originCoord ?? location.currentLocation)
            setLookup(field, .searching)
            var armed = placeDebounce
            armed.arm(field) {
                let found = await self.store.placeSearch.search(q, near: near)
                guard !Task.isCancelled else { return }
                self.finishPlaceSearch(field: field, query: q, found: found)
            }
            placeDebounce = armed
        }
    }

    /// 완료 기록(noteDone)이 상태 반영보다 먼저다 — 이 순서를 바꾸면 첫 검색이 도는 중에 같은
    /// 질의를 다시 쳤을 때 유일한 결과가 버려지고 줄이 "찾는 중"에 갇힌다(드라이버 P-5의 시점).
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

    // MARK: - 현재 위치 출발지

    /// "현재 위치" 칩. 좌표가 이미 있으면 그 자리에서 확정하고, 아니면 위치를 얻을 때까지 기다린다.
    private func useCurrentLocationAsOrigin() {
        if let c = location.currentLocation {
            confirmCurrentLocationAsOrigin(c)
        } else {
            location.useCurrentLocation()
            Task { await prefillOrigin() }
        }
    }

    /// 출발지가 비어 있으면 현재 위치로 채운다(최대 5초 대기). 새 일정의 자동 프리필과 옛 일정의
    /// 출발지 nil을 채우는 길이 같다 — 옛 화면 prefillOrigin과 같은 흐름이다.
    private func prefillOrigin() async {
        guard confirmedPlace("origin_query") == nil else { return }
        if location.currentLocation == nil { location.useCurrentLocation() }
        for _ in 0..<25 {
            if let c = location.currentLocation {
                confirmCurrentLocationAsOrigin(c)
                return
            }
            // 기다리는 사이 사용자가 직접 출발지를 골랐으면 덮어쓰지 않는다 — 원본에는 없는
            // 재확인이지만, await 너머의 상태를 믿지 않는 규칙과 같은 부류이다.
            if let chosen = field("origin_query")?.chosen, chosen != Self.hereMarker { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func confirmCurrentLocationAsOrigin(_ c: CLLocationCoordinate2D) {
        // 다른 출발지가 이미 골라져 있으면(프리필 대기 중 사용자가 고른 경우) 그 값을 지키고,
        // "현재 위치" 칩 자체가 선택된 상태일 때만 확정한다
        guard field("origin_query")?.chosen == nil || field("origin_query")?.chosen == Self.hereMarker
        else { return }
        confirmedPlaces[Self.hereMarker] = Place(name: location.currentPlaceName ?? "현재 위치",
                                                 address: "", latitude: c.latitude, longitude: c.longitude)
        if var c2 = card, let i = c2.fields.firstIndex(where: { $0.key == "origin_query" }) {
            c2.fields[i].chosen = Self.hereMarker
            card = c2
        }
        ensureGatedRows()
        Task { await recomputeEstimates() }
    }

    // MARK: - 이동시간

    private func recomputeEstimates() async {
        guard let origin = confirmedPlace("origin_query"),
              let dest = confirmedPlace("destination_query") else { return }
        estimating = true
        let all = await store.directions.estimateAll(
            from: CLLocationCoordinate2D(latitude: origin.latitude, longitude: origin.longitude),
            to: CLLocationCoordinate2D(latitude: dest.latitude, longitude: dest.longitude))
        estimates = all
        estimating = false
        syncFieldExtras()
    }

    /// 줄에 붙는 딸린 글을 카드에 다시 맞춘다 — 모드 칩의 소요시간, 출처 캡션, 시각 줄 안내·예상
    /// 시각. 이 문자열들을 조립하는 곳은 이 함수 하나다(REQ-030(c)).
    private func syncFieldExtras() {
        guard var c = card else { return }
        let currentMode = c.fields.first(where: { $0.key == "mode" })?.chosen
            .flatMap(TransportMode.init(rawValue:)) ?? .transit
        if let mi = c.fields.firstIndex(where: { $0.key == "mode" }) {
            for oi in c.fields[mi].options.indices {
                let m = TransportMode(rawValue: c.fields[mi].options[oi].value)
                c.fields[mi].options[oi].detail = m.flatMap { estimates[$0] }?.durationText
            }
            // 출처는 이용 가능한 추정의 것만, 줄 캡션에 한 번 — 칩마다 붙으면 큰 글씨에서 칩이
            // 세 줄로 감긴다.
            var seen = Set<String>()
            let sources = TransportMode.allCases
                .compactMap { estimates[$0] }.filter(\.isAvailable).map(\.source)
                .filter { seen.insert($0).inserted }
            c.fields[mi].note = sources.isEmpty ? nil : "소요시간: " + sources.joined(separator: " · ")
        }
        if let ti = c.fields.firstIndex(where: { $0.key == "arrival_iso" }) {
            let parsed = c.fields[ti].chosen.flatMap(BesirTime.parseDatetime)
            let departureAnchored = parsed?.prefix == "dep:"
            // 안내 문안 두 개는 옛 화면의 캡션 그대로 — 기준을 아직 안 골랐을 때는 도착 편 문안
            var note = departureAnchored
                ? "출발 시각을 기준으로 도착 시각을 순산합니다(귀가처럼 출발이 우선일 때). 버퍼는 적용되지 않습니다."
                : "도착 시각을 기준으로 출발 시각을 역산합니다."
            // 이동시간을 알면 반대쪽 예상 시각을 붙인다 — 옛 화면의 비기준 줄 예상값이 사는 자리
            if let secs = estimates[currentMode]?.duration, let parsed {
                let buffer = Double(c.fields.first(where: { $0.key == "buffer_minutes" })?.chosen
                    .flatMap { Int($0) } ?? 0) * 60
                if departureAnchored {
                    note += " 예상 도착 " + BesirTime.compact.string(from: parsed.date.addingTimeInterval(secs))
                } else {
                    note += " 예상 출발 "
                        + BesirTime.compact.string(from: parsed.date.addingTimeInterval(-secs - buffer))
                }
            }
            c.fields[ti].note = note
        }
        card = c
    }

    private func setBusy(key: String, _ on: Bool) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.key == key }),
              c.fields[i].busy != on else { return }
        c.fields[i].busy = on
        card = c
    }

    // MARK: - 읽기 보조

    private func field(_ key: String) -> EditField? {
        card?.fields.first { $0.key == key }
    }

    /// 줄의 chosen 이름으로 확정된 장소를 되찾는다.
    private func confirmedPlace(_ key: String) -> Place? {
        field(key)?.chosen.flatMap { confirmedPlaces[$0] }
    }

    private var originCoord: CLLocationCoordinate2D? {
        confirmedPlace("origin_query").map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    /// 지금 입력값 그대로 저장하면 겹치게 되는 기존 블록. 이동시간이나 시각을 아직 모르면(장소
    /// 미선택·계산 실패·시각 미확정) 차지할 범위를 알 수 없어 빈 배열.
    private var currentConflicts: [Store.Conflict] {
        guard let modeChosen = field("mode")?.chosen,
              let mode = TransportMode(rawValue: modeChosen),
              let secs = estimates[mode]?.duration,
              let parsed = field("arrival_iso")?.chosen.flatMap(BesirTime.parseDatetime)
        else { return [] }
        let buffer = Double(field("buffer_minutes")?.chosen.flatMap { Int($0) } ?? 0) * 60
        let dep: Date, arr: Date
        if parsed.prefix == "arr:" {
            arr = parsed.date
            dep = parsed.date.addingTimeInterval(-secs - buffer)
        } else {
            dep = parsed.date
            arr = parsed.date.addingTimeInterval(secs)
        }
        return store.conflicts(departure: dep, arrival: arr,
                               recurrenceId: editing?.recurrenceId,
                               excludingEventId: editing?.id)
    }

    // MARK: - 저장

    private func save() async {
        // 카드가 다 차 있어도 좌표·시각은 여기서 되찾는다 — isReady는 줄의 chosen만 본다
        guard let origin = confirmedPlace("origin_query"),
              let dest = confirmedPlace("destination_query"),
              let parsed = field("arrival_iso")?.chosen.flatMap(BesirTime.parseDatetime)
        else { return }
        let title = field("title")?.chosen ?? ""
        // parsed가 "기준 시각"이다 — anchor == .arrival이면 도착 시각, .departure면 출발 시각이고
        // store의 arrivalDate 파라미터는 기준 시각을 받아 안에서 방향에 맞게 처리한다.
        let anchor: ScheduleAnchor = parsed.prefix == "arr:" ? .arrival : .departure
        let mode = field("mode")?.chosen.flatMap(TransportMode.init(rawValue:)) ?? .transit
        let bufferMinutes = field("buffer_minutes")?.chosen.flatMap { Int($0) } ?? 0
        // 알림 줄이 꺼져서 없으면 화면이 기억한 마지막 값을 쓴다(REQ-022(b))
        let notifyLeadMinutes = field("notify_lead_minutes")?.chosen.flatMap { Int($0) }
            ?? Int(lastNotifyLead) ?? 0
        let notifyEnabled = field("notify_enabled")?.chosen != "false"
        let syncToCalendar: Bool
        if let chosen = field("calendar_sync")?.chosen {
            syncToCalendar = chosen == "true"
        } else {
            syncToCalendar = calendarDefault
        }
        saving = true
        if let e = editing {
            await store.updateEvent(id: e.id, title: title, origin: origin, destination: dest,
                                    arrivalDate: parsed.date, mode: mode,
                                    bufferMinutes: bufferMinutes, notifyLeadMinutes: notifyLeadMinutes,
                                    anchor: anchor, notifyEnabled: notifyEnabled,
                                    syncToCalendar: syncToCalendar)
        } else {
            await store.addEvent(title: title, origin: origin, destination: dest,
                                 arrivalDate: parsed.date, mode: mode,
                                 bufferMinutes: bufferMinutes, notifyLeadMinutes: notifyLeadMinutes,
                                 anchor: anchor, notifyEnabled: notifyEnabled,
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
            // 건별 줄을 따로 읽으면 하나의 겹침으로 안 들린다 — 배너를 한 덩어리로 낭독한다
            .accessibilityElement(children: .combine)
        }
    }

    private func label(for c: Store.Conflict) -> String {
        guard let formatter else { return c.title }
        return "\(c.title) · \(formatter.string(from: c.start)) ~ \(formatter.string(from: c.end))"
    }
}
