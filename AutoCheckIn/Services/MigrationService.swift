import Foundation

class MigrationService {
    static let shared = MigrationService()

    private init() {}

    func migrateFromLegacyFiles() {
        // Phase 1: Legacy file migration (runs once on old installations)
        if !UserDefaults.standard.bool(forKey: AppDefaults.migrationComplete) {
            runLegacyFileMigration()
            UserDefaults.standard.set(true, forKey: AppDefaults.migrationComplete)
        }

        // Phase 2: Migrate wifi1/2/3 keys → wifiEntries (idempotent)
        migrateWifiEntriesToNewFormat()

        // Phase 3: Set weather defaults if not yet configured
        setWeatherDefaults()
    }

    private func runLegacyFileMigration() {
        print("🔄 Running legacy file migration...")

        let oldDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("code/wifi/old-stuff")

        var migrated = false

        let tokenPath = oldDir.appendingPathComponent(".wifi_slack_token")
        if FileManager.default.fileExists(atPath: tokenPath.path),
           let token = try? String(contentsOf: tokenPath, encoding: .utf8)
               .trimmingCharacters(in: .whitespacesAndNewlines),
           !token.isEmpty {
            UserDefaults.standard.set(token, forKey: AppDefaults.slackToken)
            print("✅ Migrated Slack token")
            migrated = true
        }

        let channelPath = oldDir.appendingPathComponent(".wifi_slack_channel")
        if FileManager.default.fileExists(atPath: channelPath.path),
           let channel = try? String(contentsOf: channelPath, encoding: .utf8)
               .trimmingCharacters(in: .whitespacesAndNewlines),
           !channel.isEmpty {
            UserDefaults.standard.set(channel, forKey: AppDefaults.slackChannel)
            print("✅ Migrated Slack channel: \(channel)")
            migrated = true
        }

        if migrated {
            print("✅ Legacy file migration completed")
        } else {
            print("ℹ️ No legacy files found")
        }
    }

    private func migrateWifiEntriesToNewFormat() {
        // Skip if already migrated to new format
        guard UserDefaults.standard.data(forKey: AppDefaults.wifiEntries) == nil else {
            return
        }

        print("🔄 Migrating WiFi entries to new format...")
        var entries: [WiFiEntry] = []

        for i in 1...3 {
            let name = UserDefaults.standard.string(forKey: "wifi\(i)Name") ?? ""
            let message = UserDefaults.standard.string(forKey: "wifi\(i)Prefix") ?? ""
            let isWork = UserDefaults.standard.bool(forKey: "wifi\(i)IsWork")

            if !name.isEmpty {
                entries.append(WiFiEntry(ssid: name, message: message, isWork: isWork))
                print("✅ Migrated WiFi \(i): '\(name)'")
            }

            UserDefaults.standard.removeObject(forKey: "wifi\(i)Name")
            UserDefaults.standard.removeObject(forKey: "wifi\(i)Prefix")
            UserDefaults.standard.removeObject(forKey: "wifi\(i)IsWork")
        }

        // Remove deprecated keys
        UserDefaults.standard.removeObject(forKey: "workWifiName")
        UserDefaults.standard.removeObject(forKey: "customMessage")

        if entries.isEmpty {
            entries = [WiFiEntry()]
        }

        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: AppDefaults.wifiEntries)
            print("✅ WiFi entries migrated (\(entries.count) entries)")
        }
    }

    private func setWeatherDefaults() {
        if UserDefaults.standard.object(forKey: AppDefaults.weatherEnabled) == nil {
            UserDefaults.standard.set(true, forKey: AppDefaults.weatherEnabled)
        }
        if UserDefaults.standard.object(forKey: AppDefaults.temperatureUnit) == nil {
            UserDefaults.standard.set("celsius", forKey: AppDefaults.temperatureUnit)
        }
    }
}
