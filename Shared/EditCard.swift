import Foundation

/// 편집 카드의 필드 모델. AI 채팅의 되묻기 카드로 태어나 AIAssistant 안에 중첩돼 있었지만,
/// 네 편집 화면이 같은 타입을 쓰게 되며 중첩을 벗어났다 — 모델이 AI 전용 이름에 묶여 있으면
/// 화면이 빌려 쓸 수가 없다. 시각 해석의 단일 출처(BesirTime)도 이 파일이 함께 가진다.
///
/// 이 파일은 SwiftUI를 가져오지 않는다. 가드 드라이버(Tools/GuardDriver.swift)는 뷰 없이
/// 컴파일되는데, 모델이 뷰 프레임워크에 기대면 그 컴파일 집합이 깨진다.

/// 시각 표기("9월 17일 (목) 오후 3:00")와 카드 시각 값의 왕복 해석을 홀로 안다. 포매터·파서가
/// 파일마다 제각각 생기는 것이 이 프로젝트가 이미 한 번 당한 어긋남이라 정의는 이곳 하나고,
/// AIAssistant는 위탁 한 줄로 같은 시그니처를 유지한다.
@MainActor enum BesirTime {
    private static let whenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h시 m분"
        return f
    }()
    static func when(_ d: Date) -> String { whenFormatter.string(from: d) }

    /// 배너가 두 시각을 "~"로 잇는 데 쓰는 좁은 표기("9/17 (목) 오후 3시 05분"). `when`으로
    /// 흡수하지 않는 이유는 폭이다 — 실측 결과 `when`("9월 17일 (목) 오후 3시 5분")은 이보다
    /// 길어, ConflictBanner가 두 문자열을 이어 붙이면 줄바꿈이 깨진다(SPEC-UIKIT-002 REQ-023).
    /// static let인 이유: 옛 AddEventView의 depFmt는 계산 프로퍼티라 접근할 때마다 포매터를
    /// 새로 만들어 한 차례 재렌더에 최대 세 번 할당했다.
    static let compact: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M/d (E) a h시 mm분"
        return f
    }()

    /// 상세 화면 헤더의 완전한 표기("9월 17일 (목) 오후 3시 05분"). `when`과 패딩만 다른
    /// 쌍둥이인데 mm을 m으로 통일하면 "05분"의 0이 사라진다 — EventDetailView에서 이사해 온
    /// 그대로이고 한 글자도 다시 쓰지 않는다(SPEC-UIKIT-004 REQ-001).
    static let full: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h시 mm분"
        return f
    }()

    /// 하루 안의 시각만("오후 3시 05분") — 출발 시각 큰 숫자가 쓴다. 이사 본체, 패턴 불변.
    static let clock: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "a h시 mm분"
        return f
    }()

    /// 카드가 확정한 시각의 왕복 형식 — 쓰기(직렬화)와 읽기(accepts·재확정)가 같은 포매터를
    /// 쓴다. 형식 문자열이 두 벌이 되면 한쪽만 고쳐지는 날이 온다(렌더링·히트테스트가 어긋났던
    /// 그 모양). 실행부의 parseDate가 받는 형식이기도 하다.
    static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    /// "arr:2026-09-17T15:00:00" 형태의 시각 줄 값을 (접두, Date)로 푼다. accepts·customLabel·
    /// 직렬화·기준 재선택이 전부 이 파서를 지난다 — 제각각 파면 어느 한쪽만 고쳐진다.
    /// 접두 없는 값도 ("", Date)로 푼다 — 활동의 시작·종료는 도착/출발 기준을 갖지 않는 시각이라
    /// 확정값에 접두가 붙지 않는다. 빈 문자열이 목록 맨 끝인 이유: hasPrefix("")는 항상 참이라
    /// 앞에 두면 "arr:"와 "dep:"가 영영 도달하지 않는다.
    static func parseDatetime(_ raw: String) -> (prefix: String, date: Date)? {
        for prefix in ["arr:", "dep:", ""] where raw.hasPrefix(prefix) {
            if let d = isoFormatter.date(from: String(raw.dropFirst(prefix.count))) {
                return (prefix, d)
            }
        }
        return nil
    }

    /// 접두("arr:"/"dep:")와 도착·출발 기준을 잇는 매핑의 유일한 집 — 폼·AI 카드·컴포넌트가
    /// 제각각 삼항으로 알던 모양이 이 매핑의 계약 5 위반이었다. 몸통을 switch로 쓰는 것은
    /// 소유자 자신이 세는 신호(잔여 비교·삼항 grep)를 깨뜨리지 않기 위해서고, 커밋된 줄을
    /// 통째로 물어온 호출부는 parseDatetime을 먼저 거치게 한다(형식 지식이 호출부에 새는 것을
    /// 막는다 — 잘못된 값은 nil로, 삼항 시절의 "나머지 전부 출발"이 아니라).
    static func anchor(ofPrefix: String) -> ScheduleAnchor? {
        switch ofPrefix {
        case "arr:": return .arrival
        case "dep:": return .departure
        default: return nil
        }
    }

    /// anchor(ofPrefix:)의 역방향 — 직렬화하는 세 곳(폼 두 곳·AI 보류 턴)이 공유한다.
    static func prefix(for anchor: ScheduleAnchor) -> String {
        switch anchor {
        case .arrival: return "arr:"
        case .departure: return "dep:"
        }
    }
}

/// 앱이 직접 물을 인자 하나 = 카드의 한 줄.
///
/// 되묻는 주체가 모델이 아니라 앱인 이유: 이 모델은 선언된 선택 인자를 비워두지 못하고 전부
/// 채운다(b303f41 — 저장해둔 여유 10분이 0으로 덮여 35건이 등록되고도 아무도 몰랐다).
/// "비워둬라"·"물어봐라"는 이 프로젝트에서 가장 안 지켜지는 지시였고 두 번 실패했다.
/// 그래서 이 인자들은 툴 선언에서 아예 뺐다 — 모델이 채울 수 없어야 앱이 "비었다"를 관측한다.
// @MainActor를 명시하는 이유: 중첩 타입은 바깥 클래스의 배우 격리를 상속하지 않는다. 이
// 줄의 해석(accepts·customLabel)이 BesirTime의 포매터·파서를 쓰는데, 격리가 없으면 MainActor
// 정적 멤버를 부를 수 없다. 실제 호출자(뷰·AIAssistant·드라이버의 @MainActor 진입점)는 전부
// MainActor라 자연스럽다.
@MainActor struct EditField: Identifiable {
    /// 고른 문자열을 툴 인자로 되돌릴 때 쓰는 해석 방식.
    /// 줄마다 받아들이는 범위가 달라서 종류를 나눈다 — 여유와 알림은 상한이 다르다
    /// (여유는 Store가 180분에서 묶고, 알림은 "하루 전에 알려줘"가 실제 요청이라 안 묶는다).
    enum Kind {
        case place, mode, buffer, notify, weeks, title, datetime
        // 불(예·아니요)을 고르는 줄. 진짜 Toggle 컨트롤을 새 문법으로 넣지 않고 칩 두 개로
        // 굴린다 — 카드 안에 문법이 둘이 되면 줄마다 익히는 법이 둘이 된다(D-2). 칩은 고른
        // 값이 없으면 확인이 영원히 풀리지 않으므로(isReady), 토글 줄은 생성 시 "true"/"false"로
        // chosen을 seed한다.
        case toggle
    }
    struct Option: Identifiable {
        let id = UUID()
        /// 칩 글자는 소유 화면이 확정 뒤에 고칠 수 있다(현재 위치 칩에 지명을 얹는 확인 경로).
        /// options와 같은 이유로 var — 새 Option으로 갈아끼우면 id가 다시 찍혀 칩 신원이 흔들린다.
        var label: String
        let value: String
        /// 칩 안에 작게 따라붙는 근거 글(이동수단의 소요시간). 고르는 값과 고르는 근거를 같은
        /// 자리에 두는 것이 목적이라 줄 캡션으로 몰지 않는다 — 몰면 어느 칩이 어느 시간인지
        /// 눈으로 다시 맞춰야 한다. 기본값이 있어 기존 생성부는 한 줄도 바뀌지 않는다.
        var detail: String? = nil
    }
    let id = UUID()
    /// 툴 인자 이름. 확인 시 이 키로 값이 실린다.
    let key: String
    let kind: Kind
    let label: String
    /// 칩의 소요시간(detail)은 이동시간 계산이 돌아온 뒤 소유 화면이 채운다 — 그때 줄을 통째로
    /// 새로 만들면 id가 바뀌어 줄 에디터의 지역 상태가 흩어지므로(REQ-021), 배열째 제자리에서
    /// 고칠 수 있어야 한다.
    var options: [Option]
    /// 칩만으로 모든 값을 열거할 수 없는 줄에만 붙인다. 이동수단은 세 칩이 곧 전체 집합이라
    /// 붙이지 않는다(승인된 카드 형태 그대로 — 직접입력이 없어도 못 고르는 값이 없다).
    let allowsCustom: Bool
    /// 이 줄이 **왜 떴는지** 한 줄로. 값이 차 있는데 앱이 풀지 못할 때만 붙는다("회사"라고
    /// 말했는데 그 이름의 즐겨찾기가 없는 경우) — 말한 적 없는 값을 묻는 줄과 겉모습이 같으면
    /// 사용자는 "방금 말했는데 왜 또 묻지"로 읽는다. 빈 값을 묻는 평범한 줄에는 nil이다.
    var note: String? = nil
    /// 장소 줄의 검색 상태. 장소는 **후보를 탭해서** 고르는 것이 정상 경로다 — 자유 텍스트를
    /// 그대로 확정하면 좌표가 없어, 카드를 다 채우고 확인을 누른 **뒤에야** 실행부의 검색이
    /// 실패한다("'ㅁㄴㅇㄹ' 위치를 찾지 못했어요" — 2026-09-16 실기기 결함 P). 가장 늦게
    /// 알게 되는 실패를 가장 이른 자리로 옮기는 것이 이 상태의 존재 이유다.
    enum Lookup { case idle, searching, results([Place]), empty }
    var lookup: Lookup = .idle
    /// 사용자가 고른 원시 값. nil이면 아직 안 골랐다 — 확인 버튼이 잠긴다.
    var chosen: String? = nil
    /// 줄이 진행 중임을 알리는 깃발. 카드 뷰는 순수 값 뷰라 외부 상태를 스스로 관찰할 수
    /// 없어, 소유 화면이 자기 상태(현재 위치 찾기·이동시간 계산)를 이 값으로 줄에 잇고 바꿔
    /// 재렌더를 일으킨다. 참이면 줄 이름 옆에 작은 ProgressView가 뜬다.
    var busy: Bool = false
    /// 카드가 뜰 때 에디터를 열어두는 줄(제목·목적지처럼 새 일정마다 반드시 새로 치는 값).
    /// 칩 문법은 칩을 먼저 탭해야 입력칸이 열리므로 이 깃발이 없으면 주 경로에 탭이 하나
    /// 늘어난다. 소유 화면이 카드를 완성한 뒤에 띄운다는 전제로 뷰가 onAppear에서 씨앗을
    /// 뿌린다. AI 후보 카드(U-4)는 후보를 미리 얹은 줄에서 이 깃발을 켠다(D-6 (a)) — 후보가
    /// 카드 안에 있으면서도 첫 화면에서는 보이지 않는 일이 없게 한다.
    var startsOpen: Bool = false
    /// 시각 줄이 도착/출발 기준을 갖는지. 활동의 시작·종료처럼 기준 없는 시각은 false로 만들며,
    /// 그런 줄은 기준 칩이 없고(REQ-002) 확정이 chooseTimePlain으로 간다(REQ-001 (d)). 기본값이
    /// true인 이유는 기존 생성부(AddEventView·AIAssistant)가 전부 기준 있는 줄이라 그 둘이 한
    /// 줄도 바뀌지 않게 하려는 것이다.
    var anchored: Bool = true

    var chosenLabel: String? {
        guard let chosen else { return nil }
        return options.first { $0.value == chosen }?.label ?? Self.customLabel(kind, chosen)
    }
    static func customLabel(_ kind: Kind, _ value: String) -> String {
        switch kind {
        case .buffer, .notify: return "\(value)분"
        case .weeks: return "\(value)주"
        // .toggle 가지는 컴파일 강제일 뿐 실행 중 오지 않는다 — 토글 줄은 allowsCustom이
        // false라 칩 밖에서 온 값(customLabel의 유일한 호출 경로)이 생기지 않는다.
        case .place, .mode, .title, .toggle: return value
        case .datetime:
            // "arr:2026-09-17T15:00:00" → "도착 9월 17일 (목) 오후 3:00" — 기준이 글자로 박혀
            // 나간다(확정 요약·재오픈 칩 모두 이 문구를 쓴다). 기준 글자는 anchor(ofPrefix:)의
            // 답으로만 정한다 — 여기서 접두를 다시 읽으면 해석이 두 곳에 살고(계약 5) ""(기준
            // 없는 시각)이 "출발"로 박혀 나간다.
            return BesirTime.parseDatetime(value).map { parsed in
                switch BesirTime.anchor(ofPrefix: parsed.prefix) {
                case .arrival: return "도착 " + BesirTime.when(parsed.date)
                case .departure: return "출발 " + BesirTime.when(parsed.date)
                case nil: return BesirTime.when(parsed.date)
                }
            } ?? value
        }
    }

    /// 직접입력 값을 받아들일지 판정한다. 범위 밖을 카드에서 막아야 실행부까지 흘러가지 않는다.
    /// 빈 입력은 어떤 줄에서도 제출되지 않는다.
    func accepts(_ raw: String) -> String? {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        switch kind {
        // .toggle도 컴파일 강제 가지다 — 토글 줄은 직접입력 에디터가 없어 accepts가 불리지 않는다.
        case .place, .title, .toggle: return t
        case .mode: return TransportMode(rawValue: t) != nil ? t : nil
        case .buffer:
            guard let v = Int(t), (0...Store.maxBufferMinutes).contains(v) else { return nil }
            return String(v)
        case .notify:
            // 카드 입력의 상한일 뿐 저장값의 상한이 아니다 — clampNotifyLead는 위로 묶지 않는다.
            // 하루(1440분) 전 알림까지는 실제 요청이고, 그 밖은 오타로 본다.
            guard let v = Int(t), (0...1440).contains(v) else { return nil }
            return String(v)
        case .weeks:
            guard let v = Int(t), (1...Store.maxRecurrenceWeeks).contains(v) else { return nil }
            return String(v)
        case .datetime:
            // 뷰의 DatePicker가 만든 값의 불변식 게이트다(시각 줄에는 텍스트 입력 경로가 없다) —
            // 접두(도착/출발) + 정규 ISO만 받아들이고 통과하면 정규화해 돌려준다. 접두 없는 정규
            // ISO도 받는다 — parseDatetime이 ""를 푼다(REQ-001 (a)).
            return BesirTime.parseDatetime(t)
                .map { $0.prefix + BesirTime.isoFormatter.string(from: $0.date) }
        }
    }
}

/// 부재 인자를 전부 모은 카드 한 장. 요청당 정확히 한 장이고, 확인을 누르면 보류해 둔
/// 호출이 채워진 인자와 함께 **1회** 실행된다 — 선택과 값 사이에 모델이 끼어들 틈이 없다.
/// parts·stated의 기본값은 화면 카드가 이 둘 없이 카드를 만들기 위한 것 — let에 기본값을
/// 붙이면 멤버와이즈 이니셜라이저에서 빠져 기존 호출부가 깨지므로 var이다.
@MainActor struct EditCard: Identifiable {
    let id = UUID()
    /// 보류해 둔 모델 턴 원본. 확인 시 인자만 채워 히스토리에 넣는다 — 미완성 인자가 담긴
    /// 턴을 히스토리에 먼저 넣으면 다음 요청에 그 값이 계속 딸려간다.
    var parts: [[String: Any]] = []
    /// 사용자가 말로 이미 정한 값(카드에 줄을 만들지 않은 것들). 무엇이 조용히 정해졌는지
    /// 카드에 적어 보여준다 — 줄이 사라진 자리를 사용자가 못 보면 그게 곧 조용한 적용이다.
    var stated: [String] = []
    /// 후보 카드(parkForUnclearPlaces)가 인자를 **비워 둔** 키의 기록. 확인 경로의 사전 주입은
    /// 이 키에만 실린다 — 빈 값이면 어디에나 있을 수 있어서다(모델이 안 보낸 키도 비어 있다).
    /// 카드가 비우지 않은 빈 키(같은 턴 다른 호출의 같은 이름 키)에 고른 값을 실으면 그 호출이
    /// 묻지 않은 장소로 조용히 등록된다(sync 1차 D4). 실행 전 카드는 비운 키가 없으므로 공집합.
    var clearedKeys: Set<String> = []
    var fields: [EditField]
    var isReady: Bool { fields.allSatisfy { $0.chosen != nil } }
}

// MARK: - 구간 줄 문법(SPEC-UIKIT-009 MB)

/// 구간 줄 아홉의 키 표 — 리터럴은 이 표에만 산다(AC-006 (9)). 생성 카드·활동 카드·이 파일의
/// 전이와 줄 공장이 전부 이 상수를 읽는다. AI 카드의 어휘(travel_from_query·return_to_query)와
/// 이름이 다른 채로 둔 이유: 사상은 어댑터의 일이고 그 어댑터는 t30의 몫이기 때문이다(REQ-007) —
/// 여기서는 두 화면이 같은 키로 말하게 하는 것만이 목적이다.
@MainActor enum LegRowKeys {
    static let outboundEnabled = "outbound_enabled"
    static let originQuery = "origin_query"
    static let outboundMode = "outbound_mode"
    static let bufferMinutes = "buffer_minutes"
    static let returnEnabled = "return_enabled"
    static let returnQuery = "return_query"
    static let returnMode = "return_mode"
    static let notifyEnabled = "notify_enabled"
    static let notifyLeadMinutes = "notify_lead_minutes"
    /// 장소가 사라질 때 한꺼번에 빠지는 아홉 줄의 집합 — 키 나열이 호출부마다 배열 리터럴로
    /// 흩어져 있으면 열째 줄이 생기는 날 한 자리만 늙는다.
    static let allKeys: Set<String> = [outboundEnabled, originQuery, outboundMode, bufferMinutes,
                                       returnEnabled, returnQuery, returnMode,
                                       notifyEnabled, notifyLeadMinutes]
}

/// 활동의 구간(가는/오는 이동) 줄을 굴리는 값 상태와 전이. 생성 카드(AddActivityView)가 뷰의
/// @State 아홉과 빌더 다섯으로 홀로 들고 있던 것을, 활동 카드(ActivityDetailView)도 같은 문법으로
/// 쓰게 하려고 뷰 밖으로 뽑았다(SPEC-UIKIT-009 REQ-007) — 문법이 두 화면에 벌로 있으면 줄
/// 문구·멤버십 규칙이 어느 한쪽만 늙는다(계약 5). EditField가 @MainActor struct이므로 이 타입도
/// 같은 격리를 따른다(이 파일 머리 주석의 이유와 같다).
///
/// 뷰는 이 값 하나를 @State로 들고 choose만 부른다. 좌표 사전(줄 신원 → Place)과 기억값 아홉이
/// card와 한 몸인 이유: choose의 전이가 셋을 함께 고치는데 뷰 쪽에 흩어 두면 어느 하나만 값을
/// 옮기는 순간 전이가 반쪽으로 도는 문법이 된다.
@MainActor struct LegCardForm {
    var card: EditCard
    /// 후보를 탭한 순간 좌표까지 확정된 장소. 열쇠는 이름이 아니라 **줄 신원**(EditField.id)이다.
    /// 이름으로 걸면 같은 상호의 다른 지점을 두 줄에서 고를 때 나중 쓰기가 앞 줄의 좌표까지
    /// 덮어, 활동 장소와 출발지가 한 좌표가 된다 — 이동 0분짜리 구간에 출발 알람이 활동 시작
    /// 시각으로 잡히고, 화면엔 이름만 보여 어긋난 걸 알 길이 없다. 줄 신원은 생성 때 한 번
    /// 찍히므로 두 줄이 겹칠 수가 없다. 지연 해석 함수는 만들지 않는다(계약 5: 만들면
    /// resolvePlace의 세 번째 구현이 된다).
    var confirmedPlaces: [UUID: Place] = [:]
    /// 즐겨찾기 칩의 옵션과 라벨 → 좌표 씨앗. 칩 탭은 Place를 들고 오지 않고 라벨만 주므로 그
    /// 라벨을 좌표로 푸는 씨앗이 전이에 필요하다 — 카드를 띄우는 화면이 시트가 뜰 때 채워 넣는다.
    var favoriteOptions: [EditField.Option] = []
    var favoritePlaces: [String: Place] = [:]

    // ── 줄이 배열에서 빠져 있는 동안의 기억값(REQ-011). 되살리지 않으면 토글을 껐다 켠 사용자가
    // 방금 고른 출발지·여유를 잃는다 — AddEventView의 lastNotifyLead와 같은 형태다.
    /// 가는 편이 꺼져 있는(또는 장소가 없어 줄 자체가 없는) 동안의 출발지 이름.
    var rememberedOutboundOrigin: String? = nil
    /// 그 출발지의 좌표. 이름만 기억하면 다리를 껐다 켠 사용자가 좌표를 잃는다 — 좌표가 줄 신원에
    /// 걸린 뒤로, 되살린 줄은 신원이 달라 이름으로는 되찾을 길이 없다.
    var rememberedOutboundOriginPlace: Place? = nil
    var rememberedOutboundMode = TransportMode.transit.rawValue
    /// 가는 편이 꺼져 있는 동안의 도착 여유(분).
    var rememberedBuffer = "10"
    /// 오는 편이 꺼져 있는 동안의 도착지 이름.
    var rememberedReturnTo: String? = nil
    /// 그 도착지의 좌표 — 출발지와 같은 이유로 이름과 함께 기억한다.
    var rememberedReturnToPlace: Place? = nil
    var rememberedReturnMode = TransportMode.transit.rawValue
    /// 알림 줄이 꺼져 있는 동안의 마지막 켬/끔 — 다리를 껐다 켜도 알림을 끊은 사실이 되살아나야
    /// 옛 폼과 같다(옛 폼의 알림 스위치는 다리를 꺼도 값을 유지했다).
    var lastNotifyOn = true
    /// 알림 줄이 꺼져 있는 동안의 마지막 리드 값.
    var lastNotifyLead = "30"

    /// 칩을 탭했을 때의 전이 — 생성 카드의 choose(field:value:place:)에서 구간 네 분기와 공통
    /// 몸통(값 적기·좌표 걸기)을 그대로 옮겼다. 문구·멤버십·줄 위치가 한 글자도 다르지 않아야
    /// 같은 문법이다(AC-006 (2)가 전 저장소에서 문구가 정확히 한 번 나온다고 잰다).
    /// `place`는 검색 후보를 탭해 지점까지 특정된 경우에만 실려 온다(choosePlace) — 칩 탭은
    /// nil로 들어와 라벨을 즐겨찾기 씨앗에서 푼다.
    mutating func choose(field: UUID, value: String, place: Place? = nil) {
        guard let i = card.fields.firstIndex(where: { $0.id == field }) else { return }
        let key = card.fields[i].key
        card.fields[i].chosen = value
        // 좌표는 값을 적은 그 줄 자리에 건다. 실려 온 place가 즐겨찾기 씨앗을 이기는 순서인 이유:
        // 검색 후보는 지점까지 특정된 값이고 즐겨찾기 라벨은 우연히 같을 수 있는 이름일 뿐이라,
        // 반대로 두면 검색해서 고른 "스타벅스" 홍대점이 즐겨찾기 "스타벅스"의 좌표로 조용히
        // 바뀐다. 씨앗에도 없으면("장소 없음" 칩) nil이 들어가 옛 좌표가 지워진다 — 이름이
        // 열쇠이던 시절엔 열쇠가 바뀌며 저절로 풀리던 자리라, 이제 명시로 갚는다.
        if card.fields[i].kind == .place { confirmedPlaces[field] = place ?? favoritePlaces[value] }
        switch key {
        case "location_query":
            // note는 없는 줄(이동)을 설명하는 말 — 고르는 순간 낡는다. 남아 있으면 잡음이다.
            card.fields[i].note = nil
            if confirmedPlaces[field] != nil {
                // 실제 장소를 고른 순간 다리 토글 줄이 태어난다 — 옛 화면의 else 가지가 줄 멤버십으로
                // 옮겨온 자리다. "장소 없음"은 즐겨찾기 씨앗에도 검색 결과에도 없어 바로 위에서
                // 이 줄의 좌표가 nil로 지워지므로 이 가지를 타지 않는다.
                if !card.fields.contains(where: { $0.key == LegRowKeys.outboundEnabled }) {
                    let at = card.fields.firstIndex(where: { $0.key == "end_iso" }).map { $0 + 1 }
                        ?? card.fields.count
                    card.fields.insert(contentsOf: [
                        legToggleRow(key: LegRowKeys.outboundEnabled, label: "가는 이동 (활동 시작에 맞춰 도착)"),
                        legToggleRow(key: LegRowKeys.returnEnabled, label: "오는 이동 (활동 끝나면 출발)"),
                    ], at: at)
                }
            } else {
                rememberTravelValues()
                forgetPlaces([LegRowKeys.originQuery, LegRowKeys.returnQuery])
                card.fields.removeAll { LegRowKeys.allKeys.contains($0.key) }
            }
        case LegRowKeys.outboundEnabled:
            if value == "true" {
                // 칩은 선택 상태를 스스로 가리지 않고 매 탭마다 불린다 — 이미 켠 다리를 다시
                // 탭해도 줄이 겹치면 field()가 첫 줄을 읽어 저장값이 씨앗값으로 굳는다.
                if !card.fields.contains(where: { $0.key == LegRowKeys.originQuery }) {
                    let at = card.fields.firstIndex(where: { $0.key == LegRowKeys.outboundEnabled }).map { $0 + 1 }
                        ?? card.fields.count
                    let rows = outboundRows(origin: rememberedOutboundOrigin,
                                            mode: rememberedOutboundMode,
                                            buffer: rememberedBuffer)
                    // 되살린 줄은 신원이 새로 찍힌다 — 기억해 둔 좌표를 그 새 신원에 다시 건다.
                    // 안 걸면 이름만 살아나고 저장 때 출발지가 nil로 풀려, 다리는 켜졌는데
                    // 출발지 없는 구간이 만들어진다.
                    reseed(rows, LegRowKeys.originQuery, rememberedOutboundOriginPlace)
                    card.fields.insert(contentsOf: rows, at: at)
                }
                ensureNotifyRows()
            } else {
                rememberOutboundOrigin()
                if let m = chosenIn(LegRowKeys.outboundMode) { rememberedOutboundMode = m }
                if let b = chosenIn(LegRowKeys.bufferMinutes) { rememberedBuffer = b }
                forgetPlaces([LegRowKeys.originQuery])
                card.fields.removeAll {
                    [LegRowKeys.originQuery, LegRowKeys.outboundMode, LegRowKeys.bufferMinutes].contains($0.key)
                }
                // 다리가 전부 꺼지면 알림 줄도 근거를 잃는다 — 옛 폼 조건의 멤버십 판이다.
                if chosenIn(LegRowKeys.returnEnabled) != "true" { removeNotifyRows() }
            }
        case LegRowKeys.returnEnabled:
            if value == "true" {
                // 위와 같은 이유 — 켜진 오는 편을 다시 탭해도 줄이 겹쳐 들어가지 않게 멤버십이 가드한다.
                if !card.fields.contains(where: { $0.key == LegRowKeys.returnQuery }) {
                    let at = card.fields.firstIndex(where: { $0.key == LegRowKeys.returnEnabled }).map { $0 + 1 }
                        ?? card.fields.count
                    let rows = returnRows(to: rememberedReturnTo, mode: rememberedReturnMode)
                    // 가는 편과 같은 이유 — 되살린 줄의 새 신원에 기억해 둔 좌표를 다시 건다.
                    reseed(rows, LegRowKeys.returnQuery, rememberedReturnToPlace)
                    card.fields.insert(contentsOf: rows, at: at)
                }
                ensureNotifyRows()
            } else {
                rememberReturnTo()
                if let m = chosenIn(LegRowKeys.returnMode) { rememberedReturnMode = m }
                forgetPlaces([LegRowKeys.returnQuery])
                card.fields.removeAll {
                    [LegRowKeys.returnQuery, LegRowKeys.returnMode].contains($0.key)
                }
                if chosenIn(LegRowKeys.outboundEnabled) != "true" { removeNotifyRows() }
            }
        case LegRowKeys.notifyEnabled:
            lastNotifyOn = value == "true"
            if value == "false" {
                // 끌 때 마지막 값을 기억한 뒤 줄을 뺀다 — 값까지 지우면 다시 켤 때 처음부터
                if let l = chosenIn(LegRowKeys.notifyLeadMinutes) { lastNotifyLead = l }
                card.fields.removeAll { $0.key == LegRowKeys.notifyLeadMinutes }
            } else if !card.fields.contains(where: { $0.key == LegRowKeys.notifyLeadMinutes }) {
                let at = card.fields.firstIndex(where: { $0.key == LegRowKeys.notifyEnabled }).map { $0 + 1 }
                    ?? card.fields.count
                card.fields.insert(notifyLeadRow(chosen: lastNotifyLead), at: at)
            }
        default:
            break
        }
    }

    /// 장소가 사라질 때(장소 없음 칩) 다리 줄 전부의 값을 기억해 둔다 — 다시 실제 장소를 고르면
    /// 토글은 문서화된 기본값(끔)으로 돌아오지만, 토글을 켜면 고르던 값들이 되살아난다.
    /// 장소 줄은 다리를 끈 뒤엔 이미 없다 — 칩이 nil을 돌려도 무조건 넣으면 끌 때 기억한 값까지 지운다.
    private mutating func rememberTravelValues() {
        rememberOutboundOrigin()
        if let m = chosenIn(LegRowKeys.outboundMode) { rememberedOutboundMode = m }
        if let b = chosenIn(LegRowKeys.bufferMinutes) { rememberedBuffer = b }
        rememberReturnTo()
        if let m = chosenIn(LegRowKeys.returnMode) { rememberedReturnMode = m }
        if let l = chosenIn(LegRowKeys.notifyLeadMinutes) { lastNotifyLead = l }
        if let n = chosenIn(LegRowKeys.notifyEnabled) { lastNotifyOn = n == "true" }
    }

    /// 출발지 줄의 이름과 좌표를 함께 기억한다. 둘을 갈라 두지 않는 이유: 좌표가 줄 신원에 걸린
    /// 뒤로, 이름만 기억하면 되살린 줄에서 그 좌표를 되찾을 길이 없다.
    private mutating func rememberOutboundOrigin() {
        guard let f = card.fields.first(where: { $0.key == LegRowKeys.originQuery }), let o = f.chosen else { return }
        rememberedOutboundOrigin = o
        rememberedOutboundOriginPlace = confirmedPlaces[f.id]
    }

    /// 도착지 줄도 같은 이유로 이름과 좌표를 함께 기억한다.
    private mutating func rememberReturnTo() {
        guard let f = card.fields.first(where: { $0.key == LegRowKeys.returnQuery }), let r = f.chosen else { return }
        rememberedReturnTo = r
        rememberedReturnToPlace = confirmedPlaces[f.id]
    }

    /// 아직 배열에 넣기 전인 줄에 기억해 둔 좌표를 건다 — 되살린 줄은 신원이 다르기 때문이다.
    private mutating func reseed(_ rows: [EditField], _ key: String, _ place: Place?) {
        guard let place, let row = rows.first(where: { $0.key == key }) else { return }
        confirmedPlaces[row.id] = place
    }

    /// 줄이 배열에서 빠질 때 그 줄에 걸린 좌표도 놓는다 — 신원이 사라진 좌표는 아무도 되찾지
    /// 못하는데, 놓지 않으면 카드가 사는 동안 사전만 자란다.
    private mutating func forgetPlaces(_ keys: [String]) {
        for f in card.fields where keys.contains(f.key) { confirmedPlaces[f.id] = nil }
    }

    /// 다리가 하나라도 켜지면 알림 줄이 필요해진다 — 캘린더 줄이 있다면 그 앞에, 없으면 맨 끝에.
    private mutating func ensureNotifyRows() {
        let legOn = card.fields.first(where: { $0.key == LegRowKeys.outboundEnabled })?.chosen == "true"
            || card.fields.first(where: { $0.key == LegRowKeys.returnEnabled })?.chosen == "true"
        guard legOn, !card.fields.contains(where: { $0.key == LegRowKeys.notifyEnabled }) else { return }
        let at = card.fields.firstIndex(where: { $0.key == "calendar_sync" }) ?? card.fields.count
        card.fields.insert(notifyToggleRow(chosen: lastNotifyOn ? "true" : "false"), at: at)
        // 꺼져 있던 채로 돌아오는 것이 아니라면 리드 줄이 곧바로 따라온다 — 토글만 홀로 나오는
        // 순간이 없게 한다(켬이 문서화된 기본값이다).
        if lastNotifyOn { card.fields.insert(notifyLeadRow(chosen: lastNotifyLead), at: at + 1) }
    }

    /// 알림 줄을 지우기 전에 마지막 값을 기억한다 — 다리를 다시 켤 때 되살린다.
    private mutating func removeNotifyRows() {
        if let l = chosenIn(LegRowKeys.notifyLeadMinutes) { lastNotifyLead = l }
        if let n = chosenIn(LegRowKeys.notifyEnabled) { lastNotifyOn = n == "true" }
        card.fields.removeAll {
            $0.key == LegRowKeys.notifyEnabled || $0.key == LegRowKeys.notifyLeadMinutes
        }
    }

    // MARK: 줄 만들기

    private func legToggleRow(key: String, label: String) -> EditField {
        .init(key: key, kind: .toggle, label: label,
              options: [.init(label: "만들기", value: "true"), .init(label: "안 만들기", value: "false")],
              allowsCustom: false, chosen: "false")
    }

    private func outboundRows(origin: String?, mode: String, buffer: String) -> [EditField] {
        [
            .init(key: LegRowKeys.originQuery, kind: .place, label: "출발지", options: favoriteOptions,
                  allowsCustom: true, chosen: origin),
            .init(key: LegRowKeys.outboundMode, kind: .mode, label: "가는 편 이동수단",
                  options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
                  allowsCustom: false, chosen: mode),
            // 이름에 "가는 편"이 붙는 이유: 복귀 구간의 여유는 Store가 0으로 박아 둔다
            // (addActivityWithTravel). "도착 여유"라고만 쓰면 이 줄이 오는 편에도 적용된다고
            // 말하는 셈이 된다(REQ-014).
            .init(key: LegRowKeys.bufferMinutes, kind: .buffer, label: "가는 편 도착 여유",
                  options: [.init(label: "0분", value: "0"), .init(label: "10분", value: "10"),
                            .init(label: "20분", value: "20"), .init(label: "30분", value: "30")],
                  allowsCustom: true, chosen: buffer),
        ]
    }

    private func returnRows(to: String?, mode: String) -> [EditField] {
        [
            .init(key: LegRowKeys.returnQuery, kind: .place, label: "도착지", options: favoriteOptions,
                  allowsCustom: true, chosen: to),
            .init(key: LegRowKeys.returnMode, kind: .mode, label: "오는 편 이동수단",
                  options: TransportMode.allCases.map { .init(label: $0.title, value: $0.rawValue) },
                  allowsCustom: false, chosen: mode),
        ]
    }

    private func notifyToggleRow(chosen: String) -> EditField {
        .init(key: LegRowKeys.notifyEnabled, kind: .toggle, label: "이동 알림 받기",
              options: [.init(label: "받기", value: "true"), .init(label: "안 받기", value: "false")],
              allowsCustom: false, chosen: chosen)
    }

    /// 알림 옵션은 AddEventView.notifyLeadRow와 같은 넷이다 — 두 폼이 다른 보기를 내면 같은
    /// 값을 두 문법으로 배우게 된다(REQ-012).
    private func notifyLeadRow(chosen: String) -> EditField {
        .init(key: LegRowKeys.notifyLeadMinutes, kind: .notify, label: "알림",
              options: [.init(label: "출발 시각", value: "0"), .init(label: "10분 전", value: "10"),
                        .init(label: "30분 전", value: "30"), .init(label: "1시간 전", value: "60")],
              allowsCustom: true, chosen: chosen)
    }

    private func chosenIn(_ key: String) -> String? {
        card.fields.first(where: { $0.key == key })?.chosen
    }
}

/// 카드가 스스로 그리는 크롬(머리글·확인 문구)을 끄는 스위치. 소유 화면이 자기 제목과 제출
/// 버튼을 이미 갖고 있으면 카드 쪽을 꺼야 한다 — 둘을 다 그리면 제목이 둘, 제출 버튼이 둘로
/// 보인다. nil이면 숨긴다. AI 카드의 기본 문구는 뷰 쪽 기본값에 두고 이 타입엔 없다 — 모델이
/// 특정 화면의 문구를 알면 중립 타입이 아니게 된다.
struct EditCardChrome {
    var header: String?
    var confirmTitle: String?
}

/// 카드 뷰가 값을 소유한 쪽(AIAssistant 등)을 타입으로 모르게 하는 다리 — 뷰가 부르는
/// 여덟 동작을 클로저로 묶어 넘긴다. 값은 Store/AIAssistant에만 있고, 결합이 이 어댑터로
/// 수축한다(네 편집 화면이 같은 카드를 쓰려면 뷰가 특정 소유자를 가져선 안 된다).
struct EditCardActions {
    var chooseValue: @MainActor (UUID, String) -> Void
    var rechooseTimeBasis: @MainActor (UUID, ScheduleAnchor) -> Void
    var chooseTime: @MainActor (UUID, ScheduleAnchor, Date) -> Bool
    /// 기준 없는 시각 줄의 확정 — chooseTime에서 ScheduleAnchor만 뺀 형태. chooseTime의 인자를
    /// 옵셔널로 바꾸는 대신 별도 클로저를 둔 이유는 생성부 둘(AIAssistant·AddEventView)과 그
    /// 안쪽 시그니처가 함께 바뀌지 않게 하려는 것이다(SPEC-UIKIT-003 D-2). 기본값이 있어 기존
    /// 생성부는 무변경이고, 아직 기준 없는 줄을 만들지 않는 화면은 항상 false를 받는다.
    var chooseTimePlain: @MainActor (UUID, Date) -> Bool = { _, _ in false }
    var choosePlace: @MainActor (UUID, Place) -> Void
    var searchPlaces: @MainActor (UUID, String) -> Void
    var submitCustom: @MainActor (UUID, String) -> Bool
    var confirm: @MainActor () async -> Void
}

/// 장소 검색 묶음(debounce) — **입력이 멈춘 뒤 한 번만** 부르게 만드는 정책의 단일 소유자.
/// 글자마다 부르면 카카오 일일 할당량을 그대로 태운다(이 프로젝트는 외부 한도로 이미 데였다:
/// iOS 알림 64건). 350ms인 이유는 한글 조합이 한 글자를 완성하는 간격보다는 길고
/// ("가"→"강"→"강남"이 한 번으로 묶인다) 다 치고 기다리는 느낌이 나기엔 짧아서다.
///
/// 정책이 이 타입에만 있는 이유는 계약 5(같은 계산은 한 곳에)다 — AI 카드와 이 카드를 빌려 쓸
/// 화면이 각자 지연 시간을 들고 있으면 한쪽만 늙는다. 지연 상수도 이 타입이 유일하게 소유하고,
/// 소유자는 인스턴스를 하나씩 들며 줄 id(UUID)로 서로 다른 줄의 검색을 구분한다.
/// 같은 질의를 건너뛰는 것도 정책의 일부다 — 단 **직전 검색이 완료된 뒤의 같은 질의에만** 내린
/// 다. 방금 진행 중 작업을 끊은 참이면 같은 질의라도 다시 실행한다: 끊긴 작업이 줄에 뿌린
/// '찾는 중'을 되돌릴 주체가 더는 없어서다.
@MainActor struct PlaceSearchDebouncer {
    /// gate의 판정. 호출자는 이 세 갈래를 그대로 따를 뿐 정책을 다시 해석하지 않는다 —
    /// 판단이 밖으로 새면 정책이 두 벌이 된다.
    enum Outcome {
        /// 정리된 질의로 검색을 시작해야 한다.
        case fire(String)
        /// 같은 질의가 이어서 왔다 — 부르지 않고, 상태도 되돌리지 않는다.
        case skip
        /// 입력이 비었다 — 호출자가 줄 상태를 비운다.
        case clear
    }

    /// 지연 시간은 이곳이 유일한 출처다(REQ-010). 350ms.
    private static let delayNanos: UInt64 = 350_000_000

    private var tasks: [UUID: Task<Void, Never>] = [:]
    /// 완료된 마지막 질의 — skip 판정의 재료.
    private var lastQuery: [UUID: String] = [:]
    /// 예약(arm)돼 아직 완료되지 않은 질의 — 이번 gate에서 진행 중 작업을 끊었는지 아는 재료.
    private var armedQuery: [UUID: String] = [:]

    /// 새 입력에 대한 판정. 예전 작업은 이 자리에서 끊는다 — gate이 끊어 주지 않으면
    /// 호출자의 취소 실수 하나로 묶음이 아니라 지연된 연쇄 호출이 된다. skip은 **완료된 뒤의
    /// 같은 질의에만** 내린다: 방금 진행 중 작업을 끊었는데 skip을 내리면 그 작업이 줄에 뿌린
    /// '찾는 중'을 되돌릴 주체가 남지 않아 줄이 영원히 찾는 중에 갇힌다(한 글자 지웠다 다시
    /// 치는 정정이 대표 경로) — 끊은 작업이 있으면 같은 질의라도 다시 실행한다.
    mutating func gate(_ key: UUID, _ raw: String) -> Outcome {
        let q = raw.trimmingCharacters(in: .whitespaces)
        let hadLiveTask = armedQuery[key] != nil
        tasks[key]?.cancel()
        tasks[key] = nil
        armedQuery[key] = nil
        guard !q.isEmpty else {
            lastQuery[key] = nil
            return .clear
        }
        if lastQuery[key] == q, !hadLiveTask { return .skip }
        return .fire(q)
    }

    /// 판정이 fire일 때만 부른다. 지연을 기다렸다가 그새 취소되지 않았으면 호출자의 클로저를
    /// 실행한다. 예약 질의를 함께 기록한다 — gate가 "방금 진행 중 작업을 끊었는가"를 아는
    /// 유일한 재료라서, 기록이 남으면 skip이 억제되고 재실행으로 간다.
    mutating func arm(_ key: UUID, _ query: String, fire: @escaping @MainActor () async -> Void) {
        tasks[key] = Task {
            try? await Task.sleep(nanoseconds: Self.delayNanos)
            guard !Task.isCancelled else { return }
            await fire()
        }
        armedQuery[key] = query
    }

    /// 완료한 질의를 기록한다 — **비동기 작업이 돌아온 뒤에만**(호출자는 fire 클로저의 끝에서
    /// 부른다). 예약 시점에 기록하면 아직 도는 검색까지 "완료된 질의"로 세여 skip이 결과를
    /// 덮어써 버린다. 완료 시점에 기록해야 "지우고 다시 친 같은 질의"는 다시 불린다. 드라이버
    /// P-5가 단언 추가 없이 초록인 것이 이 시점이 살아 있다는 증거다. 예약 기록도 함께 지운다 —
    /// 완료한 작업은 더 진행 중이 아니다.
    mutating func noteDone(_ key: UUID, _ query: String) {
        lastQuery[key] = query
        armedQuery[key] = nil
    }

    /// 모든 작업을 끊고 기록을 비운다. 카드가 사라지는 순간(취소·확인)에 불린다.
    mutating func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks = [:]
        lastQuery = [:]
        armedQuery = [:]
    }
}
