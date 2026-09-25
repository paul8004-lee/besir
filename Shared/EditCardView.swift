import SwiftUI

/// 빠진 인자를 **한 장에 모아** 묻는 카드. 호출마다 끼어들지 않는 이유는 카드를 만드는 쪽에
/// 적혀 있고, 여기서 지키는 건 그 반대편이다: 물어본 값도 묻지 않고 정해진 값도 **전부 화면에
/// 보인다**. 화면에서 빠진 값은 사용자가 고칠 수 없는 값이고, 그게 b303f41(여유 0분 35건)의 모양이었다.
struct EditCardView: View {
    let card: EditCard
    // 확인 버튼 잠금·진행 표시에 쓰는 호출자 쪽 상태 — 뷰가 값을 소유한 주체를 타입으로 알지
    // 못하므로 바쁨 여부만 값으로 받는다.
    let busy: Bool
    // 동작은 전부 이 묶음으로 온다 — 값의 주인을 뷰가 직접 부르면 네 편집 화면이 이 카드를
    // 빌려 쓸 수 없다.
    let actions: EditCardActions
    // 카드 크롬의 뷰 쪽 기본값 — AI 카드가 지금까지 하드코딩으로 쓰던 문구 그대로다. 기본값이
    // 있어야 유일한 기존 호출부(채팅)가 무변경으로 컴파일된다.
    var chrome: EditCardChrome = EditCardChrome(header: "몇 가지만 알려주세요", confirmTitle: "등록하기")

    // 직접입력 상태는 카드와 수명을 같이 한다. 채팅 뷰에 두면 카드가 요약으로 바뀐 뒤에도
    // 열린 입력창과 거절 표시가 남아 다음 카드로 흘러간다.
    @State private var customOpen: Set<UUID> = []
    @State private var draft: [UUID: String] = [:]
    @State private var rejected: Set<UUID> = []
    // 시각 줄의 임시 상태 — 기준 칩과 에디터의 바퀴 위치. 커밋 전까지 어떤 것도 값이 아니다.
    // 기준은 처음에 아무것도 골라두지 않는다(사용자 결정: 앱이 먼저 정해둔 값이 오늘 하루 종일
    // 없애던 것이므로, 여기서도 예외를 두지 않는다).
    @State private var draftBasis: [UUID: ScheduleAnchor] = [:]
    @State private var draftDate: [UUID: Date] = [:]

    // 칩 높이는 글자 크기를 따라 커진다 — 고정하면 큰 글씨 설정에서 칩이 잘린다.
    // iOS는 손가락이라 44pt가 최소고, macOS는 포인터라 그만큼 키우면 카드만 길어진다.
    #if os(iOS)
    @ScaledMetric(relativeTo: .callout) private var chipHeight: CGFloat = 44
    #else
    @ScaledMetric(relativeTo: .callout) private var chipHeight: CGFloat = 28
    #endif

    private var canConfirm: Bool { card.isReady && !busy }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 머리글은 카드가 스스로 그리는 크롬이라 소유 화면이 끌 수 있다 — 화면 제목과
            // 겹치는 화면에서 둘 다 보이면 제목이 둘로 읽힌다.
            if let header = chrome.header {
                Text(header)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.ink)
            }

            // 줄이 안 생긴 값 = 묻지 않고 정해진 값. 적어두지 않으면 그게 곧 조용한 기본값이다.
            if !card.stated.isEmpty {
                Text("말씀하신 대로: " + card.stated.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            ForEach(card.fields) { field in
                fieldRow(field, depBasis: departureAnchored)
            }

            confirmButton
        }
        .padding(14)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
        // startsOpen 줄의 에디터를 카드가 뜰 때 연다. 합집합으로 씨앗을 뿌리는 까닭은 이미
        // 열려 있는 입력칸을 닫을 근거가 없어서고, draft를 채우지 않는 까닭은 빈 칸이 곧
        // "새로 입력하라"는 뜻이라서다 — 완성 전 카드가 뜨는 일은 소유 화면이 막는다.
        .onAppear {
            customOpen.formUnion(card.fields.filter(\.startsOpen).map(\.id))
        }
    }

    /// 시각 줄이 출발 기준으로 확정됐는지 — 이면 도착 여유 줄이 흐려지고 캡션이 붙는다. 기준 있는
    /// 줄만 재료로 삼는다: 활동 카드의 시작·종료는 기준이 없어 currentBasis의 ?? .departure
    /// 폴백이 언제나 출발로 답하는데, 그 줄을 재보면 여유 줄은 생기자마자 영구히 흐려진다
    /// (SPEC-UIKIT-003 §1.4 — REQ-014의 선행 조건이라 폴백은 고치지 않고 묻는 대상을 고쳤다).
    private var departureAnchored: Bool {
        guard let time = card.fields.first(where: { $0.kind == .datetime && $0.anchored }) else { return false }
        return currentBasis(time) == .departure
    }

    // MARK: 줄

    @ViewBuilder
    private func fieldRow(_ field: EditField, depBasis: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 줄 이름 옆의 진행 표시 — 화면 소유 상태가 이 줄에서 일하는 중임을 알린다.
            // 장소 검색의 "찾는 중…"과 같은 문법이라 두 진행이 한 카드에서 같게 읽힌다.
            HStack(spacing: 6) {
                Text(field.label)
                if field.busy {
                    // 이름 없는 스피너는 VoiceOver에서 소리만 나고 무엇이 진행 중인지 안 들린다 —
                    // 줄 컨테이너(.contain)가 줄 이름 뒤에 이 문구를 이어 읽는다.
                    ProgressView().controlSize(.small)
                        .accessibilityLabel("진행 중")
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.faint)

            // 값이 차 있는데 앱이 풀지 못해 뜬 줄에만 붙는다. 줄 이름만 있으면 "말한 적 없는 값"을
            // 묻는 줄과 구분되지 않아, 방금 "회사"라고 말한 사용자가 왜 또 묻는지 알 수 없다(결함 O).
            // fixedSize로 줄바꿈을 강제한다 — 길어도 잘리지 않는다(G11: 줄을 숨기지 않는다).
            if let note = field.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if field.kind == .datetime {
                datetimeRow(field)
            } else {
                ChipFlow(spacing: 6, lineSpacing: 6) {
                    ForEach(field.options) { option in
                        chip(option.label, selected: field.chosen == option.value, detail: option.detail) {
                            actions.chooseValue(field.id, option.value)
                            closeCustom(field)
                        }
                    }
                    // 직접 적은 값도 선택된 칩으로 남긴다 — 고른 값이 화면에 없으면 안 고른 것과 같다.
                    if let typed = typedLabel(field) {
                        chip(typed, selected: true) { openCustom(field) }
                    }
                    if field.allowsCustom {
                        // 장소 줄의 그 칩은 이제 빈 칸이 아니라 검색창을 연다 — 이름을 그렇게 적는다.
                        chip(field.kind == .place ? "장소 검색" : "직접입력",
                             selected: false) { openCustom(field) }
                    }
                }

                if customOpen.contains(field.id) { customEditor(field) }

                // 거절 사유에 범위를 적지 않는 이유: 상한이 Store 상수라 문구에 박으면 두 곳이 된다.
                if rejected.contains(field.id) {
                    Text("그 값은 쓸 수 없어요")
                        .font(.caption)
                        .foregroundStyle(Theme.warn)
                }
            }

            // 출발 기준으로 확정된 카드의 도착 여유는 쓰이지 않는다 — 색(흐림)만으로 상태를 말하지
            // 않고 캡션 한 줄로 이중 표현한다. 값은 그대로 골을 수 있고 chosen도 남아 있어서
            // 확인 버튼이 막히지 않는다(직렬화에서만 빠진다).
            if field.kind == .buffer, depBasis {
                Text("출발 기준이라 쓰지 않아요")
                    .font(.caption)
                    .foregroundStyle(Theme.faint)
            }
        }
        // 흐려진 여유 줄 — 살아 있는 줄과 0.5 대 1의 차이만으로는 부족해 캡션과 함께 읽힌다.
        .opacity(field.kind == .buffer && depBasis ? 0.5 : 1)
        // 칩만 따로 읽히면 무엇에 대한 선택인지 알 수 없다 — 줄 이름과 묶어서 읽히게 한다.
        .accessibilityElement(children: .contain)
        // 캡션이 있으면 줄 이름과 함께 읽힌다 — 왜 떴는지가 화면에만 있고 음성엔 없으면 안 된다.
        .accessibilityLabel(field.note.map { "\(field.label). \($0)" } ?? field.label)
    }

    /// 칩 목록에 없는 값이 골라져 있으면 그 표시 문구. 없으면 nil.
    private func typedLabel(_ field: EditField) -> String? {
        guard let chosen = field.chosen,
              !field.options.contains(where: { $0.value == chosen }) else { return nil }
        return field.chosenLabel
    }

    // MARK: 시각 줄

    /// 시각 줄의 현재 기준. 커밋된 값이 있으면 그 접두가 정답이고, 없으면 사용자가 방금 탭한
    /// 임시값이다(처음엔 둘 다 없다 — 기준은 미리 골라두지 않는다).
    private func currentBasis(_ field: EditField) -> ScheduleAnchor? {
        if let chosen = field.chosen { return BesirTime.parseDatetime(chosen).flatMap { BesirTime.anchor(ofPrefix: $0.prefix) } ?? .departure }
        return draftBasis[field.id]
    }

    private func tapBasis(_ field: EditField, _ basis: ScheduleAnchor) {
        // 이미 커밋된 시각이면 같은 시각으로 접두만 바꿔 재확정한다(에디터 재오픈 없이) — 이때
        // 도착 여유 줄의 흐림이 함께 바뀐다.
        actions.rechooseTimeBasis(field.id, basis)
        draftBasis[field.id] = basis
    }

    /// 시각 줄 몸통 — 기준 칩 한 줄, 그 아래 (미선택) 고르기 칩 또는 (커밋) 확정 칩 한 줄. 칩으로
    /// 값을 열거하지 않는 이유는 시각 줄을 만드는 쪽(timeField) 주석에 있다. 둘을 각기 다른
    /// ChipFlow에 두는 이유: 한 흐름에 있으면 시각 칩이 감기는 위치가 폭의 함수가 되어 같은
    /// 카드가 기기 폭·큰 글씨 설정마다 다르게 읽힌다(2026-09-20 사용자 확인 요청 ③).
    private func datetimeRow(_ field: EditField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 기준 없는 줄(활동의 시작·종료)은 이 줄이 통째로 없다 — 기준 칩만 남기면 고를 수
            // 없는 값을 보여주는 셈이다(REQ-001).
            if field.anchored {
                ChipFlow(spacing: 6, lineSpacing: 6) {
                    // 출발 기준 → 도착 기준 순서는 사용자 확인 요청 ③(2026-09-20)이다.
                    ForEach([ScheduleAnchor.departure, .arrival], id: \.self) { basis in
                        chip(basis == .arrival ? "도착 기준" : "출발 기준",
                             selected: currentBasis(field) == basis) {
                            tapBasis(field, basis)
                        }
                    }
                }
            }

            ChipFlow(spacing: 6, lineSpacing: 6) {
                if let label = typedLabel(field) {
                    // 커밋된 값도 선택된 칩 문법으로 남는다(재탭 = 에디터 재오픈) — 텍스트 줄의
                    // 직접입력 칩과 같은 동작. 긴 날짜 문구는 접근성 크기에서 감기게 놔둔다.
                    chip(label, selected: true) { openCustom(field) }
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    chip("날짜·시각 고르기", selected: false) { openCustom(field) }
                }
            }

            if customOpen.contains(field.id) { datetimeEditor(field) }
        }
    }

    /// 시각 에디터 — 다른 줄의 텍스트 에디터 자리에 네이티브 DatePicker가 온다. 바퀴가 보여주는
    /// 위치는 값이 아니다: 확인을 눌러야 chosen이 생긴다. 기준 있는 줄에서 기준을 아직 안 골랐다면
    /// 확인은 아무것도 확정하지 않고, 기준 없는 줄은 chooseTimePlain으로 곧장 확정한다.
    private func datetimeEditor(_ field: EditField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            DatePicker("날짜·시각", selection: Binding(
                get: { draftDate[field.id] ?? Self.nextWholeHour() },
                set: { draftDate[field.id] = $0 }))
            #if os(iOS)
                .datePickerStyle(.graphical)
            #endif
            HStack {
                Spacer()
                Button("확인") {
                    // 기준 있는 줄과 없는 줄이 확정 경로에서 갈라지는 유일한 자리다. 없는 줄을
                    // 아래 guard에 그대로 두면 확인이 조용히 아무 일도 하지 않는다 — 빌드도
                    // 드라이버도 못 잡는 실패 모양이라 여기서 갈라야 한다(REQ-001 (d)).
                    let confirmed: Bool
                    if field.anchored {
                        guard let basis = currentBasis(field) else { return }
                        confirmed = actions.chooseTime(field.id, basis,
                                                       draftDate[field.id] ?? Self.nextWholeHour())
                    } else {
                        confirmed = actions.chooseTimePlain(field.id,
                                                            draftDate[field.id] ?? Self.nextWholeHour())
                    }
                    if confirmed { closeCustom(field) }
                }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.travelInk)
                .padding(.horizontal, 10)
                .frame(minHeight: chipHeight)
                .background(Theme.travelFill, in: Capsule())
            }
        }
    }

    /// 에디터의 처음 바퀴 위치 — "지금에서 다음 정각". 커밋 전까지 이 값은 어떤 것도 아니다.
    private static func nextWholeHour() -> Date {
        Calendar.current.nextDate(after: Date(), matching: DateComponents(minute: 0),
                                  matchingPolicy: .nextTime) ?? Date().addingTimeInterval(3600)
    }

    /// 칩 하나. 선택 표시를 색에만 맡기지 않는다(체크 글리프 + 글자 굵기) — 색을 구분 못 하면
    /// 어느 값을 골랐는지 알 방법이 사라진다. 직접입력 칩도 같은 실선이다(2026-09-24 사용자
    /// 요청으로 통일 — 칩마다 테두리가 다르면 버튼 문법이 흔들린다).
    private func chip(_ label: String, selected: Bool, detail: String? = nil,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark").font(.caption2.weight(.bold))
                }
                Text(label).font(.callout.weight(selected ? .semibold : .regular))
                // 칩 안의 작은 근거 글(소요시간). 한 단계 작게, 미선택일 때는 색도 흐리게 둬
                // 값과 근거가 한 덩어리로 읽히지 않게 한다. 별도 접근성 문구는 붙이지 않는다 —
                // 칩의 Text들이 이미 합쳐 읽히기 때문이다("자동차 32분").
                if let detail {
                    Text(detail).font(.caption)
                        .foregroundStyle(selected ? Theme.bg : Theme.muted)
                }
            }
            .foregroundStyle(selected ? Theme.bg : Theme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: chipHeight)
            .background(selected ? Theme.travel : Theme.bg, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? Color.clear : Theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 직접입력

    /// 텍스트 에디터의 안내문 — .datetime은 여기 안 온다(시각 줄의 에디터는 DatePicker다).
    private func placeholder(for field: EditField) -> String {
        switch field.kind {
        case .place: return "장소 검색 (예: 강남역, 가산디지털단지)"
        case .title: return "제목"
        case .datetime: return "날짜·시각"
        case .mode, .buffer, .notify, .weeks: return "숫자만"
        // 토글 줄은 allowsCustom이 false라 에디터가 열리지 않아 실행 중 도달하지 않는다 —
        // "숫자만"과 묶으면 뜻도 없는 안내문이 붙으므로 따로 둔다(전수 switch 유지).
        case .toggle: return ""
        }
    }

    @ViewBuilder
    private func customEditor(_ field: EditField) -> some View {
        if field.kind == .place { placeSearchEditor(field) } else { textCustomEditor(field) }
    }

    /// 장소 줄의 입력칸 — 빈 칸이 아니라 **검색해서 고르는 자리**다. 자유 텍스트를 그대로 확정하는
    /// 버튼을 두지 않는다: 확정해봐야 좌표가 없어 실행부가 같은 검색으로 다시 실패하고, 그 실패는
    /// 카드를 다 채우고 확인을 누른 **뒤에** 온다(결함 P의 증상 그 자체). 못 찾으면 다른 말로 다시
    /// 치게 하는 쪽이 왕복을 줄인다. 즐겨찾기 칩과 "현재 위치" 칩은 그대로라 길이 막히지 않는다.
    @ViewBuilder
    private func placeSearchEditor(_ field: EditField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(placeholder(for: field), text: placeQueryBinding(field))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .submitLabel(.search)
                #endif
            switch field.lookup {
            case .idle:
                EmptyView()
            case .searching:
                // 검색이 도는 동안에도 다른 줄은 그대로 조작할 수 있다 — 카드를 막지 않는다.
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("찾는 중…").font(.caption).foregroundStyle(Theme.muted)
                }
            case .empty:
                // 0건과 검색 실패(오프라인)를 PlaceSearch가 같은 빈 배열로 돌려줘 앱이 구분하지
                // 못한다 — 구분 못 하는 것을 구분한 척하지 않고 양쪽을 함께 말한다.
                Text("후보를 찾지 못했어요. 다른 이름이나 주소로 적어보세요(인터넷이 끊겨 있을 때도 이렇게 보여요).")
                    .font(.caption).foregroundStyle(Theme.warn)
                    .fixedSize(horizontal: false, vertical: true)
            case .results(let places):
                ForEach(places, id: \.self) { place in
                    suggestionRow(field, place)
                }
            }
        }
    }

    /// 후보 한 줄. 탭하면 그 순간 좌표까지 확정된다 — 확인 뒤에 실패할 자리가 사라진다.
    private func suggestionRow(_ field: EditField, _ place: Place) -> some View {
        Button {
            actions.choosePlace(field.id, place)
            closeCustom(field)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name).font(.callout).foregroundStyle(Theme.ink)
                // 같은 이름의 다른 지점을 가르는 건 주소뿐이다 — 이름만 보여주면 고르는 의미가 없다.
                if !place.address.isEmpty {
                    Text(place.address).font(.caption).foregroundStyle(Theme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: chipHeight)
            .background(Theme.bg, in: RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(place.address.isEmpty ? place.name : "\(place.name), \(place.address)")
    }

    /// 숫자·제목 줄의 입력칸(장소 외 전부). 여기는 값을 그대로 확정하는 것이 맞다 — 확인 뒤에
    /// 실패할 외부 조회가 없다.
    @ViewBuilder
    private func textCustomEditor(_ field: EditField) -> some View {
        HStack(spacing: 6) {
            TextField(placeholder(for: field), text: draftBinding(field))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                // 숫자 줄은 숫자판이 편하지만 숫자판엔 완료 키가 없다 — 그래서 확인 버튼이 있다.
                .keyboardType(field.kind == .place || field.kind == .title ? .default : .numberPad)
                #endif
                .onSubmit { submitCustom(field) }
            Button("확인") { submitCustom(field) }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.travelInk)
                .padding(.horizontal, 10)
                .frame(minHeight: chipHeight)
                .background(Theme.travelFill, in: Capsule())
        }
    }

    /// 장소 줄의 입력 바인딩. 묶음(디바운스)은 assistant가 한다 — 뷰가 타이머를 들면 카드가 다시
    /// 그려질 때마다 흩어져 글자마다 호출이 나간다(카카오 일일 할당량).
    private func placeQueryBinding(_ field: EditField) -> Binding<String> {
        Binding(
            get: { draft[field.id] ?? "" },
            set: { text in
                draft[field.id] = text
                rejected.remove(field.id)
                actions.searchPlaces(field.id, text)
            }
        )
    }

    private func draftBinding(_ field: EditField) -> Binding<String> {
        Binding(
            get: { draft[field.id] ?? "" },
            set: { text in
                draft[field.id] = text
                // 고쳐 쓰기 시작하면 거절 표시는 지운다 — 남아 있으면 지금 값이 거절된 것처럼 보인다.
                rejected.remove(field.id)
            }
        )
    }

    private func openCustom(_ field: EditField) {
        draft[field.id] = typedLabel(field) == nil ? "" : (field.chosen ?? "")
        // 시각 줄을 다시 열 때는 확정 시각으로 바퀴 씨앗을 뿌린다 — 재오픈한 바퀴가 지금 기준
        // 정각에 앉으면 확인만 눌러도 시각이 조용히 바뀐다. 해석은 BesirTime이 단일 출처이고,
        // 풀리지 않는 값이면 씨앗을 뿌리지 않아 정각 폴백이 이어진다.
        if field.kind == .datetime, let chosen = field.chosen {
            draftDate[field.id] = BesirTime.parseDatetime(chosen)?.date
        }
        customOpen.insert(field.id)
    }

    private func closeCustom(_ field: EditField) {
        customOpen.remove(field.id)
        rejected.remove(field.id)
    }

    /// 거절되면 입력창을 열어둔 채 표시만 남긴다 — 닫아버리면 무엇이 안 받아들여졌는지 사라진다.
    private func submitCustom(_ field: EditField) {
        if actions.submitCustom(field.id, draft[field.id] ?? "") {
            draft[field.id] = ""
            closeCustom(field)
        } else {
            rejected.insert(field.id)
        }
    }

    // MARK: 확인

    // 확인 문구가 nil이면 아예 그리지 않는다 — 소유 화면이 자기 제출 버튼을 갖고 있을 때
    // 둘이면 제출이 두 군데서 일어나는 것처럼 읽히기 때문이다.
    @ViewBuilder
    private var confirmButton: some View {
        if let confirmTitle = chrome.confirmTitle {
            Button { Task { await actions.confirm() } } label: {
                HStack(spacing: 6) {
                    Spacer(minLength: 0)
                    if busy {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(confirmTitle).font(.callout.weight(.semibold))
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(canConfirm ? Theme.bg : Theme.muted)
                .frame(maxWidth: .infinity, minHeight: chipHeight)
                .background(canConfirm ? Theme.travel : Theme.bg,
                            in: RoundedRectangle(cornerRadius: Theme.radius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius)
                        .stroke(canConfirm ? Color.clear : Theme.line)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
            .accessibilityHint(card.isReady ? "" : "빠진 값을 모두 고르면 눌 수 있어요")
        }
    }
}

/// 칩을 줄바꿈으로 흘려 넣는 배치.
///
/// 가로 스크롤을 쓰지 않는 이유: 화면 밖으로 밀린 칩은 **고를 수 없는 값**이고, 이 카드에서
/// 못 고른 값은 그대로 조용한 기본값이 된다. 반복 일정이면 줄이 다섯을 넘지만 카드는 길어져도
/// 되고, 스크롤은 채팅 쪽 ScrollView가 이미 맡고 있다.
struct ChipFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? (rows.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// 배치와 크기 계산이 같은 함수를 쓴다 — 따로 세면 높이와 실제 줄 수가 어긋난다.
    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            // 칩 하나가 한 줄보다 넓어도 줄을 새로 열지 않는다 — 빈 줄만 생긴다.
            if !row.items.isEmpty, row.width + spacing + size.width > maxWidth {
                rows.append(row)
                row = Row()
            }
            row.width += row.items.isEmpty ? size.width : spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append((index, size))
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}
