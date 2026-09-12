import SwiftUI
import CoreLocation

/// 이동이 아닌 체류형 활동(수업·근무·약속 등)을 수동으로 한 번만 추가하는 화면.
/// 반복 활동은 AI 채팅으로 만든다 — 여긴 "+" 메뉴에서 만드는 단발성 활동 전용.
///
/// 활동과 함께 "가는 이동 / 오는 이동"도 같이 만들 수 있다. 따로따로 만들면 둘 사이에 아무
/// 연결이 없어서 나중에 활동 블록을 옮겨도 이동 블록이 제자리에 남는데, 여기서 같이 만들면
/// `linkedActivityId`로 묶여서 활동을 옮길 때 이동도 따라 움직이고 지울 때도 같이 지워진다.
struct AddActivityView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var locationPlace: Place?
    @State private var startDate = Date().addingTimeInterval(3600)
    @State private var endDate = Date().addingTimeInterval(7200)
    @State private var saving = false

    // 함께 만들 이동 구간.
    @State private var addOutbound = false
    @State private var originPlace: Place?
    @State private var addReturn = false
    @State private var returnPlace: Place?
    /// 가는 편과 오는 편은 수단이 다른 경우가 흔하다(갈 땐 지하철, 올 땐 택시 등) — 따로 고른다.
    @State private var outboundMode: TransportMode = .transit
    @State private var returnMode: TransportMode = .transit
    @State private var notifyEnabled = true
    @State private var syncToCalendar = true

    /// 이동 구간의 기본값. 만든 뒤 이동 블록 상세에서 바꿀 수 있어 여기선 묻지 않는다.
    private let defaultBuffer = 10
    private let defaultNotify = 30

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty, endDate > startDate else { return false }
        // 이동을 만들려면 활동 장소(= 이동의 목적지/출발지)와 상대편 장소가 둘 다 있어야 한다.
        if addOutbound && (locationPlace == nil || originPlace == nil) { return false }
        if addReturn && (locationPlace == nil || returnPlace == nil) { return false }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    titleField
                    PlaceField(title: "장소 (선택)", systemImage: "mappin.circle.fill", place: $locationPlace)
                    timeSection
                    travelSection
                    optionsSection
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
    }

    private var header: some View {
        HStack {
            Text("새 활동").font(.title2).bold()
            Spacer()
            Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding()
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("활동 제목").font(.headline)
            TextField("예: 스터디 모임", text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("시간").font(.headline)
            DatePicker("시작", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
            DatePicker("종료", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
        }
    }

    @ViewBuilder
    private var travelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이동 일정 함께 만들기").font(.headline)
            if locationPlace == nil {
                Text("장소를 정하면 이동도 함께 만들 수 있어요")
                    .font(.caption).foregroundStyle(Theme.faint)
            } else {
                Toggle("가는 이동 (활동 시작에 맞춰 도착)", isOn: $addOutbound)
                if addOutbound {
                    VStack(alignment: .leading, spacing: 8) {
                        PlaceField(title: "출발지", systemImage: "figure.walk.departure", place: $originPlace)
                        modePicker("가는 편 이동수단", selection: $outboundMode)
                    }
                    .padding(.leading, 12)
                }
                Toggle("오는 이동 (활동 끝나면 출발)", isOn: $addReturn)
                if addReturn {
                    VStack(alignment: .leading, spacing: 8) {
                        PlaceField(title: "도착지", systemImage: "house", place: $returnPlace)
                        modePicker("오는 편 이동수단", selection: $returnMode)
                    }
                    .padding(.leading, 12)
                }
                if addOutbound || addReturn {
                    Text("여유 \(defaultBuffer)분 · 알림 \(defaultNotify)분 전")
                        .font(.caption2).foregroundStyle(Theme.faint)
                }
            }
        }
    }

    private func modePicker(_ label: String, selection: Binding<TransportMode>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Picker(label, selection: selection) {
                ForEach(TransportMode.allCases) { m in
                    Label(m.title, systemImage: m.systemImage).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var optionsSection: some View {
        if (addOutbound || addReturn) || (store.config.hasGoogleCalendar && store.config.autoAddToCalendar) {
            VStack(alignment: .leading, spacing: 10) {
                if addOutbound || addReturn {
                    Toggle("이동 알림 받기", isOn: $notifyEnabled)
                }
                if store.config.hasGoogleCalendar && store.config.autoAddToCalendar {
                    Toggle("구글 캘린더에도 등록", isOn: $syncToCalendar)
                }
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
                if saving { ProgressView().controlSize(.small) } else { Text("추가") }
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canSave || saving)
        }
        .padding()
    }

    private func save() async {
        saving = true
        await store.addActivityWithTravel(title: title,
                                          location: locationPlace,
                                          startDate: startDate,
                                          endDate: endDate,
                                          travelFrom: addOutbound ? originPlace : nil,
                                          returnTo: addReturn ? returnPlace : nil,
                                          outboundMode: outboundMode,
                                          returnMode: returnMode,
                                          bufferMinutes: defaultBuffer,
                                          notifyLeadMinutes: defaultNotify,
                                          notifyEnabled: notifyEnabled,
                                          syncToCalendar: syncToCalendar)
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
                            Text(p.address).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("변경") { place = nil }.buttonStyle(.borderless)
                }
                .padding(10)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
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
                                Text(found.address).font(.caption).foregroundStyle(.secondary)
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
