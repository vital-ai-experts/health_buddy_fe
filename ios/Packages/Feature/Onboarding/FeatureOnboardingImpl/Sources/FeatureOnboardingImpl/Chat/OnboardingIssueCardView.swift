import SwiftUI
import ThemeKit

struct OnboardingIssueCardView: View {
    let payload: ProfileCardPayload?
    let onSelectIssue: (String) -> Void

    @State private var selectedIssueId: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("关键问题", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.Palette.successMain)

            VStack(spacing: 10) {
                ForEach(payload?.issues ?? []) { issue in
                    Button {
                        selectedIssueId = issue.id
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedIssueId == issue.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.Palette.successMain)
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
                                .stroke(selectedIssueId == issue.id ? Color.Palette.successMain.opacity(0.6) : Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }

            Button {
                guard !selectedIssueId.isEmpty else { return }
                onSelectIssue(selectedIssueId)
            } label: {
                HStack {
                    Spacer()
                    Text("确认关键问题")
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(selectedIssueId.isEmpty ? Color.Palette.surfaceElevatedBorder : Color.Palette.successMain)
                .foregroundColor(selectedIssueId.isEmpty ? Color.Palette.textSecondary : Color.Palette.textOnAccent)
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
}

#Preview {
    let payload = ProfileCardPayload(
        gender: "女",
        age: 28,
        height: 165,
        weight: 55,
        issues: [
            .init(id: "fatigue", title: "睡够 7 小时仍然很累", detail: "深睡 < 10%"),
            .init(id: "focus", title: "下午难集中", detail: "久坐 + HRV 偏低")
        ],
        selectedIssueId: "fatigue"
    )
    return OnboardingIssueCardView(
        payload: payload,
        onSelectIssue: { _ in }
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
}
