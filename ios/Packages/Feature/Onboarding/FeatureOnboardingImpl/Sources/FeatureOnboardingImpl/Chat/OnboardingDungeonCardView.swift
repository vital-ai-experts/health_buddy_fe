import SwiftUI
import ThemeKit

struct OnboardingDungeonCardView: View {
    let payload: DungeonCardPayload?
    let onViewDungeon: () -> Void
    let onStartDungeon: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(payload?.title ?? "已加入副本")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.Palette.textPrimary)
                if let subtitle = payload?.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.Palette.textSecondary)
                }
                if let detail = payload?.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.Palette.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Button(action: onViewDungeon) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text(payload?.secondaryAction ?? "查看详情")
                    }
                    .font(.callout.weight(.semibold))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.Palette.bgMuted)
                    .foregroundColor(.Palette.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: onStartDungeon) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text(payload?.primaryAction ?? "开启副本")
                    }
                    .font(.callout.weight(.semibold))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.Palette.infoMain)
                    .foregroundColor(.Palette.textOnAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
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
    }
}
