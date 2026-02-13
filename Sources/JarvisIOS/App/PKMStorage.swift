import Foundation
import CryptoKit

final class PKMStorage {
    static let shared = PKMStorage()
    private let keyTag = "com.jarvis.pkm.key"
    private let fileURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pkm_index.json")
    }()

    private init() { try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true) }

    private func loadKey() throws -> SymmetricKey {
        let tag = keyTag.data(using: .utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: tag,
                                    kSecAttrKeyType as String: kSecAttrKeyTypeAES,
                                    kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let keyData = item as? Data {
            return SymmetricKey(data: keyData)
        }
        // Create a new key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let addQuery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: tag,
                                       kSecAttrKeyType as String: kSecAttrKeyTypeAES,
                                       kSecValueData as String: keyData]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(addQuery as CFDictionary, nil)
        return key
    }

    func saveIndex(_ index: PKMIndex) throws {
        let key = try loadKey()
        let data = try JSONEncoder().encode(index)
        let sealed = try AES.GCM.seal(data, using: key)
        let combined = sealed.combined!
        try combined.write(to: fileURL)
    }

    func loadIndex() throws -> PKMIndex {
        let key = try loadKey()
        guard let data = try? Data(contentsOf: fileURL) else { return .empty }
        let box = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(box, using: key)
        return try JSONDecoder().decode(PKMIndex.self, from: decrypted)
    }
}
