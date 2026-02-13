import Foundation

// Thin convenience wrapper to keep older call sites working while centralizing logic in ConnectService.
extension GatewayClient {
    func connectOnboarding(
        memoryAnswers: [String],
        soulAnswers: [String],
        subscriptionTier: String,
        connectedSkills: [String]
    ) async throws -> String {
        return try await ConnectService.connectOnboarding(
            memoryAnswers: memoryAnswers,
            soulAnswers: soulAnswers,
            subscriptionTier: subscriptionTier,
            connectedSkills: connectedSkills
        )
    }
}
