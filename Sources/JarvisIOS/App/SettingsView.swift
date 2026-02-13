import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel

    @AppStorage("accountName") private var accountName: String = ""
    @AppStorage("accountEmail") private var accountEmail: String = ""
    @AppStorage("subscriptionTier") private var subscriptionTier: String = "Free" // Free or Pro

    @AppStorage("gatewayURL") private var gatewayURL: String = "http://localhost:18789/v1/chat"

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("voiceEnabled") private var voiceEnabled: Bool = false
    @AppStorage("voiceName") private var voiceName: String = "Samantha" // Samantha/Daniel/Alex

    @AppStorage("appearance") private var appearance: String = "system" // system/light/dark

    @State private var showClearConfirm = false
    @State private var showLogoutConfirm = false

    private let connectedSkillsKey = "connectedSkills"

    var body: some View {
        List {
            Section(header: Label("Account", systemImage: "person.crop.circle")) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Name", text: $accountName)
                        TextField("Email", text: $accountEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Spacer()
                    Text(subscriptionTier)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(subscriptionTier == "Pro" ? Color.green.opacity(0.2) : Color.orangeBrand.opacity(0.2))
                        .foregroundColor(subscriptionTier == "Pro" ? .green : .orangeBrand)
                        .clipShape(Capsule())
                        .accessibilityLabel("Subscription tier")
                }
                Picker("Tier", selection: $subscriptionTier) {
                    Text("Free").tag("Free")
                    Text("Pro").tag("Pro")
                }
                .pickerStyle(.segmented)
            }

            Section(header: Label("Gateway", systemImage: "network")) {
                HStack(spacing: 12) {
                    Image(systemName: "link")
                        .foregroundColor(.orangeBrand)
                    TextField("Gateway URL", text: $gatewayURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Text("Current: \(gatewayURL)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section(header: Label("Notifications", systemImage: "bell.fill")) {
                Toggle("Enable push notifications", isOn: $notificationsEnabled)
            }

            Section(header: Label("Voice", systemImage: "mic.fill")) {
                Toggle("Enable voice messages", isOn: $voiceEnabled)
                Picker("Voice", selection: $voiceName) {
                    Text("Samantha").tag("Samantha")
                    Text("Daniel").tag("Daniel")
                    Text("Alex").tag("Alex")
                }
            }

            Section(header: Label("Appearance", systemImage: "moon.circle.fill")) {
                Picker("Theme", selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section(header: Label("Data", systemImage: "square.and.arrow.up")) {
                if #available(iOS 16.0, *) {
                    ShareLink(item: exportText) {
                        Label("Export chat history", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        // Fallback: copy to clipboard
                        UIPasteboard.general.string = exportText
                    } label: {
                        Label("Copy chat history", systemImage: "doc.on.doc")
                    }
                }
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label("Clear Data (reset onboarding + skills)", systemImage: "trash")
                }
            }

            Section(header: Label("About", systemImage: "info.circle")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenClaw Gateway")
                        .font(.subheadline)
                    Text("Jarvis connects to your personal OpenClaw gateway for skills like email, calendar, and more.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Settings")
        .tint(.orangeBrand)
        .alert("Clear all data?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { clearAllData() }
        } message: {
            Text("This will reset onboarding and disconnect all skills. This action cannot be undone.")
        }
        .alert("Sign out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) { logout() }
        } message: {
            Text("You will be signed out and your local data will be cleared.")
        }
    }

    private var exportText: String {
        viewModel.messages.map { "\($0.role.rawValue): \($0.text)" }.joined(separator: "\n\n")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func clearAllData() {
        let defaults = UserDefaults.standard
        [
            "accountName",
            "accountEmail",
            "subscriptionTier",
            "gatewayURL",
            "notificationsEnabled",
            "voiceEnabled",
            "voiceName",
            "appearance",
            connectedSkillsKey
        ].forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        // Optionally clear chat messages locally
        viewModel.messages.removeAll()
    }

    private func logout() {
        // Clear account-specific info
        let defaults = UserDefaults.standard
        ["accountName", "accountEmail", "subscriptionTier"].forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
        viewModel.messages.removeAll()
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: ChatViewModel(gatewayClient: GatewayClient()))
    }
}
