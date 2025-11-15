#!/usr/bin/env bash
set -euo pipefail

# CI/CD 配置验证脚本
# 用于验证所有配置文件的正确性

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; PASSED=$((PASSED+1)); }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; FAILED=$((FAILED+1)); }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=================================="
echo "  CI/CD 配置验证"
echo "=================================="
echo ""

# 1. 验证 YAML 文件
log_info "验证 YAML 配置文件..."
if python3 -c "
import yaml
import sys

files = [
    '.github/workflows/build.yml',
    '.github/workflows/manual-build.yml',
    'ios/project.yml'
]

for file in files:
    try:
        with open(file, 'r') as f:
            yaml.safe_load(f)
    except Exception as e:
        print(f'Error in {file}: {e}')
        sys.exit(1)
" 2>&1; then
    log_success "YAML 文件语法验证通过"
else
    log_error "YAML 文件语法验证失败"
fi

# 2. 验证 Shell 脚本
log_info "验证 Shell 脚本语法..."
scripts=(
    ".github/scripts/ci-helper.sh"
    "ios/scripts/build.sh"
    "ios/scripts/generate_project.sh"
)

for script in "${scripts[@]}"; do
    if bash -n "$script" 2>&1; then
        log_success "脚本语法正确: $script"
    else
        log_error "脚本语法错误: $script"
    fi
done

# 3. 检查文件权限
log_info "检查脚本执行权限..."
if [ -x ".github/scripts/ci-helper.sh" ]; then
    log_success "ci-helper.sh 有执行权限"
else
    log_error "ci-helper.sh 缺少执行权限"
fi

if [ -x "ios/scripts/build.sh" ]; then
    log_success "build.sh 有执行权限"
else
    log_error "build.sh 缺少执行权限"
fi

# 4. 验证项目配置
log_info "验证项目配置完整性..."
if python3 -c "
import yaml
import sys

with open('ios/project.yml', 'r') as f:
    project = yaml.safe_load(f)

required = ['name', 'targets', 'packages', 'schemes']
for key in required:
    if key not in project:
        print(f'Missing required key: {key}')
        sys.exit(1)

if not project['targets']:
    print('No targets defined')
    sys.exit(1)
" 2>&1; then
    log_success "项目配置完整"
else
    log_error "项目配置不完整"
fi

# 5. 检查文档文件
log_info "检查文档文件..."
docs=(
    ".github/README.md"
    ".github/QUICKSTART.md"
    ".github/CI-SETUP.md"
    ".github/SECRETS-EXAMPLE.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        log_success "文档存在: $doc"
    else
        log_error "文档缺失: $doc"
    fi
done

# 6. 检查 .gitignore
log_info "验证 .gitignore..."
if grep -q "ci-logs/" .gitignore && grep -q "ci-artifacts/" .gitignore; then
    log_success ".gitignore 配置正确"
else
    log_error ".gitignore 缺少必要配置"
fi

# 7. 检查 workflow 配置
log_info "检查 workflow 配置..."
if grep -q "workflow_dispatch" .github/workflows/manual-build.yml; then
    log_success "manual-build.yml 支持手动触发"
else
    log_error "manual-build.yml 缺少 workflow_dispatch"
fi

if grep -q "upload-artifact" .github/workflows/build.yml; then
    log_success "build.yml 配置了产物上传"
else
    log_error "build.yml 缺少产物上传配置"
fi

# 8. 环境检查
log_info "检查构建环境..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    log_success "运行在 macOS 环境"

    if command -v xcodebuild >/dev/null 2>&1; then
        log_success "Xcode 已安装"
    else
        log_warning "Xcode 未安装 (本地构建需要)"
    fi

    if command -v xcodegen >/dev/null 2>&1; then
        log_success "XcodeGen 已安装"
    else
        log_warning "XcodeGen 未安装 (本地构建需要)"
    fi
else
    log_warning "非 macOS 环境，本地构建不可用"
    log_info "将使用 GitHub Actions 云端 macOS runner"
fi

if command -v gh >/dev/null 2>&1; then
    log_success "GitHub CLI 已安装"
else
    log_warning "GitHub CLI 未安装 (触发云端构建需要)"
fi

# 总结
echo ""
echo "=================================="
echo "  验证结果"
echo "=================================="
echo -e "${GREEN}通过: $PASSED${NC}"
echo -e "${RED}失败: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ 所有验证通过！${NC}"
    echo ""
    echo "后续步骤:"
    echo "1. 在 GitHub Actions 上触发构建测试"
    echo "2. 访问: https://github.com/vital-ai-experts/health_buddy_fe/actions"
    echo "3. 选择 'Manual iOS Build' 并点击 'Run workflow'"
    echo ""
    exit 0
else
    echo -e "${RED}❌ 存在 $FAILED 个失败项${NC}"
    echo ""
    echo "请修复上述问题后重试"
    exit 1
fi
