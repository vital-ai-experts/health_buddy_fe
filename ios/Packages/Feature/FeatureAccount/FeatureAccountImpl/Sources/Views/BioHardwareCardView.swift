import SwiftUI

/// Bio-Hardware card view displaying physiological information
struct BioHardwareCardView: View {
    let data: BioHardwareData
    let onEdit: () -> Void
    
    var body: some View {
        AboutMeCardView(
            title: "生理信息",
            subtitle: "你的生理特征",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🧬",
                    title: "昼夜节律",
                    description: data.chronotype,
                    aiThinking: data.chronotypeAIThinking
                )
                
                insightItem(
                    emoji: "☕️",
                    title: "咖啡因代谢",
                    description: data.caffeineSensitivity,
                    aiThinking: data.caffeineSensitivityAIThinking
                )
                
                insightItem(
                    emoji: "🔋",
                    title: "压力耐受度",
                    description: data.stressResilience
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
        BioHardwareCardView(
            data: .mock,
            onEdit: { print("Edit bio-hardware") }
        )
        .padding()
    }
    .background(Color(uiColor: .systemGroupedBackground))
}
