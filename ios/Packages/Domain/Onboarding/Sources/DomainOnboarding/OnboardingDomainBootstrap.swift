import Foundation
import LibraryServiceLoader

/// Onboarding Domain 层服务注册
public enum OnboardingDomainBootstrap {
    /// 配置并注册 Onboarding 相关服务
    public static func configure(manager: ServiceManager = .shared) {
        // 注册 Mock 实现（Demo 使用）
        manager.register(OnboardingService.self) { MockOnboardingService() }
        
        // 后续可以替换为真实实现：
        // manager.register(OnboardingService.self) { RealOnboardingService() }
    }
}

