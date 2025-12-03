# GitHub CI 状态检查脚本

## 脚本说明

`check_ci_status.sh` - 用于检查当前分支的 GitHub Actions CI 状态

## 功能特性

- ✅ 自动检测当前 Git 分支
- ✅ 查询最新的 CI workflow run 状态
- ✅ 如果 CI 正在运行，自动等待完成（最多 30 分钟）
- ✅ 如果 CI 失败，自动获取并打印失败日志
- ✅ **自动下载和解析编译日志 Artifacts**
- ✅ **智能提取错误和警告信息**
- ✅ 彩色输出，清晰易读

## 使用方法

### 环境变量要求

脚本需要设置 `GITHUB_CI_TOKEN` 环境变量：

```bash
export GITHUB_CI_TOKEN="your_github_token"
```

**Token 权限要求：**
- `repo` - 访问仓库
- `actions:read` - 读取 Actions 状态
- `actions:write` - 下载 artifacts

### 运行脚本

```bash
# 在项目根目录执行
.github/check_ci_status.sh
```

### 退出代码

- `0` - CI 通过或当前分支没有 CI runs
- `1` - CI 失败、被取消、超时或其他错误

## 使用场景

### 场景 1: 在推送前检查 CI 状态

```bash
# 推送代码后检查 CI 是否通过
git push && .github/check_ci_status.sh
```

### 场景 2: 在合并前验证 CI

```bash
# 切换到功能分支并检查 CI
git checkout feature-branch
.github/check_ci_status.sh
```

### 场景 3: 自动化脚本中使用

```bash
#!/bin/bash
# 等待 CI 完成后自动合并
.github/check_ci_status.sh
if [ $? -eq 0 ]; then
    git merge feature-branch
else
    echo "CI 失败，取消合并"
    exit 1
fi
```

## 输出示例

### CI 通过

```
当前分支: feature-branch
正在检查 feature-branch 分支的 CI 状态...
找到 Workflow Run:
  Workflow: iOS Build
  Run ID: 12345678
  URL: https://github.com/vital-ai-experts/health_buddy_fe/actions/runs/12345678
  状态: completed
  结论: success

CI 已完成
  最终状态: completed
  结论: success
✓ CI 通过！
```

### CI 失败

```
当前分支: feature-branch
正在检查 feature-branch 分支的 CI 状态...
找到 Workflow Run:
  Workflow: iOS Build
  Run ID: 12345678
  URL: https://github.com/vital-ai-experts/health_buddy_fe/actions/runs/12345678
  状态: completed
  结论: failure

CI 已完成
  最终状态: completed
  结论: failure
✗ CI 失败！
==================================================
CI 失败 - 获取失败日志
==================================================

失败的 Job: build (ID: 55478649706)
--------------------------------------------------
[错误] 构建失败！
[详细日志内容...]
--------------------------------------------------
```

### CI 正在运行

```
当前分支: feature-branch
正在检查 feature-branch 分支的 CI 状态...
找到 Workflow Run:
  Workflow: iOS Build
  Run ID: 12345678
  URL: https://github.com/vital-ai-experts/health_buddy_fe/actions/runs/12345678
  状态: in_progress
  结论: null
CI 正在运行中... (已等待 10 秒)
CI 正在运行中... (已等待 20 秒)
...
```

## 编译日志 Artifacts 自动下载

### 工作原理

当 CI 失败时，脚本会自动：

1. 先显示 GitHub Actions 标准 Job 日志
2. 查询该 workflow run 的所有 artifacts
3. 自动识别名称包含 "build" 的 artifacts（如 `build-artifacts`）
4. 下载 artifact zip 文件到临时目录
5. 解压缩并查找所有 `.log` 文件
6. 智能解析日志内容并显示关键信息
7. 自动清理临时文件

### 智能日志解析策略

对于大型日志文件（超过 500 行），脚本会分段显示：

1. **错误信息**：提取包含 "error"、"fail"、"失败"、"❌" 等关键词的行（最后 100 条）
2. **警告信息**：提取包含 "warning"、"warn"、"⚠" 等关键词的行（最后 50 条）
3. **日志末尾**：显示最后 100 行原始日志

对于小文件（≤500 行）：直接显示完整内容。

### 示例输出（带 Artifact 下载）

```
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

## 配置参数

脚本内部可配置的参数（在脚本开头）：

- `CHECK_INTERVAL` - 检查间隔时间（默认 10 秒）
- `MAX_WAIT_TIME` - 最大等待时间（默认 1800 秒 = 30 分钟）

## 故障排查

### 错误：GITHUB_CI_TOKEN 环境变量未设置

确保已设置 GitHub token：

```bash
export GITHUB_CI_TOKEN="your_token_here"
```

### 错误：Bad credentials

检查 token 是否有效，需要具有以下权限：
- `repo` - 访问仓库
- `actions` - 访问 GitHub Actions

### 当前分支没有 CI workflow runs

这可能是因为：
- 分支还未推送到远程仓库
- 该分支没有触发 CI workflow
- CI workflow 的触发条件不匹配当前分支

### 无法下载 Artifacts

如果遇到 artifacts 下载失败：
1. 确认 CI workflow 确实上传了 artifacts
2. 确认 artifact 名称包含 "build" 关键词
3. 检查 Token 是否有 `actions:write` 权限
4. 检查网络连接是否正常

### 找不到日志文件

如果解压缩后找不到 `.log` 文件：
1. 确认 CI workflow 正确打包了日志文件
2. 检查日志文件扩展名是否为 `.log`
3. 手动下载 artifact 查看其内容结构

## 沙盒环境使用建议

在 Codex、Claude Code Web 等沙盒环境中，此脚本特别有用：
- 无法本地编译和测试
- CI 是唯一的验证机制
- 必须通过 CI 反馈来修复编译错误

**推荐工作流：**
```bash
# 1. 推送代码后立即检查 CI
git push && .github/check_ci_status.sh

# 2. 如果失败，脚本会自动下载并显示编译日志

# 3. 修复问题后重新推送
git add .
git commit -m "fix: resolve CI errors"
git push

# 4. 再次检查直到 CI 通过
.github/check_ci_status.sh
```

## 重要说明！！
编译失败一定要找到失败的原因，不要靠猜！不要轻易放弃，你之前每次都成功通过日志找到了原因。
脚本可以下载 Artifact 拿到编译日志。
比如
```
bash .github/check_ci_status.sh 2>&1 | grep -A 50 "检查是否有编译日志"
```