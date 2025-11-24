import Foundation

enum OnboardingCallState {
    case idle
    case waiting
    case inCall
    case completed

    var buttonTitle: String {
        switch self {
        case .idle:
            return "预约健康顾问来电"
        case .waiting:
            return "10秒内你将接到电话"
        case .inCall:
            return "通话中"
        case .completed:
            return "已完成通话，生成我的副本"
        }
    }

    var isProcessing: Bool {
        switch self {
        case .waiting, .inCall:
            return true
        case .idle, .completed:
            return false
        }
    }
}
