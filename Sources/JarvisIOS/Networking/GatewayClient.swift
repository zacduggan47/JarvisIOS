import Foundation
import SwiftUI

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
        endpoint: URL? = nil
    ) {
        self.session = session
        if let configured = UserDefaults.standard.string(forKey: "gatewayURL"),
           let url = URL(string: configured), !configured.isEmpty {
            self.endpoint = url
        } else if let env = ProcessInfo.processInfo.environment["OPENCLAW_GATEWAY_URL"],
                  let url = URL(string: env) {
            self.endpoint = url
        } else {
            self.endpoint = URL(string: "http://localhost:18789/v1/chat")!
        }
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

    // MARK: - Onboarding Connect
    func connectUser(
        memoryAnswers: [String],
        soulAnswers: [String],
        subscriptionTier: String,
        connectedSkills: [String]
    ) async throws -> String {
        // Derive a /connect endpoint from the configured chat endpoint
        let connectURL = endpoint.deletingLastPathComponent().appendingPathComponent("connect")
        var request = URLRequest(url: connectURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ConnectRequest(
            memoryAnswers: memoryAnswers,
            soulAnswers: soulAnswers,
            subscriptionTier: subscriptionTier,
            connectedSkills: connectedSkills
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw GatewayError.badResponse
        }

        let decoded = try JSONDecoder().decode(ConnectResponse.self, from: data)
        if let userId = decoded.userId ?? decoded.id {
            return userId
        }
        throw GatewayError.badResponse
    }

    private struct ConnectRequest: Encodable {
        let memoryAnswers: [String]
        let soulAnswers: [String]
        let subscriptionTier: String
        let connectedSkills: [String]
    }

    private struct ConnectResponse: Decodable {
        let userId: String?
        let id: String?
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
