import Foundation
import UserNotifications

struct WashTimer: Codable, Identifiable {
    let id: String
    let printId: String
    let printLabel: String
    let endDate: Date

    var remaining: TimeInterval { endDate.timeIntervalSinceNow }
    var isExpired: Bool { remaining <= 0 }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let timersKey = "activeWashTimers"
    private let categoryId = "WASH_TIMER"
    private let dismissActionId = "DISMISS"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    private func registerCategories() {
        let dismissAction = UNNotificationAction(
            identifier: dismissActionId,
            title: "Done",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleWashTimer(printId: String, label: String, minutes: Int) {
        let id = UUID().uuidString
        let duration = TimeInterval(minutes * 60)

        let content = UNMutableNotificationContent()
        content.title = "Wash complete"
        content.body = label
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )

        let endDate = Date().addingTimeInterval(duration)
        var timers = loadTimers()
        timers.append(WashTimer(id: id, printId: printId, printLabel: label, endDate: endDate))
        saveTimers(timers)
    }

    func cancelTimer(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        var timers = loadTimers()
        timers.removeAll { $0.id == id }
        saveTimers(timers)
    }

    func activeTimer(for printId: String) -> WashTimer? {
        loadTimers().first { $0.printId == printId }
    }

    func loadTimers() -> [WashTimer] {
        guard let data = UserDefaults.standard.data(forKey: timersKey),
              let timers = try? JSONDecoder().decode([WashTimer].self, from: data) else {
            return []
        }
        let active = timers.filter { !$0.isExpired }
        if active.count != timers.count { saveTimers(active) }
        return active
    }

    private func saveTimers(_ timers: [WashTimer]) {
        if let data = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(data, forKey: timersKey)
        }
    }

    // Show banner + sound when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        removeExpiredTimer(id: notification.request.identifier)
        return [.banner, .sound]
    }

    // Handle action button tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        removeExpiredTimer(id: response.notification.request.identifier)
    }

    private func removeExpiredTimer(id: String) {
        var timers = loadTimers()
        timers.removeAll { $0.id == id }
        saveTimers(timers)
    }
}
