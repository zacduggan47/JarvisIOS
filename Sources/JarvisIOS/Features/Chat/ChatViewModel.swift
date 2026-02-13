import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]
    @Published var inputText = ""
    @Published var isSending = false
    @Published var errorMessage: String?

    private let gatewayClient: GatewayClient

    init(gatewayClient: GatewayClient) {
        self.gatewayClient = gatewayClient
        self.messages = [
            ChatMessage(role: .assistant, text: "Hi, I'm Jarvis. How can I help you today?")
        ]
    }

    func sendCurrentMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        inputText = ""
        errorMessage = nil
        isSending = true

        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)

        do {
            let reply = try await gatewayClient.send(message: text, history: messages)
            let assistantMessage = ChatMessage(
                role: .assistant,
                text: reply.isEmpty ? "I couldn't generate a response." : reply
            )
            messages.append(assistantMessage)
        } catch {
            errorMessage = error.localizedDescription
            messages.append(ChatMessage(role: .system, text: "Request failed. Please try again."))
        }

        isSending = false
    }
}
