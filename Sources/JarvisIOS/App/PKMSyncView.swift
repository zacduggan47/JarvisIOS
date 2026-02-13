import SwiftUI

struct PKMSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = PKMManager.shared
    @State private var showConfetti = false
    @State private var successBanner = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
                    Text("Connect Your Brain")
                        .font(.largeTitle.bold())
                        .foregroundColor(.orangeBrand)
                    Text("One-tap connect to your PKM apps. Jarvis gets 10x smarter.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    List(PKMApp.allCases) { app in
                        HStack(spacing: 12) {
                            Image(systemName: app.icon)
                                .foregroundColor(.orangeBrand)
                            VStack(alignment: .leading) {
                                Text(app.displayName)
                                Text(status(for: app))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Connect") { connect(app) }
                                .buttonStyle(.bordered)
                                .tint(.orangeBrand)
                        }
                    }
                    .frame(maxHeight: 360)

                    Button(action: connectAll) {
                        HStack {
                            if manager.isSyncing { ProgressView() }
                            Text(manager.isSyncing ? "Connecting…" : "Connect All")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orangeBrand)

                    if manager.isSyncing {
                        ProgressView(value: manager.progress)
                    }

                    if let last = manager.lastSync {
                        Text("Last sync: \(last.formatted(date: .abbreviated, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding()
            .navigationTitle("PKM Sync")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }

            if showConfetti { ConfettiView().ignoresSafeArea() }
            if !successBanner.isEmpty {
                VStack {
                    Text(successBanner)
                        .font(.headline)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    Spacer()
                }
                .transition(.opacity)
                .padding()
            }
        }
    }

    private func status(for app: PKMApp) -> String {
        // TODO: derive per-app status from stored index or connector states
        return "Not Connected"
    }

    private func connect(_ app: PKMApp) {
        Task {
            switch app {
            case .obsidian: _ = await manager.connectObsidian()
            case .notion: _ = await manager.connectNotion()
            case .readwise: _ = await manager.connectReadwise()
            case .appleNotes: _ = await manager.connectAppleNotes()
            case .remember: _ = await manager.connectRemember()
            }
            try? PKMStorage.shared.saveIndex(manager.index)
        }
    }

    private func connectAll() {
        Task {
            await manager.connectAll()
            withAnimation { showConfetti = true; successBanner = "🎉 Your Jarvis is now 10x smarter!" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showConfetti = false
                successBanner = ""
                dismiss()
            }
        }
    }
}
