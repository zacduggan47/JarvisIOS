import Foundation

// Response model for /connect
private struct ConnectResponse: Decodable {
    let userId: String
}

// Payload model for /connect
private struct ConnectPayload: Encodable {
    let memory: [String: String]
    let soul: [String: String]
    let subscriptionTier: String
    let connectedSkills: [String]
}

// MARK: - GatewayClient + Connect
// This extension adds the /connect onboarding call. It derives the base URL from the stored
// "gatewayURL" (used for chat) and targets the /connect endpoint on the same host/port.
//
// Expected server behavior:
//   POST /connect with JSON payload (see ConnectPayload)
//   Returns { "userId": "..." }
//
// If the stored gateway URL is something like:
//   http://localhost:18789/v1/chat
// we will call:
//   http://localhost:18789/connect
//
extension GatewayClient {
    /// Connects a user by sending onboarding data to the gateway's /connect endpoint and returns the userId.
    /// - Parameters:
    ///   - memoryAnswers: First 7 onboarding answers
    ///   - soulAnswers: Last 7 onboarding answers
    ///   - subscriptionTier: e.g., "Free", "Pro", "Business"
    ///   - connectedSkills: Skill identifiers connected during onboarding
    /// - Returns: The userId returned by the gateway
    func connectUser(
        memoryAnswers: [String],
        soulAnswers: [String],
        subscriptionTier: String,
        connectedSkills: [String]
    ) async throws -> String {
        let url = try makeConnectURL()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Map arrays to keyed dictionaries expected by the gateway
        let memoryDict: [String: String] = [
            "name": memoryAnswers.indices.contains(0) ? memoryAnswers[0] : "",
            "work": memoryAnswers.indices.contains(1) ? memoryAnswers[1] : "",
            "achieve": memoryAnswers.indices.contains(2) ? memoryAnswers[2] : "",
            "struggle": memoryAnswers.indices.contains(3) ? memoryAnswers[3] : "",
            "messageStyle": memoryAnswers.indices.contains(4) ? memoryAnswers[4] : "",
            "dosDonts": memoryAnswers.indices.contains(5) ? memoryAnswers[5] : "",
            "extra": memoryAnswers.indices.contains(6) ? memoryAnswers[6] : ""
        ]
        let soulDict: [String: String] = [
            "tone": soulAnswers.indices.contains(0) ? soulAnswers[0] : "",
            "humor": soulAnswers.indices.contains(1) ? soulAnswers[1] : "",
            "energy": soulAnswers.indices.contains(2) ? soulAnswers[2] : "",
            "avoidTopics": soulAnswers.indices.contains(3) ? soulAnswers[3] : "",
            "responseStyle": soulAnswers.indices.contains(4) ? soulAnswers[4] : "",
            "motivation": soulAnswers.indices.contains(5) ? soulAnswers[5] : "",
            "happiness": soulAnswers.indices.contains(6) ? soulAnswers[6] : ""
        ]

        let payload = ConnectPayload(
            memory: memoryDict,
            soul: soulDict,
            subscriptionTier: subscriptionTier,
            connectedSkills: connectedSkills
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "GatewayClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Connect failed (\(http.statusCode)) \n\(message)"])
        }

        // Try decoding a well-formed response { "userId": "..." }
        if let res = try? JSONDecoder().decode(ConnectResponse.self, from: data) {
            return res.userId
        }
        // Be lenient: sometimes servers return just a string
        if let id = try? JSONDecoder().decode(String.self, from: data) {
            return id
        }
        // Or a generic JSON dictionary
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = obj["userId"] as? String {
            return id
        }

        throw NSError(domain: "GatewayClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse userId from /connect response"])
    }

    /// Derives the /connect URL from stored settings.
    /// If the stored gatewayURL is "http://localhost:18789/v1/chat", this returns "http://localhost:18789/connect".
    private func makeConnectURL() throws -> URL {
        let defaults = UserDefaults.standard
        let stored = defaults.string(forKey: "gatewayURL") ?? "http://localhost:18789/v1/chat"

        // If the stored value is already a /connect URL, use it as-is
        if stored.hasSuffix("/connect"), let url = URL(string: stored) {
            return url
        }

        // Try to parse as a full URL and extract scheme/host/port
        if let base = URL(string: stored), let scheme = base.scheme, let host = base.host {
            var comps = URLComponents()
            comps.scheme = scheme
            comps.host = host
            comps.port = base.port
            comps.path = "/connect"
            if let url = comps.url { return url }
        }

        // Fall back: naive append
        if let url = URL(string: stored + (stored.hasSuffix("/") ? "connect" : "/connect")) {
            return url
        }

        // Final fallback to localhost
        guard let fallback = URL(string: "http://localhost:18789/connect") else {
            throw URLError(.badURL)
        }
        return fallback
    }
}
