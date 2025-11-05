# HealthBuddy

一个模块化的 iOS Demo 集合平台，用于展示各种 iOS 功能和技术实现。

## 项目介绍

HealthBuddy 采用清晰的分层架构，支持快速添加新的 Demo。每个 Demo 都是一个独立的功能模块，可以方便地进行开发、测试和展示。

### 当前 Demo

- **HealthKit**: HealthKit 数据追踪与可视化
  - 健康数据授权流程
  - 步数、睡眠、活动等数据采集
  - CareKit 图表展示

### 技术栈

- **UI框架**: SwiftUI
- **架构模式**: 清晰的分层架构（App → Feature → Domain → Library）
- **依赖注入**: ServiceManager（自定义服务定位器）
- **模块管理**: Swift Package Manager (SPM)
- **项目生成**: XcodeGen
- **数据持久化**: SwiftData

## 快速开始

### 环境要求

- iOS 17.0+
- Xcode 15.0+
- XcodeGen (`brew install xcodegen`)

### 构建项目

```bash
# 生成 Xcode 项目
scripts/generate_project.sh

# 快速构建
scripts/build.sh

# 清理构建
scripts/build.sh --clean
```

### 运行项目

在 Xcode 中打开 `HealthBuddy.xcodeproj`，选择模拟器或真机运行。

## 如何添加新 Demo

### 方式一：简单 Demo（推荐）

如果你的 Demo 不需要复杂的业务逻辑，可以直接在 AppComposition 中注册：

```swift
// 在 App/Sources/Composition/AppComposition.swift 中

import LibraryDemoRegistry

static func bootstrap() {
    // ... 其他注册 ...

    // 注册你的 Demo
    DemoRegistry.shared.register(
        DemoItem(
            id: "my-simple-demo",
            title: "我的 Demo",
            description: "Demo 简介",
            category: .uiComponents,
            iconName: "star.fill",
            buildView: { AnyView(MyDemoView()) }
        )
    )
}
```

然后创建你的视图文件（可以放在 App/Sources 下）：

```swift
import SwiftUI

struct MyDemoView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, Demo!")
            }
            .navigationTitle("我的 Demo")
        }
    }
}
```

### 方式二：完整 Feature 模块

对于复杂的 Demo，建议创建独立的 Feature 模块：

#### 1. 创建模块

```bash
scripts/createModule.py -f MyDemo
```

#### 2. 调整目录结构

```bash
cd Packages/Feature/Mydemo
mv api FeatureMydemoApi
mv impl FeatureMydemoImpl
```

#### 3. 更新 Package.swift

确保包名、产品名与目录名一致：

**FeatureMydemoApi/Package.swift:**
```swift
let package = Package(
    name: "FeatureMydemoApi",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureMydemoApi", targets: ["FeatureMydemoApi"]) ],
    targets: [
        .target(name: "FeatureMydemoApi", path: "Sources")
    ]
)
```

**FeatureMydemoImpl/Package.swift:**
```swift
let package = Package(
    name: "FeatureMydemoImpl",
    platforms: [ .iOS(.v17) ],
    products: [ .library(name: "FeatureMydemoImpl", targets: ["FeatureMydemoImpl"]) ],
    dependencies: [
        .package(name: "FeatureMydemoApi", path: "../FeatureMydemoApi"),
        .package(name: "LibraryDemoRegistry", path: "../../../Library/DemoRegistry")
    ],
    targets: [
        .target(
            name: "FeatureMydemoImpl",
            dependencies: [
                .product(name: "FeatureMydemoApi", package: "FeatureMydemoApi"),
                .product(name: "LibraryDemoRegistry", package: "LibraryDemoRegistry")
            ],
            path: "Sources"
        )
    ]
)
```

#### 4. 实现 Demo

**创建视图** (`FeatureMydemoImpl/Sources/MyDemoView.swift`):
```swift
import SwiftUI

struct MyDemoView: View {
    var body: some View {
        NavigationStack {
            Text("Hello, Feature Demo!")
                .navigationTitle("我的 Demo")
        }
    }
}
```

**创建注册模块** (`FeatureMydemoImpl/Sources/MyDemoModule.swift`):
```swift
import SwiftUI
import LibraryDemoRegistry

public enum MyDemoModule {
    public static func register() {
        DemoRegistry.shared.register(
            DemoItem(
                id: "my-demo",
                title: "我的 Feature Demo",
                description: "这是一个完整的 Feature 模块示例",
                category: .uiComponents,
                iconName: "sparkles",
                buildView: { AnyView(MyDemoView()) }
            )
        )
    }
}
```

#### 5. 更新 project.yml

```yaml
packages:
  # ... 其他包 ...
  FeatureMydemoApi:
    path: Packages/Feature/Mydemo/FeatureMydemoApi
  FeatureMydemoImpl:
    path: Packages/Feature/Mydemo/FeatureMydemoImpl

targets:
  HealthBuddy:
    dependencies:
      # ... 其他依赖 ...
      - package: FeatureMydemoApi
        product: FeatureMydemoApi
      - package: FeatureMydemoImpl
        product: FeatureMydemoImpl
```

#### 6. 在 AppComposition 中注册

```swift
import FeatureMydemoImpl  // 添加导入

enum AppComposition {
    static func bootstrap() {
        // ... 其他注册 ...
        MyDemoModule.register()  // 添加注册
    }
}
```

#### 7. 重新生成并构建

```bash
scripts/generate_project.sh
scripts/build.sh
```

## Demo 分类

在注册 Demo 时，可以选择以下分类：

- `.systemFrameworks` - 系统框架（如 HealthKit、CoreLocation）
- `.uiComponents` - UI 组件（自定义控件、动画效果）
- `.networking` - 网络相关（API 调用、WebSocket）
- `.dataPersistence` - 数据持久化（CoreData、SwiftData）
- `.multimedia` - 多媒体（音视频处理）
- `.other` - 其他

## 项目结构

```
HealthBuddy/
├── App/                          # 应用层
│   ├── Sources/
│   │   ├── AppMain/             # 入口和导航
│   │   └── Composition/         # 依赖注入配置
│   └── Resources/               # 资源文件
├── Packages/
│   ├── Feature/                 # 功能模块
│   │   ├── DemoList/           # Demo 列表
│   │   └── HealthKit/          # 健康数据追踪与可视化（统一模块）
│   ├── Domain/                  # 领域层
│   │   └── Health/             # 健康领域服务（含 HealthKitManager）
│   └── Library/                 # 工具库
│       ├── ServiceLoader/       # 依赖注入
│       └── DemoRegistry/       # Demo 注册系统
├── scripts/                     # 构建脚本
└── project.yml                  # XcodeGen 配置
```


## 架构设计

项目采用严格的分层架构，依赖关系自上而下：

```
App → Feature (Impl) → Feature (Api) → Domain → Library
```

- **App**: 应用入口、导航、依赖注入配置
- **Feature**: 业务功能模块，分为 Api（协议）和 Impl（实现）
- **Domain**: 跨功能的领域服务和业务逻辑
- **Library**: 与业务无关的工具和框架封装

## 开发指南

### 命名规范

- Feature 模块目录：`FeatureXxxApi`、`FeatureXxxImpl`
- Domain 模块：`DomainXxx`
- Library 模块：`LibraryXxx`

### Import 规则

```swift
// ✅ 正确
import DomainHealth
import LibraryServiceLoader
import FeatureDemoListApi

// ❌ 错误
import HealthDomain
import ServiceLoader
import DemolistFeatureAPI
```

### 常见问题

**Q: 为什么编译失败提示找不到模块？**

A: 检查以下几点：
1. Package.swift 中的 `name`、`product` 名称与目录名是否一致
2. import 语句是否使用了正确的模块名（如 `DomainHealth` 而非 `HealthDomain`）
3. 是否运行了 `scripts/generate_project.sh` 重新生成项目

**Q: 如何删除一个 Demo？**

A:
1. 在 AppComposition 中移除对应的注册代码
2. 从 project.yml 中移除 package 和 dependency
3. 删除对应的 Feature 目录
4. 运行 `scripts/generate_project.sh`
