import SwiftUI
import ThemeKit

/// 副本详情页，展示 RPG 风格的挑战信息
struct DungeonDetailView: View {
    var onStart: () -> Void = {}
    private let gradientColors = [
        Color.Palette.bgBase,
        Color.Palette.bgMuted
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerSection
                    northStarSection
                    scienceSection
                    socialProofSection
                    rewardSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("我的副本")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                startButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }

    private var headerSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color.Palette.infoBgSoft, Color.Palette.infoMain.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 10) {
                label(title: "21天深度睡眠修护", icon: "map.fill", tint: Color.Palette.infoMain)

                VStack(alignment: .leading, spacing: 12) {
                    headerRow(title: "当前等级", value: "Lv.1 睡眠新手 ➔ 目标：Lv.10 满电玩家")
                    headerRow(title: "挑战周期", value: "3 周 (21 天)")
                }
                .padding(12)
                .background(Color.Palette.bgBase.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var northStarSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color.Palette.bgMuted, Color.Palette.infoBgSoft],
            startPoint: .top,
            endPoint: .bottom
        )) {
            VStack(alignment: .leading, spacing: 14) {
                label(title: "北极星指标", icon: "star.fill", tint: Color.Palette.warningMain)

                Text("用最直观的对比图表展示，一眼看懂差距。")
                    .font(.footnote)
                    .foregroundColor(.Palette.textSecondary)

                VStack(spacing: 12) {
                    comparisonRow(title: "你的现状", value: "深度睡眠 8%", color: Color.Palette.dangerMain, icon: "exclamationmark.octagon.fill", subtitle: "易疲劳、脑雾", progress: 0.08)
                    comparisonRow(title: "通关目标", value: "深度睡眠 15%", color: Color.Palette.successMain, icon: "checkmark.seal.fill", subtitle: "精力充沛、反应敏捷", progress: 0.15)
                }
                .padding(12)
                .background(Color.Palette.bgBase.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("达成这个指标，你每天醒来时将感觉年轻 5 岁。")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.Palette.successText)
            }
        }
    }

    private var scienceSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color.Palette.infoBgSoft, Color.Palette.infoMain.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "攻略来源：专业背书 (The Science)", icon: "brain.head.profile", tint: Color.Palette.infoMain)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(Color.Palette.infoMain, Color.Palette.textOnAccent)
                        .frame(width: 34, height: 34)
                        .background(Color.Palette.infoBgSoft.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("🗺️ 核心攻略支持：")
                            .font(.headline)
                            .foregroundColor(.Palette.textPrimary)
                        Text("基于 斯坦福大学 Huberman Lab 的“生物钟重置协议”。")
                            .foregroundColor(.Palette.textSecondary)
                        Text("核心机制： 我们不靠死撑意志力，而是利用**“光照”和“温差”**这两个生理开关，像调时钟一样调整你的身体。")
                            .foregroundColor(.Palette.textSecondary)
                    }
                }
            }
        }
    }

    private var socialProofSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color.Palette.successBgSoft, Color.Palette.successMain.opacity(0.16)],
            startPoint: .top,
            endPoint: .bottom
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "玩家数据：成功率 (The Social Proof)", icon: "person.3.fill", tint: Color.Palette.successMain)

                VStack(alignment: .leading, spacing: 6) {
                    Text("让用户觉得他不是小白鼠，而是加入了一个赢家俱乐部。")
                        .foregroundColor(.Palette.textSecondary)
                    Text("👥 玩家大数据：")
                        .font(.headline)
                        .foregroundColor(.Palette.textPrimary)
                    Text("已有 8,420 位像你一样的脑力工作者参与了此副本。\n91% 的玩家在 Day 7 成功摆脱了“起床困难症”。")
                        .foregroundColor(.Palette.textSecondary)
                }
            }
        }
    }

    private var rewardSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color.Palette.warningBgSoft, Color.Palette.warningMain.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "通关奖励 (The Reward)", icon: "gift.fill", tint: Color.Palette.warningMain)

                Text("把健康的收益具象化，变成游戏里的成就。")
                    .foregroundColor(.Palette.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("🎁 预期收益：")
                        .font(.headline)
                        .foregroundColor(.Palette.textPrimary)
                    rewardRow(title: "XP 经验值：", value: "+2000 (用于瓜分通关奖池)", icon: "sparkles")
                    rewardRow(title: "解锁成就徽章：", value: "🏅 “晨型人 (Morning Person)”", icon: "shield.checkered")
                }
                .padding(12)
                .background(Color.Palette.bgBase.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var startButton: some View {
        Button(action: {
            onStart()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color.Palette.warningText)
                Text("开启副本")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(Color.Palette.textOnAccent)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.Palette.warningMain, Color.Palette.warningHover],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.Palette.warningBorder.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.Palette.warningMain.opacity(0.45), radius: 12, x: 0, y: 8)
        }
    }

    private func sectionCard<Content: View>(background: LinearGradient, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Palette.borderSubtle.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.Palette.textPrimary.opacity(0.15), radius: 12, x: 0, y: 8)
    }

    private func label(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(tint)
            Text(title)
                .font(.headline)
                .foregroundColor(.Palette.textPrimary)
        }
    }

    private func headerRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.Palette.textSecondary)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.Palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonRow(title: String, value: String, color: Color, icon: String, subtitle: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.Palette.textPrimary)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(value)
                    .foregroundColor(.Palette.textPrimary)
                    .font(.subheadline.weight(.bold))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.Palette.borderSubtle.opacity(0.35))
                        .frame(height: 10)
                    Capsule()
                        .fill(color.opacity(0.7))
                        .frame(width: max(CGFloat(progress) * geometry.size.width * 3, 40), height: 10)
                }
            }
            .frame(height: 12)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.Palette.textSecondary)
        }
        .padding(10)
        .background(Color.Palette.bgBase.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rewardRow(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color.Palette.warningMain)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.Palette.textPrimary)
                Text(value)
                    .foregroundColor(.Palette.textSecondary)
            }
        }
    }
}

#Preview {
    DungeonDetailView()
        .environment(\.colorScheme, .dark)
}
