import Foundation
import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Product IDs configured in App Store Connect
    enum ProductID: String, CaseIterable {
        case proMonthly = "com.jarvis.ios.pro.monthly"
        case proYearly = "com.jarvis.ios.pro.yearly"
        case businessMonthly = "com.jarvis.ios.business.monthly"
        case businessYearly = "com.jarvis.ios.business.yearly"
    }

    @Published var products: [Product] = []
    @Published var currentTier: String = UserDefaults.standard.string(forKey: "subscriptionTier") ?? "Free"

    var isPro: Bool { currentTier == "Pro" || isBusiness }
    var isBusiness: Bool { currentTier == "Business" }

    private init() {}

    func loadProducts() async {
        do {
            let ids = Set(ProductID.allCases.map { $0.rawValue })
            let prods = try await Product.products(for: ids)
            products = prods.sorted(by: { $0.displayName < $1.displayName })
        } catch {
            // Silent failure; UI can show placeholder prices
        }
    }

    func updateEntitlements() async {
        var highest: String = "Free"
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let tier = tierFor(productID: transaction.productID)
            highest = pickHigherTier(lhs: highest, rhs: tier)
        }
        setTier(highest)
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let transaction) = verification {
                let tier = tierFor(productID: transaction.productID)
                setTier(tier)
                await transaction.finish()
            } else {
                throw NSError(domain: "Subscription", code: 1, userInfo: [NSLocalizedDescriptionKey: "Purchase verification failed"]) }
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func restorePurchases() async {
        do { try await AppStore.sync() } catch { }
        await updateEntitlements()
    }

    func manageSubscriptions() {
        if #available(iOS 15.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                Task { try? await AppStore.showManageSubscriptions(in: scene) }
            }
        }
    }

    // MARK: - Helpers
    private func setTier(_ tier: String) {
        currentTier = tier
        UserDefaults.standard.set(tier, forKey: "subscriptionTier")
    }

    private func tierFor(productID: String) -> String {
        if productID.contains("business") { return "Business" }
        if productID.contains("pro") { return "Pro" }
        return "Free"
    }

    private func pickHigherTier(lhs: String, rhs: String) -> String {
        let rank: [String: Int] = ["Free": 0, "Pro": 1, "Business": 2]
        return (rank[rhs] ?? 0) > (rank[lhs] ?? 0) ? rhs : lhs
    }
}
