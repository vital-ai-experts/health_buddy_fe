extension AgendaTask {
    static let sampleTasks: [AgendaTask] = [
        AgendaTask(
            title: "任务：采集光子",
            subtitle: "去窗边/户外晒 5 分钟。向视网膜发送信号，定好今晚的入睡闹钟。",
            countdown: "⏳ 剩余 15 分钟",
            tags: ["晨间觉醒"],
            reward: "+20 XP",
            status: .inProgress,
            accent: .sunrise
        ),
        AgendaTask(
            title: "任务：填充冷却液",
            subtitle: "喝一杯 300ml 温水，让\"缩水\"的脑组织重新膨胀，提升反应速度。",
            countdown: "⏳ 剩余 10 分钟",
            tags: ["水分补给"],
            reward: "+10 净水值",
            status: .completed,
            accent: .aqua
        ),
        AgendaTask(
            title: "史诗任务：引擎重铸",
            subtitle: "进行 4 组 2 分钟全力冲刺，把心率推到 160+。",
            countdown: "⏳ 今日内有效",
            tags: ["超级任务", "心肺"],
            reward: "钻石经验 +500",
            status: .inProgress,
            accent: .crimson
        ),
        AgendaTask(
            title: "任务：燃烧葡萄糖",
            subtitle: "饭后别坐下！快走 10 分钟，让大腿肌肉像海绵一样吸走血糖。",
            countdown: "⏳ 剩余 20 分钟",
            tags: ["血糖防御"],
            reward: "+30 能量",
            status: .failed,
            accent: .epic
        ),
        AgendaTask(
            title: "任务：系统强制冷却",
            subtitle: "执行“生理叹息”（两吸一呼），只需 60 秒，重启副交感神经。",
            countdown: "⏳ 立即执行",
            tags: ["急救"],
            reward: "+40 冷静值",
            status: .inProgress,
            accent: .mint
        ),
        AgendaTask(
            title: "任务：全景扫描",
            subtitle: "去窗边盯着远处看 30 秒，解除眼部肌肉痉挛，降低焦虑。",
            countdown: "⏳ 剩余 5 分钟",
            tags: ["视神经重置"],
            reward: "+1 鹰眼 Buff",
            status: .inProgress,
            accent: .aqua
        ),
        AgendaTask(
            title: "超级任务：静默领域",
            subtitle: "21:00 起到明早 7 点，彻底物理隔离手机。",
            countdown: "⏳ 22:00 前开启",
            tags: ["超级任务", "睡眠优化"],
            reward: "钻石经验 +800",
            status: .inProgress,
            accent: .epic
        ),
        AgendaTask(
            title: "超级任务：彩虹协议",
            subtitle: "午餐必须包含 5 种不同颜色的天然食材。",
            countdown: "⏳ 13:30 前有效",
            tags: ["超级任务", "营养补充"],
            reward: "钻石经验 +600",
            status: .completed,
            accent: .emerald
        ),
        AgendaTask(
            title: "超级任务：晨曦猎人",
            subtitle: "在 7:30 之前走出家门，拍摄清晨的光线或空无一人的街道。",
            countdown: "⏳ 07:30 失效",
            tags: ["超级任务"],
            reward: "钻石经验 +800",
            status: .failed,
            accent: .sunrise
        )
    ]
}
