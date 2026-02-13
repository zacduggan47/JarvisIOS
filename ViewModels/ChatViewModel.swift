import Foundation
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let gatewayURL: String
    private let webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    
    init(gatewayURL: String = "wss://your-gateway.com/ws") {
        self.gatewayURL = gatewayURL
        self.session = URLSession(configuration: .default)
        
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hey! I'm Jarvis. How can I help you today?",
            isFromUser: false
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(content: inputText, isFromUser: true)
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await sendToGateway(message: messageToSend)
                
                let assistantMessage = ChatMessage(
                    content: response,
                    isFromUser: false
                )
                messages.append(assistantMessage)
            } catch {
                errorMessage = "Failed to get response. Please try again."
                
                let fallbackMessage = ChatMessage(
                    content: "Sorry, I couldn't get a response. Try again?",
                    isFromUser: false
                )
                messages.append(fallbackMessage)
            }
            isLoading = false
        }
    }
    
    private func sendToGateway(message: String) async throws -> String {
        let url = URL(string: "\(gatewayURL)/chat")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = GatewayMessage(
            type: "chat",
            content: message,
            userId: nil
        )
        
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let gatewayResponse = try JSONDecoder().decode(GatewayResponse.self, from: data)
        return gatewayResponse.content
    }
}
