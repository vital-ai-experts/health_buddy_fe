import SwiftUI

/// Goals card view displaying The Core Drivers
struct GoalsCardView: View {
    let data: GoalsData
    let onEdit: () -> Void
    
    var body: some View {
        AboutMeCardView(
            title: "目标",
            subtitle: "你的动机与挑战",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🏷️",
                    title: "表层意图",
                    description: "\"\(data.surfaceGoal)\""
                )
                
                insightItem(
                    emoji: "🔑",
                    title: "深层动机",
                    description: data.deepMotivation
                )
                
                insightItem(
                    emoji: "🚫",
                    title: "潜在障碍",
                    description: data.obstacle,
                    aiThinking: data.obstacleAIThinking
                )
            }
        }
    }
    
    @ViewBuilder
    private func insightItem(emoji: String, title: String, description: String, aiThinking: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            if let thinking = aiThinking {
                HStack(alignment: .top, spacing: 8) {
                    Text("AI 🤔:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text(thinking)
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(12)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    ScrollView {
        GoalsCardView(
            data: .mock,
            onEdit: { print("Edit goals") }
        )
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
