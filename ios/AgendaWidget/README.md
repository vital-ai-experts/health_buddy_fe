# 健康任务锁屏卡 Widget

## 功能概述

这是一个 iOS 锁屏卡片 Widget，用于展示用户的健康任务和待办事项。

### 当前状态

**🚧 开发中 - 使用 Mock 数据**

- ✅ Widget 框架已搭建完成
- ✅ 支持多种锁屏卡样式（圆形、矩形、内联）
- ✅ 每 5 分钟自动刷新
- ✅ 显示更新时间
- ⏳ 目前使用天气 API 作为 Mock 数据测试
- ⏳ 未来将替换为真实的健康任务数据

## 技术实现

### Mock 数据源

当前使用 [wttr.in](https://wttr.in) 天气 API 作为测试数据：
- API 端点：`https://wttr.in/Shanghai?format=j1`
- 无需 API Key，免费使用
- 返回 JSON 格式数据

### 数据映射

天气数据字段临时映射为健康任务字段：

| 天气字段 | 临时用途 | 未来替换为 |
|---------|---------|----------|
| temperature | 任务数量 | 今日待办任务数 |
| feelsLike | 紧急任务数 | 优先级高的任务数 |
| weatherDescription | 任务描述 | 主要任务描述 |
| humidity | 完成率 | 任务完成百分比 |
| windSpeed | 待办数 | 未完成任务数 |
| weatherCode | 任务类型 | 任务分类代码 |
| location | 用户标识 | 用户昵称 |

### 文件结构

```
AgendaWidget/
├── AgendaModels.swift       # 数据模型（包含 Mock 映射）
├── AgendaService.swift      # 数据服务（当前调用天气 API）
├── AgendaWidget.swift       # Widget 主文件
├── Info.plist              # Widget 配置
└── Assets.xcassets/        # 资源文件
```

## 支持的 Widget 样式

- **锁屏圆形卡片** (`accessoryCircular`) - 简洁显示图标和关键数据
- **锁屏矩形卡片** (`accessoryRectangular`) - 推荐，显示完整信息
- **锁屏内联卡片** (`accessoryInline`) - 顶部一行显示
- **主屏幕小组件** (`systemSmall`) - 主屏幕小尺寸
- **主屏幕中等组件** (`systemMedium`) - 主屏幕中等尺寸

## 如何使用

1. 运行主应用 `ThriveBody`
2. 进入 Me → 设置 → 添加健康任务锁屏卡
3. 按照引导页面的步骤操作

## 未来计划

- [ ] 接入真实的健康任务 API
- [ ] 替换 Mock 数据为实际任务数据
- [ ] 优化 UI 显示（根据任务类型调整图标和颜色）
- [ ] 支持用户自定义显示内容
- [ ] 添加任务点击跳转功能
- [ ] 支持多用户数据

## 技术说明

- **平台**: iOS 17.0+
- **框架**: WidgetKit, SwiftUI
- **刷新策略**: Timeline，每 5 分钟自动更新
- **网络请求**: URLSession + async/await
- **错误处理**: 失败时使用占位数据，5 分钟后自动重试
