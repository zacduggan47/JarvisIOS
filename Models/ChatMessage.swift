import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(content: String, isFromUser: Bool) {
        self.id = UUID().uuidString
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}

struct GatewayMessage: Codable {
    let type: String
    let content: String
    let userId: String?
}

struct GatewayResponse: Codable {
    let type: String
    let content: String
    let timestamp: String?
}
