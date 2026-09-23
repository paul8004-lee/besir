import SwiftUI

/// 이동이 아닌 체류형 활동(수업·근무·약속 등)을 수동으로 한 번만 추가하는 화면.
/// 반복 활동은 AI 채팅으로 만든다 — 여긴 "+" 메뉴에서 만드는 단발성 활동 전용.
///
/// 활동과 함께 "가는 이동 / 오는 이동"도 같이 만들 수 있다. 따로따로 만들면 둘 사이에 아무
/// 연결이 없어서 나중에 활동 블록을 옮겨도 이동 블록이 제자리에 남는데, 여기서 같이 만들면
/// `linkedActivityId`로 묶여서 활동을 옮길 때 이동도 따라 움직이고 지울 때도 같이 지워진다.
struct AddActivityView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    // 폼의 값은 전부 카드(card.fields)에 산다 — 제출 판정도 card.isReady 하나다(REQ-010). 화면이
    // 들고 있는 것은 카드가 가질 수 없는 것뿐: 좌표 사전, 묶음, 진행 깃발, 그리고 줄이 배열에서
    // 빠져 있는 동안 그 값을 기억하는 상태들.
    @State private var card: EditCard?
    /// 후보를 탭한 순간 좌표까지 확정된 장소. 열쇠는 이름이 아니라 **줄 신원**(EditField.id)이다.
    /// 이름으로 걸면 같은 상호의 다른 지점을 두 줄에서 고를 때(Place 주석이 말하는 그 겹침) 나중
    /// 쓰기가 앞 줄의 좌표까지 덮어, 활동 장소와 출발지가 한 좌표가 된다 — 이동 0분짜리 구간에
    /// 출발 알람이 활동 시작 시각으로 잡히고, 화면엔 이름만 보여 어긋난 걸 알 길이 없다. 줄 신원은
    /// 생성 때 한 번 찍히므로 두 줄이 겹칠 수가 없다. 지연 해석 함수는 여전히 만들지 않는다
    /// (계약 5: 만들면 resolvePlace의 세 번째 구현이 된다).
    @State private var confirmedPlaces: [UUID: Place] = [:]
    /// 즐겨찾기 칩의 라벨 → 장소. 칩 탭은 Place를 들고 오지 않고 라벨만 준다(placeOptions·
    /// favoriteOptions가 value에 라벨을 싣는다) — 그 라벨을 좌표로 푸는 씨앗이다. 줄 신원 사전과
    /// 합치지 않는 이유: 라벨은 줄이 아니라 즐겨찾기 목록의 것이고, 여러 줄이 같은 칩을 고른다.
    @State private var favoritePlaces: [String: Place] = [:]
    /// 카드 검색 에디터의 묶음(350ms 지연·취소·같은 질의 스킵). PlaceField 쪽에는 붙이지 않는다
    /// (REQ-042(b)) — 저쪽은 onSubmit·버튼 탭 두 경로뿐이라 글자마다 부르지 않아, 묶음이 막을
    /// 할당량 소모가 애초에 없다.
    @State private var placeDebounce = PlaceSearchDebouncer()
    @State private var saving = false

    // ── 줄이 배열에서 빠져 있는 동안의 기억값(REQ-011). 되심지 않으면 토글을 껐다 켠 사용자가
    // 방금 고른 출발지·여유를 잃는다 — AddEventView의 lastNotifyLead와 같은 형태다.
    /// 가는 편이 꺼져 있는(또는 장소가 없어 줄 자체가 없는) 동안의 출발지 이름.
    @State private var rememberedOutboundOrigin: String? = nil
    /// 그 출발지의 좌표. 이름만 기억하면 다리를 껐다 켠 사용자가 좌표를 잃는다 — 좌표가 줄 신원에
    /// 걸린 뒤로, 되심은 줄은 신원이 달라 이름으로는 되찾을 길이 없다.
    @State private var rememberedOutboundOriginPlace: Place? = nil
    @State private var rememberedOutboundMode = TransportMode.transit.rawValue
    /// 가는 편이 꺼져 있는 동안의 도착 여유(분).
    @State private var rememberedBuffer = "10"
    /// 오는 편이 꺼져 있는 동안의 도착지 이름.
    @State private var rememberedReturnTo: String? = nil
    /// 그 도착지의 좌표 — 출발지와 같은 이유로 이름과 함께 기억한다.
    @State private var rememberedReturnToPlace: Place? = nil
    @State private var rememberedReturnMode = TransportMode.transit.rawValue
    /// 알림 줄이 꺼져 있는 동안의 마지막 켬/끔 — 다리를 껐다 켜도 알림을 끊은 사실이 되살아나야
    /// 옛 폼과 같다(옛 폼의 알림 스위치는 다리를 꺼도 값을 유지했다).
    @State private var lastNotifyOn = true
    /// 알림 줄이 꺼져 있는 동안의 마지막 리드 값.
    @State private var lastNotifyLead = "30"
    /// 캘린더 줄이 설정 조건으로 아예 없을 때 저장에 쓸 값. 줄이 화면에 있으면 카드가 정답이다.
    @State private var calendarDefault = true

    /// "장소 없음" 칩의 값. 장소가 선택임을 카드 문법으로 표현하는 열쇠다 — isReady는 모든 줄의
    /// chosen을 전수로 보므로 이 칩이 없으면 장소 없는 활동을 만들 수 없다(REQ-030 마지막 절).
    /// Store에는 절대 흘러가지 않고 save()에서 nil로 풀린다.
    private static let noPlaceMarker = "__no_place__"

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 카드는 이 자리에 무조건 둔다 — Group·AnyView·가변 .id로 감싸면 줄 에디터의
                    // 지역 상태가 매번 새 UUID로 앉아 장소 이름을 한 글자도 못 친다(REQ-013(b)).
                    // nil→값 전이는 .task가 딱 한 번 일으킨다.
                    if let card {
                        EditCardView(card: card, busy: saving, actions: actions,
                                     chrome: EditCardChrome(header: nil, confirmTitle: nil))
                    }
                }
                .padding(24)
            }
            Divider()
            footer
        }
        .background(Theme.bg)
        #if os(macOS)
        .frame(width: 560, height: 640)
        #endif
        // 카드는 정확히 한 번 만든다(REQ-013(a)) — 이후로는 줄을 제자리에서 고치거나 넣고 뺀다.
        .task { bootstrap() }
        // 시트가 내려가도 예약돼 있던 검색은 350ms 뒤 그대로 나간다 — 사라진 화면의 결과를 위해
        // 네트워크를 태우지 않는다는 정리 계약의 폼 쪽 이행이다(AddEventView와 같은 판단).
        .onDisappear {
            var d = placeDebounce
            d.cancelAll()
            placeDebounce = d
        }
    }

    private var header: some View {
        HStack {
            Text("새 활동").font(.title2).bold()
            Spacer()
            Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    /// 카드 뷰가 부르는 동작을 화면의 함수로 잇는 어댑터. rechooseTimeBasis·chooseTime는 이
    /// 카드에 기준 있는 시각 줄이 하나도 없어(REQ-001) 올 수 없는 경로다 — 서명 채움일 뿐이고,
    /// 기준 없는 줄의 확정은 chooseTimePlain으로 간다.
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
            confirm: { await save() }
        )
    }

    // MARK: - 카드 만들기

    /// 시트가 뜨는 동안 딱 한 번 카드를 만든다(REQ-013(a)).
    private func bootstrap() {
        guard card == nil else { return }
        // 즐겨찾기는 칩을 만드는 시점에 좌표까지 확정해 둔다(REQ-010) — 탭 순간에 되찾기만 한다.
        for fav in store.favorites { favoritePlaces[fav.label] = fav.place }
        var fields: [EditField] = [
            .init(key: "title", kind: .title, label: "활동 제목", options: [], allowsCustom: true,
                  startsOpen: true),
            // "장소 없음" 칩이 '장소는 선택'임을 푸는 열쇠다 — 줄을 아예 안 만들면 장소를 나중에 더할
            // 길이 화면에서 사라진다(REQ-030 마지막 절).
            .init(key: "location_query", kind: .place, label: "장소 (선택)", options: placeOptions,
                  allowsCustom: true, note: "장소를 정하면 이동도 함께 만들 수 있어요"),
            // 활동의 시작·종료는 도착/출발 기준을 갖지 않는 시각이다(REQ-001). 옛 폼의 +1시간/+2시간
            // 프리필은 보이지 않는 기본값이었으므로 카드 문법대로 비워 둔다.
            .init(key: "start_iso", kind: .datetime, label: "시작", options: [], allowsCustom: false,
                  anchored: false),
            .init(key: "end_iso", kind: .datetime, label: "종료", options: [], allowsCustom: false,
                  anchored: false),
        ]
        // 캘린더 줄은 카드 생성 시점의 설정으로 정한다 — 시트가 열려 있는 동안 설정이 바뀌는 경로가
        // 없다(설정을 바꾸는 호출부는 설정 화면 하나). 줄이 없으면 calendarDefault가 저장에 쓰인다.
        if store.config.hasGoogleCalendar && store.config.autoAddToCalendar {
            fields.append(.init(key: "calendar_sync", kind: .toggle, label: "구글 캘린더에도 등록",
                                 options: [.init(label: "등록", value: "true"),
                                           .init(label: "안 함", value: "false")],
                                 allowsCustom: false, chosen: "true"))
        }
        card = EditCard(fields: fields)
    }

    /// 장소 줄의 칩: 즐겨찾기 + "장소 없음".
    private var placeOptions: [EditField.Option] {
        store.favorites.map { .init(label: $0.label, value: $0.label) }
            + [.init(label: "장소 없음", value: Self.noPlaceMarker)]
    }

    private var favoriteOptions: [EditField.Option] {
        store.favorites.map { .init(label: $0.label, value: $0.label) }
    }

    // MARK: - 칩 선택과 줄 멤버십

    /// 칩을 탭했을 때. 값은 줄에 적고, 키에 따라 딸린 줄(다리·알림)이 배열로 들어가고 빠진다.
    /// `place`는 검색 후보를 탭해 지점까지 특정된 경우에만 실려 온다(choosePlace) — 칩 탭은 nil로
    /// 들어와 라벨을 즐겨찾기 씨앗에서 푼다.
    private func choose(field: UUID, value: String, place: Place? = nil) {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }) else { return }
        let key = c.fields[i].key
        c.fields[i].chosen = value
        // 좌표는 값을 적은 그 줄 자리에 건다. 실려 온 place가 즐겨찾기 씨앗을 이기는 순서인 이유:
        // 검색 후보는 지점까지 특정된 값이고 즐겨찾기 라벨은 우연히 같을 수 있는 이름일 뿐이라,
        // 반대로 두면 검색해서 고른 "스타벅스" 홍대점이 즐겨찾기 "스타벅스"의 좌표로 조용히
        // 바뀐다. 씨앗에도 없으면("장소 없음" 칩) nil이 들어가 옛 좌표가 지워진다 — 이름이
        // 열쇠이던 시절엔 열쇠가 바뀌며 저절로 풀리던 자리라, 이제 명시로 갚는다.
        if c.fields[i].kind == .place { confirmedPlaces[field] = place ?? favoritePlaces[value] }
        switch key {
        case "location_query":
            // note는 없는 줄(이동)을 설명하는 말 — 고르는 순간 낡는다. 남아 있으면 잡음이다.
            c.fields[i].note = nil
            if confirmedPlaces[field] != nil {
                // 실제 장소를 고른 순간 다리 토글 줄이 태어난다 — 옛 화면의 else 가지가 줄 멤버십으로
                // 옮겨온 자리다. "장소 없음"은 즐겨찾기 씨앗에도 검색 결과에도 없어 바로 위에서
                // 이 줄의 좌표가 nil로 지워지므로 이 가지를 타지 않는다.
                if !c.fields.contains(where: { $0.key == "outbound_enabled" }) {
                    let at = c.fields.firstIndex(where: { $0.key == "end_iso" }).map { $0 + 1 }
                        ?? c.fields.count
                    c.fields.insert(contentsOf: [
                        legToggleRow(key: "outbound_enabled", label: "가는 이동 (활동 시작에 맞춰 도착)"),
                        legToggleRow(key: "return_enabled", label: "오는 이동 (활동 끝나면 출발)"),
                    ], at: at)
                }
            } else {
                rememberTravelValues(c)
                forgetPlaces(["origin_query", "return_query"], c)
                c.fields.removeAll {
                    ["outbound_enabled", "origin_query", "outbound_mode", "buffer_minutes",
                     "return_enabled", "return_query", "return_mode",
                     "notify_enabled", "notify_lead_minutes"].contains($0.key)
                }
            }
            card = c
        case "outbound_enabled":
            if value == "true" {
                // 칩은 선택 상태를 스스로 가리지 않고 매 탭마다 불린다 — 이미 켠 다리를 다시
                // 탭해도 줄이 겹치면 field()가 첫 줄을 읽어 저장값이 씨앗값으로 굳는다.
                if !c.fields.contains(where: { $0.key == "origin_query" }) {
                    let at = c.fields.firstIndex(where: { $0.key == "outbound_enabled" }).map { $0 + 1 }
                        ?? c.fields.count
                    let rows = outboundRows(origin: rememberedOutboundOrigin,
                                            mode: rememberedOutboundMode,
                                            buffer: rememberedBuffer)
                    // 되심은 줄은 신원이 새로 찍힌다 — 기억해 둔 좌표를 그 새 신원에 다시 건다.
                    // 안 걸면 이름만 살아나고 저장 때 출발지가 nil로 풀려, 다리는 켜졌는데
                    // 출발지 없는 구간이 만들어진다.
                    reseed(rows, "origin_query", rememberedOutboundOriginPlace)
                    c.fields.insert(contentsOf: rows, at: at)
                }
                ensureNotifyRows(&c)
            } else {
                rememberOutboundOrigin(c)
                if let m = chosenIn("outbound_mode", c) { rememberedOutboundMode = m }
                if let b = chosenIn("buffer_minutes", c) { rememberedBuffer = b }
                forgetPlaces(["origin_query"], c)
                c.fields.removeAll { ["origin_query", "outbound_mode", "buffer_minutes"].contains($0.key) }
                // 다리가 전부 꺼지면 알림 줄도 근거를 잃는다 — 옛 :141 조건의 멤버십 판이다.
                if chosenIn("return_enabled", c) != "true" { removeNotifyRows(&c) }
            }
            card = c
        case "return_enabled":
            if value == "true" {
                // 위와 같은 이유 — 켜진 오는 편을 다시 탭해도 줄이 겹쳐 들어가지 않게 멤버십이 가드한다.
                if !c.fields.contains(where: { $0.key == "return_query" }) {
                    let at = c.fields.firstIndex(where: { $0.key == "return_enabled" }).map { $0 + 1 }
                        ?? c.fields.count
                    let rows = returnRows(to: rememberedReturnTo, mode: rememberedReturnMode)
                    // 가는 편과 같은 이유 — 되심은 줄의 새 신원에 기억해 둔 좌표를 다시 건다.
                    reseed(rows, "return_query", rememberedReturnToPlace)
                    c.fields.insert(contentsOf: rows, at: at)
                }
                ensureNotifyRows(&c)
            } else {
                rememberReturnTo(c)
                if let m = chosenIn("return_mode", c) { rememberedReturnMode = m }
                forgetPlaces(["return_query"], c)
                c.fields.removeAll { ["return_query", "return_mode"].contains($0.key) }
                if chosenIn("outbound_enabled", c) != "true" { removeNotifyRows(&c) }
            }
            card = c
        case "notify_enabled":
            lastNotifyOn = value == "true"
            if value == "false" {
                // 끌 때 마지막 값을 화면이 기억한 뒤 줄을 뺀다 — 값까지 지우면 다시 켤 때 처음부터
                if let l = chosenIn("notify_lead_minutes", c) { lastNotifyLead = l }
                c.fields.removeAll { $0.key == "notify_lead_minutes" }
            } else if !c.fields.contains(where: { $0.key == "notify_lead_minutes" }) {
                let at = c.fields.firstIndex(where: { $0.key == "notify_enabled" }).map { $0 + 1 }
                    ?? c.fields.count
                c.fields.insert(notifyLeadRow(chosen: lastNotifyLead), at: at)
            }
            card = c
        default:
            card = c
        }
    }

    /// 장소가 사라질 때(장소 없음 칩) 다리 줄 전부의 값을 기억해 둔다 — 다시 실제 장소를 고르면
    /// 토글은 문서화된 기본값(끔)으로 돌아오지만, 토글을 켜면 고르던 값들이 되살아난다.
    /// 장소 줄은 다리를 끈 뒤엔 이미 없다 — 칩이 nil을 돌려도 무조건 넣으면 끌 때 기억한 값까지 지운다.
    private func rememberTravelValues(_ c: EditCard) {
        rememberOutboundOrigin(c)
        if let m = chosenIn("outbound_mode", c) { rememberedOutboundMode = m }
        if let b = chosenIn("buffer_minutes", c) { rememberedBuffer = b }
        rememberReturnTo(c)
        if let m = chosenIn("return_mode", c) { rememberedReturnMode = m }
        if let l = chosenIn("notify_lead_minutes", c) { lastNotifyLead = l }
        if let n = chosenIn("notify_enabled", c) { lastNotifyOn = n == "true" }
    }

    /// 출발지 줄의 이름과 좌표를 함께 기억한다. 둘을 갈라 두지 않는 이유: 좌표가 줄 신원에 걸린
    /// 뒤로, 이름만 기억하면 되심은 줄에서 그 좌표를 되찾을 길이 없다.
    private func rememberOutboundOrigin(_ c: EditCard) {
        guard let f = c.fields.first(where: { $0.key == "origin_query" }), let o = f.chosen else { return }
        rememberedOutboundOrigin = o
        rememberedOutboundOriginPlace = confirmedPlaces[f.id]
    }

    /// 도착지 줄도 같은 이유로 이름과 좌표를 함께 기억한다.
    private func rememberReturnTo(_ c: EditCard) {
        guard let f = c.fields.first(where: { $0.key == "return_query" }), let r = f.chosen else { return }
        rememberedReturnTo = r
        rememberedReturnToPlace = confirmedPlaces[f.id]
    }

    /// 아직 배열에 넣기 전인 줄에 기억해 둔 좌표를 건다 — 되심은 줄은 신원이 다르기 때문이다.
    private func reseed(_ rows: [EditField], _ key: String, _ place: Place?) {
        guard let place, let row = rows.first(where: { $0.key == key }) else { return }
        confirmedPlaces[row.id] = place
    }

    /// 줄이 배열에서 빠질 때 그 줄에 걸린 좌표도 놓는다 — 신원이 사라진 좌표는 아무도 되찾지
    /// 못하는데, 놓지 않으면 시트가 사는 동안 사전만 자란다.
    private func forgetPlaces(_ keys: [String], _ c: EditCard) {
        for f in c.fields where keys.contains(f.key) { confirmedPlaces[f.id] = nil }
    }

    /// 다리가 하나라도 켜지면 알림 줄이 필요해진다 — 캘린더 줄이 있다면 그 앞에, 없으면 맨 끝에.
    private func ensureNotifyRows(_ c: inout EditCard) {
        let legOn = c.fields.first(where: { $0.key == "outbound_enabled" })?.chosen == "true"
            || c.fields.first(where: { $0.key == "return_enabled" })?.chosen == "true"
        guard legOn, !c.fields.contains(where: { $0.key == "notify_enabled" }) else { return }
        let at = c.fields.firstIndex(where: { $0.key == "calendar_sync" }) ?? c.fields.count
        c.fields.insert(notifyToggleRow(chosen: lastNotifyOn ? "true" : "false"), at: at)
        // 꺼져 있던 채로 돌아오는 것이 아니라면 리드 줄이 곧바로 따라온다 — 토글만 홀로 나오는
        // 순간이 없게 한다(켬이 문서화된 기본값이다).
        if lastNotifyOn { c.fields.insert(notifyLeadRow(chosen: lastNotifyLead), at: at + 1) }
    }

    /// 알림 줄을 지우기 전에 마지막 값을 기억한다 — 다리를 다시 켤 때 되심운다.
    private func removeNotifyRows(_ c: inout EditCard) {
        if let l = chosenIn("notify_lead_minutes", c) { lastNotifyLead = l }
        if let n = chosenIn("notify_enabled", c) { lastNotifyOn = n == "true" }
        c.fields.removeAll { $0.key == "notify_enabled" || $0.key == "notify_lead_minutes" }
    }

    // MARK: - 줄 만들기

    private func legToggleRow(key: String, label: String) -> EditField {
        .init(key: key, kind: .toggle, label: label,
              options: [.init(label: "만들기", value: "true"), .init(label: "안 만들기", value: "false")],
              allowsCustom: false, chosen: "false")
    }

    private func outboundRows(origin: String?, mode: String, buffer: String) -> [EditField] {
        [
            .init(key: "origin_query", kind: .place, label: "출발지", options: favoriteOptions,
                  allowsCustom: true, chosen: origin),
            .init(key: "outbound_mode", kind: .mode, label: "가는 편 이동수단",
                  options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
                  allowsCustom: false, chosen: mode),
            // 이름에 "가는 편"이 붙는 이유: 복귀 구간의 여유는 Store가 0으로 박아 둔다
            // (addActivityWithTravel). "도착 여유"라고만 쓰면 이 줄이 오는 편에도 적용된다고
            // 말하는 셈이 된다(REQ-014).
            .init(key: "buffer_minutes", kind: .buffer, label: "가는 편 도착 여유",
                  options: [.init(label: "0분", value: "0"), .init(label: "10분", value: "10"),
                            .init(label: "20분", value: "20"), .init(label: "30분", value: "30")],
                  allowsCustom: true, chosen: buffer),
        ]
    }

    private func returnRows(to: String?, mode: String) -> [EditField] {
        [
            .init(key: "return_query", kind: .place, label: "도착지", options: favoriteOptions,
                  allowsCustom: true, chosen: to),
            .init(key: "return_mode", kind: .mode, label: "오는 편 이동수단",
                  options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
                  allowsCustom: false, chosen: mode),
        ]
    }

    private func notifyToggleRow(chosen: String) -> EditField {
        .init(key: "notify_enabled", kind: .toggle, label: "이동 알림 받기",
              options: [.init(label: "받기", value: "true"), .init(label: "안 받기", value: "false")],
              allowsCustom: false, chosen: chosen)
    }

    /// 알림 옵션은 AddEventView.notifyLeadRow와 같은 넷이다 — 두 폼이 다른 보기를 내면 같은
    /// 값을 두 문법으로 배우게 된다(REQ-012).
    private func notifyLeadRow(chosen: String) -> EditField {
        .init(key: "notify_lead_minutes", kind: .notify, label: "알림",
              options: [.init(label: "출발 시각", value: "0"), .init(label: "10분 전", value: "10"),
                        .init(label: "30분 전", value: "30"), .init(label: "1시간 전", value: "60")],
              allowsCustom: true, chosen: chosen)
    }

    // MARK: - 확정 · 직접입력

    /// 기준 없는 시각 줄의 확인. 종료 줄은 시작보다 뒤여야 한다 — 옛 DatePicker의 in: startDate...
    /// 예방이 카드 문법에서는 확인 시점의 거절로 바뀐다(REQ-030(a)). 거절 문구에 유효 범위를
    /// 나열하지 않는 것은 프로젝트 규칙이다. false를 돌려주면 여기서 얹은 note가 그 줄에 남아
    /// 이유를 말한다 — 카드 뷰의 rejected 표시는 직접입력 줄 전용이라 시각 줄엔 오지 않는다.
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

    /// 검색 후보를 탭했을 때 — 이름은 chosen에, 좌표는 이 순간 확정한다(REQ-010). 좌표를 여기서
    /// 먼저 적고 choose를 부르는 대신 인자로 실어 보내는 이유: 쓰기 자리가 하나면 "검색이
    /// 즐겨찾기를 이긴다"가 호출 순서가 아니라 구조로 정해진다.
    private func choosePlace(field: UUID, place: Place) {
        choose(field: field, value: place.name, place: place)
    }

    /// 직접입력(제목·여유·알림). 범위 밖은 받지 않는다 — 거절 표시는 카드 뷰가 띄운다. 장소 줄은
    /// 검색 에디터라 여기 오지 않는다.
    @discardableResult
    private func submitCustom(field: UUID, text: String) -> Bool {
        guard var c = card, let i = c.fields.firstIndex(where: { $0.id == field }),
              let value = c.fields[i].accepts(text) else { return false }
        c.fields[i].chosen = value
        card = c
        return true
    }

    // MARK: - 장소 검색

    /// 카드 검색 에디터의 입력. 묶음 정책(350ms 지연·취소·같은 질의 스킵)은 공용 디바운서가
    /// 단독으로 소유한다 — 이 화면이 지연 시간을 들면 카카오 할당량 정책이 두 벌이 된다.
    /// 검색 기준점은 없다(옛 PlaceField와 같다) — 출발지 근처를 우선할 근거가 이 화면엔 없다.
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

    /// 검색 상태를 줄에 얹는다. await에서 돌아온 뒤 id로 다시 찾는다 — 줄이 없어졌으면(다리를
    /// 꺼서 출발지 줄이 빠졌으면) 조용히 버린다(위험 부류 H1과 같은 이유로 잡아둔 자리에 쓰지
    /// 않는다).
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

    /// 줄에 걸린 좌표를 되찾는다 — 열쇠는 chosen 이름이 아니라 줄 신원이다. "장소 없음" 칩은
    /// 고르는 순간 그 줄의 좌표가 지워지므로(choose) 여기서 nil이 나온다.
    /// `chosen == nil`을 먼저 거르는 이유는 지금 막히는 경로가 있어서가 아니라 **실패 방향을
    /// 닫아두기 위해서다.** 열쇠가 이름이던 시절엔 이름 없는 줄이 사전을 못 찾아 저절로 nil이
    /// 나왔다. 신원 열쇠에서는 "좌표만 걸리고 이름은 없는 줄"이 생기면 그 좌표가 조용히 실려
    /// 나간다 — 지금은 쓰기 세 자리가 이름과 좌표를 늘 함께 적어 도달 불가지만, 그 불변식을
    /// 강제하는 것은 코드가 아니라 규율뿐이라 한 절로 갚아 둔다(잘못된 장소보다 없는 장소가 낫다).
    private func confirmedPlace(_ key: String) -> Place? {
        field(key).flatMap { $0.chosen == nil ? nil : confirmedPlaces[$0.id] }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("취소") { dismiss() }
            Button {
                Task { await save() }
            } label: {
                if saving { ProgressView().controlSize(.small) } else { Text("추가") }
            }
            .keyboardShortcut(.defaultAction)
            // 저장 중에는 라벨이 스피너로 접혀 이름이 사라진다 — VoiceOver는 여전히 무슨 버튼인지
            // 알아야 한다(AddEventView와 같은 판단).
            .accessibilityLabel("추가")
            .disabled(!(card?.isReady ?? false) || saving)
        }
        .padding()
    }

    // MARK: - 저장

    private func save() async {
        // 카드가 다 차 있어도 좌표·시각 해석은 여기서 한다 — isReady는 줄의 chosen만 본다.
        guard let start = field("start_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date,
              let end = field("end_iso")?.chosen.flatMap(BesirTime.parseDatetime)?.date else { return }
        let outboundOn = field("outbound_enabled")?.chosen == "true"
        let returnOn = field("return_enabled")?.chosen == "true"
        saving = true
        await store.addActivityWithTravel(
            title: field("title")?.chosen ?? "",
            // "장소 없음" 칩은 좌표 사전에 없는 값이라 여기서 nil로 풀린다 — Store에는 흘러가지 않는다
            location: confirmedPlace("location_query"),
            startDate: start,
            endDate: end,
            travelFrom: outboundOn ? confirmedPlace("origin_query") : nil,
            returnTo: returnOn ? confirmedPlace("return_query") : nil,
            outboundMode: field("outbound_mode")?.chosen.flatMap(TransportMode.init(rawValue:)) ?? .transit,
            returnMode: field("return_mode")?.chosen.flatMap(TransportMode.init(rawValue:)) ?? .transit,
            // 여유 줄은 가는 편이 켜져 있어야 배열에 있으므로 폴백 0은 다리 없는 저장에만 닿는다
            bufferMinutes: field("buffer_minutes")?.chosen.flatMap { Int($0) } ?? 0,
            // 알림 줄이 꺼져서 없으면 화면이 기억한 마지막 값을 쓴다(REQ-012)
            notifyLeadMinutes: field("notify_lead_minutes")?.chosen.flatMap { Int($0) }
                ?? Int(lastNotifyLead) ?? 0,
            notifyEnabled: field("notify_enabled")?.chosen != "false",
            syncToCalendar: field("calendar_sync")?.chosen.map { $0 == "true" } ?? calendarDefault)
        saving = false
        dismiss()
    }
}

/// 장소 하나를 고르는 섹션(즐겨찾기 버튼 + 검색).
/// 활동 장소·출발지·도착지, 그리고 be full sir의 식사 일정 시트에서 같은 모양으로 쓴다
/// (화면마다 따로 만들면 검색 동작이 조금씩 갈라진다).
struct PlaceField: View {
    let title: String
    let systemImage: String
    @Binding var place: Place?

    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var results: [Place] = []
    @State private var searching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            if let p = place {
                HStack {
                    Image(systemName: systemImage).foregroundStyle(Theme.activity)
                    VStack(alignment: .leading) {
                        Text(p.name).bold()
                        if !p.address.isEmpty {
                            Text(p.address).font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    Spacer()
                    Button("변경") { place = nil }.buttonStyle(.borderless)
                }
                .padding(10)
                .background(Theme.raised, in: RoundedRectangle(cornerRadius: 8))
            } else {
                if !store.favorites.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.favorites) { fav in
                                Button(fav.label) { place = fav.place }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                        }
                    }
                }
                HStack {
                    TextField("장소·주소 검색", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { runSearch() }
                    Button { runSearch() } label: {
                        if searching { ProgressView().controlSize(.small) }
                        else { Image(systemName: "magnifyingglass") }
                    }
                }
                // 검색 결과는 이름이 겹칠 수 있어 좌표까지 합쳐 구분한다(같은 이름 두 곳이 한 줄로 합쳐지지 않게).
                ForEach(results, id: \.self) { found in
                    Button {
                        place = found
                        results = []
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle")
                            VStack(alignment: .leading) {
                                Text(found.name)
                                Text(found.address).font(.caption).foregroundStyle(Theme.muted)
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

    private func runSearch() {
        guard query.count >= 2 else { return }
        searching = true
        Task {
            let found = await store.placeSearch.search(query, near: nil)
            await MainActor.run { results = found; searching = false }
        }
    }
}
