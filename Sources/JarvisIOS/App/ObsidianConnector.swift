import Foundation
import UniformTypeIdentifiers
import SwiftUI

final class ObsidianConnector: NSObject {
    static let shared = ObsidianConnector()
    private let vaultURLKey = "obsidian_vault_url"

    func hasVault() -> Bool {
        return UserDefaults.standard.url(forKey: vaultURLKey) != nil
    }

    func setVault(url: URL) {
        UserDefaults.standard.set(url, forKey: vaultURLKey)
    }

    func fetchItems() async -> [PKMItem] {
        guard let base = UserDefaults.standard.url(forKey: vaultURLKey) else { return [] }
        var items: [PKMItem] = []
        let fm = FileManager.default
        let enumerator = fm.enumerator(at: base, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles])
        while let file = enumerator?.nextObject() as? URL {
            guard file.pathExtension.lowercased() == "md" else { continue }
            let title = extractTitle(from: file) ?? file.deletingPathExtension().lastPathComponent
            let tags = extractTags(from: file)
            let updated = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            items.append(PKMItem(title: title, link: file.absoluteString, tags: tags, source: "obsidian", updatedAt: updated))
        }
        return items
    }

    private func extractTitle(from url: URL) -> String? {
        guard let str = try? String(contentsOf: url) else { return nil }
        if let firstLine = str.split(separator: "\n").first, firstLine.hasPrefix("# ") {
            return String(firstLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    private func extractTags(from url: URL) -> [String] {
        guard let str = try? String(contentsOf: url) else { return [] }
        var tags: [String] = []
        // frontmatter tags: tags: [tag1, tag2]
        if let range = str.range(of: "tags:") {
            let after = str[range.upperBound...]
            if let endLine = after.firstIndex(of: "\n") {
                let line = after[..<endLine]
                let comps = line.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").split(separator: ",")
                tags.append(contentsOf: comps.map { $0.trimmingCharacters(in: .whitespaces) })
            }
        }
        // wikilinks [[tag]] or markdown #tag
        let hashTags = str.split(separator: "\n").flatMap { $0.split(separator: " ") }.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
        tags.append(contentsOf: hashTags)
        return Array(Set(tags)).filter { !$0.isEmpty }
    }
}
