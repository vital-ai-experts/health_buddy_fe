import Foundation
import SwiftUI

/// 自定义消息的数据载体，由外部模块提供渲染实现
public struct CustomRenderedMessage: Hashable, Identifiable {
    public let id: String
    public let type: String
    public let text: String
    public let timestamp: Date
    public let data: String?

    public init(id: String, type: String, text: String, timestamp: Date, data: String? = nil) {
        self.id = id
        self.type = type
        self.text = text
        self.timestamp = timestamp
        self.data = data
    }
}

public typealias CustomMessageRenderer = (CustomRenderedMessage, ChatContext) -> AnyView

/// 自定义消息渲染注册表，允许外部模块按类型注册渲染逻辑
public final class ChatMessageRendererRegistry {
    public static let shared = ChatMessageRendererRegistry()

    private var renderers: [String: CustomMessageRenderer] = [:]
    private let lock = NSLock()

    private init() {}

    public func register(type: String, renderer: @escaping CustomMessageRenderer) {
        lock.lock()
        renderers[type] = renderer
        lock.unlock()
    }

    public func renderer(for type: String) -> CustomMessageRenderer? {
        lock.lock()
        let renderer = renderers[type]
        lock.unlock()
        return renderer
    }

    public func hasRenderer(for type: String) -> Bool {
        lock.lock()
        let exists = renderers[type] != nil
        lock.unlock()
        return exists
    }
}
