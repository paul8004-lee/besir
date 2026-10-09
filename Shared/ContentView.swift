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
        /// 구간 드래그가 시작될 때 onBegin이 한 번 구해 둔 소유 활동(REQ-009). 드래그 중에는
        /// span·도우미·onChange 어디서도 다시 조회하지 않는다 — 중간에 값이 어긋나면 미리보기와
        /// 드롭이 다른 블록을 움직인다. 활동 드래그와 소유 없는 구간 드래그는 nil.
        var owner: ActivityBlock? = nil
        /// 드래그가 시작된 페이지 날짜 — 하루 연장(dayLimitMinutes)과 자동 스크롤이 이 날에만
        /// 붙는다(REQ-015 "끄는 동안"의 연장은 시작한 페이지의 것이고 다른 페이지는 그대로).
        var pageDate: Date = Date()
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
    /// 저녁 구간이 통째로 그려지지 않는다. 어느 날에 나열되는지의 판정은 `isListed(on:calendar:)`
    /// (Models.swift) 한 곳에서 낸다 — 월간·주간 점(daysWithSchedule)도 같은 판정으로 켜지므로
    /// 같은 앱이 같은 날에 대해 다른 말을 하지 않게(계약 5). 이동시간 미계산 구간은 앵커 시각이
    /// 든 날 하루에만 나열된다(REQ-023 — 경고 블록이 날짜로 잘리지 않는 것과 세트).
    private func events(on date: Date) -> [ScheduledEvent] {
        store.events.filter { $0.isListed(on: date, calendar: calendar) }
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
        // 하루 길이는 하루 한계 도우미 하나가 낸다(REQ-015) — 소유 구간을 끄는 중 시작 페이지는
        // 24시 아래로 늘어나고, 눈금·구분선·콘텐츠 높이·두 span의 자르기가 전부 이 값을 읽는다.
        let hourCount = dayLimitMinutes(on: date) / 60
        return ScrollView {
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 0) {
                    // Array로 싸는 것은 칸 수가 드래그 중 24보다 커질 수 있기 때문 — 리터럴 범위
                    // ForEach는 상수 전용이라 연장이 붙는 순간 경고·재생성 문제를 낸다.
                    ForEach(Array(0..<hourCount), id: \.self) { h in
                        // 24시 위로는 "다음 날 00"처럼 조용히(같은 Theme.faint, 글자만 알려준다).
                        Text(h < 24 ? String(format: "%02d", h) : String(format: "다음 날 %02d", h - 24))
                            .font(.caption2).foregroundStyle(Theme.faint)
                            .lineLimit(1).minimumScaleFactor(0.6)
                            .frame(width: 28, height: hourHeight, alignment: .top)
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(Array(0..<hourCount), id: \.self) { _ in
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
                                guard let found = block(atX: x, y: y, in: placed, total: geo.size.width) else { return false }
                                // 소유 조회는 드래그 시작 때 이 한 번뿐이다(REQ-009·AC-007) — 이후
                                // span·도우미·onChange가 다시 찾으면 드래그 중 회차가 어긋날 때
                                // 미리보기와 드롭이 다른 활동을 움직인다. 활동 드래그는 소유가 없다.
                                let owner: ActivityBlock?
                                if case .event(let e) = found { owner = store.owningActivity(of: e) } else { owner = nil }
                                activeDrag = ActiveDrag(kind: found, deltaMinutes: 0, owner: owner, pageDate: date)
                                return true
                            },
                            onChange: { dy in
                                let rawMinutes = Double(dy) / Double(hourHeight) * 60
                                var requested = Int((rawMinutes / Double(Store.dragSnapStepMinutes)).rounded()) * Store.dragSnapStepMinutes
                                // 소유 있는 구간은 요청 Δ를 그대로 쓰지 않고 Store 한계 함수의 유효 Δ를
                                // 쓴다(REQ-008) — 미리보기(두 span)와 드롭(adjustTravelLeg)이 같은 값을
                                // 읽게 하는 단일 출처다. 소유 없는 구간은 오늘처럼 요청값을 그대로 둔다.
                                if let drag = activeDrag, let owner = drag.owner, case .event(let leg) = drag.kind {
                                    requested = store.effectiveDragMinutes(leg: leg, owner: owner, requestedMinutes: requested)
                                }
                                activeDrag?.deltaMinutes = requested
                            },
                            onEnd: { committed in
                                guard let drag = activeDrag else { return }
                                activeDrag = nil
                                if committed && drag.deltaMinutes != 0 { finalizeDrag(drag) }
                            },
                            onTap: { x, y in
                                guard let found = block(atX: x, y: y, in: placed, total: geo.size.width) else { return }
                                switch found {
                                case .event(let e): selection = e.id
                                case .activity(let a): selectedActivityId = a.id
                                }
                            },
                            // 가장자리 자동 스크롤·하루 연장은 소유 있는 구간 드래그에만 붙는다(Q-9).
                            autoScrollEligible: { activeDrag?.owner != nil },
                            panLockFallback: Self.usesPanLockFallbackForOwnedLegDrag
                        )
                    )
                    #endif
                }
                .frame(height: CGFloat(hourCount) * hourHeight)
            }
            .frame(height: CGFloat(hourCount) * hourHeight, alignment: .topLeading)
            .padding([.horizontal, .bottom])

            if dayEvents.isEmpty && dayActivities.isEmpty {
                Text("일정 없음").foregroundStyle(Theme.faint).font(.caption).padding()
            }
        }
        // 블록을 꾹 눌러 드래그하는 동안만 스크롤을 잠가 화면 스크롤과 블록 이동이 서로 방해하지
        // 않게 한다(평소엔 블록 위에서 시작한 스와이프도 정상적으로 화면을 스크롤할 수 있어야 함).
        // 대체안(usesPanLockFallbackForOwnedLegDrag)에서는 소유 있는 구간 드래그만 이 잠금 대신
        // 스크롤 뷰의 팬 인식기를 끈다 — 활동·소유 없는 구간 드래그는 어느 쪽에서나 잠긴 채(spec §3).
        .scrollDisabled(scrollLockedDuringDrag)
    }

    /// 드래그 중 스크롤 잠금 여부 — 본안에서는 드래그 중 항상 참, 대체안에서는 소유 있는 구간
    /// 드래그만 거짓(팬 인식기 끄기가 대신한다, D-11).
    private var scrollLockedDuringDrag: Bool {
        guard let drag = activeDrag else { return false }
        if Self.usesPanLockFallbackForOwnedLegDrag && drag.owner != nil { return false }
        return true
    }

    /// D-11 대체안 스위치. true는 2026-10-08 t51의 선택 — 운영자가 S-6·S-16·S-17에서 본안
    /// (.scrollDisabled)일 때 자동 스크롤이 시간표를 움직이지 않는 것을 관측했다. 팬 끄기가
    /// 프로그램 오프셋을 살리는지는 운영자 재확인(S-6·S-16·S-17)이 판정한다.
    private static let usesPanLockFallbackForOwnedLegDrag = true

    /// 자리가 정해진 블록 하나를 그린다(종류에 맞는 뷰 선택). date는 그리는 날 — 자정을
    /// 넘는 블록의 잘린 범위 계산에 쓰인다.
    @ViewBuilder
    private func blockView(for p: PositionedBlock, on date: Date) -> some View {
        switch p.kind {
        case .activity(let a):
            activityBlockView(a, on: date)
        case .event(let e):
            // 이동시간 계산 실패(API 할당량 소진 등)는 조용히 숨기지 않고 따로 표시한다.
            // 판정은 앵커 함수 하나가 낸다(REQ-023) — 출발 기준인데 출발만 저장된 모양(재추정 실패의
            // 옛 도착·새로 만든 출발=도착)도 경고 블록이 되고, 레코드 생김새를 여기서 다시 해석하지 않는다.
            // 경고 블록의 세로 자리(앵커 분에서 아래로)는 span(for:on:)의 실패 분기가 낸다.
            if e.failedBlockAnchor != nil { failedEstimateBlockView(e) } else { travelBlockView(e, on: date) }
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
    /// 테스트가 따로 계산돼 "보이는데 탭이 안 되는" 짧은 블록 문제가 있었다. 5분은 드래그가 만들
    /// 수 있는 가장 짧은 활동(REQ-006)과 같은 값이지만 그리기 전용이다 — Store 상수와 하나로
    /// 묶으면 화면 상수가 Store 격리를 끌어당긴다. 5분 이상 활동은 모두 실제 길이로 그려진다.
    private static let minActivityMinutes: CGFloat = 5
    private static let minTravelMinutes: CGFloat = 16
    /// 이동시간 계산 실패 블록의 고정 높이(pt).
    private static let failedBlockHeight: CGFloat = 20
    /// 같은 줄에 놓인 블록 사이 간격(pt) — 칸 경계에만 들어가고 묶음 안쪽 나눔에는 안 들어간다.
    /// 렌더와 히트테스트가 같은 값을 쓰는지는 `SlotRange.points`가 보증한다.
    private static let columnGap: CGFloat = 3

    /// 소유 있는 구간 드래그의 이동량(유효 Δ, 분)을 한 곳에서 낸다(REQ-009 — 미리보기 = 확정).
    /// 끌리는 구간 자신(legId)과 그 소유 활동(activityId)에만 Δ를 돌려주고 다른 모든 블록은
    /// 0이다 — 두 span이 이 값으로 옮긴 범위를 만들고 dragOffsetMinutes는 소유 있는 끌림 구간의
    /// 평행이동을 이 값으로 걷는다(같은 블록이 두 번 움직이지 않게). 소유 조회는 onBegin이 이미
    /// 끝냈다 — 여기서 다시 찾지 않는다(AC-007).
    private func legDragShift(legId: ScheduledEvent.ID? = nil, activityId: ActivityBlock.ID? = nil) -> Int {
        guard let drag = activeDrag, let owner = drag.owner, case .event(let e) = drag.kind else { return 0 }
        if legId == e.id || activityId == owner.id { return drag.deltaMinutes }
        return 0
    }

    /// 그리는 날의 하루 한계(분). 평소 1440이고, 소유 있는 구간을 끄는 중에는 그 드래그가 시작된
    /// 페이지에서만 아래로 늘어난다(REQ-015 (1)) — 늘어나는 양은 드래그가 움직이는 끝(끌린 구간의
    /// 더 늦은 쪽 끝, 소유 활동의 끌리는 쪽 가장자리)이 그 날 24시를 넘는 초과분을 시간으로 올림한
    /// 값이다. 드래그가 움직이지 않는 끝은 이미 자정을 넘어 있어도 연장하지 않는다(N5-5). 드래그가
    /// 끝나면(activeDrag == nil) 상태가 이끄는 대로 1440로 돌아가고, 다른 페이지는 언제나 1440이다.
    /// @MX:NOTE 하루 길이의 단일 출처 — 눈금·구분선·콘텐츠 높이·두 span의 자르기·히트 테스트가
    /// 모두 이 값을 읽는다. 여기서 따로 세면 연장 중 렌더와 히트가 어긋난다(계약 5).
    private func dayLimitMinutes(on date: Date) -> Int {
        guard let drag = activeDrag, let owner = drag.owner,
              case .event(let leg) = drag.kind,
              calendar.isDate(drag.pageDate, inSameDayAs: date) else { return 1440 }
        let delta = TimeInterval(drag.deltaMinutes) * 60
        let dayEnd = calendar.startOfDay(for: date).addingTimeInterval(24 * 3600)
        let laterLegEnd = max(leg.departureDate ?? leg.arrivalDate, leg.arrivalDate).addingTimeInterval(delta)
        let ownerDraggedEdge = ((leg.anchor ?? .arrival) == .departure ? owner.endDate : owner.startDate)
            .addingTimeInterval(delta)
        let excess = max(0, laterLegEnd.timeIntervalSince(dayEnd), ownerDraggedEdge.timeIntervalSince(dayEnd))
        return 1440 + Int(ceil(excess / 3600)) * 60
    }

    /// 일간 시간표에서 블록이 차지하는 세로 범위(자정 기준 분). 렌더링 위치·높이와 히트 테스트가
    /// 반드시 같은 값을 보도록 여기 한 곳에서만 계산한다. 자정을 넘는 블록은 이틀에 나뉘어
    /// 그려지므로 "그리는 날"(on)을 받아 그 날의 0시~하루 한계분으로 자른다 — 호출자가 제각각
    /// 자르면 렌더와 히트 테스트가 어긋나는, 이 함수가 원래 하나로 묶으려 했던 문제가 다시 생긴다.
    private func span(for activity: ActivityBlock, on date: Date) -> (start: CGFloat, minutes: CGFloat) {
        // 소유 활동이 끌리는 중에는 먼저 옮긴 시각을 만든다 — 오는 편 드래그는 활동 끝이, 가는 편
        // 드래그는 활동 시작이 유효 Δ만큼 움직이고 반대쪽은 그대로(REQ-001·002와 같은 방향 —
        // 미리보기가 곧 확정값이므로 드래그 중에도 확정과 같은 모양으로 그린다).
        var startDate = activity.startDate
        var endDate = activity.endDate
        let shift = legDragShift(activityId: activity.id)
        if shift != 0, case .event(let leg)? = activeDrag?.kind {
            let delta = TimeInterval(shift) * 60
            if (leg.anchor ?? .arrival) == .departure {
                endDate = endDate.addingTimeInterval(delta)      // 오는 편 → 끝을 늘린다
            } else {
                startDate = startDate.addingTimeInterval(delta)  // 가는 편 → 시작을 민다
            }
        }
        let dayStart = calendar.startOfDay(for: date)
        let clippedStart = max(startDate, dayStart)
        let clippedEnd = min(endDate, dayStart.addingTimeInterval(TimeInterval(dayLimitMinutes(on: date)) * 60))
        // 옮긴 범위가 그 날에 남지 않으면 (start, 0)을 돌려 positionedBlocks가 건너뛰게 한다(REQ-009)
        // — 최소 높이로 늘려 그리면 하루 끝에 없는 토막이 생긴다. 저장된 블록(나열 판정이 그 날과
        // 겹침을 보장)과 시작 = 끝인 깨진 레코드는 이 갈래에 오지 않고 오늘처럼 최소 높이로 그린다.
        guard clippedEnd > clippedStart else {
            if shift != 0 { return (0, 0) }
            let s = calendar.isDate(activity.startDate, inSameDayAs: date) ? minutesSinceMidnight(activity.startDate) : 0
            return (s, Self.minActivityMinutes)
        }
        // 잘린 반쪽이 최소 높이에 못 미쳐도 늘리는 방향은 그대로 아래로 둔다. 늘리지 않으면 그
        // 조각은 보이지도 탭되지도 않는 블록이 되고(이 값은 렌더와 히트 테스트가 함께 쓴다),
        // 반대 방향(위로)은 자리가 없다 — 자정 직전에 잘린 반쪽이 위로 늘면 그 날의 이웃을 덮고,
        // 0시에 붙어 시작하는 반쪽은 0 위에 그릴 수 없다. 밑으로 넘치는 몇 분은 그 날 화면
        // 밖이라 아무것도 덮지 않는다.
        // 분 단위로 자른다(초는 내린다) — 외부 가져오기·AI가 만든 시각은 초가 0이 아닐 수 있는데,
        // 초까지 반영하면 10:00:30~11:00:30 활동과 11:00:30 복귀 다리가 반쪽 폭으로 갈라진다.
        // b59fcaa 기준선의 minutesSinceMidnight(시*60+분, 초 버림)와 같은 의미이며 초가 0이면
        // 내림이 항등이므로 기존 그림은 바이트 단위로 그대로다.
        let start = CGFloat((clippedStart.timeIntervalSince(dayStart) / 60).rounded(.down))
        let end = CGFloat((clippedEnd.timeIntervalSince(dayStart) / 60).rounded(.down))
        return (start, max(Self.minActivityMinutes, end - start))
    }

    private func span(for event: ScheduledEvent, on date: Date) -> (start: CGFloat, minutes: CGFloat) {
        let dayStart = calendar.startOfDay(for: date)
        let limit = CGFloat(dayLimitMinutes(on: date))
        // 끌리는 소유 구간은 시각에 유효 Δ를 더해 옮긴 뒤 그 날의 0~하루 한계 안에서 그린다(REQ-009)
        // — 평행이동 미리보기(dragOffsetMinutes)를 겹쳐 쓰지 않는다. 옮긴 범위가 그 날에 남지
        // 않으면 (start, 0)을 돌려 positionedBlocks가 건너뛰게 한다 — 연장 밖이나 하루 시작 앞에
        // 토막을 그리면 놓을 자리를 잘못 읽게 한다.
        let shift = legDragShift(legId: event.id)
        if shift != 0 {
            let delta = TimeInterval(shift) * 60
            // 경고 블록(미계산)은 나열 시각 = 앵커 하나만 옮겨 그린다 — 한계 함수도 그 시각
            // 하나로 자르므로 그림도 같은 시각을 따라간다.
            if let anchor = event.failedBlockAnchor {
                let m = CGFloat(anchor.addingTimeInterval(delta).timeIntervalSince(dayStart) / 60)
                guard m >= 0, m < limit else { return (0, 0) }
                return (m, Self.failedBlockHeight / hourHeight * 60)
            }
            guard let dep = event.departureDate else {
                let m = CGFloat(event.arrivalDate.addingTimeInterval(delta).timeIntervalSince(dayStart) / 60)
                guard m >= 0, m < limit else { return (0, 0) }
                return (m, Self.failedBlockHeight / hourHeight * 60)
            }
            let depMin = min(max(CGFloat(dep.addingTimeInterval(delta).timeIntervalSince(dayStart) / 60), 0), limit)
            let arrivalMin = min(max(CGFloat(event.arrivalDate.addingTimeInterval(delta).timeIntervalSince(dayStart) / 60), 0), limit)
            guard arrivalMin > depMin else { return (0, 0) }
            let natural = arrivalMin - depMin
            guard natural < Self.minTravelMinutes else { return (depMin, natural) }
            // 최소 높이로 늘리는 방향은 고정된 쪽의 반대 — 아래 저장된 구간의 규칙과 같다.
            if (event.anchor ?? .arrival) == .departure {
                return (depMin, Self.minTravelMinutes)                                   // 출발 고정 → 아래로
            }
            return (max(0, arrivalMin - Self.minTravelMinutes), Self.minTravelMinutes)    // 도착 고정 → 위로
        }
        // 이하는 저장된 구간 — 지금의 자르기에서 하루 끝 값만 하루 한계 도우미로 바뀐다.
        // 이동시간 미계산 구간은 경고 블록 하나 — 앵커 시각(REQ-023의 A)의 분에서 "아래로" 고정
        // 높이만큼 그린다. **날짜로 자르지 않는다**: 미계산 구간은 앵커가 든 날 하루에만 나열되므로
        // 자르기가 필요 없고, 앵커가 자정 직전이면 블록 끝이 그 날 화면 아래 밖으로 몇 분 넘치는
        // 것은 계산된 구간의 아래 넘침과 같은 규칙이다(위 활동 span 주석). 출발 기준의 옛 도착
        // (재추정 실패 모양)은 앵커가 아니므로 여기 오지 않는다.
        if let anchor = event.failedBlockAnchor {
            return (minutesSinceMidnight(anchor), Self.failedBlockHeight / hourHeight * 60)
        }
        guard let dep = event.departureDate else {
            // 여기 오는 건 이동시간은 계산됐는데 출발이 없는 깨진 레코드뿐이다(nil을 만드는 곳은
            // travelSeconds도 같이 비운다). 도착 시각에서 아래로 그려 옛 경고 모양으로 폴백한다.
            return (minutesSinceMidnight(event.arrivalDate), Self.failedBlockHeight / hourHeight * 60)
        }
        // 출발·도착을 그리는 날의 0~하루 한계분 안으로 자른다 — 전날 밤에 출발해 자정을 넘겨 도착하는
        // 구간은 출발 시각(예: 23:30)을 그대로 쓰면 도착일 화면의 엉뚱한 자리에 그려지므로 도착일
        // 에서는 0시부터, 출발일에서는 그 날 끝까지. 자정을 넘는 이동이 이틀에 각각 반쪽씩
        // 그려지는 것(결함 G)은 이 자르기와 나열(events(on:)의 겹침 판정)이 함께 완성한다.
        let depMin = calendar.isDate(dep, inSameDayAs: date) ? minutesSinceMidnight(dep) : 0
        let arrivalMin = calendar.isDate(event.arrivalDate, inSameDayAs: date)
            ? minutesSinceMidnight(event.arrivalDate) : limit
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
        // 소유 있는 구간의 미리보기는 span이 옮긴 범위로 이미 그린다(legDragShift가 Δ를 주는
        // 블록) — 여기서 또 평행이동하면 같은 블록이 두 번 움직인다(REQ-009). 소유 없는 구간은
        // 오늘처럼 평행이동 미리보기를 쓴다.
        if legDragShift(legId: id) != 0 { return 0 }
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
        // 링크가 **살아 있는지**는 조회로 본다(AC-005 (3)) — linkedActivityId만 보면 활동이 지워진
        // 매달린 링크가 연결된 것처럼 제목을 숨긴다.
        let showsTitle = store.activity(forLeg: event) == nil
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

    /// 화면에 놓일 자리가 정해진 블록. 가로 범위는 칸 함수가 낸 [lo, hi]를 통째로 든다 —
    /// 렌더(columnFrame)와 히트테스트(block(atX:))가 이 값을 그대로 읽는다(AC-016).
    private struct PositionedBlock: Identifiable {
        let id: String
        let kind: ActiveDrag.Kind
        let start: CGFloat      // 자정 기준 분
        let minutes: CGFloat
        let range: ScheduleLogic.SlotRange
    }

    /// 하루치 블록을 겹침·묶음 배치로 자리 정한다.
    ///
    /// 배치 산술 전부는 `ScheduleLogic.overlapSlots`(Models.swift)이 한다 — 뷰가 칸 계산을
    /// 따로 들고 있으면 렌더와 히트테스트가 어긋난다(AC-016). 여기는 레코드를 (id, start, end)로
    /// 펴서 넣고 결과를 다시 블록으로 매핑하기만 한다. 범위는 그리는 날(on)로 잘라 계산한다 —
    /// 자정을 넘는 블록이 이틀에 나열돼도 각 날의 목록·배치는 서로 별개라 같은 블록이 하루 안에서
    /// 두 번 세어질 일은 없다. 묶음 키는 여기서 주입한다(REQ-015): 활동은 자기 id, 구간은
    /// `packingGroups`가 대응시켜 준 활동 id, 대응이 없으면 nil(단독 이동·매달린 링크).
    private func positionedBlocks(events dayEvents: [ScheduledEvent],
                                  activities dayActivities: [ActivityBlock],
                                  on date: Date) -> [PositionedBlock] {
        let groups = store.packingGroups(events: dayEvents, activities: dayActivities)
        struct Item { let id: String; let kind: ActiveDrag.Kind; let start: CGFloat; let end: CGFloat; let key: String? }
        // 옮긴 범위가 그 날에 남지 않은 블록(span이 minutes 0을 돌려준 것)은 여기서 뺀다 — 렌더와
        // 히트 테스트가 같은 목록을 보므로 그려지지도 눌리지도 않는다(REQ-009). 저장된 블록은
        // 나열 판정이 그 날과의 겹침을 보장하므로 이 갈래에 오지 않는다.
        var items: [Item] = dayActivities.compactMap {
            let s = span(for: $0, on: date)
            guard s.minutes > 0 else { return nil }
            return Item(id: "a-\($0.id)", kind: .activity($0), start: s.start, end: s.start + s.minutes,
                        key: $0.id.uuidString)
        }
        items += dayEvents.compactMap {
            let s = span(for: $0, on: date)
            guard s.minutes > 0 else { return nil }
            return Item(id: "e-\($0.id)", kind: .event($0), start: s.start, end: s.start + s.minutes,
                        key: groups[$0.id]?.uuidString)
        }
        let byID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return ScheduleLogic.overlapSlots(items.map {
            ScheduleLogic.LayoutItem(id: $0.id, start: $0.start, end: $0.end, groupKey: $0.key)
        }).compactMap { range -> PositionedBlock? in
            guard let it = byID[range.id] else { return nil }
            return PositionedBlock(id: it.id, kind: it.kind, start: it.start,
                                   minutes: it.end - it.start, range: range)
        }
    }

    /// 칸 범위 [lo, hi]에 맞는 가로 위치·폭. `total`은 블록이 놓일 영역 전체 폭 — 점 환산(간격
    /// 포함)은 `SlotRange.points`가 하므로 여기엔 칸 산술이 없다(AC-016).
    private func columnFrame(_ p: PositionedBlock, total: CGFloat) -> (x: CGFloat, width: CGFloat) {
        let f = p.range.points(in: total, gap: Self.columnGap)
        return (f.x, max(f.width, 1))
    }

    // MARK: - 시간표 재조정: 어느 블록을 눌렀는지 좌표로 찾기

    /// 좌표(세로 y pt, 가로는 정규화 x에 `total`을 곱한 점)가 어느 블록 위인지 찾는다.
    ///
    /// 겹치는 블록은 가로로 나눠 놓기 때문에 세로만 봐서는 어느 쪽을 눌렀는지 알 수 없다 —
    /// 가로 판정은 **렌더와 같은 점 사각형**(`SlotRange.points`, 칸 경계 간격 포함)으로 한다.
    /// 예전엔 히트가 칸 비율만 봐 렌더의 3pt 간격과 어긋났다(F9). 간격 3pt 자체는 어느 블록도
    /// 아니므로 그 안의 탭은 빈 곳으로 양보된다(잘못된 블록이 열리는 것보다 낫다 — 렌더와
    /// 히트가 같은 사각형을 쓰는 것 자체가 계약이다, AC-016).
    /// 여전히 여러 개가 걸리면 지속시간이 가장 짧은(=가장 구체적인) 블록을 고른다.
    private func block(atX x: CGFloat, y: CGFloat, in blocks: [PositionedBlock], total: CGFloat) -> ActiveDrag.Kind? {
        let px = x * total
        let minutes = y / hourHeight * 60
        var best: (duration: CGFloat, kind: ActiveDrag.Kind)?
        for p in blocks {
            guard minutes >= p.start, minutes <= p.start + p.minutes else { continue }
            let f = p.range.points(in: total, gap: Self.columnGap)
            guard px >= f.x, px <= f.x + f.width else { continue }
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
                            commitPage(delta: 1)
                        } else if value.translation.width > threshold {
                            dragOffset = width
                            commitPage(delta: -1)
                        } else {
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    /// 임계치를 넘긴 스와이프의 확정(가설 기반 방어 — t60). 세 쓰기(부모 date, animated,
    /// dragOffset)를 한 트랜잭션에 애니메이션 없이 묶는다. 낱개 쓰기면 0.25초 이징이 아직
    /// 붙어 있는 사이(커밋은 0.22초에 발사) 갱신 경계를 넘으며 하위트리 일부(주간 스트립·시트
    /// 제시)만 낡은 상태에 남는다는 **가설**이다 — 시뮬레이터에서 무계측 빌드로만 재현(2/16,
    /// 간헐)됐고 원인은 미확정, 수리 효과도 증명 전이다(t60 progress.md §2·운영자 실기기
    /// 확인 대기). 같은 페이지 자리를 위치 기준으로 재사용하는 페이저라 어질러도 화면이
    /// 멀쩡해 보여 조용히 남는다.
    private func commitPage(delta: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                date = step(date, delta)
                animated = false
                dragOffset = 0
            }
        }
    }
}

#if os(iOS)
/// UIScrollView.delaysContentTouches(기본 true)는 스크롤인지 판단될 때까지 콘텐츠 뷰(와 그
/// 제스처 인식기)로의 터치 전달을 지연·취소시킬 수 있다 — 길게 눌러야 하는 드래그(0.35초)는
/// 그 사이 무사히 살아남지만, 짧은 탭은 이 지연 때문에 종종 씹혔다(탭해도 상세정보가 안 뜨던
/// 원인). window에 붙는 시점에 조상 UIScrollView를 찾아 꺼버려 탭이 확실히 전달되게 한다.
private final class ScrollTouchFixView: UIView {
    /// 창에서 빠질 때의 알림 — 자동 스크롤 타이머가 살아 있으면 여기서 멈춘다(AC-016 끝 경로:
    /// 앱 내리기 등으로 오버레이가 창에서 떨어져도 .cancelled가 오지 않을 수 있다).
    var onLeaveWindow: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            onLeaveWindow?()
            return
        }
        var v: UIView? = superview
        while let cur = v {
            if let scroll = cur as? UIScrollView { scroll.delaysContentTouches = false }
            v = cur.superview
        }
    }
}

/// CADisplayLink는 대상을 retain한다(공식 문서 "The newly constructed display link retains the
/// target") — 코디네이터를 직접 대상으로 두면 무효화 전까지 링과 코디네이터가 서로 붙잡는다.
/// 약한 참조 대리를 대상으로 두고 틱마다 코디네이터를 다시 잡게 한다(D-11).
private final class AutoScrollProxy: NSObject {
    weak var target: RescheduleOverlay.Coordinator?
    @objc func tick(_ link: CADisplayLink) {
        // 코디네이터가 stopAutoScroll 없이 사라지면 링은 proxy만 붙잡은 채 프레임마다
        // 헛돈다 — 대상이 없을 때는 여기서 직접 끊는다.
        guard let target else { link.invalidate(); return }
        target.autoScrollTick(link)
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
    /// 가장자리 자동 스크롤을 켜도 되는지(= 소유 활동이 있는 구간 드래그 중인지). 드래그가
    /// 시작된 뒤에야 답이 정해지므로 매 순간의 상태를 읽는 클로저로 받는다(Q-9 — 활동 드래그와
    /// 소유 없는 구간 드래그는 자동 스크롤·연장을 하지 않는다).
    let autoScrollEligible: () -> Bool
    /// D-11 대체안 스위치 — true면 소유 구간 드래그에서 scrollDisabled 대신 스크롤 뷰의 팬
    /// 인식기를 끈다. 기본값은 ContentView의 상수가 정한다.
    let panLockFallback: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegin: onBegin, onChange: onChange, onEnd: onEnd, onTap: onTap,
                    autoScrollEligible: autoScrollEligible, panLockFallback: panLockFallback)
    }

    func makeUIView(context: Context) -> UIView {
        let view = ScrollTouchFixView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.onLeaveWindow = { [weak coordinator = context.coordinator] in coordinator?.stopAutoScroll() }

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

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // SwiftUI가 오버레이를 조용히 치우는 경로도 끝 경로다 — 타이머가 남으면 뷰가 없는 데도
        // 스크롤을 돌린다(AC-016).
        coordinator.stopAutoScroll()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onBegin = onBegin
        context.coordinator.onChange = onChange
        context.coordinator.onEnd = onEnd
        context.coordinator.onTap = onTap
        context.coordinator.autoScrollEligible = autoScrollEligible
        context.coordinator.panLockFallback = panLockFallback
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onBegin: (CGFloat, CGFloat) -> Bool
        var onChange: (CGFloat) -> Void
        var onEnd: (Bool) -> Void
        var onTap: (CGFloat, CGFloat) -> Void
        var autoScrollEligible: () -> Bool
        var panLockFallback: Bool

        private var startY: CGFloat = 0
        private var didBegin = false

        // 자동 스크롤 상태 — 링 하나, 인식기 하나, 시작할 때 찾아 둔 스크롤 뷰 하나뿐이다.
        private var displayLink: CADisplayLink?
        private var activeRecognizer: UILongPressGestureRecognizer?
        private var dragScrollView: UIScrollView?
        private var lastTick: CFTimeInterval = 0
        private var scrolledDown = false
        private var panWasDisabled = false

        /// 매김값(D-11 〔제안〕 — 시뮬레이터 S-16이 감각으로 정한다): 띠는 보이는 높이의 12%,
        /// 최소 44pt. 최대 속도 600pt/초(56pt/시간이므로 초당 약 10.7시간 분량).
        private static let autoScrollBandRatio: CGFloat = 0.12
        private static let autoScrollMinBand: CGFloat = 44
        private static let autoScrollMaxSpeed: CGFloat = 600

        init(onBegin: @escaping (CGFloat, CGFloat) -> Bool, onChange: @escaping (CGFloat) -> Void,
             onEnd: @escaping (Bool) -> Void, onTap: @escaping (CGFloat, CGFloat) -> Void,
             autoScrollEligible: @escaping () -> Bool, panLockFallback: Bool) {
            self.onBegin = onBegin; self.onChange = onChange; self.onEnd = onEnd; self.onTap = onTap
            self.autoScrollEligible = autoScrollEligible; self.panLockFallback = panLockFallback
        }

        /// 가로 좌표를 0~1로 바꾼다(겹친 블록이 좌우로 나뉘어 있어 어느 열인지 판단해야 한다).
        private func normalizedX(_ gr: UIGestureRecognizer) -> CGFloat {
            let width = gr.view?.bounds.width ?? 1
            return width > 0 ? min(max(gr.location(in: gr.view).x / width, 0), 1) : 0
        }

        /// 가장 가까운 조상 UIScrollView — ScrollTouchFixView와 같은 올라가기(코디네이터 안에는
        /// while을 두지 않는다, AC-016).
        private func nearestScrollView(from view: UIView?) -> UIScrollView? {
            guard let v = view?.superview else { return nil }
            if let scroll = v as? UIScrollView { return scroll }
            return nearestScrollView(from: v)
        }

        @objc func handleLongPress(_ gr: UILongPressGestureRecognizer) {
            let y = gr.location(in: gr.view).y
            switch gr.state {
            case .began:
                startY = y
                didBegin = onBegin(normalizedX(gr), y)
                if !didBegin {
                    // 블록 밖에서 시작한 자리 — 상태를 취소로 못박고 타이머도 (시작 전이지만) 멈춤
                    // 함수로 끝낸다. 모든 끝 경로가 같은 함수를 지나야 한다는 규칙의 하나(AC-016).
                    gr.state = .cancelled
                    stopAutoScroll()
                    return
                }
                startAutoScrollIfNeeded(for: gr)
            case .changed:
                guard didBegin else { return }
                onChange(y - startY)
                // 길게 누르기 인식기는 손가락이 움직일 때만 .changed를 보낸다 — 손가락이 가장자리에
                // 머무른 채 움직이지 않으면 이벤트가 없으므로 여기서도 (이미 켜져 있으면 아무 일
                // 없이) 링을 다시 건다. 띠 안팎 판정은 틱이 한다.
                startAutoScrollIfNeeded(for: gr)
            case .ended:
                stopAutoScroll()
                if didBegin { onEnd(true) }
                didBegin = false
            case .cancelled, .failed:
                stopAutoScroll()
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

        /// 소유 있는 구간 드래그에서만 가장자리 자동 스크롤을 켠다(REQ-015 (2)). 이미 켜져 있으면
        /// 아무 일도 하지 않는다(멱등) — .began과 .changed 양쪽에서 불려도 링은 하나다.
        /// @MX:WARN 멈춤 함수가 모든 끝 경로에서 불려야 한다 — 빠지면 손을 뗀 뒤에도 스크롤이 돈다
        private func startAutoScrollIfNeeded(for gr: UILongPressGestureRecognizer) {
            guard displayLink == nil, didBegin, autoScrollEligible() else { return }
            activeRecognizer = gr
            lastTick = 0
            dragScrollView = nearestScrollView(from: gr.view)
            if panLockFallback, let scroll = dragScrollView {
                // 대체안: 소유 구간 드래그는 scrollDisabled 대신 팬 인식기를 끈다(D-11) —
                // scrollDisabled가 프로그램 오프셋까지 막는지 확인되지 않아 S-16이 어느 쪽인지
                // 정한다. 되돌리는 곳은 멈춤 함수뿐이다.
                scroll.panGestureRecognizer.isEnabled = false
                panWasDisabled = true
            }
            let proxy = AutoScrollProxy()
            proxy.target = self
            let link = CADisplayLink(target: proxy, selector: #selector(AutoScrollProxy.tick(_:)))
            // .common이어야 스크롤 트래킹 중에도 틱이 온다(N5-12) — .default면 트래킹 모드에서 멈춘다.
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        /// 매 틱: 띠 깊이에 비례한 속도로 오프셋을 옮기고, 손가락 위치를 다시 읽어 같은 onChange로
        /// 넘긴다. 오버레이가 스크롤 콘텐츠 **안**에 있어 손가락이 멈춰 있어도 콘텐츠가 움직이면
        /// 같은 손가락의 콘텐츠 좌표가 그만큼 바뀐다 — 위치 재읽기가 보정의 전부이고,
        /// contentOffset을 onChange에 더하면 두 번 더해진다(D-11).
        func autoScrollTick(_ link: CADisplayLink) {
            guard let gr = activeRecognizer, let scroll = dragScrollView else {
                stopAutoScroll(); return
            }
            // 인식기가 드래그 중일 때만 돈다 — 그 밖의 상태는 드래그가 끝났다는 뜻이라 스스로
            // 멈춘다(앱 내리기 등 시스템 취소도 이 검사가 잡는다).
            guard gr.state == .began || gr.state == .changed else {
                stopAutoScroll(); return
            }
            if lastTick == 0 { lastTick = link.timestamp; return }
            let elapsed = CGFloat(max(link.timestamp - lastTick, 0))
            lastTick = link.timestamp
            guard elapsed > 0 else { return }
            // 띠 판정은 보이는 창 기준으로 한다 — UIScrollView의 bounds 원점은 contentOffset과
            // 같아 location(in: scroll)이 돌려주는 값은 콘텐츠 좌표다. 스크롤이 된 뒤 이를
            // 보정하지 않으면 화면 한가운데의 손가락이 아래 띠 깊은 곳으로 읽히고, 오프셋이
            // 커질수록 속도가 더 커지는 되먹임 폭주가 생긴다(D-11).
            let fingerY = gr.location(in: scroll).y - scroll.contentOffset.y
            let visible = scroll.bounds.height
            let band = max(visible * Self.autoScrollBandRatio, Self.autoScrollMinBand)
            var speed: CGFloat = 0
            if fingerY < band {
                speed = -Self.autoScrollMaxSpeed * (1 - fingerY / band)
            } else if fingerY > visible - band {
                speed = Self.autoScrollMaxSpeed * (1 - (visible - fingerY) / band)
            }
            // 손가락이 스크롤 영역 밖(띠보다 더 위/아래)이면 비례식이 최대 속도를 넘긴다 —
            // 깊이 ≥ 띠 높이면 최대 속도로 막는다(D-11).
            speed = min(max(speed, -Self.autoScrollMaxSpeed), Self.autoScrollMaxSpeed)
            guard speed != 0 else { return }
            if speed > 0 { scrolledDown = true }
            // 콘텐츠 맨 위(첫날 0시)와 지금 콘텐츠 끝(연장이 자라면 같이 자란다)에서 멈춘다.
            let maxOffset = max(0, scroll.contentSize.height - visible)
            let newOffset = min(max(scroll.contentOffset.y + speed * elapsed, 0), maxOffset)
            scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: newOffset), animated: false)
            onChange(gr.location(in: gr.view).y - startY)
        }

        /// 자동 스크롤을 멈추는 유일한 함수 — .ended·.cancelled/.failed·onBegin 거절·dismantleUIView·
        /// 창 이탈(onLeaveWindow)·틱 상태 검사, 모든 끝 경로가 여기로 온다(AC-016 G). 링을 끊고,
        /// 대체안으로 꺼둔 팬 인식기를 되돌리고, 아래로 감기던 중이었다면 연장이 사라져 콘텐츠가
        /// 줄은 뒤 오프셋이 새 최대를 넘는지 다시 본다 — 시스템이 알아서 당겨주리라는 보장이 없어
        /// 직접 맞춘다(S-17). 재렌더를 기다리기 위해 한 틱 뒤에 실행한다.
        func stopAutoScroll() {
            if panWasDisabled, let scroll = dragScrollView {
                scroll.panGestureRecognizer.isEnabled = true
                panWasDisabled = false
            }
            let scroll = dragScrollView
            let wasScrollingDown = scrolledDown
            displayLink?.invalidate()
            displayLink = nil
            activeRecognizer = nil
            dragScrollView = nil
            scrolledDown = false
            guard wasScrollingDown, let scroll else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let maxOffset = max(0, scroll.contentSize.height - scroll.bounds.height)
                if scroll.contentOffset.y > maxOffset {
                    scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: maxOffset), animated: false)
                }
            }
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
