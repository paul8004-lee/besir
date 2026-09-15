import Foundation
import CoreLocation

/// LLM 대화로 자연어 일정을 이해해 besir 앱에 자동 등록하는 도우미.
///
/// 보안 설계: AI 백엔드는 앱에 없다. 앱은 Cloudflare Worker 프록시의 `/ai/chat`으로
/// 대화 본문을 POST 하고, 프록시가 실제 모델을 호출해 같은 형식으로 응답을 돌려준다 —
/// 백엔드가 바뀌어도 이 클래스는 그대로 두고 프록시만 바꾸면 되도록, 요청/응답은 Gemini
/// generateContent 형식을 그대로 쓴다. 실제로 Gemini → Workers AI → OpenAI 세 번을
/// 이 클래스 수정 없이 통과했다. 현재 모델이 무엇인지는 여기 적지 않는다 — 그 사실이
/// 이 주석에 복제되는 순간 낡는다(실제로 낡았다). SSOT는 `proxy/src/index.js`의 상수와
/// `CLAUDE.md`의 "AI 백엔드" 절이다.
///
/// 흐름: 사용자 발화(또는 다른 앱에서 공유받은 텍스트/이미지) → 모델이 `create_schedule`
/// 툴 호출 → 앱이 목적지를 카카오 검색(또는 즐겨찾기)으로 해석하고 현재 위치를 출발지로
/// 삼아 `Store.addEvent` 실행 → 결과를 다시 모델에 전달 → 모델이 한국어로 등록 확인.
@MainActor
final class AIAssistant: ObservableObject {
    struct Bubble: Identifiable {
        enum Role { case user, assistant }
        let id = UUID()
        let role: Role
        var text: String
    }

    @Published var bubbles: [Bubble] = []
    @Published var isThinking = false
    @Published var input = ""
    /// 채팅 시트 표시 여부. 공유받은 항목이 도착하면 자동으로 true가 된다.
    @Published var isPresented = false

    private let store: Store
    private let location: LocationManager

    /// 대화 히스토리(툴 라운드트립 포함). role: user/model/function. (Gemini generateContent 형식)
    private var contents: [[String: Any]] = []
    /// 이번 대화에서 가장 최근에 만든 반복 일정 그룹 — "방금 만든 거 자동차로 바꿔줘" 같은 수정
    /// 요청이 새로 만들지 않고 이 그룹을 그대로 갱신하도록(update_recurring_schedule) 참조한다.
    private var lastRecurrenceId: UUID?
    /// list_schedules가 반복 그룹에 붙인 번호(UUID→번호). **한 번 붙은 번호는 대화가 끝날 때까지
    /// 그 그룹 전용**이다 — 목록을 다시 그릴 때마다 1부터 다시 매기면 중간에 그룹이 지워졌을 때
    /// 같은 번호가 다른 그룹을 가리키게 되고, 모델이 옛 목록에서 본 번호를 그대로 말했다가
    /// 엉뚱한 그룹을 **조용히** 고치게 된다. 지워진 그룹의 번호는 비워 두지 않고 남겨 둬도
    /// 실행부의 0건 가드가 잡는다. 히스토리와 함께 저장하지 않는다: lastRecurrenceId와 달리
    /// 번호는 렌더링에서 만들어진 약속이라 앱을 다시 켜면 전부 무효인데, 저장해 두면 무효 번호가
    /// 옛 그룹을 향해 살아 있다 — 못 찾는 쪽(되묻기 → 다시 목록)이 조용한 오작동보다 싸다.
    private var seriesNumbers: [UUID: Int] = [:]
    private var nextSeriesNumber = 1
    /// 반복 주기를 되물을 때 **무엇을 물었는지**. 모델이 되묻기도 전에 스스로
    /// `confirm_recurrence:true`를 붙여 보내는 바람에 "요일 3개 이상 + 주기 인자" 가드가 통째로
    /// 사라진 적이 있다(평일 5일짜리 출근 일정이 7건만 생겼다) — 묻지도 않았는데 온 확인은 확인이 아니다.
    ///
    /// "물어봤다"는 사실만 Bool로 들고 있으면 그 확인이 **엉뚱한 호출에서** 쓰인다. 두 길이 실제로 열린다:
    /// 한 턴에 툴 호출이 배열로 여러 개 오면(runLoop이 그대로 순회한다) 앞 호출이 켠 걸 뒤 호출이
    /// 주워 쓰고, 되묻고 나서 아무 호출도 통과하지 못한 채 대화가 흘러가면(사용자가 딴 얘기를 하거나
    /// 툴 루프가 5회를 다 써서 안내가 모델 아닌 사용자에게 가면) 그 확인이 남아 나중의 무관한
    /// 반복 요청을 그냥 통과시킨다. 그래서 조합 자체를 들고 같은 조합일 때만 인정한다.
    ///
    /// 히스토리에 저장하지 않는다: 앱을 껐다 켜서 이 값이 풀리면 한 번 더 되묻는 게 전부지만,
    /// 반대로 살아남으면 묻지도 않고 통과한다 — 틀렸을 때 손해가 작은 쪽으로 둔다.
    private struct RecurrenceAsk: Equatable {
        let nth: Int?
        let interval: Int
        let weekdayCount: Int
    }
    private var recurrenceConfirmAsk: RecurrenceAsk?

    /// 반복 그룹 수정에서 여유·알림에 0이 왔을 때 되물은 조합. `RecurrenceAsk`와 같은 이유로
    /// 값 자체를 들고 있다 — 다른 조합에 대해 받아둔 확인이 뒤의 무관한 0을 통과시키면 안 된다.
    private struct ZeroUpdateAsk: Equatable {
        let recurrenceId: UUID
        let buffer: Int?
        let notify: Int?
    }
    private var zeroUpdateConfirmAsk: ZeroUpdateAsk?

    /// 사용자에 대해 오래 기억해둘 사실(주로 쓰는 이동수단 등). 대화 기록(ai_history.json)과 달리
    /// "새 대화 시작"으로 지워지지 않는다 — 매번 새로 물어보지 않도록 시스템 프롬프트에 항상 포함된다.
    @Published private(set) var rememberedFacts: [String] = []

    init(store: Store, location: LocationManager) {
        self.store = store
        self.location = location
        loadHistory()
        loadMemory()
        if bubbles.isEmpty {
            bubbles.append(.init(role: .assistant,
                text: "안녕하세요! 등록할 일정을 말로 알려주세요.\n예: \"내일 오후 3시에 강남역에서 친구 만나기\"\n다른 앱에서 일정표를 공유해주셔도 돼요."))
        }
        // 출발지 계산을 위해 현재 위치를 미리 확보해 둔다.
        if location.currentLocation == nil { location.useCurrentLocation() }
    }

    // MARK: - 장기 기억(사용자 선호 등, 대화 초기화와 무관하게 유지)

    private var memoryURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("ai_memory.json")
    }

    private func saveMemory() {
        guard let data = try? JSONEncoder().encode(rememberedFacts) else { return }
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        try? data.write(to: memoryURL)
    }

    private func loadMemory() {
        guard let data = try? Data(contentsOf: memoryURL),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else { return }
        rememberedFacts = decoded
    }

    /// 설정 화면 등에서 잘못 기억한 내용을 지울 때 쓴다.
    func forgetFact(_ fact: String) {
        rememberedFacts.removeAll { $0 == fact }
        saveMemory()
    }

    func forgetAllFacts() {
        rememberedFacts = []
        saveMemory()
    }

    // MARK: - 대화 기록 저장/복원(재설치·재실행해도 유지)

    private var historyURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("ai_history.json")
    }

    private func saveHistory() {
        let bubblesJSON: [[String: Any]] = bubbles.map {
            ["role": $0.role == .user ? "user" : "assistant", "text": $0.text]
        }
        // lastRecurrenceId도 같이 저장한다 — 앱을 껐다 켜면 사라져서 "방금 만든 반복 일정
        // 자동차로 바꿔줘"가 안 되던 문제(체크리스트 D1/D2)를 없앤다.
        var obj: [String: Any] = ["bubbles": bubblesJSON, "contents": contents]
        if let rid = lastRecurrenceId { obj["lastRecurrenceId"] = rid.uuidString }
        guard JSONSerialization.isValidJSONObject(obj),
              let data = try? JSONSerialization.data(withJSONObject: obj) else { return }
        try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)
        try? data.write(to: historyURL)
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: historyURL),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if let bubblesJSON = obj["bubbles"] as? [[String: Any]] {
            bubbles = bubblesJSON.compactMap { dict in
                guard let roleStr = dict["role"] as? String, let text = dict["text"] as? String else { return nil }
                return Bubble(role: roleStr == "user" ? .user : .assistant, text: text)
            }
        }
        if let savedContents = obj["contents"] as? [[String: Any]] {
            contents = savedContents
        }
        if let rid = obj["lastRecurrenceId"] as? String { lastRecurrenceId = UUID(uuidString: rid) }
        // 예전 버그(툴 실행 후 마무리 텍스트 턴이 히스토리에 안 남던 문제)로 저장된 대화가
        // "...function" 으로 끝나 있을 수 있다 — 그 상태로 다음 사용자 메시지를 보내면 Workers AI가
        // "user 다음에 tool" 순서를 거부해 매번 실패한다. 사용자가 "새 대화 시작"을 누르지 않아도
        // 자동으로 복구되도록, 불러온 직후 끝을 다듬어둔다.
        repairDanglingToolTurn()
        // 예전 버전이 저장해둔 이미지 base64·과도하게 긴 히스토리도 여기서 정리한다.
        stripInlineDataFromHistory()
        trimHistory()
    }

    /// 히스토리에 남아 있는 이미지(base64)를 짧은 설명으로 바꾼다.
    /// 공유받은 스크린샷은 한 번 읽히면 그만인데, 그대로 두면 그 뒤의 **모든** 요청에 수 MB짜리
    /// base64가 매번 다시 실려 가고(느리고 토큰도 낭비) ai_history.json도 그만큼 계속 커진다.
    private func stripInlineDataFromHistory() {
        for i in contents.indices {
            guard let parts = contents[i]["parts"] as? [[String: Any]],
                  parts.contains(where: { $0["inlineData"] != nil }) else { continue }
            contents[i]["parts"] = parts.map { part -> [String: Any] in
                part["inlineData"] != nil ? ["text": "(이전에 공유한 이미지)"] : part
            }
        }
    }

    /// 대화가 길어지면 매 요청마다 전체 히스토리를 다시 보내느라 점점 느려지고, 언젠가는 모델의
    /// 컨텍스트 한도를 넘겨 대화가 통째로 실패한다(그때부터는 무슨 말을 해도 안 됨). 오래된 턴부터
    /// 잘라내되, 남는 첫 턴은 반드시 user 여야 한다 — function(툴 결과) 턴으로 시작하면 짝이 되는
    /// model 턴이 없어 백엔드가 role 순서를 거부한다.
    private static let maxHistoryTurns = 40
    private func trimHistory() {
        guard contents.count > Self.maxHistoryTurns else { return }
        var cut = contents.count - Self.maxHistoryTurns
        while cut < contents.count, (contents[cut]["role"] as? String) != "user" { cut += 1 }
        guard cut < contents.count else { return }   // user 턴을 못 찾으면 자르지 않는다(안전).
        contents.removeFirst(cut)
    }

    /// 히스토리가 function(tool) 턴으로 끝나 있으면 그 뒤에 짧은 확인 턴을 끼워 넣어, 다음에 오는
    /// 사용자 메시지가 항상 "model 다음의 user"가 되도록 순서를 보장한다.
    private func repairDanglingToolTurn() {
        guard let last = contents.last, (last["role"] as? String) == "function" else { return }
        contents.append(["role": "model", "parts": [["text": "네, 확인했어요."]]])
    }

    /// 대화 기록을 비우고 새로 시작한다. 예전 히스토리가 role 순서 버그 등으로 깨져 있어도
    /// (예: tool 다음에 user가 바로 오면 Workers AI가 매 요청을 거부) 여기서 초기화하면 복구된다.
    func resetConversation() {
        contents = []
        lastRecurrenceId = nil
        // 목록 번호도 같이 지운다 — 번호는 "이 대화에서 목록이 보여줬다"는 약속이라 새 대화에서
        // 옛 번호가 살아 있으면 아무 그룹이나 가리키게 된다.
        seriesNumbers = [:]
        nextSeriesNumber = 1
        recurrenceConfirmAsk = nil
        zeroUpdateConfirmAsk = nil
        bubbles = [.init(role: .assistant,
            text: "안녕하세요! 등록할 일정을 말로 알려주세요.\n예: \"내일 오후 3시에 강남역에서 친구 만나기\"\n다른 앱에서 일정표를 공유해주셔도 돼요.")]
        saveHistory()
    }

    var canUse: Bool { store.config.hasAI }


    /// **[테스트용]** 대화 전체를 텍스트로 만든다. 출시 전에 이 함수와 채팅 화면의 복사 버튼을 같이 뺀다.
    ///
    /// 화면에 보이는 말풍선뿐 아니라 **도구 호출과 그 결과**까지 함께 담는다 — 문제를 볼 때
    /// 정작 필요한 건 "모델이 어떤 도구를 어떤 인자로 불렀고 앱이 뭐라고 답했는지"인데,
    /// 말풍선만 봐서는 그게 안 보인다(모델이 도구를 안 부르고 부른 척한 적도 있다).
    func transcriptForDebugging() -> String {
        var lines: [String] = ["=== besir AI 대화 기록 ==="]
        for turn in contents {
            let role = turn["role"] as? String ?? "?"
            let parts = turn["parts"] as? [[String: Any]] ?? []
            for part in parts {
                if let text = part["text"] as? String, !text.isEmpty {
                    lines.append("[\(role)] \(text)")
                }
                if let call = part["functionCall"] as? [String: Any] {
                    let name = call["name"] as? String ?? "?"
                    let args = call["args"] as? [String: Any] ?? [:]
                    let shown = args.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
                    lines.append("[도구 호출] \(name)(\(shown))")
                }
                if let resp = part["functionResponse"] as? [String: Any] {
                    let name = resp["name"] as? String ?? "?"
                    let result = (resp["response"] as? [String: Any])?["result"] as? String ?? ""
                    lines.append("[도구 결과] \(name) → \(result)")
                }
            }
        }
        // 지금 적용 중인 기본값도 같이 — 기본값이 비어 있어 생긴 문제가 여러 번 있었다.
        let cfg = store.config
        lines.append("--- 기본값 ---")
        lines.append("이동수단=\(cfg.preferredMode ?? "없음"), 여유=\(cfg.preferredBuffer.map(String.init) ?? "없음"), 알림=\(cfg.preferredNotify.map(String.init) ?? "없음")")
        lines.append("기억=\(rememberedFacts.isEmpty ? "없음" : rememberedFacts.joined(separator: " / "))")
        return lines.joined(separator: "\n")
    }

    // MARK: - 전송

    func send() async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isThinking else { return }
        input = ""
        await submit(text: text, imageData: nil, mimeType: nil, bubbleText: text)
    }

    /// 다른 앱(예: 카카오톡)에서 공유받은 텍스트/이미지를 받아 그대로 파싱·등록을 시도한다.
    /// 공유 확장(Share Extension)이 앱 그룹에 남긴 대기 항목을 처리할 때 호출된다.
    func handleShared(text: String?, imageData: Data?, mimeType: String?) async {
        guard !isThinking else { return }
        let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (trimmed?.isEmpty == false) || imageData != nil else { return }
        isPresented = true
        let bubbleText = trimmed?.isEmpty == false ? trimmed! : "(공유된 이미지)"
        await submit(text: trimmed?.isEmpty == false ? trimmed! : "공유받은 이미지에서 일정 정보를 찾아 등록해줘.",
                     imageData: imageData, mimeType: mimeType, bubbleText: bubbleText)
    }

    private func submit(text: String, imageData: Data?, mimeType: String?, bubbleText: String) async {
        bubbles.append(.init(role: .user, text: bubbleText))
        // 선호를 말하면 모델이 remember_fact를 부르든 말든 앱이 직접 반영한다.
        // (도구를 안 부르고 "기억해둘게요"라고만 답해 설정이 비어 있던 문제.)
        // 이 턴의 시스템 프롬프트부터 바로 반영되므로 모델도 곧장 새 기본값을 본다.
        applyStatedPreferences(from: text)
        repairDanglingToolTurn()   // 방어적 재확인(로드 시점에 이미 고쳐지지만, 만일을 대비).
        var parts: [[String: Any]] = [["text": text]]
        if let imageData, let mimeType {
            parts.append(["inlineData": ["mimeType": mimeType, "data": imageData.base64EncodedString()]])
        }
        // 실패했을 때 되돌아갈 지점. 실패한 턴을 히스토리에 남겨두면 그게 이후 모든 요청에 계속
        // 딸려가 같은 실패를 무한 반복하게 된다(특히 백엔드가 role 순서를 거부하는 경우).
        let historyBeforeTurn = contents
        contents.append(["role": "user", "parts": parts])
        isThinking = true
        defer { isThinking = false; saveHistory() }
        do {
            try await runLoop()
            stripInlineDataFromHistory()   // 이 턴에서 쓴 이미지는 역할을 다했으니 히스토리에서 비운다.
            trimHistory()
        } catch {
            contents = historyBeforeTurn
            bubbles.append(.init(role: .assistant, text: Self.userMessage(for: error)))
        }
    }

    /// 실패 원인을 사용자가 이해하고 다음 행동을 정할 수 있는 문구로 바꾼다.
    private static func userMessage(for error: Error) -> String {
        if (error as? AIError)?.kind == .quotaExceeded {
            return """
            오늘 쓸 수 있는 AI 사용량을 다 썼어요(Cloudflare Workers AI 일일 무료 한도).
            한국 시간 오전 9시(UTC 자정)에 초기화되니 그 뒤에 다시 시도해 주세요.
            그 전에 등록해야 한다면 오른쪽 위 + 버튼으로 직접 추가하실 수 있어요.
            """
        }
        return "죄송해요, 처리 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요."
    }


    /// 사용자가 "앞으로 ~", "주로 ~", "기억해줘" 처럼 **선호를 말한 경우에만** 그 문장에서
    /// 이동수단·도착여유·알림을 읽어 설정에 반영한다.
    ///
    /// 신호어를 요구하는 이유: "내일 자동차로 강남 가야 해"는 이번 일정 얘기지 기본값 설정이
    /// 아니다. 그런 문장까지 기본값을 바꾸면 사용자가 모르는 사이에 설정이 흔들린다.
    private func applyStatedPreferences(from text: String) {
        let signals = ["기억", "주로", "앞으로", "항상", "보통", "기본", "늘 "]
        guard signals.contains(where: { text.contains($0) }) else { return }

        var config = store.config
        var changed: [String] = []
        if let m = Self.mode(in: text), config.preferredMode != m.rawValue {
            config.preferredMode = m.rawValue; changed.append("이동수단 \(m.title)")
        }
        if let b = Self.minutes(in: text, near: ["여유"]), config.preferredBuffer != b {
            config.preferredBuffer = b; changed.append("도착 여유 \(b)분")
        }
        if let n = Self.minutes(in: text, near: ["알림", "분 전"]), config.preferredNotify != n {
            config.preferredNotify = n; changed.append("알림 \(n)분 전")
        }
        guard !changed.isEmpty else { return }
        store.updateConfig(config)
        // 문장은 따로 남기지 않는다 — 값은 설정의 "기본값"에 그대로 보이고, 모델도 대개
        // remember_fact로 요약 문장을 저장한다. 둘 다 남기면 같은 내용이 두 줄로 쌓인다.
    }

    // MARK: - 대화 + 툴 루프

    private func runLoop() async throws {
        // 툴 호출이 이어질 수 있으니 최대 몇 회까지 반복.
        // lastToolSummary: 툴이 이미 성공 실행된 뒤(등록 자체는 끝난 뒤) 뒤이은 "자연스러운 확인 문구"용
        // AI 호출만 실패하는 경우를 위한 폴백. 등록은 이미 끝났으니 이 경우 에러로 취급하면 안 되고
        // (사용자가 "실패"로 오해해 같은 요청을 또 보내면 중복 등록됨), 툴이 직접 만든 결과 문구를 그대로 보여준다.
        var lastToolSummary: String?
        for _ in 0..<5 {
            let response: [String: Any]
            do {
                response = try await callAI()
            } catch {
                if let lastToolSummary { bubbles.append(.init(role: .assistant, text: lastToolSummary)) }
                if lastToolSummary != nil { return }
                throw error
            }
            guard let candidate = (response["candidates"] as? [[String: Any]])?.first,
                  let contentObj = candidate["content"] as? [String: Any],
                  let parts = contentObj["parts"] as? [[String: Any]] else {
                if let lastToolSummary {
                    bubbles.append(.init(role: .assistant, text: lastToolSummary))
                } else {
                    bubbles.append(.init(role: .assistant, text: "죄송해요, 응답을 이해하지 못했어요."))
                }
                return
            }

            // 텍스트 파트를 화면에 표시.
            let text = parts.compactMap { $0["text"] as? String }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                bubbles.append(.init(role: .assistant, text: text))
            }

            // 모델의 이번 턴은 함수 호출 여부와 무관하게 항상 히스토리에 남겨야 한다. 이걸 함수 호출이
            // 있을 때만 남기면(예전 버그), 툴 실행 후 "등록됐어요" 같은 텍스트만 있는 마무리 턴이
            // 히스토리에서 빠져 role 순서가 …tool → user로 이어져 버린다 — Workers AI 백엔드가 이
            // 순서를 거부해("Unexpected role 'user' after role 'tool'") 다음 사용자 메시지가 매번
            // 실패했다(할당량 문제가 아니라 이 히스토리 버그였음).
            contents.append(["role": "model", "parts": parts])

            let functionCalls = parts.compactMap { $0["functionCall"] as? [String: Any] }
            guard !functionCalls.isEmpty else { return }

            // 툴 실행 → 결과를 하나의 function 턴으로 모아 히스토리에 담는다.
            var resultParts: [[String: Any]] = []
            for call in functionCalls {
                let name = call["name"] as? String ?? ""
                let args = call["args"] as? [String: Any] ?? [:]
                let resultText = await executeTool(name: name, input: args)
                resultParts.append(["functionResponse": ["name": name, "response": ["result": resultText]]])
                lastToolSummary = resultText
            }
            contents.append(["role": "function", "parts": resultParts])
        }
        // 5회를 다 돌 때까지 마무리가 안 된 드문 경우에도, 툴 결과가 있으면 보여준다.
        if let lastToolSummary { bubbles.append(.init(role: .assistant, text: lastToolSummary)) }
    }

    // MARK: - AI 호출(프록시 경유, Workers AI — 백엔드는 프록시가 결정)

    private func callAI() async throws -> [String: Any] {
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt()]]],
            "tools": [["functionDeclarations": toolsJSON()]],
            "contents": contents
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        guard let req = store.config.proxyPOSTRequest("/ai/chat", body: data) else {
            throw URLError(.badURL)
        }

        // 일반적인 일시적 네트워크 오류에 대비한 가벼운 재시도(2회).
        var lastError: Error = URLError(.unknown)
        for _ in 0..<2 {
            do {
                let (respData, resp) = try await URLSession.shared.data(for: req)
                let status = (resp as? HTTPURLResponse)?.statusCode ?? -1
                guard (200..<300).contains(status) else {
                    throw Self.classify(status: status, body: respData)
                }
                guard let obj = try JSONSerialization.jsonObject(with: respData) as? [String: Any] else {
                    throw URLError(.cannotParseResponse)
                }
                return obj
            } catch {
                lastError = error
                // 할당량 소진은 재시도해도 결과가 같다 — 남은 요청만 낭비하지 말고 바로 알린다.
                if (error as? AIError)?.kind == .quotaExceeded { break }
            }
        }
        throw lastError
    }

    /// AI 호출 실패의 종류. 원인에 따라 사용자에게 다른 안내를 하기 위해 구분한다 —
    /// 예전에 전부 "처리 중 문제가 생겼어요" 하나로 뭉뚱그려 보여주는 바람에, 히스토리 버그를
    /// 할당량 문제로 오해하고(반대로도) 원인을 찾는 데 오래 걸렸다.
    struct AIError: LocalizedError {
        enum Kind { case quotaExceeded, server }
        let kind: Kind
        let detail: String
        var errorDescription: String? { detail }
    }

    private static func classify(status: Int, body: Data) -> AIError {
        let text = String(data: body, encoding: .utf8) ?? ""
        // Workers AI 일일 무료 한도(neurons) 소진: `{"error":"upstream_error","detail":"AiError: 4006: ..."}`
        if text.contains("4006") || text.localizedCaseInsensitiveContains("neurons") {
            return AIError(kind: .quotaExceeded, detail: text)
        }
        return AIError(kind: .server, detail: "HTTP \(status) \(text.prefix(200))")
    }

    // MARK: - 시스템 프롬프트 / 툴 정의

    private func systemPrompt() -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.timeZone = .current
        df.dateFormat = "yyyy년 M월 d일 (EEEE) a h시 m분"
        let nowStr = df.string(from: Date())
        let loc = location.currentPlaceName ?? "확인 중"
        let favoritesLine = store.favorites.isEmpty ? "" :
            "\n- 사용자의 즐겨찾기 장소: \(store.favorites.map { $0.label }.joined(separator: ", ")). 출발지·목적지·점심장소가 이 이름과 일치하면 그 이름을 그대로 써(origin_query/destination_query/lunch_place_query)."
        // 값으로 저장된 선호는 문장과 따로, 도구 인자에 그대로 넣으라고 못 박아 전달한다
        // (문장만 주면 모델이 해석을 건너뛰고 기본값을 쓰는 일이 있었다).
        //
        // 이동수단은 이 목록에서 빼고 따로 적는다. buffer/notify는 "채워라", mode_this_time은
        // "비워둬라"로 방향이 정반대인데 한 줄에 "도구 인자에 그대로 채워라"로 묶어 놓는 바람에
        // 절대 규칙 2와 정면으로 부딪쳤고, 실기기에서 모델이 규칙 2 쪽을 따르면서 INTEGER에는
        // 없는 '비움'을 0으로 대신 써 저장된 여유·알림 10분이 0으로 덮였다.
        var prefs: [String] = []
        if let b = store.config.preferredBuffer { prefs.append("buffer_minutes=\(b)") }
        if let n = store.config.preferredNotify { prefs.append("notify_lead_minutes=\(n)") }
        let prefsBlock = prefs.isEmpty ? "" :
            "\n- **저장된 기본값 — 묻지 말고 생성 도구 인자에 이 숫자를 그대로 채워라**: " + prefs.joined(separator: ", ")
        let modeBlock = store.config.preferredMode.flatMap { TransportMode(rawValue: $0) }
            .map { "\n- 저장된 기본 이동수단: \($0.title) — 앱이 알아서 쓴다. mode_this_time은 **비워둬라**." } ?? ""
        let factsBlock = rememberedFacts.isEmpty ? "" :
            "\n\n## 기억하고 있는 것(새로 묻지 말고 활용해)\n" + rememberedFacts.map { "- \($0)" }.joined(separator: "\n")
        return """
        besir 일정 도우미. 사용자 말(또는 공유받은 텍스트·이미지)에서 일정을 파악해 도구로 등록한다.
        이미지면 표·텍스트를 읽어 여러 일정이면 각각 도구를 호출한다.
        지금: \(nowStr) (KST) / 현재 위치(참고용, 출발지 기본값 아님): \(loc)\(favoritesLine)\(prefsBlock)\(modeBlock)\(factsBlock)

        # 절대 규칙
        1. 실제 데이터가 필요한 질문(뭐가 등록됐나·몇 건·삭제/수정 대상)은 반드시 list_schedules를 먼저 호출하고 그 결과만 말한다. 제목·시각·건수·가게이름을 지어내면 안 된다.
        2. 일정을 만들 때 도착여유(buffer_minutes)·알림(notify_lead_minutes)은 위 "저장된 기본값" 줄의 숫자를 **그대로 채운다** — 비우거나 0으로 대신하지 마라(0은 "여유 없이"라는 진짜 요청이다). 이동수단은 반대로 mode_this_time을 **비워야** 저장된 수단이 쓰인다. 사용자가 이번 요청에서 다르게 말했으면 그 값을 넣고, 저장된 값도 없고 사용자도 말하지 않았으면 **임의로 정하지 말고 물어본다**.
        3. 출발지: **사용자가 말했으면 반드시 origin_query에 넣어라**(말로만 "회사에서"라고 쓰고 인자를 비우면 엉뚱한 곳에서 출발하는 일정이 만들어진다). 말하지 않았으면 즐겨찾기 "집"을 쓰되, 그것도 없으면 물어본다.
           단 **check_travel_time은 예외**: 등록이 아니라 조회라 되물을 필요가 없다. 바로 호출한다.
        4. 물어서 답을 들으면 그 자리에서 remember_fact로 저장하되, **값은 mode/buffer_minutes/notify_lead_minutes 인자에 넣어라**(문장만 저장하면 다음에 안 쓰인다).
           이미 아는 내용처럼 보여도 저장 요청이 오면 **반드시 도구를 호출해** 값을 최신화한다 — "이미 기억하고 있어요"로 끝내지 마라.
        5. 상대 표현("내일", "다음 주 금요일")은 위 현재 시각 기준으로 정확한 ISO 시각으로 바꾼다.
           "이번 주"는 **오늘이 들어가는 주**다(오늘 날짜를 반드시 포함하게 from_date/to_date를 잡아라).
           조회 결과가 비었는데 도구가 "전체로는 N건 있다"고 알려주면, 날짜를 잘못 잡은 것이니
           범위를 비우고 다시 조회해라 — "일정이 없다"고 잘라 말하면 안 된다.
        6. 답변은 짧고 친근하게. 일정·식사와 무관한 요청은 정중히 거절.
        7. **제목은 되묻지 마라** — 없으면 목적지나 활동 이름으로 알아서 짓는다("강남역 약속"). 되물을 가치가 있는 건 목적지·출발지·시각이다.

        # 어떤 도구를 쓰나
        - 이동만 필요: create_schedule. "3시까지 가야 해"→arrival_iso / "6시에 출발할래"→departure_iso (둘 중 하나만).
        - 그 장소에 머무는 시간이 있으면: create_activity. **오가는 이동도 필요하면 travel_from_query/return_to_query를 같이 넣어 한 번에** 만든다(그래야 활동과 이동이 묶여 같이 움직이고 같이 지워진다. create_schedule로 따로 만들면 안 묶임).
          예) "8~10시 강남에서 친구 만나고 집에 올래" → create_activity(place_query:강남역, start/end, travel_from_query:집, return_to_query:집) 한 번.
        - 반복: create_recurring_schedule. "평일"=월~금. 주기는 사용자 말대로(최대 26주). 격주=every_n_weeks:2, "매월 첫째 주 월"=weekdays:[mon]+nth_week_of_month:1(마지막=-1, 매월 아니면 0), "공휴일 빼고"=skip_holidays:true.
          "9시부터 18시까지"면 9시=arrival_time, 18시=return_time(왕복 원하는지 확인). 점심은 보통 같은 건물이라 lunch_place_query를 **비워둔다** — "밖에서" 같이 명시할 때만 채운다.
        - 이미 있는 일정 고치기: update_schedule (지우고 새로 만들지 말 것).
        - 반복 그룹의 수단/버퍼/알림 수정: update_recurring_schedule. 목록(list_schedules)의 [n] 그룹 번호를 series_number로 주고, 이번 대화에서 만든 그룹이면 번호 없이. **create_recurring_schedule을 다시 부르면 중복 등록된다.** 요일·시각·목적지 변경은 전체 삭제 후 재등록하라고 안내.
        - 먹을 곳: recommend_meal. 메뉴를 좁혀 말하면(일식→초밥) keyword에 그대로 넣어 재검색. 시각만 말하면 at_iso.
          추천 중 하나로 일정을 잡아 달라 하면 create_activity를 부르되 **log_as_meal:true**를 꼭 넣는다(안 넣으면 '최근 먹은 것' 목록에 안 남는다).
        - 등록 없이 소요시간만: check_travel_time.
        - 기억/잊기: remember_fact / forget_fact.

        # 되돌아오는 응답 처리(중요)
        - **겹침**: create_schedule이 "겹친다"며 선택지를 돌려주면 등록된 게 아니다. 사용자에게 물어보고 답을 들으면 **같은 인자에 on_conflict만 추가해** 다시 호출(ignore=그대로 / late_arrival=끝나고 출발). 되묻기만 반복하면 안 된다.
        - **여러 건**: update_schedule이 대상이 여러 건이라며 날짜를 물으면, 확인 후 **같은 인자에 date만 추가해** 다시 호출.
        - **낱개 다수**: delete_schedule이 "N개예요"라고 하면, 재확인 후 **confirm_many:true를 추가해** 다시 호출(그냥 재시도하면 같은 응답만 반복).

        # 삭제
        - 삭제는 되돌릴 수 없다. 도구를 부르기 전에 **텍스트로만** 짧게 확인받는다("오늘 강남역 약속을 삭제할까요?").
        - 확인받으면 delete_schedule을 **한 번만** 호출한다(도구가 다시 묻지 않고 바로 실행됨).
        - 반복 일정에 date를 안 주면 그룹 전체가 삭제된다. "이 회차만"이면 date + whole_series:false.

        # 개별 설정
        - "알림 필요 없어"→notify_enabled:false, "캘린더에 올리지 마"→add_to_calendar:false. 말 안 하면 둘 다 켬.
        """
    }

    /// Gemini function declaration 형식(OpenAPI Schema 서브셋, type은 대문자: STRING/OBJECT/ARRAY/INTEGER).
    private func toolsJSON() -> [[String: Any]] {
        // 설명은 최대한 짧게 유지한다 — 이 배열 전체가 **매 요청마다** 모델에 실려 가므로
        // 길어질수록 하루 사용량(Workers AI neurons)을 그대로 깎아먹는다. 다만 실제 버그를
        // 막으려고 넣은 규칙(재호출 방법·지어내기 금지 등)은 줄이지 않는다.
        // 이름을 그냥 "mode"로 두면 작은 모델이 저장된 기본값이 있어도 습관처럼 채워 넣어
        // 기본값을 덮어버린다(기억시킨 자동차가 대중교통으로 바뀌던 원인). 이름 자체를
        // "이번만 다르게"로 바꿔 기본 동작이 '비워두기'라는 게 드러나게 했다.
        let mode: [String: Any] = ["type": "STRING", "enum": ["car", "transit", "walk"],
                                   "description": "**이번 요청에서만 다른 수단을 쓸 때만** 채운다(예: \"오늘은 걸어갈래\"). 그 외에는 반드시 비워둔다 — 비우면 저장된 기본 이동수단이 쓰인다. 기본값도 없고 사용자도 말 안 했으면 물어본다."]
        let notifyFlag: [String: Any] = ["type": "BOOLEAN", "description": "false=알림 끔. 기본 true."]
        let calFlag: [String: Any] = ["type": "BOOLEAN", "description": "false=구글 캘린더에 안 올림. 기본 true."]
        // 두 생성 도구가 같은 뜻으로 쓴다 — mode·notifyFlag와 같은 이유로 한 곳에서 만들어 돌려쓴다.
        // mode와 달리 여기서는 "채워라"가 맞다. "기본값이 있으면 비워둬"로 적었더니, INTEGER에는
        // 비움을 적을 자리가 없어 모델이 0을 대신 보냈고 저장해 둔 10분이 0으로 덮였다.
        //
        // 설명에 **세 가지가 다 있어야** 한다. ① 저장값이 있으면 그 숫자 ② 없으면 물어보기
        // ③ 0을 비움 대신 쓰지 말기. 하나씩 빠질 때마다 모델에게 열린 길이 줄고, 마지막에 남는 건
        // "아무 값이나 채우기"다 — 한 번 압축하면서 ②를 날렸더니(원래 create_schedule 쪽의
        // "모르면 물어볼 것") 저장값이 없는 사용자는 ①이 안 걸리고 ③이 막혀 갈 데가 없었다.
        // ③은 **명령**으로 적는다("쓰지 마라"). 괄호 안은 이유일 뿐이고, 고쳐야 할 대상이 값의
        // 뜻이 아니라 "선언된 선택 인자는 다 채운다"는 절차라서 서술형으로는 절차를 못 막는다.
        //
        // 줄일 땐 한 인자에 한 글자가 요청당 두 글자인 걸 감안한다 — 호이스팅해도 와이어 비용은
        // 안 줄고 쓰는 도구마다 복제되기 때문. 다만 인자마다 **두 번**이지 네 번이 아니다
        // (호출 지점 네 곳은 두 인자를 합친 수). 직렬화해서 세어 확인했다.
        let bufferArg: [String: Any] = ["type": "INTEGER", "description": "도착 여유(분). 저장된 기본값 있으면 그 숫자를 채우고, 없으면 물어봐라. 0을 비움 대신 쓰지 마라(0=여유 없이)."]
        let notifyArg: [String: Any] = ["type": "INTEGER", "description": "출발 몇 분 전 알림. 저장된 기본값 있으면 그 숫자를 채우고, 없으면 물어봐라. 0을 비움 대신 쓰지 마라(0=출발 시각 알림)."]
        return [[
            "name": "create_schedule",
            "description": "이동 일정 1건 등록(머무는 시간 없이 이동만).",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title": ["type": "STRING", "description": "제목"],
                    "origin_query": ["type": "STRING", "description": "출발지 검색어"],
                    "destination_query": ["type": "STRING", "description": "목적지 검색어"],
                    "arrival_iso": ["type": "STRING", "description": "도착 시각 ISO(예: 2026-07-06T15:00:00). 도착 기준."],
                    "departure_iso": ["type": "STRING", "description": "출발 시각 ISO. 출발 기준(버퍼 0). arrival_iso와 둘 중 하나만."],
                    "mode_this_time": mode,
                    "buffer_minutes": bufferArg,
                    "notify_lead_minutes": notifyArg,
                    "notify_enabled": notifyFlag,
                    "add_to_calendar": calFlag,
                    "on_conflict": ["type": "STRING", "enum": ["ignore", "late_arrival"],
                                    "description": "겹침 응답을 받은 뒤에만 쓴다. 처음엔 비워둘 것."]
                ],
                "required": ["title", "destination_query"]
            ]
        ], [
            "name": "create_activity",
            "description": "그 장소에 머무는 일회성 활동 1건. travel_from_query/return_to_query를 같이 주면 오가는 이동까지 한 번에 만들어 활동과 묶는다(따로 만들면 안 묶임). **왕복이면 return_to_query를 빠뜨리지 마라** — 없으면 돌아오는 이동이 아예 안 만들어진다.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title": ["type": "STRING", "description": "제목"],
                    "place_query": ["type": "STRING", "description": "활동 장소. 이동도 만들려면 필수."],
                    "start_iso": ["type": "STRING", "description": "시작 ISO"],
                    "end_iso": ["type": "STRING", "description": "종료 ISO"],
                    "travel_from_query": ["type": "STRING", "description": "가는 이동의 출발지(선택)"],
                    "return_to_query": ["type": "STRING", "description": "오는 이동의 도착지(선택). travel_from_query를 채웠고 왕복이면 이것도 같이 채운다(보통 travel_from_query와 같은 값)."],
                    "mode_this_time": mode,
                    "travel_mode_this_time": ["type": "STRING", "enum": ["car", "transit", "walk"], "description": "가는 편만 다른 수단일 때만"],
                    "return_mode_this_time": ["type": "STRING", "enum": ["car", "transit", "walk"], "description": "오는 편만 다른 수단일 때만(예: 갈 땐 지하철, 올 땐 택시)"],
                    "notify_enabled": notifyFlag,
                    "add_to_calendar": calFlag,
                    "log_as_meal": ["type": "BOOLEAN", "description": "식사 활동이면 true — '최근 먹은 것' 목록에도 남는다. 기본 false."]
                ],
                "required": ["title", "start_iso", "end_iso"]
            ]
        ], [
            "name": "create_recurring_schedule",
            "description": "반복 출퇴근/등원 일정. 가는 구간은 항상 만들고 return_time·lunch_*는 필요할 때만.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title": ["type": "STRING", "description": "제목"],
                    "origin_query": ["type": "STRING", "description": "출발지 검색어"],
                    "destination_query": ["type": "STRING", "description": "목적지 검색어"],
                    "weekdays": ["type": "ARRAY",
                                 "items": ["type": "STRING", "enum": ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]],
                                 "description": "반복 요일"],
                    "arrival_time": ["type": "STRING", "description": "매회 도착(시작) 'HH:mm'"],
                    "return_time": ["type": "STRING", "description": "복귀 출발 'HH:mm'(주면 돌아오는 구간도 생성)"],
                    "lunch_place_query": ["type": "STRING", "description": "점심 장소가 근무지와 **다를 때만**. 같으면 비워둘 것."],
                    "lunch_start": ["type": "STRING", "description": "점심 시작 'HH:mm'"],
                    "lunch_end": ["type": "STRING", "description": "점심 종료 'HH:mm'"],
                    "start_date": ["type": "STRING", "description": "시작일 'yyyy-MM-dd'(기본 오늘)"],
                    "weeks": ["type": "INTEGER", "description": "반복 주수. 기본 8, 최대 26."],
                    "every_n_weeks": ["type": "INTEGER", "description": "2=격주"],
                    "nth_week_of_month": ["type": "INTEGER", "description": "**\"매월\"이라고 말했을 때만**: 그 달 n번째 요일(1~4, -1=마지막). 매월이 아니면 0"],
                    "confirm_recurrence": ["type": "BOOLEAN", "description": "주기를 되묻는 응답을 받고 사용자가 확인했을 때 true"],
                    "skip_holidays": ["type": "BOOLEAN", "description": "true=한국 공휴일 제외"],
                    "mode_this_time": mode,
                    "buffer_minutes": bufferArg,
                    "notify_lead_minutes": notifyArg
                ],
                "required": ["title", "destination_query", "weekdays", "arrival_time"]
            ]
        ], [
            "name": "update_recurring_schedule",
            "description": "반복 그룹의 수단·버퍼·알림 수정(재생성 금지). 대상은 series_number, 없으면 이번 대화에서 만든 그룹.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    // 이 모델은 선언된 선택 인자를 비우지 못해 INTEGER에 0을 채운다 — 그래서 0을
                    // "안 골랐다"로 읽게 적고 번호는 1부터 센다. 유효한 값을 나열하지 않는다
                    // (nth_week_of_month에서 -1을 골라 35건을 7건으로 만든 적이 있다).
                    "series_number": ["type": "INTEGER", "description": "list_schedules 각 줄의 [n] 반복 그룹 번호. 그 그룹 전체(등원·복귀·점심 함께)를 고른다. 이번 대화에서 만든 그룹이면 0."],
                    // 여긴 "바꿔줘"라는 명시적 수정이라 값을 채우는 게 정상이다(생성 도구의 override와 다름).
                    "mode": ["type": "STRING", "enum": ["car", "transit", "walk"], "description": "바꿀 이동수단(안 바꾸면 비움)"],
                    "buffer_minutes": ["type": "INTEGER", "description": "바꿀 도착 여유(분)"],
                    "notify_lead_minutes": ["type": "INTEGER", "description": "바꿀 알림(분)"],
                    "confirm_zero": ["type": "BOOLEAN", "description": "0으로 바꾸는 게 맞냐고 되묻는 응답을 받고 사용자가 확인했을 때 true"]
                ],
                "required": []
            ]
        ], [
            "name": "update_schedule",
            "description": "이미 등록된 일정 1건의 제목·시각·장소·수단 수정. 여러 건이 걸리면 도구가 날짜를 요구한다.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title_query": ["type": "STRING", "description": "고칠 일정의 현재 제목(일부 일치)"],
                    "date": ["type": "STRING", "description": "대상 특정용 날짜 'yyyy-MM-dd'"],
                    "new_title": ["type": "STRING", "description": "바꿀 제목"],
                    "new_arrival_iso": ["type": "STRING", "description": "새 도착 시각(이동 일정)"],
                    "new_departure_iso": ["type": "STRING", "description": "새 출발 시각(이동 일정)"],
                    "new_start_iso": ["type": "STRING", "description": "새 시작 시각(활동). 묶인 이동도 같이 이동."],
                    "new_end_iso": ["type": "STRING", "description": "새 종료 시각(활동)"],
                    "new_place_query": ["type": "STRING", "description": "바꿀 장소"],
                    "new_mode": ["type": "STRING", "enum": ["car", "transit", "walk"], "description": "바꿀 이동수단"]
                ],
                "required": ["title_query"]
            ]
        ], [
            "name": "list_schedules",
            "description": "실제 등록된 일정 조회(출발 시각 포함). 데이터가 필요한 질문엔 반드시 먼저 호출.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title_query": ["type": "STRING", "description": "제목 검색(일부 일치)"],
                    "from_date": ["type": "STRING", "description": "시작일 'yyyy-MM-dd'"],
                    "to_date": ["type": "STRING", "description": "종료일 'yyyy-MM-dd'(하루면 from과 같게)"]
                ],
                "required": []
            ]
        ], [
            "name": "recommend_meal",
            "description": "먹을 곳을 실제 검색해 추천. 결과에 없는 가게를 지어내면 안 된다.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "keyword": ["type": "STRING", "description": "메뉴·업종(일식, 초밥 등). 좁혀 말하면 그대로."],
                    "category": ["type": "STRING", "enum": ["restaurant", "cafe"], "description": "기본 restaurant"],
                    "at_iso": ["type": "STRING", "description": "이 시각에 있을 장소 주변에서 찾는다"],
                    "place_query": ["type": "STRING", "description": "기준 장소 직접 지정(at_iso보다 우선)"],
                    "radius_meters": ["type": "INTEGER", "description": "반경(m). 사용자가 범위를 말하지 않았으면 0 — 기본 1000m로 찾는다."]
                ],
                "required": []
            ]
        ], [
            "name": "check_travel_time",
            "description": "등록하지 않고 이동시간·도착 시각만 계산한다. **자동차·대중교통·도보 세 가지를 한 번에 돌려주니 수단을 고르거나 물을 필요가 없다.** 출발지도 되묻지 말고 바로 호출해라 — origin_query를 비우면 즐겨찾기 '집' 또는 현재 위치에서 계산한다. 소요시간을 지어내면 안 된다.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "origin_query": ["type": "STRING", "description": "출발지(비우면 집/현재 위치)"],
                    "destination_query": ["type": "STRING", "description": "목적지"],
                    "depart_iso": ["type": "STRING", "description": "출발 시각(비우면 지금)"]
                ],
                "required": ["destination_query"]
            ]
        ], [
            "name": "remember_fact",
            "description": "앞으로도 참고할 사실을 저장한다. **이동수단·도착여유·알림을 물어서 답을 들었으면 반드시 mode/buffer_minutes/notify_lead_minutes에 그 값을 넣어 저장해** — 그래야 다음부터 앱이 자동으로 그 값을 쓴다(문장만 저장하면 놓친다).",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "fact": ["type": "STRING", "description": "짧은 한 문장(예: '주로 자동차로 다님')"],
                    "mode": ["type": "STRING", "enum": ["car", "transit", "walk"], "description": "주로 쓰는 이동수단"],
                    "buffer_minutes": ["type": "INTEGER", "description": "기본 도착 여유(분)"],
                    "notify_lead_minutes": ["type": "INTEGER", "description": "기본 알림(출발 몇 분 전)"]
                ],
                "required": []
            ]
        ], [
            "name": "forget_fact",
            "description": "저장된 기억 삭제.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "fact_query": ["type": "STRING", "description": "지울 기억의 일부 문구"],
                    "all": ["type": "BOOLEAN", "description": "true=전부 삭제"]
                ],
                "required": []
            ]
        ], [
            "name": "delete_schedule",
            "description": "제목/날짜로 일정 삭제. **텍스트로 확인받은 뒤 한 번만** 호출(도구가 되묻지 않고 바로 실행).",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title_query": ["type": "STRING", "description": "지울 제목(일부 일치). date가 있으면 생략 가능."],
                    "date": ["type": "STRING", "description": "'yyyy-MM-dd'. 제목 없이 이것만 주면 그 날 전부."],
                    "whole_series": ["type": "BOOLEAN", "description": "반복: 전체=true(기본), 이 회차만=false(date 필요)"],
                    "confirm_many": ["type": "BOOLEAN", "description": "\"N개예요\" 응답을 받고 사용자가 재확인했을 때 true"]
                ],
                "required": []
            ]
        ]]
    }


    // MARK: - 사용자 선호 기본값
    //
    // 모델이 인자를 빠뜨려도 지켜지도록, 저장된 선호값을 실행부에서 직접 기본값으로 쓴다.
    // (기억시켜 둔 뒤에도 모델이 mode를 안 넘겨 대중교통으로 계산되던 문제를 막는다.)

    private func resolvedMode(_ raw: Any?) -> TransportMode {
        if let s = raw as? String, let m = TransportMode(rawValue: s) { return m }
        if let s = store.config.preferredMode, let m = TransportMode(rawValue: s) { return m }
        return .transit
    }
    private var defaultBuffer: Int { store.config.preferredBuffer ?? 10 }
    private var defaultNotify: Int { store.config.preferredNotify ?? 30 }

    // MARK: - 툴 실행

    private func executeTool(name: String, input: [String: Any]) async -> String {
        switch name {
        case "create_schedule": return await executeCreateSchedule(input)
        case "create_activity": return await executeCreateActivity(input)
        case "create_recurring_schedule": return await executeCreateRecurringSchedule(input)
        case "update_recurring_schedule": return await executeUpdateRecurringSchedule(input)
        case "remember_fact": return executeRememberFact(input)
        case "list_schedules": return executeListSchedules(input)
        case "check_travel_time": return await executeCheckTravelTime(input)
        case "recommend_meal": return await executeRecommendMeal(input)
        case "forget_fact": return executeForgetFact(input)
        case "update_schedule": return await executeUpdateSchedule(input)
        case "delete_schedule": return executeDeleteSchedule(input)
        default: return "알 수 없는 도구입니다."
        }
    }

    private func executeCreateSchedule(_ input: [String: Any]) async -> String {
        guard let title = (input["title"] as? String)?.trimmingCharacters(in: .whitespaces), !title.isEmpty,
              let destQuery = (input["destination_query"] as? String)?.trimmingCharacters(in: .whitespaces), !destQuery.isEmpty else {
            return "일정 정보가 부족합니다. 제목과 목적지를 다시 확인해 주세요."
        }
        // 도착 기준 / 출발 기준은 사용자가 어느 쪽 시각을 말했는지로 정해진다("3시까지 가야 해" vs
        // "6시에 출발할래"). 둘 다 오면 도착을 우선한다 — 도착이 보통 지켜야 하는 약속이다.
        let anchor: ScheduleAnchor
        let anchorDate: Date
        if let iso = input["arrival_iso"] as? String, let d = parseDate(iso) {
            anchor = .arrival; anchorDate = d
        } else if let iso = input["departure_iso"] as? String, let d = parseDate(iso) {
            anchor = .departure; anchorDate = d
        } else {
            return "시각을 이해하지 못했어요. 도착 시각(arrival_iso) 또는 출발 시각(departure_iso) 중 하나를 정확한 날짜·시각으로 넣어주세요."
        }

        let mode = resolvedMode(input["mode_this_time"])
        // 출발 기준 구간은 버퍼 개념이 없다(도착 여유를 둘 대상이 없음).
        let buffer = anchor == .departure ? 0 : (intValue(input["buffer_minutes"]) ?? defaultBuffer)
        let notify = intValue(input["notify_lead_minutes"]) ?? defaultNotify

        guard let origin = await resolveOrigin(input["origin_query"] as? String) else {
            return "현재 위치를 아직 확인하지 못했어요. 위치 권한을 켠 뒤 다시 시도해 주세요."
        }
        guard let dest = await resolveDestination(destQuery) else { return placeNotFound(destQuery) }

        // 출발지와 목적지가 사실상 같으면 만들지 않는다. 모델이 origin_query를 빠뜨려
        // 기본 출발지(즐겨찾기 '집')가 잡히면 "집 → 집"이 되어 이동시간 0짜리 일정이 조용히
        // 만들어진다(실제로 "회사에서 출발"이라고 말했는데 그렇게 등록된 적이 있다).
        if Self.isSamePlace(origin, dest) {
            return "출발지와 목적지가 '\(origin.name)'으로 같아요. 어디서 출발하는지 origin_query에 넣어 다시 호출해."
        }

        // 충돌을 만들기 전에 판단하려면 이동시간이 먼저 필요하다. 여기서 구한 값을 addEvent에
        // 그대로 넘겨(travelSecondsHint) 외부 길찾기 API를 두 번 호출하지 않는다.
        let seconds = await store.travelSeconds(from: origin, to: dest, mode: mode)
        let onConflict = (input["on_conflict"] as? String)?.lowercased()

        var finalAnchor = anchor
        var finalDate = anchorDate
        var lateBy: Int?

        if let seconds, onConflict != "ignore" {
            let plannedDeparture = anchor == .arrival
                ? anchorDate.addingTimeInterval(-seconds - Double(buffer) * 60) : anchorDate
            let plannedArrival = anchor == .arrival
                ? anchorDate : anchorDate.addingTimeInterval(seconds)
            let found = store.conflicts(departure: plannedDeparture, arrival: plannedArrival)
            if let last = found.map({ $0.end }).max() {   // 겹치는 게 없으면 nil
                if onConflict == "late_arrival" {
                    // 겹치는 일정이 모두 끝난 시각에 출발 → 그만큼 늦게 도착(출발 기준으로 전환).
                    finalAnchor = .departure
                    finalDate = last
                    lateBy = Int(last.addingTimeInterval(seconds).timeIntervalSince(plannedArrival) / 60)
                } else {
                    return conflictPrompt(found, plannedDeparture: plannedDeparture,
                                          plannedArrival: plannedArrival,
                                          lateDeparture: last, travelSeconds: seconds)
                }
            }
        }

        await store.addEvent(title: title,
                             origin: origin,
                             destination: dest,
                             arrivalDate: finalDate,
                             mode: mode,
                             bufferMinutes: buffer,
                             notifyLeadMinutes: notify,
                             anchor: finalAnchor,
                             travelSecondsHint: seconds,
                             notifyEnabled: (input["notify_enabled"] as? Bool) ?? true,
                             syncToCalendar: (input["add_to_calendar"] as? Bool) ?? true)

        // 방금 만든 일정을 찾아 출발시각을 요약(모델이 자연스럽게 다시 안내하도록).
        let created = store.events.last { $0.title == title && $0.destination.name == dest.name }
        // 출발지를 함께 남긴다 — 되묻지 않고 자동으로 정해진 경우 엉뚱한 곳일 수 있어
        // 사용자가 바로 알아챌 수 있어야 한다(등록 시점 현재 위치가 굳는 게 이 앱의 약점).
        var summary = "등록 완료 — 제목 '\(title)', '\(origin.name)' → '\(dest.name)', 이동수단 \(mode.title)."
        // travelSeconds가 없으면 출발·도착이 같은 시각으로 남는다 — 성공한 것처럼 보고하면 안 된다.
        if let c = created, let dep = c.departureDate, c.travelSeconds != nil {
            summary += " 출발 \(Self.when(dep)) → 도착 \(Self.when(c.arrivalDate)), 출발 \(notify)분 전 알림 예약됨."
        } else {
            summary += " ⚠️ 다만 이동시간을 계산하지 못해 출발·도착 시각이 비어 있어요 — 사용자에게 알려주고 장소가 맞는지 확인해."
        }
        if let lateBy, lateBy > 0 {
            summary += " 겹치는 일정이 끝난 뒤 출발하도록 잡아서 원래 계획보다 \(lateBy)분 늦게 도착해요 — 상대방에게 알려야 할 수도 있다고 안내해."
        }
        return summary
    }

    /// 충돌을 발견했을 때, 일정을 만들지 않고 모델에게 선택지를 돌려준다.
    /// 다시 호출할 때 **무엇을 추가해야 하는지 파라미터 이름까지 명시**한다 — 작은 모델은
    /// 열린 질문을 돌려주면 같은 호출을 반복하기만 해서(삭제 확인 무한루프 전례) 이렇게 못 박아야 한다.
    private func conflictPrompt(_ found: [Store.Conflict],
                                plannedDeparture: Date,
                                plannedArrival: Date,
                                lateDeparture: Date,
                                travelSeconds: TimeInterval) -> String {
        let names = found.map { "'\($0.title)'(\(Self.when($0.start))~\(Self.when($0.end)))" }.joined(separator: ", ")
        let lateArrival = lateDeparture.addingTimeInterval(travelSeconds)
        let lateBy = Int(lateArrival.timeIntervalSince(plannedArrival) / 60)
        return """
        아직 등록하지 않았어요 — 기존 일정과 시간이 겹칩니다.
        계획대로면 \(Self.when(plannedDeparture))에 출발해 \(Self.when(plannedArrival))에 도착하는데, \(names)와 겹쳐요.
        사용자에게 아래 둘 중 무엇을 원하는지 물어보고, 답을 들으면 **방금과 똑같은 인자에 on_conflict만 추가해서 이 도구를 한 번 더** 호출하세요.
        ① 겹쳐도 예정대로 등록 → on_conflict:"ignore"
        ② 겹치는 일정이 끝나는 \(Self.when(lateDeparture))에 출발(도착 \(Self.when(lateArrival)), \(lateBy)분 늦음) → on_conflict:"late_arrival"
        """
    }

    /// 일회성 활동 블록(머무는 시간)을 만든다. 활동끼리는 겹치는 게 정상이라(근무 중 점심 등)
    /// 충돌 검사를 하지 않는다 — 충돌 검사는 이동 구간에만 적용된다.
    private func executeCreateActivity(_ input: [String: Any]) async -> String {
        guard let title = (input["title"] as? String)?.trimmingCharacters(in: .whitespaces), !title.isEmpty,
              let startISO = input["start_iso"] as? String, let start = parseDate(startISO),
              let endISO = input["end_iso"] as? String, let end = parseDate(endISO) else {
            return "활동 정보가 부족합니다. 제목과 시작·종료 시각을 다시 확인해 주세요."
        }
        guard end > start else { return "종료 시각이 시작 시각보다 빨라요. 다시 확인해 주세요." }

        var place: Place?
        if let q = (input["place_query"] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            place = await resolveDestination(q)
        }
        func resolve(_ key: String) async -> Place? {
            guard let q = (input[key] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty else { return nil }
            return await resolveDestination(q)
        }
        let from = await resolve("travel_from_query")
        let to = await resolve("return_to_query")
        // 가는 편·오는 편 수단을 따로 받을 수 있게 한다(안 주면 mode를 양쪽에 쓴다).
        let mode = resolvedMode(input["mode_this_time"])
        let outboundMode = (input["travel_mode_this_time"] as? String).flatMap { TransportMode(rawValue: $0) } ?? mode
        let returnMode = (input["return_mode_this_time"] as? String).flatMap { TransportMode(rawValue: $0) } ?? mode

        if (from != nil || to != nil) && place == nil {
            return "이동까지 만들려면 활동 장소(place_query)가 필요해요. 어디서 하는 일정인지 물어봐 주세요."
        }
        let result = await store.addActivityWithTravel(
            title: title, location: place, startDate: start, endDate: end,
            travelFrom: from, returnTo: to, outboundMode: outboundMode, returnMode: returnMode,
            bufferMinutes: defaultBuffer, notifyLeadMinutes: defaultNotify,
            notifyEnabled: (input["notify_enabled"] as? Bool) ?? true,
            syncToCalendar: (input["add_to_calendar"] as? Bool) ?? true)
        let madeLegs = result.travelLegs
        // FullSirView.save()와 같은 방식 — 제목·시각으로 되찾지 않고 방금 만든 활동의 id를 직접 받는다.
        if (input["log_as_meal"] as? Bool) == true {
            store.addMeal(category: .diningOut, title: title, place: place,
                          activityId: result.activityId, plannedAt: start)
        }

        let where_ = place.map { " 장소 '\($0.name)'," } ?? ""
        var summary = "활동 블록 등록 완료 — '\(title)',\(where_) \(Self.when(start)) ~ \(Self.when(end))."
        if madeLegs > 0 {
            let modeText = outboundMode == returnMode ? outboundMode.title
                : "가는 편 \(outboundMode.title) · 오는 편 \(returnMode.title)"
            summary += " 오가는 이동 \(madeLegs)건도 활동에 묶어서 만들었어요(\(modeText))."
            // 여기선 겹쳐도 만들기를 막지 않는다(한 번에 여러 개를 만드는 도구라 되묻기가 꼬인다) —
            // 대신 겹치는 게 있으면 알려주고 사용자가 판단하게 한다.
            let warnings = store.events
                .filter { $0.linkedActivityId != nil && $0.departureDate != nil }
                .suffix(madeLegs)
                .flatMap { leg -> [String] in
                    guard let dep = leg.departureDate else { return [] }
                    return store.conflicts(departure: dep, arrival: leg.arrivalDate, excludingEventId: leg.id)
                        .filter { $0.title != title }
                        .map { "'\($0.title)'(\(Self.when($0.start))~\(Self.when($0.end)))" }
                }
            if !warnings.isEmpty {
                summary += " 다만 \(Set(warnings).sorted().joined(separator: ", "))와 시간이 겹쳐요 — 사용자에게 알려줘."
            }
        }
        return summary
    }

    private static let whenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h시 m분"
        return f
    }()
    private static func when(_ d: Date) -> String { whenFormatter.string(from: d) }

    /// 출퇴근/등원형 반복 일정. 기본은 "도착" 구간 하나지만, return_time을 주면 복귀(귀가) 구간을,
    /// lunch_place_query(+lunch_start/lunch_end)를 주면 점심 이동 구간(왕복)을 같은 반복 그룹으로 추가 생성한다.
    /// 점심 장소가 근무지와 같으면(가장 흔한 경우) lunch_place_query를 비워 이동 구간을 만들지 않는다.
    private func executeCreateRecurringSchedule(_ input: [String: Any]) async -> String {
        guard let title = (input["title"] as? String)?.trimmingCharacters(in: .whitespaces), !title.isEmpty,
              let destQuery = (input["destination_query"] as? String)?.trimmingCharacters(in: .whitespaces), !destQuery.isEmpty,
              let weekdayStrings = input["weekdays"] as? [String], !weekdayStrings.isEmpty,
              let timeStr = input["arrival_time"] as? String,
              let (hour, minute) = parseTime(timeStr) else {
            return "반복 일정 정보가 부족합니다. 제목, 목적지, 반복 요일, 도착 시각을 다시 확인해 주세요."
        }
        let weekdays = Set(weekdayStrings.compactMap(Self.weekdaySymbol))
        guard !weekdays.isEmpty else {
            return "반복 요일을 이해하지 못했어요. 요일을 다시 말씀해 주세요."
        }
        // 장소 검색(네트워크)보다 먼저 본다 — 어차피 되돌려 보낼 호출이면 길찾기·검색을 낭비할 이유가 없다.
        if let ask = recurringArgumentIssue(input, weekdayCount: weekdays.count) { return ask }
        // 매주(기본) / 격주 / 매월 n번째 요일 / 공휴일 제외를 하나의 규칙으로 묶는다.
        let rule = RecurrenceRule(weekdays: weekdays,
                                  everyNWeeks: everyNWeeksArgument(input),
                                  nthWeekOfMonth: nthWeekArgument(input),
                                  skipHolidays: (input["skip_holidays"] as? Bool) ?? false)
        let mode = resolvedMode(input["mode_this_time"])
        let buffer = intValue(input["buffer_minutes"]) ?? defaultBuffer
        let notify = intValue(input["notify_lead_minutes"]) ?? defaultNotify
        let weeks = weeksArgument(input) ?? 8
        let startDate = (input["start_date"] as? String).flatMap(parseDay) ?? Date()
        let originQuery = input["origin_query"] as? String

        guard let origin = await resolveOrigin(originQuery) else {
            return "출발지를 확인하지 못했어요. 어디서 출발하는지 알려주시거나 즐겨찾기에 장소를 추가해 주세요."
        }
        guard let dest = await resolveDestination(destQuery) else { return placeNotFound(destQuery) }

        // 1) 등원/출근(도착) 구간.
        let leg1 = await store.addRecurringEvents(title: title, origin: origin, destination: dest,
                                                   rule: rule, anchor: .arrival(hour: hour, minute: minute),
                                                   startDate: startDate, weeks: weeks, mode: mode,
                                                   bufferMinutes: buffer, notifyLeadMinutes: notify)
        guard leg1.count > 0 else {
            return "반복 일정을 생성하지 못했어요(지정한 요일·기간에 해당하는 날짜가 없어요)."
        }
        let recurrenceId = leg1.recurrenceId
        lastRecurrenceId = recurrenceId
        // 확인은 **실제로 만들어졌을 때** 소진된다. 가드를 통과한 자리에서 지우면 그 뒤 출발지·목적지
        // 해석이나 날짜 계산이 실패했을 때 멀쩡한 확인이 같이 날아가, 모델이 사용자에게 같은 걸 또 묻는다.
        recurrenceConfirmAsk = nil
        var totalCount = leg1.count
        var parts = ["등원/출근 \(leg1.count)건(도착 \(String(format: "%02d:%02d", hour, minute)))"]

        // 2) 복귀(귀가) 구간 — 종료 후 이 시각에 출발. 있으면 "체류" 활동 블록(9시~18시 같은 실제 활동 시간)도 같이 만든다.
        var activityCount = 0
        if let returnStr = input["return_time"] as? String, let (rH, rM) = parseTime(returnStr) {
            let leg2 = await store.addRecurringEvents(title: "\(title) (복귀)", origin: dest, destination: origin,
                                                       rule: rule, anchor: .departure(hour: rH, minute: rM),
                                                       startDate: startDate, weeks: weeks, mode: mode,
                                                       bufferMinutes: 0, notifyLeadMinutes: notify,
                                                       recurrenceId: recurrenceId)
            totalCount += leg2.count
            parts.append("복귀 \(leg2.count)건(출발 \(String(format: "%02d:%02d", rH, rM)))")

            let activityLeg = await store.addRecurringActivities(title: title, location: dest, rule: rule,
                                                                  startHour: hour, startMinute: minute,
                                                                  endHour: rH, endMinute: rM,
                                                                  startDate: startDate, weeks: weeks,
                                                                  recurrenceId: recurrenceId)
            activityCount += activityLeg
        }

        // 3) 점심시간 — 활동 블록은 항상 추가하고, 왕복 이동 구간은 `lunch_place_query`가 있고
        //    검색에 성공했을 때만 붙인다. **장소를 근무지와 비교하지는 않는다** — 같은 장소를 적어도
        //    이동 구간이 생긴다(`isSamePlace` 가드는 create_schedule 경로 전용).
        //    예전 주석이 "장소가 다르면 추가"라고 잘못 적혀 있었고, SPEC REQ-021이 그걸 옮겨 적었다.
        if let lsStr = input["lunch_start"] as? String, let (lsH, lsM) = parseTime(lsStr),
           let leStr = input["lunch_end"] as? String, let (leH, leM) = parseTime(leStr) {
            let lunchQuery = (input["lunch_place_query"] as? String)?.trimmingCharacters(in: .whitespaces)
            var lunchPlace: Place? = nil
            if let q = lunchQuery, !q.isEmpty {
                lunchPlace = await resolveDestination(q)
                if let lunchPlace {
                    let leg3 = await store.addRecurringEvents(title: "\(title) - 점심 이동", origin: dest, destination: lunchPlace,
                                                               rule: rule, anchor: .arrival(hour: lsH, minute: lsM),
                                                               startDate: startDate, weeks: weeks, mode: mode,
                                                               bufferMinutes: 0, notifyLeadMinutes: notify,
                                                               recurrenceId: recurrenceId)
                    let leg4 = await store.addRecurringEvents(title: "\(title) - 점심 후 복귀", origin: lunchPlace, destination: dest,
                                                               rule: rule, anchor: .departure(hour: leH, minute: leM),
                                                               startDate: startDate, weeks: weeks, mode: mode,
                                                               bufferMinutes: 0, notifyLeadMinutes: notify,
                                                               recurrenceId: recurrenceId)
                    totalCount += leg3.count + leg4.count
                    parts.append("점심 이동 왕복 \(leg3.count + leg4.count)건('\(lunchPlace.name)')")
                } else {
                    parts.append("(점심 장소 '\(q)'는 찾지 못해 이동 구간은 생략)")
                }
            }
            let lunchActivity = await store.addRecurringActivities(title: "\(title) - 점심시간", location: lunchPlace ?? dest,
                                                                    rule: rule,
                                                                    startHour: lsH, startMinute: lsM,
                                                                    endHour: leH, endMinute: leM,
                                                                    startDate: startDate, weeks: weeks,
                                                                    recurrenceId: recurrenceId)
            activityCount += lunchActivity
        }

        // 활동 블록도 합계에 넣는다. "총 N건" 뒤에 나열한 항목을 사용자가 그대로 세어보기 때문에,
        // 목록에는 적으면서 합계에서만 빼면 숫자가 안 맞는다(실기기에서 "총 4건"이라 해놓고 6건을
        // 나열했다). 이동이냐 활동이냐는 앱의 구분이고, 사용자에겐 캘린더에 생긴 항목이 전부
        // 같은 "건"이다 — 같은 반복 그룹이라 지울 때도 같이 지워진다.
        if activityCount > 0 {
            totalCount += activityCount
            parts.append("시간표(활동) 블록 \(activityCount)건")
        }

        // 실제로 적용된 여유·알림을 적는다. 모델이 뭘 보냈든 사용자는 **결과**를 보게 된다 —
        // 위 totalCount 수정과 같은 이유다. 값을 적용하는 네 경로 중 여기만 둘 다 안 보여줬고,
        // 하필 그 경로에서 0으로 덮인 35건이 아무도 모르게 기기까지 갔다.
        return "등록 완료 — '\(title)' 총 \(totalCount)건 등록했어요: \(parts.joined(separator: ", ")). 출발지 '\(origin.name)' ↔ 목적지 '\(dest.name)', 이동수단 \(mode.title), 도착 여유 \(buffer)분, 출발 \(notify)분 전 알림. 전체를 지우려면 아무 일정이나 열어 '반복 일정 전체 삭제'를 눌러주세요."
    }

    /// `nth_week_of_month`를 읽는 **단 한 곳**(가드와 RecurrenceRule이 같은 값을 보게 — 계약 5).
    ///
    /// 0은 오류가 아니라 "해당 없음"으로 읽는다. 이 모델은 선언된 선택 인자를 비워두지 못하고 전부
    /// 채워 보낸다 — 같은 호출에 lunch_start·lunch_end·return_time이 빈 문자열로 같이 왔다. 문자열은
    /// 빈 값으로 "없음"을 말할 수 있지만 INTEGER에는 그 자리가 0뿐이다. 빈 문자열을 resolvedMode·
    /// resolveOrigin이 조용히 흘려보내는 것과 같은 처리를 숫자 쪽에도 해준다.
    /// 툴 선언과 시스템 프롬프트에도 "매월이 아니면 0"이라고 적어 뒀다 — 앱만 알고 모델은 모르면,
    /// 되돌려 보낼 때 모델이 쓸 수 있는 탈출로가 없어 선언에 적힌 1~4·-1 중 하나를 다시 고른다.
    ///
    /// **인자마다 따로 판단한다 — 0을 일괄로 "없음" 처리하는 헬퍼로 합치지 말 것.**
    /// · `nth_week_of_month`·`weeks`는 0에 뜻이 없다("0번째 주"도 "0주짜리 반복"도 없다).
    ///   그래서 0은 모델의 "없음"으로만 읽힌다.
    /// · `buffer_minutes`·`notify_lead_minutes`의 0은 사용자가 실제로 할 수 있는 말이다
    ///   ("여유 없이", "출발 시각에 알림" — 실제로 executeCreateSchedule이 출발 기준 일정에 0을 넣는다).
    ///   여기까지 없앰 처리하면 진짜 요청을 버리고 기억해둔 기본값을 조용히 끼워 넣는다.
    ///   아래 recurringArgumentIssue 주석의 "값을 조용히 버리는 건 조용히 따르는 것만큼 나쁘다"가
    ///   정확히 그 경우다. 그 둘은 그대로 둔다.
    private func nthWeekArgument(_ input: [String: Any]) -> Int? {
        guard let nth = intValue(input["nth_week_of_month"]), nth != 0 else { return nil }
        return nth
    }

    /// `weeks`를 읽는 **단 한 곳**(되묻기 판단과 실제 생성이 같은 값을 보게 — 계약 5).
    ///
    /// 0은 위와 같은 이유로 "아직 안 정해짐"이다. 걸러내지 않으면 되묻기 조건(`== nil`)이 빗나가
    /// 사용자에게 기간을 묻지도 않고, Store의 `min(max(weeks, 1), maxRecurrenceWeeks)`가 1주로
    /// 깎아 한 주짜리 반복이 조용히 만들어진다 — 등록은 "성공"인데 결과가 틀린,
    /// nth_week_of_month와 똑같은 모양이다. 음수도 같은 이유로 막는다(역시 1주로 깎인다).
    private func weeksArgument(_ input: [String: Any]) -> Int? {
        guard let weeks = intValue(input["weeks"]), weeks > 0 else { return nil }
        return weeks
    }

    /// `every_n_weeks`를 읽는 **단 한 곳**(가드와 RecurrenceRule이 같은 값을 보게 — 계약 5).
    /// 위 둘과 달리 Int?가 아니라 Int다: 0도 없음도 "매주"라는 같은 뜻이라 호출부가 구분할 게 없다.
    /// 두 곳에 `max(1, ... ?? 1)`이 똑같이 적혀 있었다 — 지금은 값이 같지만 한쪽만 고쳐지면
    /// 되묻기 판단과 실제 생성이 서로 다른 주기를 보게 된다(렌더링·히트테스트가 어긋났던 그 모양).
    private func everyNWeeksArgument(_ input: [String: Any]) -> Int {
        max(1, intValue(input["every_n_weeks"]) ?? 1)
    }

    /// 반복 일정을 만들기 **전에** 인자를 점검한다. 되돌려 보낼 이유가 있으면 모델에게 줄 안내를,
    /// 없으면 nil. 프롬프트로 타이르지 않고 실행부에서 막는 이유는, 여기 걸리는 게 전부 "모델이
    /// 인자를 잘못 채운" 경우라 코드가 확실하고 매 요청 토큰도 더 먹지 않기 때문이다.
    ///
    /// ① 주기 인자(`nth_week_of_month`·`every_n_weeks`)는 사용자가 말했을 때만 채워야 하는데,
    ///    "평일 9시부터 6시까지" 한 문장에 모델이 `nth_week_of_month:1`을 얹어 매달 1~7일에만
    ///    일정이 생긴 적이 있다(9/1~9/7, 10/1~10/7 …). 요일이 3개 이상이면 "매월 첫째 주 평일
    ///    전체" 같은 아주 드문 요청이 아닌 한 잘못 채운 것이다.
    /// ② 기간(`weeks`)을 비우면 조용히 8주가 적용된다. 요일이 많은 = 오래 다니는 일정은 사용자가
    ///    직접 정하길 기대하므로 되묻는다(요일 1~2개짜리는 그대로 8주로 둔다 — 매번 물으면 귀찮다).
    ///
    /// ①의 확인(`confirm_recurrence`)은 **앱이 그 조합을 실제로 되물은 뒤**에만 인정한다(`recurrenceConfirmAsk`).
    ///
    /// 값을 조용히 버리는 건 조용히 따르는 것만큼 나쁘다. **아직 만들지 않았다**고 알리고 무엇을
    /// 붙여 다시 부르면 되는지까지 준다 — on_conflict·confirm_many와 같은 방식이다(탈출 인자 없이
    /// 되묻기만 하면 모델이 같은 호출을 그대로 반복한다).
    private func recurringArgumentIssue(_ input: [String: Any], weekdayCount: Int) -> String? {
        let nth = nthWeekArgument(input)
        // 1~4·-1 밖의 값은 사용자가 뭐라 했든 규칙으로 표현할 수 없다 — 확인으로 통과시키지 않는다.
        if let nth, nth != -1, !(1...4).contains(nth) {
            return "아직 만들지 않았어요. nth_week_of_month에 쓸 수 없는 값(\(nth))이 들어왔어요. **nth_week_of_month:0**으로 두고 나머지 인자는 그대로 둔 채 다시 호출해 — 매주 반복이 됩니다. 사용자가 '매월 몇째 주'라고 말한 게 확실할 때만, 몇째 주인지 사용자에게 먼저 물어보고 답을 들은 뒤에 다시 호출해."
        }

        // 요일 3개 이상 = "평일 전체" 같은 통근형. 주기 인자와 같이 오면 십중팔구 잘못 채운 것이다.
        let many = weekdayCount >= 3
        let interval = everyNWeeksArgument(input)
        var asks: [String] = []
        // 확인은 앱이 ①을 **이 조합 그대로** 되물었을 때만 유효하다 — 모델이 스스로 켜서 보낸 값도,
        // 다른 호출에 대해 받아둔 확인도 확인이 아니다.
        let asked = RecurrenceAsk(nth: nth, interval: interval, weekdayCount: weekdayCount)
        let confirmed = recurrenceConfirmAsk == asked && (input["confirm_recurrence"] as? Bool) == true
        if many, !confirmed {
            var cycle: String? = nil
            // "매월 1번째 주"는 어색해서 사용자에게 그대로 전달되면 티가 난다 — 서수로 읽어준다.
            if let nth { cycle = "매월 \(Self.nthWeekLabel(nth)) 주에만" }
            else if interval > 1 { cycle = "\(interval)주 간격으로만" }
            if let cycle {
                // 여기가 유일한 되묻기 지점이다 — 이 조합을 그대로 다시 들고 오는 호출의
                // confirm_recurrence만 진짜 확인으로 친다.
                recurrenceConfirmAsk = asked
                asks.append("· \(cycle) 반복하게 돼 있는데 요일은 \(weekdayCount)개예요. 매주 반복이 맞으면 nth_week_of_month:0·every_n_weeks:1로 두고, 그 주기가 정말 맞으면 confirm_recurrence:true를 붙여 다시 호출해.")
            }
        }
        if many, weeksArgument(input) == nil {
            asks.append("· 언제부터 몇 주간 다니는지 아직 안 정해졌어요. 사용자에게 물어보고 start_date·weeks를 채워 다시 호출해(최대 26주. 사용자가 안 정하면 weeks:8).")
        }
        guard !asks.isEmpty else { return nil }
        // 두 가지가 같이 걸리면 한 번에 묻는다 — 나눠 물으면 사용자가 두 번 답해야 한다.
        return "아직 만들지 않았어요. 아래를 **한 번에** 사용자에게 확인하고, 답을 들으면 같은 인자에 고쳐서 다시 호출해.\n" + asks.joined(separator: "\n")
    }

    private static let nthWeekLabels = ["첫째", "둘째", "셋째", "넷째"]
    private static func nthWeekLabel(_ nth: Int) -> String {
        (1...4).contains(nth) ? nthWeekLabels[nth - 1] : "마지막"
    }

    /// 반복 일정 그룹을 새로 만들지 않고 그대로 수정한다(이동수단·버퍼·알림). 대상은 series_number로
    /// 고르고, 없으면 이 대화에서 방금 만든 그룹(lastRecurrenceId).
    private func executeUpdateRecurringSchedule(_ input: [String: Any]) async -> String {
        // 대상 결정이 인자 점검보다 앞선다 — 대상 없이는 고칠 것 자체가 없다. 번호는 1부터이고
        // 0은 "안 골랐다"(선언에 적은 대로). 음수도 여기서 잡는다: 조용히 lastRecurrenceId로
        // 흘리면 nth_week_of_month의 -1과 같은 모양(잘못 채운 값이 조용히 적용)이 된다.
        let seriesNumber = intValue(input["series_number"]) ?? 0
        var resolvedByNumber = false
        let resolved: UUID?
        if seriesNumber != 0 {
            guard let rid = seriesNumbers.first(where: { $0.value == seriesNumber })?.key else {
                // 탈출구를 list_schedules 재호출로 준다 — 모델이 할 수 있는 행동이고, 번호를
                // 다시 보면 스스로 바로잡는다(recurrenceConfirmAsk 계열과 같은 방식).
                return "그 번호의 반복 그룹을 찾지 못했어요. 번호는 이번 대화에서 목록을 보여줄 때 붙은 것이라 앱을 다시 켰거나 새 대화를 시작했으면 달라져요. list_schedules를 다시 호출해 각 줄의 [n] 번호를 확인한 뒤, 그 번호를 series_number에 넣어 다시 호출해."
            }
            resolved = rid
            resolvedByNumber = true
        } else {
            resolved = lastRecurrenceId
        }
        guard let recurrenceId = resolved else {
            return "이 대화에서 만든 반복 일정을 찾지 못했어요. 어떤 일정을 수정할지 다시 말씀해 주시거나, 새로 등록해 주세요."
        }
        let mode = (input["mode"] as? String).flatMap { TransportMode(rawValue: $0) }
        let buffer = intValue(input["buffer_minutes"])
        let notify = intValue(input["notify_lead_minutes"])
        // 인자를 하나도 안 보내는 경우는 이 모델에선 사실상 없지만(선택 인자를 전부 채운다),
        // 사람이 도구를 직접 부르거나 모델이 바뀌면 다시 살아나는 길이라 남겨둔다.
        guard mode != nil || buffer != nil || notify != nil else {
            return "무엇을 바꿀지 알려주세요(이동수단, 도착 여유, 알림 시각 중)."
        }
        if let ask = zeroUpdateIssue(recurrenceId, buffer: buffer, notify: notify, input: input) {
            // 번호로 온 호출의 되묻기에는 번호를 그대로 다시 붙이라고 덧붙인다 — 모델이 되묻기
            // 답을 보낼 때 series_number를 빼면 "안 골랐다" 경로(lastRecurrenceId)로 흘러
            // 엉뚱한 그룹에 현행값을 덮어쓴다. 사용자에게 보이는 확인 문구 자체는 그대로 둔다.
            return resolvedByNumber ? ask + "\n· 다시 호출할 때 series_number:\(seriesNumber)도 그대로 둬라." : ask
        }
        let count = await store.updateRecurringSeries(recurrenceId, mode: mode, bufferMinutes: buffer, notifyLeadMinutes: notify)
        guard count > 0 else {
            return "그 반복 일정을 더 이상 찾을 수 없어요(이미 삭제됐을 수 있어요)."
        }
        // 확인은 실제로 반영됐을 때 소진된다(생성 쪽과 같은 자리·같은 이유) — 남겨두면 나중에
        // 같은 조합으로 온 0이 되묻지도 않고 통과한다.
        zeroUpdateConfirmAsk = nil
        var changes: [String] = []
        if let mode { changes.append("이동수단 \(mode.title)") }
        if let buffer { changes.append("도착 여유 \(buffer)분") }
        if let notify { changes.append("출발 \(notify)분 전 알림") }
        // 어느 그룹을 고쳤는지 이름으로 말한다. 번호를 빼먹은 재호출은 조용히 lastRecurrenceId로
        // 흘러 엉뚱한 그룹을 고칠 수 있는데, 예전 문구("반복 일정 35건을 수정했어요")에는 대상이
        // 없어서 그 오조준이 사후에도 보이지 않았다 — b303f41의 등록 요약과 같은 이유로, 모델이
        // 아니라 출력이 스스로 대조 근거를 들고 있게 한다.
        let subject = store.events.filter { $0.recurrenceId == recurrenceId }
            .min(by: { $0.arrivalDate < $1.arrivalDate })
            .map { "'\($0.title)' " } ?? ""
        return "\(subject)반복 일정 \(count)건을 수정했어요: \(changes.joined(separator: ", "))."
    }

    /// 반복 그룹 수정에서 여유·알림에 온 0을 곧이곧대로 적용하지 않고 되묻는다.
    ///
    /// 이 모델은 선언된 선택 인자를 비우지 못해 INTEGER에 0을 채운다. 그래서 "수단만 바꿔줘"가
    /// buffer_minutes:0·notify_lead_minutes:0을 달고 오고, 그대로 적용하면 통근 시리즈 35건의
    /// 여유·알림이 통째로 0이 된다. 반대로 `remember_fact`처럼 0을 조용히 버릴 수도 없다 —
    /// 여기서는 "여유 없이로 바꿔줘"가 실제로 가능한 요청이라 버리면 기능이 사라진다.
    ///
    /// 그래서 되묻되, **탈출구를 숫자로 준다**. 모델은 인자를 비울 수 없으니 "그대로 둬라"는
    /// 지시를 따를 방법이 없고, 값 목록을 보여주면 거기서 아무거나 골라 온다(`nth_week_of_month`에
    /// -1을 골라 35건을 7건으로 만든 적이 있다). 지금 시리즈에 들어 있는 값을 그대로 알려주면
    /// 모델이 고를 것 없이 되돌려 보낼 수 있다 — 단 그 값이 0인 경우는 예외라서 아래에서 갈라진다.
    ///
    /// 확인(`confirm_zero`)은 **앱이 그 조합을 실제로 되물은 뒤**에만 인정한다 — 모델이 첫 호출에
    /// 스스로 켜서 보낸 확인으로 가드가 통째로 무력해진 적이 있다(`recurrenceConfirmAsk`와 같은 이유).
    private func zeroUpdateIssue(_ recurrenceId: UUID, buffer: Int?, notify: Int?, input: [String: Any]) -> String? {
        let zeroBuffer = buffer == 0
        let zeroNotify = notify == 0
        guard zeroBuffer || zeroNotify else { return nil }

        let asked = ZeroUpdateAsk(recurrenceId: recurrenceId, buffer: buffer, notify: notify)
        if zeroUpdateConfirmAsk == asked && (input["confirm_zero"] as? Bool) == true { return nil }

        // 탈출구로 돌려줄 현재 값은 시리즈의 첫 회차에서 읽는다(updateRecurringSeries와 같은 정렬).
        // 시리즈가 이미 사라졌으면 되물을 근거가 없으니 통과시키고, 뒤의 count > 0 가드가 안내한다.
        guard let current = store.events.filter({ $0.recurrenceId == recurrenceId })
            .min(by: { $0.arrivalDate < $1.arrivalDate }) else { return nil }

        // 복원 경로가 있는 갈래에서는 그것을 먼저 적는다. 이 가드가 실제로 잡는 건 "수단만 바꿔줘"에 딸려온
        // 0이고 그때 옳은 행동은 복원 쪽인데, 파괴 경로가 앞에 있으면 모델이 먼저 읽은 쪽을 집는다
        // (`nth_week_of_month` 안내문의 값 목록에서 -1을 집어 35건을 7건으로 만든 것과 같은 자리다).
        //
        // 현재 값이 이미 0이면 복원 탈출구 자체를 주지 않는다 — "그대로 둬라"와 "0으로 바꿔라"가
        // 같은 와이어 값이라, 알려준 0이 그대로 돌아와 가드를 다시 발동시키고 안내만 반복하다
        // 툴 루프 상한에서 턴이 끝난다(이동수단 변경은 끝내 일어나지 않는다).
        var asks: [String] = []
        if zeroBuffer {
            asks.append(current.bufferMinutes == 0
                ? "· 도착 여유는 이미 0분이라 이 값은 바뀌는 게 없어요. buffer_minutes:0 그대로 confirm_zero:true를 붙여 다시 호출해."
                : "· 도착 여유를 0분으로 바꾸게 돼 있어요. 여유는 건드리는 게 아니었으면 buffer_minutes:\(current.bufferMinutes)으로 다시 호출하고, 정말 여유 없이가 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
        }
        if zeroNotify {
            asks.append(current.notifyLeadMinutes == 0
                ? "· 알림은 이미 출발 0분 전이라 이 값은 바뀌는 게 없어요. notify_lead_minutes:0 그대로 confirm_zero:true를 붙여 다시 호출해."
                : "· 알림을 출발 0분 전으로 바꾸게 돼 있어요. 알림은 건드리는 게 아니었으면 notify_lead_minutes:\(current.notifyLeadMinutes)로 다시 호출하고, 정말 그게 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
        }
        // 되물은 조합을 여기서만 기록한다 — 이 조합 그대로 다시 오는 호출의 confirm_zero만 진짜 확인이다.
        zeroUpdateConfirmAsk = asked
        return "아직 바꾸지 않았어요. 아래를 **먼저 사용자에게 확인**하고 답을 들은 뒤에 다시 호출해.\n" + asks.joined(separator: "\n")
    }

    /// 사용자에 대한 사실을 장기 기억에 저장한다(대화 초기화와 무관하게 유지, 다음 시스템 프롬프트부터 반영).
    private func executeRememberFact(_ input: [String: Any]) -> String {
        var saved: [String] = []

        // 값으로 저장할 수 있는 건 설정에 직접 넣는다 — 문장만 남기면 다음 요청 때 모델이
        // 그 문장을 다시 해석해야 하고, 실제로 놓쳐서 기본값(대중교통)으로 계산한 적이 있다.
        let fact = (input["fact"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        var config = store.config

        // 모델이 선택적 인자를 자주 빠뜨린다 — 인자가 없으면 저장하려는 문장에서 직접 읽어낸다.
        // ("주로 자동차로 다녀"라고 기억시켜도 preferredMode가 비어 있던 문제.)
        let mode = (input["mode"] as? String).flatMap { TransportMode(rawValue: $0) } ?? Self.mode(in: fact)
        if let mode { config.preferredMode = mode.rawValue; saved.append("이동수단 \(mode.title)") }
        // 여기서만 0을 버린다(weeksArgument와 같은 모양). 생성 도구의 0은 이번 한 건짜리
        // 진짜 요청이라 그대로 두지만, 여기서 저장된 0은 **영구적이고 전역**이라 이후 모든
        // 일정이 여유·알림 0으로 만들어진다 — 되돌리려면 사용자가 설정을 직접 고쳐야 한다.
        // 같은 실수여도 값이 사는 수명이 달라서 판단을 달리한다.
        // (문장에서 읽는 Self.minutes는 이미 v > 0만 돌려주므로 걸러낼 게 없다.)
        if let b = intValue(input["buffer_minutes"]).flatMap({ $0 > 0 ? $0 : nil })
            ?? Self.minutes(in: fact, near: ["여유"]) {
            config.preferredBuffer = b; saved.append("도착 여유 \(b)분")
        }
        if let n = intValue(input["notify_lead_minutes"]).flatMap({ $0 > 0 ? $0 : nil })
            ?? Self.minutes(in: fact, near: ["알림", "분 전"]) {
            config.preferredNotify = n; saved.append("알림 \(n)분 전")
        }
        if !saved.isEmpty { store.updateConfig(config) }

        if !fact.isEmpty {
            if !rememberedFacts.contains(fact) {
                rememberedFacts.append(fact)
                saveMemory()
            }
            saved.append(fact)
        }
        guard !saved.isEmpty else { return "기억할 내용이 비어 있어요." }
        return "기억했어요: \(saved.joined(separator: ", "))."
    }


    /// 기억할 문장에서 이동수단을 읽어낸다. 대중교통·도보를 먼저 보는 이유는
    /// "기차"처럼 '차'가 들어간 낱말이 자동차로 잘못 잡히지 않게 하기 위함.
    private static func mode(in text: String) -> TransportMode? {
        for w in ["대중교통", "지하철", "전철", "버스", "기차"] where text.contains(w) { return .transit }
        for w in ["도보", "걸어", "걷는"] where text.contains(w) { return .walk }
        for w in ["자동차", "자차", "차로", "차를", "차 타", "운전"] where text.contains(w) { return .car }
        return nil
    }

    /// "…여유 10분", "알림 30분 전"처럼 특정 낱말 근처의 분 단위 숫자를 읽어낸다.
    ///
    /// **낱말 뒤를 먼저** 본다("알림 30분"). 앞뒤를 한 덩어리로 보면 "도착 여유 10분, 알림 30분 전"에서
    /// 알림 값으로 앞의 10분을 집어버린다. 뒤에 없을 때만 앞을 보되 낱말에 가장 가까운 숫자를 쓴다
    /// ("출발 10분 전에 알림").
    private static func minutes(in text: String, near keywords: [String]) -> Int? {
        func firstMinutes(_ s: Substring, last: Bool) -> Int? {
            var found: Int?
            var cursor = s.startIndex
            while let m = s.range(of: "[0-9]+ *분", options: .regularExpression, range: cursor..<s.endIndex) {
                let v = Int(s[m].filter(\.isNumber))
                if let v, v > 0, v <= 180 {
                    found = v
                    if !last { return v }
                }
                cursor = m.upperBound
            }
            return found
        }
        for key in keywords {
            guard let r = text.range(of: key) else { continue }
            let tail = text.index(r.upperBound, offsetBy: 12, limitedBy: text.endIndex) ?? text.endIndex
            if let v = firstMinutes(text[r.upperBound..<tail], last: false) { return v }
            let head = text.index(r.lowerBound, offsetBy: -12, limitedBy: text.startIndex) ?? text.startIndex
            // 낱말 자체를 포함해 본다("10분 전"처럼 숫자가 낱말에 붙어 있는 경우).
            if let v = firstMinutes(text[head..<r.upperBound], last: true) { return v }
        }
        return nil
    }

    /// 실제 등록된 일정을 조회한다(모델이 지어낸 데이터로 답하는 걸 막기 위한 읽기 전용 도구).
    /// 반복 그룹은 대표 1건 + 회차 수로 요약해 응답이 너무 길어지지 않게 한다.
    private func executeListSchedules(_ input: [String: Any]) -> String {
        let titleQuery = (input["title_query"] as? String)?.trimmingCharacters(in: .whitespaces)
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d(E) a h:mm"

        // 날짜 범위: from은 그 날 00:00, to는 그 날 23:59:59까지 포함한다.
        let cal = Calendar.current
        let from = (input["from_date"] as? String).flatMap(parseDay)
        let to = (input["to_date"] as? String).flatMap(parseDay)
            .flatMap { cal.date(byAdding: DateComponents(day: 1, second: -1), to: $0) }
        func inRange(_ d: Date) -> Bool {
            if let from, d < from { return false }
            if let to, d > to { return false }
            return true
        }
        var rangeLabel = ""
        if from != nil || to != nil {
            let df = DateFormatter(); df.locale = Locale(identifier: "ko_KR"); df.dateFormat = "M/d"
            rangeLabel = " (\(from.map { df.string(from: $0) } ?? "처음")~\(to.map { df.string(from: $0) } ?? "끝"))"
        }

        var events = store.events.filter { inRange($0.arrivalDate) }
        var activities = store.activities.filter { inRange($0.startDate) }
        if let q = titleQuery, !q.isEmpty {
            events = events.filter { $0.title.localizedCaseInsensitiveContains(q) }
            activities = activities.filter { $0.title.localizedCaseInsensitiveContains(q) }
        }
        guard !events.isEmpty || !activities.isEmpty else {
            let what = (titleQuery?.isEmpty == false) ? "'\(titleQuery!)'와 일치하는 일정" : "등록된 일정"
            // 조건에 걸린 게 없을 때 그냥 "없어요"로 끝내면, 조건(특히 모델이 계산한 날짜 범위)이
            // 틀렸을 뿐인데도 모델이 "일정이 하나도 없다"고 잘라 말해버린다. 실제로 "이번 주"를
            // 엉뚱한 주로 계산해 등록된 일정을 못 찾은 적이 있다 — 전체 현황을 같이 돌려줘
            // 스스로 바로잡을 수 있게 한다.
            let total = store.events.count + store.activities.count
            guard total > 0 else { return "등록된 일정이 하나도 없어요." }
            let nearest = (store.events.map { ($0.title, $0.arrivalDate) }
                           + store.activities.map { ($0.title, $0.startDate) })
                .min { abs($0.1.timeIntervalSinceNow) < abs($1.1.timeIntervalSinceNow) }
            let hint = nearest.map { " 가장 가까운 건 '\($0.0)' \(f.string(from: $0.1))이에요." } ?? ""
            return "\(what)은 없어요\(rangeLabel). 다만 전체로는 \(total)건 등록돼 있어요.\(hint)"
                + " 조건(날짜 범위·제목)이 잘못됐을 수 있으니, 필요하면 조건을 비우거나 고쳐서 다시 조회해."
        }

        // (종류, recurrenceId, 제목)별 회차 수를 한 번에 세어둔다 — 아래 루프 안에서 매번
        // store.events 전체를 filter하면 일정이 수백 건일 때 O(n²)이 된다.
        var groupCounts: [String: Int] = [:]
        for e in store.events {
            guard let rid = e.recurrenceId else { continue }
            groupCounts["event|\(rid.uuidString)|\(e.title)", default: 0] += 1
        }
        for a in store.activities {
            guard let rid = a.recurrenceId else { continue }
            groupCounts["activity|\(rid.uuidString)|\(a.title)", default: 0] += 1
        }

        var lines: [String] = []
        // recurrenceId만으로 묶으면 같은 반복 그룹 안의 등원/복귀/점심 이동처럼 제목이 서로 다른
        // 구간들이 한 줄로 뭉개져 특정 구간을 콕 집어 말할 수 없게 된다 — (recurrenceId, 제목) 조합
        // 으로 묶어야 각 구간이 따로 보인다. 이동 구간과 활동은 종류(kind)도 키에 넣는다 — 등원
        // 이동과 메인 활동은 같은 recurrenceId·같은 제목을 공유해서 종류를 안 넣으면 하나가
        // 다른 하나를 가려 활동 블록이 통째로 안 보이는 문제가 있었다.
        // "몇 시에 나가야 하나"가 이 앱의 핵심이라 출발 시각을 반드시 같이 보여준다
        // (예전엔 도착 시각만 있어서 모델이 출발 시각을 지어내거나 답하지 못했다).
        func leg(_ e: ScheduledEvent) -> String {
            guard let dep = e.departureDate else { return "\(f.string(from: e.arrivalDate)) 도착" }
            return "\(f.string(from: dep)) 출발 → \(f.string(from: e.arrivalDate)) 도착"
        }
        // 반복 그룹 번호: 같은 그룹의 등원/복귀/점심 줄이 **모두 같은 번호**를 달게 한다. 줄마다
        // 다른 번호를 주면 "복귀만 고른다"는 착각을 만드는데, update_recurring_schedule과
        // updateRecurringSeries는 recurrenceId 단위로만 움직여 구간만 고르는 길이 없다 — 번호가
        // 그룹 전체를 가리킨다는 걸 줄 표기와 맨 아래 안내 문장 양쪽에서 말해준다.
        func seriesTag(_ rid: UUID) -> String {
            if let n = seriesNumbers[rid] { return "\(n)" }
            let n = nextSeriesNumber
            nextSeriesNumber += 1
            seriesNumbers[rid] = n
            return "\(n)"
        }
        // 번호는 **수정할 수 있는 그룹에만** 붙인다. updateRecurringSeries는 events만 보고
        // 움직이는데(Store.swift:662), deleteEvent는 짝 활동 블록을 지우지 않아 이동 구간만
        // 사라진 그룹이 실제로 생긴다 — 거기에 번호를 붙이면 목록은 "고칠 수 있다"고 보여주고
        // 실행부는 "없다"고 답해, 모델이 방금 본 목록과 모순된 답을 받고 재조회를 반복한다.
        let updatableRids = Set(store.events.compactMap { $0.recurrenceId })
        var showedRecurring = false
        var seenGroups: Set<String> = []
        for e in events.sorted(by: { $0.arrivalDate < $1.arrivalDate }) {
            let failedTag = e.departureDate == nil ? " ⚠️이동시간 계산 실패" : ""
            if let rid = e.recurrenceId {
                let key = "event|\(rid.uuidString)|\(e.title)"
                guard !seenGroups.contains(key) else { continue }
                seenGroups.insert(key)
                let count = groupCounts[key] ?? 1
                showedRecurring = true
                lines.append("- [반복 \(seriesTag(rid))] '\(e.title)' 등 \(count)건, 다음 회차 \(leg(e))\(failedTag)")
            } else {
                lines.append("- '\(e.title)' \(leg(e))\(failedTag)")
            }
        }
        for a in activities.sorted(by: { $0.startDate < $1.startDate }) {
            if let rid = a.recurrenceId {
                let key = "activity|\(rid.uuidString)|\(a.title)"
                guard !seenGroups.contains(key) else { continue }
                seenGroups.insert(key)
                let count = groupCounts[key] ?? 1
                guard updatableRids.contains(rid) else {
                    lines.append("- (활동/반복) '\(a.title)' 등 \(count)건, 다음 회차 \(f.string(from: a.startDate)) ~ \(f.string(from: a.endDate)) — 이동 일정이 모두 지워져 시간표 블록만 남았어요(수단·여유·알림을 고칠 게 없어요)")
                    continue
                }
                showedRecurring = true
                lines.append("- (활동/반복 \(seriesTag(rid))) '\(a.title)' 등 \(count)건, 다음 회차 \(f.string(from: a.startDate)) ~ \(f.string(from: a.endDate))")
            } else {
                lines.append("- (활동) '\(a.title)' \(f.string(from: a.startDate)) ~ \(f.string(from: a.endDate))")
            }
        }
        let capped = Array(lines.prefix(20))
        let more = lines.count > capped.count ? "\n(그 외 \(lines.count - capped.count)건 더 있음 — 제목으로 좁혀서 다시 조회해)" : ""
        // 안내문은 **캡을 통과한 줄** 기준이다. 단발 일정이 앞을 채워 반복 줄이 전부 잘리면
        // 모델에게는 인용할 [n]이 하나도 없는데 "목록의 [n]을 series_number에"라고 말하게 된다.
        showedRecurring = capped.contains { $0.contains("[반복 ") || $0.contains("(활동/반복 ") }
        // 이 안내가 다리다 — 모델은 목록은 볼 수 있었지만 "어느 그룹"을 말할 인자가 없어서
        // update_recurring_schedule이 늘 lastRecurrenceId에만 걸렸다(옛 대화에서 만든 그룹 수정 불가).
        // 반복 줄이 보였을 때만 붙인다: 번호 없는 목록에 이 문장은 소음이다.
        let numberNote = showedRecurring ? "\n[n]은 반복 그룹 번호 — 등원·복귀·점심을 묶은 그룹 전체를 가리킨다(일부 구간만 고칠 수는 없다). 그 그룹의 수단·여유·알림 수정은 update_recurring_schedule의 series_number에 그 번호." : ""
        return "실제 등록된 일정\(rangeLabel):\n" + capped.joined(separator: "\n") + more + numberNote
    }



    /// 실제 장소 검색으로 식사 추천을 만든다(be full sir).
    ///
    /// 기준 위치는 ① place_query ② at_iso 시각에 있을 장소(그 시간대 활동·일정의 장소)
    /// ③ 현재 위치 순으로 정한다 — "1시 점심시간에 일식"처럼 시각만 말해도 그때 있을 곳 주변에서 찾는다.
    private func executeRecommendMeal(_ input: [String: Any]) async -> String {
        let keyword = (input["keyword"] as? String)?.trimmingCharacters(in: .whitespaces)
        let category: MealCategoryFilter = (input["category"] as? String) == "cafe" ? .cafe : .restaurant
        // 0은 "범위를 안 정했다"로 읽는다 — 이 모델은 선택 인자를 비우지 못해 INTEGER에 0을 채운다.
        // 그대로 두면 PlaceSearch가 하한 100m로 올려 반경 100m 검색이 되고, 결과가 거의 안 나온다.
        let radius = intValue(input["radius_meters"]).flatMap { $0 > 0 ? $0 : nil } ?? 1000

        var basis: Place?
        var basisNote = ""
        if let q = (input["place_query"] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            basis = await resolveDestination(q)
            basisNote = basis.map { "'\($0.name)' 주변" } ?? ""
        }
        if basis == nil, let at = (input["at_iso"] as? String).flatMap(parseDate) {
            if let (place, label) = placeAt(at) {
                basis = place
                basisNote = "\(label) 기준 '\(place.name)' 주변"
            }
        }
        if basis == nil {
            guard let here = location.currentLocation else {
                return "어디 주변에서 찾을지 알려주세요(장소를 말해주시거나 위치 권한을 켜주세요)."
            }
            basis = Place(name: location.currentPlaceName ?? "현재 위치", address: "",
                          latitude: here.latitude, longitude: here.longitude)
            basisNote = "현재 위치 주변"
        }
        guard let center = basis else { return "기준 위치를 정하지 못했어요." }

        let found = await store.placeSearch.nearbyPlaces(
            category: category,
            keyword: keyword,
            near: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            radiusMeters: radius,
            limit: 5)
        let what = (keyword?.isEmpty == false) ? "'\(keyword!)'" : category.title
        guard !found.isEmpty else {
            return "\(basisNote)에서 \(what)을(를) 찾지 못했어요. 반경을 넓히거나 다른 메뉴로 다시 찾아볼까요?"
        }
        let lines = found.map { item -> String in
            let bits = [item.category, item.distanceText].compactMap { $0 }.filter { !$0.isEmpty }
            return "- \(item.place.name)" + (bits.isEmpty ? "" : " (\(bits.joined(separator: ", ")))")
        }
        return "\(basisNote) \(what) 추천(실제 검색 결과):\n" + lines.joined(separator: "\n")
            + "\n이 목록에 있는 곳만 말하고, 마음에 드는 걸 고르면 일정으로 만들어 줄 수 있다고 안내해."
    }

    /// 그 시각에 사용자가 있을 것으로 보이는 장소를 찾는다(활동 블록 우선, 없으면 그때 도착해 있는 일정의 목적지).
    private func placeAt(_ date: Date) -> (Place, String)? {
        if let a = store.activities.first(where: { $0.startDate <= date && date <= $0.endDate }),
           let p = a.location {
            return (p, "'\(a.title)'")
        }
        // 그 시각 이전에 도착한 가장 최근 일정의 목적지에 머무르고 있다고 본다.
        if let e = store.events.filter({ $0.arrivalDate <= date })
            .max(by: { $0.arrivalDate < $1.arrivalDate }) {
            return (e.destination, "'\(e.title)' 도착지")
        }
        return nil
    }

    /// 일정을 만들지 않고 이동시간만 계산한다(A8).
    ///
    /// 수단을 고르지 않고 **세 가지를 다 돌려준다**. 예전엔 `mode` 인자를 뒀는데, 작은 모델이
    /// 저장된 기본값이 있어도 습관처럼 "transit"을 채워 넣어 기억해둔 이동수단이 무시됐다
    /// — 고를 것이 없으면 틀릴 것도 없다. 조회는 어차피 세 수단을 다 보여주는 게 더 쓸모 있다.
    private func executeCheckTravelTime(_ input: [String: Any]) async -> String {
        guard let destQuery = (input["destination_query"] as? String)?.trimmingCharacters(in: .whitespaces),
              !destQuery.isEmpty else { return "어디까지 가는지 알려주세요." }
        guard let origin = await resolveOrigin(input["origin_query"] as? String) else {
            return "출발지를 확인하지 못했어요. 어디서 출발하는지 알려주세요."
        }
        guard let dest = await resolveDestination(destQuery) else { return placeNotFound(destQuery) }
        let estimates = await store.travelEstimates(from: origin, to: dest)
        let depart = (input["depart_iso"] as? String).flatMap(parseDate) ?? Date()
        let preferred = store.config.preferredMode.flatMap { TransportMode(rawValue: $0) }

        let lines = TransportMode.allCases.compactMap { m -> String? in
            guard let seconds = estimates[m]?.duration else { return nil }
            let minutes = Int((seconds / 60).rounded())
            let duration = minutes < 60 ? "\(minutes)분" : "\(minutes / 60)시간 \(minutes % 60)분"
            let arrive = Self.when(depart.addingTimeInterval(seconds))
            let star = (m == preferred) ? " ← 평소 쓰는 수단" : ""
            return "- \(m.title) \(duration) (도착 \(arrive))\(star)"
        }
        guard !lines.isEmpty else {
            return "'\(origin.name)' → '\(dest.name)' 이동시간을 계산하지 못했어요(경로를 못 찾았거나 조회 실패)."
        }
        return "'\(origin.name)' → '\(dest.name)', \(Self.when(depart)) 출발 기준:\n"
            + lines.joined(separator: "\n")
            + "\n(등록하지는 않았어요) 평소 쓰는 수단이 표시돼 있으면 그걸 먼저 말해줘."
    }

    /// 장기 기억에서 항목을 지운다(G3).
    private func executeForgetFact(_ input: [String: Any]) -> String {
        if (input["all"] as? Bool) == true {
            let count = rememberedFacts.count
            guard count > 0 else { return "기억하고 있는 게 없어요." }
            forgetAllFacts()
            return "기억하고 있던 \(count)건을 모두 지웠어요."
        }
        guard let q = (input["fact_query"] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty else {
            return "무엇을 잊을지 알려주세요(또는 전부 지우려면 all:true)."
        }
        let matches = rememberedFacts.filter { $0.localizedCaseInsensitiveContains(q) }
        guard !matches.isEmpty else {
            return "'\(q)'와 관련해 기억하고 있는 게 없어요. 현재 기억: \(rememberedFacts.isEmpty ? "없음" : rememberedFacts.joined(separator: " / "))"
        }
        for m in matches { forgetFact(m) }
        return "잊었어요: \(matches.joined(separator: ", "))."
    }

    /// 이미 등록된 일정 하나(이동 구간 또는 활동)를 찾아 제목·시각·장소·이동수단을 고친다.
    /// 대상이 여러 건이면 고치지 않고 날짜를 요구한다 — 엉뚱한 회차를 바꾸는 게 더 나쁘다.
    private func executeUpdateSchedule(_ input: [String: Any]) async -> String {
        guard let titleQuery = (input["title_query"] as? String)?.trimmingCharacters(in: .whitespaces),
              !titleQuery.isEmpty else {
            return "어떤 일정을 고칠지 제목을 알려주세요."
        }
        let dateFilter = (input["date"] as? String).flatMap(parseDay)
        let cal = Calendar.current
        let events = store.events.filter {
            $0.title.localizedCaseInsensitiveContains(titleQuery)
                && (dateFilter == nil || cal.isDate($0.arrivalDate, inSameDayAs: dateFilter!))
        }
        let activities = store.activities.filter {
            $0.title.localizedCaseInsensitiveContains(titleQuery)
                && (dateFilter == nil || cal.isDate($0.startDate, inSameDayAs: dateFilter!))
        }
        let total = events.count + activities.count
        guard total > 0 else { return "'\(titleQuery)'와 일치하는 일정을 찾지 못했어요." }
        guard total == 1 else {
            let sample = (events.map { "'\($0.title)' \(Self.when($0.arrivalDate))" }
                          + activities.map { "(활동) '\($0.title)' \(Self.when($0.startDate))" }).prefix(5)
            return """
            '\(titleQuery)'에 \(total)건이 걸려서 아직 고치지 않았어요: \(sample.joined(separator: ", "))\(total > 5 ? " 외" : "").
            어느 날짜 것을 고칠지 사용자에게 물어보고, **같은 인자에 date(yyyy-MM-dd)만 추가해서** 다시 호출하세요.
            """
        }

        var newPlace: Place?
        if let q = (input["new_place_query"] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            newPlace = await resolveDestination(q)
            if newPlace == nil { return placeNotFound(q) }
        }
        let newTitle = (input["new_title"] as? String)?.trimmingCharacters(in: .whitespaces)

        if let activity = activities.first {
            let newStart = (input["new_start_iso"] as? String).flatMap(parseDate)
            let newEnd = (input["new_end_iso"] as? String).flatMap(parseDate)
            guard newTitle?.isEmpty == false || newStart != nil || newEnd != nil || newPlace != nil else {
                return "무엇을 바꿀지 알려주세요(제목, 시작·종료 시각, 장소 중)."
            }
            let ok = store.modifyActivity(id: activity.id, newTitle: newTitle,
                                          newStart: newStart, newEnd: newEnd, newPlace: newPlace)
            guard ok else { return "바뀐 내용이 없어요." }
            guard let after = store.activities.first(where: { $0.id == activity.id }) else { return "수정했어요." }
            return "활동 '\(after.title)'을(를) 수정했어요 — \(Self.when(after.startDate)) ~ \(Self.when(after.endDate))."
                + (store.events.contains { $0.linkedActivityId == after.id } ? " 묶인 이동 구간도 같이 옮겼어요." : "")
        }

        guard let event = events.first else { return "수정 대상을 찾지 못했어요." }
        let newArrival = (input["new_arrival_iso"] as? String).flatMap(parseDate)
        let newDeparture = (input["new_departure_iso"] as? String).flatMap(parseDate)
        let newMode = (input["new_mode"] as? String).flatMap { TransportMode(rawValue: $0) }
        guard newTitle?.isEmpty == false || newArrival != nil || newDeparture != nil
                || newPlace != nil || newMode != nil else {
            return "무엇을 바꿀지 알려주세요(제목, 도착·출발 시각, 목적지, 이동수단 중)."
        }
        // 사용자가 말한 쪽이 새 기준이 된다(도착을 말했으면 도착 기준, 출발을 말했으면 출발 기준).
        let newAnchor: ScheduleAnchor? = newArrival != nil ? .arrival : (newDeparture != nil ? .departure : nil)
        await store.modifyEvent(id: event.id,
                                newTitle: newTitle,
                                newAnchorDate: newArrival ?? newDeparture,
                                newAnchor: newAnchor,
                                newDestination: newPlace,
                                newMode: newMode)
        guard let after = store.events.first(where: { $0.id == event.id }) else { return "수정했어요." }
        var summary = "'\(after.title)' 일정을 수정했어요 — 목적지 '\(after.destination.name)', 이동수단 \(after.mode.title)."
        if let dep = after.departureDate {
            summary += " \(Self.when(dep)) 출발 → \(Self.when(after.arrivalDate)) 도착."
            let clash = store.conflicts(departure: dep, arrival: after.arrivalDate,
                                        recurrenceId: after.recurrenceId, excludingEventId: after.id)
            if !clash.isEmpty {
                summary += " 다만 \(clash.map { "'\($0.title)'" }.joined(separator: ", "))와 시간이 겹쳐요 — 사용자에게 알려줘."
            }
        } else {
            summary += " (이동시간을 계산하지 못해 출발 시각은 비어 있어요.)"
        }
        return summary
    }

    /// 제목(+선택적 날짜)으로 기존 일정을 찾아 삭제한다. whole_series를 안 주면 date 유무로
    /// 기본값을 정해 한 번 호출로 항상 실제 삭제까지 끝난다(도구가 확인 질문을 돌려주는 방식은
    /// 작은 모델이 그 답을 정확히 이어붙이지 못해 같은 질문을 반복하는 문제가 있었다).
    private func executeDeleteSchedule(_ input: [String: Any]) -> String {
        let titleQuery = (input["title_query"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        let dateFilter = (input["date"] as? String).flatMap(parseDay)
        // 제목과 날짜 둘 다 없으면 "전부 삭제"가 돼버려 위험하다 — 최소 하나는 있어야 한다.
        guard !titleQuery.isEmpty || dateFilter != nil else {
            return "지울 일정의 제목이나 날짜 중 하나는 알려주세요."
        }
        let cal = Calendar.current
        func titleMatches(_ t: String) -> Bool {
            titleQuery.isEmpty || t.localizedCaseInsensitiveContains(titleQuery)
        }

        let matchingEvents = store.events.filter {
            titleMatches($0.title)
                && (dateFilter == nil || cal.isDate($0.arrivalDate, inSameDayAs: dateFilter!))
        }
        let matchingActivities = store.activities.filter {
            titleMatches($0.title)
                && (dateFilter == nil || cal.isDate($0.startDate, inSameDayAs: dateFilter!))
        }
        let target = titleQuery.isEmpty
            ? "그 날짜" : "'\(titleQuery)'"
        guard !matchingEvents.isEmpty || !matchingActivities.isEmpty else {
            return "\(target)에 해당하는 일정을 찾지 못했어요."
        }

        let isRecurring = matchingEvents.contains { $0.recurrenceId != nil } || matchingActivities.contains { $0.recurrenceId != nil }
        let totalCount = matchingEvents.count + matchingActivities.count

        // 반복이 아닌데(recurrenceId 없이 옛날에 낱개로 여러 번 만들어진 경우 등) 제목이 너무 많이
        // 걸리면 안전하게 확인을 한 번 더 요청한다 — 사용자가 "전부 지워줘"라고 이미 명확히
        // 확인했으면(confirm_many) 그냥 다 지운다.
        if !isRecurring && totalCount > 5 && (input["confirm_many"] as? Bool) != true {
            return "\(target)에 해당하는 일정이 \(totalCount)개예요(반복 일정이 아니라 낱개로 등록된 것들이에요). 전부 지우려면 확인해주세요(예: \"응 전부 지워줘\"), 아니면 날짜를 알려주시면 그것만 지울게요."
        }
        // 반복인데 날짜 없이 "이 회차만"(whole_series:false)이라고 명시하면 위험하니 날짜를 요구한다.
        if isRecurring && dateFilter == nil && (input["whole_series"] as? Bool) == false {
            return "이 회차만 지우려면 날짜를 알려주세요."
        }

        // 실제로 제목이 일치한 것들만 지운다(deleteRecurringSeries로 recurrenceId 전체를 지우면,
        // 같은 반복 그룹 안에 있는 "등원/복귀/점심 이동"처럼 제목이 다른 다른 구간까지 같이
        // 사라진다 — 예: "점심 후 복귀"만 지워달랬는데 등원 구간까지 지워지는 사고를 막기 위함).
        let names = Array(Set(matchingEvents.map { $0.title } + matchingActivities.map { $0.title })).sorted()
        // 낱개로 지우면 건수만큼 저장·재계산이 반복된다(수십 건이면 눈에 띄게 멈춤) — 한 번에 지운다.
        store.deleteEvents(matchingEvents)
        store.deleteActivities(matchingActivities)
        let scope = isRecurring ? (dateFilter == nil ? "반복 일정 " : "해당 날짜의 반복 일정 ") : ""
        return "\(scope)\(target) 관련 \(totalCount)건을 삭제했어요: \(names.joined(separator: ", "))."
    }



    /// 두 장소가 사실상 같은 곳인지(50m 이내). 이름이 달라도 같은 지점이면 같다고 본다.
    private static func isSamePlace(_ a: Place, _ b: Place) -> Bool {
        let dLat = (a.latitude - b.latitude) * 111_000
        let dLng = (a.longitude - b.longitude) * 111_000 * cos(a.latitude * .pi / 180)
        return (dLat * dLat + dLng * dLng) < 50 * 50
    }

    /// 장소를 못 찾았을 때 모델에게 돌려줄 안내.
    ///
    /// "더 정확한 장소명을 알려주세요"만 돌려주면 모델이 주소를 캐묻는데, "집"·"회사"처럼
    /// 즐겨찾기에 있어야 할 이름이면 **주소를 받는 게 아니라 즐겨찾기에 등록하는 게** 맞다.
    /// 등록된 즐겨찾기 이름을 같이 알려줘 모델이 올바른 안내를 하게 한다.
    private func placeNotFound(_ query: String) -> String {
        let labels = store.favorites.map { $0.label }
        let common = ["집", "회사", "학교", "사무실", "우리집"]
        if common.contains(query) {
            let have = labels.isEmpty ? "아직 없어요" : labels.joined(separator: ", ")
            return "'\(query)'이(가) 즐겨찾기에 없어요(등록된 즐겨찾기: \(have)). "
                + "besir 별 모양 버튼에서 '\(query)'을(를) 즐겨찾기에 추가하면 다음부터 이름만으로 쓸 수 있다고 안내해. "
                + "지금 바로 등록하려면 실제 장소명이나 주소를 받아서 그걸 넣어."
        }
        let hint = labels.isEmpty ? "" : " (즐겨찾기: \(labels.joined(separator: ", ")))"
        return "'\(query)' 위치를 찾지 못했어요. 더 정확한 장소명을 알려주세요.\(hint)"
    }

    /// 출발지 해석 우선순위: ① query가 즐겨찾기 이름과 일치 ② query로 검색 ③ 즐겨찾기 "집" ④ 현재 위치(최후 폴백).
    /// 반복 일정(출퇴근 등)은 등록 시점의 "현재 위치"가 출발지로 굳어버리면 안 맞을 수 있어(예: 등록할 때
    /// 마침 회사에 있었다면 회사→회사가 됨) 시스템 프롬프트가 출발지를 반드시 확인하도록 지시한다 — 이 폴백은
    /// 그래도 origin_query가 끝내 없을 때의 안전망일 뿐이다.
    private func resolveOrigin(_ query: String? = nil) async -> Place? {
        let trimmed = query?.trimmingCharacters(in: .whitespaces)
        if let q = trimmed, !q.isEmpty {
            if let fav = store.favorites.first(where: { $0.label.caseInsensitiveCompare(q) == .orderedSame }) {
                return fav.place
            }
            if let found = await store.placeSearch.search(q, near: location.currentLocation).first {
                return found
            }
        }
        if let home = store.favorites.first(where: { $0.label == "집" }) {
            return home.place
        }
        if location.currentLocation == nil {
            location.useCurrentLocation()
            for _ in 0..<15 {
                if location.currentLocation != nil { break }
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
        guard let c = location.currentLocation else { return nil }
        return Place(name: location.currentPlaceName ?? "현재 위치",
                     address: "", latitude: c.latitude, longitude: c.longitude)
    }

    /// 목적지 해석: 즐겨찾기 이름과 일치하면 그 좌표를 우선 사용, 아니면 검색(카카오 → MapKit 폴백).
    private func resolveDestination(_ query: String) async -> Place? {
        if let fav = store.favorites.first(where: { $0.label.caseInsensitiveCompare(query) == .orderedSame }) {
            return fav.place
        }
        let results = await store.placeSearch.search(query, near: location.currentLocation)
        return results.first
    }

    // MARK: - 유틸

    private static let weekdaySymbolMap: [String: Int] = [
        "sun": 1, "mon": 2, "tue": 3, "wed": 4, "thu": 5, "fri": 6, "sat": 7
    ]
    private static func weekdaySymbol(_ s: String) -> Int? { weekdaySymbolMap[s.lowercased()] }

    /// "09:00" -> (9, 0)
    private func parseTime(_ s: String) -> (Int, Int)? {
        let parts = s.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), (0...23).contains(h), (0...59).contains(m) else { return nil }
        return (h, m)
    }

    /// "2026-07-06" -> Date(그 날 00:00, 로컬)
    private func parseDay(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }

    private func intValue(_ any: Any?) -> Int? {
        if let i = any as? Int { return i }
        if let d = any as? Double { return Int(d) }
        if let s = any as? String { return Int(s) }
        return nil
    }

    /// "2026-07-06T15:00:00" 같은 로컬 ISO 문자열을 Date 로 파싱한다.
    private func parseDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm"] {
            f.dateFormat = fmt
            if let d = f.date(from: s) { return d }
        }
        // 타임존이 포함된 ISO8601 형태 폴백.
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }
        return nil
    }
}
