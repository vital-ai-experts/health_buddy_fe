import ActivityKit
import Foundation

/// Activity Attributes for Agenda Live Activity
@available(iOS 16.1, *)
public struct AgendaActivityAttributes: ActivityAttributes {
    /// Static attributes that don't change during the activity
    public struct ContentState: Codable, Hashable {
        /// Current weather information
        public var weather: String

        /// Current task for the user
        public var task: String

        /// Last update timestamp
        public var lastUpdate: Date

        public init(weather: String, task: String, lastUpdate: Date = Date()) {
            self.weather = weather
            self.task = task
            self.lastUpdate = lastUpdate
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
}
