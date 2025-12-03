import Foundation

enum OnboardingStep: Int, CaseIterable {
    case intro
    case scan

    var title: String {
        switch self {
        case .intro:
            return "极简启动"
        case .scan:
            return "数据扫描"
        }
    }
}
