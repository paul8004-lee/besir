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

}

@main
struct Drv {
    @MainActor
    static func main() async {
        let store = Store(notifications: NotificationManager())
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

        print("\n\(drvPass)/\(drvPass + drvFail) 통과")
        exit(drvFail == 0 ? 0 : 1)
    }
}
