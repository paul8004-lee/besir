import Foundation
import AuthenticationServices
import CryptoKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// 구글 캘린더 연동: 이동 일정을 캘린더에 등록/조회/삭제한다.
/// OAuth 2.0 Authorization Code + PKCE (설치형 앱, client secret 불필요).
/// besir가 만든 이벤트는 `extendedProperties.private.besir = "1"` 로 표시해 구분한다.
@MainActor
final class GoogleCalendarService: NSObject {
    let clientID: String
    init(clientID: String) { self.clientID = clientID }

    private var redirectScheme: String {
        let prefix = clientID.replacingOccurrences(of: ".apps.googleusercontent.com", with: "")
        return "com.googleusercontent.apps.\(prefix)"
    }
    private var redirectURI: String { "\(redirectScheme):/oauth2redirect" }
    private let scope = "https://www.googleapis.com/auth/calendar.events"
    static let refreshTokenKey = "besir.google.refreshToken"
    private var refreshKey: String { Self.refreshTokenKey }

    /// 백그라운드(잠금 상태 포함) 동기화에서도 토큰을 읽을 수 있도록 키체인 접근성을 올린다.
    /// 앱 시작 시 한 번 부르면 된다.
    static func prepareForBackgroundAccess() {
        Keychain.upgradeAccessibility(refreshTokenKey)
    }
    private let base = "https://www.googleapis.com/calendar/v3/calendars/primary/events"

    struct GoogleError: LocalizedError { let message: String; var errorDescription: String? { message } }

    /// 한 번이라도 로그인해 refresh token이 있으면 true(무인증 동기화 가능).
    var isConnected: Bool { Keychain.get(refreshKey) != nil }

    func disconnect() { Keychain.delete(refreshKey); Self.cachedToken = nil }

    /// 구글 로그인만 수행해 연결을 맺는다(이벤트 생성 없이 계정 연결용).
    func connect() async throws { _ = try await accessToken(allowInteractive: true) }

    // MARK: - 공개 API

    /// 일정을 캘린더에 등록하고 생성된 이벤트 ID를 반환한다(필요 시 로그인 화면).
    @discardableResult
    func createEvent(for e: ScheduledEvent) async throws -> String {
        let token = try await accessToken(allowInteractive: true)
        let body = eventBody(for: e)
        let (data, resp) = try await send("POST", url: URL(string: base)!, token: token, json: body)
        guard (resp as? HTTPURLResponse).map({ $0.statusCode < 300 }) == true,
              let id = json(data)?["id"] as? String else {
            throw GoogleError(message: "캘린더 등록 실패: \(String(data: data, encoding: .utf8)?.prefix(120) ?? "")")
        }
        return id
    }

    /// 활동(체류형) 블록을 캘린더에 등록한다. ScheduledEvent와 달리 이동시간 계산이 없다.
    @discardableResult
    func createEvent(for a: ActivityBlock) async throws -> String {
        let token = try await accessToken(allowInteractive: true)
        let tz = TimeZone.current.identifier
        let iso = ISO8601DateFormatter()
        var priv: [String: String] = ["besir": "1", "kind": "activity", "title": a.title]
        if let loc = a.location {
            priv["locName"] = loc.name; priv["locAddr"] = loc.address
            // 좌표까지 넣어야 다른 기기의 besir가 캘린더에서 활동을 손실 없이 복원할 수 있다.
            priv["locLat"] = "\(loc.latitude)"; priv["locLng"] = "\(loc.longitude)"
        }
        let body: [String: Any] = [
            "summary": a.title,
            "location": a.location.map { $0.address.isEmpty ? $0.name : $0.address } ?? "",
            "description": "besir",
            "start": ["dateTime": iso.string(from: a.startDate), "timeZone": tz],
            "end": ["dateTime": iso.string(from: a.endDate), "timeZone": tz],
            "extendedProperties": ["private": priv],
            "reminders": ["useDefault": false, "overrides": []]
        ]
        let (data, resp) = try await send("POST", url: URL(string: base)!, token: token, json: body)
        guard (resp as? HTTPURLResponse).map({ $0.statusCode < 300 }) == true,
              let id = json(data)?["id"] as? String else {
            throw GoogleError(message: "캘린더 등록 실패: \(String(data: data, encoding: .utf8)?.prefix(120) ?? "")")
        }
        return id
    }

    /// 캘린더에 올라가 있는 besir 항목 하나의 원본 정보.
    /// ScheduledEvent/ActivityBlock으로 복원되는 것만 봐서는 "복원조차 안 되는 찌꺼기 이벤트"를
    /// 발견할 수 없어(그게 캘린더에만 중복으로 남던 원인), 복원 결과와 별개로 날것 그대로도 돌려준다.
    struct RemoteItem {
        let id: String
        /// "activity"면 활동 블록, 그 외(빈 문자열)면 이동 일정.
        let kind: String
        /// 알림이 하나라도 켜져 있는지(캘린더 기본 알림 사용 중이거나 개별 알림이 설정됨).
        let hasReminder: Bool
    }

    /// besir가 만든 캘린더 항목을 페이지를 넘겨가며 받아, 이동 일정·활동·원본 정보로 함께 돌려준다.
    /// (예전엔 이동 일정만 복원했고 활동은 아무도 대조하지 않아, 캘린더에만 남은 활동이 정리되지 않았다.)
    ///
    /// 조회 실패(오프라인·토큰 만료·HTTP 오류·깨진 본문)는 빈 결과가 아니라 예외로 던진다 —
    /// 동기화는 빈 결과를 "원격이 정말 비었다"로 읽어 로컬 일정을 지우고 알림까지 취소하므로
    /// (2026-09-25 t13 판정 X1), 실패를 빈 척 삼키면 오프라인 콜드스타트 한 번으로 로컬
    /// 데이터가 통째로 지워진다. 정말 비어 있는 캘린더(200 + items 없음/빈 배열)만 빈 결과다.
    func fetchBesirItems() async throws -> (events: [ScheduledEvent], activities: [ActivityBlock], all: [RemoteItem]) {
        guard isConnected else { throw GoogleError(message: "구글 계정 미연결") }
        let token = try await accessToken(allowInteractive: false)
        let items = try await Self.collectPages { pageToken in
            var comps = URLComponents(string: base)!
            comps.queryItems = [
                .init(name: "privateExtendedProperty", value: "besir=1"),
                .init(name: "maxResults", value: "250"),
                .init(name: "singleEvents", value: "true"),
                .init(name: "showDeleted", value: "false")
            ]
            if let pageToken { comps.queryItems?.append(.init(name: "pageToken", value: pageToken)) }
            let (data, resp) = try await send("GET", url: comps.url!, token: token, json: nil)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200 else { throw GoogleError(message: "캘린더 조회 실패 (\(code))") }
            // 200인데 본문을 못 푸는 건 "비어 있다"가 아니라 깨진 응답이다 — 실패로 던진다.
            guard let obj = json(data) else { throw GoogleError(message: "캘린더 응답 해석 실패") }
            return obj
        }
        return (items.compactMap { parse($0) },
                items.compactMap { parseActivity($0) },
                items.compactMap { remoteItem($0) })
    }

    /// 페이지 모으기: `fetchPage`에 페이지 토큰을 넘겨 `nextPageToken`이 끊길 때까지 돌아
    /// `items`를 쌓는다. 왜 도우미인가 — 26주 평일 반복에 왕복까지 붙으면 260건이라 maxResults
    /// 250의 한 페이지로는 끝 10건이 아예 조회되지 않았고(t23 X2), 그러면 동기화가 "원격에
    /// 없다"로 읽어 로컬을 지운다. 통신을 클로저로 주입받는 구조라 가드 드라이버가 통 없이
    /// 이 루프만은 결정적으로 검증할 수 있다.
    static func collectPages(_ fetchPage: (String?) async throws -> [String: Any]) async throws -> [[String: Any]] {
        var items: [[String: Any]] = []
        var pageToken: String?
        repeat {
            let page = try await fetchPage(pageToken)
            items += (page["items"] as? [[String: Any]]) ?? []
            pageToken = page["nextPageToken"] as? String
        } while pageToken != nil
        return items
    }

    /// 이 이벤트의 알림을 모두 끈다(besir 앱에서만 알리기 위함).
    /// 알림 해제 설정을 넣기 전 버전이 만들어둔 이벤트는 구글 캘린더 기본 알림(보통 10분 전)이
    /// 그대로 남아 있어, 애플/구글 캘린더에서도 같이 울린다 — 동기화할 때 이걸로 정리한다.
    func clearReminders(id: String) async throws {
        guard isConnected, let token = try? await accessToken(allowInteractive: false) else { return }
        let (_, resp) = try await send("PATCH", url: URL(string: "\(base)/\(id)")!, token: token,
                                       json: ["reminders": ["useDefault": false, "overrides": []]])
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code < 300 else { throw GoogleError(message: "캘린더 알림 해제 실패 (\(code))") }
    }

    /// 캘린더 이벤트를 삭제한다(무인증, 미연결이면 무시).
    func deleteEvent(id: String) async throws {
        guard isConnected, let token = try? await accessToken(allowInteractive: false) else { return }
        let (_, resp) = try await send("DELETE", url: URL(string: "\(base)/\(id)")!, token: token, json: nil)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code < 300 || code == 404 || code == 410 else {
            throw GoogleError(message: "캘린더 삭제 실패 (\(code))")
        }
    }

    // MARK: - 이벤트 ↔ JSON

    private func eventBody(for e: ScheduledEvent) -> [String: Any] {
        let tz = TimeZone.current.identifier
        let iso = ISO8601DateFormatter()
        let start = e.departureDate ?? e.arrivalDate
        let mins = e.travelSeconds.map { Int(($0 / 60).rounded()) }
        let desc = mins.map { "\(e.mode.title)로 약 \($0)분 · besir" } ?? "\(e.mode.title) · besir"
        var priv: [String: String] = [
            "besir": "1",
            "mode": e.mode.rawValue,
            "buffer": "\(e.bufferMinutes)",
            "notify": "\(e.notifyLeadMinutes)",
            "title": e.title,
            "arrival": "\(e.arrivalDate.timeIntervalSince1970)",
            "destName": e.destination.name,
            "destAddr": e.destination.address,
            "destLat": "\(e.destination.latitude)",
            "destLng": "\(e.destination.longitude)"
        ]
        if let o = e.origin {
            priv["originName"] = o.name; priv["originAddr"] = o.address
            priv["originLat"] = "\(o.latitude)"; priv["originLng"] = "\(o.longitude)"
        }
        return [
            "summary": e.title,
            "location": e.destination.address.isEmpty ? e.destination.name : e.destination.address,
            "description": desc,
            "start": ["dateTime": iso.string(from: start), "timeZone": tz],
            "end": ["dateTime": iso.string(from: e.arrivalDate), "timeZone": tz],
            "extendedProperties": ["private": priv],
            "reminders": ["useDefault": false, "overrides": []]
        ]
    }

    private func parse(_ item: [String: Any]) -> ScheduledEvent? {
        guard let id = item["id"] as? String,
              let ext = item["extendedProperties"] as? [String: Any],
              let p = ext["private"] as? [String: String],
              let modeRaw = p["mode"], let mode = TransportMode(rawValue: modeRaw),
              let arrivalStr = p["arrival"], let arrival = Double(arrivalStr),
              let destLat = Double(p["destLat"] ?? ""), let destLng = Double(p["destLng"] ?? "") else { return nil }
        var origin: Place?
        if let oLat = Double(p["originLat"] ?? ""), let oLng = Double(p["originLng"] ?? "") {
            origin = Place(name: p["originName"] ?? "출발지", address: p["originAddr"] ?? "",
                           latitude: oLat, longitude: oLng)
        }
        let dest = Place(name: p["destName"] ?? "도착지", address: p["destAddr"] ?? "",
                         latitude: destLat, longitude: destLng)
        var e = ScheduledEvent(
            title: p["title"] ?? (item["summary"] as? String) ?? "일정",
            origin: origin, destination: dest,
            arrivalDate: Date(timeIntervalSince1970: arrival),
            mode: mode,
            bufferMinutes: Int(p["buffer"] ?? "5") ?? 5,
            notifyLeadMinutes: Int(p["notify"] ?? "10") ?? 10)
        e.googleEventId = id
        return e
    }

    /// 활동(체류형) 블록으로 복원한다. `kind=activity`로 표시된 항목만 대상이라
    /// 이동 일정을 복원하는 `parse`와 서로 겹치지 않는다.
    private func parseActivity(_ item: [String: Any]) -> ActivityBlock? {
        guard let id = item["id"] as? String,
              let p = (item["extendedProperties"] as? [String: Any])?["private"] as? [String: String],
              p["kind"] == "activity",
              let start = Self.dateTime(item["start"]), let end = Self.dateTime(item["end"]) else { return nil }
        // 좌표는 이 필드를 넣기 전 버전이 만든 항목에는 없다 — 그 경우 장소 없이 복원한다.
        var place: Place?
        if let lat = Double(p["locLat"] ?? ""), let lng = Double(p["locLng"] ?? "") {
            place = Place(name: p["locName"] ?? "", address: p["locAddr"] ?? "", latitude: lat, longitude: lng)
        }
        var a = ActivityBlock(title: p["title"] ?? (item["summary"] as? String) ?? "활동",
                              location: place, startDate: start, endDate: end)
        a.googleEventId = id
        return a
    }

    /// 복원 여부와 무관하게 항목의 id·종류·알림 상태만 뽑는다(중복 정리·알림 해제용).
    private func remoteItem(_ item: [String: Any]) -> RemoteItem? {
        guard let id = item["id"] as? String else { return nil }
        let p = (item["extendedProperties"] as? [String: Any])?["private"] as? [String: String] ?? [:]
        let reminders = item["reminders"] as? [String: Any]
        // useDefault를 아예 안 보내면 구글은 캘린더 기본 알림을 쓴다 — 없을 때 true로 봐야 맞다.
        let useDefault = reminders?["useDefault"] as? Bool ?? true
        let overrides = reminders?["overrides"] as? [[String: Any]] ?? []
        return RemoteItem(id: id, kind: p["kind"] ?? "", hasReminder: useDefault || !overrides.isEmpty)
    }

    private static let itemDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f
    }()

    /// 구글의 `{"dateTime": "2026-09-10T09:00:00+09:00"}` 형태에서 Date를 뽑는다.
    /// 종일 일정(`date`만 있음)은 besir가 만들지 않으므로 nil로 둔다.
    private static func dateTime(_ any: Any?) -> Date? {
        guard let obj = any as? [String: Any], let s = obj["dateTime"] as? String else { return nil }
        return itemDateFormatter.date(from: s)
    }

    // MARK: - 토큰

    /// 액세스 토큰 캐시(만료 전까지 재사용).
    /// GoogleCalendarService는 `store.gcal`을 읽을 때마다 새로 만들어지는 값 객체라 인스턴스에
    /// 캐시해두면 아무 소용이 없어 타입 단위로 둔다. 이게 없으면 캘린더 API 호출 하나마다
    /// OAuth refresh 왕복이 한 번씩 더 붙어 — 반복 일정 60건을 등록하면 60번이 아니라 120번의
    /// 네트워크 요청이 나가 등록이 몇 배로 느려지고 구글 쪽 요청 제한에도 걸리기 쉬웠다.
    private static var cachedToken: (value: String, expiry: Date)?

    private func accessToken(allowInteractive: Bool) async throws -> String {
        // 만료 1분 전부터는 새로 받는다(호출 도중 만료되는 걸 방지).
        if let cached = Self.cachedToken, cached.expiry > Date().addingTimeInterval(60) {
            return cached.value
        }
        if let refresh = Keychain.get(refreshKey),
           let token = try? await refreshAccessToken(refresh) {
            return token
        }
        guard allowInteractive else { throw GoogleError(message: "구글 계정 미연결") }
        return try await interactiveAuth()
    }

    /// 응답의 expires_in(초)만큼 캐시한다. 값이 없으면 구글 기본값인 1시간으로 잡는다.
    private func cacheToken(_ token: String, expiresIn: Any?) {
        let seconds = (expiresIn as? Double) ?? (expiresIn as? Int).map(Double.init) ?? 3600
        Self.cachedToken = (token, Date().addingTimeInterval(seconds))
    }

    private func refreshAccessToken(_ refresh: String) async throws -> String {
        let (data, resp) = try await postForm(URL(string: "https://oauth2.googleapis.com/token")!, [
            "client_id": clientID, "refresh_token": refresh, "grant_type": "refresh_token"
        ])
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let obj = json(data), let token = obj["access_token"] as? String else {
            throw GoogleError(message: "토큰 갱신 실패")
        }
        cacheToken(token, expiresIn: obj["expires_in"])
        return token
    }

    private func interactiveAuth() async throws -> String {
        let verifier = Self.randomURLSafe(64)
        let challenge = Self.base64url(Data(SHA256.hash(data: Data(verifier.utf8))))
        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "response_type", value: "code"),
            .init(name: "scope", value: scope),
            .init(name: "code_challenge", value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "access_type", value: "offline"),
            .init(name: "prompt", value: "consent")
        ]
        let code = try await runWebAuth(url: comps.url!)
        let (data, resp) = try await postForm(URL(string: "https://oauth2.googleapis.com/token")!, [
            "client_id": clientID, "code": code, "code_verifier": verifier,
            "redirect_uri": redirectURI, "grant_type": "authorization_code"
        ])
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let obj = json(data), let token = obj["access_token"] as? String else {
            throw GoogleError(message: "토큰 교환 실패")
        }
        if let refresh = obj["refresh_token"] as? String { Keychain.set(refresh, key: refreshKey) }
        cacheToken(token, expiresIn: obj["expires_in"])
        return token
    }

    private func runWebAuth(url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { callback, error in
                if let error { cont.resume(throwing: error); return }
                guard let callback,
                      let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?
                                  .queryItems?.first(where: { $0.name == "code" })?.value else {
                    cont.resume(throwing: GoogleError(message: "인증이 취소되었습니다.")); return
                }
                cont.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() { cont.resume(throwing: GoogleError(message: "인증 세션을 시작할 수 없습니다.")) }
        }
    }

    // MARK: - HTTP helpers

    private func send(_ method: String, url: URL, token: String, json body: [String: Any]?) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return try await URLSession.shared.data(for: req)
    }
    private func postForm(_ url: URL, _ fields: [String: String]) async throws -> (Data, URLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = fields.map { "\($0.key)=\(Self.escape($0.value))" }.joined(separator: "&").data(using: .utf8)
        return try await URLSession.shared.data(for: req)
    }
    private func json(_ data: Data) -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    private static let allowed = CharacterSet(charactersIn:
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    private static func escape(_ s: String) -> String { s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s }
    private static func randomURLSafe(_ n: Int) -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return String((0..<n).map { _ in chars.randomElement()! })
    }
    private static func base64url(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}

extension GoogleCalendarService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            #if os(iOS)
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
            #else
            return NSApplication.shared.windows.first ?? ASPresentationAnchor()
            #endif
        }
    }
}

/// 리프레시 토큰 보관용 최소 Keychain 래퍼.
enum Keychain {
    /// 백그라운드 동기화는 화면이 잠긴 상태에서도 돌 수 있어야 한다. 키체인 기본값
    /// (`kSecAttrAccessibleWhenUnlocked`)이면 잠금 중엔 토큰을 못 읽어 동기화가 통째로 실패하므로,
    /// "부팅 후 한 번이라도 잠금 해제했으면 읽기 가능"으로 저장한다(백그라운드 자격증명의 표준 선택).
    private static let accessibility = kSecAttrAccessibleAfterFirstUnlock

    static func set(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = accessibility
        SecItemAdd(add as CFDictionary, nil)
    }

    /// 예전 버전이 기본 접근성으로 저장해둔 항목을 위 접근성으로 올린다(이미 올라가 있으면 무해).
    /// 잠금 해제 상태에서 한 번 실행되면 그 뒤로는 잠금 중에도 읽을 수 있게 된다.
    static func upgradeAccessibility(_ key: String) {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key]
        SecItemUpdate(query as CFDictionary,
                      [kSecAttrAccessible as String: accessibility] as CFDictionary)
    }
    static func get(_ key: String) -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                     kSecAttrAccount as String: key,
                                     kSecReturnData as String: true,
                                     kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func delete(_ key: String) {
        SecItemDelete([kSecClass as String: kSecClassGenericPassword,
                       kSecAttrAccount as String: key] as CFDictionary)
    }
}
