import SwiftUI
import ThemeKit

struct OnboardingProfileCardView: View {
    let payload: ProfileCardPayload?
    let onConfirm: () -> Void
    let onSelectIssue: (String) -> Void

    @State private var selectedIssueId: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("确认信息")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.Palette.textPrimary)
                    Text("确认后我会按此生成策略")
                        .font(.subheadline)
                        .foregroundColor(.Palette.textSecondary)
                }
                Spacer()
            }

            infoGrid

            VStack(alignment: .leading, spacing: 10) {
                Label("关键问题", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.Palette.infoMain)

                VStack(spacing: 10) {
                    ForEach(payload?.issues ?? []) { issue in
                        Button {
                            selectedIssueId = issue.id
                            onSelectIssue(issue.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedIssueId == issue.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.Palette.infoMain)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(issue.title)
                                        .foregroundColor(.Palette.textPrimary)
                                        .font(.callout.weight(.semibold))
                                    Text(issue.detail)
                                        .foregroundColor(.Palette.textSecondary)
                                        .font(.footnote)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.Palette.bgMuted)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedIssueId == issue.id ? Color.Palette.infoMain.opacity(0.6) : Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }

            Button(action: onConfirm) {
                HStack {
                    Spacer()
                    Text("确认并生成策略")
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.Palette.infoMain)
                .foregroundColor(.Palette.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            selectedIssueId = payload?.selectedIssueId ?? ""
        }
        .onChange(of: payload?.selectedIssueId ?? "") { _, newValue in
            selectedIssueId = newValue
        }
    }

    @ViewBuilder
    private var infoGrid: some View {
        let name = payload?.name ?? "-"
        let gender = payload?.gender ?? "-"
        let age = payload?.age ?? 0
        let height = payload?.height ?? 0
        let weight = payload?.weight ?? 0

        VStack(alignment: .leading, spacing: 8) {
            Label("基础信息", systemImage: "person.crop.rectangle")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.Palette.infoMain)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    infoTile(title: "姓名", value: name)
                    infoTile(title: "性别", value: gender)
                }
                GridRow {
                    infoTile(title: "年龄", value: "\(age) 岁")
                    infoTile(title: "身高", value: "\(height) cm")
                }
                GridRow {
                    infoTile(title: "体重", value: "\(weight) kg")
                    infoTile(title: "问题", value: selectedIssueTitle)
                }
            }
        }
    }

    private var selectedIssueTitle: String {
        payload?.issues.first(where: { $0.id == selectedIssueId })?.title ?? "未选择"
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.Palette.textSecondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.Palette.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Palette.bgMuted)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
