import Foundation

/// Simple thread-safe service locator for registering factories and resolving dependencies.
public final class ServiceManager {
    public static let shared = ServiceManager()

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private let lock = NSLock()

    private init() {}

    public func register<Service>(_ serviceType: Service.Type, factory: @escaping () -> Service) {
        let key = ObjectIdentifier(serviceType)
        lock.lock()
        factories[key] = factory
        lock.unlock()
    }

    public func resolve<Service>(_ serviceType: Service.Type) -> Service {
        let key = ObjectIdentifier(serviceType)
        lock.lock()
        defer { lock.unlock() }

        guard let service = factories[key]?() as? Service else {
            fatalError("Service of type \(serviceType) has not been registered.")
        }
        return service
    }
}
