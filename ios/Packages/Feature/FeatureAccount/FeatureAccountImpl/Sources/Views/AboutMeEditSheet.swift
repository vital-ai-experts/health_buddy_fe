import SwiftUI
import ThemeKit

/// Edit sheet for About Me sections
struct AboutMeEditSheet: View {
    let section: AboutMeSection
    @Binding var data: AboutMeData
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedRecentPattern: RecentPatternData
    @State private var editedGoals: GoalsData
    @State private var editedBioHardware: BioHardwareData
    @State private var editedNeuroSoftware: NeuroSoftwareData
    @State private var editedArchives: ArchivesData

    init(section: AboutMeSection, data: Binding<AboutMeData>) {
        self.section = section
        self._data = data

        // Initialize edited state with current values
        _editedRecentPattern = State(initialValue: data.wrappedValue.recentPattern)
        _editedGoals = State(initialValue: data.wrappedValue.goals)
        _editedBioHardware = State(initialValue: data.wrappedValue.bioHardware)
        _editedNeuroSoftware = State(initialValue: data.wrappedValue.neuroSoftware)
        _editedArchives = State(initialValue: data.wrappedValue.archives)
    }
    
    var body: some View {
        NavigationView {
            Form {
                switch section {
                case .recentPattern:
                    recentPatternEditForm
                case .goals:
                    goalsEditForm
                case .bioHardware:
                    bioHardwareEditForm
                case .neuroSoftware:
                    neuroSoftwareEditForm
                case .archives:
                    archivesEditForm
                }
            }
            .navigationTitle("编辑\(section.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Recent Pattern Edit Form

    @ViewBuilder
    private var recentPatternEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("模式分析内容")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedRecentPattern.content)
                    .frame(minHeight: 100)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pascal 评论（不可编辑）")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))

                Text(editedRecentPattern.pascalComment)
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))
                    .padding()
                    .background(Color.Palette.surfaceElevated)
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Goals Edit Form

    @ViewBuilder
    private var goalsEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("表面意图")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedGoals.surfaceGoal)
                    .frame(minHeight: 60)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("深层动机标题")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextField("例如：深层动机——职场生存防御", text: $editedGoals.deepMotivationTitle)
                    .textFieldStyle(.roundedBorder)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("深层动机内容")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedGoals.deepMotivationContent)
                    .frame(minHeight: 100)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pascal 评论（不可编辑）")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))

                Text(editedGoals.pascalComment)
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))
                    .padding()
                    .background(Color.Palette.surfaceElevated)
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Bio-Hardware Edit Form

    @ViewBuilder
    private var bioHardwareEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("昼夜节律")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedBioHardware.chronotype)
                    .frame(minHeight: 80)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pascal 评论（不可编辑）")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))

                Text(editedBioHardware.chronotypePascalComment)
                    .font(.system(size: 14))
                    .foregroundColor(.Palette.textSecondary.opacity(0.6))
                    .padding()
                    .background(Color.Palette.surfaceElevated)
                    .cornerRadius(8)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("咖啡因代谢")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedBioHardware.caffeineMetabolism)
                    .frame(minHeight: 80)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("压力耐受度")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedBioHardware.stressResilience)
                    .frame(minHeight: 60)
            }
        }
    }
    
    // MARK: - Neuro-Software Edit Form

    @ViewBuilder
    private var neuroSoftwareEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("压力下的反应")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedNeuroSoftware.stressResponse)
                    .frame(minHeight: 80)
            }
        }

        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("运动偏好")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.Palette.textSecondary)

                TextEditor(text: $editedNeuroSoftware.exercisePreference)
                    .frame(minHeight: 80)
            }
        }
    }
    
    // MARK: - Archives Edit Form

    @ViewBuilder
    private var archivesEditForm: some View {
        Section(header: Text("已归档的失败项目")) {
            ForEach(Array(editedArchives.failedProjects.enumerated()), id: \.offset) { index, _ in
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("项目名称")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.Palette.textSecondary)
                        TextField("例如：生酮饮食", text: $editedArchives.failedProjects[index].name)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("存活时间")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.Palette.textSecondary)
                        TextField("例如：存活时间：2 周", text: $editedArchives.failedProjects[index].duration)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pascal 评论（不可编辑）")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.Palette.textSecondary.opacity(0.6))

                        Text(editedArchives.failedProjects[index].pascalComment)
                            .font(.system(size: 14))
                            .foregroundColor(.Palette.textSecondary.opacity(0.6))
                            .padding()
                            .background(Color.Palette.surfaceElevated)
                            .cornerRadius(8)
                    }
                }
            }
            .onDelete { indexSet in
                editedArchives.failedProjects.remove(atOffsets: indexSet)
            }

            Button(action: addFailedProject) {
                Label("添加失败项目", systemImage: "plus.circle.fill")
            }
        }
    }
    
    // MARK: - Helper Methods

    private func saveChanges() {
        switch section {
        case .recentPattern:
            data.recentPattern = editedRecentPattern
        case .goals:
            data.goals = editedGoals
        case .bioHardware:
            data.bioHardware = editedBioHardware
        case .neuroSoftware:
            data.neuroSoftware = editedNeuroSoftware
        case .archives:
            data.archives = editedArchives
        }
    }

    private func addFailedProject() {
        editedArchives.failedProjects.append(
            FailedProject(
                name: "",
                duration: "",
                pascalComment: ""
            )
        )
    }
}

#Preview {
    @Previewable @State var data = AboutMeData.mock
    
    AboutMeEditSheet(
        section: .goals,
        data: $data
    )
}
