import ActivityKit
import Foundation

/// Activity Attributes for Agenda Live Activity
@available(iOS 16.1, *)
public struct AgendaActivityAttributes: ActivityAttributes {
    /// Card type for Live Activity
    public enum CardType: String, Codable, Hashable {
        case task       // 任务卡片
        case inquiry    // 问询卡片
    }

    /// RPG-style Content State for Live Activity
    public struct ContentState: Codable, Hashable {
        // MARK: - Top Status Section
        public struct StatusInfo: Codable, Hashable {
            /// Status type identifier (e.g., "energy", "focus")
            public var type: String
            /// Status name (e.g., "电量", "脑力", "兴奋度")
            public var name: String
            /// Main status value (e.g., "30%", "高", "低")
            public var value: String
            /// Main status icon name (SF Symbol)
            public var icon: String
            /// List of active buffs/debuffs
            public var buffs: [BuffInfo]

            public init(type: String, name: String, value: String, icon: String, buffs: [BuffInfo]) {
                self.type = type
                self.name = name
                self.value = value
                self.icon = icon
                self.buffs = buffs
            }
        }

        /// Buff type classification
        public enum BuffType: String, Codable, Hashable {
            /// Positive buff (增益)
            case positive
            /// Negative buff/Debuff (减益)
            case negative
            /// Neutral buff (中性)
            case neutral
        }

        public struct BuffInfo: Codable, Hashable {
            /// Buff type (positive/negative/neutral)
            public var type: BuffType
            /// Buff icon identifier (SF Symbol)
            public var icon: String
            /// Short label for the buff
            public var label: String

            public init(type: BuffType, icon: String, label: String) {
                self.type = type
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
            /// Total countdown duration in seconds (optional,默认为 remainingTimeSeconds)
            public var totalTimeSeconds: Int?
            /// Progress bar color (hex string, e.g., "#FFD700")
            public var progressColor: String
            /// Current progress value (0.0 to 1.0)
            public var progress: Double
            /// (Optional) Remaining time in seconds
            public var remainingTimeSeconds: Int?
            /// Countdown start time，用于基于 remainingTimeSeconds 计算实时进度
            public var startAt: Date?

            public init(
                label: String,
                timeRange: String,
                progressColor: String,
                progress: Double,
                remainingTimeSeconds: Int? = nil,
                totalTimeSeconds: Int? = nil,
                startAt: Date? = nil
            ) {
                self.label = label
                self.timeRange = timeRange
                self.totalTimeSeconds = totalTimeSeconds
                self.progressColor = progressColor
                self.progress = progress
                self.remainingTimeSeconds = remainingTimeSeconds
                self.startAt = startAt
            }
        }

        // MARK: - Inquiry Card Section
        public struct InquiryInfo: Codable, Hashable {
            /// Question emoji
            public var emoji: String
            /// Question text
            public var question: String
            /// Available options
            public var options: [InquiryOptionInfo]

            public init(emoji: String, question: String, options: [InquiryOptionInfo]) {
                self.emoji = emoji
                self.question = question
                self.options = options
            }
        }

        public struct InquiryOptionInfo: Codable, Hashable {
            /// Option emoji
            public var emoji: String
            /// Option text
            public var text: String
            /// URL scheme to open when tapped
            public var scheme: String

            public init(emoji: String, text: String, scheme: String) {
                self.emoji = emoji
                self.text = text
                self.scheme = scheme
            }
        }

        // MARK: - Main Content State Properties
        /// Card type (task or inquiry)
        public var cardType: CardType
        /// Status info (for task cards)
        public var status: StatusInfo?
        /// Task info (for task cards)
        public var task: TaskInfo?
        /// Countdown info (for task cards)
        public var countdown: CountdownInfo?
        /// Inquiry info (for inquiry cards)
        public var inquiry: InquiryInfo?

        // MARK: - Initializers

        /// Initialize with task card data
        public init(status: StatusInfo, task: TaskInfo, countdown: CountdownInfo) {
            self.cardType = .task
            self.status = status
            self.task = task
            self.countdown = countdown
            self.inquiry = nil
        }

        /// Initialize with inquiry card data
        public init(inquiry: InquiryInfo) {
            self.cardType = .inquiry
            self.status = nil
            self.task = nil
            self.countdown = nil
            self.inquiry = inquiry
        }
    }

    /// User identifier (static during activity lifetime)
    public var userId: String

    public init(userId: String) {
        self.userId = userId
    }
}
