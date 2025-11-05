# HealthBuddy

一个基于 HealthKit 的 iOS 健康数据追踪应用，采用 SwiftUI 和模块化架构构建。

## 项目简介

HealthBuddy 专注于提供简洁直观的健康数据管理体验，包含健康数据授权、数据追踪和可视化展示等功能。

### 核心功能

- **健康数据授权**: 引导用户完成 HealthKit 权限授权
- **数据追踪**: 支持步数、睡眠、心率等多种健康指标
- **数据可视化**: 使用 CareKit 图表展示健康数据趋势
- **本地持久化**: 使用 SwiftData 存储健康数据记录

### 技术栈

- **UI 框架**: SwiftUI + SwiftData
- **架构模式**: 模块化分层架构（详见 [modularization.md](./modularization.md)）
- **依赖管理**: Swift Package Manager (SPM)
- **项目生成**: XcodeGen
- **健康数据**: HealthKit + CareKit

## 环境要求

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **工具**: XcodeGen (`brew install xcodegen`)

## 快速开始

```bash
# 1. 生成 Xcode 项目
./scripts/generate_project.sh

# 2. 快速构建验证
./scripts/build.sh

# 3. 在 Xcode 中运行
open HealthBuddy.xcodeproj
```

## 项目结构

```
HealthBuddy/
├── App/                    # 应用层：入口、导航、依赖配置
├── Packages/               # SPM 包
│   ├── Feature/           # 功能层：业务功能模块
│   │   └── HealthKit/     # HealthKit 功能（Api + Impl）
│   ├── Domain/            # 领域层：核心业务逻辑
│   │   └── Health/        # 健康领域服务
│   └── Library/           # 工具层：基础组件
│       ├── ServiceLoader/ # 依赖注入
│       └── ThemeKit/      # 主题管理
├── scripts/               # 自动化脚本
├── project.yml            # XcodeGen 配置
└── modularization.md      # 模块化架构文档
```

## 常用命令

### 生成项目

修改 `Package.swift` 或 `project.yml` 后需要重新生成项目：

```bash
./scripts/generate_project.sh
```

### 构建验证

```bash
# 增量构建
./scripts/build.sh

# 清理构建
./scripts/build.sh --clean

# 详细输出
./scripts/build.sh --verbose

# 指定模拟器
./scripts/build.sh -d "iPhone 16 Pro"
```

### 创建新模块

```bash
# Feature 模块
./scripts/createModule.py -f FeatureName

# Domain 模块
./scripts/createModule.py -d DomainName

# Library 模块
./scripts/createModule.py -l LibraryName
```

## 开发文档

- **模块化架构**: [modularization.md](./modularization.md) - 架构设计、分层规范、依赖规则
- **Claude Code 指南**: [CLAUDE.md](./CLAUDE.md) - AI 辅助开发指南、详细开发流程

## HealthKit 配置

应用需要 HealthKit 权限，相关配置：

- **Entitlements**: `App/HealthBuddy.entitlements`
- **Usage Descriptions**: 在 `project.yml` 中配置
- **支持数据类型**: 步数、睡眠、心率、活动能量等

## 常见问题

**Q: 编译失败提示找不到模块？**

检查：
1. Package.swift 中的包名与目录名是否一致
2. Import 语句是否正确（如 `DomainHealth` 而非 `HealthDomain`）
3. 运行 `./scripts/generate_project.sh` 重新生成项目

**Q: 如何添加新功能？**

参考 [CLAUDE.md](./CLAUDE.md) 中的详细步骤，或查看 [modularization.md](./modularization.md) 了解架构规范。

