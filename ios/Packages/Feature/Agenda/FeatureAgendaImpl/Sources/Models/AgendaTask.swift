import SwiftUI

struct AgendaTask: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let countdown: String
    let tags: [String]
    let reward: String
    let status: AgendaTaskStatus
    let accent: AgendaTheme
}

enum AgendaTaskStatus {
    case inProgress
    case completed
    case failed
}

enum AgendaTheme {
    case sunrise
    case coffee
    case midnight
    case epic
    case night
    case emerald
    case aqua
    case crimson
    case mint

    var gradient: LinearGradient {
        switch self {
        case .sunrise:
            LinearGradient(colors: [.orange.opacity(0.85), .pink.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .coffee:
            LinearGradient(colors: [.brown.opacity(0.8), .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .midnight:
            LinearGradient(colors: [.purple.opacity(0.75), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .epic:
            LinearGradient(colors: [.blue.opacity(0.85), .purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .night:
            LinearGradient(colors: [.indigo.opacity(0.8), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .emerald:
            LinearGradient(colors: [.green.opacity(0.8), .teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .aqua:
            LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .crimson:
            LinearGradient(colors: [.red.opacity(0.85), .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mint:
            LinearGradient(colors: [.mint.opacity(0.9), .teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
