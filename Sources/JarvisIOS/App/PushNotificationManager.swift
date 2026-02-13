import Foundation
import UserNotifications
import SwiftUI

// MARK: - Manager
@MainActor
final class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    private override init() { super.init() }

    func register() {
        UNUserNotificationCenter.current().delegate = self
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "didRequestNotificationPermission") == false {
            requestAuthorization { _ in
                defaults.set(true, forKey: "didRequestNotificationPermission")
            }
        }
    }

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func scheduleDailyNotifications(
        morning: Bool,
        afternoon: Bool,
        evening: Bool,
        quietHoursEnabled: Bool,
        quietStart: String,
        quietEnd: String
    ) {
        func validHM(_ s: String) -> Bool { let comps = s.split(separator: ":"); return comps.count == 2 && Int(comps[0]) != nil && Int(comps[1]) != nil }
        let quietStart = validHM(quietStart) ? quietStart : "22:00"
        let quietEnd = validHM(quietEnd) ? quietEnd : "07:00"

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        configureCategories()

        func isWithinQuietHours(hour: Int, minute: Int) -> Bool {
            guard quietHoursEnabled else { return false }
            let (sH, sM) = Self.parseHM(quietStart)
            let (eH, eM) = Self.parseHM(quietEnd)
            let start = sH * 60 + sM
            let end = eH * 60 + eM
            let t = hour * 60 + minute
            if start == end { return false }
            if start < end { // same day
                return (t >= start && t < end)
            } else { // spans midnight
                return (t >= start || t < end)
            }
        }

        if morning && !isWithinQuietHours(hour: 8, minute: 0) {
            let body = PushMessage.motivationalRandom()
            scheduleDaily(id: "morning_motivation", hour: 8, minute: 0, title: "Morning Motivation", body: body, category: "motivational")
        }
        if afternoon && !isWithinQuietHours(hour: 12, minute: 0) {
            let body = PushMessage.checkinRandom()
            scheduleDaily(id: "midday_checkin", hour: 12, minute: 0, title: "Mid-day Check-in", body: body, category: "checkin")
        }
        if evening && !isWithinQuietHours(hour: 18, minute: 0) {
            let body = PushMessage.reminders.randomElement() ?? "Evening reminder"
            scheduleDaily(id: "evening_reminder", hour: 18, minute: 0, title: "Evening Reminder", body: body, category: "reminder")
        }

        // Random cheer at a random non-quiet time between 9am-5pm
        var randomHour = Int.random(in: 9...16)
        if isWithinQuietHours(hour: randomHour, minute: 0) {
            randomHour = 10 // fallback
        }
        let cheer = PushMessage.random()
        scheduleDaily(id: "random_cheer", hour: randomHour, minute: 0, title: "Jarvis", body: cheer, category: "celebration")
    }

    private func scheduleDaily(id: String, hour: Int, minute: Int, title: String, body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category

        var date = DateComponents()
        date.hour = hour
        date.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        if #available(iOS 17.0, *) {
            Task {
                do { try await UNUserNotificationCenter.current().add(request) } catch { }
            }
        } else {
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }

    func scheduleTestNotifications() {
        configureCategories()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for (idx, body) in [
            PushMessage.motivationalRandom(),
            PushMessage.checkinRandom(),
            PushMessage.reminders.randomElement() ?? "Reminder"
        ].enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Jarvis Test \(idx+1)"
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "test"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(5 + idx*5), repeats: false)
            let req = UNNotificationRequest(identifier: "test_\(idx)", content: content, trigger: trigger)
            if #available(iOS 17.0, *) {
                Task {
                    do { try await center.add(req) } catch { }
                }
            } else {
                center.add(req) { _ in }
            }
        }
    }

    private func configureCategories() {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "motivational", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "reminder", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "checkin", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "celebration", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "quirky", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "gratitude", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "test", actions: [], intentIdentifiers: [], options: [])
        ]
        UNUserNotificationCenter.current().setNotificationCategories(categories)
    }

    static func parseHM(_ value: String) -> (Int, Int) {
        let comps = value.split(separator: ":")
        if comps.count == 2, let h = Int(comps[0]), let m = Int(comps[1]) { return (h, m) }
        return (0, 0)
    }
}

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle taps/responses if needed
    }
}
