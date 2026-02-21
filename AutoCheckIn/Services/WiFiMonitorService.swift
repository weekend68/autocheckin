import Foundation
import CoreWLAN
import CoreLocation
import Combine

// Uses CWEventDelegate for real-time SSID updates plus a 10-second timer fallback.
// Location Services permission is required for CoreWLAN SSID access.

class WiFiMonitorService: NSObject, ObservableObject {
    static let shared = WiFiMonitorService()

    @Published var currentSSID: String?
    @Published var isMonitoring: Bool = false

    private let wifiClient = CWWiFiClient.shared()
    private var timer: Timer?
    private let locationManager = CLLocationManager()

    var onNetworkChange: ((String?, String?) -> Void)?

    private override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }

        print("🔍 Starting WiFi monitoring...")

        wifiClient.delegate = self

        do {
            try wifiClient.startMonitoringEvent(with: .ssidDidChange)
            print("✅ CoreWLAN event monitoring started")
        } catch {
            print("⚠️ Failed to start CoreWLAN monitoring: \(error)")
        }

        // Fallback: poll every 10 seconds in case delegate misses an event
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkCurrentNetwork()
        }

        isMonitoring = true
        checkCurrentNetwork()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        print("🛑 Stopping WiFi monitoring")

        do {
            try wifiClient.stopMonitoringAllEvents()
        } catch {
            print("⚠️ Error stopping monitoring: \(error)")
        }

        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func checkCurrentNetwork() {
        let newSSID = getCurrentSSID()

        if newSSID != currentSSID {
            let previousSSID = currentSSID
            print("📡 WiFi changed: '\(previousSSID ?? "none")' → '\(newSSID ?? "disconnected")'")
            currentSSID = newSSID
            onNetworkChange?(previousSSID, newSSID)
        }
    }

    private func getCurrentSSID() -> String? {
        guard let interface = wifiClient.interface() else {
            print("⚠️ No WiFi interface found")
            return nil
        }
        return interface.ssid()
    }
}

// MARK: - CWEventDelegate

extension WiFiMonitorService: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        print("🔔 CoreWLAN delegate: SSID changed on \(interfaceName)")
        checkCurrentNetwork()
    }

    func clientConnectionStarted(withInterfaceName interfaceName: String) {
        print("🔔 CoreWLAN delegate: Connection started on \(interfaceName)")
        checkCurrentNetwork()
    }

    func clientConnectionStopped(withInterfaceName interfaceName: String) {
        print("🔔 CoreWLAN delegate: Connection stopped on \(interfaceName)")
        checkCurrentNetwork()
    }
}

// MARK: - CLLocationManagerDelegate

extension WiFiMonitorService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location Services authorized")
        case .denied, .restricted:
            print("❌ Location Services denied — WiFi monitoring will not work!")
            print("💡 Enable in System Settings → Privacy & Security → Location Services")
        case .notDetermined:
            print("⏳ Location Services authorization pending...")
        @unknown default:
            print("⚠️ Unknown location authorization status")
        }
    }
}
