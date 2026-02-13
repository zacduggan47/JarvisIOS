import Foundation
import UIKit
import AuthenticationServices

@MainActor
final class PKMManager: ObservableObject {
    static let shared = PKMManager()

    @Published private(set) var index: PKMIndex = .empty
    @Published var isSyncing: Bool = false
    @Published var lastSync: Date? = nil
    @Published var progress: Double = 0

    enum PKMError: Error { case notionAuthCancelled, connectFailed(String) }

    private init() { load() }

    func load() {
        index = (try? PKMStorage.shared.loadIndex()) ?? .empty
    }

    func connectAll() async {
        isSyncing = true
        progress = 0
        defer { isSyncing = false }
        var items: [PKMItem] = []
        let steps = 5.0
        // Obsidian
        items += await connectObsidian(); progress = 1/steps
        // Notion
        items += await connectNotion(); progress = 2/steps
        // Readwise
        items += await connectReadwise(); progress = 3/steps
        // Apple Notes
        items += await connectAppleNotes(); progress = 4/steps
        // Remember
        items += await connectRemember(); progress = 5/steps
        index = PKMIndex(items: Array(Set(items)), updatedAt: Date())
        try? PKMStorage.shared.saveIndex(index)
        lastSync = Date()
        try? await PKMService.syncIndex(index)
    }

    // MARK: - Connectors (stubs)
    func connectObsidian() async -> [PKMItem] {
        if ObsidianConnector.shared.hasVault() == false { return [] }
        return await ObsidianConnector.shared.fetchItems()
    }

    func connectNotion() async -> [PKMItem] {
        if NotionConnector.shared.hasToken() == false {
            // Requires a presentation context provider. This can be passed in from UI if needed.
            // For now, skip interactive auth in background.
            return []
        }
        return await NotionConnector.shared.fetchItems()
    }

    func connectReadwise() async -> [PKMItem] {
        // TODO: Ask for API key and fetch highlights metadata
        return []
    }

    func connectAppleNotes() async -> [PKMItem] {
        // TODO: Read notes via appropriate APIs (no direct EventKit; consider Notes APIs or user export)
        return []
    }

    func connectRemember() async -> [PKMItem] {
        // TODO: Memory app integration
        return []
    }
}
