import Foundation

struct AskRequest: Codable {
    let message: String
}

struct AskResponse: Codable {
    let reply: String
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String

    enum Role {
        case user
        case assistant
    }
}
