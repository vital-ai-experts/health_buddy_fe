# GitHub Actions CI 状态检查脚本

## 功能概述

`check_ci_status.sh` 脚本用于自动检查当前分支的 GitHub Actions CI 状态，并在 CI 失败时自动获取详细的编译日志。

## 主要功能

1. **自动检测分支**：自动获取当前 git 分支名称
2. **实时监控 CI 状态**：如果 CI 正在运行，会自动等待完成（最多 30 分钟）
3. **获取 Job 日志**：CI 失败时，自动获取所有失败 Job 的日志
4. **下载编译日志 Artifacts**：自动下载并解析 CI 上传的编译日志文件
5. **智能日志分析**：
   - 对于大型日志文件，自动提取错误和警告信息
   - 显示日志末尾的关键信息
   - 使用颜色标记不同类型的输出

## 使用方法

### 基本用法

```bash
# 检查当前分支的 CI 状态
.github/check_ci_status.sh
```

### 完整工作流

```bash
# 1. 提交代码
git add .
git commit -m "feat: add new feature"
git push

# 2. 检查 CI 状态
.github/check_ci_status.sh

# 3. 如果 CI 失败，脚本会自动：
#    - 显示失败的 Job 日志
#    - 下载编译日志 artifacts
#    - 提取并显示错误信息

# 4. 修复问题后重新推送
git add .
git commit -m "fix: resolve CI errors"
git push

# 5. 再次检查 CI 状态
.github/check_ci_status.sh
```

## 环境要求

### 必需环境变量

```bash
export GITHUB_CI_TOKEN="your_github_token_here"
```

GitHub Token 需要以下权限：
- `repo` - 访问仓库
- `actions:read` - 读取 Actions 状态
- `actions:write` - 下载 artifacts

### 必需工具

- `curl` - 发送 HTTP 请求
- `jq` - 解析 JSON 响应
- `unzip` - 解压缩 artifacts
- `git` - 获取分支信息

## Artifacts 下载功能

### 工作原理

当 CI 失败时，脚本会：

1. 查询该 workflow run 的所有 artifacts
2. 自动识别名称包含 "build" 的 artifacts（如 `build-artifacts`）
3. 下载 artifact zip 文件到临时目录
4. 解压缩并查找所有 `.log` 文件
5. 智能解析日志内容：
   - 小文件（≤500 行）：显示完整内容
   - 大文件（>500 行）：提取错误、警告和末尾内容

### 日志解析策略

对于大型日志文件（超过 500 行），脚本会分段显示：

1. **错误信息**：包含 "error"、"fail"、"失败" 等关键词的行（最后 100 条）
2. **警告信息**：包含 "warning"、"warn" 等关键词的行（最后 50 条）
3. **日志末尾**：最后 100 行原始日志

这种策略可以快速定位编译失败的根本原因，而不会被大量日志淹没。

## 输出说明

脚本使用颜色标记不同类型的输出：

- 🔵 **蓝色**：信息性消息（当前状态、进度）
- 🟢 **绿色**：成功消息（CI 通过）
- 🟡 **黄色**：警告消息（CI 被取消、警告信息）
- 🔴 **红色**：错误消息（CI 失败、错误信息）

## 退出码

- `0` - CI 通过或未找到 CI runs
- `1` - CI 失败、被取消或超时

## 示例输出

### CI 成功

```
当前分支: feature/my-feature
正在检查 feature/my-feature 分支的 CI 状态...
找到 Workflow Run:
  Workflow: iOS Build
  Run ID: 12345678
  URL: https://github.com/...
  状态: completed
  结论: success

CI 已完成
  最终状态: completed
  结论: success
✓ CI 通过！
```

### CI 失败（带 Artifact 下载）

```
当前分支: feature/my-feature
正在检查 feature/my-feature 分支的 CI 状态...
找到 Workflow Run:
  Workflow: iOS Build
  Run ID: 12345678
  ...
✗ CI 失败！

==================================================
CI 失败 - 获取失败日志
==================================================

失败的 Job: Build iOS App (ID: 87654321)
--------------------------------------------------
[Job 日志内容...]
--------------------------------------------------

==================================================
检查是否有编译日志 artifacts...
==================================================
找到 1 个 artifact(s)

找到 Artifact: build-artifacts (ID: 4721777088, 大小: 33658 bytes)
正在下载 artifact (ID: 4721777088)...
✓ Artifact 下载成功: /tmp/artifact_4721777088.zip
正在解压缩 artifact...

==================================================
编译日志: xcodebuild_20251115_104337.log
==================================================
日志文件较大 (2543 行)，只显示包含错误和警告的部分...

=== 错误信息 ===
error: No such module 'SomeModule'
error: cannot find 'someFunction' in scope
...

=== 警告信息 (最后50条) ===
warning: unused variable 'foo'
...

=== 日志末尾 (最后100行) ===
...
==================================================
```

## 故障排查

### Token 权限问题

如果遇到 "403 Forbidden" 错误：
1. 确认 `GITHUB_CI_TOKEN` 已正确设置
2. 确认 Token 有足够的权限（`repo`, `actions:read`, `actions:write`）
3. 检查 Token 是否已过期

### 无法下载 Artifacts

如果 artifacts 下载失败：
1. 确认 CI workflow 确实上传了 artifacts
2. 确认 artifact 名称包含 "build" 关键词
3. 检查网络连接
4. 确认 Token 有 `actions:write` 权限

### 找不到日志文件

如果解压缩后找不到 `.log` 文件：
1. 确认 CI workflow 正确打包了日志文件
2. 检查日志文件扩展名是否为 `.log`
3. 手动下载 artifact 查看其内容结构

## 在沙盒环境中使用

在 Codex、Claude Code Web 等沙盒环境中，此脚本特别有用：
- 无法本地编译和测试
- CI 是唯一的验证机制
- 必须通过 CI 反馈来修复编译错误

推荐工作流：
1. 推送代码后立即运行脚本
2. 如果 CI 失败，分析脚本输出的编译日志
3. 修复问题后重新推送
4. 重复检查直到 CI 通过

## 贡献

如果您发现 bug 或有改进建议，欢迎提交 issue 或 PR。
