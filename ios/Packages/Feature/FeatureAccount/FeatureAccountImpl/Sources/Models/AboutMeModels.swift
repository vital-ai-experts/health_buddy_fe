import Foundation

// MARK: - Section Identifier

enum AboutMeSection: String, Identifiable, CaseIterable {
    case recentPattern
    case goals
    case bioHardware
    case neuroSoftware
    case archives

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recentPattern:
            return "近期模式回溯"
        case .goals:
            return "目标与核心驱动"
        case .bioHardware:
            return "生理信息"
        case .neuroSoftware:
            return "行为与偏好"
        case .archives:
            return "历史档案"
        }
    }

    var subtitle: String {
        switch self {
        case .recentPattern:
            return "12/02-12/05"
        case .goals:
            return "你的动机与挑战"
        case .bioHardware:
            return "你的生理特征"
        case .neuroSoftware:
            return "你的行为模式"
        case .archives:
            return "过往经验与策略"
        }
    }
}

// MARK: - Recent Pattern Data

struct RecentPatternData: Codable, Equatable {
    var content: String
    var pascalComment: String
}

// MARK: - Goals Data

struct GoalsData: Codable, Equatable {
    var surfaceGoal: String
    var deepMotivationTitle: String
    var deepMotivationContent: String
    var pascalComment: String
}

// MARK: - Bio-Hardware Data

struct BioHardwareData: Codable, Equatable {
    var chronotype: String
    var chronotypePascalComment: String
    var caffeineMetabolism: String
    var caffeineMetabolismPascalComment: String
    var stressResilience: String
}

// MARK: - Neuro-Software Data

struct NeuroSoftwareData: Codable, Equatable {
    var stressResponse: String
    var exercisePreference: String
}

// MARK: - Failed Project

struct FailedProject: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var duration: String
    var pascalComment: String
}

// MARK: - Archives Data

struct ArchivesData: Codable, Equatable {
    var failedProjects: [FailedProject]
}

// MARK: - Top-Level Data Model

struct AboutMeData: Codable, Equatable {
    var updateTime: String
    var recentPattern: RecentPatternData
    var goals: GoalsData
    var bioHardware: BioHardwareData
    var neuroSoftware: NeuroSoftwareData
    var archives: ArchivesData
}
