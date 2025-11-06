import Foundation
import DomainOnboarding

/// 消息显示模型
struct MessageItem: Identifiable {
    let id: String
    let isBot: Bool
    let text: String
    let action: BotMessageAction?
    
    init(id: String = UUID().uuidString, isBot: Bool, text: String, action: BotMessageAction? = nil) {
        self.id = id
        self.isBot = isBot
        self.text = text
        self.action = action
    }
}

