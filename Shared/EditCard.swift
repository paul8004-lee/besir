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
    static func parseDatetime(_ raw: String) -> (prefix: String, date: Date)? {
        for prefix in ["arr:", "dep:"] where raw.hasPrefix(prefix) {
            if let d = isoFormatter.date(from: String(raw.dropFirst(prefix.count))) {
                return (prefix, d)
            }
        }
        return nil
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
    /// 칩 문법은 점선 칩을 먼저 탭해야 입력칸이 열리므로 이 깃발이 없으면 주 경로에 탭이 하나
    /// 늘어난다. 소유 화면이 카드를 완성한 뒤에 띄운다는 전제로 뷰가 onAppear에서 씨앗을
    /// 뿌린다. AI 카드는 전부 기본값 false라 무변화다.
    var startsOpen: Bool = false

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
            // 나간다(확정 요약·재오픈 칩 모두 이 문구를 쓴다).
            return BesirTime.parseDatetime(value)
                .map { ($0.prefix == "arr:" ? "도착 " : "출발 ") + BesirTime.when($0.date) } ?? value
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
            // 접두(도착/출발) + 정규 ISO만 받아들이고 통과하면 정규화해 돌려준다.
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
    var fields: [EditField]
    var isReady: Bool { fields.allSatisfy { $0.chosen != nil } }
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
/// 일곱 동작을 클로저로 묶어 넘긴다. 값은 Store/AIAssistant에만 있고, 결합이 이 어댑터로
/// 수축한다(네 편집 화면이 같은 카드를 쓰려면 뷰가 특정 소유자를 가져선 안 된다).
struct EditCardActions {
    var chooseValue: @MainActor (UUID, String) -> Void
    var rechooseTimeBasis: @MainActor (UUID, ScheduleAnchor) -> Void
    var chooseTime: @MainActor (UUID, ScheduleAnchor, Date) -> Bool
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
