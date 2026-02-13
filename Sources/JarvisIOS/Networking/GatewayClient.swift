import Foundation

struct GatewayClient {
    enum GatewayError: LocalizedError {
        case invalidURL
        case badResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The OpenClaw Gateway URL is invalid."
            case .badResponse:
                return "The gateway returned an invalid response."
            }
        }
    }

    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL? = URL(string: ProcessInfo.processInfo.environment["OPENCLAW_GATEWAY_URL"] ?? "https://api.openclaw.dev/v1/chat")
    ) {
        self.session = session
        self.endpoint = endpoint ?? URL(string: "https://api.openclaw.dev/v1/chat")!
    }

    func send(message: String, history: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = GatewayRequest(
            message: message,
            history: history.map { GatewayMessage(role: $0.role.rawValue, content: $0.text) }
        )

        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw GatewayError.badResponse
        }

        let decoded = try JSONDecoder().decode(GatewayResponse.self, from: data)
        return decoded.reply.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct GatewayRequest: Encodable {
    let message: String
    let history: [GatewayMessage]
}

private struct GatewayMessage: Encodable {
    let role: String
    let content: String
}

private struct GatewayResponse: Decodable {
    let reply: String
}
