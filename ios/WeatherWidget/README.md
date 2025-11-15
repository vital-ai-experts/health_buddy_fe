# 上海天气锁屏卡 Widget

## 功能介绍

这是一个 iOS 锁屏卡片 Widget，用于展示上海的实时天气信息。

### 主要特性

- ☀️ 实时天气信息展示（温度、天气状况、湿度、风速）
- 🔄 每 5 分钟自动更新
- ⏰ 显示数据更新时间
- 📱 支持多种 Widget 尺寸：
  - 锁屏圆形卡片（accessoryCircular）
  - 锁屏矩形卡片（accessoryRectangular）
  - 锁屏内联卡片（accessoryInline）
  - 主屏幕小组件（systemSmall）
  - 主屏幕中等组件（systemMedium）

## 技术实现

### API 来源

使用 [wttr.in](https://wttr.in) 免费天气 API：
- 无需 API Key
- 支持全球城市
- 返回详细的天气数据

API 端点：`https://wttr.in/Shanghai?format=j1`

### 架构设计

```
WeatherWidget/
├── WeatherModels.swift       # 数据模型定义
│   ├── WeatherResponse       # API 响应模型
│   ├── CurrentCondition      # 当前天气状况
│   └── WeatherData          # Widget 显示数据模型
├── WeatherService.swift      # 天气服务（网络请求）
├── WeatherWidget.swift       # Widget 主文件
│   ├── WeatherTimelineProvider  # Timeline 提供者
│   ├── WeatherEntry            # Timeline Entry
│   ├── CircularWidgetView      # 圆形锁屏卡视图
│   ├── RectangularWidgetView   # 矩形锁屏卡视图
│   ├── InlineWidgetView        # 内联锁屏卡视图
│   └── SystemWidgetView        # 主屏幕 Widget 视图
├── Info.plist               # Widget 配置
└── Assets.xcassets          # 资源文件
```

### 刷新策略

Widget 使用 WidgetKit 的 Timeline 机制：
- 初始加载：立即获取天气数据
- 定时刷新：每 5 分钟请求新数据
- 错误处理：如果网络请求失败，使用占位数据并在 5 分钟后重试

```swift
// Timeline 配置示例
let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
```

## 如何使用

### 1. 生成 Xcode 项目

```bash
cd ios
bash scripts/generate_project.sh
```

### 2. 打开 Xcode 项目

```bash
open ThriveBody.xcodeproj
```

### 3. 运行应用

1. 选择主应用 target `ThriveBody`
2. 选择目标设备（真机或模拟器）
3. 点击运行

### 4. 添加 Widget 到锁屏

#### 在真机上：
1. 长按锁屏界面
2. 点击「自定」或「Customize」
3. 选择「锁定画面」或「Lock Screen」
4. 点击添加 Widget 的位置
5. 在 Widget 列表中找到「上海天气」
6. 选择喜欢的样式（圆形、矩形或内联）
7. 点击完成

#### 在模拟器上：
模拟器支持主屏幕 Widget，但锁屏 Widget 需要在真机上测试。

### 5. 添加到主屏幕（可选）

1. 长按主屏幕空白处
2. 点击左上角的「+」按钮
3. 搜索「上海天气」
4. 选择小组件或中等组件
5. 拖放到主屏幕

## Widget 展示效果

### 锁屏矩形卡片（推荐）
```
┌─────────────────────────┐
│ ☀️ 上海 · 17°C          │
│    晴朗                  │
│ 💧56%  🌬10km/h   14:30 │
└─────────────────────────┘
```

显示内容：
- 天气图标（根据天气代码自动匹配）
- 城市名称和当前温度
- 天气描述
- 湿度、风速
- 更新时间（右下角）

### 锁屏圆形卡片
```
┌───────┐
│       │
│  ☀️   │
│ 17°   │
│       │
└───────┘
```

显示内容：
- 天气图标
- 当前温度

### 锁屏内联卡片
```
☀️ 上海 17°C
```

### 主屏幕小组件
```
┌──────────────────┐
│ 上海             │
│                  │
│ ☀️               │
│     17°C         │
│     体感 17°C    │
│                  │
│ 晴朗             │
│ 💧湿度 56%       │
│ 🌬风速 10km/h    │
│     更新: 14:30  │
└──────────────────┘
```

## 数据字段说明

| 字段 | 说明 | 示例 |
|------|------|------|
| temperature | 当前温度（摄氏度） | 17°C |
| feelsLike | 体感温度 | 17°C |
| weatherDescription | 天气描述 | 晴朗、多云、小雨等 |
| humidity | 相对湿度 | 56% |
| windSpeed | 风速（公里/小时） | 10 km/h |
| weatherCode | 天气代码 | 113（晴天） |
| updateTime | 数据更新时间 | 14:30 |

## 天气图标映射

| 天气代码 | 描述 | 图标 |
|----------|------|------|
| 113 | 晴天/晴朗 | ☀️ |
| 116 | 局部多云 | ⛅️ |
| 119 | 多云 | ☁️ |
| 122 | 阴天 | ☁️ |
| 143/248/260 | 雾 | 🌫 |
| 176/263/266 | 小雨 | 🌦 |
| 293-320 | 中雨/大雨 | 🌧 |
| 227/230 | 暴风雪 | 🌨 |
| 386-395 | 雷暴 | ⛈ |

完整天气代码请参考：[World Weather Online API Docs](https://www.worldweatheronline.com/developer/api/docs/weather-icons.aspx)

## 调试技巧

### 查看 Widget 日志

在 Xcode 中：
1. 运行主应用
2. Debug → Attach to Process by PID or Name
3. 输入「WeatherWidget」
4. 在控制台查看日志输出

### 强制刷新 Widget

在模拟器或真机上：
1. 长按 Widget
2. 选择「编辑小组件」或「Edit Widget」
3. 点击完成（这会触发重新加载）

### 测试网络请求

可以在浏览器或命令行中直接测试 API：

```bash
curl "https://wttr.in/Shanghai?format=j1"
```

## 常见问题

### Q: Widget 不更新怎么办？
A:
1. 检查网络连接
2. 确认 Widget 是否有网络访问权限
3. 尝试移除并重新添加 Widget
4. 重启设备

### Q: 如何修改城市？
A: 修改 `WeatherService.swift` 中的 `baseURL`：
```swift
private let baseURL = "https://wttr.in/Beijing?format=j1"  // 改为北京
```

### Q: 如何调整刷新频率？
A: 修改 `WeatherWidget.swift` 中的刷新间隔：
```swift
// 当前是 5 分钟
let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!

// 改为 15 分钟
let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
```

注意：iOS 系统会限制 Widget 的刷新频率，过于频繁的刷新可能会被系统限流。

### Q: 能否支持多个城市？
A: 当前版本仅支持上海。如需支持多城市，需要：
1. 添加配置选项（使用 AppIntent）
2. 修改 Widget 支持用户自定义城市
3. 在 WeatherService 中支持动态城市参数

## 后续优化建议

- [ ] 支持用户自定义城市（通过 WidgetConfiguration）
- [ ] 添加更多天气信息（紫外线指数、空气质量等）
- [ ] 支持深色模式优化
- [ ] 添加天气预警提醒
- [ ] 支持更多 Widget 尺寸
- [ ] 添加天气趋势图表
- [ ] 缓存机制优化（减少网络请求）
- [ ] 支持位置服务（自动获取当前城市）

## License

MIT License
