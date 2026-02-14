import SwiftUI
import AuthenticationServices
import UIKit

struct PKMSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = PKMManager.shared
    @State private var showConfetti = false
    @State private var successBanner = ""
    @State private var isAuthenticatingNotion = false
    @State private var authError: String? = nil

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
                            Button("Connect") {
                                switch app {
                                case .notion:
                                    isAuthenticatingNotion = true
                                    authError = nil
                                    Task {
                                        do {
                                            let presenter = WebAuthPresenter()
                                            try await NotionConnector.shared.startOAuth(presenting: presenter)
                                            await MainActor.run { isAuthenticatingNotion = false }
                                        } catch {
                                            await MainActor.run {
                                                isAuthenticatingNotion = false
                                                authError = (error as NSError).localizedDescription
                                            }
                                        }
                                    }
                                case .obsidian:
                                    showFolderPicker()
                                default:
                                    connect(app)
                                }
                            }
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

                    if isAuthenticatingNotion {
                        ProgressView("Connecting Notion…")
                    }
                    if let error = authError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

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

    private func showFolderPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.allowsMultipleSelection = false
        picker.delegate = FolderPickerDelegate { url in
            if let url { ObsidianConnector.shared.setVault(url: url) }
        }
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
    }

    final class WebAuthPresenter: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
        }
    }

    final class FolderPickerDelegate: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL?) -> Void
        init(onPick: @escaping (URL?) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) { onPick(urls.first) }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { onPick(nil) }
    }
}
