# 如何获取 GitHub Token 并触发构建

## 方法 1: 创建 Personal Access Token (经典版)

### 步骤 1: 创建 Token

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单滚动到底部 → **Developer settings**
4. 点击 **Personal access tokens** → **Tokens (classic)**
5. 点击右上角 **Generate new token** → **Generate new token (classic)**

### 步骤 2: 配置 Token

**Note (名称)**: 填写描述，例如：`CI/CD Workflow Trigger`

**Expiration (过期时间)**: 建议选择
- 30 days (临时使用)
- 90 days (常规使用)
- No expiration (永久使用，需谨慎保管)

**Select scopes (权限范围)**: 勾选以下权限
- ✅ **workflow** - 触发 GitHub Actions 工作流（必需）
- ✅ **repo** - 完整的仓库访问权限（推荐）
  - 包括 repo:status, public_repo 等子权限

### 步骤 3: 生成并保存

1. 滚动到底部，点击 **Generate token**
2. **重要**: 立即复制生成的 token（格式类似 `ghp_xxxxxxxxxxxx`）
3. ⚠️ **这是唯一一次显示，离开页面后无法再查看**
4. 保存到安全的地方（密码管理器或本地安全文件）

---

## 方法 2: 创建 Fine-grained Token (新版，更安全)

### 步骤 1: 创建 Token

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单 → **Developer settings**
4. 点击 **Personal access tokens** → **Fine-grained tokens**
5. 点击 **Generate new token**

### 步骤 2: 配置 Token

**Token name**: 例如 `health_buddy_fe_ci_trigger`

**Expiration**: 选择过期时间

**Repository access**: 选择
- ✅ **Only select repositories**
- 然后选择 **vital-ai-experts/health_buddy_fe**

**Repository permissions**: 设置以下权限
- **Actions**: Read and write (触发 workflow)
- **Contents**: Read (读取代码)
- **Metadata**: Read (默认)

### 步骤 3: 生成并保存

点击 **Generate token** 并立即保存

---

## 使用 Token 触发构建

### 方式 1: 使用 curl 命令

创建脚本文件:

```bash
#!/bin/bash

# 你的 GitHub Token
GITHUB_TOKEN="ghp_your_token_here"

# 仓库信息
OWNER="vital-ai-experts"
REPO="health_buddy_fe"
WORKFLOW="manual-build.yml"
BRANCH="claude/github-ci-packaging-setup-013J662wzTMQU7EopZ8Gg3JP"

# 触发构建
curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW}/dispatches \
  -d "{
    \"ref\": \"${BRANCH}\",
    \"inputs\": {
      \"configuration\": \"Debug\",
      \"build_type\": \"simulator\",
      \"clean_build\": \"false\",
      \"upload_ipa\": \"false\"
    }
  }"

echo "构建已触发！查看状态："
echo "https://github.com/${OWNER}/${REPO}/actions"
```

保存为 `trigger_build.sh`，然后运行：

```bash
chmod +x trigger_build.sh
./trigger_build.sh
```

### 方式 2: 使用 GitHub CLI (推荐)

GitHub CLI 会自动管理 token：

```bash
# 1. 安装 gh CLI
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# 2. 登录（会自动获取 token）
gh auth login

# 3. 触发构建
gh workflow run manual-build.yml \
  --ref claude/github-ci-packaging-setup-013J662wzTMQU7EopZ8Gg3JP \
  -f configuration=Debug \
  -f build_type=simulator \
  -f clean_build=false \
  -f upload_ipa=false

# 4. 查看构建状态
gh run list --limit 5
gh run watch  # 实时监控最新构建
```

### 方式 3: 使用项目的 ci-helper.sh 脚本

脚本已经准备好，只需配置 gh CLI：

```bash
# 1. 安装并登录 gh CLI
gh auth login

# 2. 使用辅助脚本
./.github/scripts/ci-helper.sh trigger

# 3. 实时监控
./.github/scripts/ci-helper.sh watch

# 4. 下载日志
./.github/scripts/ci-helper.sh logs

# 5. 下载产物
./.github/scripts/ci-helper.sh download
```

---

## 在当前 Linux 环境中使用 Token

创建一个快速触发脚本：

```bash
#!/bin/bash
# 保存为 /tmp/trigger_ci.sh

read -sp "请输入你的 GitHub Token: " GITHUB_TOKEN
echo ""

curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  https://api.github.com/repos/vital-ai-experts/health_buddy_fe/actions/workflows/manual-build.yml/dispatches \
  -d '{
    "ref": "claude/github-ci-packaging-setup-013J662wzTMQU7EopZ8Gg3JP",
    "inputs": {
      "configuration": "Debug",
      "build_type": "simulator",
      "clean_build": "false",
      "upload_ipa": "false"
    }
  }'

if [ $? -eq 0 ]; then
  echo -e "\n✅ 构建已触发成功！"
  echo "查看状态: https://github.com/vital-ai-experts/health_buddy_fe/actions"
else
  echo -e "\n❌ 触发失败，请检查 token 权限"
fi
```

---

## Token 安全最佳实践

### ✅ 应该做的

1. **最小权限原则**: 只授予必要的权限
2. **设置过期时间**: 避免使用永久 token
3. **安全保存**: 使用密码管理器或环境变量
4. **定期轮换**: 定期重新生成 token
5. **限制仓库**: 使用 fine-grained token 限制到特定仓库

### ❌ 不应该做的

1. **不要提交到代码仓库**: 永远不要把 token 提交到 Git
2. **不要在日志中打印**: 避免在脚本输出中显示 token
3. **不要分享**: token 等同于密码，不要分享给他人
4. **不要使用明文**: 避免在脚本中硬编码

### 使用环境变量（推荐）

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加（仅本地使用）
export GITHUB_TOKEN="ghp_your_token_here"

# 或者临时设置
export GITHUB_TOKEN="ghp_your_token_here"

# 然后脚本中引用
curl -H "Authorization: token ${GITHUB_TOKEN}" ...
```

### 使用 .env 文件（本地开发）

创建 `.env` 文件（确保在 .gitignore 中）：

```bash
GITHUB_TOKEN=ghp_your_token_here
```

然后在脚本中加载：

```bash
#!/bin/bash
source .env

curl -H "Authorization: token ${GITHUB_TOKEN}" ...
```

---

## 验证 Token 权限

创建测试脚本验证 token 是否有效：

```bash
#!/bin/bash

read -sp "请输入 GitHub Token: " TOKEN
echo ""

# 测试 token 有效性
echo "测试 Token 有效性..."
curl -s -H "Authorization: token ${TOKEN}" \
  https://api.github.com/user | jq -r '.login'

# 测试仓库访问权限
echo "测试仓库访问权限..."
curl -s -H "Authorization: token ${TOKEN}" \
  https://api.github.com/repos/vital-ai-experts/health_buddy_fe | jq -r '.full_name'

# 测试 workflow 权限
echo "测试 Workflow 权限..."
curl -s -H "Authorization: token ${TOKEN}" \
  https://api.github.com/repos/vital-ai-experts/health_buddy_fe/actions/workflows | jq -r '.total_count'

echo "✅ 权限测试完成"
```

---

## 撤销 Token

如果 token 泄露或不再需要：

1. 访问 GitHub → Settings → Developer settings
2. 进入 Personal access tokens
3. 找到对应的 token
4. 点击 **Delete** 或 **Revoke**

---

## 快速参考

| 方式 | 优点 | 缺点 |
|------|------|------|
| **Web 界面** | 无需 token，最简单 | 需要手动操作 |
| **GitHub CLI** | 自动管理 token，最方便 | 需要安装 gh |
| **curl + Token** | 灵活，可脚本化 | 需要管理 token |

**推荐**:
- 一次性使用 → Web 界面
- 日常使用 → GitHub CLI
- 自动化脚本 → curl + Token (环境变量)

---

## 故障排除

### 401 Unauthorized
- Token 无效或已过期
- 需要重新生成 token

### 403 Forbidden
- Token 缺少必要权限
- 需要添加 `workflow` 权限

### 404 Not Found
- 仓库路径错误
- Token 没有仓库访问权限

### 422 Unprocessable Entity
- 分支名称错误
- 输入参数格式错误
