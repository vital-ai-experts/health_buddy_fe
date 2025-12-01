import SwiftUI
import ThemeKit

/// Neuro-Software card view displaying behavioral preferences
struct NeuroSoftwareCardView: View {
    let data: NeuroSoftwareData
    let onEdit: () -> Void
    
    var body: some View {
        AboutMeCardView(
            title: "行为与偏好",
            subtitle: "你的行为模式",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🥗",
                    title: "饮食弱点",
                    description: data.dietaryKryptonite
                )
                
                insightItem(
                    emoji: "🏃",
                    title: "运动偏好",
                    description: data.exercisePreference
                )
                
                insightItem(
                    emoji: "💤",
                    title: "助眠触发器",
                    description: data.sleepTrigger
                )
            }
        }
    }
    
    @ViewBuilder
    private func insightItem(emoji: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.Palette.textPrimary)
            }
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.Palette.textSecondary)
                .lineSpacing(4)
        }
    }
}

#Preview {
    ScrollView {
        NeuroSoftwareCardView(
            data: .mock,
            onEdit: { print("Edit neuro-software") }
        )
        .padding()
    }
    .background(Color.Palette.surfaceElevated)
}
