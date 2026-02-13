#if canImport(AppIntents)
import AppIntents
import Foundation

// MARK: - Gateway bridge for intents
protocol JarvisGatewayCommanding {
    func runCommand(_ text: String) async throws
}

extension GatewayClient: JarvisGatewayCommanding {
    func runCommand(_ text: String) async throws {
        // Minimal stub. Send text to your gateway chat endpoint or command endpoint.
        // If you already have a chat send API, call it here.
        // For now, we perform a simple POST to /v1/chat with {"text": ...}.
        let defaults = UserDefaults.standard
        let stored = defaults.string(forKey: "gatewayURL") ?? "http://localhost:18789/v1/chat"
        guard let url = URL(string: stored) else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["text": text]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}

// MARK: - RunJarvisCommand Intent
@available(iOS 16.0, *)
struct RunJarvisCommand: AppIntent {
    static var title: LocalizedStringResource = "Run Jarvis Command"
    static var description = IntentDescription("Send a command to Jarvis via your Gateway.")

    @Parameter(title: "Command") var command: String

    func perform() async throws -> some IntentResult {
        do {
            try await GatewayClient().runCommand(command)
            return .result(value: "Success")
        } catch {
            throw error
        }
    }
}

// MARK: - App Shortcuts
@available(iOS 16.0, *)
struct JarvisShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(intent: MorningBriefIntent(), phrases: [
                "Morning Brief in \(.applicationName)"
            ], shortTitle: "Morning Brief", systemImageName: "sun.max.fill"),

            AppShortcut(intent: PlanMyDayIntent(), phrases: [
                "Plan my day in \(.applicationName)"
            ], shortTitle: "Plan My Day", systemImageName: "calendar"),

            AppShortcut(intent: SummarizeInboxIntent(), phrases: [
                "Summarize inbox in \(.applicationName)"
            ], shortTitle: "Summarize Inbox", systemImageName: "envelope.badge"),
        ]
    }
}

// Each shortcut maps to a RunJarvisCommand with a preset command string
@available(iOS 16.0, *)
struct MorningBriefIntent: AppIntent {
    static var title: LocalizedStringResource = "Morning Brief"
    static var description = IntentDescription("Give me my morning summary")

    func perform() async throws -> some IntentResult {
        try await GatewayClient().runCommand("Give me my morning summary")
        return .result(value: "Morning brief sent")
    }
}

@available(iOS 16.0, *)
struct PlanMyDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Plan My Day"
    static var description = IntentDescription("Plan my day")

    func perform() async throws -> some IntentResult {
        try await GatewayClient().runCommand("Plan my day")
        return .result(value: "Plan sent")
    }
}

@available(iOS 16.0, *)
struct SummarizeInboxIntent: AppIntent {
    static var title: LocalizedStringResource = "Summarize Inbox"
    static var description = IntentDescription("Summarize my unread emails")

    func perform() async throws -> some IntentResult {
        try await GatewayClient().runCommand("Summarize my unread emails")
        return .result(value: "Inbox summary sent")
    }
}
#endif
