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
    @State private var addingToCalendar = false
    /// 지금 떠 있는 경로 조회. 출발지 좌표가 GPS 정밀화로 계속 미세하게 바뀌면 키가 다시
    /// 불리고, 취소 없이 두면 조회가 한 벌씩 쌓여 카카오·ODsay 할당량이 타며(t11 sync N5),
    /// 취소된 조회는 서비스가 try?로 삼키기 때문에 빈 결과로 정상 돌아와 늦은 옛 결과가 새
    /// 결과를 덮는다.
    @State private var transitTask: Task<Void, Never>?

    /// 38pt 고정은 큰 글씨를 무시한다(D-4 9번) — 출발 숫자가 본문과 함께 자라게 한다.
    @ScaledMetric(relativeTo: .largeTitle) private var departureTimeSize: CGFloat = 38

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
                    // 지도 클립은 크롬이 아니라 콘텐츠 경계다 — Theme.radius(3)를 얹으면 280pt
                    // 이미지가 사각형과 구분되지 않는다(D-4 2번 유지 판정).
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("\(event.destination.name) 지도")

                departureCard

                transitItinerary

                calendarButton

                detailRows
            }
            .padding(24)
        }
        .background(Theme.bg)
        .navigationTitle(event.title)
        // 처음 표시 + 일정의 수단·출발지·목적지가 바뀔 때마다 경로 재로딩. 이전 조회는 취소하고
        // 새로 띄운다(LocationManager.startTimeout과 같은 취소-교체) — 취소는 URLSession의 진행
        // 중 요청까지 끊어, 바뀌어버린 옛 조회를 끝까지 태우지 않는다.
        .onChange(of: transitTaskKey, initial: true) {
            transitTask?.cancel()
            transitTask = Task { await loadTransitPath() }
        }
        // 사라진 화면의 결과를 위해 네트워크를 태우지 않는다(AddEventView의 정리 계약과 같은
        // 판단) — 상세를 닫아도 진행 중인 조회는 계속 도는 게 지금까지의 모습이었다.
        .onDisappear { transitTask?.cancel() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingEdit = true } label: { Label("편집", systemImage: "pencil") }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEventView(editing: event)
        }
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

    /// 등록은 로컬에서 끝나고 캘린더 업로드는 뒤따라 돈다 — 그 중간 상태가 여기 보이지 않으면
    /// 사용자는 "등록 완료"만 보고 캘린더가 빈 이유를 알 길이 없다(그게 이번 결함이었다).
    @ViewBuilder
    private var calendarButton: some View {
        Group {
            if store.googleConnected {
                if event.googleEventId != nil {
                    Label("구글 캘린더에 등록됨", systemImage: "checkmark.circle.fill")
                        .font(.callout).foregroundStyle(Theme.travel)
                } else if event.calendarUpload == .pending {
                    Label(CalendarUploadState.pending.title,
                          systemImage: CalendarUploadState.pending.systemImage)
                        .font(.callout).foregroundStyle(Theme.muted)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        // 실패해도 버튼은 남긴다 — 여기가 바로 재시도할 수 있는 유일한 자리다.
                        if event.calendarUpload == .failed {
                            Label(CalendarUploadState.failed.title,
                                  systemImage: CalendarUploadState.failed.systemImage)
                                .font(.callout).foregroundStyle(Theme.warn)
                        }
                        Button {
                            Task { await addToGoogleCalendar() }
                        } label: {
                            Label(addingToCalendar ? "추가 중…" : "구글 캘린더에 추가",
                                  systemImage: "calendar.badge.plus")
                        }
                        .disabled(addingToCalendar)
                    }
                }
            } else if store.config.hasGoogleCalendar {
                // 연동이 설정만 돼 있고 계정이 안 붙은 상태. 예전엔 이 경우에도 등록을 시도했다가
                // 전부 실패하고 아무 말도 안 했다 — 왜 캘린더가 비었는지 여기서 말해준다.
                Label("구글 계정이 연결되지 않아 캘린더에는 올리지 않았어요. 설정에서 연결할 수 있어요.",
                      systemImage: "person.crop.circle.badge.xmark")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
        }
    }

    private func addToGoogleCalendar() async {
        addingToCalendar = true
        defer { addingToCalendar = false }
        // 실패 문구는 레코드의 calendarUpload가 단일 출처다 — 화면에 같은 문장을 또 두지 않는다(계약 5).
        await store.pushToCalendar(eventID: event.id)
    }

    private func loadTransitPath() async {
        routeSegments = []
        transitSteps = []
        guard let origin = originCoord else { return }
        switch event.mode {
        case .transit:
            guard store.config.hasProxy else { return }
            let plan = await store.directions.transitPlan(from: origin, to: destCoord)
            // 취소된 조회는 에러가 아니라 빈 결과로 돌아온다(서비스가 try?로 삼킨다) — await 뒤
            // 재확인 없이 쓰면 옛 조회의 빈 결과가 새 조회의 결과를 덮는다(setLookup과 같은 규율).
            guard !Task.isCancelled else { return }
            routeSegments = plan.segments
            transitSteps = plan.steps
        case .car:
            let segments = await store.directions.carRouteSegments(from: origin, to: destCoord)
            guard !Task.isCancelled else { return }
            routeSegments = segments
        case .walk:
            let segments = await store.directions.walkRouteSegments(from: origin, to: destCoord)
            guard !Task.isCancelled else { return }
            routeSegments = segments
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(event.destination.name, systemImage: "flag.fill")
                .font(.title2).bold()
            if !event.destination.address.isEmpty {
                Text(event.destination.address).foregroundStyle(Theme.muted)
            }
            Label("도착 \(BesirTime.full.string(from: event.arrivalDate))", systemImage: "clock")
                .font(.callout).foregroundStyle(Theme.muted)
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
                Group {
                    HStack(alignment: .firstTextBaseline) {
                        Text("출발 시각")
                            .foregroundStyle(Theme.muted)
                        Spacer()
                        Text(BesirTime.clock.string(from: dep))
                            .font(.system(size: departureTimeSize, weight: .bold, design: .rounded))
                            .foregroundStyle(isPast ? Theme.nowLine : Theme.travel)
                    }
                    if isPast {
                        Text("⚠️ 이미 출발 시각이 지났습니다.")
                            .font(.caption).foregroundStyle(Theme.warn)
                    } else {
                        // 알림 상태는 사실대로 — 꺼졌거나, 예약돼 있거나, 아니라면 그 이유까지
                        // (판정식은 alarmStatus에). "예약됨"이라고만 쓰면 울리지 않을 약속을
                        // 화면이 한다(D-3).
                        Text("출발까지 \(relativeText(to: dep)) 남음 · \(alarmStatus(for: event, departure: dep))")
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                // 시각과 상태 캡션을 한 덩어리로 낭독한다(REQ-023) — 따로 읽히면 "언제"와 "얼마나
                // 남았는지"가 갈라져 한 번에 이해되지 않는다.
                .accessibilityElement(children: .combine)
            }
            .padding(18)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
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
                            .font(.caption).foregroundStyle(Theme.muted)
                    }
                }
                .padding(.bottom, 6)

                ForEach(Array(transitSteps.enumerated()), id: \.element.id) { index, step in
                    stepRow(step,
                            at: stepStartTime(index),
                            isLast: index == transitSteps.count - 1)
                }

                Text("ODsay 실시간 시간표가 아닌 평균 소요시간 기준 예상값입니다.")
                    .font(.caption2).foregroundStyle(Theme.faint)
                    .padding(.top, 8)
            }
            .padding(18)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
        }
    }

    private func stepRow(_ step: TransitStep, at time: Date?, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: step.systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    // 뱃지 바탕은 API가 준 노선색(콘텐츠)이라 Theme 의미색이 아니다 — 고정 콘텐츠색
                    // 위 글자는 Theme.bg(다크 모드에서 거의 검정)보다 흰 쪽이 두 모드 다 읽힌다.
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(hex: step.color), in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(minHeight: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.headline).font(.callout).bold()
                Text(step.detail).font(.caption).foregroundStyle(Theme.muted)
            }
            .padding(.top, 3)

            Spacer(minLength: 8)

            if let time {
                Text(Self.shortTimeFmt.string(from: time))
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 5)
            }
        }
        // 헤드라인과 예상 시각을 함께 읽는다(REQ-023) — 시각만 따로 읽히면 어느 단계의 시각인지
        // 알 수 없다.
        .accessibilityElement(children: .combine)
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
            // 값 행(+반복 배지)만 카드로 감싼다 — 삭제 단추는 카드 밖에 그대로 둔다(AC-006
            // 8·9행의 분할이 규범 — REQ-020의 :302-348 인용이 잘못 넓었고 0.1.3으로 정정).
            VStack(alignment: .leading, spacing: 10) {
                row("이동수단", "\(event.mode.title)")
                row("도착 여유(버퍼)", "\(event.bufferMinutes)분")
                // 위 캡션(alarmStatus)은 알림 상태를 사실대로 말하는데 이 행은 무조건 "출발 N분 전"을
                // 그려 "알림 꺼짐" 캡션과 모순됐다 — 끈 일정에는 받지 않음을 보인다.
                row("알림", event.wantsNotification ? "출발 \(event.notifyLeadMinutes)분 전" : "받지 않음")
                if event.recurrenceId != nil {
                    Label("반복 일정", systemImage: "repeat")
                        .font(.caption).foregroundStyle(Theme.muted)
                }
            }
            .padding(18)
            .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
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

    /// 알림 상태 문구 — 화면이 예약 여부를 사실대로 말한다(D-3). notificationId == nil에는
    /// 두 원인이 섞여 있다(과거 시각 거부·64건 창 밖 대기 — 리스케줄러가 가까운 것만 채운다).
    /// 아이디만으로는 갈라지지 않으므로 알림 시각으로 판정한다.
    private func alarmStatus(for event: ScheduledEvent, departure: Date) -> String {
        if !event.wantsNotification { return "알림 꺼짐" }
        if event.notificationId != nil { return "\(event.notifyLeadMinutes)분 전 알림 예약됨" }
        return departure.addingTimeInterval(-Double(event.notifyLeadMinutes) * 60) <= Date()
            ? "알림 시각이 지나 예약 없음"
            : "가까워지면 알림 예약돼요"
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(Theme.muted)
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
