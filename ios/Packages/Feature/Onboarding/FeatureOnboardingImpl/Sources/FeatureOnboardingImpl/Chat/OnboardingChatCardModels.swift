import Foundation

struct ProfileCardPayload: Codable {
    struct Issue: Codable, Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    let gender: String
    let age: Int
    let height: Int
    let weight: Int
    let issues: [Issue]
    let selectedIssueId: String
}

struct CallCardPayload: Codable {
    let phoneNumber: String
    let headline: String
    let note: String
    let ctaTitle: String?
    let requiresPhoneNumber: Bool?
    let loadingTitle: String?
    let hasFinished: Bool?
}

struct DungeonCardPayload: Codable {
    let title: String
    let subtitle: String
    let detail: String
    let primaryAction: String
    let secondaryAction: String
}

struct HealthConnectCardPayload: Codable {
    let title: String
    let description: String
    let connectButtonTitle: String
    let loadingTitle: String
    let analyzingHint: String
    let isFinished: Bool?
}

struct SingleChoiceCardPayload: Codable {
    struct Option: Codable, Identifiable {
        let id: String
        let title: String
        let subtitle: String?
    }

    let title: String
    let description: String?
    let options: [Option]
    let ctaTitle: String?
    let selectedId: String?
}
