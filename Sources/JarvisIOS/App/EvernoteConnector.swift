import Foundation

final class EvernoteConnector {
    static let shared = EvernoteConnector()
    private let tokenKey = "evernote_access_token"

    func hasToken() -> Bool { KeychainStore.get(tokenKey) != nil }

    func startOAuth() async throws {
        // TODO: Implement OAuth 1.0a or use SDK; store token in KeychainStore under tokenKey
    }

    func fetchItems() async -> [PKMItem] {
        // TODO: Fetch notebooks and notes metadata; map to PKMItem
        return []
    }
}
