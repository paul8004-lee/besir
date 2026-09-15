// besir의 AI 도구 인자 가드를 모델 없이 실행해 보는 드라이버.
//
//   실행(리포지토리 루트에서):
//     cat Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \
//       && swiftc -o /tmp/gd /tmp/gd.swift Shared/Store.swift Shared/Models.swift \
//            Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
//            Shared/LocationManager.swift Shared/NotificationManager.swift \
//            Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
//       && /tmp/gd
//
// ⚠️ 이 파일은 **로직을 복사하지 않는다**. 실행할 때마다 현재 Shared/AIAssistant.swift 뒤에
//    그대로 이어붙여 컴파일하므로 원본과 어긋날 수가 없다. 로직을 여기에 옮겨 적으면 원본이
//    바뀌어도 초록색이 유지되는 거짓 테스트가 된다 — 그러지 말 것.
//
// ⚠️ 이어붙이는 이유는 접근 제어다. Swift의 private는 파일이 아니라 **타입 선언 범위**라,
//    가드 함수에 닿으려면 같은 파일 안의 extension이어야 한다. 별도 파일에서는 못 부른다.
//
// 왜 있나: 이 프로젝트에는 Swift 테스트 타깃이 없어서, 인자 가드들이 한 번도 실행되지 않은 채
// 실기기로 나갔다. 반복된 실패는 전부 인자 문제였고(선택 인자 누락, 비워야 할 값을 채움,
// 0을 "없음" 대신 사용) 가드는 그때마다 방어적으로 덧붙여졌는데, 정작 그 가드 자체가
// 검증된 적이 없었다. 여기 있는 단언들은 그 구멍을 메우고, 고쳐진 결함이 되살아나면 빨개진다.
//
// 모델 호출은 하지 않는다 — API 할당량을 쓰지 않고 결정적으로 돌아간다.
// 모델이 실제로 어떤 인자를 보내는지는 여기서 알 수 없다. 그건 실기기 대화 기록만이 증거다.


var drvPass = 0, drvFail = 0

extension AIAssistant {
    func drvCheck(_ label: String, _ ok: Bool, _ detail: String = "") {
        if ok { drvPass += 1; print("  ✓ \(label)") }
        else { drvFail += 1; print("  ✗ \(label)\n      \(detail)") }
    }

    static func drvEvent(_ rid: UUID, buffer: Int, notify: Int, hours: Double) -> ScheduledEvent {
        let p = Place(name: "곳", address: "주소", latitude: 37.5, longitude: 127.0)
        return ScheduledEvent(title: "출근", origin: p, destination: p,
                              arrivalDate: Date().addingTimeInterval(hours * 3600),
                              mode: .transit, bufferMinutes: buffer, notifyLeadMinutes: notify,
                              recurrenceId: rid, anchor: .arrival)
    }

    func drvZero(_ rid: UUID, _ b: Int?, _ n: Int?, _ input: [String: Any] = [:]) -> String? {
        zeroUpdateIssue(rid, buffer: b, notify: n, input: input)
    }

    static func drvActivity(_ rid: UUID, title: String, hours: Double) -> ActivityBlock {
        let p = Place(name: "곳", address: "주소", latitude: 37.5, longitude: 127.0)
        return ActivityBlock(title: title, location: p,
                             startDate: Date().addingTimeInterval(hours * 3600),
                             endDate: Date().addingTimeInterval((hours + 8) * 3600),
                             recurrenceId: rid)
    }

    static func drvSolo(_ title: String, hours: Double) -> ScheduledEvent {
        let p = Place(name: "곳", address: "주소", latitude: 37.5, longitude: 127.0)
        return ScheduledEvent(title: title, origin: p, destination: p,
                              arrivalDate: Date().addingTimeInterval(hours * 3600),
                              mode: .transit, bufferMinutes: 10, notifyLeadMinutes: 10,
                              recurrenceId: nil, anchor: .arrival)
    }

    static func drvLeg(_ rid: UUID, title: String, hours: Double) -> ScheduledEvent {
        let p = Place(name: "곳", address: "주소", latitude: 37.5, longitude: 127.0)
        return ScheduledEvent(title: title, origin: p, destination: p,
                              arrivalDate: Date().addingTimeInterval(hours * 3600),
                              mode: .transit, bufferMinutes: 10, notifyLeadMinutes: 10,
                              recurrenceId: rid, anchor: .arrival)
    }

    func drvList(_ input: [String: Any] = [:]) -> String { executeListSchedules(input) }
    func drvUpdate(_ input: [String: Any]) async -> String { await executeUpdateRecurringSchedule(input) }
    func drvSetLast(_ rid: UUID?) { lastRecurrenceId = rid }
    func drvRecurIssue(_ input: [String: Any], _ weekdayCount: Int) -> String? {
        recurringArgumentIssue(input, weekdayCount: weekdayCount)
    }

    // 생성 경로 단언(O절)용 — 클램프는 create_schedule·create_recurring_schedule 두 곳에도
    // 걸려 있는데, 수정 경로(updateRecurringSeries)만 검사하던 시절에 음수가 두 생성 경로를
    // 뚫고 지나간 적이 있다.
    func drvCreate(_ input: [String: Any]) async -> String { await executeCreateSchedule(input) }
    func drvCreateRecurring(_ input: [String: Any]) async -> String { await executeCreateRecurringSchedule(input) }

}

@main
struct Drv {
    @MainActor
    static func main() async {
        let store = Store(notifications: NotificationManager())
        // 캘린더 푸시를 끈다 — 개발 기기의 실제 config.json엔 구글 연동이 켜져 있어,
        // 시험용 이벤트 하나를 pushToCalendar하다 OAuth 대화상자(키체인)에서 무기한 멈춘
        // 적이 있다. 캘린더 등록 결과를 보는 단언은 없으므로 꺼도 판정이 변하지 않는다.
        store.config.autoAddToCalendar = false
        func fresh() -> AIAssistant { AIAssistant(store: store, location: LocationManager()) }

        // ── A. 현재 값이 0이 아닐 때
        print("\nA. 현재 여유 10분인 시리즈에 buffer 0이 올 때")
        let ridA = UUID()
        store.events = [AIAssistant.drvEvent(ridA, buffer: 10, notify: 10, hours: 24)]
        let ai = fresh()
        let a1 = ai.drvZero(ridA, 0, nil)
        ai.drvCheck("되묻는다", a1 != nil, "nil — 가드가 통과시켰다")
        ai.drvCheck("복원 탈출구로 현재값 10을 준다", a1?.contains("buffer_minutes:10") == true, a1 ?? "nil")
        var ordered = false
        if let s = a1, let r = s.range(of: "buffer_minutes:10"), let c = s.range(of: "confirm_zero:true") {
            ordered = r.lowerBound < c.lowerBound
        }
        ai.drvCheck("복원 절이 confirm 절보다 먼저 온다", ordered, a1 ?? "nil")

        // ── B. 되묻지 않은 confirm
        print("\nB. 앱이 묻기 전에 온 confirm_zero")
        let aiB = fresh()
        aiB.drvCheck("첫 호출의 자가 confirm은 막힌다",
                     aiB.drvZero(ridA, 0, nil, ["confirm_zero": true]) != nil, "통과해버렸다")
        aiB.drvCheck("되물은 뒤 같은 조합의 confirm은 통과한다",
                     aiB.drvZero(ridA, 0, nil, ["confirm_zero": true]) == nil, "여전히 막힌다")
        aiB.drvCheck("다른 조합의 confirm은 통과하지 않는다",
                     aiB.drvZero(ridA, nil, 0, ["confirm_zero": true]) != nil, "묵은 확인이 통과시켰다")
        let aiB2 = fresh()
        _ = aiB2.drvZero(ridA, 0, nil)
        aiB2.drvCheck("숫자 1로 온 confirm은 미확인 처리(fail-closed)",
                      aiB2.drvZero(ridA, 0, nil, ["confirm_zero": 1]) != nil, "숫자 1이 확인으로 인정됐다")

        // ── C. F1 — 현재 값이 이미 0
        print("\nC. 현재 여유가 이미 0인 시리즈 (F1이 났던 자리)")
        let ridC = UUID()
        store.events = [AIAssistant.drvEvent(ridC, buffer: 0, notify: 10, hours: 24)]
        let aiC = fresh()
        let c1 = aiC.drvZero(ridC, 0, nil)
        aiC.drvCheck("되묻는다", c1 != nil, "nil")
        aiC.drvCheck("복원 지시를 주지 않는다(자기참조 없음)",
                     c1?.contains("건드리는 게 아니었으면 buffer_minutes:0") == false, c1 ?? "nil")
        aiC.drvCheck("0 언급은 confirm과 한 절로 묶여 있다",
                     c1?.contains("buffer_minutes:0 그대로 confirm_zero:true") == true, c1 ?? "nil")
        aiC.drvCheck("유일한 탈출구가 confirm_zero다", c1?.contains("confirm_zero:true") == true, c1 ?? "nil")
        aiC.drvCheck("그 confirm으로 한 번에 통과한다(루프 종결)",
                     aiC.drvZero(ridC, 0, nil, ["confirm_zero": true]) == nil, "또 되물었다 — 루프")

        // ── D. 혼합
        print("\nD. 혼합: 여유 0(이미) + 알림 30(복원 대상)")
        let ridD = UUID()
        store.events = [AIAssistant.drvEvent(ridD, buffer: 0, notify: 30, hours: 24)]
        let aiD = fresh()
        let d1 = aiD.drvZero(ridD, 0, 0)
        aiD.drvCheck("되묻는다", d1 != nil, "nil")
        aiD.drvCheck("여유 쪽은 복원 지시를 안 준다",
                     d1?.contains("건드리는 게 아니었으면 buffer_minutes:0") == false, d1 ?? "nil")
        aiD.drvCheck("알림 쪽은 복원값 30을 준다", d1?.contains("notify_lead_minutes:30") == true, d1 ?? "nil")
        aiD.drvCheck("조합이 달라진 (0,30,confirm)은 한 번 되묻힌다",
                     aiD.drvZero(ridD, 0, 30, ["confirm_zero": true]) != nil, "핀 없이 통과했다")
        aiD.drvCheck("그 다음 같은 호출은 통과한다(2회 수렴)",
                     aiD.drvZero(ridD, 0, 30, ["confirm_zero": true]) == nil, "수렴하지 않는다")

        // ── E. 시리즈 부재
        print("\nE. 시리즈가 없는 recurrenceId")
        store.events = []
        let aiE = fresh()
        aiE.drvCheck("되묻지 않고 통과시킨다(하류 0건 가드가 안내)",
                     aiE.drvZero(UUID(), 0, nil) == nil, "되물었다")


        // ── F. 번호는 한 그룹의 모든 다리가 공유한다
        print("\nF. 번호 배정 — 한 recurrenceId에 한 번호")
        let ridX = UUID(), ridY = UUID()
        store.events = [AIAssistant.drvLeg(ridX, title: "출근", hours: 24),
                        AIAssistant.drvLeg(ridX, title: "출근 (복귀)", hours: 33)]
        store.activities = [AIAssistant.drvActivity(ridX, title: "출근", hours: 25)]
        let aiF = fresh()
        let f1 = aiF.drvList()
        aiF.drvCheck("두 이동 다리가 같은 [반복 1]", f1.components(separatedBy: "[반복 1]").count == 3, f1)
        aiF.drvCheck("활동 줄도 같은 (활동/반복 1)", f1.contains("(활동/반복 1)"), f1)
        aiF.drvCheck("안내문이 붙는다", f1.contains("[n]은 반복 그룹 번호"), f1)
        aiF.drvCheck("재호출해도 같은 번호(멱등)", aiF.drvList().components(separatedBy: "[반복 1]").count == 3, "번호가 바뀌었다")
        store.events.append(AIAssistant.drvLeg(ridY, title: "헬스", hours: 30))
        let f2 = aiF.drvList()
        aiF.drvCheck("새 그룹은 2번을 받는다(재사용 없음)", f2.contains("[반복 2]"), f2)
        aiF.drvCheck("기존 그룹은 1번 유지", f2.contains("[반복 1]"), f2)

        // ── G. 미등록·음수 번호
        print("\nG. 미등록 / 음수 series_number")
        let aiG = fresh()
        _ = aiG.drvList()
        let before = store.events.map { "\($0.id)|\($0.mode.rawValue)" }
        let g1 = await aiG.drvUpdate(["series_number": 99, "mode": "car"])
        aiG.drvCheck("못 찾았다고 되묻는다", g1.contains("찾지 못했어요"), g1)
        aiG.drvCheck("list_schedules 재호출을 가리킨다", g1.contains("list_schedules"), g1)
        aiG.drvCheck("아무것도 쓰지 않는다", store.events.map { "\($0.id)|\($0.mode.rawValue)" } == before, "이벤트가 바뀌었다")
        let g2 = await aiG.drvUpdate(["series_number": -1, "mode": "car"])
        aiG.drvCheck("음수도 같은 갈래로 잡힌다", g2.contains("찾지 못했어요"), g2)

        // ── H. G1 — 번호 0/부재가 lastRecurrenceId로 흐른다
        print("\nH. series_number 0·부재 폴백 (G1 메커니즘)")
        store.events = [AIAssistant.drvLeg(ridX, title: "출근", hours: 24),
                        AIAssistant.drvLeg(ridY, title: "헬스", hours: 30)]
        store.activities = []
        let aiH = fresh()
        _ = aiH.drvList()                 // ridX=1, ridY=2 배정
        aiH.drvSetLast(ridY)              // "이 대화에서 만든" 것은 Y
        _ = await aiH.drvUpdate(["series_number": 0, "mode": "car"])
        let xMode = store.events.first { $0.recurrenceId == ridX }?.mode
        let yMode = store.events.first { $0.recurrenceId == ridY }?.mode
        aiH.drvCheck("번호 0이면 lastRecurrenceId(Y)가 대상이 된다", yMode == .car, "Y=\(String(describing: yMode))")
        aiH.drvCheck("번호를 준 적 있는 X는 건드리지 않는다", xMode == .transit, "X=\(String(describing: xMode))")
        let aiH2 = fresh()
        aiH2.drvSetLast(nil)
        let h3 = await aiH2.drvUpdate(["series_number": 0, "mode": "car"])
        aiH2.drvCheck("lastRecurrenceId가 없으면 안내로 끝난다", h3.contains("이 대화에서 만든"), h3)

        // ── I. 되묻기 안내선의 커버 경계
        print("\nI. series_number 유지 안내가 붙는 범위")
        store.events = [AIAssistant.drvLeg(ridX, title: "출근", hours: 24)]
        let aiI = fresh()
        _ = aiI.drvList()
        let i1 = await aiI.drvUpdate(["series_number": 1, "buffer_minutes": 0])
        aiI.drvCheck("번호 경유 되묻기엔 유지 안내가 붙는다", i1.contains("series_number:1도 그대로"), i1)
        let aiI2 = fresh()
        aiI2.drvSetLast(ridX)
        let i2 = await aiI2.drvUpdate(["buffer_minutes": 0])
        aiI2.drvCheck("번호 없는 되묻기엔 안 붙는다", !i2.contains("series_number"), i2)

        // ── L. G1 — 결과 문구가 대상을 이름으로 말한다
        print("\nL. G1: 수정 결과에 대상 신원")
        store.events = [AIAssistant.drvLeg(ridX, title: "출근", hours: 24)]
        store.activities = []
        let aiL = fresh()
        _ = aiL.drvList()
        let l1 = await aiL.drvUpdate(["series_number": 1, "mode": "car"])
        aiL.drvCheck("[G1] 어느 그룹을 고쳤는지 제목으로 말한다", l1.contains("'출근'"), l1)
        aiL.drvCheck("건수도 계속 말한다", l1.contains("1건을 수정했어요"), l1)

        // ── J. G2 — 활동만 남은 그룹 (읽기 판정 → 관측)
        print("\nJ. G2: 이동 구간이 지워지고 활동만 남은 그룹")
        let ridZ = UUID()
        store.events = []
        store.activities = [AIAssistant.drvActivity(ridZ, title: "출근", hours: 25)]
        let aiJ = fresh()
        let j1 = aiJ.drvList()
        aiJ.drvCheck("[G2] 번호를 붙이지 않는다", !j1.contains("(활동/반복 1)"), j1)
        aiJ.drvCheck("[G2] 줄은 여전히 보이되 이유를 말한다", j1.contains("시간표 블록만 남았어요"), j1)
        aiJ.drvCheck("[G2] 인용할 번호가 없으니 안내문도 안 붙는다", !j1.contains("[n]은 반복 그룹 번호"), j1)
        let j2 = await aiJ.drvUpdate(["series_number": 1, "mode": "car"])
        aiJ.drvCheck("[G2] 그 번호는 미등록으로 되묻힌다", j2.contains("그 번호의 반복 그룹을 찾지 못했어요"), j2)
        aiJ.drvCheck("활동은 그대로다(쓰기 없음)", store.activities.count == 1, "활동이 바뀌었다")

        // ── K. G3 — 캡이 반복 줄을 다 자른 경우
        print("\nK. G3: 20줄 캡 밖으로 밀린 반복 줄")
        store.activities = []
        store.events = (1...21).map { AIAssistant.drvSolo("단발\($0)", hours: Double($0)) }
                    + [AIAssistant.drvLeg(UUID(), title: "출근", hours: 100)]
        let aiK = fresh()
        let k1 = aiK.drvList()
        aiK.drvCheck("본문에 [반복 이 하나도 없다", !k1.contains("[반복 "), "반복 줄이 살아 있다")
        aiK.drvCheck("[G3] 인용할 번호가 없으니 안내문도 안 붙는다", !k1.contains("[n]은 반복 그룹 번호"), k1)

        // ── M. 반복 인자 가드 — c728996이 8주→7건 결함 뒤 재작성한 가드군. 단언이 하나도
        //      없어서 이 가드들이 깨져도 드라이버는 초록이었다.
        print("\nM. recurringArgumentIssue — 주기·기간 인자")
        let aiM = fresh()
        let m1 = aiM.drvRecurIssue(["nth_week_of_month": 7, "weeks": 8], 1)
        aiM.drvCheck("nth 범위 밖(7)은 되돌린다", m1?.contains("nth_week_of_month에 쓸 수 없는 값") == true, m1 ?? "nil")
        aiM.drvCheck("nth 0은 '없음'으로 읽힌다(불필요한 되묻기 없음)",
                     aiM.drvRecurIssue(["nth_week_of_month": 0, "every_n_weeks": 1, "weeks": 8], 3) == nil, "되물었다")
        aiM.drvCheck("nth -1(마지막 주)은 범위 밖으로 거부되지 않는다",
                     aiM.drvRecurIssue(["nth_week_of_month": -1, "weeks": 8], 1) == nil, "마지막 주가 거부됐다")
        let m2 = aiM.drvRecurIssue(["nth_week_of_month": 1, "weeks": 8], 3)
        aiM.drvCheck("요일 3개+매월 주기의 충돌을 되묻는다", m2?.contains("매월 첫째 주에만") == true, m2 ?? "nil")
        let m3 = aiM.drvRecurIssue(["nth_week_of_month": -1, "weeks": 8], 3)
        aiM.drvCheck("-1은 '매월 마지막 주'로 읽는다", m3?.contains("매월 마지막 주에만") == true, m3 ?? "nil")
        let aiM2 = fresh()
        _ = aiM2.drvRecurIssue(["nth_week_of_month": 1, "weeks": 8], 3)
        aiM2.drvCheck("되물은 뒤 같은 조합의 confirm_recurrence는 통과한다",
                      aiM2.drvRecurIssue(["nth_week_of_month": 1, "weeks": 8, "confirm_recurrence": true], 3) == nil, "여전히 막힌다")
        let aiM3 = fresh()
        aiM3.drvCheck("묻기 전에 스스로 붙인 confirm_recurrence는 막힌다",
                      aiM3.drvRecurIssue(["nth_week_of_month": 1, "weeks": 8, "confirm_recurrence": true], 3) != nil, "자가 확인이 통과했다")
        let m4 = aiM.drvRecurIssue(["every_n_weeks": 1], 3)
        aiM.drvCheck("기간(weeks) 비었으면 되묻는다", m4?.contains("start_date·weeks") == true, m4 ?? "nil")
        let m5 = aiM.drvRecurIssue(["weeks": 0, "every_n_weeks": 1], 3)
        aiM.drvCheck("weeks 0은 '없음'으로 읽힌다(기간 되묻기 발동)",
                     m5?.contains("언제부터 몇 주간") == true, m5 ?? "nil")
        let m6 = aiM.drvRecurIssue(["weeks": 52], 1)
        aiM.drvCheck("weeks 상한(\(Store.maxRecurrenceWeeks)) 초과는 되돌린다",
                     m6?.contains("최대 \(Store.maxRecurrenceWeeks)주까지만") == true, m6 ?? "nil")

        // ── N. 회차마다 값이 제각각인 시리즈 — C 절이 단일 회차만 만들어 도달 불가능하던 갈래.
        //      한 회차만 드래그(adjustBuffer)로 바뀐 시리즈에서 첫 회차가 0이라고 "이미 0"이라
        //      말하던 거짓이 이 가드의 수정 동기다.
        print("\nN. divergent 시리즈 — 전 회차 확인 + 버퍼 하한")
        let ridN = UUID()
        store.events = [AIAssistant.drvEvent(ridN, buffer: 0, notify: 10, hours: 24),
                        AIAssistant.drvEvent(ridN, buffer: 10, notify: 10, hours: 48)]
        let aiN = fresh()
        let n1 = aiN.drvZero(ridN, 0, nil)
        aiN.drvCheck("첫 회차가 0이어도 '이미 0'이라 말하지 않는다",
                     n1?.contains("바뀌는 게 없어요") == false, n1 ?? "nil")
        aiN.drvCheck("실제 편차(0~10분)를 말한다", n1?.contains("0~10분") == true, n1 ?? "nil")
        aiN.drvCheck("확인하면 전부 0으로 통일된다고 말한다", n1?.contains("전부 0분으로 통일") == true, n1 ?? "nil")
        aiN.drvCheck("같은 조합의 confirm_zero로 한 번에 통과한다",
                     aiN.drvZero(ridN, 0, nil, ["confirm_zero": true]) == nil, "또 되물었다 — 루프")
        let ridN2 = UUID()
        store.events = [AIAssistant.drvEvent(ridN2, buffer: 5, notify: 0, hours: 24),
                        AIAssistant.drvEvent(ridN2, buffer: 5, notify: 30, hours: 48)]
        let aiN2 = fresh()
        let n2 = aiN2.drvZero(ridN2, nil, 0)
        aiN2.drvCheck("알림 쪽도 편차를 말한다", n2?.contains("0~30분") == true, n2 ?? "nil")
        let ridN3 = UUID()
        store.events = [AIAssistant.drvEvent(ridN3, buffer: 0, notify: 10, hours: 24),
                        AIAssistant.drvEvent(ridN3, buffer: 0, notify: 10, hours: 48)]
        let aiN3 = fresh()
        let n3 = aiN3.drvZero(ridN3, 0, nil)
        aiN3.drvCheck("전 회차가 0이면 '이미 0' 갈래로 간다(다중 회차)",
                      n3?.contains("바뀌는 게 없어요") == true, n3 ?? "nil")
        // 음수 buffer_minutes: 0 가드에 걸리지 않고 Store의 상하한(0~180)으로 묶인다 —
        // 통과 여부가 아니라 '부호 없이 저장되는지'를 본다.
        let ridN4 = UUID()
        store.events = [AIAssistant.drvEvent(ridN4, buffer: 10, notify: 10, hours: 24)]
        let aiN4 = fresh()
        aiN4.drvSetLast(ridN4)
        _ = await aiN4.drvUpdate(["buffer_minutes": -5])
        let bufN4 = store.events.first { $0.recurrenceId == ridN4 }?.bufferMinutes
        aiN4.drvCheck("음수 buffer_minutes는 0으로 묶인다(-5 저장 아님)",
                      bufN4 == 0, "buffer=\(bufN4.map(String.init) ?? "nil")")

        // ── O. 클램프 저장값 — N절의 음수 단언은 수정 경로만 봤고, 그 시절 음수 buffer_minutes가
        //      세 경로 중 두 곳(create_schedule·create_recurring_schedule)을 뚫고 지나갔는데도
        //      드라이버는 초록이었다. 여기선 되돌린 문구가 아니라 **저장된 이벤트의 값**을 본다.
        //      출발지·목적지는 즐겨찾기로 둔다 — 드라이버는 위치 권한·장소 검색 밖에서 돌므로
        //      검색 없이 결정적으로 풀려야 한다(캘린더 push는 이미 위에서 꺼뒀다).
        print("\nO. clampBuffer·clampNotifyLead — 생성 경로의 저장값")
        store.favorites = [FavoritePlace(label: "집", place: Place(name: "집", address: "", latitude: 37.500, longitude: 127.000)),
                           FavoritePlace(label: "회사", place: Place(name: "회사", address: "", latitude: 37.510, longitude: 127.010))]

        store.events = []
        let aiO1 = fresh()
        _ = await aiO1.drvCreate(["title": "O-단발", "destination_query": "회사", "origin_query": "집",
                                  "arrival_iso": "2027-03-01T09:00:00",
                                  "buffer_minutes": -5, "notify_lead_minutes": -10])
        let o1 = store.events.first { $0.title == "O-단발" }
        let o1b = o1?.bufferMinutes, o1n = o1?.notifyLeadMinutes
        aiO1.drvCheck("create_schedule 음수 buffer(-5)는 0으로 저장된다",
                      o1b == 0, "buffer=\(o1b.map(String.init) ?? "이벤트 없음")")
        aiO1.drvCheck("create_schedule 음수 notify(-10)는 0으로 저장된다",
                      o1n == 0, "notify=\(o1n.map(String.init) ?? "이벤트 없음")")

        store.events = []
        let aiO2 = fresh()
        _ = await aiO2.drvCreateRecurring(["title": "O-반복", "destination_query": "회사", "origin_query": "집",
                                           "weekdays": ["mon"], "arrival_time": "09:00",
                                           "start_date": "2027-03-01", "weeks": 2,
                                           "buffer_minutes": -5, "notify_lead_minutes": -10])
        // 첫 회차만 읽으면 회차마다 다른 값을 못 본다 — N절이 밝힌 결함의 모양 그대로. 전 회차를 본다.
        // allSatisfy는 빈 배열에서 공히 참이므로 isEmpty를 함께 건다 — 생성 실패가 거짓 초록이 되지 않게.
        let seriesO = store.events.filter { $0.recurrenceId != nil }
        aiO2.drvCheck("반복은 2회차 이상 만들어진다(전 회차 검증의 전제)",
                      seriesO.count >= 2, "count=\(seriesO.count)")
        aiO2.drvCheck("create_recurring 음수 buffer는 전 회차 0으로 저장된다",
                      !seriesO.isEmpty && seriesO.allSatisfy { $0.bufferMinutes == 0 },
                      "buffer들=" + seriesO.map { String($0.bufferMinutes) }.joined(separator: ","))
        aiO2.drvCheck("create_recurring 음수 notify는 전 회차 0으로 저장된다",
                      !seriesO.isEmpty && seriesO.allSatisfy { $0.notifyLeadMinutes == 0 },
                      "notify들=" + seriesO.map { String($0.notifyLeadMinutes) }.joined(separator: ","))

        store.events = []
        let aiO3 = fresh()
        _ = await aiO3.drvCreate(["title": "O-상한", "destination_query": "회사", "origin_query": "집",
                                  "arrival_iso": "2027-03-02T09:00:00",
                                  "buffer_minutes": 9999, "notify_lead_minutes": 1440])
        let o3 = store.events.first { $0.title == "O-상한" }
        let o3b = o3?.bufferMinutes, o3n = o3?.notifyLeadMinutes
        aiO3.drvCheck("buffer 9999는 상한 180으로 묶인다",
                      o3b == 180, "buffer=\(o3b.map(String.init) ?? "이벤트 없음")")
        // 알림은 위쪽으로 묶지 않는다 — "하루 전에 알려줘"(1440분)는 실제 요청이라 상한이 없다.
        // buffer와 대칭으로 만들면 이 줄이 빨개진다(비대칭이 의도라는 사실을 여기 못 박는다).
        aiO3.drvCheck("notify 1440은 묶이지 않고 그대로 저장된다(상한 없음은 의도)",
                      o3n == 1440, "notify=\(o3n.map(String.init) ?? "이벤트 없음")")

        store.events = []
        let aiO4 = fresh()
        _ = await aiO4.drvCreate(["title": "O-출발기준", "destination_query": "집", "origin_query": "회사",
                                  "departure_iso": "2027-03-02T18:00:00", "buffer_minutes": 30])
        // 출발 기준 구간은 도착 여유를 둘 대상이 없어 클램프 이전부터 buffer를 항상 0으로 뒀다 —
        // 새 클램프가 이 규칙을 덮어쓰지 않는지 지킨다.
        let o4 = store.events.first { $0.title == "O-출발기준" }
        let o4b = o4?.bufferMinutes
        aiO4.drvCheck("출발 기준 create_schedule은 buffer 30을 보내도 0으로 저장한다",
                      o4b == 0, "buffer=\(o4b.map(String.init) ?? "이벤트 없음")")

        print("\n\(drvPass)/\(drvPass + drvFail) 통과")
        exit(drvFail == 0 ? 0 : 1)
    }
}
