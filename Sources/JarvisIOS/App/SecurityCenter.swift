import Foundation
import LocalAuthentication
import SwiftUI
import Security

// Simple Keychain helper (tokens, credentials)
final class KeychainStore {
    static func set(_ value: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = value
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(newQuery as CFDictionary, nil) == errSecSuccess
    }

    static func get(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? (result as? Data) : nil
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
final class SecurityCenter: ObservableObject {
    static let shared = SecurityCenter()

    @Published var hidePreviews: Bool = false
    @Published var requireBiometricForSensitive: Bool = true

    func exportData() -> Data {
        // Collect a minimal export; extend with chat history, settings, etc.
        let defaults = UserDefaults.standard
        let export: [String: Any] = [
            "accountName": defaults.string(forKey: "accountName") ?? "",
            "subscriptionTier": defaults.string(forKey: "subscriptionTier") ?? "",
            "memoryAnswers": defaults.array(forKey: "memoryAnswers") ?? [],
            "soulAnswers": defaults.array(forKey: "soulAnswers") ?? []
        ]
        return (try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted])) ?? Data()
    }

    func deleteAllData() {
        let defaults = UserDefaults.standard
        [
            "accountName",
            "subscriptionTier",
            "memoryAnswers",
            "soulAnswers",
            "connectedSkills",
            "userId",
        ].forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        // Clear tokens
        KeychainStore.delete("authToken")
        KeychainStore.delete("nylasToken")
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            return true
        } catch { return false }
    }
}

