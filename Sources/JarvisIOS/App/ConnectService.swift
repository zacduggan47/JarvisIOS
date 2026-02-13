import Foundation

private struct ConnectResponse: Decodable {
    let userId: String
}

private struct ConnectPayload: Encodable {
    let memory: [String: String]
    let soul: [String: String]
    let subscriptionTier: String
    let connectedSkills: [String]
}

enum ConnectService {
    static func connectOnboarding(
        memoryAnswers: [String],
        soulAnswers: [String],
        subscriptionTier: String,
        connectedSkills: [String]
    ) async throws -> String {
        let url = try makeConnectURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "ConnectService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Connect failed (\(http.statusCode))\n\(message)"])
        }
        if let res = try? JSONDecoder().decode(ConnectResponse.self, from: data) { return res.userId }
        if let id = try? JSONDecoder().decode(String.self, from: data) { return id }
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let id = obj["userId"] as? String { return id }
        throw NSError(domain: "ConnectService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse userId from /connect response"])
    }

    private static func makeConnectURL() throws -> URL {
        let defaults = UserDefaults.standard
        let stored = defaults.string(forKey: "gatewayURL") ?? "http://localhost:18789/v1/chat"
        if stored.hasSuffix("/connect"), let url = URL(string: stored) { return url }
        if let base = URL(string: stored), let scheme = base.scheme, let host = base.host {
            var comps = URLComponents()
            comps.scheme = scheme
            comps.host = host
            comps.port = base.port
            comps.path = "/connect"
            if let url = comps.url { return url }
        }
        if let url = URL(string: stored + (stored.hasSuffix("/") ? "connect" : "/connect")) { return url }
        guard let fallback = URL(string: "http://localhost:18789/connect") else { throw URLError(.badURL) }
        return fallback
    }
}
