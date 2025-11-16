import Foundation

/// Generator for random health tasks
struct TaskGenerator {
    /// Possible activity tasks
    private static let activities = [
        "Take a 10-minute walk 🚶",
        "Do 20 push-ups 💪",
        "Stand up and stretch 🧘",
        "Run for 15 minutes 🏃",
        "Do 30 jumping jacks 🤸",
        "Take the stairs instead of elevator 🪜",
        "Drink a glass of water 💧",
        "Do 15 squats 🦵",
        "Practice deep breathing for 5 minutes 🌬️",
        "Walk 1000 steps 👣",
        "Do 10 lunges on each leg 🏋️",
        "Hold a plank for 30 seconds 🧘‍♂️",
        "Do 20 sit-ups 🏃‍♀️",
        "Stretch your arms and shoulders 🤗",
        "Dance to your favorite song 💃"
    ]

    /// Generate a random task
    static func generateTask() -> String {
        activities.randomElement() ?? "Take a short walk 🚶"
    }

    /// Generate a task based on time of day
    static func generateContextualTask() -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 6..<9:
            // Morning tasks
            return ["Morning stretch 🌅", "Quick morning jog 🏃", "Start your day with 20 push-ups 💪"].randomElement()!
        case 12..<14:
            // Lunch time
            return ["Take a lunch walk 🚶", "Post-lunch stretch 🧘", "Walk around the block 👣"].randomElement()!
        case 15..<17:
            // Afternoon slump
            return ["Stand up and move 🤸", "Quick energy boost: 15 squats 🦵", "Refresh with a short walk 🚶"].randomElement()!
        case 18..<21:
            // Evening
            return ["Evening walk 🌆", "Wind down with yoga 🧘", "Light exercise before dinner 🏃"].randomElement()!
        default:
            return generateTask()
        }
    }
}
