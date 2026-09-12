import Foundation
import Network
import Security

/// 카카오맵 HTML을 https://localhost:PORT 로 서빙하는 초소형 로컬 HTTPS 서버.
/// - WKWebView의 loadHTMLString은 외부 스크립트(카카오 SDK)를 로드하지 못한다.
/// - 카카오 SDK는 엔진/타일을 프로토콜-상대경로(//...)로 부르므로, 페이지가 http면
///   http로 내려가 ATS/네트워크에 막힌다. 따라서 페이지 자체를 HTTPS로 서빙한다.
/// TLS 신원은 번들에 포함한 self-signed 인증서(localhost.p12, iOS·macOS 공용)를 쓴다.
final class LocalMapServer {
    static let shared = LocalMapServer()
    static let port: UInt16 = 8089

    private var listener: NWListener?
    private var html = "<html><body>map</body></html>"
    private var started = false

    var baseURL: URL { URL(string: "https://localhost:\(Self.port)/")! }

    func start(jsKey: String) {
        if let url = Bundle.main.url(forResource: "map", withExtension: "html"),
           let raw = try? String(contentsOf: url, encoding: .utf8) {
            html = raw.replacingOccurrences(of: "__APPKEY__", with: jsKey)
        }
        guard !started else { return }

        guard let identity = loadTLSIdentity() else {
            NSLog("LocalMapServer: TLS 신원 로드 실패")
            return
        }
        started = true
        do {
            let tls = NWProtocolTLS.Options()
            sec_protocol_options_set_local_identity(tls.securityProtocolOptions, identity)
            let params = NWParameters(tls: tls)
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: Self.port)!)
            listener.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
            listener.start(queue: .global(qos: .userInitiated))
            self.listener = listener
        } catch {
            NSLog("LocalMapServer 시작 실패: \(error)")
            started = false
        }
    }

    private func loadTLSIdentity() -> sec_identity_t? {
        guard let url = Bundle.main.url(forResource: "localhost", withExtension: "p12"),
              let data = try? Data(contentsOf: url) else {
            NSLog("LocalMapServer: localhost.p12 없음")
            return nil
        }
        let options = [kSecImportExportPassphrase as String: "besir"]
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let arr = items as? [[String: Any]],
              let identityRef = arr.first?[kSecImportItemIdentity as String] else {
            NSLog("LocalMapServer: SecPKCS12Import 실패 (\(status))")
            return nil
        }
        return sec_identity_create(identityRef as! SecIdentity)
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global(qos: .userInitiated))
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] _, _, _, _ in
            guard let self else { conn.cancel(); return }
            let body = Data(self.html.utf8)
            let header = "HTTP/1.1 200 OK\r\n" +
                         "Content-Type: text/html; charset=utf-8\r\n" +
                         "Content-Length: \(body.count)\r\n" +
                         "Connection: close\r\n\r\n"
            var resp = Data(header.utf8)
            resp.append(body)
            conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
        }
    }
}
