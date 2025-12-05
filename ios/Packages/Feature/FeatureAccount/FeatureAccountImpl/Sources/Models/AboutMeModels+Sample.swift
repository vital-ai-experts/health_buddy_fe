import Foundation

// MARK: - Sample Data Extensions

extension RecentPatternData {
    static let mock = RecentPatternData(
        content: "回顾你过去 3 天的数据，你的睡眠时间在缩短，但工作时长在拉长。特别是昨天下午你的压力值长时间处于高位，入睡潜伏期也变长了，这是一个典型的过劳前兆。",
        pascalComment: "这几天我会强制降低你的任务难度。别想着破纪录了，这段时间先保证能睡个好觉。"
    )
}

extension GoalsData {
    static let mock = GoalsData(
        surfaceGoal: "提升精力，消除下午 3 点后的脑雾。",
        deepMotivationTitle: "深层动机——职场生存防御",
        deepMotivationContent: "说实话，你并不单纯是为了健康而健身。\n你对\"35 岁后竞争力下降\"有着深深的防御机制，所以把身体当成职场武器。你害怕的不是生病，而是\"变钝\"。这种恐惧给了你极强的爆发力，但也让你容易因完美主义而陷入崩溃。",
        pascalComment: "用恐惧当燃料，跑得确实快，但积碳也严重。这种搞法，等到 35 岁那天，你迎接的不是财务自由，而是肾上腺枯竭。咱们得换种活法，兄弟。"
    )
}

extension BioHardwareData {
    static let mock = BioHardwareData(
        chronotype: "你是不折不扣的\"狼型\"体质（自然觉醒 09:30），但现实很残酷，工作强迫你 07:00 起床。这意味着你每天都在倒 2.5 小时的\"时差\"。上午的脑雾不是你懒，是你的生物钟还在倒时差。",
        chronotypePascalComment: "别再看那些成功人士凌晨4点起床的鸡汤了，逆着基因做人真的很蠢。既然改不了上班时间，那咱们就得想办法在晚上把这个时差税给补回来。",
        caffeineMetabolism: "你的 CYP1A2 基因表达似乎不高。数据监测到：下午 2 点的一杯拿铁，能让你当晚的深睡直接减少 40%。对你来说，午后咖啡就是高利贷，第二天要连本带利来还。",
        caffeineMetabolismPascalComment: "",
        stressResilience: "你的静息心率（RHR）是压力的晴雨表。只要前一天开了高压会议，第二天 RHR 必涨。你的神经系统恢复得比别人慢，接受这个设定，别硬撑。"
    )
}

extension NeuroSoftwareData {
    static let mock = NeuroSoftwareData(
        stressResponse: "当你的日间压力值飙升（HRV < 25ms）时，你点\"高糖外卖\"的概率高达 90%。\n这不是意志力薄弱，这是你的大脑在急切地寻找多巴胺来对抗皮质醇。",
        exercisePreference: "对你来说，如果一次运动没有产生漂亮的\"心率曲线图\"，那它就约等于没做，数据反馈就是你的精神食粮。"
    )
}

extension ArchivesData {
    static let mock = ArchivesData(
        failedProjects: [
            FailedProject(
                name: "生酮饮食",
                duration: "存活时间：2 周",
                pascalComment: "在中国做生意还想断碳？这不仅是反人性，简直是反社交。咱们直接把这个剧本撕了。为了瘦两斤得罪一桌客户，这买卖不划算。"
            ),
            FailedProject(
                name: "清晨 6 点跑",
                duration: "存活时间：3 天",
                pascalComment: "这是一场典型的\"意志力 vs 基因\"的自杀式袭击。结果毫无悬念，基因完胜。下次别再试图暴力破解你的生物钟了，躺在床上多睡会儿不香吗？"
            )
        ]
    )
}

extension AboutMeData {
    static let mock = AboutMeData(
        updateTime: "12:00 2025-12-05",
        recentPattern: .mock,
        goals: .mock,
        bioHardware: .mock,
        neuroSoftware: .mock,
        archives: .mock
    )
}
