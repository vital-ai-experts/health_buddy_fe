# ThriveBody

一个集成 AI 健康助手的智能健康管理应用，采用 SwiftUI 和模块化架构构建。

## 项目简介

ThriveBody 是一款智能健康管理应用，通过 AI 助手为用户提供个性化的健康建议，并整合 HealthKit 进行全面的健康数据追踪与分析。

### 核心功能

- **AI 健康助手**: 基于大语言模型的智能对话，提供个性化健康咨询
- **健康数据追踪**: 集成 HealthKit，追踪步数、睡眠、心率等多种健康指标
- **数据可视化**: 使用 CareKit 图表展示健康数据趋势
- **账户系统**: 完整的用户注册、登录、个人资料管理
- **本地持久化**: 使用 SwiftData 存储健康数据记录

### 技术栈

- **UI 框架**: SwiftUI + SwiftData
- **架构模式**: 模块化分层架构（详见 [modularization.md](./modularization.md)）
- **依赖管理**: Swift Package Manager (SPM)
- **项目生成**: XcodeGen
- **健康数据**: HealthKit + CareKit
- **网络通信**: URLSession + Async/Await

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
open ThriveBody.xcodeproj
```

## 项目结构

```
ThriveBody/
├── App/                       # 应用层
│   ├── Sources/
│   │   ├── AppMain/          # 应用入口、根视图
│   │   └── Composition/      # 依赖注入配置
│   └── Resources/            # 资源文件
├── Packages/                  # SPM 包
│   ├── Feature/              # 功能层 (Account/Chat/HealthKit)
│   │   └── FeatureAccount/   # 示例：账户功能
│   │       ├── FeatureAccountApi/      # API 协议
│   │       └── FeatureAccountImpl/     # 具体实现
│   ├── Domain/               # 领域层 (Auth/Chat/Health)
│   │   └── DomainAuth/       # 示例：认证领域
│   └── Library/              # 工具层 (ServiceLoader/Networking/ThemeKit)
├── scripts/                   # 自动化脚本
└── project.yml               # XcodeGen 配置
```

## 常用命令

### 生成项目

修改 `Package.swift` 或 `project.yml` 后需要重新生成项目：

```bash
./scripts/generate_project.sh
```

### 构建验证

```bash
# 快速构建（仅编译，不安装）
./scripts/build.sh

# 构建并安装到当前运行的模拟器（推荐）
./scripts/build.sh -i

# 构建并安装到连接的 iPhone 真机
./scripts/build.sh -i -d device

# Release 构建并安装到真机
./scripts/build.sh -r -i -d device

# 清理构建
./scripts/build.sh -c
```

**说明**：
- `-i` / `--install`：构建后自动安装并启动 App
- `-d` / `--destination`：指定目标（`simulator` 或 `device`，默认 simulator）
- `-r` / `--release`：Release 模式构建（默认 Debug）
- `-c` / `--clean`：清理构建

所有构建日志自动保存到 `build/xcodebuild_YYYYMMDD_HHMMSS.log`

### 打包发布

```bash
# 创建归档并导出 .ipa（用于 App Store 或企业分发）
./scripts/build.sh -a

# Release 归档
./scripts/build.sh -r -a
```

**说明**：
- `-a` / `--archive`：创建归档并导出 .ipa 文件
- 归档文件路径：`build/ThriveBody.xcarchive`
- IPA 文件路径：`build/ThriveBody.ipa`
- 用于提交 App Store 或通过 TestFlight 分发

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

- **Entitlements**: `App/ThriveBody.entitlements`
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

