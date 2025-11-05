import FeatureHealthKitImpl
import DomainHealth
import LibraryServiceLoader

enum AppComposition {
    @MainActor
    static func bootstrap() {
        // 1. 配置Domain层服务
        HealthDomainBootstrap.configure()

        // 2. 注册HealthKit Feature
        HealthKitModule.register()
    }
}
