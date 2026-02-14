import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: ChatViewModel

    @AppStorage("accountName") private var accountName: String = ""
    @AppStorage("accountEmail") private var accountEmail: String = ""
    @AppStorage("subscriptionTier") private var subscriptionTier: String = "Free" // Free or Pro

    @AppStorage("gatewayURL") private var gatewayURL: String = "http://localhost:18789/v1/chat"

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notifyMorning") private var notifyMorning: Bool = true
    @AppStorage("notifyAfternoon") private var notifyAfternoon: Bool = true
    @AppStorage("notifyEvening") private var notifyEvening: Bool = true
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled: Bool = false
    @AppStorage("quietStart") private var quietStart: String = "22:00"
    @AppStorage("quietEnd") private var quietEnd: String = "07:00"

    @AppStorage("voiceEnabled") private var voiceEnabled: Bool = false
    @AppStorage("voiceName") private var voiceName: String = "Samantha" // Samantha/Daniel/Alex
    @AppStorage("voiceLocale") private var voiceLocale: String = Locale.current.identifier
    @AppStorage("voiceAutoSend") private var voiceAutoSend: Bool = false

    @AppStorage("appearance") private var appearance: String = "system" // system/light/dark
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = true

    @AppStorage("hidePreviews") private var hidePreviews: Bool = false
    @AppStorage("requireBiometricForSensitive") private var requireBiometricForSensitive: Bool = true

    @AppStorage("pkmAutoSync") private var pkmAutoSync: Bool = false
    @AppStorage("pkmSuggestInChat") private var pkmSuggestInChat: Bool = true

    @State private var showClearConfirm = false
    @State private var showLogoutConfirm = false
    @State private var shareURL: URL?
    @State private var showShare = false

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
                if notificationsEnabled {
                    Toggle("Morning (8am)", isOn: $notifyMorning)
                    Toggle("Afternoon (12pm)", isOn: $notifyAfternoon)
                    Toggle("Evening (6pm)", isOn: $notifyEvening)
                    Toggle("Quiet hours", isOn: $quietHoursEnabled)
                    if quietHoursEnabled {
                        HStack {
                            Text("Start")
                            Spacer()
                            TextField("HH:MM", text: $quietStart)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                        }
                        HStack {
                            Text("End")
                            Spacer()
                            TextField("HH:MM", text: $quietEnd)
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                        }
                    }
                    Button("Apply Schedule") {
                        Task {
                            await PushNotificationManager.shared.scheduleDailyNotifications(
                                morning: notifyMorning,
                                afternoon: notifyAfternoon,
                                evening: notifyEvening,
                                quietHoursEnabled: quietHoursEnabled,
                                quietStart: quietStart,
                                quietEnd: quietEnd
                            )
                        }
                    }
                    Button("Schedule 3 test notifications") {
                        Task { await PushNotificationManager.shared.scheduleTestNotifications() }
                    }
                }
            }

            Section(header: Label("Security", systemImage: "lock.fill")) {
                Toggle("Require Face ID / App Lock", isOn: $appLockEnabled)
            }

            Section(header: Label("Voice", systemImage: "mic.fill")) {
                Toggle("Enable voice messages", isOn: $voiceEnabled)
                Picker("Voice", selection: $voiceName) {
                    Text("Samantha").tag("Samantha")
                    Text("Daniel").tag("Daniel")
                    Text("Alex").tag("Alex")
                }
                Toggle("Enable voice input", isOn: $voiceEnabled)
                Picker("Language", selection: $voiceLocale) {
                    Text("English (US)").tag("en-US")
                    Text("German").tag("de-DE")
                    Text("French").tag("fr-FR")
                    Text("Spanish").tag("es-ES")
                }
                Toggle("Auto-send after pause", isOn: $voiceAutoSend)
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
                    Button("Export chat history") {
                        UIPasteboard.general.string = exportText
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

            Section(header: Label("Profile", systemImage: "person.text.rectangle")) {
                NavigationLink("Edit My Profile") {
                    MemoryEditorView()
                }
            }

            Section(header: Label("Permissions", systemImage: "checkmark.shield.fill")) {
                NavigationLink("Permissions") { PermissionsView() }
            }
            
            Section(header: Label("Personality", systemImage: "person.crop.square.filled.and.at.rectangle")) {
                NavigationLink("Change Personality") {
                    PersonalitySettingsView()
                }
            }

            Section(header: Label("Privacy & Security", systemImage: "lock.shield.fill")) {
                Toggle("Hide message previews", isOn: $hidePreviews)
                Toggle("Require Face ID for sensitive data", isOn: $requireBiometricForSensitive)
                Button("Export My Data") {
                    let data = SecurityCenter.shared.exportData()
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("jarvis_export.json")
                    try? data.write(to: url)
                    shareURL = url
                    showShare = true
                }
                Button(role: .destructive, "Delete My Data") {
                    Task {
                        let ok = await SecurityCenter.shared.authenticate(reason: "Confirm delete")
                        if ok {
                            SecurityCenter.shared.deleteAllData()
                        }
                    }
                }
            }
            
            Section(header: Label("PKM Settings", systemImage: "brain.head.profile")) {
                Toggle("Auto-sync PKM in background", isOn: $pkmAutoSync)
                Toggle("Include in Chat suggestions", isOn: $pkmSuggestInChat)
                HStack {
                    Text("Last synced")
                    Spacer()
                    Text(PKMManager.shared.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Items indexed")
                    Spacer()
                    Text("\(PKMManager.shared.index.items.count)")
                        .foregroundColor(.secondary)
                }
                Button("Clear PKM Cache", role: .destructive) {
                    try? PKMStorage.shared.saveIndex(.empty)
                    PKMManager.shared.load()
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
        .onChange(of: notificationsEnabled) { enabled in
            if enabled {
                PushNotificationManager.shared.requestAuthorization()
            }
        }
        .onAppear {
            PushNotificationManager.shared.register()
        }
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
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
            "notifyMorning",
            "notifyAfternoon",
            "notifyEvening",
            "quietHoursEnabled",
            "quietStart",
            "quietEnd",
            "voiceEnabled",
            "voiceName",
            "voiceLocale",
            "voiceAutoSend",
            "appearance",
            "appLockEnabled",
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

struct MemoryEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("onboardingAnswersData") private var onboardingAnswersData: Data = Data()

    @State private var memoryAnswers: [String] = Array(repeating: "", count: 7)
    @State private var soulAnswers: [String] = Array(repeating: "", count: 7)

    private let totalAnswersCount = 14

    private let memoryKey = "memoryAnswers"
    private let soulKey = "soulAnswers"

    var body: some View {
        Form {
            Section(header: Text("Memory")) {
                ForEach(0..<7, id: \.self) { i in
                    TextField("Memory Answer \(i + 1)", text: $memoryAnswers[i])
                }
            }

            Section(header: Text("Soul")) {
                ForEach(0..<7, id: \.self) { i in
                    TextField("Soul Answer \(i + 1)", text: $soulAnswers[i])
                }
            }

            Section {
                Button("Save Changes") {
                    saveAnswers()
                }
            }
        }
        .navigationTitle("Edit My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadAnswers)
    }

    private func loadAnswers() {
        let defaults = UserDefaults.standard

        if let memoryData = defaults.data(forKey: memoryKey),
           let soulData = defaults.data(forKey: soulKey),
           let loadedMemory = try? JSONDecoder().decode([String].self, from: memoryData),
           let loadedSoul = try? JSONDecoder().decode([String].self, from: soulData),
           loadedMemory.count == 7, loadedSoul.count == 7 {
            memoryAnswers = loadedMemory
            soulAnswers = loadedSoul
        } else if !onboardingAnswersData.isEmpty {
            if let combined = try? JSONDecoder().decode([String].self, from: onboardingAnswersData),
               combined.count == totalAnswersCount {
                memoryAnswers = Array(combined[0..<7])
                soulAnswers = Array(combined[7..<14])
            }
        } else {
            memoryAnswers = Array(repeating: "", count: 7)
            soulAnswers = Array(repeating: "", count: 7)
        }
    }

    private func saveAnswers() {
        let defaults = UserDefaults.standard

        // Save separately (old keys)
        if let memoryData = try? JSONEncoder().encode(memoryAnswers) {
            defaults.set(memoryData, forKey: memoryKey)
        }
        if let soulData = try? JSONEncoder().encode(soulAnswers) {
            defaults.set(soulData, forKey: soulKey)
        }

        // Save combined data (new key)
        let combined = memoryAnswers + soulAnswers
        if let combinedData = try? JSONEncoder().encode(combined) {
            defaults.set(combinedData, forKey: "onboardingAnswersData")
        }

        defaults.synchronize()

        // Placeholder: Update Gateway or any other related logic here

        dismiss()
    }
}

struct PermissionsView: View {
    @StateObject private var pm = PermissionManager.shared

    private let permissionInfo: [(PermissionManager.PermissionType, String, String)] = [
        (.locationWhenInUse, "location.fill", "Location (When In Use)"),
        (.locationAlways, "location.circle.fill", "Location (Always)"),
        (.calendar, "calendar", "Calendar"),
        (.contacts, "person.2.fill", "Contacts"),
        (.microphone, "mic.fill", "Microphone"),
        (.speech, "waveform", "Speech Recognition"),
        (.health, "heart.fill", "Health"),
        (.home, "house.fill", "Home"),
        (.mediaLibrary, "music.note.list", "Media Library"),
        (.notifications, "bell.badge.fill", "Notifications"),
        (.camera, "camera.fill", "Camera"),
        (.photos, "photo.fill.on.rectangle.fill", "Photos")
    ]

    var body: some View {
        List {
            ForEach(permissionInfo, id: \.0) { (type, iconName, title) in
                Section {
                    Button {
                        Task {
                            await pm.request(type)
                        }
                    } label: {
                        HStack {
                            Image(systemName: iconName)
                                .foregroundColor(.orangeBrand)
                            Text(title)
                            Spacer()
                            if let status = pm.statuses[type] {
                                Text(status.rawValue.capitalized)
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(status.color.opacity(0.2))
                                    .foregroundColor(status.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    if let status = pm.statuses[type], status == .denied || status == .restricted {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.orangeBrand)
                    }
                }
            }
        }
        .navigationTitle("Permissions")
        .tint(.orangeBrand)
        .onAppear {
            pm.refreshAll()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: activityItems, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PersonalitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("personalityId") private var personalityId: String = JarvisPersonality.jarvisAI.rawValue
    @State private var selected: JarvisPersonality? = JarvisPersonality(rawValue: JarvisPersonality.jarvisAI.rawValue)
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Jarvis").font(.title2.bold()).foregroundColor(.orangeBrand)
            PersonalityPickerView(selected: Binding(get: { selected }, set: { selected = $0; if let s = $0 { personalityId = s.rawValue } }))
            if let p = selected {
                VStack(spacing: 8) {
                    Text("\(p.emoji) \(p.name)").font(.headline)
                    Text(p.examplePhrases.randomElement() ?? "").font(.subheadline).foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            Button("Save") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.orangeBrand)
            Spacer()
        }
        .padding()
        .navigationTitle("Personality")
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: ChatViewModel(gatewayClient: GatewayClient()))
    }
}
