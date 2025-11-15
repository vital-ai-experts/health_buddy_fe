#!/usr/bin/env bash
set -euo pipefail

# GitHub Actions 触发脚本（使用 Token）
# 使用方法: ./trigger-with-token.sh [token]

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# 仓库配置
OWNER="vital-ai-experts"
REPO="health_buddy_fe"
WORKFLOW="manual-build.yml"
BRANCH="claude/github-ci-packaging-setup-013J662wzTMQU7EopZ8Gg3JP"

# 显示帮助
show_help() {
    cat << EOF
GitHub Actions 触发脚本

用法:
    $0 [选项]

选项:
    -t, --token <token>         GitHub Personal Access Token
    -c, --config <config>       构建配置 (Debug/Release, 默认: Debug)
    -b, --build-type <type>     构建类型 (simulator/archive, 默认: simulator)
    --clean                     清理构建
    -h, --help                  显示帮助信息

示例:
    # 交互式输入 token
    $0

    # 使用命令行参数
    $0 -t ghp_your_token_here

    # 指定构建配置
    $0 -t ghp_your_token_here -c Release -b archive

    # 从环境变量读取
    export GITHUB_TOKEN=ghp_your_token_here
    $0

获取 Token:
    访问: https://github.com/settings/tokens/new
    权限: 勾选 'workflow' 和 'repo'
    详细指南: .github/GITHUB-TOKEN-GUIDE.md

EOF
}

# 解析参数
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
CONFIGURATION="Debug"
BUILD_TYPE="simulator"
CLEAN_BUILD="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -c|--config)
            CONFIGURATION="$2"
            shift 2
            ;;
        -b|--build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 如果没有 token，交互式输入
if [ -z "$GITHUB_TOKEN" ]; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  GitHub Token 输入"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    log_info "需要 GitHub Personal Access Token"
    log_info "如何获取: https://github.com/settings/tokens/new"
    log_info "必需权限: workflow, repo"
    echo ""

    read -sp "请输入你的 GitHub Token (输入不可见): " GITHUB_TOKEN
    echo ""
    echo ""

    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "Token 不能为空"
        exit 1
    fi
fi

# 验证 token 格式
if [[ ! "$GITHUB_TOKEN" =~ ^(ghp_|github_pat_) ]]; then
    log_warning "Token 格式可能不正确"
    log_warning "Personal Access Token 通常以 'ghp_' 开头"
    log_warning "Fine-grained Token 通常以 'github_pat_' 开头"
    echo ""
fi

# 验证 token 有效性
log_info "验证 Token 有效性..."
USER_INFO=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    https://api.github.com/user)

if echo "$USER_INFO" | grep -q "Bad credentials"; then
    log_error "Token 无效或已过期"
    log_info "请重新生成 token: https://github.com/settings/tokens"
    exit 1
fi

USERNAME=$(echo "$USER_INFO" | grep -o '"login"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
if [ -n "$USERNAME" ]; then
    log_success "Token 有效，已登录为: $USERNAME"
else
    log_error "无法验证 token"
    exit 1
fi

# 显示构建配置
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  构建配置"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  仓库:        ${OWNER}/${REPO}"
echo "  工作流:      ${WORKFLOW}"
echo "  分支:        ${BRANCH}"
echo "  配置:        ${CONFIGURATION}"
echo "  构建类型:    ${BUILD_TYPE}"
echo "  清理构建:    ${CLEAN_BUILD}"
echo ""

# 确认
read -p "确认触发构建? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "已取消"
    exit 0
fi

# 构建请求体
REQUEST_BODY=$(cat <<EOF
{
  "ref": "${BRANCH}",
  "inputs": {
    "configuration": "${CONFIGURATION}",
    "build_type": "${BUILD_TYPE}",
    "clean_build": "${CLEAN_BUILD}",
    "upload_ipa": "true"
  }
}
EOF
)

# 触发构建
log_info "正在触发构建..."

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Content-Type: application/json" \
    https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW}/dispatches \
    -d "${REQUEST_BODY}")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  结果"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ "$HTTP_CODE" = "204" ]; then
    log_success "构建已成功触发！✅"
    echo ""
    log_info "构建状态查看地址:"
    echo "  https://github.com/${OWNER}/${REPO}/actions"
    echo ""
    log_info "预计构建时间:"
    if [ "$BUILD_TYPE" = "simulator" ]; then
        echo "  Debug:   5-10 分钟"
        echo "  Release: 8-15 分钟"
    else
        echo "  Archive: 10-20 分钟"
    fi
    echo ""

    # 等待几秒让工作流出现
    log_info "等待工作流启动..."
    sleep 5

    # 获取最新的 run
    log_info "获取最新构建信息..."
    RUNS=$(curl -s \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${OWNER}/${REPO}/actions/runs?per_page=1")

    RUN_ID=$(echo "$RUNS" | grep -o '"id"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*')
    RUN_URL=$(echo "$RUNS" | grep -o '"html_url"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$RUN_ID" ]; then
        echo ""
        log_success "Run ID: $RUN_ID"
        log_success "直接查看: $RUN_URL"
        echo ""

        if command -v gh >/dev/null 2>&1; then
            log_info "提示: 你也可以使用 gh CLI 监控构建:"
            echo "  gh run watch $RUN_ID"
            echo "  gh run view $RUN_ID"
        fi
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"
    exit 0

elif [ "$HTTP_CODE" = "401" ]; then
    log_error "认证失败 (401 Unauthorized)"
    log_info "Token 可能无效或已过期"
    log_info "请重新生成: https://github.com/settings/tokens"
    exit 1

elif [ "$HTTP_CODE" = "403" ]; then
    log_error "权限不足 (403 Forbidden)"
    log_info "Token 缺少必要权限"
    log_info "需要权限: workflow, repo"
    log_info "请检查 token 权限: https://github.com/settings/tokens"
    exit 1

elif [ "$HTTP_CODE" = "404" ]; then
    log_error "未找到资源 (404 Not Found)"
    log_info "可能原因:"
    log_info "  - 仓库路径错误"
    log_info "  - 工作流文件不存在"
    log_info "  - Token 没有仓库访问权限"
    exit 1

elif [ "$HTTP_CODE" = "422" ]; then
    log_error "请求无法处理 (422 Unprocessable Entity)"
    log_info "可能原因:"
    log_info "  - 分支名称错误"
    log_info "  - 输入参数格式错误"
    log_info "  - 工作流配置问题"
    if [ -n "$RESPONSE_BODY" ]; then
        echo ""
        echo "响应详情:"
        echo "$RESPONSE_BODY"
    fi
    exit 1

else
    log_error "请求失败 (HTTP $HTTP_CODE)"
    if [ -n "$RESPONSE_BODY" ]; then
        echo ""
        echo "响应内容:"
        echo "$RESPONSE_BODY"
    fi
    exit 1
fi
