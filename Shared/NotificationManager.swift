import Foundation
import UserNotifications

/// 로컬 알림(알람) 예약/취소.
@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var authorized = false
    @Published var lastError: String?

    private var center: UNUserNotificationCenter? {
        // 번들 식별자가 없으면(예: 비번들 실행) UNUserNotificationCenter 접근이 크래시 나므로 가드.
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    func bootstrap() {
        guard let center else {
            lastError = "번들 식별자가 없어 알림을 사용할 수 없습니다."
            return
        }
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                self.authorized = granted
                if let error { self.lastError = error.localizedDescription }
            }
        }
    }

    /// 지정 시각에 알림을 예약하고 식별자를 반환한다. 실패 시 nil.
    @discardableResult
    func schedule(title: String, body: String, at date: Date, id: String = UUID().uuidString) -> String? {
        guard let center else { return nil }
        guard date > Date() else { return nil }   // 과거 시각은 예약하지 않음

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { Task { @MainActor in self.lastError = error.localizedDescription } }
        }
        return id
    }

    func cancel(id: String) {
        center?.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// 예약 대기 중인 알림을 전부 취소한다(Store가 "가까운 것부터 N건"만 다시 채울 때 사용).
    func cancelAll() {
        center?.removeAllPendingNotificationRequests()
    }

    // 앱이 포그라운드일 때도 배너를 보여준다.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
