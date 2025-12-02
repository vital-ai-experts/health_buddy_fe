# ThemeKit 设计规范

围绕 `ThemeKit` 提供的颜色资产，确保 UI 一致性和易于维护。所有颜色都通过 `Color.Palette.*` 访问，避免直接写入十六进制值。

## 使用原则
- 背景分层：`BgBase` 作为页面底色，`BgMuted` 用于分组区域或次级底色；浮层、卡片等需要抬升感时使用 `SurfaceElevated` 搭配 `SurfaceElevatedBorder`。
- 文本与可读性：正文优先 `TextPrimary`，辅助信息用 `TextSecondary`，禁用/弱化用 `TextDisabled`。在彩色或深色底上使用 `TextOnAccent` 确保对比度。
- 边框/分隔：弱分割用 `BorderSubtle`，需要更强强调或控件描边时使用 `BorderStrong` 或对应的状态色边框。
- 状态色：Info 代表品牌/系统主色；Success/Warning/Danger 用于状态反馈（完成、提醒、错误）。优先选用 *_BgSoft 作为轻背景，*_Main 作为主强调，Hover/Active 预留给交互态或更强对比。
- 复用优先：新增 UI 时先选择下表中的 token，确实缺失再补充资产，避免散落新增颜色。

## 色板

### 背景与表面
| Token | Hex | 用途 |
| --- | --- | --- |
| BgBase | #F5F3EC | 全局基础背景、滚动容器底色 |
| BgMuted | #F1F1F3 | 分组、表单、列表段落等次级背景 |
| SurfaceElevated | #FFFFFF | 卡片、弹窗、表单容器等提升层 |
| SurfaceElevatedBorder | #E5E5EE | 抬升面的描边或卡片分隔线 |

### 文本
| Token | Hex | 用途 |
| --- | --- | --- |
| TextPrimary | #111827 | 主要标题、正文 |
| TextSecondary | #6B7280 | 次级信息、描述文案 |
| TextDisabled | #9CA3AF | 不可用态、弱提示 |
| TextOnAccent | #FFFFFF | 彩色底/强调底上的文字与图标 |

### 边框
| Token | Hex | 用途 |
| --- | --- | --- |
| BorderSubtle | #E0E0E6 | 轻分隔线、输入框轮廓 |
| BorderStrong | #C5C7D0 | 更强分隔、组件描边或聚焦态 |

### 品牌 / 信息色
| Token | Hex | 用途 |
| --- | --- | --- |
| InfoMain | #2563EB | 品牌/主按钮、链接、高亮信息 |
| InfoBgSoft | #E5EDFF | 信息提示背景、徽标底色、选中态填充 |

### 成功态
| Token | Hex | 用途 |
| --- | --- | --- |
| SuccessMain | #22C58B | 成功状态主色、正向按钮填充 |
| SuccessHover | #1AAF7A | 成功态悬停/强调色或轻量渐变起点 |
| SuccessActive | #0F9667 | 成功态按压/高对比场景 |
| SuccessBgSoft | #E7FBF4 | 成功提示背景、徽章底色 |
| SuccessBorder | #A8F0D2 | 成功提示边框、轻分隔 |
| SuccessText | #046C4E | 成功背景上的文字/图标 |

### 警告态
| Token | Hex | 用途 |
| --- | --- | --- |
| WarningMain | #FF7A1A | 警告主色、需要注意的操作 |
| WarningHover | #FF8C33 | 悬停/强调或渐变起点 |
| WarningActive | #E86400 | 按压态或更强对比 |
| WarningBgSoft | #FFF5E9 | 警告提示底色、弱提醒 |
| WarningBorder | #FFD0A3 | 警告描边/分隔 |
| WarningText | #9A3C00 | 警告背景上的文字/图标 |

### 危险态
| Token | Hex | 用途 |
| --- | --- | --- |
| DangerMain | #EF4444 | 错误/不可逆操作按钮、严重警示 |
| DangerBgSoft | #FEE2E2 | 错误提示背景、轻量提醒 |

## 落地建议
- 新增组件或页面时，优先从上述 token 选择背景/文字/描边组合，确保跨模块一致性。
- 如果需要新增颜色，先在设计规范中定义名称、用途与示例，再补充到资产与 `Color.Palette`，避免出现重复或语义不明的 token。
