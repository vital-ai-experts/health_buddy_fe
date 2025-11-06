import Foundation
import LibraryServiceLoader

/// Bootstrap configuration for chat domain
public enum ChatDomainBootstrap {
    /// Configure and register chat services
    public static func configure(manager: ServiceManager = .shared) {
        // Register chat service
        manager.register(ChatService.self) {
            ChatServiceImpl()
        }
    }
}
