import ActivityKit
import Foundation

/// Activity Attributes for Agenda Live Activity
@available(iOS 16.1, *)
public struct AgendaActivityAttributes: ActivityAttributes {
    /// RPG-style Content State for Live Activity
    public struct ContentState: Codable, Hashable {
        // MARK: - Top Status Section
        public struct StatusInfo: Codable, Hashable {
            /// Status type identifier (e.g., "energy", "focus")
            public var type: String
            /// Main status value/title (e.g., "30%")
            public var title: String
            /// Main status icon name (SF Symbol)
            public var icon: String
            /// List of active buffs/debuffs
            public var buffs: [BuffInfo]

            public init(type: String, title: String, icon: String, buffs: [BuffInfo]) {
                self.type = type
                self.title = title
                self.icon = icon
                self.buffs = buffs
            }
        }

        public struct BuffInfo: Codable, Hashable {
            /// Buff icon identifier (SF Symbol)
            public var icon: String
            /// Short label for the buff
            public var label: String

            public init(icon: String, label: String) {
                self.icon = icon
                self.label = label
            }
        }

        // MARK: - Middle Task Section
        public struct TaskInfo: Codable, Hashable {
            /// Main task command/title
            public var title: String
            /// Detailed description (supports multi-line)
            public var description: String
            /// Action button configuration
            public var button: ButtonInfo

            public init(title: String, description: String, button: ButtonInfo) {
                self.title = title
                self.description = description
                self.button = button
            }
        }

        public struct ButtonInfo: Codable, Hashable {
            /// Button label text
            public var label: String
            /// Button icon identifier (SF Symbol)
            public var icon: String

            public init(label: String, icon: String) {
                self.label = label
                self.icon = icon
            }
        }

        // MARK: - Bottom Countdown Section
        public struct CountdownInfo: Codable, Hashable {
            /// Label text displayed above the bar
            public var label: String
            /// Time range text (e.g., "08:00 - 12:00")
            public var timeRange: String
            /// Progress bar color (hex string, e.g., "#FFD700")
            public var progressColor: String
            /// Current progress value (0.0 to 1.0)
            public var progress: Double
            /// (Optional) Remaining time in seconds
            public var remainingTimeSeconds: Int?

            public init(label: String, timeRange: String, progressColor: String, progress: Double, remainingTimeSeconds: Int? = nil) {
                self.label = label
                self.timeRange = timeRange
                self.progressColor = progressColor
                self.progress = progress
                self.remainingTimeSeconds = remainingTimeSeconds
            }
        }

        // MARK: - Main Content State Properties
        public var status: StatusInfo
        public var task: TaskInfo
        public var countdown: CountdownInfo

        public init(status: StatusInfo, task: TaskInfo, countdown: CountdownInfo) {
            self.status = status
            self.task = task
            self.countdown = countdown
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
}
