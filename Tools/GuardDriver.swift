// besir의 AI 도구 인자 가드를 모델 없이 실행해 보는 드라이버.
//
//   실행(리포지토리 루트에서):
//     cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \
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

    // P·Q·R·T절(카드·무기억·왕복·정화 결함)용 — runLoop가 카드를 만드는 실제 경로(정화 →
    // fillStated → pendingAsk)를 그대로 탄다. stated 주입은 submit()과 같은 **병합**이다(2026-09-16
    // 결함 B 이후) — 새 발화에서 말한 키만 갱신하고 안 말한 키는 유지한다. 값이 지워지는 경계(툴
    // 실행)는 Q절에서, 선언 밖 모델 인자가 버려지는 건 T절에서 검증한다.
    func drvAsk(_ tool: String, _ args: [String: Any], stated: [String: Any] = [:]) -> PendingAsk? {
        for (k, v) in stated { statedArgs[k] = v }
        let parts: [[String: Any]] = [["functionCall": ["name": tool, "args": args]]]
        return pendingAsk(for: fillStated(sanitizeModelArgs(parts)))
    }
    /// 카드가 붙잡은 보류 호출의 인자(T절 — 모델 값이 살았는지 죽었는지 보는 창).
    static func drvCallArgs(_ ask: PendingAsk?) -> [String: Any] {
        ((ask?.parts.first?["functionCall"] as? [String: Any])?["args"] as? [String: Any]) ?? [:]
    }
    /// 정화의 화이트리스트(D4 — 선언과 어긋나지 않는지 직접 본다).
    func drvModelKeys(_ tool: String) -> Set<String> { modelSuppliableKeys(for: tool) }
    /// 시스템 프롬프트 원문(U절 — 문자열 존재 확인용).
    func drvSystemPrompt() -> String { systemPrompt() }
    /// 화면에 떠 있는 카드의 실제 상태(V절 — choose/submitCustom은 버블 쪽 사본을 고친다).
    func drvLiveAsk() -> PendingAsk? {
        bubbles.lastIndex(where: { $0.ask != nil }).flatMap { bubbles[$0].ask }
    }
    /// 실행에 실제로 실린 인자(V절 — 마지막 model 턴의 첫 호출에서 직접 읽는다).
    func drvLastCallArgs() -> [String: Any] {
        for turn in contents.reversed() {
            guard (turn["role"] as? String) == "model" else { continue }
            if let call = (turn["parts"] as? [[String: Any]])?
                .compactMap({ $0["functionCall"] as? [String: Any] }).first,
               let args = call["args"] as? [String: Any] { return args }
        }
        return [:]
    }
    /// statedArgs는 private이라 Drv 구조체(다른 타입)에서는 못 읽는다 — 판정에 필요한 만큼만 노출.
    func drvStatedArgs() -> [String: Any] { statedArgs }
    func drvCancelPendingAsk() { cancelPendingAsk() }
    /// 내부 토큰 둘도 같은 이유로 노출용 접근자를 지난다(값 자체는 그대로).
    static func drvCurrentLocationToken() -> String { currentLocationToken }
    static func drvNoOutboundToken() -> String { noOutboundToken }
    /// P절 — 검색 상태를 글자로 바꿔 비교한다(Lookup은 Equatable이 아니고, 그렇게 만들 이유도 없다).
    static func drvLookup(_ l: AskField.Lookup) -> String {
        switch l {
        case .idle: return "idle"
        case .searching: return "searching"
        case .empty: return "empty"
        case .results(let p): return "results:\(p.count)"
        }
    }
    /// P절 — 캘린더 대기 문구(private이라 Drv 구조체에서 못 부른다).
    func drvCalendarNote(_ eventIDs: Set<UUID>, _ activityIDs: Set<UUID> = []) -> String {
        calendarPendingNote(eventIDs: eventIDs, activityIDs: activityIDs)
    }
    /// 일반명사 목록 snapshot(Y절 — 게이트 범위 확인용).
    static func drvGenericPlaceWords() -> Set<String> { genericPlaceWords }
    static func drvStated(_ utterance: String) -> [String: Any] { statedArguments(from: utterance) }
    func drvToolsJSON() -> [[String: Any]] { toolsJSON() }
    func drvExecuteTool(_ name: String, _ input: [String: Any]) async -> String {
        await executeTool(name: name, input: input)
    }
    func drvResolvePendingAsk() async -> String? { await resolvePendingAsk() }

    /// J절용 — 등록 요약의 시각 문구와 같은 포맷터(when)로 찍어 비교한다. when이 private이라
    /// Drv 구조체에서 못 부르므로 판정에 필요한 만큼만 통과시킨다(값은 그대로).
    static func drvWhen(_ d: Date) -> String { when(d) }

    /// REQ-040 — 보류 카드가 saveHistory가 쓰는 본문에 담기지 않는지 본다. t8부터 이 경로는
    /// 실행마다 새로 만드는 샌드박스 안에서 풀린다(실제 데이터는 종료 시 바이트 대조가 지킨다).
    /// 그래도 원본 바이트를 백업해 두고 검사 뒤 그대로 되돌린다 — init의 loadHistory가 이
    /// 파일을 다시 읽으므로(fresh()마다), 이 쓰기가 다음 절의 출발 상태를 바꾸면 안 된다.
    /// 원본이 없었으면 파일을 지운다.
    func drvPersistedPayload(card: PendingAsk?) -> [String: Any] {
        let url = AppConfig.supportDirectory.appendingPathComponent("ai_history.json")
        let backup = try? Data(contentsOf: url)
        bubbles = [.init(role: .assistant, text: "drv-말풍선"),
                   .init(role: .assistant, text: "", ask: card)]
        saveHistory()
        let obj = (try? Data(contentsOf: url))
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        if let backup { try? backup.write(to: url) }
        else { try? FileManager.default.removeItem(at: url) }
        return obj
    }

}

// ── SPEC-TEST-001: 드라이버 자기 격리의 공용 부품(샌드박스·실제 데이터 대조·시간 제한).
//    main()이 @MainActor라 여기 있는 함수·값은 전부 파일 범위 비격리다 — 시한 타이머
//    스레드에서도 불리므로 파일 읽기 외에 앱 상태를 건드리지 않는다.
//
// 내부 시간 제한(초). 기록된 온전한 완주는 2026-09-23 t5 run의 약 433초 하나뿐이라 그
// 2.1배로 잡았다 — 실행 편차를 감싸되 묶어 두지는 않는다. 무한정 도는 드라이버가 이
// 카드가 없애려는 실패(외부 감시자가 도구 호출을 붙잡던 일)를 그대로 되살린다.
let drvDeadlineDefaultSeconds = 900

// 끝내는 일은 한 루틴이 한 번만 한다 — 정상 종료(주 스레드)와 시한(타이머 스레드)이
// 각자 exit하면 동시 종료라 정의되지 않은 동작이다.
let drvFinishGate = NSLock()

/// 실제 지원 디렉터리를 {파일 이름: 바이트}로 읽는다. 이 함수는 **읽기만** 한다 —
/// 드라이버의 모든 쓰기는 샌드박스로 가야 하고, 실제 디렉터리에 쓰는 순간 2026-09-23의
/// 덮어쓰기가 재현된다. 디렉터리가 없어도 죽지 않는다 — "없음"도 기록할 상태고, 앱 데이터
/// 바이트가 0개라는 점에서 "비어 있음"과 같은 상태로 센다. 읽기에 실패한 항목(디렉터리
/// 등)은 nil 바이트로 남겨 대조에서 생겼다/사라졌다가 드러나게 한다.
func drvReadSupportDir(_ dir: URL) -> [String: Data?] {
    var out: [String: Data?] = [:]
    for name in (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [] {
        out[name] = try? Data(contentsOf: dir.appendingPathComponent(name))
    }
    return out
}

/// 두 읽기 사이에 달라진 파일 이름 전부. 정렬한다 — 전부 찍을 때 순서가 흔들리면 실행할
/// 때마다 다른 로그가 나와 차이 비교가 어려워진다.
func drvDiffSupportDir(_ a: [String: Data?], _ b: [String: Data?]) -> [String] {
    var names = Set(a.keys)
    names.formUnion(b.keys)
    return names.filter { (a[$0] ?? nil) != (b[$0] ?? nil) }.sorted()
}

/// 샌드박스를 지운다 — 단, 대상이 이번 실행이 만든 경로임을 확인한 뒤에만. 지우는 건
/// 파괴적 조작이라 확인이 없으면 실제 홈을 가리키는 오탈자 하나로 끝난다. 확인 조건은
/// 지우는 호출과 같은 함수의 바로 위에 둔다 — 떨어져 있으면 이 코드를 읽는 판정자가
/// 대응 관계를 확인할 수 없다.
func drvRemoveSandboxIfOurs(_ sandbox: URL) {
    let name = sandbox.lastPathComponent
    guard sandbox.path.hasPrefix(NSTemporaryDirectory()),
          name.hasPrefix("besir-gd-"),
          UUID(uuidString: String(name.dropFirst("besir-gd-".count))) != nil
    else {
        print("[샌드박스] 지울 대상이 이번 실행이 만든 경로가 아니다 — 남겨둔다: \(sandbox.path)")
        return
    }
    do { try FileManager.default.removeItem(at: sandbox) }
    catch { print("[샌드박스] 삭제에 실패했다 — 남겨둔다: \(sandbox.path) (\(error.localizedDescription))") }
}

/// 드라이버의 유일한 종료 루틴 — 정상 종료와 시한이 같이 쓴다. 실제 디렉터리를 다시 읽어
/// 시작 상태와 대조하고 종료 코드를 정해 exit한다. 잠금을 풀지 않는 게 핵심이다: 먼저 온
/// 쪽이 exit할 때까지 잠금을 쥐고 있으면 늦은 쪽은 잠금에서 기다리다 프로세스와 함께
/// 끝난다. 풀고 들어가는 모양이면 늦은 쪽이 루틴 밖으로 새어 나가 main의 끝까지 달려
/// 잘못된 코드로 exit할 수 있다.
func drvFinishOnce(start: [String: Data?], realSupport: URL, sandbox: URL,
                   deadlineFired: Bool, removeSandbox: Bool) -> Never {
    drvFinishGate.lock()
    let end = drvReadSupportDir(realSupport)
    let diffs = drvDiffSupportDir(start, end)
    if diffs.isEmpty {
        print("[실제 데이터] 대조 통과 — 시작 \(start.count)개, 끝 \(end.count)개의 이름·바이트가 같다")
    } else {
        for name in diffs { print("[실제 데이터] 달라졌다: \(name)") }
    }
    // 시한 가지는 지우지 않는다 — 주 스레드가 아직 샌드박스 안에 쓰는 중일 수 있고,
    // Store.save는 디렉터리를 다시 만들므로(Store.swift save) 지운 샌드박스가 되살아난다.
    if removeSandbox { drvRemoveSandboxIfOurs(sandbox) }
    else { print("[시한] 샌드박스는 그대로 둔다: \(sandbox.path)") }
    let code: Int32
    if !diffs.isEmpty { code = 3 }
    else if deadlineFired { code = 124 }
    else { code = drvFail > 0 ? 1 : 0 }
    // _exit이 아니라 exit을 쓴다 — 시한·대조 줄이 stdout 버퍼에 남은 채 죽으면 로그에서
    // 124·3의 이유를 볼 수 없다. exit은 버퍼를 비우고 끝낸다.
    exit(code)
}

@main
struct Drv {
    @MainActor
    static func main() async {
        // ── SPEC-TEST-001 REQ-001: 이 프로세스의 홈을 실행마다 새로 만드는 임시 디렉터리로
        //    돌린다. AppConfig.supportDirectory는 static let이라 **처음 읽는 순간** 고정되고,
        //    드라이버의 첫 읽기는 바로 아래 Store 생성이므로 재지정은 그 앞에서 끝나야 한다.
        //    실제 홈은 재지정 전에 먼저 읽어 둔다 — 먼저 읽어도 재지정이 막히지 않는다는 것은
        //    2026-09-24 탐침으로 잤다.
        let realHome = NSHomeDirectory()
        let sandbox = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("besir-gd-" + UUID().uuidString, isDirectory: true)
        do { try FileManager.default.createDirectory(at: sandbox, withIntermediateDirectories: true) }
        catch {
            // 샌드박스 없이 도는 건 실제 데이터 위에서 도는 것이다 — 조용히 넘어가지 않는다.
            print("[샌드박스] 임시 홈을 만들지 못했다 — 시작을 거부한다(exit 2): \(error.localizedDescription)")
            exit(2)
        }
        setenv("CFFIXED_USER_HOME", sandbox.path, 1)
        // 재지정 변수는 문서화가 얕고, 앞으로의 macOS가 이를 무시하면 드라이버의 모든 쓰기가
        // 실제 홈에 떨어진다. 그래서 확인은 fail-closed다 — 지원 디렉터리가 샌드박스 **안**을
        // 가리키지 않으면 Store를 만들기도 전에 끝낸다. 끝에 "/"를 붙이는 건 형제 샌드박스
        // 이름이 접두사로 우연히 겹치는 일을 막는다.
        guard AppConfig.supportDirectory.path.hasPrefix(sandbox.path + "/") else {
            print("[샌드박스] 지원 디렉터리가 샌드박스 안을 가리키지 않는다 — 시작을 거부한다(exit 2)")
            print("  실제로 풀린 지원 디렉터리: \(AppConfig.supportDirectory.path)")
            drvRemoveSandboxIfOurs(sandbox)
            exit(2)
        }
        print("[샌드박스] 이번 실행의 홈: \(sandbox.path)")
        print("[샌드박스] 이번 실행의 지원 디렉터리: \(AppConfig.supportDirectory.path)")
        // 실제 지원 디렉터리는 '실제 홈 + 지원 디렉터리의 샌드박스 기준 상대 경로'로 만든다.
        // 절대 경로를 두 번째 리터럴로 적으면 두 표기가 어긋나는 날 조용히 실제 데이터를
        // 잘못 읽게 된다 — 같은 계산은 한 곳에서만(계약 5).
        let realSupport = URL(fileURLWithPath: realHome
            + String(AppConfig.supportDirectory.path.dropFirst(sandbox.path.count)))
        // 시작 상태는 절이 하나라도 돌기 전에 딱 한 번 읽는다 — 끝의 대조 기준은 이 읽기다.
        let startSnapshot = drvReadSupportDir(realSupport)
        print("[실제 데이터] 시작 상태 \(startSnapshot.count)개 파일 — \(realSupport.path)")

        // 시한은 명령줄 인자 하나로 덮는다(짧은 기한 시험용). 해석이 안 되는 값으로 시험을
        // 중단시키는 대신 기본값으로 돈다 — 시험 편의를 위해 기본 보증(시간이 묶여 있다)을
        // 깨는 방향이면 안 되기 때문이다.
        let deadlineArg = CommandLine.arguments.dropFirst().first
        let drvDeadlineSeconds: Int
        if let s = deadlineArg.flatMap({ Int($0) }), s > 0 { drvDeadlineSeconds = s }
        else {
            if let a = deadlineArg {
                print("[시한] 인자 '\(a)'를 초로 읽지 못한다 — 기본 \(drvDeadlineDefaultSeconds)초로 돈다")
            }
            drvDeadlineSeconds = drvDeadlineDefaultSeconds
        }
        // 타이머는 메인 액터 밖에서 돈다 — 주 스레드가 동기 호출에 묶여 있어도(2026-09-23의
        // SecItemCopyMatching) 시한은 흘러야 한다. 클로저는 잡은 값만 쓰고 공유 상태를
        // 건드리지 않는다.
        DispatchQueue.global().asyncAfter(deadline: .now() + Double(drvDeadlineSeconds)) {
            print("[시한] \(drvDeadlineSeconds)초를 넘겼다 — 샌드박스: \(sandbox.path)")
            drvFinishOnce(start: startSnapshot, realSupport: realSupport, sandbox: sandbox,
                          deadlineFired: true, removeSandbox: false)
        }

        let store = Store(notifications: NotificationManager())
        // 캘린더 푸시를 끈다 — 개발 기기의 실제 config.json엔 구글 연동이 켜져 있어,
        // 시험용 이벤트 하나를 pushToCalendar하다 OAuth 대화상자(키체인)에서 무기한 멈춘
        // 적이 있다. 캘린더 등록 결과를 보는 단언은 없으므로 꺼도 판정이 변하지 않는다.
        store.config.autoAddToCalendar = false
        // 구글 클라이언트 ID도 비운다 — 샌드박스에는 config.json이 없어 AppConfig.load()가
        // 내장 기본값을 주는데 그 ID는 차 있다. ID가 살아 있으면 googleConnected의 단락
        // 평가가 Keychain.get까지 흘러 2026-09-23처럼 SecItemCopyMatching에서 무기한 멈출
        // 수 있다. N절은 자기가 저장한 값(여기선 빈 문자열)을 그대로 되돌리므로 이 불변식은
        // 절이 지나도 깨지지 않는다.
        store.config.googleClientID = ""
        // 프록시 주소·앱 토큰도 비운다 — 샌드박스엔 config.json이 없어 AppConfig.load()가
        // 내장 기본값을 돌려주는데 그 둘은 살아 있는 값이다(Config.swift bundledDefaults).
        // 이대로 두면 절들이 회당 몇 회 카카오·ODsay 프록시를 경유할 수 있었다(2026-09-24
        // code-safety 추적). 비워 두면 hasProxy가 거짓이 되어 proxyRequest·proxyPOSTRequest가
        // nil을 돌려 모든 조회가 로컬 MapKit 폴백으로 끝난다. 판정은 그대로다 — P-4의 검색어는
        // 폴백에서도 0건이고, Y-2·Z O-2·P-1은 transit 초록 여부에 단언이 걸려 있지 않으며,
        // S·J는 walk이라 애초에 무관하다.
        store.config.proxyBaseURL = ""
        store.config.appToken = ""
        func fresh() -> AIAssistant { AIAssistant(store: store, location: LocationManager()) }

        // 위 설정 줄들은 **전역 불변식**이다 — 드라이버가 도는 내내 그대로여야 한다. 캘린더
        // 푸시가 한 번 켜지면 그 뒤 모든 절이 만든 시험용 일정이 사용자의 진짜 구글 캘린더로
        // 올라간다. 파일 쓰기는 샌드박스가 받아 주지만 캘린더는 샌드박스 밖의 실제 서비스라
        // **되돌릴 수가 없다**(2026-09-16 실제 발생: N절이 `AppConfig.load()`로 설정을 통째로
        // 되돌리면서 디스크의 autoAddToCalendar=true를 같이 끌고 왔고, 사용자 캘린더에
        // Z-단발·P-확정이 등록됐다).
        //
        // 조용히 깨진 게 문제였으므로, 깨졌는지 **재는** 자리를 만든다. 복구는 하지 않는다 —
        // 스스로 고치면 breach가 또 안 보이게 된다. 복구는 각 절의 방어선이 맡는다.
        func drvAssertGlobalInvariants(_ ai: AIAssistant, _ where_: String) {
            ai.drvCheck("불변식: \(where_) 뒤에도 캘린더 푸시는 꺼져 있고 프록시 설정은 비어 있다",
                        !store.config.autoAddToCalendar
                            && store.config.proxyBaseURL.isEmpty
                            && store.config.appToken.isEmpty,
                        "켜져 있거나 프록시 주소·앱 토큰이 차 있다 — 이 시점 이후 절들이 실제 캘린더에 쓰거나 카카오·ODsay 외부 API를 부를 수 있다")
            // 키체인 게이트(clientID)도 같이 잰다 — 게이트가 열려 있으면 단락 평가가
            // Keychain.get까지 가고, 이 드라이버 환경에서 그 호출은 멈춤이었다(2026-09-23).
            ai.drvCheck("불변식: \(where_) 뒤에도 구글 캘린더 게이트는 닫혀 있다",
                        !store.config.hasGoogleCalendar,
                        "clientID가 차 있다 — googleConnected가 Keychain.get까지 갈 수 있다")
            // 게이트 밖 삭제·수정 경로는 googleEventId를 가진 레코드에서만 불린다. 드라이버는
            // 지금 그 경로를 부르지 않지만, 뒤에 추가될 절이 gid 레코드와 함께 들어오면
            // 키체인 대화상자로 드러나기 전에 여기서 붉게 드러나야 한다.
            ai.drvCheck("불변식: \(where_) 뒤에도 googleEventId를 가진 레코드가 없다",
                        !store.events.contains { $0.googleEventId != nil }
                            && !store.activities.contains { $0.googleEventId != nil },
                        "gid 레코드가 있으면 게이트 밖 경로가 키체인을 건드릴 수 있다")
        }

        // 세팅 직후 머리말에서 바로 한 번 잰다 — 시작부터 불변식이 깨진 형태는 절이 하나라도
        // 돌기 전에 붉게 나와야 그 뒤 절들의 결과를 읽을 이유가 없다.
        drvAssertGlobalInvariants(fresh(), "머리말")

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
        //      기간(weeks) 되묻기 단언 3건(빈 값·0·상한 초과)은 2026-09-15에 삭제했다 — weeks가
        //      툴 선언에서 빠지며(SPEC-ASK-001 REQ-010) 이 가드의 갈래가 아니 됐다. 빈 값·상한은
        //      이제 카드 입력이 막는다(AskField.accepts).
        print("\nM. recurringArgumentIssue — 주기 인자")
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
        // 카드 이후 세계에선 실행부까지 온 호출이 이미 카드(또는 발화)로 값을 받은 상태다 —
        // 픽스처에도 mode_this_time(·출발 기준이 아니면 notify까지)을 실어 줘야
        // missingAskedArguments에 걸리지 않고 클램프 저장값까지 도달한다.
        // 클램프 자체는 M1~M3에서 변하지 않았으므로 기대값은 그대로 둔다.
        _ = await aiO1.drvCreate(["title": "O-단발", "destination_query": "회사", "origin_query": "집",
                                  "arrival_iso": "2027-03-01T09:00:00", "mode_this_time": "transit",
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
                                           "start_date": "2027-03-01", "weeks": 2, "mode_this_time": "transit",
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
                                  "arrival_iso": "2027-03-02T09:00:00", "mode_this_time": "transit",
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
        // 출발 기준은 buffer 행을 카드가 만들지 않지만 알림은 끄지 않는 한 묻는다 — 그래서
        // notify까지 실어야 실행까지 닿는다(buffer가 0으로 저장되는 건 anchor가 departure라서,
        // 카드·클램프와 무관하다는 걸 이 단언이 지킨다).
        _ = await aiO4.drvCreate(["title": "O-출발기준", "destination_query": "집", "origin_query": "회사",
                                  "departure_iso": "2027-03-02T18:00:00", "mode_this_time": "transit",
                                  "notify_lead_minutes": 10, "buffer_minutes": 30])
        // 출발 기준 구간은 도착 여유를 둘 대상이 없어 클램프 이전부터 buffer를 항상 0으로 뒀다 —
        // 새 클램프가 이 규칙을 덮어쓰지 않는지 지킨다.
        let o4 = store.events.first { $0.title == "O-출발기준" }
        let o4b = o4?.bufferMinutes
        aiO4.drvCheck("출발 기준 create_schedule은 buffer 30을 보내도 0으로 저장한다",
                      o4b == 0, "buffer=\(o4b.map(String.init) ?? "이벤트 없음")")

        // ── P. 앱 주도 되묻기 카드(SPEC-ASK-001 REQ-011~015, 단언 REQ-020). 되묻기가 모델 편이던
        //      시절엔 이 검증이 불가능했다 — 모델이 실제로 어떤 인자를 보낼지는 가드가 알 수 없어
        //      실기기 대화 기록만이 증거였다. 요청 생성이 앱의 보류 상태가 되고서야 결정적 검증이
        //      생겼다(REQ-020의 '대비' 문단이 말하는 이 설계의 핵심 이득).
        print("\nP. 카드 — 부재 인자 나열·확인 시 정확히 1회 실행 (REQ-020)")
        let aiP = fresh()
        let pBase: [String: Any] = ["title": "P-카드", "destination_query": "회사",
                                    "arrival_iso": "2027-03-01T09:00:00"]
        // (a) 부재 집합 → 카드 행 집합. 도착 기준 생성의 부재는 origin·mode·buffer·notify 4개.
        let pa = aiP.drvAsk("create_schedule", pBase)
        aiP.drvCheck("(a) 부재 4개면 카드 행도 4개", pa?.fields.count == 4,
                     "rows=\(pa?.fields.count ?? 0)")
        aiP.drvCheck("(a) 행의 인자가 부재 집합과 정확히 일치",
                     Set(pa?.fields.map(\.key) ?? []) == ["origin_query", "mode_this_time", "buffer_minutes", "notify_lead_minutes"],
                     "keys=\(pa?.fields.map(\.key) ?? [])")
        // 쓰지 않을 값을 물으면 카드만 길어진다 — 출발 기준 구간엔 도착 여유를 둘 대상이 없다(REQ-011).
        let pd0 = aiP.drvAsk("create_schedule", ["title": "P-출발", "destination_query": "회사",
                                                 "origin_query": "집", "departure_iso": "2027-03-01T18:00:00"])
        aiP.drvCheck("(a) 출발 기준은 buffer 행을 만들지 않는다(부재 2 → 행 2)",
                     Set(pd0?.fields.map(\.key) ?? []) == ["mode_this_time", "notify_lead_minutes"],
                     "keys=\(pd0?.fields.map(\.key) ?? [])")

        // (b) 발화로 말한 값의 행은 카드에 없다(REQ-015). fillStated가 실제 경로처럼 채운 뒤 센다.
        let pb = aiP.drvAsk("create_schedule", pBase,
                            stated: AIAssistant.drvStated("지하철로 가고 여유 20분에 알림 30분 전으로 해줘"))
        aiP.drvCheck("(b) 발화 명시 값(mode·buffer·notify)의 행은 빠진다",
                     Set(pb?.fields.map(\.key) ?? []) == ["origin_query"],
                     "keys=\(pb?.fields.map(\.key) ?? [])")
        aiP.drvCheck("(b) 조용히 정해진 값은 카드에 적혀 보인다(줄이 사라진 자리를 사용자가 보게)",
                     pb?.stated.contains("도착 여유 20분") == true && pb?.stated.contains("알림 30분 전") == true,
                     "stated=\(pb?.stated ?? [])")

        // (c) 빈 부재 집합 → 카드 없음 + 툴 직접 실행(REQ-011 후행 절). executeTool까지 태워
        //     missingAskedArguments에 막히지 않고 이벤트가 생기는 것까지 본다.
        //     카드 이후 세계에선 실행부까지 온 호출이 이미 카드(또는 발화)로 값을 받은 상태다 —
        //     모델 인자에 실린 되묻기 값은 정화돼 버려지므로(2026-09-16 결함 D) 발화(stated)로 채운다.
        store.events = []
        let pcBase: [String: Any] = ["title": "P-직접", "destination_query": "회사", "origin_query": "집",
                                     "arrival_iso": "2027-03-01T09:00:00"]
        aiP.drvCheck("(c) 빈 부재 집합 → 카드 없음",
                     aiP.drvAsk("create_schedule", pcBase,
                                stated: AIAssistant.drvStated("도보로 가고 여유 10분에 알림 10분 전으로")) == nil,
                     "카드가 나왔다")
        let pcArgs: [String: Any] = ["title": "P-직접", "destination_query": "회사", "origin_query": "집",
                                     "arrival_iso": "2027-03-01T09:00:00",
                                     "mode_this_time": "walk", "buffer_minutes": 10, "notify_lead_minutes": 10]
        let pcRun = await aiP.drvExecuteTool("create_schedule", pcArgs)
        aiP.drvCheck("(c) 카드 없이 툴이 직접 실행된다", pcRun.hasPrefix("등록 완료"), pcRun)

        // (d) 확인 → 수집한 값을 전부 실은 호출이 정확히 1회(REQ-012). 칩 선택(choose)과 확인의
        //     실행 절반(resolvePendingAsk — confirmAsk가 부르는 그 함수)을 순서대로 탄다.
        //     앱이 호출을 직접 만들므로 선택과 값 사이에 모델이 낄 틈이 없다는 것이 이 경로의 본체다.
        store.events = []
        // buffer는 발화로 들어온다 — 모델 인자의 되묻기 값은 정화돼 버려진다(결함 D).
        let pdAsk = aiP.drvAsk("create_schedule", ["title": "P-확인", "destination_query": "회사",
                                                   "origin_query": "집", "arrival_iso": "2027-03-01T09:00:00"],
                               stated: AIAssistant.drvStated("여유 15분으로 가줘"))
        aiP.drvCheck("(d) 이 호출의 부재는 mode·notify 2개",
                     Set(pdAsk?.fields.map(\.key) ?? []) == ["mode_this_time", "notify_lead_minutes"],
                     "keys=\(pdAsk?.fields.map(\.key) ?? [])")
        aiP.bubbles.append(.init(role: .assistant, text: "", ask: pdAsk))   // runLoop가 띄우는 그 모양
        for f in pdAsk?.fields ?? [] {
            aiP.choose(field: f.id, value: f.kind == .mode ? "car" : "10")   // 칩 value는 원시 문자열
        }
        let pdSummary = await aiP.drvResolvePendingAsk()
        let pdEvent = store.events.first { $0.title == "P-확인" }
        aiP.drvCheck("(d) 확인 시 이벤트가 1건 생긴다", store.events.count == 1,
                     "count=\(store.events.count) summary=\(pdSummary ?? "nil")")
        aiP.drvCheck("(d) 수집한 이동수단이 실린다", pdEvent?.mode == .car,
                     "mode=\(pdEvent?.mode.rawValue ?? "nil")")
        aiP.drvCheck("(d) 수집한 알림이 실린다", pdEvent?.notifyLeadMinutes == 10,
                     "notify=\(pdEvent.map { String($0.notifyLeadMinutes) } ?? "nil")")
        aiP.drvCheck("(d) 말해 둔 buffer(15분)는 그대로 실린다", pdEvent?.bufferMinutes == 15,
                     "buffer=\(pdEvent.map { String($0.bufferMinutes) } ?? "nil")")
        // 카드는 소비됐다 — 두 번째 확인은 nil이고 이벤트도 더 늘지 않는다(1회 보장).
        let twice = await aiP.drvResolvePendingAsk()
        aiP.drvCheck("(d) 두 번째 확인은 아무것도 실행하지 않는다(정확히 1회)",
                     twice == nil && store.events.count == 1,
                     "twice=\(twice ?? "nil") count=\(store.events.count)")

        // (e) 제거된 툴·인자는 선언에 없다(REQ-001·REQ-010). 반대로 갱신 도구의 buffer·notify·
        //     confirm_zero 선언은 그대로 남아 있어야 한다 — 제거가 조용히 확장됐는지도 여기서 드러난다.
        let decls = aiP.drvToolsJSON()
        let names = decls.compactMap { $0["name"] as? String }
        aiP.drvCheck("(e) 툴은 9개다(remember_fact·forget_fact 제거)", names.count == 9,
                     "count=\(names.count): \(names.joined(separator: ","))")
        aiP.drvCheck("(e) remember_fact·forget_fact는 선언에 없다",
                     !names.contains("remember_fact") && !names.contains("forget_fact"),
                     names.joined(separator: ","))
        func declaredParams(_ tool: String) -> Set<String> {
            guard let t = decls.first(where: { $0["name"] as? String == tool }),
                  let props = (t["parameters"] as? [String: Any])?["properties"] as? [String: Any] else { return [] }
            return Set(props.keys)
        }
        let banned: Set<String> = ["mode_this_time", "buffer_minutes", "notify_lead_minutes", "weeks",
                                   "travel_mode_this_time", "return_mode_this_time"]
        for creator in ["create_schedule", "create_recurring_schedule", "create_activity"] {
            aiP.drvCheck("(e) \(creator)에 되묻기 인자 선언이 없다",
                         declaredParams(creator).isDisjoint(with: banned),
                         "남은 것=\(declaredParams(creator).intersection(banned).sorted())")
        }
        aiP.drvCheck("(e) 갱신 도구의 buffer·notify·confirm_zero 선언은 유지된다(확장 금지)",
                     declaredParams("update_recurring_schedule")
                         .isSuperset(of: ["buffer_minutes", "notify_lead_minutes", "confirm_zero"]),
                     "params=\(declaredParams("update_recurring_schedule").sorted())")

        // ── Q. 무기억 회귀(SPEC-ASK-001 REQ-040·REQ-041). 되묻기 상태가 요청 사이·디스크 어디에도
        //      남지 않는다 — 남으면 "저장된 값이 조용히 적용된다"는 b303f41의 사고 형태가 되살아난다.
        //      2026-09-16 결함 B 이후 "요청의 끝"은 발화가 아니라 **툴 실행**이다 — 그 경계를 여기서 잰다.
        print("\nQ. 매번 물음 — 툴 실행 뒤엔 다시 묻는다 (REQ-040·041, 결함 B)")
        let aiQ = fresh()
        let qArgs: [String: Any] = ["title": "Q-매번", "destination_query": "회사",
                                    "arrival_iso": "2027-03-01T09:00:00"]
        let q1 = aiQ.drvAsk("create_schedule", qArgs, stated: AIAssistant.drvStated("자동차로 가고 여유 20분"))
        aiQ.drvCheck("말한 값이 채워진 요청은 mode·buffer를 안 묻는다",
                     Set(q1?.fields.map(\.key) ?? []).isDisjoint(with: ["mode_this_time", "buffer_minutes"]),
                     "keys=\(q1?.fields.map(\.key) ?? [])")
        // 결함 B의 정확한 사고 모양: 모델이 시각을 되묻고 사용자가 "2시, 4시"처럼 아무 값 없이 다시
        // 답한다 — 옛 코드는 statedArgs를 통째로 덮어 써 말해 둔 여유를 증발시켰다. 병합이면 유지된다.
        let q15 = aiQ.drvAsk("create_schedule", qArgs, stated: [:])
        aiQ.drvCheck("값 없는 발화이 끼어도 말해 둔 값은 유지된다(병합)",
                     Set(q15?.fields.map(\.key) ?? []).isDisjoint(with: ["mode_this_time", "buffer_minutes"]),
                     "keys=\(q15?.fields.map(\.key) ?? [])")
        // 같은 키를 다시 말하면 덮어쓰고, 안 말한 키(buffer)는 그대로 — 유지와 갱신이 어긋나면
        // 옛 값이 새 요청을 이긴다.
        _ = aiQ.drvAsk("create_schedule", qArgs, stated: AIAssistant.drvStated("대중교통으로 가줘"))
        aiQ.drvCheck("다시 말한 값은 같은 키만 덮어쓴다(자동차→대중교통, 여유 20 유지)",
                     (aiQ.drvStatedArgs()["mode_this_time"] as? String) == "transit"
                        && (aiQ.drvStatedArgs()["buffer_minutes"] as? Int) == 20,
                     "stated=\(aiQ.drvStatedArgs())")
        // 답을 못 받은 카드가 접히는 것(다른 발화로 무효)은 요청의 끝이 아니다 — 값은 그대로다.
        let qCard0 = aiQ.drvAsk("create_schedule", qArgs)
        aiQ.bubbles.append(.init(role: .assistant, text: "", ask: qCard0))
        aiQ.drvCancelPendingAsk()
        aiQ.drvCheck("카드는 접힌다(다른 발화로 무효)", aiQ.bubbles.last?.ask == nil, "ask가 남아 있다")
        let q17 = aiQ.drvAsk("create_schedule", qArgs)
        aiQ.drvCheck("카드를 접혔어도 값은 유지된다(취소는 지우지 않는다)",
                     Set(q17?.fields.map(\.key) ?? []).isDisjoint(with: ["mode_this_time"]),
                     "keys=\(q17?.fields.map(\.key) ?? [])")
        // REQ-041의 새 경계: 툴이 실행됐다 = 요청이 끝났다. 이후의 요청은 다시 묻는다.
        _ = await aiQ.drvExecuteTool("create_schedule", pcArgs)
        let q2 = aiQ.drvAsk("create_schedule", qArgs)
        aiQ.drvCheck("툴이 실행된 뒤의 요청은 다시 묻는다(요청 사이 기억 없음)",
                     Set(q2?.fields.map(\.key) ?? []).isSuperset(of: ["mode_this_time", "buffer_minutes"]),
                     "keys=\(q2?.fields.map(\.key) ?? [])")
        // 새 대화도 값의 범위 밖이다 — 병합 유지가 옛 대화까지 새어 들어가면 안 된다.
        // resetConversation의 saveHistory는 샌드박스의 ai_history.json에 인사말만 남기는데,
        // init은 히스토리가 비면 스스로 같은 인사말을 붙이므로 파일이 남은 채나 없거나 다음
        // 절의 출발 상태가 같다 — 되돌림은 필요 없다(t10, 파일 백업 9쌍 정리의 마지막 쌍).
        aiQ.resetConversation()
        let q3 = aiQ.drvAsk("create_schedule", qArgs)
        aiQ.drvCheck("새 대화를 시작하면 다시 묻는다(대화 밖 유출 없음)",
                     Set(q3?.fields.map(\.key) ?? []).isSuperset(of: ["mode_this_time", "buffer_minutes"]),
                     "keys=\(q3?.fields.map(\.key) ?? [])")

        // REQ-040: Config에 선호 필드가 부활하면 안 된다(REQ-004). Mirror로 **런타임의** 저장
        // 프로퍼티를 본다 — 소스를 grep하는 게 아니라 이 실행계가 실제 들고 있는 모습이다.
        let configProps = Set(Mirror(reflecting: store.config).children.compactMap { $0.label })
        aiQ.drvCheck("Config에 preferred* 선호 필드가 없다",
                     configProps.isDisjoint(with: ["preferredMode", "preferredBuffer", "preferredNotify"]),
                     "발견=\(configProps.intersection(["preferredMode", "preferredBuffer", "preferredNotify"]).sorted())")

        // REQ-040: 보류 중인 카드는 저장 본문에 어떤 형태로도 남지 않는다. 저장→검사→복원.
        let qCard = aiQ.drvAsk("create_schedule", qArgs, stated: AIAssistant.drvStated("지하철로 가줘"))
        let payload = aiQ.drvPersistedPayload(card: qCard)
        let savedBubbles = payload["bubbles"] as? [[String: Any]] ?? []
        aiQ.drvCheck("보류 카드는 저장되지 않는다(텍스트 말풍선만 남는다)",
                     savedBubbles.count == 1 && (savedBubbles.first?["text"] as? String) == "drv-말풍선",
                     "bubbles=\(savedBubbles)")
        aiQ.drvCheck("저장 본문에 묻는 상태 키가 없다",
                     Set(payload.keys).isDisjoint(with: ["statedArgs", "ask", "pendingAsk", "ai_memory"]),
                     "keys=\(Set(payload.keys).sorted())")

        // ── R. 왕복 의도에서 가는 출발지가 비었을 때(2026-09-16 실기기 결함 A). 모델이
        //      return_to_query만 채우고 travel_from_query를 비워 보내면 옛 코드는 조용히 편도로
        //      만들었다 — 가는 편도, 여유 줄도 없이. 되묻는 주체는 앱이므로 여기서 결정적으로 검증된다.
        print("\nR. 왕복 의도 + 가는 출발지 부재 — 묻고, 편도 탈출이 있다 (결함 A)")
        let rBase: [String: Any] = ["title": "R-왕복", "place_query": "회사",
                                    "start_iso": "2027-03-03T14:00:00", "end_iso": "2027-03-03T18:00:00",
                                    "return_to_query": "집", "travel_from_query": ""]
        let aiR = fresh()
        let rAsk = aiR.drvAsk("create_activity", rBase)
        let rOrigin = rAsk?.fields.first { $0.key == "travel_from_query" }
        aiR.drvCheck("가는 출발지 줄이 나온다", rOrigin != nil,
                     "keys=\(rAsk?.fields.map(\.key) ?? [])")
        aiR.drvCheck("출발지 줄에 '가는 편 없음' 탈출 칩이 있다(내부 토큰)",
                     rOrigin?.options.contains { $0.value == AIAssistant.drvNoOutboundToken() } == true,
                     "options=\(rOrigin?.options.map(\.value) ?? [])")
        aiR.drvCheck("출발지 줄은 originField와 같은 재료다(즐겨찾기·현재 위치·직접입력)",
                     rOrigin?.allowsCustom == true
                        && rOrigin?.options.contains { $0.value == AIAssistant.drvCurrentLocationToken() } == true
                        && rOrigin?.options.contains { $0.value == "집" } == true,
                     "options=\(rOrigin?.options.map(\.value) ?? [])")
        // 출발지를 고르면 왕복이 되므로 카드는 처음부터 왕복 줄(가는 편·오는 편·여유)을 함께
        // 물어둔다 — 한 장 카드는 답에 따라 줄이 늘어날 수 없다.
        aiR.drvCheck("가는 편·오는 편·여유 줄도 같은 카드에 있다",
                     Set(rAsk?.fields.map(\.key) ?? []).isSuperset(
                        of: ["travel_mode_this_time", "return_mode_this_time", "buffer_minutes"]),
                     "keys=\(rAsk?.fields.map(\.key) ?? [])")

        // 진짜 출발지를 고르면 왕복이 만들어진다 — 가는 다리의 여유까지.
        store.events = []
        store.activities = []
        aiR.bubbles.append(.init(role: .assistant, text: "", ask: rAsk))
        for f in rAsk?.fields ?? [] {
            let v: String
            switch f.key {
            case "travel_from_query": v = "집"
            case "travel_mode_this_time": v = "transit"
            case "return_mode_this_time": v = "car"
            case "buffer_minutes": v = "20"
            default: v = "10"
            }
            aiR.choose(field: f.id, value: v)
        }
        let rSummary = await aiR.drvResolvePendingAsk()
        let rActivity = store.activities.first { $0.title == "R-왕복" }
        let rLegs = store.events.filter { $0.linkedActivityId == rActivity?.id }
        aiR.drvCheck("왕복으로 만들어진다(다리 2개)", rActivity != nil && rLegs.count == 2,
                     "legs=\(rLegs.count) summary=\(rSummary ?? "nil")")
        aiR.drvCheck("가는 다리에 고른 여유(20분)가 실린다",
                     rLegs.first { !$0.title.contains("(복귀)") }?.bufferMinutes == 20,
                     "legs=\(rLegs.map { "\($0.title):buf\($0.bufferMinutes)" })")
        aiR.drvCheck("오는 다리는 출발 기준이라 여유가 0이다(기존 규칙 유지)",
                     rLegs.first { $0.title.contains("(복귀)") }?.bufferMinutes == 0,
                     "legs=\(rLegs.map { "\($0.title):buf\($0.bufferMinutes)" })")
        aiR.drvCheck("가는 편=대중교통·오는 편=자동차가 각각 실린다",
                     rLegs.first { !$0.title.contains("(복귀)") }?.mode == .transit
                        && rLegs.first { $0.title.contains("(복귀)") }?.mode == .car,
                     "legs=\(rLegs.map { "\($0.title):\($0.mode.rawValue)" })")

        // "가는 편 없음"으로 답하면 편도(오는 다리만)가 만들어진다 — 빈 값과 같은 뜻으로 풀린다.
        store.events = []
        store.activities = []
        let aiR2 = fresh()
        let r2Ask = aiR2.drvAsk("create_activity", rBase)
        aiR2.bubbles.append(.init(role: .assistant, text: "", ask: r2Ask))
        for f in r2Ask?.fields ?? [] {
            let v: String
            switch f.key {
            case "travel_from_query": v = AIAssistant.drvNoOutboundToken()
            case "travel_mode_this_time": v = "car"
            case "return_mode_this_time": v = "walk"
            case "buffer_minutes": v = "0"
            default: v = "10"
            }
            aiR2.choose(field: f.id, value: v)
        }
        let r2Summary = await aiR2.drvResolvePendingAsk()
        let r2Activity = store.activities.first { $0.title == "R-왕복" }
        let r2Legs = store.events.filter { $0.linkedActivityId == r2Activity?.id }
        aiR2.drvCheck("편도로 만들어진다(오는 다리만 1개)", r2Activity != nil && r2Legs.count == 1,
                      "legs=\(r2Legs.count) summary=\(r2Summary ?? "nil")")
        aiR2.drvCheck("그 다리는 오는 편(복귀)이고 고른 수단(도보)이다",
                      r2Legs.first?.title.contains("(복귀)") == true && r2Legs.first?.mode == .walk,
                      "legs=\(r2Legs.map { "\($0.title):\($0.mode.rawValue)" })")
        aiR2.drvCheck("요약에 생기지 않은 가는 편을 말하지 않는다",
                      r2Summary?.contains("가는 편") == false, r2Summary ?? "nil")

        // 선언 대칭(결함 A 1차 방어): 가는 출발지 설명에도 왕복 의무가 적혀 있다 — 옛 설명은
        // return_to_query 쪽에만 경고가 있어 모델이 그대로 한쪽만 챙겼다.
        let rTool = decls.first { $0["name"] as? String == "create_activity" }
        let rProps = ((rTool?["parameters"] as? [String: Any])?["properties"] as? [String: Any]) ?? [:]
        let rDescText = (rProps["travel_from_query"] as? [String: Any])?["description"] as? String ?? ""
        aiR2.drvCheck("travel_from_query 선언이 왕복 의무를 말한다(return_to_query와 대칭)",
                     rDescText.contains("왕복") && rDescText.contains("안 만들어진다"), rDescText)

        // ── S. 묻지 않은 on_conflict(2026-09-16 실기기 결함 C). 이 모델은 enum이 붙은 선택
        //      인자를 비우지 못해 첫 호출에도 on_conflict를 실어 보낸다(전사에서 세 건 전부
        //      "ignore"). 그게 통과하면 겹침 검사가 통째로 건너뛰어진다 — confirm_recurrence·
        //      confirm_zero와 같은 규칙으로, 앱이 실제로 물은 조합의 재호출만 답으로 인정한다.
        print("\nS. 묻지 않은 on_conflict — 겹침 검사는 항상 돈다 (결함 C)")
        let sCal = Calendar.current
        func sDay(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ _min: Int) -> Date {
            sCal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: _min))!
        }
        // 전제: 이동시간 조회가 되어야 겹침 검사가 돈다(실패하면 실행부가 검사를 건너뛴다). nil이면
        // S절 전체가 무의미하니 여기서 빨개져 알린다 — 조용히 건너뛰는 건 거짓 초록이다.
        // 도보로 잰다: 도보 추정은 MapKit 단독이라(프록시·키를 안 탄다) 반복 호출에도 값이 흔들리지
        // 않는다. 대중교통은 프록시(ODsay) 경유라 앞절들이 쌓아둔 호출 탓에 실패할 수 있어, 그걸 쓰면
        // S절이 네트워크 상태에 좌우된다.
        let aiS = fresh()
        let sSeconds = await store.travelSeconds(
            from: store.favorites.first { $0.label == "집" }?.place ?? Place(name: "집", address: "", latitude: 37.500, longitude: 127.000),
            to: store.favorites.first { $0.label == "회사" }?.place ?? Place(name: "회사", address: "", latitude: 37.510, longitude: 127.010),
            mode: .walk)
        aiS.drvCheck("S 전제 — 이 환경에서 이동시간 조회가 된다", sSeconds != nil,
                     "seconds=nil — 겹침 검사가 돌지 않는다(네트워크·좌표 확인)")
        // C1: 그 날 하루 종일 활동이 있는데, 묻지도 않은 on_conflict:"ignore"를 달고 온 첫 호출.
        //     (활동 블록으로 겹침을 만든다 — conflicts가 이동시간 없는 이벤트는 건너뛰기 때문이다.)
        store.events = []
        store.activities = [ActivityBlock(title: "S-하루종일", location: nil,
                                          startDate: sDay(2027, 3, 1, 0, 0),
                                          endDate: sDay(2027, 3, 1, 23, 59), recurrenceId: nil)]
        let sArgs: [String: Any] = ["title": "S-겹침", "destination_query": "회사", "origin_query": "집",
                                    "arrival_iso": "2027-03-01T09:00:00", "mode_this_time": "walk",
                                    "buffer_minutes": 0, "notify_lead_minutes": 10,
                                    "on_conflict": "ignore"]
        let s1 = await aiS.drvCreate(sArgs)
        aiS.drvCheck("C1: 묻지 않은 ignore는 무시되고 겹침 안내가 나온다",
                     s1.contains("아직 등록하지 않았어요") && s1.contains("겹칩니다"), s1)
        aiS.drvCheck("C1: 등록은 일어나지 않는다",
                     !store.events.contains { $0.title == "S-겹침" },
                     "events=\(store.events.filter { $0.title == "S-겹침" }.count)")
        // C2: 앱이 물은 뒤 같은 인자로 다시 온 ignore는 답으로 인정돼 정확히 1건 등록된다.
        let s2 = await aiS.drvCreate(sArgs)
        let s2Count = store.events.filter { $0.title == "S-겹침" }.count
        aiS.drvCheck("C2: 물은 뒤의 ignore는 통과해 정확히 1건 등록된다",
                     s2.hasPrefix("등록 완료") && s2Count == 1, "count=\(s2Count) result=\(s2)")
        // C3: late_arrival도 같다 — 묻지 않으면 무시(그래서 안내가 나오고), 물은 뒤에는 출발
        //     기준 전환으로 이어진다. 소비도 본다: C2의 등록이 확인을 소진했으므로 C3의 첫 호출은
        //     다시 '안 물은' 상태에서 시작된다.
        store.events = []
        store.activities = [ActivityBlock(title: "S-오전", location: nil,
                                          startDate: sDay(2027, 3, 2, 8, 0),
                                          endDate: sDay(2027, 3, 2, 10, 0), recurrenceId: nil)]
        let s3Args: [String: Any] = ["title": "S-늦게", "destination_query": "회사", "origin_query": "집",
                                     "arrival_iso": "2027-03-02T09:00:00", "mode_this_time": "walk",
                                     "buffer_minutes": 0, "notify_lead_minutes": 10,
                                     "on_conflict": "late_arrival"]
        let s3a = await aiS.drvCreate(s3Args)
        aiS.drvCheck("C3: 묻지 않은 late_arrival도 무시되고 겹침 안내가 나온다",
                     s3a.contains("아직 등록하지 않았어요"), s3a)
        let s3b = await aiS.drvCreate(s3Args)
        let s3Event = store.events.first { $0.title == "S-늦게" }
        aiS.drvCheck("C3: 물은 뒤의 late_arrival은 출발 기준으로 바꿔 등록된다",
                     s3b.hasPrefix("등록 완료") && s3Event?.anchor == .departure,
                     "result=\(s3b) anchor=\(String(describing: s3Event?.anchor))")
        aiS.drvCheck("C3: 출발 시각은 겹침이 끝난 10:00에 맞춰진다",
                     s3Event.map { sCal.isDate($0.departureDate ?? .distantPast,
                                              equalTo: sDay(2027, 3, 2, 10, 0), toGranularity: .minute) } == true,
                     "dep=\(s3Event?.departureDate.map { "\($0)" } ?? "nil")")

        // ── T. 선언 밖 모델 인자 정화(2026-09-16 실기기 결함 D). 이 모델은 선언에서 뺀 인자도
        //      얹어 보낸다(전사 — 없는 mode_this_time·buffer_minutes·notify_lead_minutes·weeks가
        //      카드를 우회해 사용자가 고르지 않은 값으로 118건을 등록했다). 도착한 인자에서 선언
        //      밖 키를 버린다 — 화이트리스트는 선언 자체에서 구하므로 두 벌이 어긋날 수 없다.
        print("\nT. 선언 밖 모델 인자 — 버리고 카드가 묻는다 (결함 D)")
        let aiT = fresh()
        // D1: 반복 생성 — 모델이 되묻기 인자 넷을 몽땅 실어도 카드는 5줄(출발지·수단·여유·알림·기간).
        let t1 = aiT.drvAsk("create_recurring_schedule",
                            ["title": "T-반복", "destination_query": "회사",
                             "weekdays": ["mon", "tue", "wed", "thu", "fri"],
                             "arrival_time": "09:00", "return_time": "18:00",
                             "mode_this_time": "car", "buffer_minutes": 10,
                             "notify_lead_minutes": 10, "weeks": 8])
        aiT.drvCheck("D1: 카드가 나온다(출발지·수단·여유·알림·기간 5줄)",
                     Set(t1?.fields.map(\.key) ?? []) == ["origin_query", "mode_this_time", "buffer_minutes",
                                                          "notify_lead_minutes", "weeks"],
                     "keys=\(t1?.fields.map(\.key) ?? [])")
        aiT.drvCheck("D1: 모델이 실은 값은 카드가 붙잡은 호출에 없다",
                     Set(AIAssistant.drvCallArgs(t1).keys)
                        .isDisjoint(with: ["mode_this_time", "buffer_minutes", "notify_lead_minutes", "weeks"]),
                     "args=\(AIAssistant.drvCallArgs(t1).keys.sorted())")
        // D2: 단발·활동도 같다.
        let t2 = aiT.drvAsk("create_schedule",
                            ["title": "T-단발", "destination_query": "회사",
                             "arrival_iso": "2027-03-05T09:00:00",
                             "mode_this_time": "car", "buffer_minutes": 10, "notify_lead_minutes": 10])
        aiT.drvCheck("D2: create_schedule도 수단·여유·알림을 다시 묻는다",
                     Set(t2?.fields.map(\.key) ?? []) == ["origin_query", "mode_this_time",
                                                          "buffer_minutes", "notify_lead_minutes"],
                     "keys=\(t2?.fields.map(\.key) ?? [])")
        let t3 = aiT.drvAsk("create_activity",
                            ["title": "T-활동", "place_query": "회사",
                             "start_iso": "2027-03-05T14:00:00", "end_iso": "2027-03-05T18:00:00",
                             "travel_from_query": "집", "return_to_query": "집",
                             "mode_this_time": "car", "travel_mode_this_time": "car",
                             "return_mode_this_time": "car", "buffer_minutes": 10,
                             "notify_lead_minutes": 10])
        aiT.drvCheck("D2: create_activity도 가는 편·오는 편·여유·알림을 다시 묻는다",
                     Set(t3?.fields.map(\.key) ?? []) == ["travel_mode_this_time", "return_mode_this_time",
                                                          "buffer_minutes", "notify_lead_minutes"],
                     "keys=\(t3?.fields.map(\.key) ?? [])")
        aiT.drvCheck("D2: 활동 쪽 모델 값 다섯도 정화된다",
                     Set(AIAssistant.drvCallArgs(t3).keys)
                        .isDisjoint(with: ["mode_this_time", "travel_mode_this_time",
                                           "return_mode_this_time", "buffer_minutes", "notify_lead_minutes"]),
                     "args=\(AIAssistant.drvCallArgs(t3).keys.sorted())")
        // 순서: 정화 **뒤에** 발화값이 얹힌다 — 같은 키에서 부딪히면 사용자가 말한 값이 이긴다.
        let t4 = aiT.drvAsk("create_schedule",
                            ["title": "T-순서", "destination_query": "회사",
                             "arrival_iso": "2027-03-05T09:00:00",
                             "mode_this_time": "car", "buffer_minutes": 10, "notify_lead_minutes": 10],
                            stated: AIAssistant.drvStated("대중교통으로 가고 여유 20분"))
        aiT.drvCheck("모델값과 말한 값이 부딪히면 말한 값이 살아남는다(정화 → 발화 주입 순서)",
                     (AIAssistant.drvCallArgs(t4)["mode_this_time"] as? String) == "transit"
                        && (AIAssistant.drvCallArgs(t4)["buffer_minutes"] as? Int) == 20,
                     "args=\(AIAssistant.drvCallArgs(t4))")
        // D3: 갱신 도구는 선언된 mode·buffer·notify를 계속 받는다 — 정화의 화이트리스트가 선언에서
        //     오므로 깨질 수 없다는 것을 실행계가 든 키로 확인하고, 실제 저장값도 본다.
        //     confirm_zero 왕복은 B·N절이 계속 지킨다(여기서 중복하지 않는다).
        aiT.drvCheck("D3: 갱신 도구는 mode·buffer·notify·confirm_zero를 계속 받는다",
                     aiT.drvModelKeys("update_recurring_schedule")
                        .isSuperset(of: ["mode", "buffer_minutes", "notify_lead_minutes", "confirm_zero"]),
                     "keys=\(aiT.drvModelKeys("update_recurring_schedule").sorted())")
        let ridT = UUID()
        store.events = [AIAssistant.drvLeg(ridT, title: "T-수정", hours: 48)]
        store.activities = []
        let aiT3 = fresh()
        _ = aiT3.drvList()   // ridT에 [반복 1] 배정
        let t3u = await aiT3.drvUpdate(["series_number": 1, "buffer_minutes": 20])
        let bufT = store.events.first { $0.recurrenceId == ridT }?.bufferMinutes
        aiT3.drvCheck("D3: update_recurring_schedule의 buffer 20은 그대로 저장된다",
                      bufT == 20, "buffer=\(bufT.map(String.init) ?? "nil") result=\(t3u)")
        // D4: 드리프트 가드 — (e)절이 선언 파일 모습을 본다면 여기는 실행계의 화이트리스트를 본다.
        //     되묻기 인자를 다시 선언에 넣는 순간 정화가 조용히 풀리므로 두 쪽 다 잡는다.
        let cardOwned: [String: Set<String>] = [
            "create_schedule": ["mode_this_time", "buffer_minutes", "notify_lead_minutes"],
            "create_recurring_schedule": ["mode_this_time", "buffer_minutes", "notify_lead_minutes", "weeks"],
            "create_activity": ["mode_this_time", "travel_mode_this_time", "return_mode_this_time",
                                "buffer_minutes", "notify_lead_minutes"]]
        for (tool, banned) in cardOwned {
            aiT3.drvCheck("D4: \(tool) 화이트리스트에 되묻기 인자가 없다(선언=SSOT)",
                         aiT3.drvModelKeys(tool).isDisjoint(with: banned),
                         "keys=\(aiT3.drvModelKeys(tool).sorted())")
        }

        // ── U. E·F 프롬프트 규칙 — **문자열 존재 확인일 뿐, 행동 검증이 아니다.** 드라이버는
        //      모델 없이 돌므로 "지시를 모델이 지키는가"는 여기서 볼 수 없다(실기기 관찰 항목).
        //      잡는 것은 한 가지뿐이다: 프롬프트가 다시 압축되며 두 규칙이 조용히 사라지는 것.
        print("\nU. E·F 프롬프트 규칙 — 문자열 존재만 확인 (행동 검증 아님)")
        let uPrompt = aiT3.drvSystemPrompt()
        aiT3.drvCheck("E: 출발지 규칙이 '지어내서 채우면 안 된다'와 결과를 적시한다(문자열 존재)",
                      uPrompt.contains("지어내서 채우면 안 된다")
                        && uPrompt.contains("둘 다 사용자가 직접 고를 기회를 없앤다"),
                      "규칙 3 원문 확인")
        aiT3.drvCheck("F: 기억 요청에 '미래 약속 금지'와 매번 물음 이유가 있다(문자열 존재)",
                      uPrompt.contains("미래 약속을 하지 마라")
                        && uPrompt.contains("매번 다시 물어본다"),
                      "규칙 7 원문 확인")

        // ── V. 카드 확장 ① — 제목·목적지·시각 줄(2026-09-16). required를 비워야 모델이 비울 수
        //      있고, 비워야 줄이 뜬다. 시각 값은 "arr:"/"dep:" 접두 + ISO로 직렬화되고, 기준은
        //      사용자가 반드시 고른다(미리 골라두지 않는다 — 확인 버튼이 그대로 잠긴다).
        print("\nV. 카드 확장 — 제목·목적지·시각 줄 (①)")
        let vDate = sCal.date(from: DateComponents(year: 2027, month: 3, day: 8, hour: 15, minute: 0))
        let aiV = fresh()
        // ①-1: 세 값이 모두 빈 호출 → 일곱 줄. 기준 미선택(=시각 미확정)이면 확인 불가.
        let v1 = aiV.drvAsk("create_schedule", [:])
        aiV.drvCheck("①-1: 제목·목적지·시각이 비면 카드가 7줄로 뜬다",
                     Set(v1?.fields.map(\.key) ?? []) == ["title", "destination_query", "origin_query",
                                                          "arrival_iso", "mode_this_time",
                                                          "buffer_minutes", "notify_lead_minutes"],
                     "keys=\(v1?.fields.map(\.key) ?? [])")
        aiV.drvCheck("①-1: 아무것도 고르지 않으면 확인이 불가하다",
                     v1?.isReady == false, "isReady가 true다")
        aiV.bubbles.append(.init(role: .assistant, text: "", ask: v1))
        for f in v1?.fields ?? [] where f.kind != .datetime {
            switch f.key {
            case "title": _ = aiV.submitCustom(field: f.id, text: "V-카드")   // 제목도 accepts 경로로
            case "destination_query": aiV.choose(field: f.id, value: "회사")
            case "origin_query": aiV.choose(field: f.id, value: "집")
            case "mode_this_time": aiV.choose(field: f.id, value: "transit")
            case "buffer_minutes": aiV.choose(field: f.id, value: "10")
            default: aiV.choose(field: f.id, value: "10")
            }
        }
        aiV.drvCheck("①-1: 시각 외 여섯을 다 골라도 확인은 불가하다(기준·시각 모두 필수)",
                     aiV.drvLiveAsk()?.isReady == false, "isReady가 true다")
        // ①-2: 기준+시각 확정 → 확인 가능, 실행 호출에는 arrival·departure 중 정확히 하나.
        let vTime = v1?.fields.first { $0.kind == .datetime }
        var vTimeChosen = false
        if let vTime, let vDate { vTimeChosen = aiV.chooseTime(field: vTime.id, basis: .arrival, date: vDate) }
        aiV.drvCheck("①-2: 기준+시각 확정으로 확인 가능해진다(chooseTime)",
                     vTimeChosen && (aiV.drvLiveAsk()?.isReady ?? false),
                     "chooseTime=\(vTimeChosen)")
        let vSummary = await aiV.drvResolvePendingAsk()
        let vArgs = aiV.drvLastCallArgs()
        let vEvent = store.events.first { $0.title == "V-카드" }
        aiV.drvCheck("①-2: arrival_iso만 실린다(departure_iso는 없음)",
                     vArgs["arrival_iso"] != nil && vArgs["departure_iso"] == nil,
                     "args=\(vArgs.keys.sorted())")
        aiV.drvCheck("①-2: 확정 시각 그대로 1회 실행된다",
                     store.events.filter { $0.title == "V-카드" }.count == 1
                        && vEvent != nil && vDate != nil
                        && sCal.isDate(vEvent!.arrivalDate, equalTo: vDate!, toGranularity: .minute),
                     "count=\(store.events.filter { $0.title == "V-카드" }.count) summary=\(vSummary ?? "nil")")
        // ①-3: 출발 기준 — 여유는 골라도 실리지 않는다(chosen은 남아 교착 없음).
        store.events = []
        let aiV2 = fresh()
        let v2Ask = aiV2.drvAsk("create_schedule", [:])
        aiV2.bubbles.append(.init(role: .assistant, text: "", ask: v2Ask))
        for f in v2Ask?.fields ?? [] where f.kind != .datetime {
            switch f.key {
            case "title": _ = aiV2.submitCustom(field: f.id, text: "V-출발")
            case "destination_query": aiV2.choose(field: f.id, value: "회사")
            case "origin_query": aiV2.choose(field: f.id, value: "집")
            case "mode_this_time": aiV2.choose(field: f.id, value: "transit")
            case "buffer_minutes": aiV2.choose(field: f.id, value: "20")   // 출발 기준이라 실리면 안 됨
            default: aiV2.choose(field: f.id, value: "10")
            }
        }
        let v2Time = v2Ask?.fields.first { $0.kind == .datetime }
        if let v2Time, let vDate { _ = aiV2.chooseTime(field: v2Time.id, basis: .departure, date: vDate) }
        aiV2.drvCheck("①-3: 출발 기준+여유를 골라도 확인 가능하다(여유 chosen 유지 — 교착 없음)",
                      aiV2.drvLiveAsk()?.isReady == true, "isReady가 false다")
        _ = await aiV2.drvResolvePendingAsk()
        let v2Args = aiV2.drvLastCallArgs()
        let v2Event = store.events.first { $0.title == "V-출발" }
        aiV2.drvCheck("①-3: departure_iso만 실리고 arrival_iso는 없다",
                      v2Args["departure_iso"] != nil && v2Args["arrival_iso"] == nil,
                      "args=\(v2Args.keys.sorted())")
        aiV2.drvCheck("①-3: 출발 기준에는 buffer_minutes가 실리지 않는다",
                      v2Args["buffer_minutes"] == nil, "args=\(v2Args.keys.sorted())")
        aiV2.drvCheck("①-3: 출발 기준 이벤트로 등록된다(anchor=departure, buffer 0)",
                      v2Event?.anchor == .departure && v2Event?.bufferMinutes == 0,
                      "anchor=\(String(describing: v2Event?.anchor)) buffer=\(v2Event.map { String($0.bufferMinutes) } ?? "nil")")
        // ①-4: 드리프트 가드 — required에 다시 들어가면 줄이 영영 안 뜬다.
        let vToolV = decls.first { $0["name"] as? String == "create_schedule" }
        let vReq = ((vToolV?["parameters"] as? [String: Any])?["required"] as? [String]) ?? []
        aiV2.drvCheck("①-4: create_schedule required에 title·destination_query가 없다",
                     !vReq.contains("title") && !vReq.contains("destination_query"),
                     "required=\(vReq)")
        // 모델이 채워온 제목·목적지는 출처가 드러나게 카드에 보인다(최소 방어).
        let v3 = aiV2.drvAsk("create_schedule", ["title": "V-출처", "destination_query": "회사",
                                                 "arrival_iso": "2027-03-09T09:00:00"])
        aiV2.drvCheck("모델이 채워온 제목·목적지는 카드에 보인다",
                      v3?.stated.contains("제목 'V-출처'") == true && v3?.stated.contains("목적지 '회사'") == true,
                      "stated=\(v3?.stated ?? [])")
        aiV2.drvCheck("프롬프트가 목적지·제목 지어내기 금지를 적시한다(문자열 존재 — 행동 검증 아님)",
                      aiV2.drvSystemPrompt().contains("목적지·제목도 같다"), "규칙 3 원문 확인")

        // ── W. 빈 문자열 시각·비상한 종료일(2026-09-16 코드 검사 발견). 이 모델은 "비움"을 빈
        //      문자열로 실어 보내는 경우가 있다 — 시각 유무를 nil로만 판정하면 시각 줄이 영영 안 뜨고
        //      확인 뒤에야 실행부가 parseDate에서 걸러 모델에게 되물게 한다(카드가 물어야 한다).
        //      종료일은 end_iso에 상한이 없어(9999년도 parseDate를 통과한다) activities의 didSet 안
        //      걷기가 비한정이 되는 것을 366일 상한으로 막는다 — 점 개수로 그 상한을 직접 본다.
        print("\nW. 빈 문자열 시각·비상한 종료일 상한 (2026-09-16 코드 검사)")
        let wAsk = aiV2.drvAsk("create_schedule", ["title": "W-빈시각", "destination_query": "회사",
                                                   "arrival_iso": ""])
        aiV2.drvCheck("W1: arrival_iso가 빈 문자열이면 시각 줄이 뜬다(nil이 아니어도 '비었다')",
                      wAsk?.fields.contains { $0.kind == .datetime } == true,
                      "keys=\(wAsk?.fields.map(\.key) ?? [])")
        store.events = []
        store.activities = [ActivityBlock(title: "W-9999년", location: nil,
                                          startDate: sDay(2027, 3, 10, 9, 0),
                                          endDate: sDay(9999, 1, 1, 0, 0), recurrenceId: nil)]
        aiV2.drvCheck("W2: 종료일이 비상하게 길어도 점은 상한(366일) 안에서 끝난다",
                      store.daysWithSchedule.count <= 366,
                      "dots=\(store.daysWithSchedule.count)")
        // W3: 같은 상한이 생성 시점에서도 거른다 — 걷기 상한만으로는 "점이 잘린 채 저장된 활동"이
        //     남는다. create_activity는 출발지·복귀지를 안 넣으면 카드 줄이 없어 바로 실행에 닿는다.
        store.activities = []
        let w3Reject = await aiV2.drvExecuteTool("create_activity",
                                                 ["title": "W-3년짜리", "start_iso": "2027-03-10T09:00:00",
                                                  "end_iso": "2030-03-10T09:00:00"])
        aiV2.drvCheck("W3: 366일을 넘는 활동은 만들어지지 않고 사용자 확인을 요청한다",
                      w3Reject.contains("아직 만들지 않았어요") && store.activities.isEmpty,
                      "reply=\(w3Reject) count=\(store.activities.count)")
        let w3Made = await aiV2.drvExecuteTool("create_activity",
                                               ["title": "W-하룻밤", "start_iso": "2027-03-10T18:00:00",
                                                "end_iso": "2027-03-11T04:00:00"])
        aiV2.drvCheck("W3: 정상 길이(자정 넘김 하룻밤) 활동은 그대로 만들어진다",
                      w3Made.contains("등록 완료") && store.activities.count == 1,
                      "reply=\(w3Made) count=\(store.activities.count)")
        aiV2.drvCheck("W3: 만들어진 자정 넘김 활동의 점은 이틀에 켜진다(생성 경로 종단)",
                      store.daysWithSchedule == [Store.dayKey(sDay(2027, 3, 10, 0, 0), calendar: sCal),
                                                 Store.dayKey(sDay(2027, 3, 11, 0, 0), calendar: sCal)],
                      "dots=\(store.daysWithSchedule.sorted())")

        // ── X. 자정 겹침 판정 자체 — overlapsDay·dayKeys·recomputeDaysWithSchedule이 같은 날을
        //      내는지 잰다(결함 G·G-2). ⚠️ 여기서 재는 건 "어느 날에 나열되고 점이 켜지는가"까지다.
        //      블록을 그 날의 0~1440분으로 자르는 산술(span(for:on:))은 ContentView.swift에 있어
        //      드라이버가 컴파일하지 못한다 — 잘림 높이·최소 높이 늘림 방향은 여전히 실기기 확인
        //      영역이고, 이 절의 초록이 그 커버리지를 입증하지 않는다.
        print("\nX. 자정 겹침 판정 — 나열과 점이 같은 날을 본다 (결함 G·G-2)")
        // X1: 22:00 → 익일 04:00 — 두 날 모두, 그 앞·뒤 날과는 아니다.
        let x1s = sDay(2027, 3, 10, 22, 0), x1e = sDay(2027, 3, 11, 4, 0)
        aiV2.drvCheck("X1: 자정 넘김(22:00→익일 04:00)은 두 날 모두와 겹친다",
                      (10...11).allSatisfy { Store.overlapsDay(start: x1s, end: x1e, day: sDay(2027, 3, $0, 0, 0), calendar: sCal) },
                      "출발일·도착일 판정이 거짓")
        aiV2.drvCheck("X1: 그 앞·뒤 날과는 겹치지 않는다(과잉 나열이 이웃 날을 오염한다)",
                      !Store.overlapsDay(start: x1s, end: x1e, day: sDay(2027, 3, 9, 0, 0), calendar: sCal)
                      && !Store.overlapsDay(start: x1s, end: x1e, day: sDay(2027, 3, 12, 0, 0), calendar: sCal),
                      "이웃 날이 켜졌다")
        // X2: 자정을 두 번 넘으면 세 날 모두.
        let x2s = sDay(2027, 3, 10, 22, 0), x2e = sDay(2027, 3, 12, 2, 0)
        aiV2.drvCheck("X2: 자정을 두 번 넘는 구간(10일 22:00→12일 02:00)은 세 날 모두와 겹친다",
                      (8...9).allSatisfy { !Store.overlapsDay(start: x2s, end: x2e, day: sDay(2027, 3, $0, 0, 0), calendar: sCal) }
                      && (10...12).allSatisfy { Store.overlapsDay(start: x2s, end: x2e, day: sDay(2027, 3, $0, 0, 0), calendar: sCal) }
                      && !Store.overlapsDay(start: x2s, end: x2e, day: sDay(2027, 3, 13, 0, 0), calendar: sCal),
                      "가운데 날이 빠졌거나 이웃 날이 켜졌다")
        // X3: 경계 소유권 — 반열린 [start, end)라는 규칙 그 자체.
        aiV2.drvCheck("X3: 정확히 0시에 끝나는 구간은 다음 날과 겹치지 않는다",
                      Store.overlapsDay(start: x1s, end: sDay(2027, 3, 11, 0, 0), day: sDay(2027, 3, 10, 0, 0), calendar: sCal)
                      && !Store.overlapsDay(start: x1s, end: sDay(2027, 3, 11, 0, 0), day: sDay(2027, 3, 11, 0, 0), calendar: sCal),
                      "끝 날이 켜졌다")
        aiV2.drvCheck("X3: 정확히 0시에 시작하는 구간은 전날과 겹치지 않는다",
                      Store.overlapsDay(start: sDay(2027, 3, 11, 0, 0), end: x1e, day: sDay(2027, 3, 11, 0, 0), calendar: sCal)
                      && !Store.overlapsDay(start: sDay(2027, 3, 11, 0, 0), end: x1e, day: sDay(2027, 3, 10, 0, 0), calendar: sCal),
                      "전날이 켜졌다")
        // X4: 깨진 구간 — 호출자 폴백(앵커 날 하루)과 짝이 되는 판정.
        aiV2.drvCheck("X4: end ≤ start인 깨진 구간은 어느 날과도 겹치지 않는다",
                      !Store.overlapsDay(start: x1e, end: x1s, day: sDay(2027, 3, 10, 0, 0), calendar: sCal)
                      && !Store.overlapsDay(start: x1s, end: x1s, day: sDay(2027, 3, 10, 0, 0), calendar: sCal),
                      "깨진 구간이 켜졌다")
        // X5: dayKeys 열거가 overlapsDay 판정과 같은 집합을 내는지 직접 잰다(계약 5 — 두 경로가
        //     갈라지면 월간 점과 일간 나열이 다시 어긋난다). 후보 창을 구간보다 넓게(±5일) 잡아
        //     창 경계에서 어긋나는 것도 잡는다.
        let x5Days = (5...15).compactMap { sCal.date(from: DateComponents(year: 2027, month: 3, day: $0)) }
        func x5ByPredicate(_ s: Date, _ e: Date) -> Set<Int> {
            Set(x5Days.filter { Store.overlapsDay(start: s, end: e, day: $0, calendar: sCal) }
                      .map { Store.dayKey($0, calendar: sCal) })
        }
        aiV2.drvCheck("X5: dayKeys 열거 = overlapsDay 판정(두 번 넘는 구간에서 같은 집합)",
                      Set(Store.dayKeys(start: x2s, end: x2e, calendar: sCal)) == x5ByPredicate(x2s, x2e),
                      "keys=\(Store.dayKeys(start: x2s, end: x2e, calendar: sCal).sorted()) predicate=\(x5ByPredicate(x2s, x2e).sorted())")
        aiV2.drvCheck("X5: 0시 경계 구간도 열거·판정이 같다(키는 하루뿐)",
                      Set(Store.dayKeys(start: x1s, end: sDay(2027, 3, 11, 0, 0), calendar: sCal)) == x5ByPredicate(x1s, sDay(2027, 3, 11, 0, 0))
                      && Store.dayKeys(start: x1s, end: sDay(2027, 3, 11, 0, 0), calendar: sCal).count == 1,
                      "keys=\(Store.dayKeys(start: x1s, end: sDay(2027, 3, 11, 0, 0), calendar: sCal).sorted())")
        // X6: recomputeDaysWithSchedule이 실제 배열 대입에서 양쪽 날 키를 넣는다(G-2 본체 — 월간
        //     점과 일간 나열이 같은 말을 한다). 이동은 [출발, 도착), 계산 실패는 도착일 하루.
        store.events = []; store.activities = []
        let x6p = Place(name: "곳", address: "주소", latitude: 37.5, longitude: 127.0)
        var x6Event = ScheduledEvent(title: "X-이동", origin: x6p, destination: x6p,
                                     arrivalDate: x1e, mode: .transit, bufferMinutes: 10,
                                     notifyLeadMinutes: 10, recurrenceId: nil, anchor: .arrival)
        x6Event.departureDate = x1s
        store.events = [x6Event]
        aiV2.drvCheck("X6: 자정 넘는 이동(22:00 출발→익일 04:00 도착)도 두 날 모두 점이 켜진다",
                      store.daysWithSchedule == [Store.dayKey(sDay(2027, 3, 10, 0, 0), calendar: sCal),
                                                 Store.dayKey(sDay(2027, 3, 11, 0, 0), calendar: sCal)],
                      "dots=\(store.daysWithSchedule.sorted())")
        x6Event.departureDate = nil   // 계산 실패 형태 — 구간이 없으니 도착일 하루만
        store.events = [x6Event]
        aiV2.drvCheck("X6: 출발시각이 없는(계산 실패) 이동은 도착일에만 점이 켜진다",
                      store.daysWithSchedule == [Store.dayKey(sDay(2027, 3, 11, 0, 0), calendar: sCal)],
                      "dots=\(store.daysWithSchedule.sorted())")

        // ── J. 등록 요약은 방금 만든 회차의 시각을 말한다(2026-09-16 결함 J). addEvent가 도착일순
        //      정렬하므로 제목·목적지로 `.last` 되찾기하면 '매치 중 도착이 가장 늦은 것'— 같은 이름의
        //      늦은 회차—를 집어 요약이 남의 시각을 알렸다. 같은 제목·같은 목적지가 설계상 자연스러워진
        //      지금(① 카드가 제목을 직접 받는다) 잠자던 위험이 깨어난 자리다.
        //      출발지·목적지는 즐겨찾기 정확 매치로 풀리고(S절과 같은 도보 추정) 이동시간은 MapKit
        //      단독이라 결정적으로 돈다. addEvent의 save는 events.json에 쓰지만 t8부터 드라이버의
        //      모든 쓰기는 샌드박스 안에 떨어진다 — 되돌림은 필요 없고, 실제 데이터는 종료 시
        //      바이트 대조(drvFinishOnce → drvDiffSupportDir)가 한 번으로 지킨다.
        print("\nJ. 등록 요약 — 같은 이름의 늦은 회차가 있어도 방금 만든 것을 말한다 (결함 J)")
        let aiJ2 = fresh()
        store.favorites = [FavoritePlace(label: "집", place: Place(name: "집", address: "", latitude: 37.47, longitude: 126.95)),
                           FavoritePlace(label: "J-강남역", place: Place(name: "J-강남역", address: "", latitude: 37.498, longitude: 127.028))]
        // 전제: 같은 제목·같은 목적지의 '늦은 회차'(금요일 18시 도착, 출발시각·이동시간 있음)가 이미
        // 있다 — 예전 코드라면 `.last {매치}`가 이쪽을 집어 금요일 시각을 알렸다.
        var jOld = ScheduledEvent(title: "J-강남역", origin: nil, destination: store.favorites[1].place,
                                  arrivalDate: sDay(2027, 3, 12, 18, 0), mode: .walk, bufferMinutes: 10,
                                  notifyLeadMinutes: 20, recurrenceId: nil, anchor: .arrival)
        jOld.departureDate = sDay(2027, 3, 12, 17, 0)
        jOld.travelSeconds = 3600
        store.events = [jOld]
        let jReply = await aiJ2.drvExecuteTool("create_schedule",
                                              ["title": "J-강남역", "destination_query": "J-강남역",
                                               "origin_query": "집", "arrival_iso": "2027-03-10T15:00:00",
                                               "mode_this_time": "walk", "buffer_minutes": 10,
                                               "notify_lead_minutes": 20])
        aiJ2.drvCheck("J: 등록이 성공하고 이동시간도 계산됐다(전제 — 빨개지면 환경 변화 신호)",
                     jReply.contains("등록 완료") && !jReply.contains("⚠️")
                     && store.events.contains { $0.arrivalDate == sDay(2027, 3, 10, 15, 0) },
                     "reply=\(jReply)")
        aiJ2.drvCheck("J: 요약의 도착 시각은 방금 만든 회차(수요일 15:00)의 것이다",
                     jReply.contains(AIAssistant.drvWhen(sDay(2027, 3, 10, 15, 0))),
                     "reply=\(jReply)")
        aiJ2.drvCheck("J: 늦은 회차(금요일 17시·18시)의 시각은 요약에 없다",
                     !jReply.contains(AIAssistant.drvWhen(sDay(2027, 3, 12, 17, 0)))
                     && !jReply.contains(AIAssistant.drvWhen(sDay(2027, 3, 12, 18, 0))),
                     "reply=\(jReply)")
        store.favorites = []

        // ── Y. 일반명사 장소·조용한 이동 실패(2026-09-16 결함 K·M). 즐겨찾기에 없는 '회사'가
        //      검색 첫 결과('농업회사법인 화조원')로 조용히 해석돼 118건이 엉뚱한 곳에 등록됐고,
        //      왕복 이동 다리가 0개인데 요약은 성공 문구만 남겼다. 이 절도 events·activities에
        //      쓰지만 전부 샌드박스 안이다 — J절과 같은 이유로 중간 백업·복원은 하지 않는다.
        print("\nY. 일반명사 장소 해석·이동 실패 가시화 (K·M)")
        let aiY = fresh()
        let yHome = FavoritePlace(label: "집", place: Place(name: "집", address: "", latitude: 37.500, longitude: 127.000))
        let yOffice = FavoritePlace(label: "회사", place: Place(name: "회사", address: "", latitude: 37.510, longitude: 127.010))
        // K: 즐겨찾기에 '회사'가 없으면 검색으로 때우지 않는다(일반명사 게이트 — 네트워크 없이 결정적).
        store.favorites = [yHome]
        store.events = []
        store.activities = []
        let y1 = await aiY.drvCreate(["title": "Y-단발", "destination_query": "회사", "origin_query": "집",
                                      "arrival_iso": "2027-03-10T09:00:00", "mode_this_time": "transit",
                                      "buffer_minutes": 10, "notify_lead_minutes": 10])
        aiY.drvCheck("K: 즐겨찾기 없는 일반명사('회사')는 검색으로 해석되지 않고 즐겨찾기 안내로 돌아간다",
                     y1.contains("즐겨찾기에 없어요") && y1.contains("회사"), y1)
        aiY.drvCheck("K: 일정은 만들어지지 않는다(118건 사고의 재현이 막힌다)",
                     store.events.filter { $0.title == "Y-단발" }.isEmpty,
                     "events=\(store.events.filter { $0.title == "Y-단발" }.count)")
        let y3 = await aiY.drvCreateRecurring(["title": "Y-반복", "destination_query": "회사", "origin_query": "집",
                                               "weekdays": ["mon"], "arrival_time": "09:00",
                                               "mode_this_time": "transit", "buffer_minutes": 10,
                                               "notify_lead_minutes": 10, "weeks": 1])
        aiY.drvCheck("K: 반복 생성에서도 같게 막힌다(실측 사고는 이 자리였다)",
                     y3.contains("즐겨찾기에 없어요") && store.events.isEmpty, y3)
        // K: 즐겨찾기에 있으면 일반명사도 진짜 장소다 — 게이트는 '없는 경우'에만 작동한다.
        store.favorites = [yHome, yOffice]
        let y2 = await aiY.drvCreate(["title": "Y-즐겨", "destination_query": "회사", "origin_query": "집",
                                      "arrival_iso": "2027-03-10T10:00:00", "mode_this_time": "transit",
                                      "buffer_minutes": 10, "notify_lead_minutes": 10])
        aiY.drvCheck("K: 즐겨찾기에 있으면 일반명사도 그 장소로 등록된다",
                     y2.hasPrefix("등록 완료") && store.events.filter { $0.title == "Y-즐겨" }.count == 1, y2)
        // K: 진짜 장소명은 게이트에 걸리지 않는다 — 게이트는 낱말 전체 일치만 보고, 이 외의
        //    질의는 이 diff에서 건드리지 않은 검색 분기를 그대로 지난다(검색 동작 자체는 기기 확인).
        aiY.drvCheck("K: 진짜 장소명(강남역·홍대입구역 등)은 게이트 목록에 없다",
                     AIAssistant.drvGenericPlaceWords().isDisjoint(with: ["강남역", "홍대입구역", "선릉역"]),
                     "목록=\(AIAssistant.drvGenericPlaceWords().sorted())")
        // M: 비어 있지 않은 이동/장소 질의의 해석 실패가 결과 문구에 드러난다(모두 일반명사 게이트로
        //    실패시키므로 네트워크 없이 결정적).
        store.favorites = [yHome]
        store.events = []
        store.activities = []
        // (즐겨찾기가 '집'뿐이므로 다리 질의는 '학교'로 — 셋 다 일반명사 게이트로 실패시킨다.)
        let y4 = await aiY.drvExecuteTool("create_activity",
            ["title": "Y-활동", "place_query": "회사",
             "start_iso": "2027-03-10T14:00:00", "end_iso": "2027-03-10T18:00:00",
             "travel_from_query": "학교", "return_to_query": "학교",
             "travel_mode_this_time": "car", "return_mode_this_time": "transit",
             "buffer_minutes": 10, "notify_lead_minutes": 10])
        aiY.drvCheck("M: 해석 실패한 이동·장소가 요약에 드러난다(조용히 넘어가지 않는다)",
                     y4.hasPrefix("활동 블록 등록 완료") && y4.contains("찾지 못해")
                        && y4.contains("가는 편 출발지 '학교'") && y4.contains("활동 장소 '회사'"), y4)
        aiY.drvCheck("M: 활동 자체는 등록된다(이동 0건 — 성공인 척하지 않되 등록도 안 막는다)",
                     store.activities.filter { $0.title == "Y-활동" }.count == 1
                        && store.events.filter { $0.linkedActivityId != nil }.isEmpty,
                     "acts=\(store.activities.filter { $0.title == "Y-활동" }.count)")
        // M: "가는 편 없음" 칩(명시적 안 만들기)은 실패가 아니다 — 서로 다른 사건이 다르게 보인다.
        let y5 = await aiY.drvExecuteTool("create_activity",
            ["title": "Y-탈출", "place_query": "집",
             "start_iso": "2027-03-10T14:00:00", "end_iso": "2027-03-10T18:00:00",
             "travel_from_query": "회사", "return_to_query": AIAssistant.drvNoOutboundToken(),
             "travel_mode_this_time": "car", "return_mode_this_time": "transit",
             "buffer_minutes": 10, "notify_lead_minutes": 10])
        aiY.drvCheck("M: 명시적 '가는 편 없음'은 실패로 세지 않는다(실패는 가는 편 출발지 '회사'만)",
                     y5.contains("가는 편 출발지 '회사'")
                        && !y5.contains("오는 편 도착지") && !y5.contains("활동 장소")
                        && !y5.contains(AIAssistant.drvNoOutboundToken()), y5)
        // L: 프롬프트 문자열 존재 — 행동 검증이 아니다(모델 없이 도는 드라이버는 행동을 못 본다).
        aiY.drvCheck("L: '빈 인자로 호출·말로 되묻지 마라' 지시가 프롬프트에 있다(문자열 존재)",
                     aiY.drvSystemPrompt().contains("말로 되묻지 말고")
                        && aiY.drvSystemPrompt().contains("빈 인자"), "규칙 8 원문 확인")
        store.favorites = [yHome, yOffice]

        // ── N. 캘린더 업로드 가드 + 업로드 상태의 영속성
        //
        // 결함 N: 캘린더 쓰기 경로가 "클라이언트 ID가 설정돼 있나"(`config.hasGoogleCalendar`,
        // 항상 참)만 보고 "계정이 실제로 연결돼 있나"는 보지 않았다. 계정이 안 붙은 기기에서
        // 58건짜리 반복을 만들면 건마다 로그인 시도 + 네트워크 호출이 나가고 전부 실패했는데,
        // 그 실패가 조용히 버려져 사용자는 오래 기다린 뒤 "등록 완료"만 봤다.
        print("\nN. 캘린더 업로드 가드와 상태 기록")
        let aiCal = fresh()

        // N-1) 캘린더를 쓸 수 없는 상태에서는 업로드를 **시도조차** 하지 않는다.
        //      키체인은 건드리지 않는다(사용자의 실제 구글 리프레시 토큰이다) — 연결 불가 상태는
        //      clientID를 비워 만든다. 그래서 이 단언이 덮는 것은 `googleConnected == false`이며,
        //      "ID는 있는데 계정만 없다"는 반쪽은 기기에서만 확인된다.
        // 바꾸는 건 clientID 한 필드뿐이므로 그 필드만 건드리고 그 필드만 되돌린다.
        // 구조체를 통째로 대입하면(예전 이 자리의 모양) 옆 필드까지 같이 실려 오고,
        // 머리말이 세운 autoAddToCalendar=false가 그렇게 조용히 지워졌다.
        let calSavedClientID = store.config.googleClientID
        store.config.googleClientID = ""
        aiCal.drvCheck("N: clientID가 비면 googleConnected는 거짓", !store.googleConnected)

        store.events = [AIAssistant.drvSolo("N-미연결", hours: 30)]
        store.activities = [AIAssistant.drvActivity(UUID(), title: "N-활동", hours: 30)]
        let nEventID = store.events[0].id
        let nActID = store.activities[0].id
        store.enqueueCalendarUpload(eventIDs: [nEventID], activityIDs: [nActID])
        await store.pushToCalendar(eventIDs: [nEventID])
        await store.pushActivitiesToCalendar([nActID])
        aiCal.drvCheck("N: 미연결이면 일정에 업로드 흔적이 없다(pending·failed·gid 전부 없음)",
                     store.events[0].calendarUpload == nil && store.events[0].googleEventId == nil,
                     "upload=\(String(describing: store.events[0].calendarUpload)) gid=\(String(describing: store.events[0].googleEventId))")
        aiCal.drvCheck("N: 미연결이면 활동에도 업로드 흔적이 없다",
                     store.activities[0].calendarUpload == nil && store.activities[0].googleEventId == nil,
                     "upload=\(String(describing: store.activities[0].calendarUpload)) gid=\(String(describing: store.activities[0].googleEventId))")

        // N-2) 이미 gid가 있는 건은 다시 큐에 넣지 않는다 — 두 번 올리면 캘린더에 중복이 생긴다.
        var nSynced = AIAssistant.drvSolo("N-이미등록", hours: 31)
        nSynced.googleEventId = "gid-already"
        store.events = [nSynced]
        store.enqueueCalendarUpload(eventIDs: [nSynced.id])
        aiCal.drvCheck("N: gid가 이미 있으면 pending으로 표시하지 않는다",
                     store.events[0].calendarUpload == nil,
                     "upload=\(String(describing: store.events[0].calendarUpload))")

        // N-3) 상태가 저장/복원을 왕복한다. 값이 디스크를 못 넘기면 앱을 껐다 켠 순간
        //      "못 올라갔다"는 사실이 사라져 이번 수정의 의미가 없어진다.
        var nPending = AIAssistant.drvSolo("N-대기", hours: 32)
        nPending.calendarUpload = .pending
        var nFailed = AIAssistant.drvActivity(UUID(), title: "N-실패", hours: 32)
        nFailed.calendarUpload = .failed
        let nRoundEvent = try? JSONDecoder().decode(ScheduledEvent.self,
                                                    from: JSONEncoder().encode(nPending))
        let nRoundAct = try? JSONDecoder().decode(ActivityBlock.self,
                                                  from: JSONEncoder().encode(nFailed))
        aiCal.drvCheck("N: 일정의 pending이 JSON 왕복을 견딘다", nRoundEvent?.calendarUpload == .pending,
                     "\(String(describing: nRoundEvent?.calendarUpload))")
        aiCal.drvCheck("N: 활동의 failed가 JSON 왕복을 견딘다", nRoundAct?.calendarUpload == .failed,
                     "\(String(describing: nRoundAct?.calendarUpload))")

        // N-4) **이 필드가 없는 옛 JSON도 그대로 읽힌다.** 아래 두 페이로드는 사용자 시뮬레이터에
        //      실제로 저장돼 있던 레코드의 키 구성이다(events 39건·activities 19건 모두 이 모양).
        //      기본값을 가진 비-Optional로 만들었다면 여기서 디코딩이 통째로 실패해 일정이 사라진다.
        let nLegacyEvent = """
        {"id":"24896927-039D-431B-9E7D-3772996FED1F","arrivalDate":826178400,\
        "origin":{"latitude":37.5,"address":"","name":"집","longitude":127},"bufferMinutes":0,\
        "anchor":"departure","title":"V-출발","destination":{"latitude":37.51,"address":"",\
        "name":"회사","longitude":127.01},"departureDate":826178400,"notifyLeadMinutes":10,\
        "mode":"transit","googleEventId":"gid-old","recurrenceId":"1E8B0F54-2C0E-4D0E-9E7E-2A1C6B3D4E5F",\
        "travelSeconds":600,"notificationId":"n1"}
        """
        let nLegacyAct = """
        {"id":"3F2B1A90-7C4D-4E2A-9B8C-1D0E5F6A7B8C","title":"근무","startDate":826178400,\
        "endDate":826207200,"location":{"latitude":37.51,"address":"","name":"회사","longitude":127.01},\
        "googleEventId":"gid-old-act","recurrenceId":"1E8B0F54-2C0E-4D0E-9E7E-2A1C6B3D4E5F"}
        """
        let nOldEvent = try? JSONDecoder().decode(ScheduledEvent.self,
                                                  from: Data(nLegacyEvent.utf8))
        let nOldAct = try? JSONDecoder().decode(ActivityBlock.self, from: Data(nLegacyAct.utf8))
        aiCal.drvCheck("N: calendarUpload 키가 없는 옛 일정 JSON이 그대로 디코딩된다(nil)",
                     nOldEvent != nil && nOldEvent?.calendarUpload == nil
                        && nOldEvent?.googleEventId == "gid-old",
                     "decoded=\(nOldEvent != nil)")
        aiCal.drvCheck("N: calendarUpload 키가 없는 옛 활동 JSON이 그대로 디코딩된다(nil)",
                     nOldAct != nil && nOldAct?.calendarUpload == nil
                        && nOldAct?.googleEventId == "gid-old-act",
                     "decoded=\(nOldAct != nil)")

        store.events = []
        store.activities = []
        // 예전엔 여기서 `store.config = AppConfig.load()`를 했다 — 한 필드를 되돌리려고 디스크
        // 설정을 통째로 다시 읽은 것이고, 그 바람에 autoAddToCalendar=true가 딸려 들어와
        // 뒤 절들의 시험 일정이 실제 캘린더로 나갔다. 비워둔 필드만 되돌린다.
        store.config.googleClientID = calSavedClientID
        drvAssertGlobalInvariants(aiCal, "N절")

        // ── Z. 못 푸는 장소는 **카드가 묻는다**(결함 O). K가 막은 자리의 다음 걸음이다 — K는
        //      "검색 첫 결과로 때우지 않는다"까지였고, 그 결과 대화가 "즐겨찾기에 추가해 주세요"에서
        //      끊겨 사용자가 ⭐ 화면에 다녀와 처음부터 다시 말해야 했다. 이제 그 값을 카드 줄로 묻고,
        //      실행부 가드는 카드를 지나지 않은 호출용으로 그대로 남는다(카드 먼저, 가드 다음).
        // ⚠️ 이 줄의 전역 불변식(머리말의 "캘린더 푸시를 끈다")을 여기서 다시 세운다. N절이 끝나며
        //    `store.config = AppConfig.load()`로 디스크 설정을 되돌리는데, 개발 기기의 실제
        //    config.json은 autoAddToCalendar=true에 구글이 연결돼 있다 — 그 뒤 절에서 만든
        //    **시험용 일정이 사용자의 진짜 구글 캘린더로 올라간다**(백업·복원이 불가능한 부작용).
        //    되돌린 clientID는 그대로 두고 자동 업로드만 다시 끈다.
        store.config.autoAddToCalendar = false
        print("\nZ. 앱이 못 푸는 장소는 카드가 묻는다 (결함 O)")
        let zFavBackup = store.favorites
        let aiZ = fresh()
        let zHome = FavoritePlace(label: "집", place: Place(name: "집", address: "", latitude: 37.500, longitude: 127.000))
        let zGasan = FavoritePlace(label: "가산 오피스", place: Place(name: "가산 오피스", address: "", latitude: 37.480, longitude: 126.880))
        store.favorites = [zHome, zGasan]
        store.events = []
        store.activities = []
        // 수단·여유·알림은 선언에 없어 모델이 실어 와도 정화가 버린다(결함 D) — 그래서 이 카드엔
        // 언제나 그 세 줄이 있다. 이번 변경이 **더하는** 것은 목적지 줄 하나뿐이라는 것이 판정 기준이다.
        let zBase = ["mode_this_time", "buffer_minutes", "notify_lead_minutes"]
        let zFull: [String: Any] = ["title": "Z-단발", "destination_query": "회사", "origin_query": "집",
                                    "arrival_iso": "2027-03-11T09:00:00"]
        let z1 = aiZ.drvAsk("create_schedule", zFull)
        aiZ.drvCheck("O-1: 즐겨찾기 없는 '회사'는 실행 거부가 아니라 목적지 줄로 뜬다",
                     z1?.fields.map(\.key) == ["destination_query"] + zBase,
                     "keys=\(z1?.fields.map(\.key) ?? [])")
        aiZ.drvCheck("O-1: 그 줄은 왜 떴는지 사용자의 낱말로 적는다(빈 값을 묻는 줄과 구분된다)",
                     (z1?.fields.first?.note).map { $0.contains("회사") && $0.contains("⭐") } == true,
                     "note=\(z1?.fields.first?.note ?? "nil")")
        aiZ.drvCheck("O-1: 칩으로 즐겨찾기를 고를 수 있고 직접입력도 열려 있다(대화를 떠날 필요가 없다)",
                     z1?.fields.first?.options.contains { $0.value == "가산 오피스" } == true
                        && z1?.fields.first?.allowsCustom == true,
                     "options=\(z1?.fields.first?.options.map(\.value) ?? [])")
        aiZ.drvCheck("O-1: 묻고 있는 값을 '말씀하신 대로'에 같이 적지 않는다(한 카드가 두 말 하지 않기)",
                     z1?.stated.contains(where: { $0.contains("목적지") }) == false,
                     "stated=\(z1?.stated ?? [])")
        // O-2: 고른 값으로 **정확히 1회** 등록된다 — 여기까지 와야 "대화 안에서 끝난다"가 참이다.
        aiZ.bubbles.append(.init(role: .assistant, text: "", ask: z1))
        for f in z1?.fields ?? [] {
            switch f.key {
            case "destination_query": aiZ.choose(field: f.id, value: "가산 오피스")
            case "mode_this_time": aiZ.choose(field: f.id, value: "transit")
            default: aiZ.choose(field: f.id, value: "10")
            }
        }
        aiZ.drvCheck("O-2: 줄을 다 고르면 확인이 열린다", aiZ.drvLiveAsk()?.isReady == true, "isReady가 false다")
        let z2 = await aiZ.drvResolvePendingAsk()
        let zEvent = store.events.first { $0.title == "Z-단발" }
        aiZ.drvCheck("O-2: 고른 장소로 정확히 1건 등록된다(검색 첫 결과가 아니다)",
                     store.events.filter { $0.title == "Z-단발" }.count == 1
                        && zEvent?.destination.name == "가산 오피스",
                     "count=\(store.events.filter { $0.title == "Z-단발" }.count) dest=\(zEvent?.destination.name ?? "nil") summary=\(z2 ?? "nil")")
        // O-3: 게이트는 '즐겨찾기가 없을 때'만 작동한다 — 있으면 줄이 생기지 않는다(카드가 길어지지 않음).
        store.favorites = [zHome, FavoritePlace(label: "회사", place: Place(name: "회사", address: "", latitude: 37.510, longitude: 127.010))]
        aiZ.drvCheck("O-3: 즐겨찾기가 있는 일반명사는 목적지 줄이 생기지 않는다",
                     aiZ.drvAsk("create_schedule", zFull)?.fields.map(\.key) == zBase,
                     "keys=\(aiZ.drvAsk("create_schedule", zFull)?.fields.map(\.key) ?? [])")
        // O-4: 진짜 장소명은 그대로 지나간다 — 모든 목적지를 질문으로 바꾸지 않는다.
        store.favorites = [zHome]
        var zReal = zFull; zReal["destination_query"] = "강남역"
        aiZ.drvCheck("O-4: 진짜 장소명(강남역)은 목적지 줄이 생기지 않는다",
                     aiZ.drvAsk("create_schedule", zReal)?.fields.map(\.key) == zBase,
                     "keys=\(aiZ.drvAsk("create_schedule", zReal)?.fields.map(\.key) ?? [])")
        // O-5: 실행부 가드는 그대로다 — 카드를 지나지 않고 온 호출은 여전히 막히고, 그때의 안내는
        //      "비어 있어요"가 아니라 즐겨찾기 목록이 붙은 placeNotFound다(문구가 거짓이 되면 안 된다).
        store.events = []
        // 실행부는 카드가 채운 값을 다 받은 상태로 들어온다(drvCreate는 정화를 지나지 않는다 —
        // 카드 통과 경로와 같은 모양). 그 상태에서도 못 푸는 목적지는 그대로 막혀야 한다.
        var zExec = zFull
        zExec["mode_this_time"] = "transit"; zExec["buffer_minutes"] = 10; zExec["notify_lead_minutes"] = 10
        let z5 = await aiZ.drvCreate(zExec)
        aiZ.drvCheck("O-5: 카드를 지나지 않은 호출은 실행부가 그대로 막는다(가드 유지)",
                     z5.contains("즐겨찾기에 없어요") && z5.contains("회사")
                        && !z5.contains("비어 있어요")
                        && store.events.filter { $0.title == "Z-단발" }.isEmpty, z5)
        // O-6: 활동의 장소·다리 질의도 같다. 이동이 없는 활동도 장소를 못 풀면 묻는다(위치 없는
        //      활동으로 조용히 등록되던 자리 — M의 사후 보고보다 앞에서 막힌다).
        let zActPlace = aiZ.drvAsk("create_activity", ["title": "Z-활동", "place_query": "회사",
                                                       "start_iso": "2027-03-11T14:00:00",
                                                       "end_iso": "2027-03-11T18:00:00"])
        aiZ.drvCheck("O-6: 이동 없는 활동도 못 푸는 장소면 활동 장소 줄이 뜬다(이동 줄은 그대로 없다)",
                     zActPlace?.fields.map(\.key) == ["place_query"],
                     "keys=\(zActPlace?.fields.map(\.key) ?? [])")
        let zAct = aiZ.drvAsk("create_activity", ["title": "Z-왕복", "place_query": "회사",
                                                  "start_iso": "2027-03-11T14:00:00",
                                                  "end_iso": "2027-03-11T18:00:00",
                                                  "travel_from_query": "학교", "return_to_query": "사무실",
                                                  "travel_mode_this_time": "car", "return_mode_this_time": "transit",
                                                  "buffer_minutes": 10, "notify_lead_minutes": 10])
        // 활동의 최악은 이 일곱 줄이다(단발 일정의 최악과 같은 수) — G11의 상한이 그대로 유지된다.
        aiZ.drvCheck("O-6: 세 질의가 각각 자기 줄로 뜨고, 활동 카드의 최악은 일곱 줄이다",
                     zAct?.fields.map(\.key) == ["place_query", "travel_from_query", "return_to_query",
                                                 "travel_mode_this_time", "return_mode_this_time",
                                                 "buffer_minutes", "notify_lead_minutes"],
                     "keys=\(zAct?.fields.map(\.key) ?? [])")
        aiZ.drvCheck("O-6: 사용자가 말한 가는 편 출발지에는 '가는 편 없음' 탈출 칩을 붙이지 않는다",
                     zAct?.fields.first { $0.key == "travel_from_query" }?
                        .options.contains { $0.value == AIAssistant.drvNoOutboundToken() } == false,
                     "options=\(zAct?.fields.first { $0.key == "travel_from_query" }?.options.map(\.value) ?? [])")
        aiZ.drvCheck("O-6: 모델이 비워 보낸 가는 편 출발지에는 탈출 칩이 그대로 있다(A절 회귀 방지)",
                     aiZ.drvAsk("create_activity", ["title": "Z-편도", "place_query": "가산 오피스",
                                                    "start_iso": "2027-03-11T14:00:00",
                                                    "end_iso": "2027-03-11T18:00:00",
                                                    "return_to_query": "가산 오피스"])?
                        .fields.first { $0.key == "travel_from_query" }?
                        .options.contains { $0.value == AIAssistant.drvNoOutboundToken() } == true,
                     "탈출 칩이 사라졌다")
        // O-7: 같은 일반명사를 직접입력으로 다시 적는 건 답이 아니다 — 받아들이면 확인 뒤 같은
        //      이유로 막혀 대화가 한 바퀴 더 돈다. 칩·진짜 장소명은 그대로 받는다.
        let aiZ2 = fresh()
        let z7 = aiZ2.drvAsk("create_schedule", zFull)
        aiZ2.bubbles.append(.init(role: .assistant, text: "", ask: z7))
        if let zf = z7?.fields.first {
            aiZ2.drvCheck("O-7: 직접입력에 '회사'를 다시 적으면 받지 않는다",
                          aiZ2.submitCustom(field: zf.id, text: "회사") == false, "받아들였다")
            aiZ2.drvCheck("O-7: 거절된 자리에 이유가 붙는다('그 값은 쓸 수 없어요'만 남지 않는다)",
                          (aiZ2.drvLiveAsk()?.fields.first { $0.id == zf.id }?.note)?.contains("회사") == true,
                          "note=\(aiZ2.drvLiveAsk()?.fields.first { $0.id == zf.id }?.note ?? "nil")")
            aiZ2.drvCheck("O-7: 진짜 장소명은 직접입력으로 받는다(막다른 골목이 아니다)",
                          aiZ2.submitCustom(field: zf.id, text: "가산3차 SK V1센터") == true, "거절했다")
        }
        // O-8: 반복 생성에도 같은 줄이 붙는다(118건 사고가 난 도구).
        let z8Args: [String: Any] = ["title": "Z-반복", "destination_query": "회사", "origin_query": "집",
                                     "weekdays": ["mon"], "arrival_time": "09:00"]
        aiZ2.drvCheck("O-8: 반복 일정의 못 푸는 목적지도 줄로 뜬다(118건 사고가 난 도구)",
                      aiZ2.drvAsk("create_recurring_schedule", z8Args)?.fields.map(\.key)
                        == ["destination_query"] + zBase + ["weeks"],
                      "keys=\(aiZ2.drvAsk("create_recurring_schedule", z8Args)?.fields.map(\.key) ?? [])")
        store.events = []
        store.activities = []
        store.favorites = zFavBackup

        // ── P. 장소 줄의 직접입력이 그냥 빈 칸이라, 틀린 값은 **카드를 다 채우고 확인을 누른 뒤에야**
        //      실행부에서 실패했다(2026-09-16 실기기: 'ㅁㄴㅇㄹ'). 이제 검색해서 고르고, 고른 순간
        //      좌표까지 확정된다. 여기 단언은 전부 그 확정값이 실행부까지 그대로 가는지를 본다.
        store.config.autoAddToCalendar = false   // Z절과 같은 이유(N절의 설정 되돌리기 뒤에 있다)
        print("\nP. 장소 줄 검색 — 고른 후보의 좌표가 실행부까지 간다 (결함 P)")
        let psFavBackup = store.favorites
        let psHome = FavoritePlace(label: "집", place: Place(name: "집", address: "", latitude: 37.500, longitude: 127.000))
        store.favorites = [psHome]
        store.events = []
        let aiPS = fresh()
        let psPicked = Place(name: "가산3차 SK V1센터", address: "서울 금천구 가산디지털1로 173",
                            latitude: 37.4812, longitude: 126.8827)
        let psAsk = aiPS.drvAsk("create_schedule", ["title": "P-확정", "destination_query": "회사",
                                                  "origin_query": "집", "arrival_iso": "2027-03-12T09:00:00"])
        aiPS.bubbles.append(.init(role: .assistant, text: "", ask: psAsk))
        for f in psAsk?.fields ?? [] {
            switch f.key {
            case "destination_query": aiPS.choose(field: f.id, place: psPicked)   // ← 후보 탭
            case "mode_this_time": aiPS.choose(field: f.id, value: "transit")
            default: aiPS.choose(field: f.id, value: "10")
            }
        }
        _ = await aiPS.drvResolvePendingAsk()
        let psArgs = aiPS.drvLastCallArgs()
        let psEvent = store.events.first { $0.title == "P-확정" }
        aiPS.drvCheck("P-1: 인자에는 **이름만** 실린다(내부 토큰이 모델·요약으로 새지 않는다)",
                     (psArgs["destination_query"] as? String) == "가산3차 SK V1센터",
                     "dest=\(psArgs["destination_query"] ?? "nil")")
        aiPS.drvCheck("P-1: 실행부가 이름을 다시 검색하지 않고 **고른 좌표 그대로** 등록한다",
                     psEvent?.destination == psPicked,
                     "dest=\(String(describing: psEvent?.destination))")
        // P-2: 거절과 검색이 갈리는 지점 — 자유 텍스트로 확정하는 건 여전히 거절, 후보로 고른
        //      같은 이름은 통과. '사무실'은 일반명사 목록에 있고 즐겨찾기엔 없다.
        let aiPS2 = fresh()
        let ps2Ask = aiPS2.drvAsk("create_schedule", ["title": "P-사무실", "destination_query": "사무실",
                                                    "origin_query": "집", "arrival_iso": "2027-03-12T10:00:00"])
        aiPS2.bubbles.append(.init(role: .assistant, text: "", ask: ps2Ask))
        let ps2Dest = ps2Ask?.fields.first { $0.key == "destination_query" }
        aiPS2.drvCheck("P-2: 고르기 전에는 자유 텍스트 '사무실'을 받지 않는다(O의 거절 유지)",
                      ps2Dest.map { aiPS2.submitCustom(field: $0.id, text: "사무실") } == false, "받아들였다")
        let ps2Picked = Place(name: "사무실", address: "서울 강남구 테헤란로 1", latitude: 37.4979, longitude: 127.0276)
        if let ps2Dest { aiPS2.choose(field: ps2Dest.id, place: ps2Picked) }
        aiPS2.drvCheck("P-2: 후보로 고른 뒤에는 같은 이름도 받아들인다(좌표가 생겼으므로)",
                      ps2Dest.map { aiPS2.submitCustom(field: $0.id, text: "사무실") } == true, "거절했다")
        aiPS2.drvCheck("P-2: 고른 뒤에는 카드가 그 값을 다시 묻지 않는다",
                      aiPS2.drvAsk("create_schedule", ["title": "P-사무실", "destination_query": "사무실",
                                                      "origin_query": "집", "arrival_iso": "2027-03-12T10:00:00"])?
                        .fields.contains { $0.key == "destination_query" } == false,
                      "목적지 줄이 다시 떴다")
        // P-3: 이름이 즐겨찾기와 겹치면 **즐겨찾기가 이긴다**(오래 사는 설정 쪽). 뒤집히면
        //      "집이라고 했는데 아까 고른 카페"가 된다.
        let aiPS3 = fresh()
        let ps3Ask = aiPS3.drvAsk("create_schedule", ["title": "P-겹침", "destination_query": "회사",
                                                    "origin_query": "집", "arrival_iso": "2027-03-12T11:00:00"])
        aiPS3.bubbles.append(.init(role: .assistant, text: "", ask: ps3Ask))
        if let f = ps3Ask?.fields.first(where: { $0.key == "destination_query" }) {
            aiPS3.choose(field: f.id, place: Place(name: "집", address: "카페 집", latitude: 37.1, longitude: 126.1))
            for g in ps3Ask?.fields ?? [] where g.key != "destination_query" {
                aiPS3.choose(field: g.id, value: g.key == "mode_this_time" ? "transit" : "10")
            }
        }
        _ = await aiPS3.drvResolvePendingAsk()
        aiPS3.drvCheck("P-3: 확정 장소와 즐겨찾기 이름이 겹치면 즐겨찾기가 이긴다(출발지=목적지로 막힌다)",
                      store.events.filter { $0.title == "P-겹침" }.isEmpty,
                      "events=\(store.events.filter { $0.title == "P-겹침" }.count)")
        // P-4: 0건이 조용히 넘어가지 않는다. 머리말에서 프록시를 비웠으므로 검색은 MapKit
        //      단독으로 돈다 — 이 어지러운 질의의 결과는 0건으로 정해져 있다.
        let aiPS4 = fresh()
        let ps4Ask = aiPS4.drvAsk("create_schedule", ["title": "P-빈결과", "destination_query": "회사",
                                                    "origin_query": "집", "arrival_iso": "2027-03-12T12:00:00"])
        aiPS4.bubbles.append(.init(role: .assistant, text: "", ask: ps4Ask))
        let ps4Dest = ps4Ask?.fields.first { $0.key == "destination_query" }
        if let ps4Dest {
            aiPS4.searchPlaces(field: ps4Dest.id, text: "ㅁㄴㅇㄹ쀍똙")
            aiPS4.drvCheck("P-4: 부르는 즉시 '찾는 중'이 되고 확인 버튼은 그대로 잠겨 있다(카드를 막지 않는다)",
                          AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle) == "searching"
                            && aiPS4.drvLiveAsk()?.isReady == false,
                          "lookup=\(AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle))")
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            aiPS4.drvCheck("P-4: 0건이면 '찾지 못함'이 줄에 남는다 — 조용히 넘어가지 않는다 〔MapKit 단독〕",
                          AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle) == "empty",
                          "lookup=\(AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle))")
            // P-5: 같은 질의를 연달아 부르면 다시 부르지 않는다(묶음의 관측 가능한 계약) —
            //      다시 불렀다면 상태가 'searching'으로 돌아갔을 것이다.
            aiPS4.searchPlaces(field: ps4Dest.id, text: "ㅁㄴㅇㄹ쀍똙")
            aiPS4.drvCheck("P-5: 같은 질의는 다시 부르지 않는다(상태가 '찾는 중'으로 돌아가지 않는다)",
                          AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle) == "empty",
                          "lookup=\(AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .idle))")
            aiPS4.searchPlaces(field: ps4Dest.id, text: "")
            aiPS4.drvCheck("P-5: 입력을 비우면 상태도 비워진다(옛 결과가 남지 않는다)",
                          AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .searching) == "idle",
                          "lookup=\(AIAssistant.drvLookup(aiPS4.drvLiveAsk()?.fields.first { $0.key == "destination_query" }?.lookup ?? .searching))")
        }
        // P-6: 검색이 도는 사이 카드가 사라지면 결과를 버린다(H1 — await 앞뒤로 자리를 믿지 않는다).
        let aiPS6 = fresh()
        let ps6Ask = aiPS6.drvAsk("create_schedule", ["title": "P-사라짐", "destination_query": "회사",
                                                    "origin_query": "집", "arrival_iso": "2027-03-12T13:00:00"])
        aiPS6.bubbles.append(.init(role: .assistant, text: "", ask: ps6Ask))
        if let f = ps6Ask?.fields.first(where: { $0.key == "destination_query" }) {
            aiPS6.searchPlaces(field: f.id, text: "강남역")
        }
        aiPS6.drvCancelPendingAsk()
        let ps6New = aiPS6.drvAsk("create_schedule", ["title": "P-새카드", "destination_query": "회사",
                                                    "origin_query": "집", "arrival_iso": "2027-03-12T14:00:00"])
        aiPS6.bubbles.append(.init(role: .assistant, text: "", ask: ps6New))
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        aiPS6.drvCheck("P-6: 카드가 사라진 뒤 돌아온 결과는 새 카드에 앉지 않는다(조용히 버려진다)",
                      aiPS6.drvLiveAsk()?.fields.allSatisfy { AIAssistant.drvLookup($0.lookup) == "idle" } == true,
                      "lookups=\(aiPS6.drvLiveAsk()?.fields.map { AIAssistant.drvLookup($0.lookup) } ?? [])")
        // P-7: 캘린더 대기 문구 — 판정의 출처는 레코드의 pending 표시다. 이 환경은 구글 미연결이라
        //      pending이 안 붙고, 그래서 문구도 없다(없는데 기다리라고 하면 거짓이다).
        let psDone = store.events.first { $0.title == "P-확정" }
        aiPS.drvCheck("P-7: 미연결이면 캘린더 문구를 붙이지 않는다",
                     psDone.map { aiPS.drvCalendarNote([$0.id]).isEmpty } == true,
                     "note=\(psDone.map { aiPS.drvCalendarNote([$0.id]) } ?? "nil")")
        if let psDone, let i = store.events.firstIndex(where: { $0.id == psDone.id }) {
            store.events[i].calendarUpload = .pending
            aiPS.drvCheck("P-7: pending이면 '아직 안 올라갔다'고 말한다(올라간 것처럼 읽히지 않는다)",
                         aiPS.drvCalendarNote([psDone.id]).contains("아직 올라가지 않았")
                            && aiPS.drvCalendarNote([psDone.id]).contains("캘린더"),
                         aiPS.drvCalendarNote([psDone.id]))
        }
        store.events = []
        store.favorites = psFavBackup

        // 마지막 절이 불변식을 깨고 끝나면 그 뒤에 아무 방어선도 없다 — 여기서 한 번 더 잰다.
        // 한계는 분명하다: 중간 절이 깼다가 다음 절이 되세우면 이 단언은 통과한다. 절 경계마다
        // drvAssertGlobalInvariants를 부르는 것이 진짜 방어이고, 이건 꼬리 구간의 backstop이다.
        drvAssertGlobalInvariants(fresh(), "전체 실행")

        print("\n\(drvPass)/\(drvPass + drvFail) 통과")
        // 대조·종료 코드·샌드박스 정리까지 전부 이 루틴 하나가 한다 — 단언 실패의 exit 1
        // 가지도 여기로 접혔다(우선순위: 실제 디렉터리 차이 3 > 시한 124 > 단언 실패 1 > 0).
        drvFinishOnce(start: startSnapshot, realSupport: realSupport, sandbox: sandbox,
                      deadlineFired: false, removeSandbox: true)
    }
}
