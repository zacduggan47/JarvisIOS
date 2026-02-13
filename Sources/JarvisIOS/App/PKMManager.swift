import Foundation
import UIKit

@MainActor
final class PKMManager: ObservableObject {
    static let shared = PKMManager()

    @Published private(set) var index: PKMIndex = .empty
    @Published var isSyncing: Bool = false
    @Published var lastSync: Date? = nil

    private init() { load() }

    func load() {
        index = (try? PKMStorage.shared.loadIndex()) ?? .empty
    }

    func connectAll() async {
        isSyncing = true
        defer { isSyncing = false }
        var items: [PKMItem] = index.items
        // Stubs: In production, call connectors below
        items.append(contentsOf: await connectObsidian())
        items.append(contentsOf: await connectNotion())
        items.append(contentsOf: await connectReadwise())
        items.append(contentsOf: await connectAppleNotes())
        items.append(contentsOf: await connectRemember())
        index = PKMIndex(items: Array(Set(items)), updatedAt: Date())
        try? PKMStorage.shared.saveIndex(index)
        lastSync = Date()
        // Optionally notify gateway to sync cloud index
        try? await PKMService.syncIndex(index)
    }

    // MARK: - Connectors (stubs)
    func connectObsidian() async -> [PKMItem] {
        // TODO: Present a document picker for a folder (Files) and scan filenames
        return []
    }

    func connectNotion() async -> [PKMItem] {
        // TODO: OAuth and fetch pages/databases metadata
        return []
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
