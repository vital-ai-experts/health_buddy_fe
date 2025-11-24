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
