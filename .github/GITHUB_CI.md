# GitHub CI 状态检查脚本

## 脚本说明

`check_ci_status.sh` - 用于检查当前分支的 GitHub Actions CI 状态

## 功能特性

- ✅ 自动检测当前 Git 分支
- ✅ 查询最新的 CI workflow run 状态
- ✅ 如果 CI 正在运行，自动等待完成（最多 30 分钟）
- ✅ 如果 CI 失败，自动获取并打印失败日志
- ✅ 彩色输出，清晰易读

## 使用方法

### 环境变量要求

脚本需要设置 `GITHUB_CI_TOKEN` 环境变量：

```bash
export GITHUB_CI_TOKEN="your_github_token"
```

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
