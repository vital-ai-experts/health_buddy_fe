import FeatureAgendaApi

public final class AgendaGoalManager: AgendaGoalManaging {
    public private(set) var goals: [AgendaGoal]
    public var defaultSelectedGoalId: String?

    public init(
        goals: [AgendaGoal] = AgendaGoal.mockGoals,
        defaultSelectedGoalId: String? = nil
    ) {
        self.goals = goals
        self.defaultSelectedGoalId = defaultSelectedGoalId ?? goals.first?.id
    }

    public func goal(withId id: String) -> AgendaGoal? {
        goals.first { $0.id == id }
    }

    public func updateGoals(_ goals: [AgendaGoal]) {
        self.goals = goals
        if let current = defaultSelectedGoalId,
           goals.contains(where: { $0.id == current }) == false {
            defaultSelectedGoalId = goals.first?.id
        } else if defaultSelectedGoalId == nil {
            defaultSelectedGoalId = goals.first?.id
        }
    }
}
