import FeatureHealthKitImpl
import FeatureAccountImpl
import FeatureChatImpl
import FeatureOnboardingImpl
import FeatureAgendaImpl
import DomainHealth
import DomainAuth
import DomainChat
import DomainOnboarding
import LibraryServiceLoader
import LibraryTrack

#if DEBUG
import FeatureDebugToolsImpl
#endif

enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // 1. 配置Library层
        TrackBootstrap.configure()  // Track层会自动注册CommonParamsProvider到Networking层

        // 2. 配置Domain层服务
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()
        OnboardingDomainBootstrap.configure()

        // 3. 注册Features
        HealthKitModule.register()
        AccountModule.register(router: router)
        ChatModule.register()
        OnboardingModule.register()
        AgendaModule.register()

        #if DEBUG
        DebugToolsFeatureModule.register(router: router)
        #endif
    }
}
