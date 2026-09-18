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
    static let whenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E) a h시 m분"
        return f
    }()
    static func when(_ d: Date) -> String { whenFormatter.string(from: d) }

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
/// 되묻는 주제가 모델이 아니라 앱인 이유: 이 모델은 선언된 선택 인자를 비워두지 못하고 전부
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
    enum Kind { case place, mode, buffer, notify, weeks, title, datetime }
    struct Option: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
    let id = UUID()
    /// 툴 인자 이름. 확인 시 이 키로 값이 실린다.
    let key: String
    let kind: Kind
    let label: String
    let options: [Option]
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

    var chosenLabel: String? {
        guard let chosen else { return nil }
        return options.first { $0.value == chosen }?.label ?? Self.customLabel(kind, chosen)
    }
    static func customLabel(_ kind: Kind, _ value: String) -> String {
        switch kind {
        case .buffer, .notify: return "\(value)분"
        case .weeks: return "\(value)주"
        case .place, .mode, .title: return value
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
        case .place, .title: return t
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
