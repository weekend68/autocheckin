import Foundation

class SlackService {
    static let shared = SlackService()

    private let apiEndpoint = "https://slack.com/api/chat.postMessage"

    private init() {}

    struct SlackResponse: Codable {
        let ok: Bool
        let error: String?
    }

    func postMessage(token: String, channel: String, text: String) async throws -> Bool {
        guard !token.isEmpty, !channel.isEmpty else {
            throw SlackError.invalidConfiguration
        }

        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "channel": channel,
            "text": text
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SlackError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw SlackError.httpError(statusCode: httpResponse.statusCode)
        }

        let slackResponse = try JSONDecoder().decode(SlackResponse.self, from: data)

        if !slackResponse.ok {
            throw SlackError.apiError(message: slackResponse.error ?? "Unknown error")
        }

        return true
    }

    func testConnection(token: String, channel: String) async -> Result<String, SlackError> {
        do {
            let success = try await postMessage(
                token: token,
                channel: channel,
                text: "🧪 Test from WiFi Monitor"
            )

            if success {
                return .success("✅ Slack connection works!")
            } else {
                return .failure(.unknown)
            }
        } catch let error as SlackError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
}

enum SlackError: LocalizedError {
    case invalidConfiguration
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(message: String)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Slack token or channel is missing"
        case .invalidResponse:
            return "Invalid response from Slack"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let message):
            return "Slack API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "Unknown error"
        }
    }
}
