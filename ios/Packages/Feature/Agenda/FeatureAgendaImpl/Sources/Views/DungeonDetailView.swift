import SwiftUI

/// 副本详情页，展示 RPG 风格的挑战信息
struct DungeonDetailView: View {
    private let gradientColors = [
        Color(red: 10/255, green: 14/255, blue: 26/255),
        Color(red: 16/255, green: 31/255, blue: 69/255),
        Color(red: 38/255, green: 74/255, blue: 105/255)
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
                .overlay(
                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .foregroundColor(.white.opacity(0.06))
                        .offset(x: 120, y: -260),
                    alignment: .topTrailing
                )
                .overlay(
                    Image(systemName: "hexagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .foregroundColor(.blue.opacity(0.08))
                        .rotationEffect(.degrees(12))
                        .offset(x: -140, y: 260),
                    alignment: .bottomLeading
                )
                .ignoresSafeArea()
            )
            .navigationTitle("副本详情")
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
            colors: [Color.purple.opacity(0.35), Color.blue.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 10) {
                label(title: "场景 3：副本交付 (The Reveal)", icon: "map.fill", tint: .yellow)

                VStack(alignment: .leading, spacing: 12) {
                    headerRow(title: "挑战名称", value: "21天深度睡眠修护 (Deep Sleep Repair)")
                    headerRow(title: "当前等级", value: "Lv.1 睡眠新手 ➔ 目标：Lv.10 满电玩家")
                    headerRow(title: "挑战周期", value: "3 周 (21 天)")
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var northStarSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color(red: 42/255, green: 66/255, blue: 111/255), Color(red: 25/255, green: 39/255, blue: 79/255)],
            startPoint: .top,
            endPoint: .bottom
        )) {
            VStack(alignment: .leading, spacing: 14) {
                label(title: "核心目标：北极星指标 (The North Star)", icon: "star.fill", tint: .orange)

                Text("用最直观的对比图表展示，一眼看懂差距。")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))

                VStack(spacing: 12) {
                    comparisonRow(title: "你的现状", value: "深度睡眠 8%", color: .red, icon: "exclamationmark.octagon.fill", subtitle: "易疲劳、脑雾", progress: 0.08)
                    comparisonRow(title: "通关目标", value: "深度睡眠 15%", color: .green, icon: "checkmark.seal.fill", subtitle: "精力充沛、反应敏捷", progress: 0.15)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("只要达成这个指标，你每天醒来时的体感将年轻 5 岁。")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.green.opacity(0.9))
            }
        }
    }

    private var scienceSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color(red: 53/255, green: 38/255, blue: 88/255), Color(red: 27/255, green: 18/255, blue: 48/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "攻略来源：专业背书 (The Science)", icon: "brain.head.profile", tint: .cyan)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(.cyan, .white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("🗺️ 核心攻略支持：")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("基于 斯坦福大学 Huberman Lab 的“生物钟重置协议”。")
                            .foregroundColor(.white.opacity(0.86))
                        Text("核心机制： 我们不靠死撑意志力，而是利用**“光照”和“温差”**这两个生理开关，像调时钟一样调整你的身体。")
                            .foregroundColor(.white.opacity(0.88))
                    }
                }
            }
        }
    }

    private var socialProofSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color(red: 31/255, green: 59/255, blue: 63/255), Color(red: 19/255, green: 32/255, blue: 36/255)],
            startPoint: .top,
            endPoint: .bottom
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "玩家数据：成功率 (The Social Proof)", icon: "person.3.fill", tint: .mint)

                VStack(alignment: .leading, spacing: 6) {
                    Text("让用户觉得他不是小白鼠，而是加入了一个赢家俱乐部。")
                        .foregroundColor(.white.opacity(0.82))
                    Text("👥 玩家大数据：")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("已有 8,420 位像你一样的脑力工作者参与了此副本。\n91% 的玩家在 Day 7 成功摆脱了“起床困难症”。")
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
    }

    private var rewardSection: some View {
        sectionCard(background: LinearGradient(
            colors: [Color(red: 83/255, green: 58/255, blue: 15/255), Color(red: 48/255, green: 29/255, blue: 10/255)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )) {
            VStack(alignment: .leading, spacing: 12) {
                label(title: "通关奖励 (The Reward)", icon: "gift.fill", tint: .yellow)

                Text("把健康的收益具象化，变成游戏里的成就。")
                    .foregroundColor(.white.opacity(0.82))

                VStack(alignment: .leading, spacing: 8) {
                    Text("🎁 预期收益：")
                        .font(.headline)
                        .foregroundColor(.white)
                    rewardRow(title: "XP 经验值：", value: "+2000 (用于瓜分通关奖池)", icon: "sparkles")
                    rewardRow(title: "解锁成就徽章：", value: "🏅 “晨型人 (Morning Person)”", icon: "shield.checkered")
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var startButton: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.yellow)
                Text("开启副本")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.black)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.95), Color.orange.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .orange.opacity(0.55), radius: 12, x: 0, y: 8)
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
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func label(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(tint)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    private func headerRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func comparisonRow(title: String, value: String, color: Color, icon: String, subtitle: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(value)
                    .foregroundColor(.white)
                    .font(.subheadline.weight(.bold))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 10)
                    Capsule()
                        .fill(color.opacity(0.7))
                        .frame(width: max(CGFloat(progress) * geometry.size.width * 3, 40), height: 10)
                }
            }
            .frame(height: 12)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.78))
        }
        .padding(10)
        .background(Color.black.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func rewardRow(title: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(value)
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }
}

#Preview {
    DungeonDetailView()
        .environment(\.colorScheme, .dark)
}
