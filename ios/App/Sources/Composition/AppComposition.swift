import FeatureHealthKitImpl
import FeatureAccountImpl
import FeatureChatImpl
import DomainHealth
import DomainAuth
import DomainChat
import LibraryServiceLoader

enum AppComposition {
    @MainActor
    static func bootstrap() {
        // 1. 配置Domain层服务
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // 2. 注册Features
        HealthKitModule.register()
        AccountModule.register()
        ChatModule.register()
    }
}
