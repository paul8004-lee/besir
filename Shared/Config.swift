import Foundation

/// 외부 API 설정.
/// `~/Library/Application Support/besir/config.json` 에서 읽는다.
///
/// 보안 설계: Kakao REST 키·ODsay 키는 **앱에 두지 않고** Cloudflare Worker 프록시가 보관한다.
/// 앱은 `proxyBaseURL` + `appToken` 으로 프록시만 호출한다(키 노출 없음).
/// Kakao JavaScript 키는 지도 SDK가 클라이언트에서 로드해야 해 불가피하게 앱에 두되,
/// 카카오 콘솔의 도메인 잠금(`https://localhost:8089`)으로 보호한다.
struct AppConfig: Codable {
    /// 지도 렌더링용 Kakao JS 키(클라이언트 노출, 도메인 잠금으로 보호).
    var kakaoJsKey: String = ""
    /// 프록시 서버 주소. 예: `https://besir-proxy.<계정>.workers.dev`
    var proxyBaseURL: String = ""
    /// 프록시 호출용 앱 토큰(비밀이 아니라 식별·차단용).
    var appToken: String = ""
    /// 구글 캘린더 연동용 iOS OAuth 클라이언트 ID(예: `xxx.apps.googleusercontent.com`).
    var googleClientID: String = ""
    /// 일정 생성 시 구글 캘린더에 자동 등록할지(기본 ON).
    var autoAddToCalendar: Bool = true

    // 구버전 config.json의 kakaoRestKey/odsayKey 키는 JSONDecoder가 무시한다.
    // preferredMode/preferredBuffer/preferredNotify도 같은 취급이다 — 저장된 선호가 조용히
    // 적용되다 여유 0분짜리 35건이 등록되고도 아무도 모른 사고(b303f41) 뒤, 값이 없으면
    // 추측하지 않고 앱이 그 자리에서 묻는 쪽으로 바꿨다. 기기에 남은 옛 키는 읽지 않는다.

    var hasKakaoJs: Bool { !kakaoJsKey.trimmingCharacters(in: .whitespaces).isEmpty }
    var hasGoogleCalendar: Bool { !googleClientID.trimmingCharacters(in: .whitespaces).isEmpty }

    /// 프록시(자동차 길찾기·대중교통·장소검색)가 설정돼 있는지.
    var hasProxy: Bool {
        !proxyBaseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !appToken.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// 프록시 GET 요청을 만든다. 경로(path)와 쿼리를 받아 토큰 헤더를 붙인다.
    func proxyRequest(_ path: String, query: [URLQueryItem]) -> URLRequest? {
        let base = proxyBaseURL.trimmingCharacters(in: .whitespaces)
        guard hasProxy, var comps = URLComponents(string: base) else { return nil }
        comps.path = (comps.path.hasSuffix("/") ? String(comps.path.dropLast()) : comps.path) + path
        comps.queryItems = query
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        return req
    }

    /// 프록시 POST 요청을 만든다(예: Claude 대화형 일정 등록 `/claude/messages`).
    func proxyPOSTRequest(_ path: String, body: Data) -> URLRequest? {
        let base = proxyBaseURL.trimmingCharacters(in: .whitespaces)
        guard hasProxy, var comps = URLComponents(string: base) else { return nil }
        comps.path = (comps.path.hasSuffix("/") ? String(comps.path.dropLast()) : comps.path) + path
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(appToken, forHTTPHeaderField: "X-App-Token")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        return req
    }

    /// LLM(대화형 일정 등록)을 쓸 수 있는지. 키는 프록시가 보관하므로 프록시 설정 여부로 판단.
    var hasAI: Bool { hasProxy }

    static let supportDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("besir", isDirectory: true)
    }()

    static var configURL: URL { supportDirectory.appendingPathComponent("config.json") }

    /// 앱에 내장하는 기본 설정(출시본의 정상 기본값).
    /// - 비밀이 아닌 값만 내장한다: 프록시 주소, 앱 토큰(식별·차단용), 카카오 JS 키(도메인 잠금).
    /// - **REST·ODsay 키는 여기 없음** — Cloudflare Worker 프록시(서버)에만 존재하므로 앱스토어 배포 안전.
    /// - 사용자가 설정 화면에서 값을 저장하면 그쪽(config.json)이 우선한다.
    static let bundledDefaults = AppConfig(
        kakaoJsKey: "c5f9b16607bb62ac6a75807dd5027dd2",
        proxyBaseURL: "https://besir-proxy.paul8004.workers.dev",
        appToken: "7eb36a1fe1b459e9c717e9317f005a246dd576933badb8e7",
        googleClientID: "453862479563-ulgiuqvfme7bfeql859k3hla33k2vkbv.apps.googleusercontent.com"
    )

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configURL),
              let cfg = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return bundledDefaults   // 설정 파일 없으면 내장 기본값 사용
        }
        return cfg
    }

    func save() {
        try? FileManager.default.createDirectory(at: Self.supportDirectory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: Self.configURL)
        }
    }
}

extension AppConfig {
    private enum CodingKeys: String, CodingKey {
        case kakaoJsKey, proxyBaseURL, appToken, googleClientID, autoAddToCalendar
    }
    // 누락된 키는 기본값으로(새 필드 추가 시 옛 config.json이 깨지지 않게).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            kakaoJsKey: (try? c.decode(String.self, forKey: .kakaoJsKey)) ?? "",
            proxyBaseURL: (try? c.decode(String.self, forKey: .proxyBaseURL)) ?? "",
            appToken: (try? c.decode(String.self, forKey: .appToken)) ?? "",
            googleClientID: (try? c.decode(String.self, forKey: .googleClientID)) ?? "",
            autoAddToCalendar: (try? c.decode(Bool.self, forKey: .autoAddToCalendar)) ?? true
        )
    }
}
