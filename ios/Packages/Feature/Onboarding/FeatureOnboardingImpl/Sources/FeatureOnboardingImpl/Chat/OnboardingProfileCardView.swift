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
                        .foregroundColor(.white)
                    Text("确认后我会按此生成策略")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }

            infoGrid

            VStack(alignment: .leading, spacing: 10) {
                Label("关键问题", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.Palette.successMain)

                VStack(spacing: 10) {
                    ForEach(payload?.issues ?? []) { issue in
                        Button {
                            selectedIssueId = issue.id
                            onSelectIssue(issue.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: selectedIssueId == issue.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(.Palette.successMain)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(issue.title)
                                        .foregroundColor(.white)
                                        .font(.callout.weight(.semibold))
                                    Text(issue.detail)
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.footnote)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(selectedIssueId == issue.id ? Color.Palette.successMain.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1)
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
                .background(Color.Palette.successMain)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                .foregroundColor(.Palette.successMain)
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
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
