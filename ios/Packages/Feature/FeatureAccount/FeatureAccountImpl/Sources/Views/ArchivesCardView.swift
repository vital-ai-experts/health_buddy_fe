import SwiftUI
import ThemeKit

/// Archives card view displaying historical data
struct ArchivesCardView: View {
    let data: ArchivesData
    let onEdit: () -> Void
    
    var body: some View {
        AboutMeCardView(
            title: "历史档案",
            subtitle: "过往经验与策略",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("❌ 过去失败的项目")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.Palette.textPrimary)
                    
                    ForEach(data.failedProjects) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• \(project.name)")
                                .font(.system(size: 15, weight: .medium))
                            Text("  \(project.duration)")
                                .font(.system(size: 14))
                                .foregroundColor(.Palette.textSecondary)
                            Text("  失败原因：\(project.failureReason)")
                                .font(.system(size: 14))
                                .foregroundColor(.Palette.textSecondary)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("✅ 本次策略调整")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.Palette.successMain)
                    
                    ForEach(data.strategyAdjustments, id: \.self) { adjustment in
                        Text("• \(adjustment)")
                            .font(.system(size: 14))
                            .foregroundColor(.Palette.textPrimary)
                    }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ArchivesCardView(
            data: .mock,
            onEdit: { print("Edit archives") }
        )
        .padding()
    }
    .background(Color.Palette.surfaceElevated)
}
