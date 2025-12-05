import SwiftUI
import ThemeKit

/// Archives card view displaying historical data
struct ArchivesCardView: View {
    let data: ArchivesData
    let onEdit: (() -> Void)?
    @State private var expandedProjects: Set<UUID> = []

    init(data: ArchivesData, onEdit: (() -> Void)? = nil) {
        self.data = data
        self.onEdit = onEdit
    }

    var body: some View {
        AboutMeCardView(
            title: "📂 历史档案",
            subtitle: "",
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(data.failedProjects) { (project: FailedProject) in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedProjects.contains(project.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedProjects.insert(project.id)
                                } else {
                                    expandedProjects.remove(project.id)
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
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
                        .padding(.top, 8)
                    } label: {
                        Text("已归档：\(project.name)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.Palette.textSecondary)
                    }
                    .animation(.easeInOut, value: expandedProjects)
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
