# GitHub CI 配置文档

本文档介绍如何使用 GitHub Actions 进行 iOS 项目的持续集成和构建。

## 目录

- [概述](#概述)
- [架构设计](#架构设计)
- [工作流说明](#工作流说明)
- [使用方法](#使用方法)
- [IaC 最佳实践](#iac-最佳实践)
- [故障排除](#故障排除)

## 概述

本项目配置了完整的 GitHub CI/CD 流程,支持:

- ✅ 自动化构建 (PR/Push 触发)
- ✅ 手动触发构建
- ✅ 多种构建配置 (Debug/Release)
- ✅ 模拟器和真机构建
- ✅ 归档和 IPA 生成
- ✅ 构建日志收集和下载
- ✅ 构建产物管理
- ✅ 命令行工具支持

## 架构设计

### IaC (Infrastructure as Code) 原则

本配置遵循以下 IaC 最佳实践:

1. **版本控制**: 所有 CI/CD 配置文件都在 Git 仓库中管理
2. **声明式配置**: 使用 YAML 定义工作流,清晰易读
3. **可复用性**: 使用 workflow 模板和可复用的 action
4. **环境变量管理**: 集中管理环境变量和配置
5. **可审计性**: 所有变更都可追踪和回滚

### 目录结构

```
.github/
├── workflows/              # GitHub Actions 工作流
│   ├── build.yml          # 主构建工作流
│   └── manual-build.yml   # 手动触发工作流
├── scripts/               # CI 辅助脚本
│   └── ci-helper.sh       # CLI 工具
└── CI-SETUP.md           # 本文档
```

## 工作流说明

### 1. build.yml - 主构建工作流

**触发条件:**
- Push 到 main, develop, release/* 分支
- Pull Request 到 main, develop 分支
- 手动触发 (workflow_dispatch)

**功能:**
- 自动生成 Xcode 项目
- 模拟器构建
- 构建日志收集
- 构建产物上传
- 构建报告生成

**配置参数:**
```yaml
configuration: Debug/Release     # 构建配置
create_archive: true/false       # 是否创建归档
upload_artifacts: true/false     # 是否上传产物
```

### 2. manual-build.yml - 手动触发工作流

**触发条件:**
- 手动触发 (workflow_dispatch)

**功能:**
- 完整的构建选项控制
- 支持清理构建
- 灵活的配置组合
- 详细的构建报告

**配置参数:**
```yaml
configuration: Debug/Release           # 构建配置
build_type: simulator/archive          # 构建类型
clean_build: true/false                # 是否清理
upload_ipa: true/false                 # 是否上传 IPA
```

## 使用方法

### 方法 1: GitHub Web 界面

1. 打开仓库的 Actions 页面
2. 选择工作流 (例如 "Manual iOS Build")
3. 点击 "Run workflow"
4. 选择配置选项
5. 点击 "Run workflow" 开始构建

### 方法 2: GitHub CLI (推荐)

#### 前置要求

安装 GitHub CLI:

```bash
# macOS
brew install gh

# 或访问 https://cli.github.com/
```

登录 GitHub:

```bash
gh auth login
```

#### 使用 CI 辅助脚本

我们提供了一个强大的 CLI 工具来简化 CI 操作:

```bash
# 进入项目根目录
cd /path/to/health_buddy_fe

# 使用辅助脚本
./.github/scripts/ci-helper.sh
```

#### 常用命令

**触发构建:**

```bash
# Debug 模拟器构建
./.github/scripts/ci-helper.sh trigger

# Release 归档构建
./.github/scripts/ci-helper.sh trigger -c Release -t archive

# 清理构建
./.github/scripts/ci-helper.sh trigger --clean -c Release

# 指定分支
./.github/scripts/ci-helper.sh trigger -b develop
```

**查看状态:**

```bash
# 查看最新构建状态
./.github/scripts/ci-helper.sh status

# 列出最近的构建
./.github/scripts/ci-helper.sh list

# 实时监控构建
./.github/scripts/ci-helper.sh watch
```

**下载日志:**

```bash
# 下载最新构建的日志
./.github/scripts/ci-helper.sh logs

# 下载指定构建的日志
./.github/scripts/ci-helper.sh logs -r 123456

# 指定输出目录
./.github/scripts/ci-helper.sh logs -o ./my-logs
```

**下载产物:**

```bash
# 下载所有产物
./.github/scripts/ci-helper.sh download

# 下载指定构建的产物
./.github/scripts/ci-helper.sh download -r 123456

# 只下载特定 artifact
./.github/scripts/ci-helper.sh download -n "simulator-app-Debug-123"

# 指定输出目录
./.github/scripts/ci-helper.sh download -o ./my-artifacts
```

**取消构建:**

```bash
./.github/scripts/ci-helper.sh cancel
```

### 方法 3: 直接使用 gh CLI

```bash
# 触发工作流
gh workflow run manual-build.yml \
  -f configuration=Release \
  -f build_type=archive \
  -f clean_build=true

# 查看运行列表
gh run list

# 查看运行状态
gh run view <run-id>

# 下载产物
gh run download <run-id>

# 实时监控
gh run watch <run-id>
```

## 构建产物和日志

### 日志文件

构建日志自动上传为 GitHub Actions artifacts,保留 30 天。

**日志文件包含:**
- xcodebuild 详细输出
- 构建摘要
- 错误信息
- 构建报告 (Markdown 格式)

**日志命名:**
- `build-logs-<Configuration>-<BuildType>-<RunNumber>`

### 构建产物

**Simulator 构建:**
- `.app` 文件
- 保留 7 天

**Archive 构建:**
- `.ipa` 文件
- `.xcarchive` 文件
- 保留 30 天

## IaC 最佳实践

### 1. 配置即代码

所有构建配置都通过 YAML 文件定义,便于:
- 版本控制和追踪
- Code Review
- 快速回滚
- 环境复制

### 2. 参数化配置

使用 `workflow_dispatch` inputs 实现灵活配置:

```yaml
workflow_dispatch:
  inputs:
    configuration:
      type: choice
      options: [Debug, Release]
```

### 3. 环境变量管理

集中管理环境变量:

```yaml
env:
  XCODE_VERSION: '15.2'
  IOS_DEPLOYMENT_TARGET: '17.0'
```

### 4. 构建缓存

使用 GitHub Actions cache 加速构建:

```yaml
- uses: actions/cache@v4
  with:
    path: ios/build/DerivedData
    key: ${{ runner.os }}-derived-data-${{ hashFiles('...') }}
```

### 5. 产物管理

自动化产物收集和上传:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: build-logs-${{ github.run_number }}
    retention-days: 30
```

## 配置自定义

### 修改 Xcode 版本

编辑 `.github/workflows/build.yml`:

```yaml
env:
  XCODE_VERSION: '15.2'  # 修改为需要的版本
```

### 修改保留时间

编辑 workflow 文件中的 `retention-days`:

```yaml
- uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # 修改保留天数
```

### 添加新的构建配置

1. 编辑 workflow 文件
2. 添加新的 input 或 matrix 配置
3. 更新构建步骤

### 自定义构建脚本

编辑 `ios/scripts/build.sh` 来修改本地构建逻辑。

## 故障排除

### 常见问题

#### 1. 构建失败

**检查步骤:**
1. 下载构建日志: `./.github/scripts/ci-helper.sh logs`
2. 查看错误信息
3. 检查本地构建是否正常
4. 验证 Xcode 版本兼容性

#### 2. 无法下载产物

**可能原因:**
- Run 未完成
- 产物已过期
- 权限不足

**解决方法:**
```bash
# 检查 run 状态
gh run view <run-id>

# 检查是否有产物
gh run view <run-id> --log
```

#### 3. gh CLI 认证失败

```bash
# 重新登录
gh auth logout
gh auth login
```

#### 4. 工作流未触发

**检查:**
- 分支是否在触发条件中
- 文件路径是否匹配
- 工作流文件语法是否正确

### 调试技巧

1. **启用详细日志:**
   - 在 GitHub secrets 中添加 `ACTIONS_STEP_DEBUG=true`

2. **本地测试构建脚本:**
   ```bash
   cd ios
   ./scripts/build.sh -c -r -d simulator
   ```

3. **查看完整日志:**
   ```bash
   gh run view <run-id> --log
   ```

## 进阶配置

### 设置 GitHub Secrets

对于敏感信息(如证书、密钥),使用 GitHub Secrets:

1. 进入仓库 Settings > Secrets and variables > Actions
2. 添加 secrets
3. 在 workflow 中引用:

```yaml
env:
  CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}
```

### 矩阵构建

同时构建多个配置:

```yaml
strategy:
  matrix:
    configuration: [Debug, Release]
    platform: [simulator, device]
```

### 条件执行

基于条件执行步骤:

```yaml
- name: Deploy to TestFlight
  if: github.ref == 'refs/heads/main'
  run: ./scripts/deploy.sh
```

### Webhook 通知

集成 Slack/Discord 等通知:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

## 安全最佳实践

1. **不要在代码中硬编码密钥**
2. **使用 GitHub Secrets 存储敏感信息**
3. **限制工作流权限**
4. **定期更新依赖**
5. **审查第三方 Actions**

## 参考资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitHub CLI 文档](https://cli.github.com/manual/)
- [XcodeGen 文档](https://github.com/yonaskolb/XcodeGen)
- [iOS CI/CD 最佳实践](https://docs.fastlane.tools/)

## 维护

### 定期检查

- [ ] 更新 Xcode 版本
- [ ] 检查 Actions 版本
- [ ] 清理过期产物
- [ ] 审查构建时间和成本

### 版本控制

所有配置变更都应该:
1. 创建功能分支
2. 提交 Pull Request
3. Code Review
4. 测试验证
5. 合并到主分支

---

## 支持

如有问题,请:
1. 查看本文档
2. 检查 GitHub Actions 日志
3. 提交 Issue
4. 联系团队负责人
