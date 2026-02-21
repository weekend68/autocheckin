import Foundation
import Combine

class WiFiMonitorViewModel: ObservableObject {
    @Published var currentSSID: String?
    @Published var isMonitoring: Bool = false

    private let wifiService = WiFiMonitorService.shared
    private let loggerService = LoggerService.shared
    private let notificationService = NotificationService.shared
    private let slackService = SlackService.shared
    private let messageGenerator = MessageGeneratorService.shared

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
        setupWiFiMonitoring()
    }

    private func setupBindings() {
        wifiService.$currentSSID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ssid in
                self?.currentSSID = ssid
            }
            .store(in: &cancellables)

        wifiService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .sink { [weak self] monitoring in
                self?.isMonitoring = monitoring
            }
            .store(in: &cancellables)

        wifiService.onNetworkChange = { [weak self] previous, new in
            self?.handleNetworkChange(from: previous, to: new)
        }
    }

    private func setupWiFiMonitoring() {
        wifiService.startMonitoring()
    }

    private func handleNetworkChange(from previousSSID: String?, to newSSID: String?) {
        loggerService.logNetworkChange(from: previousSSID, to: newSSID)

        if let newSSID = newSSID {
            checkWorkWiFiConnection(ssid: newSSID, previousSSID: previousSSID)
        }
    }

    private func loadWifiEntries() -> [WiFiEntry] {
        guard let data = UserDefaults.standard.data(forKey: AppDefaults.wifiEntries),
              let entries = try? JSONDecoder().decode([WiFiEntry].self, from: data) else {
            return []
        }
        return entries
    }

    private func checkWorkWiFiConnection(ssid: String, previousSSID: String?) {
        let entries = loadWifiEntries()
        let match = entries.first { !$0.ssid.isEmpty && $0.ssid == ssid && $0.isWork }

        guard let match = match else {
            loggerService.logDebug("No work WiFi match for '\(ssid)'")
            return
        }

        if previousSSID != match.ssid {
            loggerService.logDebug("Work WiFi match: '\(match.ssid)' — triggering auto check-in")
            print("🏢 Connected to work WiFi: \(match.ssid)")

            Task {
                await notificationService.notifyWorkWiFiConnection(wifiName: match.ssid)
            }

            autoCheckInToSlack(for: match.ssid)
        } else {
            loggerService.logDebug("Work WiFi match but previousSSID == current, skipping")
        }
    }

    // MARK: - Auto Check-In

    private func autoCheckInToSlack(for ssid: String) {
        let key = AppDefaults.autoCheckInKey(for: ssid)
        let today = Calendar.current.startOfDay(for: Date())

        if let lastDate = UserDefaults.standard.object(forKey: key) as? Date,
           Calendar.current.startOfDay(for: lastDate) >= today {
            print("ℹ️ Already auto-checked in for '\(ssid)' today")
            return
        }

        print("🤖 Auto check-in triggered for '\(ssid)'")
        checkInToSlack(isAuto: true, ssid: ssid)
    }

    // MARK: - Public Actions

    func checkInToSlack(isAuto: Bool = false, ssid: String? = nil) {
        let token = UserDefaults.standard.string(forKey: AppDefaults.slackToken) ?? ""
        let channel = UserDefaults.standard.string(forKey: AppDefaults.slackChannel) ?? ""

        guard !token.isEmpty else {
            print("⚠️ Slack token not configured")
            return
        }

        let resolvedSSID = ssid ?? currentSSID

        Task {
            let entries = loadWifiEntries()
            let entry = entries.first { !$0.ssid.isEmpty && $0.ssid == resolvedSSID }
            let message = await messageGenerator.generateMessage(for: entry)

            guard !message.isEmpty else {
                print("⚠️ No message configured for current WiFi")
                return
            }

            loggerService.logDebug("checkInToSlack: channel='\(channel)' message='\(message)' isAuto=\(isAuto)")
            print("📝 Sending: \(message)")

            let retryDelays: [UInt64] = isAuto ? [10, 30, 60, 120] : []
            var attempt = 0

            while true {
                do {
                    let success = try await slackService.postMessage(
                        token: token,
                        channel: channel,
                        text: message
                    )

                    if success {
                        print("✅ Slack check-in sent")
                        if isAuto, let ssid = resolvedSSID {
                            UserDefaults.standard.set(Date(), forKey: AppDefaults.autoCheckInKey(for: ssid))
                            loggerService.logDebug("autoCheckIn: succeeded — flag set for '\(ssid)'")
                        }
                        loggerService.logSlackCheckIn(message: message, channel: channel)
                    }
                    break
                } catch {
                    print("❌ Slack check-in failed: \(error)")
                    let isNetworkError = error is URLError
                    if isNetworkError && attempt < retryDelays.count {
                        let delay = retryDelays[attempt]
                        print("🔄 Network error — retrying in \(delay)s...")
                        try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
                        attempt += 1
                    } else {
                        break
                    }
                }
            }
        }
    }

    func openLogFile() {
        loggerService.openLogFile()
    }

    func stopMonitoring() {
        wifiService.stopMonitoring()
    }
}
