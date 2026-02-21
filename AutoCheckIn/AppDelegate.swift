import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 AutoCheckIn started")

        // Migration must run before anything else
        MigrationService.shared.migrateFromLegacyFiles()

        Task {
            await NotificationService.shared.requestPermissions()
        }

        // WiFi monitoring is started by WiFiMonitorViewModel
        print("✅ App initialization complete")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("👋 AutoCheckIn stopping")
        WiFiMonitorService.shared.stopMonitoring()
    }
}
