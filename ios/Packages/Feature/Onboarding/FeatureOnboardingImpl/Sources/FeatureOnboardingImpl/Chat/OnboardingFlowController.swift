import Foundation

/// 统一管理 Onboarding 结束等流程的控制器，后续可扩展更多动作
final class OnboardingFlowController: ObservableObject {
    private let finishHandler: () -> Void

    init(finish: @escaping () -> Void) {
        self.finishHandler = finish
    }

    func finish() {
        finishHandler()
    }
}
