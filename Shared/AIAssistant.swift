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
        /// 비어 있는 인자를 묻는 카드. nil이면 보통 말풍선이다.
        var ask: PendingAsk?
    }

    // 필드 모델(EditField·EditCard)과 시각 해석(BesirTime)은 Shared/EditCard.swift로 옮겼다.
    // 이 별칭 둘은 본문과 가드 드라이버의 기존 참조를 한 줄도 고치지 않기 위한 다리다 —
    // 이름 통일은 화면 카드 통합과 함께 별도 작업에서 한다.
    typealias AskField = EditField
    typealias PendingAsk = EditCard

    @Published var bubbles: [Bubble] = []
    @Published var isThinking = false
    @Published var input = ""
    /// 채팅 시트 표시 여부. 공유받은 항목이 도착하면 자동으로 true가 된다.
    @Published var isPresented = false

    private let store: Store
    private let location: LocationManager

    /// 대화 히스토리(툴 라운드트립 포함). role: user/model/function. (Gemini generateContent 형식)
    private var contents: [[String: Any]] = []
    /// 카드에서 **후보를 탭해 확정한 장소**(이름 → 좌표). 인자에는 이름만 실어 보내고 좌표는 여기서
    /// 되찾는다 — 내부 토큰을 인자에 실으면 모델·요약 문구로 그대로 새어 나간 전례가 두 번 있고
    /// (현재 위치·가는 편 없음), 이름만 실으면 실행부가 같은 이름을 **다시 검색**해 다른 지점이
    /// 잡힌다('회사' → 농업회사법인 화조원). 대화가 끝날 때까지 산다(resetConversation이 지운다).
    private var confirmedPlaces: [String: Place] = [:]
    /// 장소 줄별 검색 작업·마지막 질의(묶음 처리용). 줄 id는 카드마다 새로 만들어져 겹치지 않는다.
    private var placeSearchTasks: [UUID: Task<Void, Never>] = [:]
    private var lastPlaceQuery: [UUID: String] = [:]
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

    /// create_schedule이 겹침 안내를 실제로 내보낸 조합. `RecurrenceAsk`·`ZeroUpdateAsk`와 같은
    /// 이유로 조합 자체를 들고 있다 — 이 모델은 선언된 선택 인자를 비워두지 못해 **첫 호출에도**
    /// on_conflict를 실어 보낸다(2026-09-16 실기기 전사에서 세 건 전부 "ignore"였다). 그 값이
    /// 그대로 통과하면 겹침 검사 자체가 건너뛰어지고 conflictPrompt는 영영 발화하지 못한다.
    /// 앱이 그 조합을 되물었을 때만 답으로 인정한다. 재호출은 "방금과 똑같은 인자"로 오므로
    /// 목적지·기준 시각만으로 알아본다. 히스토리에 저장하지 않는다(형제들과 같은 이유).
    private struct ConflictAsk: Equatable {
        let destinationQuery: String
        let anchor: Date
    }
    private var conflictConfirmAsk: ConflictAsk?

    /// 사용자 발화에서 앱이 직접 읽어낸 인자("자동차로 가자" → mode_this_time). 저장하지 않는다.
    /// 한 요청 안에서는 되묻는 사이에도 유지되다가(발화마다 병합), 툴이 실제로 실행된 순간 지워진다 —
    /// 그다음 요청에서 말하지 않으면 다시 묻는다. 등록(툴 실행)이 값을 끝내는 유일한 지점이다.
    private var statedArgs: [String: Any] = [:]

    init(store: Store, location: LocationManager) {
        self.store = store
        self.location = location
        loadHistory()
        if bubbles.isEmpty {
            bubbles.append(.init(role: .assistant,
                text: "안녕하세요! 등록할 일정을 말로 알려주세요.\n예: \"내일 오후 3시에 강남역에서 친구 만나기\"\n다른 앱에서 일정표를 공유해주셔도 돼요."))
        }
        // 출발지 계산을 위해 현재 위치를 미리 확보해 둔다.
        if location.currentLocation == nil { location.useCurrentLocation() }
    }

    // MARK: - 대화 기록 저장/복원(재설치·재실행해도 유지)

    private var historyURL: URL {
        AppConfig.supportDirectory.appendingPathComponent("ai_history.json")
    }

    private func saveHistory() {
        // 아직 답하지 않은 카드는 빼고 저장한다 — 보류 상태는 어떤 형태로도 디스크에 남기지
        // 않는다. 앱을 껐다 켜면 카드가 사라지고, 그 요청은 다시 말해야 한다(매번 물음).
        let bubblesJSON: [[String: Any]] = bubbles.compactMap {
            $0.ask == nil ? ["role": $0.role == .user ? "user" : "assistant", "text": $0.text] : nil
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
        conflictConfirmAsk = nil
        // 말해 둔 값도 같이 지운다 — 병합으로 유지되는 값이 새 대화의 첫 요청까지 이어지면,
        // 옛 대화에서 말한 "자동차로"가 사용자가 모르는 사이 새 일정에 적용된다.
        statedArgs = [:]
        // 확정 장소도 같이 지운다 — 옛 대화에서 고른 '스타벅스'가 새 대화의 같은 이름에 조용히
        // 붙으면, 사용자는 이번에 고른 적 없는 지점으로 일정이 잡힌 걸 알 수 없다(statedArgs와 같은 이유).
        confirmedPlaces = [:]
        cancelPlaceSearches()
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
        // 앱이 카드로 물어 채운 값은 위 [도구 호출] 줄의 인자에 그대로 보인다 — 저장된 기본값이
        // 없어졌으므로 따로 덧붙일 상태가 없다.
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
        // 답을 못 받은 카드는 이번 발화로 무효가 된다 — 사용자가 다른 얘기로 넘어갔다는 뜻이다.
        cancelPendingAsk()
        bubbles.append(.init(role: .user, text: bubbleText))
        // 사용자가 직접 말한 값은 모델을 거치지 않고 앱이 읽는다(결정적). **병합**한다 — 통째로
        // 덮어쓰면 모델이 시각을 되묻는 바람에 사용자가 "2시, 4시"처럼 시각만 다시 답한 발화 하나로
        // 이미 말한 여유가 증발하고, 카드가 같은 걸 다시 물었다(2026-09-16 실기기 결함). 새 발화에서
        // 말한 키만 갱신하고 안 말한 키는 유지하며, 유지는 툴이 실행된 순간 끝난다(executeTool).
        for (k, v) in Self.statedArguments(from: text) { statedArgs[k] = v }
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
            // statedArgs는 유지한다 — 이 요청은 실패했을 뿐 등록이 끝난 게 아니므로, 사용자가 다시
            // 시도할 때 말해 둔 값이 여전히 적용돼야 한다. 툴이 이미 실행됐다면 그 실행 지점에서
            // 지워졌고, 그렇지 않다면 요청이 아직 끝나지 않은 것이다.
            contents = historyBeforeTurn
            bubbles.append(.init(role: .assistant, text: Self.userMessage(for: error)))
        }
    }

    /// 실패 원인을 사용자가 이해하고 다음 행동을 정할 수 있는 문구로 바꾼다.
    private static func userMessage(for error: Error) -> String {
        if (error as? AIError)?.kind == .quotaExceeded {
            // 백엔드 이름과 초기화 시각을 적지 않는다 — 860e121로 백엔드가 바뀐 뒤에도 옛
            // Workers AI 문구가 살아 있어, 없는 서비스를 말하고 틀린 초기화 시각을 안내했다.
            // 한도가 언제 풀리는지 앱은 알 수 없으니 아는 것(다른 등록 수단)만 말한다.
            return """
            AI 사용량 한도를 다 썼어요. 나중에 다시 시도해 주세요.
            그 전에 등록해야 할 일정이 있다면 오른쪽 위 + 버튼으로 직접 추가하실 수 있어요.
            """
        }
        return "죄송해요, 처리 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요."
    }


    /// 사용자가 발화에서 **직접 말한** 값을 이번 요청의 인자로 읽어낸다. 모델을 거치지 않으므로
    /// 모델이 무엇을 보내든 상관없이 결정적이고, 어디에도 저장하지 않는다 — 다음 요청에서는
    /// 말하지 않으면 다시 묻는다.
    ///
    /// 옛 applyStatedPreferences와 달리 "기억해줘"·"주로" 같은 신호어를 요구하지 않는다.
    /// 그 신호어는 "이번 일정 얘기"와 "기본값 설정"을 가르려고 있었는데, 저장할 기본값 자체가
    /// 사라졌으므로 가를 것이 없다. 대신 낱말을 좁게 잡는다(statedMode 주석 참고).
    private static func statedArguments(from text: String) -> [String: Any] {
        var args: [String: Any] = [:]
        if let m = statedMode(in: text) { args["mode_this_time"] = m.rawValue }
        if let b = minutes(in: text, near: ["여유"]) { args["buffer_minutes"] = b }
        if let n = minutes(in: text, near: ["알림", "분 전"]) { args["notify_lead_minutes"] = n }
        return args
    }

    /// 발화에서 이동수단을 읽어낸다. **이동을 말하는 형태일 때만** 잡는 것이 핵심이다 —
    /// 낱말만 보던 옛 판정은 "기차역에서 만나"를 대중교통으로 잡았고, 그렇게 들어간 값은
    /// 카드에서 줄을 지워버려 사용자가 고칠 기회조차 잃는다(이 SPEC이 없애려는 바로 그 모양).
    /// 대중교통·도보를 먼저 보는 이유는 "기차"처럼 '차'가 들어간 낱말이 자동차로 잡히지 않게.
    private static func statedMode(in text: String) -> TransportMode? {
        for w in ["대중교통", "지하철로", "지하철 타", "전철로", "전철 타", "버스로", "버스 타", "기차로", "기차 타"]
            where text.contains(w) { return .transit }
        for w in ["도보로", "걸어서", "걸어갈", "걷는"] where text.contains(w) { return .walk }
        for w in ["자동차로", "자차로", "차로 가", "차 타고", "운전해", "운전하"] where text.contains(w) { return .car }
        return nil
    }

    /// 카드에 "말씀하신 대로 이미 정해진 것"을 적는다 — 줄이 사라진 자리를 사용자가 보지
    /// 못하면 그것 역시 조용한 적용이다.
    private func statedLabels() -> [String] {
        var out: [String] = []
        if let m = (statedArgs["mode_this_time"] as? String).flatMap(TransportMode.init(rawValue:)) {
            out.append("이동수단 \(m.title)")
        }
        if let b = statedArgs["buffer_minutes"] as? Int { out.append("도착 여유 \(b)분") }
        if let n = statedArgs["notify_lead_minutes"] as? Int { out.append("알림 \(n)분 전") }
        return out
    }

    // MARK: - 대화 + 툴 루프

    /// - Parameter seed: 카드 확인 경로처럼 **루프에 들어오기 전에 이미 실행된** 툴 결과.
    ///   뒤이은 AI 호출만 실패했을 때 사용자에게 보여줄 폴백이 첫 바퀴부터 있어야 한다.
    private func runLoop(seed: String? = nil) async throws {
        // 툴 호출이 이어질 수 있으니 최대 몇 회까지 반복.
        // lastToolSummary: 툴이 이미 성공 실행된 뒤(등록 자체는 끝난 뒤) 뒤이은 "자연스러운 확인 문구"용
        // AI 호출만 실패하는 경우를 위한 폴백. 등록은 이미 끝났으니 이 경우 에러로 취급하면 안 되고
        // (사용자가 "실패"로 오해해 같은 요청을 또 보내면 중복 등록됨), 툴이 직접 만든 결과 문구를 그대로 보여준다.
        var lastToolSummary: String? = seed
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
            guard parts.contains(where: { $0["functionCall"] != nil }) else {
                contents.append(["role": "model", "parts": parts])
                return
            }

            // 모델이 보낸 인자 중 **선언에 없는 키**를 여기서 버린다(인바운드 단일 초크포인트).
            // 이 아래의 fillStated(발화로 읽은 값 주입)·pendingAsk/askFields(부재 판정)·
            // resolvePendingAsk(카드 답 주입)·runToolCalls(실행)이 전부 정화된 인자를 본다 —
            // 앱이 스스로 넣는 값(발화·카드)은 이 뒤에 얹히므로 영향받지 않는다. 왜 버리는지는
            // sanitizeModelArgs 주석에.
            let filled = fillStated(sanitizeModelArgs(parts))

            // 그래도 비어 있는 인자가 있으면 앱이 직접 묻는다. 모델 턴은 아직 히스토리에 넣지
            // 않고 카드에 보류한다 — 미완성 인자가 담긴 턴을 남기면 그 값이 이후 요청에 계속
            // 딸려가고, 확인 뒤 채워 넣은 값과 두 벌이 된다.
            if let ask = pendingAsk(for: filled) {
                bubbles.append(.init(role: .assistant, text: "", ask: ask))
                return
            }

            contents.append(["role": "model", "parts": filled])
            lastToolSummary = await runToolCalls(filled) ?? lastToolSummary
        }
        // 5회를 다 돌 때까지 마무리가 안 된 드문 경우에도, 툴 결과가 있으면 보여준다.
        if let lastToolSummary { bubbles.append(.init(role: .assistant, text: lastToolSummary)) }
    }

    /// 모델 턴의 도구 호출을 차례로 실행하고, 결과를 하나의 function 턴으로 모아 히스토리에
    /// 담는다. 마지막 결과 문구를 돌려준다(뒤이은 AI 호출이 실패해도 보여줄 폴백).
    ///
    /// 루프에서 떼어낸 이유는 카드 확인 경로가 같은 실행을 해야 하기 때문이다 — 두 벌로 적으면
    /// 한쪽만 고쳐져 "카드로 만든 일정만 다르게 동작"하는 결함이 된다(계약 5).
    private func runToolCalls(_ parts: [[String: Any]]) async -> String? {
        var resultParts: [[String: Any]] = []
        var last: String?
        for call in parts.compactMap({ $0["functionCall"] as? [String: Any] }) {
            let name = call["name"] as? String ?? ""
            let args = call["args"] as? [String: Any] ?? [:]
            let resultText = await executeTool(name: name, input: args)
            resultParts.append(["functionResponse": ["name": name, "response": ["result": resultText]]])
            last = resultText
        }
        guard !resultParts.isEmpty else { return nil }
        contents.append(["role": "function", "parts": resultParts])
        return last
    }

    // MARK: - 앱 주도 되묻기(카드)

    /// 이 호출이 **실제로 쓸** 인자 중 아직 비어 있는 것들. "무엇을 물을까"의 단일 출처다 —
    /// 카드를 그릴 때와 확인 뒤 값을 채울 때가 같은 목록을 봐야 어긋나지 않는다(계약 5).
    ///
    /// 쓰지 않을 값은 묻지 않는다: 출발 기준 구간엔 도착 여유를 둘 대상이 없고, 이동을 만들지
    /// 않는 활동엔 이동수단이 쓰일 자리가 없다. 안 쓰는 걸 물으면 카드만 길어진다.
    private func askFields(tool: String, args: [String: Any]) -> [AskField] {
        func filled(_ key: String) -> Bool {
            if let s = args[key] as? String { return !s.trimmingCharacters(in: .whitespaces).isEmpty }
            return args[key] != nil
        }
        /// 그 인자가 "일반명사인데 같은 이름의 즐겨찾기가 없다"면 그 낱말, 아니면 nil.
        /// 값이 비어서가 아니라 **앱이 풀 수 없어서** 물어야 하는 자리다(결함 O). 판정이 동기라서
        /// 여기서 할 수 있다 — 즐겨찾기는 메모리에 있고 일반명사 목록은 정적 집합이라 네트워크가
        /// 필요 없다. 검색까지 해봐야 아는 실패는 여기서 판정할 수 없고, 그건 실행부가 맡는다.
        func unknownPlace(_ key: String) -> String? {
            guard unresolvedGenericPlace(args[key]) else { return nil }
            return (args[key] as? String)?.trimmingCharacters(in: .whitespaces)
        }
        // 알림을 꺼 달라고 한 요청에는 알림 줄을 만들지 않는다(notify_enabled는 모델이 채운다).
        let notifyOn = (args["notify_enabled"] as? Bool) != false
        var fields: [AskField] = []
        switch tool {
        case "create_schedule":
            // 제목·목적지·시각도 카드가 묻는다(2026-09-16 카드 확장 ①) — required에서 빼야 모델이
            // 비워둘 수 있고, 비워야 이 줄들이 뜬다. 선언은 그대로라 사용자가 말하면 모델이 넘긴다.
            if !filled("title") { fields.append(titleField()) }
            // 값이 비었으면 평범한 줄, 차 있는데 못 풀면 이유를 적은 줄 — **둘 다 카드에서 끝난다**.
            // 예전엔 후자를 실행부가 "즐겨찾기에 추가해 주세요"로 되돌려 보내 대화가 거기서 끊겼고,
            // 사용자는 채팅을 떠나 ⭐ 화면에 등록한 뒤 처음부터 다시 말해야 했다(2026-09-16 결함 O).
            if !filled("destination_query") { fields.append(destinationField()) }
            else if let q = unknownPlace("destination_query") { fields.append(destinationField(unknown: q)) }
            if !filled("origin_query") { fields.append(originField()) }
            else if let q = unknownPlace("origin_query") { fields.append(originField(unknown: q)) }
            // 시각의 유무는 nil이 아니라 **filled**로 판정한다 — 이 모델은 "비움"을 빈 문자열로
            // 실어 보내는 경우가 있다(다른 줄의 부재 판정과 같은 이유). nil로만 보면 arrival_iso:""에
            // 시각 줄이 영영 안 뜨고, 확인 뒤에야 실행부가 parseDate에서 걸러 모델에게 되물게 한다.
            if !filled("arrival_iso"), !filled("departure_iso") { fields.append(timeField()) }
            if !filled("mode_this_time") { fields.append(modeField("mode_this_time", label: "이동수단")) }
            // 여유는 도착 기준에만 쓰인다 — 도착이 정해졌거나 아직 기준을 모를 때(=시각 줄이 있을
            // 때) 묻는다. 도착·출발 둘 다 오는 모델 오류는 실행부가 도착을 우선하므로 도착 편에 붙인다.
            if filled("arrival_iso") || !filled("departure_iso") {
                if !filled("buffer_minutes") { fields.append(bufferField()) }
            }
            if notifyOn, !filled("notify_lead_minutes") { fields.append(notifyField()) }
        case "create_recurring_schedule":
            // 목적지는 이 도구에선 비어 올 수 없다(선언 required) — 그래서 "못 푸는 값"일 때만 뜬다.
            // 118건이 '농업회사법인 화조원'으로 등록된 사고가 난 자리가 정확히 여기다(결함 K).
            if let q = unknownPlace("destination_query") { fields.append(destinationField(unknown: q)) }
            if !filled("origin_query") { fields.append(originField()) }
            else if let q = unknownPlace("origin_query") { fields.append(originField(unknown: q)) }
            if !filled("mode_this_time") { fields.append(modeField("mode_this_time", label: "이동수단")) }
            if !filled("buffer_minutes") { fields.append(bufferField()) }
            if notifyOn, !filled("notify_lead_minutes") { fields.append(notifyField()) }
            if !filled("weeks") { fields.append(weeksField()) }
        case "create_activity":
            // 못 푸는 장소 줄은 아래 guard(이동이 없으면 수단·여유를 묻지 않는다)보다 **앞**에 둔다 —
            // 이동이 없는 활동도 place_query를 못 풀면 위치 없는 활동으로 조용히 등록되기 때문이다.
            if let q = unknownPlace("place_query") { fields.append(activityPlaceField(unknown: q)) }
            if let q = unknownPlace("travel_from_query") { fields.append(outboundOriginField(unknown: q)) }
            if let q = unknownPlace("return_to_query") { fields.append(returnPlaceField(unknown: q)) }
            let outbound = filled("travel_from_query"), back = filled("return_to_query")
            guard outbound || back else { break }
            // 왕복을 염두에 둔 호출(return_to_query 있음)에서 모델이 가는 출발지를 빠뜨리면, 비었다고
            // 조용히 편도로 만들지 않고 어디서 오는지 묻는다(2026-09-16 실기기 결함 — 가는 편이 아예
            // 안 생기고 여유 줄도 사라졌다). 출발지는 절대 추측해 넣지 않는다.
            if back, !outbound { fields.append(outboundOriginField()) }
            if back {
                // 갈 땐 지하철, 올 땐 택시 — 사용자가 Day 7에 따로 고르게 해 달라고 한 자리다.
                if !filled("travel_mode_this_time") { fields.append(modeField("travel_mode_this_time", label: "가는 편")) }
                if !filled("return_mode_this_time") { fields.append(modeField("return_mode_this_time", label: "오는 편")) }
            } else if !filled("mode_this_time") {
                fields.append(modeField("mode_this_time", label: "이동수단"))
            }
            // 여유는 가는 편(도착 기준 구간)에만 쓰인다 — 복귀는 출발 기준이라 0으로 고정이다.
            // return만 온 호출에서도 미리 묻는다: 출발지 줄에서 진짜 출발지를 고르면 왕복이 되는데
            // 카드는 한 장이라 답에 따라 줄이 늘어날 수 없기 때문이다. "가는 편 없음"으로 답하면
            // 이 값은 쓰이지 않는다(가는 편이 없으면 여유를 둘 구간 자체가 없다).
            if !filled("buffer_minutes") { fields.append(bufferField()) }
            if notifyOn, !filled("notify_lead_minutes") { fields.append(notifyField()) }
        default: break
        }
        return fields
    }

    /// 출발지 줄. 즐겨찾기 + 현재 위치 + 직접입력이고, 고른 값은 resolveOrigin이 그대로 읽는다.
    /// `unknown`이 오면 사용자가 말한 낱말을 앱이 풀지 못해 뜬 줄이다 — 줄 이름은 그대로 두고
    /// 이유만 캡션으로 붙인다(줄 이름은 실행부 안내·확정 요약과 같은 문구라 상황마다 바꾸면
    /// 세 자리가 서로 다른 말을 하게 된다).
    private func originField(unknown: String? = nil) -> AskField {
        var options = store.favorites.map { AskField.Option(label: $0.label, value: $0.label) }
        options.append(.init(label: "현재 위치", value: Self.currentLocationToken))
        return .init(key: "origin_query", kind: .place, label: "출발지",
                     options: options, allowsCustom: true,
                     note: unknown.map(Self.unknownPlaceNote))
    }

    /// 제목 줄. 칩이 없다 — 제목은 열거 불가능하고 앱이 내놓는 후보는 그 자체로 "앱이 지어낸 값"이다.
    private func titleField() -> AskField {
        .init(key: "title", kind: .title, label: "제목", options: [], allowsCustom: true)
    }

    /// 목적지 줄. 출발지 줄에서 "현재 위치"만 뺀 형제 — 목적지는 사용자가 실제로 가려는 곳이라
    /// 현재 위치가 기본값이 될 이유가 없다.
    private func destinationField(unknown: String? = nil) -> AskField {
        let options = store.favorites.map { AskField.Option(label: $0.label, value: $0.label) }
        return .init(key: "destination_query", kind: .place, label: "목적지",
                     options: options, allowsCustom: true,
                     note: unknown.map(Self.unknownPlaceNote))
    }

    /// 활동 장소 줄. **못 푸는 값일 때만** 뜬다(빈 place_query는 장소 없는 활동이라는 정당한 요청).
    /// 목적지 줄과 같은 이유로 "현재 위치" 칩이 없다 — 활동이 열리는 곳은 사용자가 가려는 곳이다.
    private func activityPlaceField(unknown: String) -> AskField {
        .init(key: "place_query", kind: .place, label: "활동 장소",
              options: store.favorites.map { .init(label: $0.label, value: $0.label) },
              allowsCustom: true, note: Self.unknownPlaceNote(unknown))
    }

    /// 오는 편 도착지 줄. 이쪽도 못 푸는 값일 때만 뜬다 — 빈 값은 "오는 편 없음"이라는 뜻이고,
    /// 그건 물을 일이 아니다. 도착지이므로 "현재 위치" 칩은 없다(목적지 줄과 같은 자리).
    private func returnPlaceField(unknown: String) -> AskField {
        .init(key: "return_to_query", kind: .place, label: "오는 편 도착지",
              options: store.favorites.map { .init(label: $0.label, value: $0.label) },
              allowsCustom: true, note: Self.unknownPlaceNote(unknown))
    }

    /// 시각 줄. 칩으로 값을 열거하지 않는다 — 날짜·시각은 열거 불가능한 값 공간이고 "오늘/내일" 칩은
    /// 카드가 떠 있는 동안 자정이 지나면 거짓이 된다. 점선 캡슐 → 네이티브 DatePicker 에디터로
    /// 직접입력과 같은 문법을 쓰고, 값은 "arr:"/"dep:" 접두 + ISO로 직렬화된다. 도착/출발 기준 칩은
    /// 모델의 options가 아니라 에디터의 일부라 뷰가 그린다.
    private func timeField() -> AskField {
        .init(key: "arrival_iso", kind: .datetime, label: "시각",
              options: [], allowsCustom: false)
    }

    /// 가는 출발지 줄(왕복 의도에서 모델이 travel_from_query를 비워 보냈을 때). 출발지 줄과 같은
    /// 재료에 **"가는 편 없음" 칩**을 얹는다 — 이미 그 장소에 있어 오는 길만 필요한 진짜 편도다.
    /// 칩의 값은 내부 토큰이고 executeCreateActivity가 "이 구간은 만들지 않는다"로 푼다. 빈 문자열을
    /// 그대로 실을 수 없는 이유: 부재 판정(askFields)이 다시 그 줄을 물어야 한다고 읽어, 사용자가
    /// 골랐는데도 실행이 missingAskedArguments에서 막힌다 — "현재 위치"가 currentLocationToken으로
    /// 흘러가는 것과 같은 방식이라 값이 비었는지 토큰인지는 실행부만 구분하면 된다.
    private func outboundOriginField(unknown: String? = nil) -> AskField {
        var options = store.favorites.map { AskField.Option(label: $0.label, value: $0.label) }
        options.append(.init(label: "현재 위치", value: Self.currentLocationToken))
        // 탈출 칩은 **모델이 비워 보냈을 때만** 붙인다 — 사용자가 출발지를 실제로 말한 호출(unknown)
        // 에서는 가는 편을 만들 의도가 이미 분명해서, 지우는 선택지를 먼저 내밀 자리가 아니다.
        if unknown == nil { options.append(.init(label: "가는 편 없음", value: Self.noOutboundToken)) }
        return .init(key: "travel_from_query", kind: .place, label: "가는 편 출발지",
                     options: options, allowsCustom: true,
                     note: unknown.map(Self.unknownPlaceNote))
    }

    /// 이동수단 줄. 세 칩이 곧 TransportMode 전체 집합이라 직접입력을 붙이지 않는다 —
    /// 붙여봐야 고를 수 있는 값이 늘지 않고, 오히려 없는 수단을 적을 자리만 생긴다.
    private func modeField(_ key: String, label: String) -> AskField {
        .init(key: key, kind: .mode, label: label,
              options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
              allowsCustom: false)
    }

    /// 도착 여유 줄. **진짜 0분 칩이 있다** — 0은 "여유 없이"라는 정당한 요청인데 문장 파서가
    /// 0보다 큰 값만 돌려줘서 말로는 전달할 길이 없었다. 카드가 그 격차를 닫는다.
    private func bufferField() -> AskField {
        .init(key: "buffer_minutes", kind: .buffer, label: "도착 여유",
              options: [.init(label: "0분", value: "0"), .init(label: "10분", value: "10"),
                        .init(label: "20분", value: "20"), .init(label: "30분", value: "30")],
              allowsCustom: true)
    }

    /// 알림 줄. 0은 "알림 없음"이 아니라 **출발 시각 알림**이라 그렇게 적는다 — 알림 자체를
    /// 끄는 건 notify_enabled(발화: "알림 필요 없어")이고, 그때는 이 줄이 아예 안 생긴다.
    private func notifyField() -> AskField {
        .init(key: "notify_lead_minutes", kind: .notify, label: "알림",
              options: [.init(label: "출발 시각", value: "0"), .init(label: "10분 전", value: "10"),
                        .init(label: "30분 전", value: "30"), .init(label: "1시간 전", value: "60")],
              allowsCustom: true)
    }

    private func weeksField() -> AskField {
        .init(key: "weeks", kind: .weeks, label: "반복 기간",
              options: [.init(label: "4주", value: "4"), .init(label: "8주", value: "8"),
                        .init(label: "12주", value: "12"),
                        .init(label: "\(Store.maxRecurrenceWeeks)주", value: "\(Store.maxRecurrenceWeeks)")],
              allowsCustom: true)
    }

    /// 이 턴의 모든 호출에서 비어 있는 인자를 모아 카드 **한 장**을 만든다. 한 턴에 호출이
    /// 여러 개여도(이미지 한 장에서 일정 여러 건) 카드는 한 장이고 같은 답이 전부에 적용된다 —
    /// 호출마다 끼어들면 사용자가 같은 질문에 다섯 번 답하게 된다.
    private func pendingAsk(for parts: [[String: Any]]) -> PendingAsk? {
        var fields: [AskField] = []
        for call in parts.compactMap({ $0["functionCall"] as? [String: Any] }) {
            let name = call["name"] as? String ?? ""
            let args = call["args"] as? [String: Any] ?? [:]
            for f in askFields(tool: name, args: args) where !fields.contains(where: { $0.key == f.key }) {
                fields.append(f)
            }
        }
        guard !fields.isEmpty else { return nil }
        var stated = statedLabels()
        // 모델이 채워온 제목·목적지는 줄이 안 생기는 값이다 — 카드에 적어 보이지 않으면 사용자가
        // 못 본 채 그대로 등록된다(표시 자체가 이 값의 최소 방어다. 잔여 노출은 보고서 참조).
        for call in parts.compactMap({ $0["functionCall"] as? [String: Any] })
        where (call["name"] as? String) == "create_schedule" {
            let cArgs = call["args"] as? [String: Any] ?? [:]
            // 같은 값에 줄이 생겼으면 여긴 비운다 — 카드가 묻고 있는 값을 "말씀하신 대로 정해졌다"고
            // 같이 적으면 한 카드가 서로 다른 말을 한다(못 푸는 목적지 줄이 생기는 결함 O 경로).
            if let t = (cArgs["title"] as? String)?.trimmingCharacters(in: .whitespaces), !t.isEmpty,
               !fields.contains(where: { $0.key == "title" }) {
                stated.append("제목 '\(t)'")
            }
            if let d = (cArgs["destination_query"] as? String)?.trimmingCharacters(in: .whitespaces), !d.isEmpty,
               !fields.contains(where: { $0.key == "destination_query" }) {
                stated.append("목적지 '\(d)'")
            }
        }
        return PendingAsk(parts: parts, stated: stated, fields: fields)
    }

    /// 모델 턴의 도구 호출 인자에서 **선언에 없는 키**를 뺀다. SPEC-ASK-001의 전제는 "선언에서
    /// 뺀 인자는 모델이 보낼 수 없다"였으나 이 모델은 선언 밖 인자도 얽어 보낸다(2026-09-16
    /// 실기기 — 없는 mode_this_time·buffer_minutes·notify_lead_minutes·weeks가 카드를 우회해
    /// 사용자가 고르지 않은 값으로 반복 일정 118건을 등록했다). 선언 밖 인자는 부재 판정을
    /// 속이는 값일 뿐이라 도착 즉시 버린다. 화이트리스트를 별도로 두 벌 유지하면 선언과 어긋나므로
    /// **선언 자체에서 구한다** — 갱신 도구(update_*)의 mode·buffer·notify·confirm_zero는 선언돼
    /// 있어 그대로 통과하고, notify_enabled도 선언돼 있어("알림 필요 없어") 그대로 통과한다.
    private func sanitizeModelArgs(_ parts: [[String: Any]]) -> [[String: Any]] {
        parts.map { part in
            guard var call = part["functionCall"] as? [String: Any],
                  let name = call["name"] as? String else { return part }
            let allowed = modelSuppliableKeys(for: name)
            // 선언에 없는 도구는 정화 대상이 아니다(어차피 실행부가 "알 수 없는 도구"로 거부).
            guard !allowed.isEmpty,
                  let args = call["args"] as? [String: Any],
                  args.keys.contains(where: { !allowed.contains($0) }) else { return part }
            call["args"] = args.filter { allowed.contains($0.key) }
            var out = part
            out["functionCall"] = call
            return out
        }
    }

    /// 도구별로 모델이 실어와도 되는 인자 키(= 선언의 properties). 매 턴 다시 파지 않게 한 번만 뺀다.
    private var declaredKeysCache: [String: Set<String>]?
    private func modelSuppliableKeys(for tool: String) -> Set<String> {
        if let declaredKeysCache { return declaredKeysCache[tool] ?? [] }
        var map: [String: Set<String>] = [:]
        for t in toolsJSON() {
            guard let name = t["name"] as? String,
                  let props = (t["parameters"] as? [String: Any])?["properties"] as? [String: Any] else { continue }
            map[name] = Set(props.keys)
        }
        declaredKeysCache = map
        return map[tool] ?? []
    }

    /// 발화에서 읽어낸 값을 호출 인자에 채운다. **그 도구가 물었을 인자에만** 넣는다 —
    /// 쓰지도 않을 인자를 얹으면 실행부가 엉뚱한 값을 보게 된다.
    private func fillStated(_ parts: [[String: Any]]) -> [[String: Any]] {
        guard !statedArgs.isEmpty else { return parts }
        return parts.map { part in
            guard var call = part["functionCall"] as? [String: Any] else { return part }
            let name = call["name"] as? String ?? ""
            var args = call["args"] as? [String: Any] ?? [:]
            for f in askFields(tool: name, args: args) {
                // 이동수단은 도구마다 인자 이름이 다르다(가는 편·오는 편) — 발화의 한 값이
                // 그 줄들 전부에 적용돼야 "자동차로 가자"가 왕복 모두에 걸린다.
                let stated = f.kind == .mode ? statedArgs["mode_this_time"] : statedArgs[f.key]
                if let stated { args[f.key] = stated }
            }
            var out = part
            call["args"] = args
            out["functionCall"] = call
            return out
        }
    }

    /// 칩을 탭했을 때. 마지막 탭이 그 줄의 값이고, 확인 전까지는 아무것도 실행되지 않는다.
    func choose(field: UUID, value: String) {
        guard let b = bubbles.lastIndex(where: { $0.ask != nil }),
              let f = bubbles[b].ask?.fields.firstIndex(where: { $0.id == field }) else { return }
        bubbles[b].ask?.fields[f].chosen = value
    }

    /// 검색 후보를 탭했을 때. 이름을 `chosen`에 넣고 **좌표는 confirmedPlaces에 따로** 기록한다.
    /// 이 순간부터 그 이름은 "앱이 못 푸는 값"이 아니다 — 일반명사 거절(unresolvedGenericPlace)과
    /// 검색이 여기서 갈린다: 자유 텍스트로 '사무실'을 확정하는 건 여전히 거절이고, 검색 결과에서
    /// 고른 '사무실'(진짜 상호, 좌표 있음)은 통과한다.
    func choose(field: UUID, place: Place) {
        confirmedPlaces[place.name] = place
        choose(field: field, value: place.name)
    }

    /// 후보 개수 상한. 카카오는 10건까지 주지만 카드가 그만큼 길어지면 아래 줄들이 화면 밖으로
    /// 밀린다(G11은 "줄을 숨기지 않는다"이지 "얼마든 길어져도 된다"가 아니다). 5건이면 한 손에
    /// 들어오고, 원하는 곳이 없으면 더 적어서 좁히는 쪽이 목록을 훑는 것보다 빠르다.
    static let maxPlaceSuggestions = 5

    /// 장소 줄의 검색. **입력이 멈춘 뒤 한 번만** 부른다 — 글자마다 부르면 카카오 일일 할당량을
    /// 그대로 태운다(이 프로젝트는 외부 한도로 이미 데였다: iOS 알림 64건). 350ms인 이유는 한글
    /// 조합이 한 글자를 완성하는 간격보다는 길고("가"→"강"→"강남"이 한 번으로 묶인다) 다 치고
    /// 기다리는 느낌이 나기엔 짧아서다. 같은 질의가 이어서 오면 아예 부르지 않는다(지우고 다시 친 경우).
    ///
    /// 카드를 막지 않는다: 호출자는 기다리지 않고, 결과는 돌아왔을 때 그 줄에만 얹힌다. 확인 버튼의
    /// 잠금은 `chosen`만 보므로 검색 중이라고 열리거나 잠기지 않는다.
    func searchPlaces(field: UUID, text: String) {
        let q = text.trimmingCharacters(in: .whitespaces)
        placeSearchTasks[field]?.cancel()
        guard !q.isEmpty else {
            lastPlaceQuery[field] = nil
            setLookup(field, .idle)
            return
        }
        guard lastPlaceQuery[field] != q else { return }
        setLookup(field, .searching)
        placeSearchTasks[field] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled, let self else { return }
            let found = await self.store.placeSearch.search(q, near: self.location.currentLocation)
            guard !Task.isCancelled else { return }
            self.lastPlaceQuery[field] = q
            // 0건과 검색 실패(오프라인)는 PlaceSearch.search가 둘 다 빈 배열로 돌려준다 — 여기서는
            // 구분할 수 없어 문구가 양쪽을 함께 말한다. 조용히 넘기지는 않는다(상태가 보인다).
            self.setLookup(field, found.isEmpty ? .empty
                           : .results(Array(found.prefix(Self.maxPlaceSuggestions))))
        }
    }

    /// 검색 결과를 줄에 얹는다. **await에서 돌아온 뒤 인덱스를 다시 구한다** — 도는 사이 카드가
    /// 취소되거나(다음 발화) 확인으로 소비되거나 말풍선이 더 쌓일 수 있다. 이 프로젝트의 1번 위험
    /// 부류(H1)라서, 잡아뒀던 자리에 쓰지 않고 줄 id로 다시 찾고 없으면 조용히 버린다. 줄 id는
    /// 카드마다 새로 만들어지므로 늦게 온 결과가 **다른 카드의 같은 이름 줄**에 앉을 수 없다.
    private func setLookup(_ field: UUID, _ lookup: AskField.Lookup) {
        guard let b = bubbles.lastIndex(where: { $0.ask != nil }),
              let f = bubbles[b].ask?.fields.firstIndex(where: { $0.id == field }) else { return }
        bubbles[b].ask?.fields[f].lookup = lookup
    }

    /// 카드가 사라지는 순간(취소·확인) 도는 검색을 끊는다. 남겨두면 아무 데도 못 앉을 결과를
    /// 위해 네트워크만 쓴다.
    private func cancelPlaceSearches() {
        placeSearchTasks.values.forEach { $0.cancel() }
        placeSearchTasks = [:]
        lastPlaceQuery = [:]
    }

    /// 직접입력 제출. 빈 입력과 범위 밖은 받아들이지 않는다 — 값이 안 정해지므로 확인 버튼도
    /// 계속 잠겨 있다. 여기서 막아야 범위 밖 값이 실행부까지 흘러가지 않는다.
    @discardableResult
    func submitCustom(field: UUID, text: String) -> Bool {
        guard let b = bubbles.lastIndex(where: { $0.ask != nil }),
              let f = bubbles[b].ask?.fields.firstIndex(where: { $0.id == field }),
              let value = bubbles[b].ask?.fields[f].accepts(text) else { return false }
        // 즐겨찾기 없는 일반명사를 장소 줄에 다시 적는 건 답이 아니다 — 받아들이면 확인 뒤 해석부가
        // 같은 이유로 막아 대화가 한 바퀴를 더 돈다. 거절만 하면 "그 값은 쓸 수 없어요"뿐이라 왜인지
        // 알 수 없으므로, 그 줄에 이유(캡션)를 그때 붙인다 — 빈 값을 묻던 평범한 줄도 이 순간부터는
        // "앱이 모르는 장소를 받은 줄"이라 못 푸는 값으로 뜬 줄과 같은 설명이 맞다.
        if bubbles[b].ask?.fields[f].kind == .place, unresolvedGenericPlace(value) {
            bubbles[b].ask?.fields[f].note = Self.unknownPlaceNote(value)
            return false
        }
        bubbles[b].ask?.fields[f].chosen = value
        return true
    }

    /// 시각 줄의 에디터가 값을 확정하는 통로. 뷰가 ISO를 직접 만들지 않게 한다 — 형식의 단일
    /// 출처(isoFormatter)가 accepts·직렬화와 같은 자리에 있어야 세 곳이 어긋나지 않는다.
    /// 기준은 반드시 여기 실려 온다(사용자 결정: 기준 칩을 미리 골라두지 않는다 — 기준 없는
    /// 시각은 확정되지 않으므로 확인 버튼이 그대로 잠긴다).
    @discardableResult
    func chooseTime(field: UUID, basis: ScheduleAnchor, date: Date) -> Bool {
        submitCustom(field: field, text: (basis == .arrival ? "arr:" : "dep:")
            + Self.isoFormatter.string(from: date))
    }

    /// 커밋된 시각의 기준만 바꾼다(같은 시각, 에디터 재오픈 없이) — 기준 칩을 다시 탭했을 때.
    @discardableResult
    func rechooseTimeBasis(field: UUID, basis: ScheduleAnchor) -> Bool {
        guard let chosen = bubbles.lastIndex(where: { $0.ask != nil })
            .flatMap({ bubbles[$0].ask?.fields.first(where: { $0.id == field })?.chosen }),
            let parsed = Self.parseDatetime(chosen) else { return false }
        return chooseTime(field: field, basis: basis, date: parsed.date)
    }

    /// 카드의 확인 버튼. 고른 값을 보류해 둔 호출에 실어 **정확히 1회** 실행한다.
    /// 호출을 앱이 직접 만들므로 선택과 실제 값 사이에 모델이 끼어들 틈이 없다.
    func confirmAsk() async {
        guard !isThinking, bubbles.contains(where: { $0.ask != nil }) else { return }
        isThinking = true
        defer { isThinking = false; saveHistory() }
        guard let summary = await resolvePendingAsk() else { return }
        do {
            try await runLoop(seed: summary)
            stripInlineDataFromHistory()
            trimHistory()
        } catch {
            // 툴은 이미 실행됐다 — 여기 오는 건 마무리 문구용 AI 호출만 실패한 경우다.
            bubbles.append(.init(role: .assistant, text: Self.userMessage(for: error)))
        }
    }

    /// 카드를 소비해 보류해 둔 호출을 실행한다. **모델을 부르지 않는 부분만** 여기 있다 —
    /// 확인 버튼과 GuardDriver가 같은 경로를 지나가야 "카드로 만든 일정만 다르게 동작"하는
    /// 결함이 안 생기고, 드라이버는 이 지점까지만 돌려 모델·할당량 없이 결정적으로 검증한다.
    /// 돌려주는 값은 마지막 툴 결과 문구다(카드가 없거나 아직 덜 골랐으면 nil).
    @discardableResult
    private func resolvePendingAsk() async -> String? {
        guard let idx = bubbles.lastIndex(where: { $0.ask != nil }),
              let ask = bubbles[idx].ask, ask.isReady else { return nil }
        cancelPlaceSearches()

        // 카드를 고른 값 요약으로 바꾼다 — 남겨두면 같은 호출을 두 번 보낼 수 있고, 보류 상태가
        // 히스토리 저장에 닿아서도 안 된다. 요약은 사용자가 무엇을 골랐는지 다시 볼 자리다.
        let chosenLine = ask.fields.compactMap { f in f.chosenLabel.map { "\(f.label) \($0)" } }
            .joined(separator: " · ")
        bubbles[idx] = .init(role: .user, text: chosenLine)

        var parts = ask.parts
        for i in parts.indices {
            guard var call = parts[i]["functionCall"] as? [String: Any] else { continue }
            let name = call["name"] as? String ?? ""
            var args = call["args"] as? [String: Any] ?? [:]
            // 카드를 만들 때와 **같은 함수**로 이 호출이 무엇을 물었는지 다시 구한다.
            for f in askFields(tool: name, args: args) {
                guard let chosen = ask.fields.first(where: { $0.key == f.key })?.chosen else { continue }
                // 출발 기준으로 확정된 시각 옆의 여유는 실리지 않는다 — 줄을 흐리게 하고 캡션으로
                // "안 쓴다"고 보여줬으므로 여기가 그 약속의 실행 장소다. chosen은 그대로 남겨
                // 확인 버튼이 막히지 않게 한다(교착 방지).
                if f.kind == .buffer,
                   let time = ask.fields.first(where: { $0.kind == .datetime })?.chosen,
                   Self.parseDatetime(time)?.prefix == "dep:" { continue }
                switch f.kind {
                case .buffer, .notify, .weeks: args[f.key] = Int(chosen) ?? 0
                case .place, .mode, .title: args[f.key] = chosen
                case .datetime:
                    // 접두가 곧 도착/출발 기준이다 — arrival·departure 중 정확히 하나만 쓴다.
                    // 실행부의 parseDate가 받는 형식 그대로다.
                    if let p = Self.parseDatetime(chosen) {
                        args[p.prefix == "arr:" ? "arrival_iso" : "departure_iso"]
                            = Self.isoFormatter.string(from: p.date)
                    }
                }
            }
            call["args"] = args
            parts[i]["functionCall"] = call
        }

        contents.append(["role": "model", "parts": parts])
        return await runToolCalls(parts)
    }

    /// 답을 못 받은 카드를 접는다. 보류한 모델 턴은 히스토리에 넣은 적이 없으므로 버려도
    /// 남는 흔적이 없다 — 등록되지 않았다는 사실만 사용자에게 남긴다.
    private func cancelPendingAsk() {
        cancelPlaceSearches()
        for i in bubbles.indices where bubbles[i].ask != nil {
            bubbles[i] = .init(role: .assistant, text: "물어본 값을 받지 못해서 그 등록은 진행하지 않았어요.")
        }
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
        // OpenAI 쿼터 소진: 프록시가 429에 {"error":"openai_error","detail":…(OpenAI 원문)}로 돌려주므로
        // insufficient_quota 마커가 detail에 그대로 남는다. 상태코드만(429 전부)으로 몰면 일시적
        // rate limit까지 "사용량 소진"이 되고, 마커 문자열만 좇으면 백엔드가 또 바뀌었을 때 옛 값이
        // 남는다 — 둘을 묶는다. 예전 Workers AI 판별(4006/neurons)은 그 백엔드 삭제(860e121) 뒤
        // 도달 불가능한 죽은 분기여서, 감지를 고치며 안내문도 같이 고쳤다.
        let hardQuota = status == 429
            && (text.localizedCaseInsensitiveContains("insufficient_quota")
                || text.localizedCaseInsensitiveContains("usage_limit_"))
        if hardQuota {
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
        // 저장된 선호를 프롬프트에 주입하던 세 블록(prefsBlock·modeBlock·factsBlock)은 없앴다.
        // "이 숫자를 그대로 채워라"와 "mode_this_time은 비워둬라"가 한 프롬프트 안에서 방향이
        // 정반대였고, 모델은 INTEGER에 없는 '비움'을 0으로 대신 써서 저장해둔 여유·알림 10분을
        // 0으로 덮었다(35건이 그렇게 등록되고도 아무도 몰랐다). 지금은 이 값들이 툴 선언에
        // 아예 없다 — 모델이 채울 수 없으니 앱이 "비었다"를 관측해 사용자에게 직접 묻는다.
        // 절대 규칙 7은 그 뒷면이다: 기억이 없는데 "앞으로 자동차로 할게요"라고 약속하면 다음
        // 요청에서 카드가 다시 물으며 약속이 거짓임이 드러난다(2026-09-16 실측) — 못 지킬 약속을
        // 만들지 말라고 못 박아 둔다.
        return """
        besir 일정 도우미. 사용자 말(또는 공유받은 텍스트·이미지)에서 일정을 파악해 도구로 등록한다.
        이미지면 표·텍스트를 읽어 여러 일정이면 각각 도구를 호출한다.
        지금: \(nowStr) (KST) / 현재 위치(참고용, 출발지 기본값 아님): \(loc)\(favoritesLine)

        # 절대 규칙
        1. 실제 데이터가 필요한 질문(뭐가 등록됐나·몇 건·삭제/수정 대상)은 반드시 list_schedules를 먼저 호출하고 그 결과만 말한다. 제목·시각·건수·가게이름을 지어내면 안 된다.
        2. 이동수단·도착여유·알림·반복 기간은 **도구 인자에 없다** — 앱이 사용자에게 직접 묻는다. 너는 이 값들을 묻지도, 지어내지도 말고 나머지 인자만 채워 호출해라. 호출만 하면 그 뒤는 앱이 처리한다.
        3. 출발지: **사용자가 말했으면 반드시 origin_query에 넣어라**(말로만 "회사에서"라고 쓰고 인자를 비우면 엉뚱한 곳에서 출발하는 일정이 만들어진다). 말하지 않았으면 **비워둬라** — 비워야 앱이 카드로 물어본다. **지어내서 채우면 안 된다**: 추측해 넣은 출발지로 조용히 등록되거나, 못 찾아 등록이 실패하거나 — 둘 다 사용자가 직접 고를 기회를 없앤다. 네가 임의로 정하지 마라.
           목적지·제목도 같다: **사용자가 말한 것만 채운다** — 말하지 않았으면 비워둬라(앱이 카드로 물어본다). 지어낸 목적지는 사용자가 고칠 기회 없이 그대로 등록된다.
           단 **check_travel_time은 예외**: 등록이 아니라 조회라 되물을 필요가 없다. origin_query를 비운 채 바로 호출한다.
        4. 상대 표현("내일", "다음 주 금요일")은 위 현재 시각 기준으로 정확한 ISO 시각으로 바꾼다.
           "이번 주"는 **오늘이 들어가는 주**다(오늘 날짜를 반드시 포함하게 from_date/to_date를 잡아라).
           조회 결과가 비었는데 도구가 "전체로는 N건 있다"고 알려주면, 날짜를 잘못 잡은 것이니
           범위를 비우고 다시 조회해라 — "일정이 없다"고 잘라 말하면 안 된다.
        5. 답변은 짧고 친근하게. 일정·식사와 무관한 요청은 정중히 거절.
        6. **제목은 되묻지 마라** — 없으면 목적지나 활동 이름으로 알아서 짓는다("강남역 약속"). 되물을 가치가 있는 건 목적지·출발지·시각이다.
        7. "앞으로 ~", "주로 ~", "다음부터 ~", "~기억해줘"처럼 기본값 저장을 부탁하면 **미래 약속을 하지 마라** — 이 앱에는 그런 기억이 없다. 그 값은 이번 요청에만 적용되고, 다음에는 besir이 매번 다시 물어본다(사용자가 모르는 사이 틀린 값이 적용되는 일을 막으려는 것이다). 그렇게 솔직하게 알려 주고 이번 등록을 마저 진행해라.
        8. 사용자가 일정을 만들겠다고 하면 **정보가 부족해도 말로 되묻지 말고 create_schedule을 호출해라** — 빈 인자로("일정 생성" 한마디도 마찬가지). 묻는 일은 앱의 카드가 한다: 필요한 값을 한 번에 전부 묻고 칩으로만 고르게 해서 값이 조용히 정해지는 일이 없다. 네가 대신 값을 지어 채우는 것보다 비운 채로 보내는 게 언제나 낫다.

        # 어떤 도구를 쓰나
        - 이동만 필요: create_schedule. "3시까지 가야 해"→arrival_iso / "6시에 출발할래"→departure_iso (둘 중 하나만).
        - 그 장소에 머무는 시간이 있으면: create_activity. **오가는 이동도 필요하면 travel_from_query/return_to_query를 같이 넣어 한 번에** 만든다(그래야 활동과 이동이 묶여 같이 움직이고 같이 지워진다. create_schedule로 따로 만들면 안 묶임).
          예) "8~10시 강남에서 친구 만나고 집에 올래" → create_activity(place_query:강남역, start/end, travel_from_query:집, return_to_query:집) 한 번.
        - 반복: create_recurring_schedule. "평일"=월~금. 격주=every_n_weeks:2, "매월 첫째 주 월"=weekdays:[mon]+nth_week_of_month:1(마지막=-1, 매월 아니면 0), "공휴일 빼고"=skip_holidays:true.
          "9시부터 18시까지"면 9시=arrival_time, 18시=return_time(왕복 원하는지 확인). 반복 기간은 앱이 묻는다. 점심은 보통 같은 건물이라 lunch_place_query를 **비워둔다** — "밖에서" 같이 명시할 때만 채운다.
        - 이미 있는 일정 고치기: update_schedule (지우고 새로 만들지 말 것).
        - 반복 그룹의 수단/버퍼/알림 수정: update_recurring_schedule. 목록(list_schedules)의 [n] 그룹 번호를 series_number로 주고, 이번 대화에서 만든 그룹이면 번호 없이. **create_recurring_schedule을 다시 부르면 중복 등록된다.** 요일·시각·목적지 변경은 전체 삭제 후 재등록하라고 안내.
        - 먹을 곳: recommend_meal. 메뉴를 좁혀 말하면(일식→초밥) keyword에 그대로 넣어 재검색. 시각만 말하면 at_iso.
          추천 중 하나로 일정을 잡아 달라 하면 create_activity를 부르되 **log_as_meal:true**를 꼭 넣는다(안 넣으면 '최근 먹은 것' 목록에 안 남는다).
        - 등록 없이 소요시간만: check_travel_time.

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
        // 이동수단·도착 여유·알림·반복 기간의 인자 선언은 여기 없다(있었다가 지웠다).
        // 이 모델은 선언된 선택 인자를 비워두지 못하고 전부 채운다 — 이름을 "이번만 다르게"로
        // 바꿔도, 설명에 "비워둬라"·"0을 비움 대신 쓰지 마라"를 세 겹으로 적어도 소용없었다
        // (두 번 실패했다). 앱이 "비었다"를 관측하려면 모델이 그 값을 보낼 수 없어야 한다.
        // 지금은 앱이 카드로 직접 묻는다(askFields). 부수 효과로 요청당 고정 토큰비도 내려갔다.
        let notifyFlag: [String: Any] = ["type": "BOOLEAN", "description": "false=알림 끔. 기본 true."]
        let calFlag: [String: Any] = ["type": "BOOLEAN", "description": "false=구글 캘린더에 안 올림. 기본 true."]
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
                    "notify_enabled": notifyFlag,
                    "add_to_calendar": calFlag,
                    "on_conflict": ["type": "STRING", "enum": ["ignore", "late_arrival"],
                                    "description": "**앱이 겹친다고 알려준 뒤 사용자가 답한 재호출에만** 넣는다 — 첫 호출에 보내면 무시된다. ignore=그대로 등록, late_arrival=겹침이 끝난 뒤 출발."]
                ],
                // required를 비운다 — 제목·목적지를 모델이 비워둘 수 있어야 카드가 그 줄을 물을 수
                // 있다(필수로 남아 있으면 비울 수 없어 줄이 영영 안 뜬다). 선언 자체는 유지:
                // 사용자가 말하면 모델이 넘기는 정상 경로다.
                "required": []
            ]
        ], [
            "name": "create_activity",
            "description": "그 장소에 머무는 일회성 활동 1건. travel_from_query/return_to_query를 같이 주면 오가는 이동까지 한 번에 만들어 활동과 묶는다(따로 만들면 안 묶임). **왕복이면 둘 다 빠뜨리지 마라** — 하나라도 비면 그쪽 이동이 아예 안 만들어진다.",
            "parameters": [
                "type": "OBJECT",
                "properties": [
                    "title": ["type": "STRING", "description": "제목"],
                    "place_query": ["type": "STRING", "description": "활동 장소. 이동도 만들려면 필수."],
                    "start_iso": ["type": "STRING", "description": "시작 ISO"],
                    "end_iso": ["type": "STRING", "description": "종료 ISO"],
                    "travel_from_query": ["type": "STRING", "description": "가는 이동의 출발지. **왕복이면 return_to_query와 둘 다 채운다** — 이게 비면 가는 이동이 아예 안 만들어진다. 사용자가 이미 그 장소에 있어 오는 길만 필요할 때만 비운다."],
                    "return_to_query": ["type": "STRING", "description": "오는 이동의 도착지(선택). travel_from_query를 채웠고 왕복이면 이것도 같이 채운다(보통 travel_from_query와 같은 값)."],
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
                    "every_n_weeks": ["type": "INTEGER", "description": "2=격주"],
                    "nth_week_of_month": ["type": "INTEGER", "description": "**\"매월\"이라고 말했을 때만**: 그 달 n번째 요일(1~4, -1=마지막). 매월이 아니면 0"],
                    "confirm_recurrence": ["type": "BOOLEAN", "description": "주기를 되묻는 응답을 받고 사용자가 확인했을 때 true"],
                    "skip_holidays": ["type": "BOOLEAN", "description": "true=한국 공휴일 제외"]
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


    // MARK: - 인자 읽기
    //
    // 저장된 선호로 부재를 메우던 자리다. 그 대체가 b303f41의 사고였다 — 조용히 들어간 값은
    // 아무도 보지 못한다. 지금은 부재를 부재로 두고, 카드가 사용자에게 직접 묻는다.

    private static func transportMode(_ raw: Any?) -> TransportMode? {
        (raw as? String).flatMap(TransportMode.init(rawValue:))
    }

    /// 카드가 채웠어야 할 인자가 아직 비어 있으면 그 이름들을 돌려준다.
    /// 판정은 카드를 그릴 때와 **같은 askFields**로 한다 — 두 벌로 적으면 한쪽만 고쳐져
    /// "카드는 물었는데 실행부는 딴 값을 쓰는" 어긋남이 생긴다(계약 5).
    ///
    /// 도달할 일이 없는 경로다(카드를 통과하지 않은 호출이 여기 올 수 없다). 그래도 조용한
    /// 기본값 대신 멈추는 쪽으로 두는 이유: 도달했다면 askFields에 구멍이 뚫렸다는 뜻이고,
    /// 그 구멍은 0분짜리 일정으로 조용히 새어 나가는 대신 여기서 보여야 한다.
    private func missingAskedArguments(tool: String, input: [String: Any]) -> String? {
        // note가 붙은 줄(값은 차 있는데 앱이 못 푸는 장소)은 여기서 세지 않는다 — "비어 있다"가
        // 아니라서 문구가 거짓이 되고, 그 경우의 올바른 안내는 placeNotFound가 즐겨찾기 목록과
        // 함께 이미 갖고 있다. 카드가 먼저 묻고(askFields), 카드를 지나지 않고 온 호출은 해석부가
        // 그대로 막는다 — 둘 다 산다(카드 먼저, 가드 다음).
        let missing = askFields(tool: tool, args: input).filter { $0.note == nil }.map(\.label)
        return missing.isEmpty ? nil : missing.joined(separator: ", ")
    }

    // MARK: - 툴 실행

    private func executeTool(name: String, input: [String: Any]) async -> String {
        // 툴이 실행됐다 = 이 요청이 끝났다. 여기서 말해 둔 값(statedArgs)을 지운다 — 모든 실행
        // 경로가 지나가는 단일 지점이기 때문이다. 겹침처럼 되돌아가는 응답을 받은 뒤의 재호출은
        // 값이 이미 채워진 채 히스토리에 남아 있어 모델이 그대로 되울러 오고, 안 되울러 오면 카드가
        // 다시 묻는다 — 말해 둔 값이 조용히 이어 붙는 것보다 한 번 더 묻는 쪽이 안전하다.
        statedArgs = [:]
        switch name {
        case "create_schedule": return await executeCreateSchedule(input)
        case "create_activity": return await executeCreateActivity(input)
        case "create_recurring_schedule": return await executeCreateRecurringSchedule(input)
        case "update_recurring_schedule": return await executeUpdateRecurringSchedule(input)
        case "list_schedules": return executeListSchedules(input)
        case "check_travel_time": return await executeCheckTravelTime(input)
        case "recommend_meal": return await executeRecommendMeal(input)
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
        if let missing = missingAskedArguments(tool: "create_schedule", input: input) {
            return "아직 만들지 않았어요 — \(missing)이(가) 비어 있어요. 이 값들은 앱이 사용자에게 직접 묻는 것이니 네가 채우지 말고, 다시 말해달라고 안내해."
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

        // 위 가드를 지났으므로 이 값들은 카드(또는 사용자 발화)가 이미 채워 놓은 것이다.
        let mode = Self.transportMode(input["mode_this_time"]) ?? .transit
        // 출발 기준 구간은 버퍼 개념이 없다(도착 여유를 둘 대상이 없음).
        let buffer = anchor == .departure ? 0 : Store.clampBuffer(intValue(input["buffer_minutes"]) ?? 0)
        let notify = Store.clampNotifyLead(intValue(input["notify_lead_minutes"]) ?? 0)

        guard let origin = await resolveOrigin(input["origin_query"] as? String) else {
            // 카드의 "현재 위치" 칩은 내부 토큰을 그대로 싣는다. 위치 권한 거부로 실패했을 때 이 토큰이
            // 메시지에 섞여 나가면 사용자에게 그대로 노출되고, "더 정확한 장소명" 안내도 지금 여기엔
            // 맞지 않으니(여기보다 정확한 장소명은 없다) 별도 안내로 갈린다.
            let originQuery = (input["origin_query"] as? String)?.trimmingCharacters(in: .whitespaces)
            if originQuery == Self.currentLocationToken {
                return "현재 위치를 확인하지 못했어요. 위치 권한을 켜주시거나 어디서 출발하는지 알려주세요."
            }
            return placeNotFound(originQuery ?? "출발지")
        }
        guard let dest = await resolveDestination(destQuery, creation: true) else { return placeNotFound(destQuery) }

        // 출발지와 목적지가 사실상 같으면 만들지 않는다. 모델이 origin_query를 빠뜨려
        // 기본 출발지(즐겨찾기 '집')가 잡히면 "집 → 집"이 되어 이동시간 0짜리 일정이 조용히
        // 만들어진다(실제로 "회사에서 출발"이라고 말했는데 그렇게 등록된 적이 있다).
        if Self.isSamePlace(origin, dest) {
            return "출발지와 목적지가 '\(origin.name)'으로 같아요. 어디서 출발하는지 origin_query에 넣어 다시 호출해."
        }

        // 충돌을 만들기 전에 판단하려면 이동시간이 먼저 필요하다. 여기서 구한 값을 addEvent에
        // 그대로 넘겨(travelSecondsHint) 외부 길찾기 API를 두 번 호출하지 않는다.
        let seconds = await store.travelSeconds(from: origin, to: dest, mode: mode)
        // on_conflict는 앱이 겹침 안내를 내보낸 뒤의 재호출에만 답으로 인정한다(confirm_recurrence·
        // confirm_zero와 같은 규칙). 묻지도 않은 첫 호출의 값은 없는 것으로 읽는다 — 이 모델은
        // enum이 붙은 선택 인자를 비워두지 못하고 멤버를 골라 실어 보내므로, 그게 통과하면 겹침
        // 검사가 통째로 건너뛰어진다.
        let asked = ConflictAsk(destinationQuery: destQuery, anchor: anchorDate)
        let sent = (input["on_conflict"] as? String)?.lowercased()
        let onConflict: String? = (sent != nil && conflictConfirmAsk == asked) ? sent : nil

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
                    // 여기가 유일한 "물은" 자리다 — 이 조합 그대로 돌아오는 재호출의 on_conflict만
                    // 답으로 친다(recurrenceConfirmAsk를 기록하는 자리와 같은 구조).
                    conflictConfirmAsk = asked
                    return conflictPrompt(found, plannedDeparture: plannedDeparture,
                                          plannedArrival: plannedArrival,
                                          lateDeparture: last, travelSeconds: seconds)
                }
            }
        }

        // 방금 만든 일정은 만든 쪽에서 직접 받는다(addEvent의 반환값). 제목·목적지로 되찾으면
        // 같은 이름의 더 늦은 회차를 집어 요약이 남의 시각을 알렸다(2026-09-16 결함 J — addEvent가
        // 도착일순 정렬하므로 `.last {매치}`는 '매치 중 도착이 가장 늦은 것'이다). 요약이 방금
        // 등록한 값을 말해야 사용자가 그 자리에서 틀린 값을 본다(체크리스트 A9의 취지).
        let created = await store.addEvent(title: title,
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
        // 등록에 성공했으면 겹침 확인은 소진됐다 — 남겨두면 나중에 우연히 같은 목적지·시각으로 온
        // 첫 호출이 묻지도 않은 on_conflict로 통과한다(형제 확인들이 각자의 소비 지점을 둔 이유).
        conflictConfirmAsk = nil

        // 출발지를 함께 남긴다 — 되묻지 않고 자동으로 정해진 경우 엉뚱한 곳일 수 있어
        // 사용자가 바로 알아챌 수 있어야 한다(등록 시점 현재 위치가 굳는 게 이 앱의 약점).
        // 적용된 여유도 같이 적는다(b303f41 원칙의 남은 절반) — 요약에 없으면 잘못된 여유가
        // 등록돼도 사용자가 그 자리에서 보지 못한다.
        var summary = "등록 완료 — 제목 '\(title)', '\(origin.name)' → '\(dest.name)', 이동수단 \(mode.title), 도착 여유 \(buffer)분."
        // travelSeconds가 없으면 출발·도착이 같은 시각으로 남는다 — 성공한 것처럼 보고하면 안 된다.
        if let dep = created.departureDate, created.travelSeconds != nil {
            summary += " 출발 \(Self.when(dep)) → 도착 \(Self.when(created.arrivalDate)), 출발 \(notify)분 전 알림 예약됨."
        } else {
            summary += " ⚠️ 다만 이동시간을 계산하지 못해 출발·도착 시각이 비어 있어요 — 사용자에게 알려주고 장소가 맞는지 확인해."
        }
        if let lateBy, lateBy > 0 {
            summary += " 겹치는 일정이 끝난 뒤 출발하도록 잡아서 원래 계획보다 \(lateBy)분 늦게 도착해요 — 상대방에게 알려야 할 수도 있다고 안내해."
        }
        summary += calendarPendingNote(eventIDs: [created.id])
        return summary
    }

    /// 방금 만든 항목이 아직 캘린더에 안 올라갔으면 붙이는 한 줄. 캘린더 업로드가 등록의 임계
    /// 경로에서 빠지면서(2026-09-16 결함 N) "등록 완료"와 "캘린더에 보인다" 사이에 시차가 생겼는데,
    /// 요약이 그걸 말하지 않으면 사용자는 이미 올라간 줄 알고 캘린더 앱을 열었다가 없는 걸 본다.
    ///
    /// 판정의 단일 출처는 **레코드의 pending 표시**다 — `add_to_calendar`나 `googleConnected`를
    /// 여기서 다시 따지면 Store의 큐 조건(연결됨·동기화 희망·아직 안 올라감)과 두 벌이 되어,
    /// 올라갈 일이 없는데 기다리라고 말하게 된다. 연결이 없으면 pending 자체가 안 붙어 문구도 없다.
    private func calendarPendingNote(eventIDs: Set<UUID> = [], activityIDs: Set<UUID> = []) -> String {
        let waiting = store.events.contains { eventIDs.contains($0.id) && $0.calendarUpload == .pending }
            || store.activities.contains { activityIDs.contains($0.id) && $0.calendarUpload == .pending }
        return waiting ? " 구글 캘린더에는 방금 올리기 시작했어요 — 아직 올라가지 않았고 잠시 뒤 캘린더 앱에 보여요." : ""
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
        // 기간 상한. 상한 없는 end_iso(9999년도 parseDate를 통과한다)가 그대로 저장되면 달력 점
        // 계산이 activities 대입(didSet) 안에서 구간의 날을 하루씩 걷다가 메인 액터를 얼리고, 앱을
        // 다시 켜도 load가 같은 대입을 반복해 그 레코드를 지울 수조차 없게 된다(2026-09-16 코드
        // 검사 발견 1). 걷기 쪽 상한(Store.maxIntervalDays)만으로는 "점이 잘린 채 저장된 활동"이
        // 남으므로 생성 시점에도 **같은 값**으로 거른다 — 계약 5. 카드(인자 부재 확인)보다 먼저
        // 거는 이유는 기간은 이미 온 두 값만으로 알 수 있는데 카드를 먼저 띄우면 사용자가 나머지
        // 줄을 전부 채운 뒤에야 기간 문제를 알게 되기 때문이다. 값은 버리지 않고 사용자 확인을
        // 요청한다(conflictPrompt와 같은 결 — 내부 토큰·원시 인자는 찍지 않는다).
        guard end.timeIntervalSince(start) <= Double(Store.maxIntervalDays) * 86400 else {
            return "아직 만들지 않았어요 — 활동 기간이 너무 길어요. 한 번에 만들 수 있는 활동은 최대 \(Store.maxIntervalDays)일이에요. 정말 그렇게 긴 일정인지, 반복 일정으로 만들어야 하는 건 아닌지 사용자에게 확인해 주세요."
        }
        if let missing = missingAskedArguments(tool: "create_activity", input: input) {
            return "아직 만들지 않았어요 — \(missing)이(가) 비어 있어요. 이 값들은 앱이 사용자에게 직접 묻는 것이니 네가 채우지 말고, 다시 말해달라고 안내해."
        }

        var place: Place?
        if let q = (input["place_query"] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty {
            place = await resolveDestination(q, creation: true)
        }
        func resolve(_ key: String) async -> Place? {
            guard let q = (input[key] as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty else { return nil }
            // 카드의 "가는 편 없음" 칩 — 이 구간은 만들지 말라는 명시적 답이다(빈 값과 같은 뜻).
            if q == Self.noOutboundToken { return nil }
            // "현재 위치" 칩은 출발지 줄과 같은 토큰을 싣는데 resolveDestination은 그 토큰을 모른다 —
            // 넘기지 않으면 토큰 그대로 장소 검색에 들어가 실패 문구에 내부 토큰이 찍힌다(M6에서
            // 지운 노출과 같은 종류). 가는 편 출발지 줄이 못 푸는 값으로도 뜨게 되면서 이 칩에
            // 닿는 경로가 늘었다.
            if q == Self.currentLocationToken { return await resolveOrigin(q) }
            return await resolveDestination(q, creation: true)
        }
        let from = await resolve("travel_from_query")
        let to = await resolve("return_to_query")
        // 이동 질의가 **비어 있지 않은데 해석에 실패한 것**을 따로 모은다 — "안 만들기로 한 것"
        // (가는 편 없음 칩·빈 값)과 "만들려 했는데 실패한 것"은 다른 사건인데 결과가 같아 통째로
        // 묻혔다(2026-09-16 실측: 카드에서 수단까지 골랐는데 다리가 0개였고 요약은 성공 문구만
        // 남겼다). 토큰·빈 값은 여기서 실패로 세지 않는다.
        func unresolvedQueryText(_ key: String, _ label: String) -> String? {
            guard let q = (input[key] as? String)?.trimmingCharacters(in: .whitespaces),
                  !q.isEmpty, q != Self.noOutboundToken else { return nil }
            return "\(label) '\(q)'"
        }
        var unresolved: [String] = []
        if from == nil, let t = unresolvedQueryText("travel_from_query", "가는 편 출발지") { unresolved.append(t) }
        if to == nil, let t = unresolvedQueryText("return_to_query", "오는 편 도착지") { unresolved.append(t) }
        // 장소 질의도 같은 클래스다 — 말해 둔 장소가 해석 못 해 위치 없는 활동으로 조용히 등록되면
        // 사용자는 자기가 고른 값이 적용된 줄 안다. (이동이 필요한데 장소가 없는 경우는 위의
        // 안내 가드가 먼저 막는다.)
        if place == nil, let t = unresolvedQueryText("place_query", "활동 장소") { unresolved.append(t) }
        // 가는 편·오는 편 수단을 따로 받는다(왕복이 아니면 카드가 한 줄로만 묻고 그 값을 쓴다).
        let stated = Self.transportMode(input["mode_this_time"])
        let outboundMode = Self.transportMode(input["travel_mode_this_time"]) ?? stated ?? .transit
        let returnMode = Self.transportMode(input["return_mode_this_time"]) ?? stated ?? .transit

        if (from != nil || to != nil) && place == nil {
            return "이동까지 만들려면 활동 장소(place_query)가 필요해요. 어디서 하는 일정인지 물어봐 주세요."
        }
        let result = await store.addActivityWithTravel(
            title: title, location: place, startDate: start, endDate: end,
            travelFrom: from, returnTo: to, outboundMode: outboundMode, returnMode: returnMode,
            // 이동 구간에만 쓰인다 — 이동이 없으면 카드가 묻지 않았고 여기서도 쓰이지 않는다.
            bufferMinutes: Store.clampBuffer(intValue(input["buffer_minutes"]) ?? 0),
            notifyLeadMinutes: Store.clampNotifyLead(intValue(input["notify_lead_minutes"]) ?? 0),
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
            // 만들어지지 않은 구간의 수단은 요약에도 내놓지 않는다 — "가는 편 없음"으로 답한 편도에서
            // 가는 편 수단이 언급되면 생기지도 않은 구간이 있는 것처럼 읽힌다.
            let modeText: String
            let legKind: String
            if from == nil { modeText = returnMode.title; legKind = "돌아오는 이동" }
            else if to == nil { modeText = outboundMode.title; legKind = "가는 이동" }
            else {
                modeText = outboundMode == returnMode ? outboundMode.title
                    : "가는 편 \(outboundMode.title) · 오는 편 \(returnMode.title)"
                legKind = "오가는 이동"
            }
            summary += " \(legKind) \(madeLegs)건도 활동에 묶어서 만들었어요(\(modeText))."
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
        // 활동 자체는 유효하므로 등록은 하되 성공인 척하지 않는다 — 이동시간 계산 실패 안내
        // (executeCreateSchedule의 ⚠️)와 같은 결로, 못 만든 부분을 문구에 드러낸다.
        if !unresolved.isEmpty {
            summary += " ⚠️ 다만 \(unresolved.joined(separator: ", ")) 위치를 찾지 못해 그 부분은 만들지 못했어요 — 사용자에게 알려주고 장소를 다시 정해달라고 해."
        }
        // 활동과 묶인 이동 구간도 같은 큐에 실린다 — 둘 중 하나라도 대기 중이면 같은 말이 맞다.
        summary += calendarPendingNote(
            eventIDs: Set(store.events.filter { $0.linkedActivityId == result.activityId }.map(\.id)),
            activityIDs: [result.activityId])
        return summary
    }

    // 시각 표기의 단일 출처는 BesirTime이다 — 정의를 그쪽으로 옮기고도 카드 밖의 when 호출부와
    // 카드 경로의 parseDatetime·isoFormatter 호출부를 한 줄도 고치지 않으려 같은 시그니처로
    // 위탁만 남긴다. 형식 문자열의 사본이 이 파일에 생기면 카드의 accepts와 실행부 직렬화가
    // 어긋난다.
    private static func when(_ d: Date) -> String { BesirTime.when(d) }
    private static func parseDatetime(_ raw: String) -> (prefix: String, date: Date)? { BesirTime.parseDatetime(raw) }
    private static var isoFormatter: DateFormatter { BesirTime.isoFormatter }

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
        if let missing = missingAskedArguments(tool: "create_recurring_schedule", input: input) {
            return "아직 만들지 않았어요 — \(missing)이(가) 비어 있어요. 이 값들은 앱이 사용자에게 직접 묻는 것이니 네가 채우지 말고, 다시 말해달라고 안내해."
        }
        if let ask = recurringArgumentIssue(input, weekdayCount: weekdays.count) { return ask }
        // 매주(기본) / 격주 / 매월 n번째 요일 / 공휴일 제외를 하나의 규칙으로 묶는다.
        let rule = RecurrenceRule(weekdays: weekdays,
                                  everyNWeeks: everyNWeeksArgument(input),
                                  nthWeekOfMonth: nthWeekArgument(input),
                                  skipHolidays: (input["skip_holidays"] as? Bool) ?? false)
        let mode = Self.transportMode(input["mode_this_time"]) ?? .transit
        let buffer = Store.clampBuffer(intValue(input["buffer_minutes"]) ?? 0)
        let notify = Store.clampNotifyLead(intValue(input["notify_lead_minutes"]) ?? 0)
        let weeks = weeksArgument(input) ?? 8
        let startDate = (input["start_date"] as? String).flatMap(parseDay) ?? Date()
        let originQuery = input["origin_query"] as? String

        guard let origin = await resolveOrigin(originQuery) else {
            return "출발지를 확인하지 못했어요. 어디서 출발하는지 알려주시거나 즐겨찾기에 장소를 추가해 주세요."
        }
        guard let dest = await resolveDestination(destQuery, creation: true) else { return placeNotFound(destQuery) }

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
                lunchPlace = await resolveDestination(q, creation: true)
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
        // 반복은 방금 만든 그룹 전체가 한 큐에 실린다 — id를 따로 모으지 않고 그룹으로 본다.
        let pendingNote = calendarPendingNote(
            eventIDs: Set(store.events.filter { $0.recurrenceId == recurrenceId }.map(\.id)),
            activityIDs: Set(store.activities.filter { $0.recurrenceId == recurrenceId }.map(\.id)))
        return "등록 완료 — '\(title)' 총 \(totalCount)건 등록했어요: \(parts.joined(separator: ", ")). 출발지 '\(origin.name)' ↔ 목적지 '\(dest.name)', 이동수단 \(mode.title), 도착 여유 \(buffer)분, 출발 \(notify)분 전 알림.\(pendingNote) 전체를 지우려면 아무 일정이나 열어 '반복 일정 전체 삭제'를 눌러주세요."
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
    /// ② 기간(`weeks`)을 모델에게 되묻던 갈래는 없앴다 — 선언에서 뺐으므로 모델이 보낼 수
    ///    없고, 상한(26주)과 빈 값은 카드가 입력 단계에서 막는다(AskField.accepts). 남은 건
    ///    모델이 여전히 채울 수 있는 주기 인자(①)뿐이다.
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
        guard !asks.isEmpty else { return nil }
        return "아직 만들지 않았어요. 아래를 사용자에게 확인하고, 답을 들으면 같은 인자에 고쳐서 다시 호출해.\n" + asks.joined(separator: "\n")
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
        let subject = store.recurringSeries(recurrenceId).first.map { "'\($0.title)' " } ?? ""
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

        // 현재 값은 회차 전체에서 읽는다(recurringSeries — updateRecurringSeries와 같은 멤버십·정렬).
        // 첫 회차만 보면 안 된다: 한 회차를 드래그해 여유를 바꾼 시리즈(adjustTravelLeg(wholeSeries:false)
        // → adjustBuffer)는 회차마다 값이 제각각이라, 첫 회차가 0이라고 "이미 0"이라 말하면 거짓이
        // 되고 — 사용자는 사실이 아닌 전제에 confirm_zero를 누르며, Store가 나머지 회차까지 0으로
        // 덮어쓴다. 시리즈가 이미 사라졌으면 되물을 근거가 없으니 통과시키고, 뒤의 count > 0 가드가 안내한다.
        let series = store.recurringSeries(recurrenceId)
        guard !series.isEmpty else { return nil }

        // 복원 경로가 있는 갈래에서는 그것을 먼저 적는다. 이 가드가 실제로 잡는 건 "수단만 바꿔줘"에 딸려온
        // 0이고 그때 옳은 행동은 복원 쪽인데, 파괴 경로가 앞에 있으면 모델이 먼저 읽은 쪽을 집는다
        // (`nth_week_of_month` 안내문의 값 목록에서 -1을 집어 35건을 7건으로 만든 것과 같은 자리다).
        //
        // 현재 값이 이미 0이면 복원 탈출구 자체를 주지 않는다 — "그대로 둬라"와 "0으로 바꿔라"가
        // 같은 와이어 값이라, 알려준 0이 그대로 돌아와 가드를 다시 발동시키고 안내만 반복하다
        // 툴 루프 상한에서 턴이 끝난다(이동수단 변경은 끝내 일어나지 않는다).
        //
        // 회차마다 값이 제각각인 시리즈는 되돌릴 "현재 값" 하나가 없다 — 첫 회차 값을 내미는 건
        // 방금 막은 거짓과 같은 모양이라, 편차를 사실대로 알리고 0 이외의 값이면 되묻지 않는다는
        // 탈출구만 준다.
        var asks: [String] = []
        if zeroBuffer {
            let values = series.map(\.bufferMinutes)
            if values.allSatisfy({ $0 == 0 }) {
                asks.append("· 도착 여유는 모든 회차가 이미 0분이라 이 값은 바뀌는 게 없어요. buffer_minutes:0 그대로 confirm_zero:true를 붙여 다시 호출해.")
            } else if let lo = values.min(), let hi = values.max(), lo == hi {
                asks.append("· 도착 여유를 0분으로 바꾸게 돼 있어요. 여유는 건드리는 게 아니었으면 buffer_minutes:\(lo)으로 다시 호출하고, 정말 여유 없이가 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
            } else if let lo = values.min(), let hi = values.max() {
                asks.append("· 도착 여유를 0분으로 바꾸게 돼 있어요. 지금은 회차마다 \(lo)~\(hi)분으로 제각각이라, 확인하면 전부 0분으로 통일돼요. 0 말고 다른 값으로 바꾸고 싶으면 그 숫자를 buffer_minutes에 넣어 다시 호출하고, 정말 전부 여유 없이가 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
            }
        }
        if zeroNotify {
            let values = series.map(\.notifyLeadMinutes)
            if values.allSatisfy({ $0 == 0 }) {
                asks.append("· 알림은 모든 회차가 이미 출발 0분 전이라 이 값은 바뀌는 게 없어요. notify_lead_minutes:0 그대로 confirm_zero:true를 붙여 다시 호출해.")
            } else if let lo = values.min(), let hi = values.max(), lo == hi {
                asks.append("· 알림을 출발 0분 전으로 바꾸게 돼 있어요. 알림은 건드리는 게 아니었으면 notify_lead_minutes:\(lo)로 다시 호출하고, 정말 그게 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
            } else if let lo = values.min(), let hi = values.max() {
                asks.append("· 알림을 출발 0분 전으로 바꾸게 돼 있어요. 지금은 회차마다 \(lo)~\(hi)분으로 제각각이라, 확인하면 전부 0분으로 통일돼요. 0 말고 다른 값으로 바꾸고 싶으면 그 숫자를 notify_lead_minutes에 넣어 다시 호출하고, 정말 전부 그게 맞을 때만 confirm_zero:true를 붙여 다시 호출해.")
            }
        }
        // 되물은 조합을 여기서만 기록한다 — 이 조합 그대로 다시 오는 호출의 confirm_zero만 진짜 확인이다.
        zeroUpdateConfirmAsk = asked
        return "아직 바꾸지 않았어요. 아래를 **먼저 사용자에게 확인**하고 답을 들은 뒤에 다시 호출해.\n" + asks.joined(separator: "\n")
    }

    /// 사용자에 대한 사실을 장기 기억에 저장한다(대화 초기화와 무관하게 유지, 다음 시스템 프롬프트부터 반영).
    /// "…여유 10분", "알림 30분 전"처럼 특정 낱말 근처의 분 단위 숫자를 읽어낸다.
    /// 이제 저장이 아니라 **이번 요청의 인자**를 채운다(statedArguments) — 값이 잡히면 카드에
    /// 그 줄이 생기지 않는다. 0보다 큰 값만 돌려주므로 진짜 0은 말로 전달되지 않고, 그 격차는
    /// 카드의 `0분` 칩이 닫는다.
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
        guard let origin = await resolveOrigin(input["origin_query"] as? String, orDefault: true) else {
            return "출발지를 확인하지 못했어요. 어디서 출발하는지 알려주세요."
        }
        guard let dest = await resolveDestination(destQuery) else { return placeNotFound(destQuery) }
        let estimates = await store.travelEstimates(from: origin, to: dest)
        let depart = (input["depart_iso"] as? String).flatMap(parseDate) ?? Date()
        let lines = TransportMode.allCases.compactMap { m -> String? in
            guard let seconds = estimates[m]?.duration else { return nil }
            let minutes = Int((seconds / 60).rounded())
            let duration = minutes < 60 ? "\(minutes)분" : "\(minutes / 60)시간 \(minutes % 60)분"
            let arrive = Self.when(depart.addingTimeInterval(seconds))
            return "- \(m.title) \(duration) (도착 \(arrive))"
        }
        guard !lines.isEmpty else {
            return "'\(origin.name)' → '\(dest.name)' 이동시간을 계산하지 못했어요(경로를 못 찾았거나 조회 실패)."
        }
        return "'\(origin.name)' → '\(dest.name)', \(Self.when(depart)) 출발 기준:\n"
            + lines.joined(separator: "\n")
            + "\n(등록하지는 않았어요)"
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
        if Self.genericPlaceWords.contains(query) {
            let have = labels.isEmpty ? "아직 없어요" : labels.joined(separator: ", ")
            return "'\(query)'이(가) 즐겨찾기에 없어요(등록된 즐겨찾기: \(have)). "
                + "besir 별 모양 버튼에서 '\(query)'을(를) 즐겨찾기에 추가하면 다음부터 이름만으로 쓸 수 있다고 안내해. "
                + "지금 바로 등록하려면 실제 장소명이나 주소를 받아서 그걸 넣어."
        }
        let hint = labels.isEmpty ? "" : " (즐겨찾기: \(labels.joined(separator: ", ")))"
        return "'\(query)' 위치를 찾지 못했어요. 더 정확한 장소명을 알려주세요.\(hint)"
    }

    /// 출발지 해석: ① 카드에서 고른 "현재 위치" ② 즐겨찾기 이름과 일치 ③ 검색.
    ///
    /// **등록 경로에서는 여기까지 와서 빈 값일 수 없다** — 카드가 먼저 묻기 때문이다. 예전엔
    /// origin_query가 비면 조용히 즐겨찾기 "집"이나 등록 시점 현재 위치로 떨어졌고, 그래서
    /// "회사에서 출발"이라고 말했는데 집→집인 0분짜리 일정이 만들어진 적이 있다. 그 폴백은
    /// `orDefault`로 가뒀다 — 지금 켜는 곳은 check_travel_time 하나뿐이고, 그건 등록이 아니라
    /// 조회라 되묻을 이유가 없다(시스템 프롬프트 규칙 3의 예외와 같은 자리).
    private func resolveOrigin(_ query: String? = nil, orDefault: Bool = false) async -> Place? {
        let trimmed = query?.trimmingCharacters(in: .whitespaces)
        if trimmed == Self.currentLocationToken { return await currentPlace() }
        if let q = trimmed, !q.isEmpty {
            if let fav = store.favorites.first(where: { $0.label.caseInsensitiveCompare(q) == .orderedSame }) {
                return fav.place
            }
            // 카드에서 후보를 탭해 확정한 장소는 **그때 받은 좌표** 그대로 쓴다. 이름으로 다시
            // 검색하면 모호한 이름("스타벅스")이 다른 지점으로 잡혀, 사용자가 고른 곳과 등록된
            // 곳이 달라진다 — 화면에는 같은 이름이 찍혀 있어 알아챌 방법도 없다.
            // 즐겨찾기보다 **뒤**에 본다: 즐겨찾기는 사용자가 따로 등록해 오래 사는 설정이고,
            // 확정 장소는 이번 대화에서만 사는 값이다. 이름이 겹치면 오래 사는 쪽이 이겨야
            // "집이라고 했는데 어제 고른 카페로 잡히는" 일이 안 생긴다.
            if let confirmed = confirmedPlaces[q] { return confirmed }
            // 출발지의 일반명사도 목적지와 같은 맹점이다 — "회사에서 출발"에 검색 첫 결과가 조용히
            // 붙는다. orDefault가 켜진 조회 경로(check_travel_time)만 지금대로 검색에 둔다.
            if !orDefault, unresolvedGenericPlace(q) { return nil }
            // 검색이 빈손이면 실패다. 여기서 기본 출발지로 떨어지면 사용자가 말한 곳과 다른
            // 데서 출발하는 일정이 "성공"으로 등록된다 — 못 찾았다고 말하는 쪽이 낫다.
            return await store.placeSearch.search(q, near: location.currentLocation).first
        }
        guard orDefault else { return nil }
        if let home = store.favorites.first(where: { $0.label == "집" }) {
            return home.place
        }
        return await currentPlace()
    }

    /// 카드에서 고르는 "현재 위치". 권한이 아직이면 잠깐 기다렸다가, 끝내 못 받으면 nil이다.
    private static let currentLocationToken = "__current_location__"
    /// 카드에서 고르는 "가는 편 없음" — 빈 값(진짜 편도)을 실어 나르는 내부 토큰. 위 토큰과 같은
    /// 방식이다. currentLocationToken과 달리 이쪽은 어느 실행부에서도 장소로 풀리지 않는다.
    private static let noOutboundToken = "__no_outbound_leg__"
    private func currentPlace() async -> Place? {
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


    /// 일반명사 장소 낱말 — 즐겨찾기에 등록돼 있을 때만 장소가 되는 이름들. 아래의 creation 게이트와
    /// placeNotFound의 안내가 같은 목록을 봐야 한다(두 벌이 되면 한쪽만 고쳐진다).
    /// **스냅숏 한계**: 여기 없는 일반명사(예: "학원", "직장")는 여전히 검색으로 흘러가 조용히
    /// 해석될 수 있다 — 목록은 낱말 추가로만 자라며 완전하다는 보장이 없다.
    private static let genericPlaceWords: Set<String> = ["집", "회사", "학교", "사무실", "우리집"]

    /// 생성 경로에서 **앱 혼자 풀 수 없는** 장소 질의인지 — 일반명사인데 같은 이름의 즐겨찾기가 없다.
    /// 카드(askFields)와 해석부(resolveDestination·resolveOrigin)가 같은 술어를 봐야 한다: 두 벌로
    /// 적으면 카드가 묻지 않은 값을 해석부가 거절하거나 그 반대가 된다(계약 5). 네트워크를 쓰지
    /// 않으므로 카드를 그리는 동기 경로에서 그대로 부를 수 있다.
    private func unresolvedGenericPlace(_ raw: Any?) -> Bool {
        guard let q = (raw as? String)?.trimmingCharacters(in: .whitespaces), !q.isEmpty,
              Self.genericPlaceWords.contains(q) else { return false }
        // 검색 후보로 확정한 이름은 좌표가 있으니 더는 못 푸는 값이 아니다 — 카드가 다시 묻지 않고
        // 직접입력도 그 이름을 받아들인다(거절과 검색이 갈리는 지점).
        if confirmedPlaces[q] != nil { return false }
        return !store.favorites.contains { $0.label.caseInsensitiveCompare(q) == .orderedSame }
    }

    /// 못 푸는 장소 줄의 캡션. 조사 대신 "위치를"로 받는 이유는 낱말마다 받침이 달라서다("회사가"/
    /// "집이") — 목록이 자라도 문구가 깨지지 않는다. 즐겨찾기 안내를 함께 두되 **이 줄에서 고르면
    /// 이번 등록은 끝난다**: 등록을 마치려고 대화를 떠나 ⭐ 화면에 다녀와야 했던 것이 결함 O였다.
    private static func unknownPlaceNote(_ query: String) -> String {
        "besir가 '\(query)' 위치를 몰라요. 고르면 이번 일정에 쓰고, ⭐에 추가해 두면 다음부터 이름만으로 돼요."
    }

    /// 목적지 해석: 즐겨찾기 이름과 일치하면 그 좌표를 우선 사용, 아니면 검색(카카오 → MapKit 폴백).
    /// - Parameter creation: 등록 경로에서 쓴다. 일반명사(집·회사…)는 즐겨찾기에 없으면 장소가
    ///   아니라 **물어야 할 값**이다 — 검색으로 때우면 "회사"가 '농업회사법인 화조원' 같은 곳으로
    ///   조용히 잡히고 118건이 전부 그리로 등록된 뒤에야 사용자가 알았다(2026-09-16 실측).
    ///   부분 문자열 판정은 이 사례를 못 잡는다('화조원' 이름이 '회사'를 포함한다) — 낱말이 통째로
    ///   일반명사인지만 본다. 조회 경로(check_travel_time·recommend_meal)는 지금대로 검색에 둔다.
    private func resolveDestination(_ query: String, creation: Bool = false) async -> Place? {
        if let fav = store.favorites.first(where: { $0.label.caseInsensitiveCompare(query) == .orderedSame }) {
            return fav.place
        }
        // 확정 장소는 즐겨찾기 다음(resolveOrigin과 같은 순서·같은 이유 — 계약 5).
        if let confirmed = confirmedPlaces[query.trimmingCharacters(in: .whitespaces)] { return confirmed }
        if creation, unresolvedGenericPlace(query) { return nil }
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
