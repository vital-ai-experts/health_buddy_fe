import SwiftUI
import ThemeKit

/// Neuro-Software card view displaying behavioral preferences
struct NeuroSoftwareCardView: View {
    let data: NeuroSoftwareData
    let onEdit: () -> Void

    var body: some View {
        AboutMeCardView(
            title: "🧠 行为与偏好",
            subtitle: "",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 20) {
                // Stress Response section
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "压力下的"碳水猎手"")

                    Text(data.stressResponse)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)
                }

                Divider()

                // Exercise Preference section
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(title: "运动模式——数据控")

                    Text(data.exercisePreference)
                        .font(.system(size: 15))
                        .foregroundColor(.Palette.textSecondary)
                        .lineSpacing(6)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.Palette.textPrimary)
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
    .background(Color.Palette.bgBase)
}
