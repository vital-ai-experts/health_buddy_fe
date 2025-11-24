import Foundation

enum OnboardingMockData {
    static let profileSnapshot = OnboardingProfileSnapshot(
        gender: "男",
        age: 30,
        height: 178,
        weight: 75
    )

    static let issueOptions: [OnboardingIssueOption] = [
        OnboardingIssueOption(
            id: "fatigue",
            title: "虽然睡够了 7 小时，但醒来依然像没睡一样累",
            detail: "AI 检测到深睡占比 < 10%"
        ),
        OnboardingIssueOption(
            id: "focus",
            title: "下午 3 点后注意力很难集中，必须靠咖啡续命",
            detail: "AI 检测到日间久坐 + 心率变异性低"
        ),
        OnboardingIssueOption(
            id: "bloat",
            title: "体重正常，但经常感觉身体“沉重”或水肿",
            detail: "AI 检测到步数与卡路里消耗不匹配"
        )
    ]

    static let scanLines: [OnboardingScanLine] = [
        OnboardingScanLine(text: "同步基本档案：性别 - 男"),
        OnboardingScanLine(text: "同步年龄：30 岁"),
        OnboardingScanLine(text: "同步身高：178 cm"),
        OnboardingScanLine(text: "同步体重：75 kg"),
        OnboardingScanLine(text: "读取最近一次心率：64 bpm"),
        OnboardingScanLine(text: "读取静息心率：58 bpm"),
        OnboardingScanLine(text: "过去 7 天平均心率：67 bpm"),
        OnboardingScanLine(text: "最近 30 天心率变异性均值：62 ms"),
        OnboardingScanLine(text: "最近一周静息心率波动范围：56 - 62 bpm"),
        OnboardingScanLine(text: "过去 30 天日均步数：8,420 步"),
        OnboardingScanLine(text: "过去 30 天日均爬楼：11 层"),
        OnboardingScanLine(text: "过去 30 天日均站立：13 小时"),
        OnboardingScanLine(text: "过去 30 天日均能量消耗：2,350 kcal"),
        OnboardingScanLine(text: "最近 7 天高强度训练：7 次，共 3 小时 40 分"),
        OnboardingScanLine(text: "睡眠质量：平均睡眠 7 小时 10 分"),
        OnboardingScanLine(text: "深睡占比：11%"),
        OnboardingScanLine(text: "REM 占比：20%"),
        OnboardingScanLine(text: "入睡时间波动：22:45 - 00:30"),
        OnboardingScanLine(text: "呼吸频率：16 次/分钟"),
        OnboardingScanLine(text: "血氧饱和度：平均 97%"),
        OnboardingScanLine(text: "体温偏移：+0.1℃"),
        OnboardingScanLine(text: "血压记录：近 30 天 118/74 mmHg"),
        OnboardingScanLine(text: "步态稳定性：轻度偏低"),
        OnboardingScanLine(text: "心率变异性均值：62 ms"),
        OnboardingScanLine(text: "昨日 HRV 峰值：78 ms"),
        OnboardingScanLine(text: "昨日 HRV 谷值：44 ms"),
        OnboardingScanLine(text: "过去 7 天 HRV 波动区间：44 - 80 ms"),
        OnboardingScanLine(text: "晨间 HRV 恢复指数：82 / 100"),
        OnboardingScanLine(text: "压力指数（近 24 小时）：轻度"),
        OnboardingScanLine(text: "压力高峰时段：15:00 - 16:30"),
        OnboardingScanLine(text: "训练后心率恢复时间：2 分 30 秒"),
        OnboardingScanLine(text: "VO2max 估算：44 ml·kg⁻¹·min⁻¹"),
        OnboardingScanLine(text: "最大摄氧量近 30 天趋势：+3%"),
        OnboardingScanLine(text: "日均站立间隔：每 52 分钟起身"),
        OnboardingScanLine(text: "血糖稳定性：优"),
        OnboardingScanLine(text: "低血糖风险：极低"),
        OnboardingScanLine(text: "高血糖风险：低"),
        OnboardingScanLine(text: "肌肉恢复评分：良好"),
        OnboardingScanLine(text: "骨骼肌量趋势：稳定"),
        OnboardingScanLine(text: "体脂率估算：17.5%"),
        OnboardingScanLine(text: "近 30 天平均步频：112 步/分钟"),
        OnboardingScanLine(text: "跑步对称性：1.02 (理想为 1.00)"),
        OnboardingScanLine(text: "踝部冲击评分：安全"),
        OnboardingScanLine(text: "静息血氧低谷：95%"),
        OnboardingScanLine(text: "体温恢复速度：正常"),
        OnboardingScanLine(text: "午后心率轻微上浮：+6 bpm"),
        OnboardingScanLine(text: "夜间心率最低点：50 bpm"),
        OnboardingScanLine(text: "夜间翻身次数：5 次"),
        OnboardingScanLine(text: "睡眠中呼吸暂停风险：极低"),
        OnboardingScanLine(text: "近 7 天平均卡路里摄入估算：2,150 kcal"),
        OnboardingScanLine(text: "蛋白质摄入估算：每公斤 1.4 g"),
        OnboardingScanLine(text: "水分摄入估算：2.6 L/天"),
        OnboardingScanLine(text: "微量元素缺口：镁、维生素 D"),
        OnboardingScanLine(text: "静息心率异常段检测中..."),
        OnboardingScanLine(text: "准备生成初步健康摘要..."),
        OnboardingScanLine(text: "正在读取过去 30 天睡眠记录..."),
        OnboardingScanLine(text: "发现异常静息心率波动..."),
        OnboardingScanLine(text: "识别到深夜屏幕使用模式"),
        OnboardingScanLine(text: "···"),
        OnboardingScanLine(text: "初步诊断生成中..."),
        OnboardingScanLine(text: "初步诊断完成")
    ]
}
