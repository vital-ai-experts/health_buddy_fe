import FeatureAccountImpl
import FeatureChatImpl
import FeatureOnboardingImpl
import FeatureAgendaImpl
import DomainHealth
import DomainAuth
import DomainChat
import LibraryServiceLoader
import LibraryTrack
import FeatureDebugToolsImpl

enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // 1. 配置Library层
        TrackBootstrap.configure()

        // 2. 配置Domain层服务
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // 3. 注册Features
        AccountModule.register(router: router)
        ChatModule.register(router: router)
        OnboardingModule.register()
        AgendaModule.register()
        DebugToolsFeatureModule.register(router: router)
    }
}
