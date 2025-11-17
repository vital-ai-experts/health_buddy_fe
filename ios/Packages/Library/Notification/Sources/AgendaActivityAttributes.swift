import ActivityKit
import Foundation

/// Activity Attributes for Agenda Live Activity
@available(iOS 16.1, *)
public struct AgendaActivityAttributes: ActivityAttributes {
    /// Static attributes that don't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Title of the live activity
        public var title: String

        /// Text content to display
        public var text: String

        public init(title: String = "Thrive mission 💪", text: String = "Deep breath") {
            self.title = title
            self.text = text
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
}
