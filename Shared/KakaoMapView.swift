import SwiftUI
import WebKit
import CoreLocation

/// 카카오맵(JS SDK)을 WKWebView로 표시한다(iOS·macOS 공용).
/// kakaoJsKey 가 있을 때만 사용한다(없으면 호출 측에서 MapKit으로 폴백).
struct KakaoMapView {
    let jsKey: String
    let origin: CLLocationCoordinate2D?
    let destination: CLLocationCoordinate2D
    let destinationName: String
    let mode: TransportMode
    /// 대중교통 등 구간별 실제 경로(도보/지하철/버스). 있으면 색을 나눠 그린다.
    var segments: [RouteSegment] = []

    func makeCoordinator() -> Coordinator { Coordinator() }

    fileprivate func makeWebView(_ coordinator: Coordinator) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.navigationDelegate = coordinator
        #if os(macOS)
        web.setValue(false, forKey: "drawsBackground")
        #else
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        #endif
        LocalMapServer.shared.start(jsKey: jsKey)
        web.load(URLRequest(url: LocalMapServer.shared.baseURL))
        return web
    }

    fileprivate func update(_ web: WKWebView, _ coordinator: Coordinator) {
        coordinator.latestJS = routeJS()
        if coordinator.loaded { web.evaluateJavaScript(routeJS()) }
    }

    private func routeJS() -> String {
        func obj(_ c: CLLocationCoordinate2D) -> String { "{lat:\(c.latitude),lng:\(c.longitude)}" }
        let originJS = origin.map(obj) ?? "null"
        let destJS = "{lat:\(destination.latitude),lng:\(destination.longitude),name:\(jsString(destinationName))}"
        let segsJS = "[" + segments.map { seg in
            let coords = "[" + seg.coords.map(obj).joined(separator: ",") + "]"
            return "{mode:'\(seg.mode.rawValue)',color:'\(seg.color)',coords:\(coords)}"
        }.joined(separator: ",") + "]"
        return "renderRoute({origin:\(originJS),dest:\(destJS),segments:\(segsJS),mode:'\(mode.rawValue)'});"
    }

    private func jsString(_ s: String) -> String {
        let escaped = s.replacingOccurrences(of: "\\", with: "\\\\")
                       .replacingOccurrences(of: "'", with: "\\'")
        return "'\(escaped)'"
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var loaded = false
        var latestJS: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            loaded = true
            if let js = latestJS { webView.evaluateJavaScript(js) }
        }

        // 로컬 HTTPS 서버의 self-signed 인증서를 localhost에 한해 신뢰한다.
        func webView(_ webView: WKWebView,
                     didReceive challenge: URLAuthenticationChallenge,
                     completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if challenge.protectionSpace.host == "localhost",
               let trust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: trust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}

#if os(macOS)
extension KakaoMapView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateNSView(_ web: WKWebView, context: Context) { update(web, context.coordinator) }
}
#else
extension KakaoMapView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { makeWebView(context.coordinator) }
    func updateUIView(_ web: WKWebView, context: Context) { update(web, context.coordinator) }
}
#endif
