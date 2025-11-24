import Foundation

struct OnboardingScanLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

struct OnboardingIssueOption: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
}

struct OnboardingProfileSnapshot {
    let gender: String
    let age: Int
    let height: Int
    let weight: Int
}
