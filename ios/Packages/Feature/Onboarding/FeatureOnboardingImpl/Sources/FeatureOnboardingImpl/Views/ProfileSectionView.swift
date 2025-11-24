import SwiftUI

struct ProfileSectionView: View {
    let snapshot: OnboardingProfileSnapshot
    let issueOptions: [OnboardingIssueOption]
    let selectedIssueID: String
    let selectedIssue: OnboardingIssueOption?
    let onIssueSelect: (String) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("确认信息")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                }

                ProfileCardView(snapshot: snapshot)

                VStack(alignment: .leading, spacing: 10) {
                    Label("关键问题", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green.opacity(0.9))

                    VStack(spacing: 12) {
                        ForEach(issueOptions) { option in
                            IssueRowView(
                                option: option,
                                isSelected: selectedIssueID == option.id,
                                onSelect: {
                                    onIssueSelect(option.id)
                                }
                            )
                        }
                    }
                }

                if let selected = selectedIssue {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("已选策略")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green.opacity(0.9))
                        Text(selected.title)
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

private struct ProfileCardView: View {
    let snapshot: OnboardingProfileSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("基础信息", systemImage: "sparkles")
                    .foregroundColor(.green.opacity(0.9))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow(alignment: .top) {
                    infoTile(title: "性别", value: snapshot.gender)
                    infoTile(title: "年龄", value: "\(snapshot.age)")
                }
                GridRow(alignment: .top) {
                    infoTile(title: "身高", value: "\(snapshot.height) cm")
                    infoTile(title: "体重", value: "\(snapshot.weight) kg")
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.6))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct IssueRowView: View {
    let option: OnboardingIssueOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.green.opacity(0.95))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text(option.detail)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.green.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
