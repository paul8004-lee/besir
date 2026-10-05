import SwiftUI
import CoreLocation

/// 활동(체류형) 블록의 정보 보기·편집 화면. 이동 구간(ScheduledEvent)의 편집도 연결된 구간이면
/// 이 카드가 맡는다(SPEC-UIKIT-009 REQ-001 — 시간을 고치면 활동과 분리되던 창이 나오지 않게).
/// 구간 줄의 문법은 생성 카드(AddActivityView)와 같은 LegCardForm이다(REQ-007).
struct ActivityDetailView: View {
    let activityId: UUID
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    // 편집값 넷(제목·장소·시작·종료)과 구간 줄의 문법·좌표 사전·기억값은 전부 LegCardForm 한 몸에
    // 산다(SPEC-UIKIT-009 MB). 화면이 직접 드는 것은 문법이 가질 수 없는 것뿐: 시드 때의 스냅샷
    // (저장 diff의 기준), 검색 묶음, 주변 맛집, 저장 진행·결과, 삭제 대화상자.
    @State private var form: LegCardForm?
    /// 저장 diff의 기준 — 시드 때의 폼 그대로. diff가 (시드, 현재, 시드 때 구간)의 순수 함수라
    /// await 사이에도 늙지 않는다.
    @State private var seed: LegCardForm?
    /// 시드 때의 명시적 연결 구간(Store.legs(of:)). 저장이 끝난 뒤엔 다시 읽지 않는다 — 시드와
    /// diff가 같은 순간을 보아야 무변경 저장이 바이트 동일로 닫힌다(REQ-008).
    @State private var seedLegs: (outbound: ScheduledEvent?, `return`: ScheduledEvent?) = (nil, nil)
    /// 저장 도중 저장·닫기를 잠근다(생성 카드의 saving 패턴 그대로) — 활동만 저장되고 구간은
    /// 미적용인 중간 상태에서 시트가 내려가는 것을 막는다(design §3). 이 잠금이 MA code-safety
    /// 경고 1(addLeg 중복 역할 검사가 await 앞에만 있다)의 뷰 경로를 닫는다 — 같은 카드에서
    /// 두 번 저장이 겹칠 수 없으므로 이 화면에서는 같은 역할 addLeg가 경쟁하지 않는다.
    @State private var saving = false
    /// 저장 결과 안내(REQ-010·REQ-009). nil이면 저장이 조용히 닫혔다는 뜻이다.
    @State private var saveReport: String?
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
    /// 지금 떠 있는 주변 조회. 종류를 연달아 바꾸면 취소 없이는 카카오 조회가 한 벌씩 쌓이고,
    /// 취소된 조회는 try?로 삼켜진 빈 배열로 정상 돌아와 늦은 옛 빈 결과가 새 결과를 덮는다
    /// (day-close §6 후속 12).
    @State private var nearbyTask: Task<Void, Never>?

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
                    if let card = form?.card {
                        EditCardView(card: card, busy: saving, actions: actions,
                                     chrome: EditCardChrome(header: nil, confirmTitle: nil))
                    }
                    if let saveReport {
                        // 저장 결과는 시트 안에서 말한다(REQ-010) — 닫고 나면 들을 자리가 없다.
                        Label(saveReport, systemImage: "exclamationmark.triangle")
                            .font(.callout).foregroundStyle(Theme.warn)
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
                    Button("닫기") { dismiss() }.disabled(saving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(!(form?.card.isReady ?? false) || saving)
                }
            }
            .confirmationDialog("반복 일정을 어떻게 삭제할까요?", isPresented: $showingDeleteMenu, titleVisibility: .visible) {
                Button("전체 반복 일정 삭제", role: .destructive) { deleteWholeSeries() }
                Button("이 일정만 삭제", role: .destructive) { delete() }
                Button("취소", role: .cancel) {}
            }
            .confirmationDialog(deleteConfirmTitle, isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
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
            // 진행 중인 주변 조회도 끊는다 — 위 검색과 같은 정리 계약, 취소는 진행 중 요청까지 끊는다.
            nearbyTask?.cancel()
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

    /// 화면이 뜨는 동안 딱 한 번, 저장된 활동에서 카드를 만든다. 구간 줄의 시드는 전부
    /// LegCardForm.seeded가 안다(REQ-011 — 반복 회차엔 구간 줄이 아예 없다).
    private func bootstrap() {
        guard form == nil, let a = activity else { return }
        let legs = store.legs(of: a.id)
        var f = LegCardForm.seeded(activity: a, outbound: legs.outbound, returnLeg: legs.return,
                                   noPlaceValue: Self.noPlaceMarker,
                                   placeOptions: placeOptions, favoriteOptions: favoriteOptions)
        // 즐겨찾기는 칩을 만드는 시점에 좌표까지 확정해 둔다 — 탭 순간에 되찾기만 한다.
        for fav in store.favorites { f.favoritePlaces[fav.label] = fav.place }
        seed = f
        seedLegs = legs
        form = f
    }

    /// 장소 줄의 칩: 즐겨찾기 + "장소 없음".
    private var placeOptions: [EditField.Option] {
        store.favorites.map { .init(label: $0.label, value: $0.label) }
            + [.init(label: "장소 없음", value: Self.noPlaceMarker)]
    }

    private var favoriteOptions: [EditField.Option] {
        store.favorites.map { .init(label: $0.label, value: $0.label) }
    }

    // MARK: - 칩 선택 · 확정

    /// 칩을 탭했을 때. 값 적기·좌표 걸기·구간 줄의 멤버십 전이는 전부 LegCardForm이 안다 —
    /// 문법이 뷰에 남으면 생성 카드와 규칙이 두 벌이 된다(REQ-007). 화면이 더하는 일은 문법이
    /// 모르는 것 하나: 장소가 바뀌면 주변 맛집 결과를 낡은 채로 두지 않는다.
    private func choose(field: UUID, value: String, place: Place? = nil) {
        guard let f = form, let row = f.card.fields.first(where: { $0.id == field }) else { return }
        let key = row.key
        let previous = row.chosen
        form?.choose(field: field, value: value, place: place)
        if key == "location_query", previous != value {
            // 좌표가 달라질 장소를 골랐다는 뜻이다 — 비우지 않으면 저장 뒤 새 장소 이름 아래
            // 옛 장소의 식당이 남는다(§1.2의 결함이 형태만 바꿔 살아남는 경로, REQ-021).
            // 도는 중인 옛 장소 조회도 취소한다 — 놔두면 착지해서 막 비운 목록을 옛 결과로 다시
            // 채운다. 취소를 여기 더해도 거짓 "찾지 못함"이 안 생기는 건 가드가 이미 앞이라
            // 취소된 조회가 빈 결과를 쓸 길이 없기 때문이다(t12 sync N2·N3).
            nearbyTask?.cancel()
            nearby = []
            nearbyLoaded = false
        }
    }

    /// 검색 후보를 탭했을 때 — 이름은 chosen에, 좌표는 이 순간 확정한다(REQ-021).
    private func choosePlace(field: UUID, place: Place) {
        choose(field: field, value: place.name, place: place)
    }

    /// 직접입력(제목). 범위 밖은 받지 않는다 — 거절 표시는 카드 뷰가 띄운다. 장소 줄은 검색
    /// 에디터라 여기 오지 않는다.
    @discardableResult
    private func submitCustom(field: UUID, text: String) -> Bool {
        guard var f = form, let i = f.card.fields.firstIndex(where: { $0.id == field }),
              let value = f.card.fields[i].accepts(text) else { return false }
        f.card.fields[i].chosen = value
        form = f
        return true
    }

    /// 기준 없는 시각 줄의 확인. 종료 줄은 시작보다 뒤여야 한다 — 옛 DatePicker의 in: startDate...
    /// 예방이 카드 문법에서는 확인 시점의 거절로 바뀐다(REQ-030(a)). 거절 문구에 유효 범위를
    /// 나열하지 않는 것은 프로젝트 규칙이다. false를 돌려주면 여기서 얹은 note가 그 줄에 남아
    /// 이유를 말한다 — 카드 뷰의 rejected 표시는 직접입력 줄 전용이라 시각 줄엔 오지 않는다.
    @discardableResult
    private func chooseTimePlain(field: UUID, date: Date) -> Bool {
        guard var f = form, let i = f.card.fields.firstIndex(where: { $0.id == field }) else { return false }
        if f.card.fields[i].key == "end_iso",
           let startRaw = f.card.fields.first(where: { $0.key == "start_iso" })?.chosen,
           let start = BesirTime.parseDatetime(startRaw)?.date,
           date <= start {
            f.card.fields[i].note = "종료는 시작보다 뒤여야 해요"
            form = f
            return false
        }
        f.card.fields[i].chosen = BesirTime.isoFormatter.string(from: date)
        // 거절 사유는 유효 확정과 함께 지운다 — 남아 있으면 방금 고른 값도 거절된 것처럼 보인다
        f.card.fields[i].note = nil
        if f.card.fields[i].key == "start_iso",
           let ei = f.card.fields.firstIndex(where: { $0.key == "end_iso" }),
           let endRaw = f.card.fields[ei].chosen,
           let end = BesirTime.parseDatetime(endRaw)?.date,
           end <= date {
            // 시작을 종료 뒤로 옮기면 확정된 종료는 무효가 된다 — 옛 폼이 종료>시작 판정으로
            // 저장을 막던 것의 계승. 줄 문법에서는 chosen을 비워 isReady를 다시 잠근다.
            f.card.fields[ei].chosen = nil
            f.card.fields[ei].note = "종료는 시작보다 뒤여야 해요"
        }
        form = f
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
                let found = await store.placeSearch.search(q, near: nil)
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

    /// 검색 상태를 줄에 얹는다. await에서 돌아온 뒤 id로 다시 찾는다 — 줄이 없어졌으면(장소를
    /// 지워 구간 줄이 빠졌으면) 조용히 버린다(위험 부류 H1과 같은 이유로 잡아둔 자리에 쓰지 않는다).
    private func setLookup(_ field: UUID, _ lookup: EditField.Lookup) {
        guard var f = form, let i = f.card.fields.firstIndex(where: { $0.id == field }) else { return }
        f.card.fields[i].lookup = lookup
        form = f
    }

    // MARK: - 읽기 보조

    private func field(_ key: String) -> EditField? {
        form?.card.fields.first { $0.key == key }
    }

    /// 줄에 걸린 좌표를 되찾는다 — 열쇠는 chosen 이름이 아니라 줄 신원이다. "장소 없음" 칩은
    /// 고르는 순간 그 줄의 좌표가 지워지므로(choose) 여기서 nil이 나온다.
    /// `chosen == nil`을 먼저 거르는 이유는 지금 막히는 경로가 있어서가 아니라 **실패 방향을
    /// 닫아두기 위해서다.** 좌표만 걸리고 이름은 없는 줄이 생기면 그 좌표가 조용히 실려
    /// 나간다 — 쓰기 자리가 이름과 좌표를 늘 함께 적어 도달 불가하지만, 그 불변식을 강제하는
    /// 것은 코드가 아니라 규율뿐이라 잘못된 장소보다 없는 장소가 낫다.
    private func confirmedPlace(_ key: String) -> Place? {
        field(key).flatMap { $0.chosen == nil ? nil : form?.confirmedPlaces[$0.id] }
    }

    // MARK: - 저장 · 삭제

    /// 저장 순서는 design §3 그대로: ① 활동 저장(제목·시간·장소 — "장소 없음"이면 clearPlace) →
    /// ② 구간 diff의 제거를 먼저 → ③ 구간 따라오기(바뀐 구간만, Store가 바이트 동일을 지킨다) →
    /// ④ 남은 diff를 수정 → 추가 순서로 하나씩 직렬 → ⑤ 결과 집계(미계산은 연산 뒤 레코드에서) →
    /// ⑥ 닫기(안내가 있으면 시트를 열어 둔 뒤 재시드). 결과에 이동시간 미계산·거절이 있으면
    /// 시트 안에 안내하고 열어 둔다(REQ-010·009).
    private func save() {
        guard !saving, let a = activity,
              let start = field("start_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date,
              let end = field("end_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date,
              let seed, let current = form else { return }
        let newPlace = confirmedPlace("location_query")
        let ops = LegSavePlanner.ops(seed: seed, current: current,
                                     outboundLeg: seedLegs.outbound, returnLeg: seedLegs.return)
        saving = true
        // 뷰는 구조체라 weak 캡처가 없다 — Task가 값 복사를 잡지만 @State는 참조 지지대라
        // 화면이 사라져도 쓰기가 시트 재생성으로 새는 일 없이 그 시트의 상태에만 닿는다
        // (EventDetailView의 Task 패턴과 같은 판단).
        Task { @MainActor in
            // ① 활동 먼저 확정한다 — 구간 시간 유도의 입력이 활동 시각이므로(design §3).
            // modifyActivity여야 묶인 구간이 같이 움직인다. "장소 없음"은 좌표가 nil로 풀리는
            // 것과 clearPlace로 구분해 넘긴다(REQ-004).
            store.modifyActivity(id: a.id,
                                 newTitle: field("title")?.chosen ?? "",
                                 newStart: start,
                                 newEnd: end,
                                 newPlace: newPlace,
                                 clearPlace: newPlace == nil)
            // 장소를 지운 저장은 구간이 이미 ①에서 함께 지워졌다 — 따라오기·diff를 돌지 않는다.
            if newPlace != nil {
                // ② diff의 제거를 먼저 돈다 — realign이 곧 지울 구간을 다시 쓰며 추정·캘린더
                // 업로드 큐에 올리는 일(sync 1차 W3)을 막고, 제거가 빈자리를 내야 추가의 중복
                // 검사가 그 빈자리를 본다(design §3).
                var refusedReasons: Set<String> = []
                var failed = 0
                for op in ops {
                    // removeLeg는 비-Optional 결과를 주므로 조건 바인딩이 아니라 그대로
                    // 패턴 매칭한다 — .removed는 세지 않고 .failed만 계수한다(기존 집계와 동등).
                    guard case .remove(let legId) = op else { continue }
                    if case .failed = store.removeLeg(legId: legId) { failed += 1 }
                }
                // ③ 구간 따라오기(바뀐 구간만, Store가 바이트 동일을 지킨다). 결과 플래그는
                // 따로 모으지 않는다 — 미계산 안내는 연산 뒤 레코드 하나에서 읽는다(sync 2차
                // F1: 통로별 플래그를 OR로 쌓으면 나중 통로가 값을 고쳐도 처음 통로의 거짓이
                // 남아 안내가 최종 레코드와 어긋난다).
                _ = await store.realignLegs(of: a.id)
                // ④ 남은 diff 연산(수정 → 추가)을 하나씩 직렬 실행한다.
                for op in ops {
                    let outcome: Store.LegOutcome
                    switch op {
                    case .remove:
                        continue
                    case .update(let legId, _, let outer, let mode, let buffer, let lead, let enabled):
                        outcome = await store.updateLeg(legId: legId, outerPlace: outer, mode: mode,
                                                             bufferMinutes: buffer,
                                                             notifyLeadMinutes: lead,
                                                             notifyEnabled: enabled)
                    case .add(let role, let outer, let mode, let buffer, let lead, let enabled):
                        outcome = await store.addLeg(activityId: a.id, role: role, outerPlace: outer,
                                                          mode: mode, bufferMinutes: buffer,
                                                          notifyLeadMinutes: lead, notifyEnabled: enabled)
                    }
                    switch outcome {
                    case .refused(let reason):
                        // 결과가 어느 이유인지 말한다(REQ-009) — "저장됐다"로 세지 않는다.
                        refusedReasons.insert(Self.refusalText(reason))
                    case .created, .updated, .removed:
                        break
                    case .failed:
                        failed += 1
                    }
                }
                // ⑤ 결과 집계 — 안내가 없을 때만 ⑥ 닫는다. 문구의 의미가 기준이다(design §8).
                // 미계산은 저장이 끝난 레코드가 유일한 사실이다(계약 5) — 존재하는 구간의
                // travelSeconds가 nil이면 알리고, 없는 구간은 따지지 않는다.
                let finalLegs = store.legs(of: a.id)
                let unknownTravel = [finalLegs.outbound, finalLegs.return].compactMap { $0 }
                    .contains { $0.travelSeconds == nil }
                var messages: [String] = []
                if unknownTravel { messages.append("이동시간을 계산하지 못했어요") }
                if !refusedReasons.isEmpty { messages.append(refusedReasons.sorted().joined(separator: " · ")) }
                if failed > 0 { messages.append("저장하지 못한 이동이 있어요") }
                saving = false
                if messages.isEmpty {
                    dismiss()
                } else {
                    saveReport = messages.joined(separator: " · ")
                    // 안내를 띄우고 시트가 열린 채 남으면 diff 기준을 지금 상태로 다시 잡는다.
                    // bootstrap은 화면마다 한 번만 돈다 — 낡은 seed로 다시 저장하면 이미 끝난
                    // 제거가 .failed, 이미 만든 추가가 .refused(.duplicateRole)로 거짓 안내가
                    // 된다(sync 2차 F2). 다시 저장은 추정 실패의 복구 경로다.
                    // seed는 guard가 지역 상수로 가려 self.로 쓴다. diff 기준을 current(저장
                    // 시작 때의 폼)로 잡는 이유: 방금 Store에 적용된 연산은 그 폼의 diff이므로 —
                    // 저장 도중 줄을 고쳤다면(줄 편집은 잠기지 않는다) 다음 diff는 그 새 값과
                    // 비교되어야 한다. 구간 목록은 방금 읽은 finalLegs 그대로 — 그 사이 Store를
                    // 고치는 호출은 없다.
                    self.seed = current
                    self.seedLegs = finalLegs
                }
            } else {
                saving = false
                dismiss()
            }
        }
    }

    /// 거절 사유의 안내 문구 — 화면이 이유를 사실대로 말한다(REQ-009).
    private static func refusalText(_ reason: Store.LegRefusalReason) -> String {
        switch reason {
        case .duplicateRole: return "이미 같은 역할의 이동이 있어 만들지 못했어요"
        case .noPlace: return "장소가 없는 활동에는 이동을 만들 수 없어요"
        case .activityMissing: return "활동이 이미 지워져 이동을 만들지 못했어요"
        case .recurrenceEpisode: return "반복 일정 회차에는 이동을 따로 만들 수 없어요"
        }
    }

    /// 삭제 확인 제목 — 딸린 이동 수를 Store 조회 하나로 읽는다(REQ-014). 반복 회차 안내 문구는
    /// 그대로 둔다(AC-011 (4)).
    private var deleteConfirmTitle: String {
        let n = store.explicitLegCount(of: activityId)
        return n >= 1 ? "이 활동과 딸린 이동 \(n)건을 삭제할까요?" : "이 활동을 삭제할까요?"
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
                    startNearby()
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
                .onChange(of: nearbyCategory) { startNearby() }

                if nearby.isEmpty && !loadingNearby {
                    Text("주변 1km 안에서 찾지 못했어요.")
                        .font(.callout).foregroundStyle(Theme.muted)
                } else {
                    ForEach(nearby) { item in
                        nearbyRow(item)
                    }
                }
            } else {
                Text("'\(activity?.location?.name ?? "이 장소")' 주변의 \(nearbyCategory.title)을(를) 찾아드려요.")
                    .font(.caption).foregroundStyle(Theme.muted)
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
                        Text(item.category).font(.caption).foregroundStyle(Theme.muted)
                    }
                    if let d = item.distanceText {
                        Text("· \(d)").font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                if !item.place.address.isEmpty {
                    Text(item.place.address).font(.caption2).foregroundStyle(Theme.faint).lineLimit(1)
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

    /// 주변 조회는 언제나 여기를 거쳐 띄운다(취소-교체) — 두 발화 지점이 각자 Task를 만들면 이전
    /// 조회를 취소할 손잡이가 없다. nearbyCategory는 @State라 새 작업이 제 값을 읽는다.
    private func startNearby() {
        nearbyTask?.cancel()
        nearbyTask = Task { await loadNearby() }
    }

    private func loadNearby() async {
        // 취소 가드가 플래그를 마지막 조회에만 맡기는 이상(아래) 조기 반환에서도 내린다.
        guard let coord = placeCoord else {
            loadingNearby = false
            return
        }
        loadingNearby = true
        let found = await store.placeSearch.nearbyPlaces(category: nearbyCategory, near: coord)
        // 취소 가드를 스피너 해제·nearbyLoaded보다 앞에 둔다 — 종류를 연달아 바꾸면(B→C) 취소된
        // B가 곧바로 돌아와 C가 도는 중에 스피너를 내리고 새로고침이 다시 눌리게 한다. 취소된
        // 조회는 아무것도 쓰지 않고 플래그는 새 조회가 끝날 때 내린다. 그래도 플래그가 켜진 채
        // 남는 길은 placeCoord nil(섹션 자체가 숨는다)과 onDisappear(시트가 사라진다)뿐이라
        // 걸려 있어도 화면에 남지 않는다.
        guard !Task.isCancelled else { return }
        loadingNearby = false
        nearbyLoaded = true
        nearby = found
    }
}
