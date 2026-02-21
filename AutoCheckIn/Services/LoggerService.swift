import Foundation
import AppKit

class LoggerService {
    static let shared = LoggerService()

    private let logFileURL: URL

    private init() {
        logFileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("autocheckin_log.txt")

        print("📝 Log file: \(logFileURL.path)")
    }

    func logNetworkChange(from previousSSID: String?, to newSSID: String?) {
        Task {
            await logNetworkChangeAsync(from: previousSSID, to: newSSID)
        }
    }

    private func logNetworkChangeAsync(from previousSSID: String?, to newSSID: String?) async {
        let timestamp = formatTimestamp(Date())
        let message = formatMessage(from: previousSSID, to: newSSID)
        let logLine = "[\(timestamp)] \(message)\n"

        do {
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            let existingContent = try String(contentsOf: logFileURL, encoding: .utf8)
            try (existingContent + logLine).write(to: logFileURL, atomically: true, encoding: .utf8)
            print("📝 Logged: \(message)")
        } catch {
            print("❌ Failed to write to log: \(error)")
        }
    }

    private func formatMessage(from previousSSID: String?, to newSSID: String?) -> String {
        if let newSSID = newSSID {
            if let previousSSID = previousSSID {
                return "Switched from '\(previousSSID)' to '\(newSSID)'"
            } else {
                return "Connected to: \(newSSID)"
            }
        } else {
            if let previousSSID = previousSSID {
                return "Disconnected from: \(previousSSID)"
            } else {
                return "No WiFi connection"
            }
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    func logSlackCheckIn(message: String, channel: String) {
        Task {
            await logSlackCheckInAsync(message: message, channel: channel)
        }
    }

    private func logSlackCheckInAsync(message: String, channel: String) async {
        let timestamp = formatTimestamp(Date())
        let logLine = "[\(timestamp)] Slack check-in → \(channel): \(message)\n"

        do {
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            let existingContent = try String(contentsOf: logFileURL, encoding: .utf8)
            try (existingContent + logLine).write(to: logFileURL, atomically: true, encoding: .utf8)
            print("📝 Logged Slack check-in")
        } catch {
            print("❌ Failed to log Slack check-in: \(error)")
        }
    }

    func logDebug(_ message: String) {
        Task {
            await logDebugAsync(message)
        }
    }

    private func logDebugAsync(_ message: String) async {
        let timestamp = formatTimestamp(Date())
        let logLine = "[\(timestamp)] [DEBUG] \(message)\n"

        do {
            if !FileManager.default.fileExists(atPath: logFileURL.path) {
                try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            }
            let existingContent = try String(contentsOf: logFileURL, encoding: .utf8)
            try (existingContent + logLine).write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to log debug: \(error)")
        }
    }

    func openLogFile() {
        NSWorkspace.shared.open(logFileURL)
    }
}
