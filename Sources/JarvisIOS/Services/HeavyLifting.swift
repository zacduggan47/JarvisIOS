// Jarvis iOS App - Heavy Lifting Features

import Foundation
import StoreKit
import SwiftUI

// ============================================
// SUBSCRIPTIONS - StoreKit 2 Implementation
// ============================================

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free = "Free"
    case pro = "Pro"
    case business = "Business"
    
    var id: String { rawValue }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$9.99/mo"
        case .business: return "$19.99/mo"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Basic chat with Jarvis",
                "50 messages per day",
                "3 skills (Gmail, Calendar, Weather)",
                "Basic voice input",
                "Standard response time"
            ]
        case .pro:
            return [
                "Unlimited messages",
                "All skills (Gmail, Calendar, WhatsApp, Things, etc.)",
                "Advanced voice input",
                "Priority response time",
                "Mood tracking & insights",
                "PKM sync (Obsidian, Notion)",
                "Push notifications",
                "Custom personality"
            ]
        case .business:
            return [
                "Everything in Pro",
                "Team workspace (up to 5)",
                "Shared skills & automations",
                "Admin controls",
                "API access",
                "Dedicated support",
                "Custom integrations",
                "White-label options"
            ]
        }
    }
}

// Product IDs (configure in App Store Connect)
enum ProductID {
    static let proMonthly = "com.jarvis.ios.pro.monthly"
    static let proYearly = "com.jarvis.ios.pro.yearly"
    static let businessMonthly = "com.jarvis.ios.business.monthly"
    static let businessYearly = "com.jarvis.ios.business.yearly"
}

// ============================================
// SUBSCRIPTION MANAGER
// ============================================

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var currentTier: SubscriptionTier = .free
    @Published var isPro: Bool = false
    @Published var isBusiness: Bool = false
    @Published var subscriptionExpirationDate: Date?
    @Published var products: [Product] = []
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        startTransactionListener()
    }
    
    func loadProducts() async {
        do {
            let store = StoreKit.Store()
            products = try await store.products(for: [
                ProductID.proMonthly,
                ProductID.proYearly,
                ProductID.businessMonthly,
                ProductID.businessYearly
            ])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateTier(for: transaction)
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                await updateTier(for: transaction)
            }
        }
    }
    
    private func updateTier(for transaction: Transaction) async {
        switch transaction.productID {
        case ProductID.proMonthly, ProductID.proYearly:
            currentTier = .pro
            isPro = true
            isBusiness = false
        case ProductID.businessMonthly, ProductID.businessYearly:
            currentTier = .business
            isPro = true
            isBusiness = true
        default:
            currentTier = .free
            isPro = false
            isBusiness = false
        }
        subscriptionExpirationDate = transaction.expirationDate
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func startTransactionListener() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                await self.updateTier(for: result)
            }
        }
    }
}

// ============================================
// ERROR HANDLING
// ============================================

enum JarvisError: LocalizedError {
    case networkError(String)
    case permissionDenied(String)
    case apiError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Connection issue: \(message)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .apiError(let message):
            return "Something went wrong: \(message)"
        case .unknownError(let message):
            return "Oops: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .permissionDenied:
            return "Enable this in Settings → Jarvis → Permissions."
        case .apiError:
            return "Please try again in a moment."
        case .unknownError:
            return "Restart the app and try again."
        }
    }
}

// ============================================
// OFFLINE MODE
// ============================================

@MainActor
class OfflineManager: ObservableObject {
    @Published var isOnline: Bool = true
    @Published var pendingMessages: [ChatMessage] = []
    @Published var isSyncing: Bool = false
    
    private let messageQueueKey = "offlineMessageQueue"
    
    func queueMessage(_ message: ChatMessage) {
        pendingMessages.append(message)
        saveQueue()
    }
    
    func syncWhenOnline() async {
        guard isOnline, !pendingMessages.isEmpty else { return }
        
        isSyncing = true
        
        for message in pendingMessages {
            do {
                // Send to gateway
                try await sendToGateway(message)
                pendingMessages.removeAll { $0.id == message.id }
            } catch {
                break // Keep in queue
            }
        }
        
        saveQueue()
        isSyncing = false
    }
    
    private func sendToGateway(_ message: ChatMessage) async throws {
        // Implement actual API call
    }
    
    private func saveQueue() {
        // Save to UserDefaults or local storage
    }
}

// ============================================
// ANALYTICS
// ============================================

struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]?
    let timestamp: Date
    
    static func onboardingCompleted(tier: SubscriptionTier) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "onboarding_completed",
            properties: ["tier": tier.rawValue],
            timestamp: Date()
        )
    }
    
    static func subscriptionPurchased(tier: SubscriptionTier) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "subscription_purchased",
            properties: ["tier": tier.rawValue, "price": tier.price],
            timestamp: Date()
        )
    }
    
    static func skillConnected(skill: String) -> AnalyticsEvent {
        AnalyticsEvent(
            name: "skill_connected",
            properties: ["skill": skill],
            timestamp: Date()
        )
    }
}

// ============================================
// CRASH REPORTING
// ============================================

// Note: In production, integrate Firebase Crashlytics
// For now, we log crashes locally

func logCrash(_ error: Error, context: String) {
    let crashLog = """
    CRASH: \(error.localizedDescription)
    Context: \(context)
    Timestamp: \(Date())
    Stack: \(Thread.callStackSymbols)
    """
    print(crashLog)
    // Send to crash reporting service
}
