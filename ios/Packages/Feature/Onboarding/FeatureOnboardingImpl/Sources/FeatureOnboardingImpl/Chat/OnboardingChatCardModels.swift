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
}

struct DungeonCardPayload: Codable {
    let title: String
    let subtitle: String
    let detail: String
    let primaryAction: String
    let secondaryAction: String
}
