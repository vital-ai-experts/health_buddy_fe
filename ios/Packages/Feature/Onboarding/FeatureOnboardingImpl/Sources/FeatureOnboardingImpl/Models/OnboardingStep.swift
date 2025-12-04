import Foundation

enum OnboardingStep: Int, CaseIterable {
    case intro

    var title: String {
        switch self {
        case .intro:
            return "极简启动"
        }
    }
}
