# GitHub CI 快速开始指南

5 分钟快速上手 iOS 项目的 CI/CD 流程。

## 前置准备

### 1. 安装 GitHub CLI

```bash
# macOS
brew install gh

# 其他系统请访问: https://cli.github.com/
```

### 2. 登录 GitHub

```bash
gh auth login
```

按提示选择:
- GitHub.com
- HTTPS
- 使用 web browser 登录

## 快速使用

### 触发构建

```bash
# 1. 进入项目目录
cd /path/to/health_buddy_fe

# 2. 触发 Debug 构建 (最快)
./.github/scripts/ci-helper.sh trigger

# 3. 查看构建状态
./.github/scripts/ci-helper.sh watch
```

### 下载日志

```bash
# 下载最新构建的日志
./.github/scripts/ci-helper.sh logs

# 日志将保存在 ./ci-logs/ 目录
```

### 下载产物

```bash
# 下载最新构建的 .app 文件
./.github/scripts/ci-helper.sh download

# 产物将保存在 ./ci-artifacts/ 目录
```

## 常用命令速查

| 操作 | 命令 |
|------|------|
| 触发 Debug 构建 | `./.github/scripts/ci-helper.sh trigger` |
| 触发 Release 归档 | `./.github/scripts/ci-helper.sh trigger -c Release -t archive` |
| 清理后构建 | `./.github/scripts/ci-helper.sh trigger --clean` |
| 查看状态 | `./.github/scripts/ci-helper.sh status` |
| 实时监控 | `./.github/scripts/ci-helper.sh watch` |
| 下载日志 | `./.github/scripts/ci-helper.sh logs` |
| 下载产物 | `./.github/scripts/ci-helper.sh download` |
| 取消构建 | `./.github/scripts/ci-helper.sh cancel` |
| 查看帮助 | `./.github/scripts/ci-helper.sh --help` |

## 构建类型说明

### Simulator Build (默认)
- 构建速度快
- 适合日常开发和测试
- 产物: `.app` 文件

```bash
./.github/scripts/ci-helper.sh trigger -t simulator
```

### Archive Build
- 生成可发布的 IPA
- 适合 TestFlight 或 App Store
- 产物: `.ipa` 和 `.xcarchive` 文件

```bash
./.github/scripts/ci-helper.sh trigger -t archive -c Release
```

## 配置说明

### Debug vs Release

- **Debug**: 包含调试信息,构建快,包体积大
- **Release**: 优化编译,构建慢,包体积小,性能好

### 清理构建

使用 `--clean` 参数可以清理缓存后重新构建:

```bash
./.github/scripts/ci-helper.sh trigger --clean
```

适用场景:
- 构建出现奇怪错误
- 修改了项目配置
- 需要完全干净的构建

## Web 界面触发

如果不想使用命令行,也可以通过 GitHub 网页:

1. 打开仓库页面
2. 点击 "Actions" 标签
3. 选择 "Manual iOS Build"
4. 点击 "Run workflow"
5. 选择参数后点击绿色按钮

## 查看构建结果

### 方法 1: 命令行

```bash
# 查看最近 5 次构建
./.github/scripts/ci-helper.sh list

# 查看详细状态
./.github/scripts/ci-helper.sh status
```

### 方法 2: Web 界面

1. 打开仓库的 Actions 页面
2. 点击具体的 workflow run
3. 查看日志和产物

## 故障排除

### 命令找不到

```bash
# 确保脚本有执行权限
chmod +x ./.github/scripts/ci-helper.sh
```

### gh CLI 未登录

```bash
gh auth status
# 如果未登录
gh auth login
```

### 构建失败

```bash
# 下载日志查看详细错误
./.github/scripts/ci-helper.sh logs

# 查看日志文件
cat ci-logs/*/build-report.md
```

### 无法下载产物

可能原因:
- 构建尚未完成 → 等待构建完成
- 产物已过期 → 重新触发构建
- 构建失败 → 检查日志,修复后重新构建

## 下一步

- 📖 阅读完整文档: `.github/CI-SETUP.md`
- 🔧 自定义构建配置
- 📱 集成自动化测试
- 🚀 配置自动部署

## 需要帮助?

```bash
# 查看命令帮助
./.github/scripts/ci-helper.sh --help

# 或查看完整文档
cat .github/CI-SETUP.md
```
