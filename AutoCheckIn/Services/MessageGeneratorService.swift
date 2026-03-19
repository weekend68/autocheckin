import Foundation
import CoreLocation

// MARK: - Open-Meteo models

private struct OpenMeteoResponse: Codable {
    let current: OpenMeteoCurrent
}

private struct OpenMeteoCurrent: Codable {
    let temperature_2m: Double
    let weathercode: Int
}

private struct WeatherResult {
    let temperature: Double // always °C from API
    let emoji: String
}

// MARK: - MessageGeneratorService

class MessageGeneratorService: NSObject {
    static let shared = MessageGeneratorService()

    private var cachedWeather: WeatherResult?
    private var cacheTime: Date?
    private let cacheTimeout: TimeInterval = 1800 // 30 minutes

    private var locationManager: CLLocationManager?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    private override init() {
        super.init()
    }

    // MARK: - Public API

    func generateMessage(for entry: WiFiEntry?) async -> String {
        let baseMessage = entry?.message ?? ""

        let weatherEnabledObj = UserDefaults.standard.object(forKey: AppDefaults.weatherEnabled)
        let weatherEnabled = weatherEnabledObj == nil ? true : UserDefaults.standard.bool(forKey: AppDefaults.weatherEnabled)

        guard weatherEnabled else {
            return baseMessage
        }

        if let weather = await fetchWeather() {
            let isFahrenheit = UserDefaults.standard.string(forKey: AppDefaults.temperatureUnit) == "fahrenheit"
            let temp = isFahrenheit ? weather.temperature * 9 / 5 + 32 : weather.temperature
            let symbol = isFahrenheit ? "°F" : "°C"
            let weatherSuffix = "\(weather.emoji) \(Int(temp.rounded()))\(symbol)"
            let parts = [baseMessage, weatherSuffix].filter { !$0.isEmpty }
            return parts.joined(separator: " ")
        }

        return baseMessage
    }

    // MARK: - Weather fetching

    private func fetchWeather() async -> WeatherResult? {
        if let cached = cachedWeather,
           let ct = cacheTime,
           Date().timeIntervalSince(ct) < cacheTimeout {
            return cached
        }

        guard let location = await requestLocation() else {
            print("⚠️ Location unavailable — skipping weather")
            return nil
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weathercode"

        guard let url = URL(string: urlString) else { return nil }

        let retryDelays: [UInt64] = [3, 5, 10]
        var lastError: Error?

        for attempt in 0...retryDelays.count {
            if attempt > 0 {
                let delay = retryDelays[attempt - 1]
                print("🔄 Weather retry \(attempt) in \(delay)s...")
                try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                let temp = response.current.temperature_2m
                let code = response.current.weathercode
                let result = WeatherResult(temperature: temp, emoji: wmoEmoji(code))

                cachedWeather = result
                cacheTime = Date()

                print("🌤️ Weather: \(result.emoji) \(Int(temp.rounded()))°C (WMO \(code))")
                return result
            } catch let error as URLError where error.code == .notConnectedToInternet {
                lastError = error
            } catch {
                print("⚠️ Open-Meteo fetch failed: \(error)")
                return nil
            }
        }

        print("⚠️ Open-Meteo fetch failed after retries: \(lastError!)")
        return nil
    }

    // MARK: - Location

    private func requestLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let manager = CLLocationManager()
                self.locationManager = manager
                self.locationContinuation = continuation
                manager.delegate = self
                manager.desiredAccuracy = kCLLocationAccuracyKilometer
                manager.requestLocation()
            }
        }
    }

    // MARK: - WMO weather code → emoji

    private func wmoEmoji(_ code: Int) -> String {
        switch code {
        case 0:          return "☀️"
        case 1:          return "🌤️"
        case 2:          return "⛅"
        case 3:          return "☁️"
        case 45, 48:     return "🌫️"
        case 51, 53, 55: return "🌦️"
        case 61, 63, 65: return "🌧️"
        case 71, 73, 75: return "❄️"
        case 77:         return "❄️"
        case 80, 81, 82: return "🌦️"
        case 85, 86:     return "🌨️"
        case 95:         return "⛈️"
        case 96, 99:     return "⛈️"
        default:         return "🌡️"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MessageGeneratorService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.first)
        locationContinuation = nil
        locationManager = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location error: \(error)")
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
        locationManager = nil
    }
}
