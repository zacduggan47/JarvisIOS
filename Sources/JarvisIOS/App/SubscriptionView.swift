import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = SubscriptionManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TierCards()
                    RestoreManageButtons()
                }
                .padding()
            }
            .navigationTitle("Subscriptions")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .task { await manager.loadProducts(); await manager.updateEntitlements() }
        }
    }
}

private struct TierCards: View {
    @ObservedObject var manager = SubscriptionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose your plan").font(.title2.bold())
            HStack(alignment: .top, spacing: 12) {
                TierCard(title: "Free", price: "$0", features: ["50 msgs/day", "3 skills", "Basic voice"], highlight: nil, isCurrent: manager.currentTier == "Free")
                TierCard(title: "Pro", price: priceFor([.proMonthly, .proYearly]), features: ["Unlimited", "All skills", "PKM sync", "Custom personality"], highlight: "Most Popular", isCurrent: manager.currentTier == "Pro") { Task { await subscribe(.proMonthly) } }
            }
            HStack(alignment: .top, spacing: 12) {
                TierCard(title: "Business", price: priceFor([.businessMonthly, .businessYearly]), features: ["Everything in Pro", "Team", "Admin", "API"], highlight: "Best Value", isCurrent: manager.currentTier == "Business") { Task { await subscribe(.businessMonthly) } }
            }
        }
    }

    private func priceFor(_ ids: [SubscriptionManager.ProductID]) -> String {
        let prods = manager.products.filter { ids.map(\.$rawValue).contains($0.id) }
        if let monthly = prods.first(where: { $0.id.contains("monthly") }) { return monthly.displayPrice + "/mo" }
        if let yearly = prods.first(where: { $0.id.contains("yearly") }) { return yearly.displayPrice + "/yr" }
        return "$—"
    }

    private func subscribe(_ id: SubscriptionManager.ProductID) async {
        guard let product = manager.products.first(where: { $0.id == id.rawValue }) else { return }
        try? await manager.purchase(product)
    }
}

private struct TierCard: View {
    let title: String
    let price: String
    let features: [String]
    let highlight: String?
    let isCurrent: Bool
    var onSubscribe: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let highlight { Text(highlight).font(.caption.bold()).padding(6).background(Color.orangeBrand.opacity(0.2)).clipShape(Capsule()) }
            Text(title).font(.headline)
            Text(price).font(.largeTitle.bold())
            ForEach(features, id: \.self) { f in HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(.green); Text(f).font(.subheadline) } }
            if isCurrent {
                Text("Current plan").font(.footnote).foregroundColor(.secondary)
            } else if let onSubscribe {
                Button("Subscribe") { onSubscribe() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orangeBrand)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orangeBrand.opacity(isCurrent ? 0.8 : 0.3), lineWidth: isCurrent ? 2 : 1))
    }
}

private struct RestoreManageButtons: View {
    var body: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") { Task { await SubscriptionManager.shared.restorePurchases() } }
            Button("Manage Subscription") { SubscriptionManager.shared.manageSubscriptions() }
        }
    }
}
