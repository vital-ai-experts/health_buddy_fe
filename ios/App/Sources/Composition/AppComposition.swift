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
import LibraryNetworking
import LibraryTrack

#if DEBUG
import FeatureDebugToolsImpl
#endif

enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // 1. 配置APIClient的通用参数提供者
        // 必须在所有服务配置之前完成，确保所有API请求都包含通用参数
        APIClient.shared.setCommonParamsProvider(CommonParamsProviderImpl.shared)

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
