import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，展示 RPG 风格的每日任务清单
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    private let viewModel = AgendaTabViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.9), Color.blue.opacity(0.35)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        ForEach(viewModel.activeStages) { stage in
                            sectionHeader(stage: stage)

                            VStack(spacing: 14) {
                                ForEach(stage.tasks) { task in
                                    AgendaCardView(task: task)
                                }
                            }
                        }

                        if !viewModel.completedTasks.isEmpty {
                            Text("已完成 · 战利品记录")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 8)

                            VStack(spacing: 14) {
                                ForEach(viewModel.completedTasks) { task in
                                    AgendaCardView(task: task)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Agenda")
        }
        .onAppear {
            router.currentTab = .agenda
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日行动手册")
                .font(.largeTitle).bold()
                .foregroundColor(.white)
            Text("完成使命获取 XP，解锁更强的你")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                )
                .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }

    private func sectionHeader(stage: AgendaStage) -> some View {
        HStack(spacing: 10) {
            Text(stage.icon)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(stage.subtitle)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}

// MARK: - View Model & Models

private final class AgendaTabViewModel {
    let stages: [AgendaStage]

    init() {
        stages = AgendaStage.sampleStages
    }

    var activeStages: [AgendaStage] {
        stages.map { stage in
            let activeTasks = stage.tasks.filter { $0.status == .inProgress }
            return AgendaStage(
                id: stage.id,
                icon: stage.icon,
                title: stage.title,
                subtitle: stage.subtitle,
                theme: stage.theme,
                tasks: activeTasks
            )
        }
        .filter { !$0.tasks.isEmpty }
    }

    var completedTasks: [AgendaTask] {
        stages.flatMap { $0.tasks }.filter { $0.status == .completed }
    }
}

private struct AgendaStage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let theme: AgendaTheme
    let tasks: [AgendaTask]

    static let sampleStages: [AgendaStage] = [
        AgendaStage(
            icon: "🌞",
            title: "早晨阶段 (Morning Routine)",
            subtitle: "唤醒身体，启动日间模式",
            theme: .sunrise,
            tasks: [
                AgendaTask(
                    statusBar: "🔋 电量 30% | 🌚 Debuff：褪黑素残留",
                    title: "任务：采集光子",
                    subtitle: "去窗边/户外晒 5 分钟。向视网膜发送信号，定好今晚的入睡闹钟。",
                    countdown: "⏳ 剩余 15 分钟",
                    actionLabel: "完成",
                    aiFlow: "AI (检测)：请拍摄一张此时的天空或窗外景色，确认光照强度。\nAI (反馈)：✅ 光信号已确认！ (XP +20) 视交叉上核已启动日间模式。",
                    tag: "晨间觉醒",
                    reward: "+20 XP",
                    status: .inProgress,
                    accent: .sunrise
                ),
                AgendaTask(
                    statusBar: "🧠 脑力 40% | 🌵 Debuff：大脑干旱",
                    title: "任务：填充冷却液",
                    subtitle: "喝一杯 300ml 温水，让\"缩水\"的脑组织重新膨胀，提升反应速度。",
                    countdown: "⏳ 剩余 10 分钟",
                    actionLabel: "完成",
                    aiFlow: "AI：🌊 注入完成。 (净水值 +10) 血液粘稠度正在降低。",
                    tag: "水分补给",
                    reward: "+10 净水值",
                    status: .inProgress,
                    accent: .aqua
                )
            ]
        ),
        AgendaStage(
            icon: "☕️",
            title: "上午与午间 (Mid-day Performance)",
            subtitle: "保持专注与血糖稳定",
            theme: .coffee,
            tasks: [
                AgendaTask(
                    statusBar: "⚡️ 兴奋度 80% | ☕️ Buff：咖啡因即将失效",
                    title: "任务：最后一杯☕️",
                    subtitle: "如果要喝，必须现在喝。再晚摄入将变成今晚的失眠毒药。",
                    countdown: "⏳ 14:00 窗口关闭",
                    actionLabel: "完成",
                    aiFlow: "AI：你摄入咖啡因了吗？\nAI (反馈)：🛡️ 明智的防守。 (睡眠护盾 +50)",
                    tag: "理智防守",
                    reward: "+50 睡眠护盾",
                    status: .inProgress,
                    accent: .coffee
                ),
                AgendaTask(
                    statusBar: "🩸 血糖海啸预警 | 📉 风险：智商掉线",
                    title: "任务：燃烧葡萄糖",
                    subtitle: "饭后别坐下！快走 10 分钟，让大腿肌肉像海绵一样吸走血糖。",
                    countdown: "⏳ 剩余 20 分钟",
                    actionLabel: "完成",
                    aiFlow: "AI：✅ 同步完成：检测到 1200 步。 (能量 +30) ",
                    tag: "血糖防御",
                    reward: "+30 能量",
                    status: .inProgress,
                    accent: .crimson
                )
            ]
        ),
        AgendaStage(
            icon: "💼",
            title: "下午抗压 (Afternoon Survival)",
            subtitle: "避免过热与视疲劳",
            theme: .midnight,
            tasks: [
                AgendaTask(
                    statusBar: "🔥 CPU 过热 | 😡 Debuff：情绪脑劫持",
                    title: "任务：系统强制冷却",
                    subtitle: "执行“生理叹息”（两吸一呼），只需 60 秒，重启副交感神经。",
                    countdown: "⏳ 立即执行",
                    actionLabel: "完成",
                    aiFlow: "AI：自动播放 1 分钟呼吸引导音频。\nAI：❄️ 冷却成功。(冷静值 +40)",
                    tag: "急救",
                    reward: "+40 冷静值",
                    status: .inProgress,
                    accent: .mint
                ),
                AgendaTask(
                    statusBar: "👀 视觉耐久 10% | 🧟 Debuff：隧道视野",
                    title: "任务：全景扫描",
                    subtitle: "去窗边盯着远处看 30 秒，解除眼部肌肉痉挛，降低焦虑。",
                    countdown: "⏳ 剩余 5 分钟",
                    actionLabel: "完成",
                    aiFlow: "AI：🦅 视觉锁定解除。(鹰眼 Buff +1) 焦虑感降低。",
                    tag: "视神经重置",
                    reward: "+1 鹰眼 Buff",
                    status: .inProgress,
                    accent: .aqua
                )
            ]
        ),
        AgendaStage(
            icon: "⚔️",
            title: "超级任务 (Epic Quests)",
            subtitle: "高风险 · 高回报",
            theme: .epic,
            tasks: [
                AgendaTask(
                    statusBar: "🐲 BOSS 战：线粒体衰退 | ⚠️ 高难度・高回报",
                    title: "史诗任务：引擎重铸 (Engine Overhaul)",
                    subtitle: "进行 4 组 2 分钟全力冲刺，把心率推到 160+。",
                    countdown: "⏳ 今日内有效",
                    actionLabel: "⚔️ 接受挑战",
                    aiFlow: "AI：准备好让 Watch 记录心率了吗？\nAI：🎉 BOSS 击杀成功！钻石经验 +500。",
                    tag: "超级任务",
                    reward: "钻石经验 +500",
                    status: .inProgress,
                    accent: .crimson
                ),
                AgendaTask(
                    statusBar: "🧟 BOSS 战：算法恶魔 | 🚫 挑战人类意志力极限",
                    title: "史诗任务：静默领域",
                    subtitle: "21:00 起到明早 7 点，彻底物理隔离手机。",
                    countdown: "⏳ 22:00 前开启",
                    actionLabel: "⚔️ 开启锁定",
                    aiFlow: "AI：点击确认后启动深度专注模式。\nAI：🎉 传奇胜利！钻石经验 +800。",
                    tag: "超级任务",
                    reward: "钻石经验 +800",
                    status: .inProgress,
                    accent: .epic
                )
            ]
        ),
        AgendaStage(
            icon: "🌙",
            title: "晚间与睡眠 (Evening & Sleep)",
            subtitle: "切换模式，准备休息",
            theme: .night,
            tasks: [
                AgendaTask(
                    statusBar: "🔋 工作电量耗尽 | 🎭 Debuff：班味残留",
                    title: "任务：模式切换",
                    subtitle: "听 5 分钟白噪音，把工作压力留在门外。",
                    countdown: "⏳ 到家前有效",
                    actionLabel: "完成",
                    aiFlow: "AI：🏠 后台进程已清理。家庭和谐度 +50。",
                    tag: "下班仪式",
                    reward: "+50 和谐度",
                    status: .completed,
                    accent: .night
                ),
                AgendaTask(
                    statusBar: "🌙 褪黑素分泌期 | 💡 风险：强光抑制",
                    title: "任务：调暗灯光",
                    subtitle: "只留落地灯或台灯，让身体知道该睡觉了。",
                    countdown: "⏳ 剩余 30 分钟",
                    actionLabel: "完成",
                    aiFlow: "AI：✅ 环境合格。(睡意值 +20) 松果体开始批量生产褪黑素。",
                    tag: "睡眠加速",
                    reward: "+20 睡意值",
                    status: .completed,
                    accent: .night
                ),
                AgendaTask(
                    statusBar: "🧟 僵尸刷屏模式 | 📉 Debuff：多巴胺成瘾",
                    title: "任务：切断连接",
                    subtitle: "把手机放到卧室外，今晚的信息都是睡眠毒药。",
                    countdown: "⏳ 末班车 15 分钟后发车",
                    actionLabel: "完成",
                    aiFlow: "AI：🏆 意志力胜利！(意志力 +100) APP 进入助眠页面。",
                    tag: "数字戒断",
                    reward: "+100 意志力",
                    status: .completed,
                    accent: .night
                ),
                AgendaTask(
                    statusBar: "🌪️ 思绪风暴 | 🚫 风险：失眠焦虑",
                    title: "任务：强制关机",
                    subtitle: "闭眼跟随身体扫描，手动降低脑波频率。",
                    countdown: "⏳ 随时有效",
                    actionLabel: "完成",
                    aiFlow: "AI：🛡️ 补救成功。浅睡质量提升，今天依然能保持战斗力。",
                    tag: "睡眠补救",
                    reward: "补救成功",
                    status: .completed,
                    accent: .night
                )
            ]
        ),
        AgendaStage(
            icon: "🥗",
            title: "超级任务 I：彩虹协议",
            subtitle: "抗炎与抗氧化集齐五色",
            theme: .emerald,
            tasks: [
                AgendaTask(
                    statusBar: "🛡️ BOSS 战：炎症风暴 | 🩸 挑战：抗氧化剂收集",
                    title: "史诗任务：彩虹协议",
                    subtitle: "午餐必须包含 5 种不同颜色的天然食材。",
                    countdown: "⏳ 13:30 前有效",
                    actionLabel: "📸 拍照上传：你的餐盘",
                    aiFlow: "AI：🎉 协议生效！色彩识别通过，钻石经验 +600。",
                    tag: "超级任务",
                    reward: "钻石经验 +600",
                    status: .completed,
                    accent: .emerald
                )
            ]
        ),
        AgendaStage(
            icon: "🌅",
            title: "超级任务 III：晨曦猎人",
            subtitle: "早起征服者",
            theme: .sunrise,
            tasks: [
                AgendaTask(
                    statusBar: "☀️ BOSS 战：黑夜女神 | ⏰ 挑战：早起征服者",
                    title: "史诗任务：晨曦猎人",
                    subtitle: "在 7:30 之前走出家门，拍摄清晨的光线或空无一人的街道。",
                    countdown: "⏳ 07:30 任务失效",
                    actionLabel: "📸 拍照上传：清晨的世界",
                    aiFlow: "AI：🎉 捕获晨曦！钻石经验 +800，生物钟顶级校准。",
                    tag: "超级任务",
                    reward: "钻石经验 +800",
                    status: .inProgress,
                    accent: .sunrise
                )
            ]
        )
    ]
}

private struct AgendaTask: Identifiable {
    let id = UUID()
    let statusBar: String
    let title: String
    let subtitle: String
    let countdown: String
    let actionLabel: String
    let aiFlow: String
    let tag: String?
    let reward: String
    let status: AgendaTaskStatus
    let accent: AgendaTheme
}

private enum AgendaTaskStatus {
    case inProgress
    case completed
}

private enum AgendaTheme {
    case sunrise
    case coffee
    case midnight
    case epic
    case night
    case emerald
    case aqua
    case crimson
    case mint

    var gradient: LinearGradient {
        switch self {
        case .sunrise:
            LinearGradient(colors: [.orange.opacity(0.85), .pink.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .coffee:
            LinearGradient(colors: [.brown.opacity(0.8), .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .midnight:
            LinearGradient(colors: [.purple.opacity(0.75), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .epic:
            LinearGradient(colors: [.blue.opacity(0.85), .purple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .night:
            LinearGradient(colors: [.indigo.opacity(0.8), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .emerald:
            LinearGradient(colors: [.green.opacity(0.8), .teal.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .aqua:
            LinearGradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .crimson:
            LinearGradient(colors: [.red.opacity(0.85), .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mint:
            LinearGradient(colors: [.mint.opacity(0.9), .teal.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Components

private struct AgendaCardView: View {
    let task: AgendaTask

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(task.statusBar)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())

                Spacer()

                if task.status == .completed {
                    label(text: "已完成", systemImage: "checkmark.seal.fill", color: .green)
                } else {
                    label(text: "进行中", systemImage: "bolt.fill", color: .yellow)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.title3).bold()
                    .foregroundColor(.white)
                Text(task.subtitle)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                if let tag = task.tag {
                    label(text: tag, systemImage: "shield.fill", color: .orange)
                }

                label(text: task.countdown, systemImage: "hourglass", color: .white.opacity(0.8))
                label(text: task.reward, systemImage: "sparkles", color: .green)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("📱 进入 APP 后的交互")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
                Text(task.aiFlow)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
            }

            Button(action: {}) {
                HStack {
                    Text(task.actionLabel)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: task.status == .completed ? "checkmark.circle" : "flame.fill")
                }
                .foregroundColor(.black)
                .padding()
                .background(task.status == .completed ? Color.white.opacity(0.8) : Color.yellow)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(task.accent.gradient)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func label(text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption)
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }
}
