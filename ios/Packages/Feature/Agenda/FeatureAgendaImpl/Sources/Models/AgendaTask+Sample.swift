extension AgendaTask {
    static let sampleTasks: [AgendaTask] = [
        AgendaTask(
            icon: "☀️",
            title: "采集光子",
            reward: "+10 能量 解除褪黑素",
            description: "去户外或窗边晒 5 分钟。光线能触发皮质醇"开机"信号，消除起床气，更为今晚的深睡定好生物闹钟。",
            timeTag: "晨曦消失前（剩余 30 分钟）",
            completed: true,
            actionType: .photo
        ),
        AgendaTask(
            icon: "❄️",
            title: "迷走神经冷启动",
            reward: "+15 清醒度 强制消除脑雾",
            description: "用冷水泼脸 30 秒。低温触发"潜水反射"，提升去甲肾上腺素，像物理外挂一样暴力清除睡眠惯性，瞬间清醒。",
            timeTag: "醒后 30 分钟（剩余 12 分钟）",
            completed: false,
            actionType: .check
        ),
        AgendaTask(
            icon: "☕️",
            title: "咖啡因战术窗口",
            reward: "+20 专注 腺苷受体阻断",
            description: "此时皮质醇已回落，是摄入的最佳时机。这是今日最后窗口，再晚将覆盖半衰期，摧毁今晚的深睡修复力。",
            timeTag: "窗口期 09:30 - 11:30（将在 45 分钟后关闭）",
            completed: false,
            actionType: .photo
        ),
        AgendaTask(
            icon: "📉",
            title: "血糖海啸防御",
            reward: "+10 代谢 预防饭后昏迷",
            description: "饭后立刻快走 10 分钟。激活肌肉直接吸走血液游离糖，物理削平血糖峰值，避免胰岛素波动导致的午后崩溃。",
            timeTag: "血糖峰值即将到达（仅剩 20 分钟窗口）",
            completed: false,
            actionType: .watch
        ),
        AgendaTask(
            icon: "🧘‍♂️",
            title: "NSFR 神经重置",
            reward: "+30 精力 清理大脑缓存",
            description: "下午低谷别硬撑。NSFR 能引导脑波进入 Theta 状态，补充多巴胺；20 分钟即可重获相当于 2 小时睡眠的专注力。",
            timeTag: "下午 13:00 - 16:00 黄金时段",
            completed: false,
            actionType: .audio
        ),
        AgendaTask(
            icon: "📵",
            title: "数字日落",
            reward: "+25 睡意 褪黑素工厂启动",
            description: "调暗灯光，避免蓝光欺骗大脑。这能给松果体发送"天黑信号"，解除褪黑素封印，让你无需药物也能自然产生困意。",
            timeTag: "睡前 1.5 小时（目标：22:30 前完成）",
            completed: false,
            actionType: .check
        )
    ]
}
