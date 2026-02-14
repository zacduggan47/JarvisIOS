import Foundation
import UniformTypeIdentifiers
import SwiftUI

final class ObsidianConnector: NSObject {
    static let shared = ObsidianConnector()
    private let bookmarkKey = "obsidian_vault_bookmark"

    func hasVault() -> Bool {
        return UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    func setVault(url: URL) {
        do {
            let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        } catch {
            // ignore for now
        }
    }

    func fetchItems() async -> [PKMItem] {
        var items: [PKMItem] = []
        withVaultURL { base in
            let fm = FileManager.default
            let enumerator = fm.enumerator(at: base, includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey], options: [.skipsHiddenFiles])
            while let file = enumerator?.nextObject() as? URL {
                guard file.pathExtension.lowercased() == "md" else { continue }
                let title = extractTitle(from: file) ?? file.deletingPathExtension().lastPathComponent
                let tags = extractTags(from: file)
                let updated = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
                items.append(PKMItem(title: title, link: file.absoluteString, tags: tags, source: "obsidian", updatedAt: updated))
            }
        }
        return items
    }

    private func withVaultURL(_ body: (URL) -> Void) {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        var isStale = false
        if let url = try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale) {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            body(url)
        }
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
