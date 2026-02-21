import Foundation

// MARK: - WiFi Entry

struct WiFiEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var ssid: String = ""
    var message: String = ""
    var isWork: Bool = false
}

// MARK: - UserDefaults Keys

struct AppDefaults {
    static let slackToken = "slackToken"
    static let slackChannel = "slackChannel"
    static let lastWorkNotification = "lastWorkNotification"
    static let migrationComplete = "migrationComplete"
    static let wifiEntries = "wifiEntries"

    // Per-SSID auto check-in tracking: "autoCheckIn_<ssid>" → Date
    static func autoCheckInKey(for ssid: String) -> String { "autoCheckIn_\(ssid)" }
    static let weatherEnabled = "weatherEnabled"
    static let temperatureUnit = "temperatureUnit" // "celsius" or "fahrenheit"
}
