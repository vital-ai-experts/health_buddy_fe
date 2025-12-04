import SwiftUI
import ThemeKit

/// Archives card view displaying historical data
struct ArchivesCardView: View {
    let data: ArchivesData
    let onEdit: () -> Void

    var body: some View {
        AboutMeCardView(
            title: "📂 历史档案",
            subtitle: "",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(data.failedProjects) { project in
                    VStack(alignment: .leading, spacing: 12) {
                        // Project header
                        HStack(spacing: 8) {
                            Text("已归档：")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.Palette.textPrimary)

                            Text(project.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.Palette.textPrimary)

                            Text("（失败）")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.Palette.errorMain)
                        }

                        // Duration
                        HStack(spacing: 8) {
                            Text("-")
                                .font(.system(size: 15))
                                .foregroundColor(.Palette.textSecondary)

                            Text(project.duration)
                                .font(.system(size: 15))
                                .foregroundColor(.Palette.textSecondary)
                        }

                        // Pascal's comment
                        PascalCommentView(comment: project.pascalComment)
                    }
                    .padding(.bottom, 8)
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
    .background(Color.Palette.bgBase)
}
