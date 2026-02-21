import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var slackToken: String = ""
    @Published var slackChannel: String = ""
    @Published var wifiEntries: [WiFiEntry] = [WiFiEntry()]
    @Published var weatherEnabled: Bool = true
    @Published var temperatureUnit: String = "celsius"

    @Published var testResult: String = ""
    @Published var isTesting: Bool = false

    private let slackService = SlackService.shared

    init() {
        loadSettings()
    }

    func loadSettings() {
        slackToken = UserDefaults.standard.string(forKey: AppDefaults.slackToken) ?? ""
        slackChannel = UserDefaults.standard.string(forKey: AppDefaults.slackChannel) ?? ""

        if let data = UserDefaults.standard.data(forKey: AppDefaults.wifiEntries),
           let entries = try? JSONDecoder().decode([WiFiEntry].self, from: data),
           !entries.isEmpty {
            wifiEntries = entries
        } else {
            wifiEntries = [WiFiEntry()]
        }

        let weatherEnabledObj = UserDefaults.standard.object(forKey: AppDefaults.weatherEnabled)
        weatherEnabled = weatherEnabledObj == nil ? true : UserDefaults.standard.bool(forKey: AppDefaults.weatherEnabled)

        temperatureUnit = UserDefaults.standard.string(forKey: AppDefaults.temperatureUnit) ?? "celsius"
    }

    func saveSettings() {
        UserDefaults.standard.set(slackToken, forKey: AppDefaults.slackToken)
        UserDefaults.standard.set(slackChannel, forKey: AppDefaults.slackChannel)

        if let data = try? JSONEncoder().encode(wifiEntries) {
            UserDefaults.standard.set(data, forKey: AppDefaults.wifiEntries)
        }

        UserDefaults.standard.set(weatherEnabled, forKey: AppDefaults.weatherEnabled)
        UserDefaults.standard.set(temperatureUnit, forKey: AppDefaults.temperatureUnit)

        print("✅ Settings saved")
    }

    func addWifiEntry() {
        wifiEntries.append(WiFiEntry())
    }

    func removeWifiEntry(at index: Int) {
        guard wifiEntries.count > 1 else { return }
        wifiEntries.remove(at: index)
    }

    func resetAutoCheckIns() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let cleared = allKeys.filter { $0.hasPrefix("autoCheckIn_") }
        cleared.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        let ssids = cleared.map { $0.replacingOccurrences(of: "autoCheckIn_", with: "") }
        LoggerService.shared.logDebug("Auto check-in flag cleared for: \(ssids.joined(separator: ", "))")
        print("🔄 Auto check-in flag cleared for: \(ssids.joined(separator: ", "))")
    }

    func testSlackConnection() {
        guard !slackToken.isEmpty else {
            testResult = "❌ Slack token missing"
            return
        }

        guard !slackChannel.isEmpty else {
            testResult = "❌ Slack channel missing"
            return
        }

        isTesting = true
        testResult = "Testing connection..."

        Task {
            let result = await slackService.testConnection(
                token: slackToken,
                channel: slackChannel
            )

            await MainActor.run {
                isTesting = false

                switch result {
                case .success(let message):
                    testResult = message
                case .failure(let error):
                    testResult = "❌ \(error.localizedDescription)"
                }
            }
        }
    }
}
