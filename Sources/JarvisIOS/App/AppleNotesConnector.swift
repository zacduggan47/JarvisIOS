import Foundation

final class AppleNotesConnector {
    static let shared = AppleNotesConnector()

    func fetchItems() async -> [PKMItem] {
        // No public Notes API. Options:
        // 1) Ask user to export notes and import metadata.
        // 2) Use Shortcuts as a bridge to fetch recent titles/links.
        // 3) Index only titles and URLs (notes://) provided by user/gateway.
        return []
    }
}
