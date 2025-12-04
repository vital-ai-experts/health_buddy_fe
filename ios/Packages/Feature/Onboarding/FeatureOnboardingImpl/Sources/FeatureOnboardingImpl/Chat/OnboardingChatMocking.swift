import Foundation

enum OnboardingChatMocking {
    enum Command {
        static let start = "#mock#onboarding_start"
        static let confirmProfile = "#mock#onboarding_confirm_profile"
        static let selectIssuePrefix = "#mock#onboarding_select_issue:"
        static let updateProfilePrefix = "#mock#onboarding_update_profile:"
        static let bookCallPrefix = "#mock#onboarding_book_call:"
        static let viewDungeon = "#mock#onboarding_view_dungeon"
        static let startDungeon = "#mock#onboarding_start_dungeon"
    }

    static let onboardingConversationPrefix = "onboarding_"

    static func makeConversationId() -> String {
        "\(onboardingConversationPrefix)\(Int(Date().timeIntervalSince1970))"
    }
}
