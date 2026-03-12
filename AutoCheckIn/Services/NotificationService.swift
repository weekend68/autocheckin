import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermissions() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])

            if granted {
                print("✅ Notification permissions granted")
            } else {
                print("⚠️ Notification permissions denied")
            }
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
        }
    }

    func notifyLocationPermissionDenied() async {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = UserDefaults.standard.object(forKey: AppDefaults.lastLocationDeniedNotification) as? Date {
            if Calendar.current.startOfDay(for: lastDate) >= today {
                print("ℹ️ Already notified about location permission today")
                return
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "AutoCheckIn — åtgärd krävs"
        content.body = "Platstillgång saknas. Inga automatiska incheckningar görs. Aktivera i Systeminställningar → Integritet → Platstjänster."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "locationPermissionDenied",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("🔔 Location permission denied notification sent")
            UserDefaults.standard.set(Date(), forKey: AppDefaults.lastLocationDeniedNotification)
        } catch {
            print("❌ Failed to send location denied notification: \(error)")
        }
    }

    func notifyWorkWiFiConnection(wifiName: String) async {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = UserDefaults.standard.object(forKey: AppDefaults.lastWorkNotification) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if lastDay >= today {
                print("ℹ️ Already notified about work WiFi today")
                return
            }
        }

        let content = UNMutableNotificationContent()
        content.title = "AutoCheckIn"
        content.body = "Connected to work WiFi (\(wifiName))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("🔔 Work WiFi notification sent")
            UserDefaults.standard.set(Date(), forKey: AppDefaults.lastWorkNotification)
        } catch {
            print("❌ Failed to send notification: \(error)")
        }
    }
}
