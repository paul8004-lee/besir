import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    /// 홈(서비스 선택 화면)으로 돌아가기. RootView가 넘겨준다.
    var onBack: (() -> Void)? = nil

    @EnvironmentObject var store: Store
    @EnvironmentObject var location: LocationManager
    @EnvironmentObject var assistant: AIAssistant

    @State private var selection: ScheduledEvent.ID?
    @State private var selectedActivityId: ActivityBlock.ID?
    @State private var showingAdd = false
    @State private var showingAddActivity = false
    @State private var showingSettings = false
    @State private var showingFavorites = false

    /// true = 월간 그리드만 표시. false = 주간 스트립 + 일간 시간표 표시.
    @State private var isMonthExpanded = true
    @State private var selectedDate: Date = Date()

    /// 드래그로 재조정 중인 블록(시간표에서 꾹 눌러 옮기는 동안의 임시 상태).
    @State private var activeDrag: ActiveDrag?
    /// 반복 일정 블록을 옮겼을 때 "전체/이 일정만" 확인이 필요한 대기 중인 이동.
    @State private var pendingMove: PendingMove?

    /// tapOnlyGesture가 이 터치 동안 한 번이라도 임계값을 넘겨 움직였는지 기록한다.
    /// 스와이프하다 손을 뗄 때 "돌아오는" 움직임 때문에 최종 translation만으로는
    /// 순간 이동거리가 작게 나와 탭으로 오인되는 경우(월간 캘린더 스와이프 중 날짜가
    /// 잘못 선택되던 버그)를 막기 위함 — 한 번이라도 스와이프였다면 손을 뗄 때까지 탭 무시.
    @GestureState private var tapGestureExceededThreshold = false

    private let calendar = Calendar.current
    private let hourHeight: CGFloat = 56

    /// DateFormatter는 생성 비용이 큰데(로케일·포맷 파싱) 아래 셀들은 스와이프 중 매 프레임,
    /// 한 페이지당 7~42개씩 다시 그려진다 — 매번 새로 만들면 그게 그대로 프레임 낭비다.
    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "E"; return f
    }()
    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "yyyy년 M월"; return f
    }()
    private static let dayTitleFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "M월 d일 (E)"; return f
    }()
    private static let todayTitleFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "ko_KR"); f.dateFormat = "'오늘' M월 d일 (E)"; return f
    }()

    var selectedEvent: ScheduledEvent? {
        store.events.first { $0.id == selection }
    }

    // MARK: - 드래그 상태

    private struct ActiveDrag {
        enum Kind {
            case event(ScheduledEvent)
            case activity(ActivityBlock)
        }
        var kind: Kind
        var deltaMinutes: Int = 0
        var blockId: String {
            switch kind {
            case .event(let e): return "e-\(e.id)"
            case .activity(let a): return "a-\(a.id)"
            }
        }
    }

    private struct PendingMove {
        let message: String
        let apply: (Bool) -> Void   // Bool = wholeSeries
    }

    // MARK: - 날짜별 데이터

    /// 자정을 넘는 이동은 출발일과 도착일 양쪽에 나열한다(결함 G) — 도착일에만 두면 출발일
    /// 저녁 구간이 통째로 그려지지 않는다. 겹침 판정은 Store.overlapsDay(start:end:day:) 한
    /// 곳에 있고 월간·주간 점(daysWithSchedule)도 같은 판정으로 켜진다 — 같은 앱이 같은 날에
    /// 대해 다른 말을 하지 않게(계약 5). 출발시각이 없는(계산 실패) 일정은 구간이 없으므로
    /// 도착일에만 세우는 기존 동작을 유지한다.
    private func events(on date: Date) -> [ScheduledEvent] {
        store.events.filter { e in
            guard let dep = e.departureDate, e.arrivalDate > dep else {
                return calendar.isDate(e.arrivalDate, inSameDayAs: date)
            }
            return Store.overlapsDay(start: dep, end: e.arrivalDate, day: date, calendar: calendar)
        }
        .sorted { $0.arrivalDate < $1.arrivalDate }
    }

    /// 활동도 이동과 같은 기준으로 [시작, 끝) 구간이 그 날과 겹치면 나열한다 — 자정을 넘는
    /// 활동의 끝날 반쪽이 통째로 안 그려지던 것(결함 G)이 이것으로 닫힌다. 시작·끝이 같거나
    /// 어긋난 깨진 레코드는 구간이 없으므로 시작일에만 두는 기존 동작을 유지한다.
    private func activities(on date: Date) -> [ActivityBlock] {
        store.activities.filter { a in
            guard a.endDate > a.startDate else {
                return calendar.isDate(a.startDate, inSameDayAs: date)
            }
            return Store.overlapsDay(start: a.startDate, end: a.endDate, day: date, calendar: calendar)
        }
        .sorted { $0.startDate < $1.startDate }
    }

    /// 월간 그리드가 좌우 스와이프 중에도 매 프레임 부르는 함수라 O(1) 캐시(Store.daysWithSchedule)만
    /// 본다 — 예전엔 events/activities 전체를 매번 훑어서(day * event 조합) 스와이프 중 버벅였다.
    private func hasEvents(on date: Date) -> Bool {
        store.daysWithSchedule.contains(Store.dayKey(date, calendar: calendar))
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ContentUnavailableView("일정을 선택하세요",
                                   systemImage: "calendar",
                                   description: Text("왼쪽 위 + 버튼으로 새 일정을 추가하세요."))
        }
        // NavigationSplitView의 detail 컬럼은 iPhone처럼 좁은 화면(compact)에서는 실제 네비게이션
        // push가 있어야 사이드바에서 넘어간다 — selection 상태만 바꿔서는(제스처로 탭했을 때처럼)
        // 화면 전환이 일어나지 않는다(탭해도 상세정보가 안 보이던 원인). 시트로 띄우면 이 문제가 없다.
        .sheet(isPresented: Binding(
            get: { selection != nil },
            set: { if !$0 { selection = nil } }
        )) {
            if let event = selectedEvent {
                NavigationStack {
                    EventDetailView(event: event)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("닫기") { selection = nil }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedActivityId != nil },
            set: { if !$0 { selectedActivityId = nil } }
        )) {
            if let activityId = selectedActivityId {
                ActivityDetailView(activityId: activityId)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEventView()
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingFavorites) {
            FavoritesView()
        }
        // AI 채팅 시트는 RootView가 띄운다 — 홈·be full sir에서도 같은 버튼이 있어서,
        // 여기에만 달아두면 그 화면들에서는 시트가 뜰 데가 없다(버튼이 먹통이 되던 원인).
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            calendarHeader

            if isMonthExpanded {
                monthGrid
            } else {
                weekStrip
                Divider()
                dayTimetable
            }
        }
        .background(Theme.bg)
        .navigationTitle("be on-time sir")
        .frame(minWidth: 280)
        .confirmationDialog(pendingMove?.message ?? "", isPresented: Binding(
            get: { pendingMove != nil },
            set: { if !$0 { pendingMove = nil } }
        ), titleVisibility: .visible) {
            Button("전체 반복 일정 이동") { pendingMove?.apply(true); pendingMove = nil }
            Button("이 일정만 이동") { pendingMove?.apply(false); pendingMove = nil }
            Button("취소", role: .cancel) { pendingMove = nil }
        }
        .toolbar {
            if let onBack {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onBack() } label: { Label("홈", systemImage: "chevron.left") }
                }
            }
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await store.syncWithGoogle() } } label: {
                    if store.isSyncing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .help("구글 캘린더와 동기화")
                .disabled(store.isSyncing)
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button { selectedDate = Date(); isMonthExpanded = false } label: { Image(systemName: "calendar.badge.clock") }
                    .help("오늘로 이동")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .help("설정")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { showingFavorites = true } label: { Image(systemName: "star") }
                    .help("즐겨찾기 장소")
            }
            if store.config.hasAI {
                ToolbarItem(placement: .primaryAction) {
                    Button { assistant.isPresented = true } label: { Image(systemName: "sparkles") }
                        .help("AI로 일정 추가 · 공유받기")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showingAdd = true } label: { Label("이동 일정 추가", systemImage: "arrow.triangle.turn.up.right.diamond") }
                    Button { showingAddActivity = true } label: { Label("활동 추가", systemImage: "clock") }
                } label: {
                    Image(systemName: "plus")
                }
                .help("새 일정 추가")
            }
        }
    }

    // MARK: - 헤더(월간⇄주간+일간 전환)

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut) { isMonthExpanded.toggle() }
            } label: {
                Image(systemName: isMonthExpanded ? "chevron.down.circle" : "chevron.up.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(isMonthExpanded ? "일간 보기로" : "월간 보기로")

            Spacer()
            Text(isMonthExpanded ? monthTitle(selectedDate) : dayTitle(selectedDate))
                .font(.headline).foregroundStyle(Theme.ink)
            Spacer()

            // 좌우 대칭을 위한 자리(버튼 없음 — 넘기기는 스와이프로 처리).
            Color.clear.frame(width: 22, height: 22)
        }
        .padding()
    }

    // MARK: - 월간(Month) 그리드

    private var monthGrid: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(Theme.faint).frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // 손가락을 따라 이전/현재/다음 달이 함께 움직이는 캐러셀.
            SwipePager(date: $selectedDate,
                       step: { d, delta in calendar.date(byAdding: .month, value: delta, to: d) ?? d }) { pageDate in
                monthGridContent(for: pageDate)
            }
            .frame(height: 240)
            Spacer()
        }
        .padding(.top, 2)
    }

    private func monthGridContent(for date: Date) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
            ForEach(daysInMonthGrid(for: date), id: \.self) { day in
                dayCell(day)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    private func dayCell(_ day: Date) -> some View {
        let inMonth = calendar.isDate(day, equalTo: selectedDate, toGranularity: .month)
        let isToday = calendar.isDateInToday(day)
        return VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: day))")
                .font(.callout)
                .foregroundStyle(inMonth ? Theme.ink : Theme.faint)
            Circle()
                .fill(hasEvents(on: day) ? Theme.travel : .clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        // 오늘은 테두리로 감싸지 않고 아래 선 하나로만 표시한다(이 방향은 선으로 나눈다).
        .overlay(alignment: .bottom) {
            Rectangle().fill(isToday ? Theme.ink : .clear).frame(height: 1.5).padding(.horizontal, 10)
        }
        .contentShape(Rectangle())
        // Button은 스와이프 도중에도 탭으로 오인하는 경우가 있어(월간 캘린더 스와이프 중 날짜가
        // 잘못 선택되던 버그), 이동 거리를 직접 확인하는 제스처로 교체했다.
        .gesture(tapOnlyGesture {
            selectedDate = day
            withAnimation(.easeInOut) { isMonthExpanded = false }
        })
    }

    /// 항상 6주(42칸) 격자로 반환해 레이아웃이 흔들리지 않게 한다.
    private func daysInMonthGrid(for date: Date) -> [Date] {
        let comps = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: comps) else { return [] }
        let leading = calendar.component(.weekday, from: monthStart) - 1
        guard let gridStart = calendar.date(byAdding: .day, value: -leading, to: monthStart) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private func monthTitle(_ d: Date) -> String { Self.monthTitleFormatter.string(from: d) }

    // MARK: - 주간(Week) 스트립 — 일간 보기 위에 표시

    /// 손가락을 따라 이전/현재/다음 주가 함께 움직이는 캐러셀(일간 시간표와 같은 SwipePager 재사용,
    /// 한 번에 7일씩 이동). selectedDate를 그대로 공유하므로 주를 넘기면 아래 일간 시간표도 같이 넘어간다.
    private var weekStrip: some View {
        SwipePager(date: $selectedDate,
                   step: { d, delta in calendar.date(byAdding: .day, value: delta * 7, to: d) ?? d },
                   isLocked: activeDrag != nil) { pageDate in
            weekStripContent(for: pageDate)
        }
        .frame(height: 64)
    }

    private func weekStripContent(for date: Date) -> some View {
        HStack(spacing: 4) {
            ForEach(daysInWeek(for: date), id: \.self) { day in
                weekDayCell(day)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func weekDayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        return VStack(spacing: 3) {
            Text(Self.weekdayFormatter.string(from: day)).font(.caption2).foregroundStyle(Theme.faint)
            Text("\(calendar.component(.day, from: day))")
                .font(.callout)
                .foregroundStyle(isSelected ? Theme.ink : (isToday ? Theme.travel : Theme.muted))
            Circle()
                .fill(hasEvents(on: day) ? Theme.travel : .clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        // 선택은 면을 칠하지 않고 밑줄로만 — 주간 스트립이 색 덩어리가 되지 않게.
        .overlay(alignment: .bottom) {
            Rectangle().fill(isSelected ? Theme.ink : .clear).frame(height: 1.5).padding(.horizontal, 6)
        }
        .contentShape(Rectangle())
        .gesture(tapOnlyGesture { selectedDate = day })
    }

    /// 이동 거리를 직접 확인해 "탭"만 처리하는 가벼운 제스처(Button은 스와이프 중에도
    /// 탭으로 오인하는 경우가 있어 쓰지 않는다). onEnded 시점의 translation은 시작점→끝점의
    /// "순 이동거리"라 스와이프 후 살짝 되돌아오며 손을 떼면 작게 나올 수 있다 — 그래서 도중에
    /// 한 번이라도 임계값을 넘겼는지(tapGestureExceededThreshold)도 같이 확인한다.
    private func tapOnlyGesture(onTap: @escaping () -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($tapGestureExceededThreshold) { value, state, _ in
                if max(abs(value.translation.width), abs(value.translation.height)) > 12 { state = true }
            }
            .onEnded { value in
                let moved = max(abs(value.translation.width), abs(value.translation.height))
                if moved <= 12 && !tapGestureExceededThreshold { onTap() }
            }
    }

    private func daysInWeek(for date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        var days: [Date] = []
        var cur = interval.start
        while cur < interval.end {
            days.append(cur)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cur) else { break }
            cur = next
        }
        return days
    }

    private func dayTitle(_ d: Date) -> String {
        (calendar.isDateInToday(d) ? Self.todayTitleFormatter : Self.dayTitleFormatter).string(from: d)
    }

    // MARK: - 일간(day) 시간표(타임라인) UI

    @ViewBuilder
    private var dayTimetable: some View {
        // 손가락을 따라 이전/현재/다음 날이 함께 움직이는 캐러셀. 블록을 드래그하는 동안(activeDrag)은
        // 페이지 전환용 좌우 제스처를 잠가 재조정 드래그와 서로 방해하지 않게 한다.
        SwipePager(date: $selectedDate,
                   step: { d, delta in calendar.date(byAdding: .day, value: delta, to: d) ?? d },
                   isLocked: activeDrag != nil) { pageDate in
            dayTimetableContent(for: pageDate)
        }
    }

    private func dayTimetableContent(for date: Date) -> some View {
        let dayEvents = events(on: date)
        let dayActivities = activities(on: date)
        let placed = positionedBlocks(events: dayEvents, activities: dayActivities, on: date)
        return ScrollView {
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 0) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h))
                            .font(.caption2).foregroundStyle(Theme.faint)
                            .frame(width: 28, height: hourHeight, alignment: .top)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(0..<24, id: \.self) { _ in
                                Divider().overlay(Theme.line).frame(height: hourHeight, alignment: .top)
                            }
                        }
                        ForEach(placed) { p in
                            let f = columnFrame(p, total: geo.size.width)
                            blockView(for: p, on: date)
                                .frame(width: f.width)
                                .offset(x: f.x, y: offsetY(for: p))
                        }
                        // 오늘이면 지금 시각을 가는 선으로 표시한다 — "다음 일정까지 얼마 남았나"를
                        // 스크롤하며 시각을 세지 않아도 알 수 있다.
                        if calendar.isDateInToday(date) {
                            Rectangle()
                                .fill(Theme.nowLine)
                                .frame(height: 1)
                                .offset(y: minutesSinceMidnight(Date()) / 60 * hourHeight)
                                .allowsHitTesting(false)
                        }
                    }
                    #if os(iOS)
                    // SwiftUI의 LongPress+Drag 조합 제스처는(.simultaneousGesture로 붙여도) ScrollView의
                    // 팬 제스처·블록의 onTapGesture와 계속 충돌했다(실패하는 시도조차 터치를 붙잡고 있음).
                    // UIKit 레벨에서 shouldRecognizeSimultaneouslyWith를 직접 true로 선언하면 확실히
                    // 동시 인식되므로, 투명 오버레이 하나로 이 부분만 UIKit 제스처로 처리한다.
                    // 이 오버레이가 블록들 위를 덮기 때문에 블록 자체의 onTapGesture는 더 이상 히트
                    // 테스트에 닿지 않는다 — 탭도 이 오버레이의 UITapGestureRecognizer가 대신 처리한다.
                    .overlay(
                        RescheduleOverlay(
                            onBegin: { x, y in
                                guard let found = block(atX: x, y: y, in: placed) else { return false }
                                activeDrag = ActiveDrag(kind: found, deltaMinutes: 0)
                                return true
                            },
                            onChange: { dy in
                                let rawMinutes = Double(dy) / Double(hourHeight) * 60
                                activeDrag?.deltaMinutes = Int((rawMinutes / 5).rounded()) * 5
                            },
                            onEnd: { committed in
                                guard let drag = activeDrag else { return }
                                activeDrag = nil
                                if committed && drag.deltaMinutes != 0 { finalizeDrag(drag) }
                            },
                            onTap: { x, y in
                                guard let found = block(atX: x, y: y, in: placed) else { return }
                                switch found {
                                case .event(let e): selection = e.id
                                case .activity(let a): selectedActivityId = a.id
                                }
                            }
                        )
                    )
                    #endif
                }
                .frame(height: 24 * hourHeight)
            }
            .frame(height: 24 * hourHeight, alignment: .topLeading)
            .padding([.horizontal, .bottom])

            if dayEvents.isEmpty && dayActivities.isEmpty {
                Text("일정 없음").foregroundStyle(Theme.faint).font(.caption).padding()
            }
        }
        // 블록을 꾹 눌러 드래그하는 동안만 스크롤을 잠가 화면 스크롤과 블록 이동이 서로 방해하지
        // 않게 한다(평소엔 블록 위에서 시작한 스와이프도 정상적으로 화면을 스크롤할 수 있어야 함).
        .scrollDisabled(activeDrag != nil)
    }

    /// 자리가 정해진 블록 하나를 그린다(종류에 맞는 뷰 선택). date는 그리는 날 — 자정을
    /// 넘는 블록의 잘린 범위 계산에 쓰인다.
    @ViewBuilder
    private func blockView(for p: PositionedBlock, on date: Date) -> some View {
        switch p.kind {
        case .activity(let a):
            activityBlockView(a, on: date)
        case .event(let e):
            // 이동시간 계산 실패(API 할당량 소진 등)는 조용히 숨기지 않고 따로 표시한다.
            if e.departureDate != nil { travelBlockView(e, on: date) } else { failedEstimateBlockView(e) }
        }
    }

    /// 드래그 중이면 그만큼(분) 더해 미리보기 위치를 보여준다.
    private func offsetY(for p: PositionedBlock) -> CGFloat {
        let drag: CGFloat
        switch p.kind {
        case .activity(let a): drag = dragOffsetMinutes(forActivity: a.id)
        case .event(let e): drag = dragOffsetMinutes(forEvent: e.id)
        }
        return (p.start + drag) / 60 * hourHeight
    }

    private func minutesSinceMidnight(_ d: Date) -> CGFloat {
        let c = calendar.dateComponents([.hour, .minute], from: d)
        return CGFloat((c.hour ?? 0) * 60 + (c.minute ?? 0))
    }

    /// 블록이 화면에서 실제로 그려지는 최소 높이(분 환산). 이 값보다 짧은 일정도 눈에 보이게
    /// 이만큼은 그리므로, 히트 테스트 범위도 반드시 같은 값을 써야 한다 — 예전엔 렌더와 히트
    /// 테스트가 따로 계산돼 "보이는데 탭이 안 되는" 짧은 블록 문제가 있었다.
    private static let minActivityMinutes: CGFloat = 20
    private static let minTravelMinutes: CGFloat = 16
    /// 이동시간 계산 실패 블록의 고정 높이(pt).
    private static let failedBlockHeight: CGFloat = 20

    /// 일간 시간표에서 블록이 차지하는 세로 범위(자정 기준 분). 렌더링 위치·높이와 히트 테스트가
    /// 반드시 같은 값을 보도록 여기 한 곳에서만 계산한다. 자정을 넘는 블록은 이틀에 나뉘어
    /// 그려지므로 "그리는 날"(on)을 받아 그 날의 0~1440분으로 자른다 — 호출자가 제각각 자르면
    /// 렌더와 히트 테스트가 어긋나는, 이 함수가 원래 하나로 묶으려 했던 문제가 다시 생긴다.
    private func span(for activity: ActivityBlock, on date: Date) -> (start: CGFloat, minutes: CGFloat) {
        // 그리는 날보다 시작이 이르면(전날부터 이어지는 반쪽) 0시부터, 끝이 늦으면 그 날
        // 자정(1440분)까지만 — 그냥 빼면 음수가 나온다.
        let start = calendar.isDate(activity.startDate, inSameDayAs: date)
            ? minutesSinceMidnight(activity.startDate) : 0
        let end = calendar.isDate(activity.endDate, inSameDayAs: date)
            ? minutesSinceMidnight(activity.endDate) : 1440
        // 잘린 반쪽이 최소 높이에 못 미쳐도 늘리는 방향은 그대로 아래로 둔다. 늘리지 않으면 그
        // 조각은 보이지도 탭되지도 않는 블록이 되고(이 값은 렌더와 히트 테스트가 함께 쓴다),
        // 반대 방향(위로)은 자리가 없다 — 자정 직전에 잘린 반쪽이 위로 늘면 그 날의 이웃을 덮고,
        // 0시에 붙어 시작하는 반쪽은 0 위에 그릴 수 없다. 밑으로 넘치는 몇 분은 그 날 화면
        // 밖이라 아무것도 덮지 않는다.
        return (start, max(Self.minActivityMinutes, end - start))
    }

    private func span(for event: ScheduledEvent, on date: Date) -> (start: CGFloat, minutes: CGFloat) {
        guard let dep = event.departureDate else {
            // 이동 시간 계산 실패 블록은 도착 시각에서 "아래로" 고정 높이만큼 그려진다.
            // 실패 블록은 도착일에만 나열되므로 그리는 날이 곧 도착일이다.
            return (minutesSinceMidnight(event.arrivalDate), Self.failedBlockHeight / hourHeight * 60)
        }
        // 출발·도착을 그리는 날의 0~1440분 안으로 자른다 — 전날 밤에 출발해 자정을 넘겨 도착하는
        // 구간은 출발 시각(예: 23:30)을 그대로 쓰면 도착일 화면의 엉뚱한 자리에 그려지므로 도착일
        // 에서는 0시부터, 출발일에서는 자정(1440분)까지. 자정을 넘는 이동이 이틀에 각각 반쪽씩
        // 그려지는 것(결함 G)은 이 자르기와 나열(events(on:)의 겹침 판정)이 함께 완성한다.
        let depMin = calendar.isDate(dep, inSameDayAs: date) ? minutesSinceMidnight(dep) : 0
        let arrivalMin = calendar.isDate(event.arrivalDate, inSameDayAs: date)
            ? minutesSinceMidnight(event.arrivalDate) : 1440
        let natural = arrivalMin - depMin
        guard natural < Self.minTravelMinutes else { return (depMin, natural) }

        // 너무 짧아 최소 높이로 그려야 할 때, **늘어나는 방향은 고정된 쪽의 반대**여야 한다.
        // 도착 기준 구간을 아래로 늘리면 도착 시각에 바로 시작하는 활동 블록을 덮어버린다
        // (도보 1분 거리 식당을 잡았을 때 이동 블록이 식사 블록과 겹쳐 보이던 원인).
        // 잘린 반쪽에도 이 규칙을 그대로 적용한다 — 규칙이 지키려는 것(고정된 끝에 붙어 시작하는
        // 블록을 덮지 않기)은 실제 출발·도착이 붙은 날의 반쪽에서 여전히 옳고, 반쪽끼리만 예외
        // 방향을 만들면 규칙이 둘로 갈라져 어느 쪽이 맞는지 판단이 흐려진다.
        if (event.anchor ?? .arrival) == .departure {
            return (depMin, Self.minTravelMinutes)                                   // 출발 고정 → 아래로
        }
        return (max(0, arrivalMin - Self.minTravelMinutes), Self.minTravelMinutes)    // 도착 고정 → 위로
    }

    /// 드래그 중인 블록이면 그 만큼(분) 임시로 더해 미리보기 위치를 보여준다.
    private func dragOffsetMinutes(forActivity id: ActivityBlock.ID) -> CGFloat {
        guard let drag = activeDrag, case .activity(let a) = drag.kind, a.id == id else { return 0 }
        return CGFloat(drag.deltaMinutes)
    }

    private func dragOffsetMinutes(forEvent id: ScheduledEvent.ID) -> CGFloat {
        guard let drag = activeDrag, case .event(let e) = drag.kind, e.id == id else { return 0 }
        return CGFloat(drag.deltaMinutes)
    }

    private func activityBlockView(_ a: ActivityBlock, on date: Date) -> some View {
        let isDragging = activeDrag?.blockId == "a-\(a.id)"
        let minutes = span(for: a, on: date).minutes
        let past = a.endDate < Date()
        return VStack(alignment: .leading, spacing: 1) {
            Text(a.title).font(.caption).foregroundStyle(Theme.activityInk).lineLimit(1)
            if let loc = a.location, !loc.name.isEmpty, minutes >= 40 {
                // 장소는 블록이 넉넉할 때만 — 짧은 블록에 두 줄을 넣으면 읽히지도 않고 잘린다.
                Text(loc.name).font(.caption2).foregroundStyle(Theme.muted).lineLimit(1)
            }
        }
        .padding(.leading, 9)
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: minutes / 60 * hourHeight, alignment: .topLeading)
        .clipped()   // 짧은 활동에서 글자가 블록 밖으로 새어 나가지 않게
        .blockSurface(fill: Theme.activityFill, rail: Theme.activity, emphasized: isDragging)
        .opacity(past ? 0.45 : 1)   // 지나간 일정은 흐리게 — 남은 일정이 먼저 눈에 들어오도록
        .contentShape(Rectangle())
        // iOS에서는 시간표를 덮는 RescheduleOverlay가 탭을 좌표로 판단해 처리하므로 여기 onTapGesture는
        // 도달하지 않는다(무해한 죽은 코드). macOS에서는 이 탭이 그대로 쓰인다.
        .onTapGesture { selectedActivityId = a.id }
        .scaleEffect(x: 1, y: isDragging ? 1.06 : 1, anchor: .top)
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }

    /// 이동시간을 계산 못한 일정(API 할당량 소진 등)도 조용히 숨기지 않고 표시한다.
    /// iOS에서는 탭을 시간표 전체를 덮는 RescheduleOverlay의 UITapGestureRecognizer가 처리하므로
    /// (그 오버레이가 히트 테스트를 가로채 여기 onTapGesture는 호출되지 않는다) macOS에서만 필요하지만,
    /// 남겨둬도 iOS에서는 그냥 도달하지 않는 죽은 코드일 뿐이라 무해하다.
    private func failedEstimateBlockView(_ event: ScheduledEvent) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
            Text(event.title).font(.caption2).lineLimit(1)
        }
        .foregroundStyle(Theme.warn)
        .padding(.leading, 9)
        .padding(.vertical, 4)
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Self.failedBlockHeight, alignment: .topLeading)
        .clipped()
        .blockSurface(fill: Theme.warnFill, rail: Theme.warn, emphasized: false)
        .contentShape(Rectangle())
        .onTapGesture { selection = event.id }
    }

    private func travelBlockView(_ event: ScheduledEvent, on date: Date) -> some View {
        let isDragging = activeDrag?.blockId == "e-\(event.id)"
        let height = span(for: event, on: date).minutes / 60 * hourHeight
        let past = event.arrivalDate < Date()
        // 활동에 묶인 이동 구간(식당 왕복 등)은 제목을 그리지 않는다 — 대개 도보 몇 분이라
        // 블록이 최소 높이로 그려지는데, 글자가 그 안에 안 들어가 옆 블록 위로 삐져나와 겹쳐 보였다.
        // 바로 옆 활동 블록에 이미 제목이 있어 무엇을 위한 이동인지는 충분히 드러난다.
        let showsTitle = event.linkedActivityId == nil
        // 아이콘조차 들어가지 않을 만큼 낮으면 색 띠만 남긴다.
        let showsIcon = height >= 20
        return HStack(spacing: 4) {
            if showsIcon {
                Image(systemName: event.mode.systemImage).font(.caption2).foregroundStyle(Theme.travel)
            }
            if showsTitle {
                Text(event.title).font(.caption2).foregroundStyle(Theme.travelInk).lineLimit(1)
            }
        }
        .padding(.leading, showsIcon || showsTitle ? 9 : 0)
        .padding(.vertical, showsIcon || showsTitle ? 4 : 0)
        .padding(.trailing, 4)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: height, alignment: .topLeading)
        // 내용이 블록 밖으로 넘쳐 이웃 블록을 덮지 않게 잘라낸다(짧은 블록에서 생기던 문제).
        .clipped()
        .blockSurface(fill: Theme.travelFill, rail: Theme.travel, emphasized: isDragging)
        .opacity(past ? 0.45 : 1)
        .contentShape(Rectangle())
        // iOS에서는 시간표 전체를 덮는 RescheduleOverlay가 탭/드래그 모두 좌표로 판단해 처리하므로
        // 여기 onTapGesture는 도달하지 않는다(무해한 죽은 코드). macOS에서는 이 탭이 그대로 쓰인다.
        .onTapGesture { selection = event.id }
        .scaleEffect(x: 1, y: isDragging ? 1.06 : 1, anchor: .top)
        .animation(.easeOut(duration: 0.15), value: isDragging)
    }


    // MARK: - 겹친 블록 나란히 배치

    /// 화면에 놓일 자리가 정해진 블록. 겹치는 것끼리 가로로 나눠 놓기 위해 열 번호를 함께 갖는다.
    private struct PositionedBlock: Identifiable {
        let id: String
        let kind: ActiveDrag.Kind
        let start: CGFloat      // 자정 기준 분
        let minutes: CGFloat
        let column: Int         // 0부터
        let columns: Int        // 이 블록이 속한 겹침 무리의 열 수
    }

    /// 하루치 블록을 훑어 겹치는 것끼리 열을 나눈다.
    ///
    /// 시간이 겹치는 블록들을 하나의 "무리"로 묶고, 무리 안에서는 먼저 시작한 것부터
    /// **비어 있는 첫 열**에 넣는다. 무리의 열 수만큼 가로를 나눠 쓰므로, 두 개가 겹치면
    /// 반씩, 세 개면 1/3씩 차지한다. 겹치지 않는 블록은 전처럼 가로 전체를 쓴다.
    /// 범위는 그리는 날(on)로 잘라 계산한다 — 자정을 넘는 블록이 이틀에 나열돼도 각 날의
    /// 목록·배치는 서로 별개라 같은 블록이 하루 안에서 두 번 세어질 일은 없다.
    private func positionedBlocks(events dayEvents: [ScheduledEvent],
                                  activities dayActivities: [ActivityBlock],
                                  on date: Date) -> [PositionedBlock] {
        struct Item { let id: String; let kind: ActiveDrag.Kind; let start: CGFloat; let end: CGFloat }
        var items: [Item] = dayActivities.map {
            let s = span(for: $0, on: date)
            return Item(id: "a-\($0.id)", kind: .activity($0), start: s.start, end: s.start + s.minutes)
        }
        items += dayEvents.map {
            let s = span(for: $0, on: date)
            return Item(id: "e-\($0.id)", kind: .event($0), start: s.start, end: s.start + s.minutes)
        }
        items.sort { $0.start == $1.start ? $0.end < $1.end : $0.start < $1.start }

        var out: [PositionedBlock] = []
        var cluster: [(item: Item, column: Int)] = []
        var columnEnds: [CGFloat] = []          // 열별로 현재까지 차 있는 끝 시각

        func flush() {
            let columns = max(1, columnEnds.count)
            for entry in cluster {
                out.append(PositionedBlock(id: entry.item.id, kind: entry.item.kind,
                                           start: entry.item.start,
                                           minutes: entry.item.end - entry.item.start,
                                           column: entry.column, columns: columns))
            }
            cluster.removeAll(); columnEnds.removeAll()
        }

        for item in items {
            // 지금까지의 무리와 전혀 겹치지 않으면(모든 열이 이미 끝났으면) 새 무리를 시작한다.
            if !columnEnds.isEmpty, columnEnds.allSatisfy({ $0 <= item.start }) { flush() }
            // 비어 있는 첫 열을 찾고, 없으면 열을 하나 늘린다.
            if let free = columnEnds.firstIndex(where: { $0 <= item.start }) {
                columnEnds[free] = item.end
                cluster.append((item, free))
            } else {
                columnEnds.append(item.end)
                cluster.append((item, columnEnds.count - 1))
            }
        }
        flush()
        return out
    }

    /// 열 번호에 맞는 가로 위치·폭. `total`은 블록이 놓일 영역 전체 폭.
    private func columnFrame(_ p: PositionedBlock, total: CGFloat) -> (x: CGFloat, width: CGFloat) {
        guard p.columns > 1 else { return (0, total) }
        let gap: CGFloat = 3
        let width = (total - gap * CGFloat(p.columns - 1)) / CGFloat(p.columns)
        return (CGFloat(p.column) * (width + gap), max(width, 1))
    }

    // MARK: - 시간표 재조정: 어느 블록을 눌렀는지 좌표로 찾기

    /// 좌표(세로 y, 가로는 0~1로 정규화한 x)가 어느 블록 위인지 찾는다.
    ///
    /// 겹치는 블록은 가로로 나눠 놓기 때문에 세로만 봐서는 어느 쪽을 눌렀는지 알 수 없다 —
    /// 그려질 때 쓴 열 정보(`positionedBlocks`)를 그대로 써서 가로 범위까지 확인한다.
    /// 여전히 여러 개가 걸리면 지속시간이 가장 짧은(=가장 구체적인) 블록을 고른다.
    private func block(atX x: CGFloat, y: CGFloat, in blocks: [PositionedBlock]) -> ActiveDrag.Kind? {
        let minutes = y / hourHeight * 60
        var best: (duration: CGFloat, kind: ActiveDrag.Kind)?
        for p in blocks {
            guard minutes >= p.start, minutes <= p.start + p.minutes else { continue }
            if p.columns > 1 {
                let slot = 1 / CGFloat(p.columns)
                let lo = CGFloat(p.column) * slot
                guard x >= lo, x <= lo + slot else { continue }
            }
            let duration = max(p.minutes, 1)
            if best == nil || duration < best!.duration { best = (duration, p.kind) }
        }
        return best?.kind
    }

    private func finalizeDrag(_ drag: ActiveDrag) {
        switch drag.kind {
        case .activity(let a):
            if a.recurrenceId != nil {
                pendingMove = PendingMove(message: "'\(a.title)'은(는) 반복 일정입니다. 어떻게 옮길까요?") { whole in
                    store.moveActivity(a, byMinutes: drag.deltaMinutes, wholeSeries: whole)
                }
            } else {
                store.moveActivity(a, byMinutes: drag.deltaMinutes, wholeSeries: false)
            }
        case .event(let e):
            if e.recurrenceId != nil {
                pendingMove = PendingMove(message: "'\(e.title)'은(는) 반복 일정입니다. 어떻게 옮길까요?") { whole in
                    store.adjustTravelLeg(e, byMinutes: drag.deltaMinutes, wholeSeries: whole)
                }
            } else {
                store.adjustTravelLeg(e, byMinutes: drag.deltaMinutes, wholeSeries: false)
            }
        }
    }
}

/// 좌우로 스와이프하면 이전/현재/다음 페이지가 손가락을 따라 함께 움직이는 캐러셀.
/// 임계값 이상 넘기고 놓으면 다음/이전으로 확정되고, 아니면 원래 자리로 되돌아온다.
private struct SwipePager<Content: View>: View {
    @Binding var date: Date
    let step: (Date, Int) -> Date
    /// true면(예: 블록을 드래그하는 중) 페이지 전환 제스처를 잠근다.
    var isLocked: Bool = false
    @ViewBuilder let content: (Date) -> Content

    @State private var dragOffset: CGFloat = 0
    @State private var animated = false

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            HStack(spacing: 0) {
                content(step(date, -1)).frame(width: width, height: geo.size.height, alignment: .top)
                content(date).frame(width: width, height: geo.size.height, alignment: .top)
                content(step(date, 1)).frame(width: width, height: geo.size.height, alignment: .top)
            }
            .offset(x: -width + dragOffset)
            .animation(animated ? .easeOut(duration: 0.25) : nil, value: dragOffset)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        guard !isLocked, abs(value.translation.width) > abs(value.translation.height) else { return }
                        animated = false
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard !isLocked, abs(value.translation.width) > abs(value.translation.height) else {
                            animated = true; dragOffset = 0; return
                        }
                        let threshold = width * 0.22
                        animated = true
                        if value.translation.width < -threshold {
                            dragOffset = -width
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                date = step(date, 1)
                                animated = false
                                dragOffset = 0
                            }
                        } else if value.translation.width > threshold {
                            dragOffset = width
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                date = step(date, -1)
                                animated = false
                                dragOffset = 0
                            }
                        } else {
                            dragOffset = 0
                        }
                    }
            )
        }
    }
}

#if os(iOS)
/// UIScrollView.delaysContentTouches(기본 true)는 스크롤인지 판단될 때까지 콘텐츠 뷰(와 그
/// 제스처 인식기)로의 터치 전달을 지연·취소시킬 수 있다 — 길게 눌러야 하는 드래그(0.35초)는
/// 그 사이 무사히 살아남지만, 짧은 탭은 이 지연 때문에 종종 씹혔다(탭해도 상세정보가 안 뜨던
/// 원인). window에 붙는 시점에 조상 UIScrollView를 찾아 꺼버려 탭이 확실히 전달되게 한다.
private final class ScrollTouchFixView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        var v: UIView? = superview
        while let cur = v {
            if let scroll = cur as? UIScrollView { scroll.delaysContentTouches = false }
            v = cur.superview
        }
    }
}

/// 시간표 전체(ZStack)를 덮는 투명 UIKit 오버레이. 블록을 꾹 눌러 옮기는 드래그와
/// 블록 탭(상세보기)을 여기서 직접 처리한다.
///
/// SwiftUI의 `.simultaneousGesture`는 ScrollView 내부 UIPanGestureRecognizer와 진짜
/// UIKit 레벨 동시 인식(shouldRecognizeSimultaneouslyWith)을 보장하지 않아, 블록 위에서
/// 시작한 스크롤이 계속 막히고 탭도 씹혔다(여러 라운드에 걸쳐 확인됨). UIKit
/// UIGestureRecognizerDelegate로 이 값을 직접 true로 선언하면 ScrollView의 팬 제스처와
/// 나란히 인식되게 만들 수 있다 — 이 오버레이가 아무 처리도 안 하기로 한 터치(빈 공간,
/// 짧은 탭, 짧은 스크롤)는 그냥 실패시켜 스크롤/탭이 정상 동작하도록 양보한다.
///
/// 이 오버레이가 블록들 위에 얹혀 히트 테스트를 가로채므로, 블록 자신의 onTapGesture는
/// 더 이상 호출되지 않는다 — 탭 판정도 이 뷰의 UITapGestureRecognizer가 좌표로 대신한다.
private struct RescheduleOverlay: UIViewRepresentable {
    /// 꾹 눌러 0.35초 유지된 시점의 좌표(가로는 0~1로 정규화, 세로는 pt).
    /// 블록 위가 아니면 false를 반환해 즉시 포기한다(스크롤/탭에 양보 — activeDrag를 절대 세우지 않는다).
    let onBegin: (CGFloat, CGFloat) -> Bool
    /// 드래그 중 시작 y좌표 대비 이동량(pt, 부호 있음).
    let onChange: (CGFloat) -> Void
    /// 손을 뗐을 때: true면 커밋(실제로 옮김), false면 취소(꾹 누르기가 중간에 실패/취소됨).
    let onEnd: (Bool) -> Void
    /// 짧은 탭이 끝난 시점의 좌표(가로 0~1 정규화, 세로 pt).
    let onTap: (CGFloat, CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegin: onBegin, onChange: onChange, onEnd: onEnd, onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = ScrollTouchFixView()
        view.backgroundColor = .clear
        view.isOpaque = false

        let longPress = UILongPressGestureRecognizer(target: context.coordinator,
                                                       action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        longPress.delegate = context.coordinator
        view.addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                          action: #selector(Coordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onBegin = onBegin
        context.coordinator.onChange = onChange
        context.coordinator.onEnd = onEnd
        context.coordinator.onTap = onTap
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onBegin: (CGFloat, CGFloat) -> Bool
        var onChange: (CGFloat) -> Void
        var onEnd: (Bool) -> Void
        var onTap: (CGFloat, CGFloat) -> Void

        private var startY: CGFloat = 0
        private var didBegin = false

        init(onBegin: @escaping (CGFloat, CGFloat) -> Bool, onChange: @escaping (CGFloat) -> Void,
             onEnd: @escaping (Bool) -> Void, onTap: @escaping (CGFloat, CGFloat) -> Void) {
            self.onBegin = onBegin; self.onChange = onChange; self.onEnd = onEnd; self.onTap = onTap
        }

        /// 가로 좌표를 0~1로 바꾼다(겹친 블록이 좌우로 나뉘어 있어 어느 열인지 판단해야 한다).
        private func normalizedX(_ gr: UIGestureRecognizer) -> CGFloat {
            let width = gr.view?.bounds.width ?? 1
            return width > 0 ? min(max(gr.location(in: gr.view).x / width, 0), 1) : 0
        }

        @objc func handleLongPress(_ gr: UILongPressGestureRecognizer) {
            let y = gr.location(in: gr.view).y
            switch gr.state {
            case .began:
                startY = y
                didBegin = onBegin(normalizedX(gr), y)
                if !didBegin { gr.state = .cancelled }
            case .changed:
                guard didBegin else { return }
                onChange(y - startY)
            case .ended:
                if didBegin { onEnd(true) }
                didBegin = false
            case .cancelled, .failed:
                if didBegin { onEnd(false) }
                didBegin = false
            default:
                break
            }
        }

        @objc func handleTap(_ gr: UITapGestureRecognizer) {
            guard gr.state == .ended else { return }
            onTap(normalizedX(gr), gr.location(in: gr.view).y)
        }

        // ScrollView의 내부 팬 제스처·이 뷰의 롱프레스/탭 서로가 동시에 인식되도록 허용한다.
        // 기본값(false)이면 UIKit이 하나만 골라 스크롤이나 탭이 막힌다.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
#endif
