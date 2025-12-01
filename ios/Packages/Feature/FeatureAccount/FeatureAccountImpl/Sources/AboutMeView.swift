import SwiftUI
import DomainAuth
import LibraryServiceLoader
import LibraryBase

/// 关于我页面 - 展示AI对用户的全部理解和数字孪生
public struct AboutMeView: View {
    @State private var user: DomainAuth.User?
    @State private var isLoading = true
    @State private var showingInfoSheet = false

    private let authService: AuthenticationService

    public init(
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self)
    ) {
        self.authService = authService
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部：头像和昵称
                headerSection
                    .padding(.top, 32)
                    .padding(.bottom, 40)

                // AI对用户的理解内容
                contentSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserInfo()
        }
        .sheet(isPresented: $showingInfoSheet) {
            infoSheetContent
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
            } else {
                // 头像
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.8))

                // 昵称
                Text(user?.fullName ?? "用户")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 24) {
            // 模块标题：关于我
            sectionHeader(
                title: "关于我",
                showInfo: true,
                onInfoTapped: { showingInfoSheet = true }
            )

            // 目标 (The Core Drivers)
            aiInsightCard(
                title: "目标",
                subtitle: "The Core Drivers",
                content: goalsContent
            )

            // 生理信息 (Bio-Hardware)
            aiInsightCard(
                title: "生理信息",
                subtitle: "Bio-Hardware",
                content: bioHardwareContent
            )

            // 行为与偏好 (Neuro-Software)
            aiInsightCard(
                title: "行为与偏好",
                subtitle: "Neuro-Software",
                content: neuroSoftwareContent
            )

            // 历史档案 (The Archives)
            aiInsightCard(
                title: "历史档案",
                subtitle: "The Archives",
                content: archivesContent
            )
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, showInfo: Bool = false, onInfoTapped: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)

            if showInfo {
                Button(action: onInfoTapped) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }

    // MARK: - AI Insight Card

    @ViewBuilder
    private func aiInsightCard(title: String, subtitle: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 卡片标题
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // 卡片内容
            content
        }
        .padding(24)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Content Builders

    @ViewBuilder
    private var goalsContent: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🏷️",
                    title: "表层意图 (Surface Goal)",
                    description: ""提升精力，消除下午的脑雾。""
                )

                insightItem(
                    emoji: "🔑",
                    title: "深层动机 (Deep Motivation)",
                    description: "[职业恐惧]：你曾在对话中提到"担心35岁后拼不过年轻人"。你的核心驱动力不是健康本身，而是**"保持职场竞争力"和"认知敏锐度"**。"
                )

                insightItem(
                    emoji: "🚫",
                    title: "潜在障碍 (The Obstacle)",
                    description: "[全有全无心态]：你倾向于制定完美的计划，一旦有一天没做到（比如偷吃了），就会产生强烈的挫败感并彻底放弃。",
                    aiThinking: "需为你提供高容错率的方案。"
                )
            }
        )
    }

    @ViewBuilder
    private var bioHardwareContent: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🧬",
                    title: "昼夜节律 (Chronotype)",
                    description: "[夜猫子型 (Wolf)]：数据显示你的自然觉醒时间在 09:30。强迫 06:00 起床会让你皮质醇飙升。",
                    aiThinking: "当前策略 - 推迟高强度任务至 10:00 以后。"
                )

                insightItem(
                    emoji: "☕️",
                    title: "咖啡因代谢 (Caffeine Sensitivity)",
                    description: "[慢代谢者]：你在下午 14:00 喝咖啡会导致当晚入睡潜伏期增加 45 分钟。",
                    aiThinking: "当前策略 - 为你设置了 12:00 的咖啡因熔断机制。"
                )

                insightItem(
                    emoji: "🔋",
                    title: "压力耐受度 (Stress Resilience)",
                    description: "[中低]：静息心率 (RHR) 对压力反应敏感。高压会议后，你的 HRV 恢复时间通常需要 4 小时。"
                )
            }
        )
    }

    @ViewBuilder
    private var neuroSoftwareContent: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                insightItem(
                    emoji: "🥗",
                    title: "饮食弱点 (Dietary Kryptonite)",
                    description: "[碳水安抚]：在高压状态下（心率 > 100），你点"高碳水外卖"的概率高达 90%。"
                )

                insightItem(
                    emoji: "🏃",
                    title: "运动偏好 (Exercise Preference)",
                    description: "[独狼模式] & [数据驱动]：你不喜欢团课，喜欢盯着 Apple Watch 的圆环看。你更愿意执行"且有明确数据反馈"的任务（如 Zone 2 跑步），而不是模糊的任务（如冥想）。"
                )

                insightItem(
                    emoji: "💤",
                    title: "助眠触发器 (Sleep Trigger)",
                    description: "[声音敏感]：白噪音对你无效，但"播客（人声）"能让你在 15 分钟内入睡。"
                )
            }
        )
    }

    @ViewBuilder
    private var archivesContent: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("❌ 过去失败的项目")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 生酮饮食")
                            .font(.system(size: 15, weight: .medium))
                        Text("  坚持了 2 周。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("  失败原因：社交困扰，无法和同事聚餐。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 晨跑计划")
                            .font(.system(size: 15, weight: .medium))
                        Text("  坚持了 3 天。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("  失败原因：起不来，导致全天精神萎靡。")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("✅ 本次策略调整")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)

                    Text("• 不采用极端饮食，改为"饮食顺序调整法"。")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)

                    Text("• 不强迫晨跑，改为"下班后快走"。")
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }
        )
    }

    // MARK: - Insight Item

    @ViewBuilder
    private func insightItem(emoji: String, title: String, description: String, aiThinking: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 20))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)

            if let thinking = aiThinking {
                HStack(alignment: .top, spacing: 8) {
                    Text("AI 🤔:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)

                    Text(thinking)
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(12)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Info Sheet

    @ViewBuilder
    private var infoSheetContent: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("这是基于我们过去的 42 次对话、Onboarding 访谈以及 14 天的穿戴数据，我为你构建的"数字孪生"。")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineSpacing(6)

                    Text("如果我有理解错的地方，请随时点击修正。你的修正会让我的决策更精准。")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                }
                .padding(24)
            }
            .navigationTitle("关于数字孪生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingInfoSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Data Loading

    private func loadUserInfo() async {
        isLoading = true
        do {
            user = try await authService.getCurrentUser()
        } catch {
            Log.e("Failed to load user info: \(error)", category: "AboutMe")
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AboutMeView()
    }
}
