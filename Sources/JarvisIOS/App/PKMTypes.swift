import Foundation
import SwiftUI

enum PKMApp: String, CaseIterable, Identifiable {
    case obsidian, notion, readwise, appleNotes, remember
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .obsidian: return "Obsidian"
        case .notion: return "Notion"
        case .readwise: return "Readwise"
        case .appleNotes: return "Apple Notes"
        case .remember: return "Remember"
        }
    }

    var icon: String {
        switch self {
        case .obsidian: return "folder.fill"
        case .notion: return "n.square.fill" // placeholder
        case .readwise: return "book.fill"
        case .appleNotes: return "note.text"
        case .remember: return "brain.head.profile"
        }
    }
}

struct PKMItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let link: String?
    let tags: [String]
    let source: String // PKMApp.rawValue
    let updatedAt: Date

    init(id: UUID = UUID(), title: String, link: String? = nil, tags: [String] = [], source: String, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.link = link
        self.tags = tags
        self.source = source
        self.updatedAt = updatedAt
    }
}

struct PKMIndex: Codable, Equatable {
    var items: [PKMItem]
    var updatedAt: Date

    static let empty = PKMIndex(items: [], updatedAt: .distantPast)
}
