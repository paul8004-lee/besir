        // ===== sync 2차 재현 하네스(스크래치 — 저장소 드라이버에는 없다, Q16 수리 7dbcd9d 검증용) =====
        let q16Cands = [aiPl("스타벅스 강남역점B1", 37.4980, 127.0286),
                        aiPl("스타벅스 강남역점2호", 37.4975, 127.0278)]

        // Q16-1 확인 버튼 낱말 — 도구별, 모르는 도구·빈 값은 등록하기
        let q16Titles: [(String, String)] = [
            ("create_schedule", "등록하기"), ("create_activity", "등록하기"),
            ("create_recurring_schedule", "등록하기"), ("update_schedule", "고치기"),
            ("check_travel_time", "조회하기"), ("recommend_meal", "조회하기"),
            ("", "등록하기"), ("zzz_unknown", "등록하기")]
        let q16TitleBad = q16Titles.filter { AIAssistant.pendingConfirmTitle(for: $0.0) != $0.1 }.map { $0.0 }
        for (t, _) in q16Titles { print("Q16-OBS 버튼 \(t.isEmpty ? "(빈 값)" : t) → \(AIAssistant.pendingConfirmTitle(for: t))") }
        fresh().drvCheck("Q16-1: 확인 버튼 낱말이 도구별로 갈린다(등록하기·고치기·조회하기, 모르는 도구는 등록하기)",
                         q16TitleBad.isEmpty, "어긋남=\(q16TitleBad)")

        // 세 종류의 열린 카드를 하나씩 만든다
        func q16Open(_ tool: String) -> (AIAssistant, String) {
            let a = fresh()
            let msg: String
            switch tool {
            case "check_travel_time":
                msg = a.drvPark("check_travel_time", ["origin_query": "집", "destination_query": "강남역"],
                                [(key: "destination_query", query: "강남역", candidates: q16Cands)])
            case "update_schedule":
                msg = a.drvPark("update_schedule", ["title_query": "팀 회의", "new_place_query": "스타벅스"],
                                [(key: "new_place_query", query: "스타벅스", candidates: q16Cands)])
            case "recommend_meal":
                msg = a.drvPark("recommend_meal", ["keyword": "일식", "place_query": "강남역"],
                                [(key: "place_query", query: "강남역", candidates: q16Cands)])
            default:
                msg = a.drvPark("create_schedule",
                                ["title": "t", "origin_query": "집", "destination_query": "스타벅스 강남점"],
                                [(key: "destination_query", query: "스타벅스 강남점", candidates: q16Cands)])
            }
            return (a, msg)
        }

        // Q16-2 카드를 만든 도구 이름과 버튼
        var q16NameBad: [String] = []
        for tool in ["check_travel_time", "update_schedule", "recommend_meal", "create_schedule"] {
            let (a, _) = q16Open(tool)
            let n = a.drvLiveAsk().map { AIAssistant.toolName(of: $0) } ?? "nil"
            print("Q16-OBS 카드 도구 \(tool) → toolName=\(n) 버튼=\(AIAssistant.pendingConfirmTitle(for: n))")
            if n != tool { q16NameBad.append("\(tool)→\(n)") }
        }
        let q16Manual = AIAssistant.toolName(of: AIAssistant.PendingAsk(parts: [], stated: [], fields: []))
        print("Q16-OBS 호출 없는 카드 toolName=\"\(q16Manual)\" 버튼=\(AIAssistant.pendingConfirmTitle(for: q16Manual))")
        fresh().drvCheck("Q16-2: 카드가 자기를 만든 도구 이름을 돌려준다(호출 없는 카드는 빈 값)",
                         q16NameBad.isEmpty && q16Manual == "", "어긋남=\(q16NameBad) manual=\(q16Manual)")

        // Q16-3 버린 카드 말풍선 — 열린 카드의 도구 동사
        let q16CancelExpect: [(String, String)] = [
            ("check_travel_time", "물어본 값을 받지 못해서 조회하지 않았어요."),
            ("recommend_meal", "물어본 값을 받지 못해서 조회하지 않았어요."),
            ("update_schedule", "물어본 값을 받지 못해서 고치지 않았어요."),
            ("create_schedule", "물어본 값을 받지 못해서 등록하지 않았어요.")]
        var q16CancelBad: [String] = []
        for (tool, want) in q16CancelExpect {
            let (a, _) = q16Open(tool)
            a.drvCancelPendingAsk()
            let got = a.bubbles.last?.text ?? "nil"
            let leftover = a.bubbles.contains { $0.ask != nil }
            print("Q16-OBS 버린 카드(\(tool)) → \"\(got)\" 카드 남음=\(leftover)")
            if got != want || leftover { q16CancelBad.append("\(tool): \(got) leftover=\(leftover)") }
        }
        fresh().drvCheck("Q16-3: 버린 카드 말풍선이 열린 카드의 도구 동사를 따르고 카드는 남지 않는다",
                         q16CancelBad.isEmpty, "어긋남=\(q16CancelBad)")

        // Q16-4 열린 카드 가드 — 문구는 열린 카드의 도구, 카드는 두 장이 안 열린다
        let q16GuardCombos: [(open: String, incoming: String, inTool: String)] = [
            ("check_travel_time", "create_schedule", "create_schedule"),
            ("update_schedule", "check_travel_time", "check_travel_time"),
            ("create_schedule", "check_travel_time", "check_travel_time"),
            ("update_schedule", "recommend_meal", "recommend_meal")]
        var q16GuardBad: [String] = []
        for c in q16GuardCombos {
            let (a, _) = q16Open(c.open)
            let msg2: String
            switch c.inTool {
            case "create_schedule":
                msg2 = a.drvPark("create_schedule",
                                 ["title": "u", "origin_query": "집", "destination_query": "스타벅스 홍대점"],
                                 [(key: "destination_query", query: "스타벅스 홍대점", candidates: q16Cands)])
            case "recommend_meal":
                msg2 = a.drvPark("recommend_meal", ["keyword": "카페", "place_query": "홍대"],
                                 [(key: "place_query", query: "홍대", candidates: q16Cands)])
            default:
                msg2 = a.drvPark("check_travel_time", ["origin_query": "집", "destination_query": "홍대"],
                                 [(key: "destination_query", query: "홍대", candidates: q16Cands)])
            }
            let cards = a.bubbles.filter { $0.ask != nil }.count
            print("Q16-OBS 가드 열림=\(c.open) 들어옴=\(c.incoming) → \"\(msg2)\" 카드수=\(cards)")
            let openVerb: String = {
                switch c.open { case "update_schedule": return "고치지"
                case "check_travel_time", "recommend_meal": return "조회하지"
                default: return "등록하지" } }()
            let sentenceOK = openVerb == "등록하지" ? msg2.contains("그 등록만") : msg2.contains("그 카드의 일만")
            if !msg2.hasPrefix("\(openVerb) 않았어요") && !msg2.hasPrefix("\(openVerb) 않았어요".replacingOccurrences(of: " ", with: ""))
                && !msg2.hasPrefix(openVerb) { q16GuardBad.append("\(c.open)/\(c.incoming): 앞머리 \(msg2.prefix(14))") }
            if !sentenceOK || cards != 1 { q16GuardBad.append("\(c.open)/\(c.incoming): 문형·카드수(\(cards))") }
        }
        fresh().drvCheck("Q16-4: 열린 카드 가드가 열린 카드의 도구로 동사를 고르고 카드는 한 장만 남긴다",
                         q16GuardBad.isEmpty, "어긋남=\(q16GuardBad)")

        // Q16-5 열린 카드가 없을 때는 수리 전과 같다 — 들어온 호출의 도구 동사로 새 카드를 연다
        var q16FreshBad: [String] = []
        for tool in ["check_travel_time", "update_schedule", "create_schedule"] {
            let (a, msg) = q16Open(tool)
            let verb: String = tool == "update_schedule" ? "고치지" : (tool == "check_travel_time" ? "조회하지" : "등록하지")
            print("Q16-OBS 새 카드(\(tool)) → \"\(msg.prefix(60))…\" 카드수=\(a.bubbles.filter { $0.ask != nil }.count)")
            if !msg.hasPrefix("아직 \(verb) 않았어요") || a.bubbles.filter({ $0.ask != nil }).count != 1 { q16FreshBad.append(tool) }
        }
        fresh().drvCheck("Q16-5: 열린 카드가 없으면 들어온 호출의 도구 동사로 카드 한 장을 연다(수리 전과 같음)",
                         q16FreshBad.isEmpty, "어긋남=\(q16FreshBad)")
        // Q16-6 혼합 턴 — 한 턴에 조회와 등록이 함께 오면 카드 한 장이 둘을 다 쥔다(디자인 렌즈 S2-2 재현 시도)
        for order in [["check_travel_time", "create_schedule"], ["create_schedule", "check_travel_time"]] {
            let a = fresh()
            if let card = a.q16Mixed(order) {
                let names = card.parts.compactMap { ($0["functionCall"] as? [String: Any])?["name"] as? String }
                let n = AIAssistant.toolName(of: card)
                print("Q16-OBS 혼합 턴 \(order) → 카드 호출=\(names) toolName=\(n) 버튼=\(AIAssistant.pendingConfirmTitle(for: n))")
            } else {
                print("Q16-OBS 혼합 턴 \(order) → 카드 없음")
            }
        }
        let q16MixCard = fresh().q16Mixed(["check_travel_time", "create_schedule"])
        let q16MixNames = q16MixCard?.parts.compactMap { ($0["functionCall"] as? [String: Any])?["name"] as? String } ?? []
        let q16MixTitle = q16MixCard.map { AIAssistant.pendingConfirmTitle(for: AIAssistant.toolName(of: $0)) } ?? "카드없음"
        fresh().drvCheck("Q16-6 (재현 시도): [조회, 등록] 혼합 턴 카드의 버튼이, 카드가 실제로 실행하는 등록을 가리킨다",
                         q16MixNames.contains("create_schedule") && q16MixTitle == "등록하기",
                         "카드 호출=\(q16MixNames) 버튼=\(q16MixTitle)")
        // ===== 스크래치 하네스 끝 =====

