import Foundation
import LibraryServiceLoader
import FeatureAgendaApi

/// Agenda feature module registration
public enum AgendaModule {
    /// Register the Agenda feature
    public static func register(in manager: ServiceManager = .shared, router: RouteRegistering? = nil) {
        // Register builder to ServiceManager
        manager.register(FeatureAgendaBuildable.self) { AgendaBuilder() }

        // Register service to ServiceManager
        manager.register(AgendaService.self) { AgendaServiceImpl() }

        // 注册副本详情路由，供调试入口或深链使用
        if let router {
            router.register(path: "/dungeon_detail", defaultSurface: .sheet) { _ in
                let builder = manager.resolve(FeatureAgendaBuildable.self)
                return builder.makeDungeonDetailView()
            }
        }
    }
}
