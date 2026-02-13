import Foundation

enum PKMService {
    static func syncIndex(_ index: PKMIndex) async throws {
        // POST /sync/pkm
        guard let url = makeURL(path: "/sync/pkm") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(index)
        _ = try await URLSession.shared.data(for: req)
    }

    static func query(_ text: String) async throws -> [PKMItem] {
        // POST /query/pkm { text }
        guard let url = makeURL(path: "/query/pkm") else { return [] }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["text": text])
        let (data, _) = try await URLSession.shared.data(for: req)
        if let items = try? JSONDecoder().decode([PKMItem].self, from: data) { return items }
        return []
    }

    static func summarize(_ text: String) async throws -> String {
        // POST /summarize/pkm { text }
        guard let url = makeURL(path: "/summarize/pkm") else { return "" }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["text": text])
        let (data, _) = try await URLSession.shared.data(for: req)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func makeURL(path: String) -> URL? {
        let base = UserDefaults.standard.string(forKey: "gatewayURL") ?? "http://localhost:18789"
        return URL(string: base + path)
    }
}
