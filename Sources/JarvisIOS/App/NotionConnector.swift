import Foundation
import AuthenticationServices

final class NotionConnector: NSObject {
    static let shared = NotionConnector()

    // TODO: Replace with your real credentials and redirect URI registered with Notion
    private let clientID: String = "YOUR_NOTION_CLIENT_ID"
    private let clientSecret: String = "YOUR_NOTION_CLIENT_SECRET"
    private let redirectURI: String = "jarvis://notion-oauth"

    private let tokenKey = "notion_access_token"
    private let apiBase = URL(string: "https://api.notion.com")!

    func hasToken() -> Bool {
        return KeychainStore.get(tokenKey) != nil
    }

    func startOAuth(presenting: ASWebAuthenticationPresentationContextProviding) async throws {
        let scope = "read%3Acontent%20read%3Auser" // URL-encoded scopes
        let authURL = URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=\(clientID)&response_type=code&owner=user&redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&scope=\(scope)")!

        let callbackScheme = URL(string: redirectURI)?.scheme ?? "jarvis"

        let code = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error { cont.resume(throwing: error); return }
                guard let url = callbackURL, let comps = URLComponents(url: url, resolvingAgainstBaseURL: false), let code = comps.queryItems?.first(where: { $0.name == "code" })?.value else {
                    cont.resume(throwing: URLError(.badServerResponse)); return
                }
                cont.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = presenting
            session.start()
        }

        try await exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) async throws {
        var req = URLRequest(url: apiBase.appendingPathComponent("/v1/oauth/token"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "client_secret": clientSecret
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let access = obj?["access_token"] as? String, let d = access.data(using: .utf8) { _ = KeychainStore.set(d, for: tokenKey) }
    }

    func fetchItems() async -> [PKMItem] {
        guard let tokenData = KeychainStore.get(tokenKey), let token = String(data: tokenData, encoding: .utf8) else { return [] }
        var req = URLRequest(url: apiBase.appendingPathComponent("/v1/search"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["page_size": 20])
        let (data, response) = try? await URLSession.shared.data(for: req) ?? (Data(), URLResponse())
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return [] }
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let results = obj["results"] as? [[String: Any]] else { return [] }
        var items: [PKMItem] = []
        for r in results {
            if let url = r["url"] as? String {
                let title = (r["object"] as? String) ?? "Notion Item"
                items.append(PKMItem(title: title, link: url, tags: [], source: "notion"))
            }
        }
        return items
    }
}
