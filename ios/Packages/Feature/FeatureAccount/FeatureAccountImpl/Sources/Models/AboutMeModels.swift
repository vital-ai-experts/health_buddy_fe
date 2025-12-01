import Foundation

// MARK: - Section Identifier

enum AboutMeSection: String, Identifiable, CaseIterable {
    case goals
    case bioHardware
    case neuroSoftware
    case archives
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .goals:
            return "目标"
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

// MARK: - Goals Data

struct GoalsData: Codable, Equatable {
    var surfaceGoal: String
    var deepMotivation: String
    var obstacle: String
    var obstacleAIThinking: String
}

// MARK: - Bio-Hardware Data

struct BioHardwareData: Codable, Equatable {
    var chronotype: String
    var chronotypeAIThinking: String
    var caffeineSensitivity: String
    var caffeineSensitivityAIThinking: String
    var stressResilience: String
}

// MARK: - Neuro-Software Data

struct NeuroSoftwareData: Codable, Equatable {
    var dietaryKryptonite: String
    var exercisePreference: String
    var sleepTrigger: String
}

// MARK: - Failed Project

struct FailedProject: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var duration: String
    var failureReason: String
}

// MARK: - Archives Data

struct ArchivesData: Codable, Equatable {
    var failedProjects: [FailedProject]
    var strategyAdjustments: [String]
}

// MARK: - Top-Level Data Model

struct AboutMeData: Codable, Equatable {
    var goals: GoalsData
    var bioHardware: BioHardwareData
    var neuroSoftware: NeuroSoftwareData
    var archives: ArchivesData
}
