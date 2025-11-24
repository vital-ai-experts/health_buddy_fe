import Foundation

enum OnboardingStep: Int, CaseIterable {
    case intro
    case scan
    case profile
    case call

    var title: String {
        switch self {
        case .intro:
            return "极简启动"
        case .scan:
            return "数据扫描"
        case .profile:
            return "确认信息"
        case .call:
            return "预约通话"
        }
    }
}
