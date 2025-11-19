# 模块化架构

## 技术选型

- **包管理**: Swift Package Manager (SPM)
- **项目生成**: XcodeGen
- **依赖注入**: 自定义 ServiceManager (服务定位器模式)

每个模块为本地 SPM 包，工程由 XcodeGen 自动生成。

## 分层设计

项目采用严格的分层架构，依赖关系自上而下单向流动:

```
App → Feature (Impl) → Feature (Api) → Domain → Library
```

### Library 层

**职责**: 业务无关的基础工具和框架封装

**位置**: `Packages/Library/`

**当前模块**:
- `ServiceLoader`: 依赖注入容器 (ServiceManager)
- `Networking`: HTTP 网络请求封装
- `ThemeKit`: 应用主题和样式管理

**规范**:
- 不包含任何业务逻辑
- 可被任何上层模块依赖
- 模块命名: `Library[ModuleName]`

### Domain 层

**职责**: 核心业务领域逻辑和跨功能服务

**位置**: `Packages/Domain/`

**当前模块**:
- `DomainHealth`: 健康数据服务、HealthKit 管理器
- `DomainAuth`: 用户认证服务、用户模型
- `DomainChat`: AI 对话服务

**规范**:
- 包含业务核心逻辑和数据模型
- 可依赖 Library 层
- 通过 Bootstrap 模式注册服务到 ServiceManager
- 模块命名: `Domain[DomainName]`
- 导入规则: `import DomainXxx` (如 `import DomainAuth`)

### Feature 层

**职责**: 具体业务功能的 UI 和交互实现

**位置**: `Packages/Feature/`

**拆分规则**: 每个功能拆分为 Api 和 Impl 两个包
- **Api 包**: 只包含协议定义 (如 `FeatureAccountBuildable`)
- **Impl 包**: 包含具体实现、ViewModel、View

**当前功能**:
- `FeatureAccount`: 用户账户管理 (登录、注册、欢迎页)
- `FeatureChat`: AI 对话功能 (聊天界面、会话列表)
- `FeatureHealthKit`: 健康数据功能 (授权、仪表盘、数据可视化)

**依赖规则**:
- Feature 模块之间只能依赖对方的 Api 包，不能依赖 Impl 包
- 只有 App 层可以依赖 Feature Impl 包
- 可以依赖 Domain 层和 Library 层

**模块注册**:
每个 Feature Impl 包导出 `[Name]Module.register(router:)` 函数（可选地接受 `ServiceManager`），该函数既负责向容器注册 `Buildable`，也会在内部触发 `registerRoutes(on:)` 将页面路由挂载到共享 `RouteManager`。所有注册都在 `AppComposition.bootstrap(router:)` 中集中调用。

### App 层

**职责**: 应用入口、路由导航、依赖组装

**位置**: `App/Sources/`

**结构**:
- `AppMain/`: 应用入口、根视图、TabView
  - `HealthBuddyApp.swift`: @main 入口
  - `RootView.swift`: 根视图，处理启动页和认证流程
  - `SplashView.swift`: 启动画面
- `Composition/`: 依赖注入配置
  - `AppComposition.swift`: 注册所有 Domain 服务和 Feature 构建器

**规范**:
- 唯一可以依赖 Feature Impl 包的层
- 负责调用所有模块的注册函数
- 不包含业务逻辑

## 路由与导航基建

- **核心理念**: 通过全局 `RouteManager` 统一接管 Tab 栈、Sheet、Fullscreen 等展示层级，让 App 层只负责注入路由器，具体页面的注册和展示交给 Feature。
- **设计要点**: `RouteManager` 会持有各 Tab 的 `NavigationPath`，并暴露 `activeSheet`、`activeFullscreen` 等状态；任意 Feature 都能在注册阶段把自己的 URL 映射到对应 View Builder，默认展示层可以在注册时配置，也可以在打开时临时指定。
- **使用方式**:
  1. Feature Impl 提供 `Module+Routing` 扩展，在自身的 `Module.register()` 里调用 `registerRoutes(on:)` 并传入共享的 `RouteManager`。
  2. 注册时实现 `builder(context:)` 闭包，根据 URL、Query、路由参数构建 SwiftUI View，需要回调登录/登出等事件时可直接调用 `RouteManager` 提供的辅助方法。
  3. 业务侧通过 `router.buildURL("/path", queryItems:)` 组装目标，再用 `router.open(url:on:)` 或 `router.open(path:on:)` 触发导航；`RootView` 负责把外部深链交给路由器，并通过 `.sheet`、`.fullScreenCover` 等绑定展示状态。
- **实践建议**: 保持 URL 命名与 Feature 一致，轻参数走 query，复杂状态交给共享数据模型；Sheet / Fullscreen 入口最好都能通过 `present` 参数覆盖，方便统一的深链调起；需要跨 Feature 触发导航时，优先复用路由 URL，而不是直接引用具体视图。

## 目录结构示意

```
.
├── App/                                     # 应用层
│   ├── Sources/
│   │   ├── AppMain/                        # 应用入口、根视图
│   │   └── Composition/                    # 依赖组装
│   └── Resources/                          # 资源文件
├── Packages/
│   ├── Feature/                            # 功能层 (3个: Account/Chat/HealthKit)
│   │   └── FeatureAccount/                 # 示例：账户功能
│   │       ├── FeatureAccountApi/          # API 协议
│   │       └── FeatureAccountImpl/         # 具体实现
│   │           └── Sources/
│   │               ├── AccountModule.swift # 模块注册
│   │               ├── AccountBuilder.swift # 构建器
│   │               └── Views...            # 视图文件
│   ├── Domain/                             # 领域层 (3个: Auth/Chat/Health)
│   │   └── DomainAuth/                     # 示例：认证领域
│   │       └── Sources/DomainAuth/
│   │           ├── AuthDomainBootstrap.swift
│   │           ├── AuthenticationService.swift
│   │           └── User.swift
│   └── Library/                            # 工具层 (3个: ServiceLoader/Networking/ThemeKit)
│       └── ServiceLoader/                  # 示例：服务定位器
├── project.yml                              # XcodeGen 配置
└── scripts/                                 # 自动化脚本
```

## 核心模式

### 1. 依赖注入模式 (ServiceManager)

使用服务定位器模式，通过 `ServiceManager` 管理依赖:

**注册** (在 Bootstrap 中):
```swift
public enum AuthDomainBootstrap {
    public static func configure(manager: ServiceManager = .shared) {
        manager.register(AuthenticationService.self) {
            AuthenticationServiceImpl()
        }
    }
}
```

**解析** (在使用处):
```swift
let authService = ServiceManager.shared.resolve(AuthenticationService.self)
```

### 2. Feature Builder 模式

Feature 通过 Builder 协议暴露视图构建方法:

**Api 包定义协议**:
```swift
public protocol FeatureAccountBuildable {
    func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView
    func makeRegisterView(onRegisterSuccess: @escaping () -> Void) -> AnyView
    func makeAccountLandingView(onSuccess: @escaping () -> Void) -> AnyView
}
```

**Impl 包实现协议**:
```swift
public struct AccountBuilder: FeatureAccountBuildable {
    public init() {}

    public func makeLoginView(onLoginSuccess: @escaping () -> Void) -> AnyView {
        AnyView(LoginView(onLoginSuccess: onLoginSuccess))
    }
    // ... 其他方法实现
}
```

### 3. Module 注册模式

每个 Feature Impl 包导出注册函数:

```swift
public enum AccountModule {
    public static func register(
        in manager: ServiceManager = .shared,
        router: RouteRegistering
    ) {
        manager.register(FeatureAccountBuildable.self) { AccountBuilder() }

        registerRoutes(on: router)
    }
}
```

在 `AppComposition.bootstrap()` 中统一调用:
```swift
enum AppComposition {
    @MainActor
    static func bootstrap(router: RouteRegistering) {
        // 1. 配置 Domain 服务
        HealthDomainBootstrap.configure()
        AuthDomainBootstrap.configure()
        ChatDomainBootstrap.configure()

        // 2. 注册 Feature（注册构建器 + 路由）
        HealthKitModule.register(router: router)
        AccountModule.register(router: router)
        ChatModule.register(router: router)
    }
}
```

### 4. Bootstrap 模式

Domain 层导出配置函数注册服务:

```swift
public enum HealthDomainBootstrap {
    public static func configure(manager: ServiceManager = .shared) {
        manager.register(AuthorizationService.self) {
            AuthorizationServiceImpl()
        }
        manager.register(HealthDataService.self) {
            HealthDataServiceImpl()
        }
        manager.register(HealthKitManager.self) {
            HealthKitManager()
        }
    }
}
```

## 命名规范

### 包命名
- Feature Api: `Feature[Name]Api`
- Feature Impl: `Feature[Name]Impl`
- Domain: `Domain[Name]`
- Library: `Library[Name]`

### 文件命名
- Feature 协议: `Feature[Name]Api.swift`
- Feature 构建器: `[Name]Builder.swift`
- Feature 模块: `[Name]Module.swift`
- Domain 引导: `[Name]DomainBootstrap.swift`

### 导入规范
```swift
// Domain 层 - 使用 DomainXxx 前缀
import DomainAuth
import DomainHealth
import DomainChat

// Library 层 - 使用 LibraryXxx 前缀
import LibraryServiceLoader
import LibraryNetworking
import LibraryThemeKit  // 注意: ThemeKit 的 product name

// Feature 层 - 使用完整包名
import FeatureAccountApi
import FeatureAccountImpl
```

## 使用说明

### 创建新模块

使用脚本创建:
```bash
# Feature 模块 (自动创建 Api 和 Impl)
scripts/createModule.py -f YourFeature

# Domain 模块
scripts/createModule.py -d YourDomain

# Library 模块
scripts/createModule.py -l YourLibrary
```

### 修改依赖

1. 编辑模块的 `Package.swift`
2. 如果是 App 依赖，同步修改 `project.yml`
3. 重新生成项目:
   ```bash
   scripts/generate_project.sh
   ```

### 添加新功能的完整流程

参见 `CLAUDE.md` 中的 "Adding a New Feature" 章节

## 应用启动流程

1. `HealthBuddyApp.init()` - 应用入口
2. `AppComposition.bootstrap()` - 注册所有服务和功能构建器
3. `RootView` 显示启动页 (1.5秒)
4. 检查认证状态:
   - 已登录 → 显示 MainTabView (AI助手、健康、我的)
   - 未登录 → 显示 AccountLandingView

## 数据流

```
View → Builder (Feature Api) → Builder Impl (Feature Impl)
  ↓
Service (Domain) → ServiceManager.resolve()
  ↓
Repository/Manager (Domain) → 数据源 (HealthKit/Network/Database)
```

## 注意事项

1. **包名一致性**: 目录名、Package name、Product name、Target name 必须完全一致
2. **依赖方向**: 严格遵守依赖方向，不允许反向依赖
3. **Feature 隔离**: Feature 之间不能直接依赖 Impl，只能通过 Api 协议
4. **导入规范**: 注意 Domain 和 Library 的导入前缀规则
5. **重新生成**: 修改 Package.swift 后必须运行 `scripts/generate_project.sh`
