import SwiftUI

/// Edit sheet for About Me sections
struct AboutMeEditSheet: View {
    let section: AboutMeSection
    @Binding var data: AboutMeData
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedGoals: GoalsData
    @State private var editedBioHardware: BioHardwareData
    @State private var editedNeuroSoftware: NeuroSoftwareData
    @State private var editedArchives: ArchivesData
    
    init(section: AboutMeSection, data: Binding<AboutMeData>) {
        self.section = section
        self._data = data
        
        // Initialize edited state with current values
        _editedGoals = State(initialValue: data.wrappedValue.goals)
        _editedBioHardware = State(initialValue: data.wrappedValue.bioHardware)
        _editedNeuroSoftware = State(initialValue: data.wrappedValue.neuroSoftware)
        _editedArchives = State(initialValue: data.wrappedValue.archives)
    }
    
    var body: some View {
        NavigationView {
            Form {
                switch section {
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
    
    // MARK: - Goals Edit Form
    
    @ViewBuilder
    private var goalsEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🏷️ 表层意图")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedGoals.surfaceGoal)
                    .frame(minHeight: 60)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔑 深层动机")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedGoals.deepMotivation)
                    .frame(minHeight: 80)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🚫 潜在障碍")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedGoals.obstacle)
                    .frame(minHeight: 80)
            }
        }
    }
    
    // MARK: - Bio-Hardware Edit Form
    
    @ViewBuilder
    private var bioHardwareEditForm: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🧬 昼夜节律")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedBioHardware.chronotype)
                    .frame(minHeight: 60)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("☕️ 咖啡因代谢")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedBioHardware.caffeineSensitivity)
                    .frame(minHeight: 60)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔋 压力耐受度")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
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
                Text("🥗 饮食弱点")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedNeuroSoftware.dietaryKryptonite)
                    .frame(minHeight: 60)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🏃 运动偏好")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedNeuroSoftware.exercisePreference)
                    .frame(minHeight: 80)
            }
        }
        
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("💤 助眠触发器")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                TextEditor(text: $editedNeuroSoftware.sleepTrigger)
                    .frame(minHeight: 60)
            }
        }
    }
    
    // MARK: - Archives Edit Form
    
    @ViewBuilder
    private var archivesEditForm: some View {
        Section(header: Text("❌ 过去失败的项目")) {
            ForEach(editedArchives.failedProjects.indices, id: \.self) { index in
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("项目名称")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("例如：生酮饮食", text: $editedArchives.failedProjects[index].name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("坚持时长")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextField("例如：坚持了 2 周。", text: $editedArchives.failedProjects[index].duration)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("失败原因")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        TextEditor(text: $editedArchives.failedProjects[index].failureReason)
                            .frame(minHeight: 60)
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
        
        Section(header: Text("✅ 本次策略调整")) {
            ForEach(editedArchives.strategyAdjustments.indices, id: \.self) { index in
                TextEditor(text: $editedArchives.strategyAdjustments[index])
                    .frame(minHeight: 60)
            }
            .onDelete { indexSet in
                editedArchives.strategyAdjustments.remove(atOffsets: indexSet)
            }
            
            Button(action: addStrategyAdjustment) {
                Label("添加策略调整", systemImage: "plus.circle.fill")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func saveChanges() {
        switch section {
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
                failureReason: ""
            )
        )
    }
    
    private func addStrategyAdjustment() {
        editedArchives.strategyAdjustments.append("")
    }
}

#Preview {
    @Previewable @State var data = AboutMeData.mock
    
    AboutMeEditSheet(
        section: .goals,
        data: $data
    )
}
