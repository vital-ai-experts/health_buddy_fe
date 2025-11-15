import Foundation
import LibraryServiceLoader
import FeatureAgendaApi

/// Agenda feature module registration
public enum AgendaModule {
    /// Register the Agenda feature
    public static func register(in manager: ServiceManager = .shared) {
        // Register builder to ServiceManager
        manager.register(FeatureAgendaBuildable.self) { AgendaBuilder() }

        // Register service to ServiceManager
        manager.register(AgendaService.self) { AgendaServiceImpl() }
    }
}
