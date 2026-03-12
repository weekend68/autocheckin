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
    @Published var locationPermissionDenied: Bool = false

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
        let status = locationManager.authorizationStatus
        print("📍 Location status at init: \(status.rawValue) (\(statusDescription(status)))")
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        checkLocationStatus()
    }

    private func checkLocationStatus() {
        let status = locationManager.authorizationStatus
        // Treat everything except explicit authorization as denied:
        // .notDetermined means macOS blocks SSID access even without user interaction.
        let denied = (status != .authorizedAlways)
        print("📍 checkLocationStatus: \(statusDescription(status)) → denied=\(denied)")
        let update = { [self] in
            if locationPermissionDenied != denied { locationPermissionDenied = denied }
        }
        if Thread.isMainThread { update() } else { DispatchQueue.main.async(execute: update) }
    }

    private func statusDescription(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        @unknown default: return "unknown(\(status.rawValue))"
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

        // Fallback: poll every 10 seconds in case delegate misses an event.
        // Also re-checks location status so the warning updates without restart.
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.checkLocationStatus()
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
        print("📍 locationManagerDidChangeAuthorization: \(statusDescription(manager.authorizationStatus)) (thread: \(Thread.isMainThread ? "main" : "bg"))")
        checkLocationStatus()
    }
}
