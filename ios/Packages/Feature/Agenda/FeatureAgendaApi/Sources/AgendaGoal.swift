import Foundation

/// 长期挑战的目标定义
public struct AgendaGoal: Identifiable, Equatable, Hashable {
    public let id: String
    public let icon: String  // 以 emoji 作为临时图标
    public let title: String

    public init(id: String = UUID().uuidString, icon: String, title: String) {
        self.id = id
        self.icon = icon
        self.title = title
    }
}

/// 负责管理 Agenda 目标数据的协议
public protocol AgendaGoalManaging: AnyObject {
    var goals: [AgendaGoal] { get }
    var defaultSelectedGoalId: String? { get set }

    func goal(withId id: String) -> AgendaGoal?
}

public extension AgendaGoal {
    /// 预置的 mock 目标
    static let mockGoals: [AgendaGoal] = [
        AgendaGoal(id: "strong_me", icon: "💪", title: "强壮的我"),
        AgendaGoal(id: "sleep_master", icon: "😴", title: "自催眠大师"),
        AgendaGoal(id: "yoga_master", icon: "🧘", title: "观呼吸菩萨"),
        AgendaGoal(id: "wall_street_wolf", icon: "💰", title: "华尔街之狼")
    ]
}
