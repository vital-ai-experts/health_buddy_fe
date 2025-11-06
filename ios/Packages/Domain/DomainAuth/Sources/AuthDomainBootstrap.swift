import Foundation
import LibraryServiceLoader

/// Bootstrap configuration for authentication domain
public enum AuthDomainBootstrap {
    /// Configure and register authentication services
    public static func configure(manager: ServiceManager = .shared) {
        // Register authentication service
        manager.register(AuthenticationService.self) {
            AuthenticationServiceImpl()
        }
    }
}
