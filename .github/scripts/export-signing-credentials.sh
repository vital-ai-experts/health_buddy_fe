#!/usr/bin/env bash
set -euo pipefail

# iOS 代码签名凭证导出脚本
# 用于导出证书和 provisioning profile 以配置 GitHub Secrets

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

show_help() {
    cat << EOF
iOS 代码签名凭证导出工具

用法:
    $0 [选项]

选项:
    -o, --output <dir>      输出目录 (默认: ./signing-credentials)
    -p, --profile <path>    指定 provisioning profile 路径
    -c, --cert <name>       指定证书名称
    -h, --help              显示帮助信息

示例:
    # 交互式导出
    $0

    # 指定输出目录
    $0 -o ~/Desktop/signing

    # 指定 provisioning profile
    $0 -p ~/Downloads/profile.mobileprovision

功能:
    1. 导出开发证书为 .p12 文件
    2. 复制 provisioning profile
    3. 转换为 Base64 编码
    4. 生成 GitHub Secrets 配置说明

EOF
}

# 默认参数
OUTPUT_DIR="./signing-credentials"
PROFILE_PATH=""
CERT_NAME=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE_PATH="$2"
            shift 2
            ;;
        -c|--cert)
            CERT_NAME="$2"
            shift 2
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

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    log_error "此脚本只能在 macOS 上运行"
    exit 1
fi

echo ""
echo "══════════════════════════════════════════════════════════"
echo "  iOS 代码签名凭证导出工具"
echo "══════════════════════════════════════════════════════════"
echo ""

# 创建输出目录
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"
OUTPUT_DIR=$(pwd)  # 获取绝对路径

log_info "输出目录: $OUTPUT_DIR"
echo ""

# ==================== 步骤 1: 导出证书 ====================
log_step "步骤 1/4: 导出开发证书"
echo ""

# 列出可用的证书
log_info "查找可用的开发证书..."
AVAILABLE_CERTS=$(security find-identity -v -p codesigning | grep -E "(Apple Development|iPhone Developer)" || echo "")

if [ -z "$AVAILABLE_CERTS" ]; then
    log_error "未找到开发证书"
    log_info "请先在 Xcode 中配置证书："
    log_info "  Xcode → Settings → Accounts → Manage Certificates"
    exit 1
fi

echo "找到以下证书:"
echo "$AVAILABLE_CERTS"
echo ""

# 选择证书
if [ -z "$CERT_NAME" ]; then
    CERT_COUNT=$(echo "$AVAILABLE_CERTS" | wc -l | xargs)

    if [ "$CERT_COUNT" -eq 1 ]; then
        CERT_NAME=$(echo "$AVAILABLE_CERTS" | sed -E 's/.*"(.*)".*/\1/')
        log_info "自动选择唯一的证书: $CERT_NAME"
    else
        log_info "请选择要导出的证书"
        echo "$AVAILABLE_CERTS" | nl
        read -p "输入证书编号 [1-$CERT_COUNT]: " CERT_NUM

        if ! [[ "$CERT_NUM" =~ ^[0-9]+$ ]] || [ "$CERT_NUM" -lt 1 ] || [ "$CERT_NUM" -gt "$CERT_COUNT" ]; then
            log_error "无效的选择"
            exit 1
        fi

        CERT_NAME=$(echo "$AVAILABLE_CERTS" | sed -n "${CERT_NUM}p" | sed -E 's/.*"(.*)".*/\1/')
    fi
fi

log_success "选择的证书: $CERT_NAME"
echo ""

# 设置导出密码
read -sp "请设置证书导出密码（用于加密 .p12 文件）: " CERT_PASSWORD
echo ""
read -sp "确认密码: " CERT_PASSWORD_CONFIRM
echo ""

if [ "$CERT_PASSWORD" != "$CERT_PASSWORD_CONFIRM" ]; then
    log_error "密码不匹配"
    exit 1
fi

if [ -z "$CERT_PASSWORD" ]; then
    log_error "密码不能为空"
    exit 1
fi

# 导出证书
log_info "导出证书..."

# 查找证书的 SHA-1
CERT_SHA1=$(security find-identity -v -p codesigning | grep "$CERT_NAME" | grep -o "[0-9A-F]\{40\}" | head -1)

if [ -z "$CERT_SHA1" ]; then
    log_error "无法获取证书 SHA-1"
    exit 1
fi

# 导出为 .p12
security export -k ~/Library/Keychains/login.keychain-db \
    -t identities \
    -f pkcs12 \
    -o certificate.p12 \
    -P "$CERT_PASSWORD" \
    -i "$CERT_SHA1" 2>/dev/null || {
    log_error "导出证书失败"
    log_info "请确保证书在登录钥匙串中"
    exit 1
}

log_success "证书已导出: certificate.p12"
echo ""

# ==================== 步骤 2: 导出 Provisioning Profile ====================
log_step "步骤 2/4: 导出 Provisioning Profile"
echo ""

PP_DIR=~/Library/MobileDevice/Provisioning\ Profiles

if [ -z "$PROFILE_PATH" ]; then
    # 查找可用的 provisioning profiles
    if [ -d "$PP_DIR" ]; then
        PROFILES=$(ls -t "$PP_DIR"/*.mobileprovision 2>/dev/null || echo "")

        if [ -n "$PROFILES" ]; then
            log_info "找到以下 Provisioning Profiles:"
            echo ""

            # 显示 profile 信息
            INDEX=1
            declare -a PROFILE_ARRAY

            while IFS= read -r profile; do
                PROFILE_ARRAY+=("$profile")

                # 提取 profile 信息
                PP_NAME=$(security cms -D -i "$profile" 2>/dev/null | grep -A 1 "Name" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
                PP_TEAM=$(security cms -D -i "$profile" 2>/dev/null | grep -A 1 "TeamName" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
                PP_EXPIRE=$(security cms -D -i "$profile" 2>/dev/null | grep -A 1 "ExpirationDate" | tail -1 | sed 's/.*<date>\(.*\)<\/date>.*/\1/' | cut -d'T' -f1)

                echo "$INDEX) $PP_NAME"
                echo "   Team: $PP_TEAM"
                echo "   Expires: $PP_EXPIRE"
                echo "   Path: $profile"
                echo ""

                ((INDEX++))
            done <<< "$PROFILES"

            PROFILE_COUNT=${#PROFILE_ARRAY[@]}
            read -p "选择 Provisioning Profile [1-$PROFILE_COUNT，或 0 手动指定路径]: " PP_NUM

            if [ "$PP_NUM" -eq 0 ]; then
                read -p "请输入 .mobileprovision 文件路径: " PROFILE_PATH
            elif [[ "$PP_NUM" =~ ^[0-9]+$ ]] && [ "$PP_NUM" -ge 1 ] && [ "$PP_NUM" -le "$PROFILE_COUNT" ]; then
                PROFILE_PATH="${PROFILE_ARRAY[$((PP_NUM-1))]}"
            else
                log_error "无效的选择"
                exit 1
            fi
        else
            log_warning "未找到 Provisioning Profiles"
            read -p "请输入 .mobileprovision 文件路径: " PROFILE_PATH
        fi
    else
        log_warning "Provisioning Profiles 目录不存在"
        read -p "请输入 .mobileprovision 文件路径: " PROFILE_PATH
    fi
fi

# 验证 profile 文件
if [ ! -f "$PROFILE_PATH" ]; then
    log_error "Provisioning Profile 文件不存在: $PROFILE_PATH"
    exit 1
fi

# 复制 profile
cp "$PROFILE_PATH" profile.mobileprovision
log_success "Provisioning Profile 已复制: profile.mobileprovision"

# 显示 profile 信息
PP_NAME=$(security cms -D -i profile.mobileprovision | grep -A 1 "Name" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
PP_UUID=$(security cms -D -i profile.mobileprovision | grep -A 1 "UUID" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

log_info "Profile 名称: $PP_NAME"
log_info "Profile UUID: $PP_UUID"
echo ""

# ==================== 步骤 3: 转换为 Base64 ====================
log_step "步骤 3/4: 转换为 Base64"
echo ""

log_info "转换证书..."
base64 -i certificate.p12 -o certificate.p12.base64
log_success "已生成: certificate.p12.base64"

log_info "转换 Provisioning Profile..."
base64 -i profile.mobileprovision -o profile.mobileprovision.base64
log_success "已生成: profile.mobileprovision.base64"

echo ""

# ==================== 步骤 4: 生成配置指南 ====================
log_step "步骤 4/4: 生成 GitHub Secrets 配置指南"
echo ""

# 生成随机 keychain 密码
KEYCHAIN_PASSWORD=$(openssl rand -base64 24)

# 创建配置文档
cat > GITHUB_SECRETS_SETUP.md << EOF
# GitHub Secrets 配置指南

## 导出信息

- **导出时间**: $(date)
- **证书名称**: $CERT_NAME
- **Profile 名称**: $PP_NAME
- **Profile UUID**: $PP_UUID

## GitHub Secrets 配置

访问你的 GitHub 仓库 Settings:
https://github.com/vital-ai-experts/health_buddy_fe/settings/secrets/actions

点击 "New repository secret" 添加以下 secrets:

### 1. CERTIFICATE_P12_BASE64

**值**: 复制 \`certificate.p12.base64\` 文件的完整内容

\`\`\`bash
cat certificate.p12.base64 | pbcopy
\`\`\`

### 2. CERTIFICATE_PASSWORD

**值**: (你设置的证书导出密码)

\`\`\`
$CERT_PASSWORD
\`\`\`

⚠️  **重要**: 请妥善保管此密码！

### 3. PROVISIONING_PROFILE_BASE64

**值**: 复制 \`profile.mobileprovision.base64\` 文件的完整内容

\`\`\`bash
cat profile.mobileprovision.base64 | pbcopy
\`\`\`

### 4. KEYCHAIN_PASSWORD

**值**: (自动生成的临时 keychain 密码)

\`\`\`
$KEYCHAIN_PASSWORD
\`\`\`

## 可选 Secrets (用于自动上传到 TestFlight)

如果需要自动上传到 App Store Connect / TestFlight，还需要配置:

### 5. APP_STORE_CONNECT_API_KEY_ID

从 App Store Connect → Users and Access → Keys 获取

### 6. APP_STORE_CONNECT_ISSUER_ID

从 App Store Connect → Users and Access → Keys 获取

### 7. APP_STORE_CONNECT_API_KEY_BASE64

下载 .p8 文件后转换:

\`\`\`bash
base64 -i AuthKey_XXXXXX.p8 | pbcopy
\`\`\`

## 验证配置

配置完成后，在 GitHub Actions 中触发构建:

\`\`\`bash
# 使用 Web 界面
访问: https://github.com/vital-ai-experts/health_buddy_fe/actions/workflows/ios-archive-signed.yml

# 或使用 gh CLI
gh workflow run ios-archive-signed.yml \\
  -f configuration=Release \\
  -f export_method=development
\`\`\`

## 文件说明

导出的文件:

- \`certificate.p12\` - 开发证书 (加密)
- \`certificate.p12.base64\` - Base64 编码的证书 (用于 GitHub Secrets)
- \`profile.mobileprovision\` - Provisioning Profile
- \`profile.mobileprovision.base64\` - Base64 编码的 Profile (用于 GitHub Secrets)
- \`GITHUB_SECRETS_SETUP.md\` - 本配置指南

## 安全提示

⚠️  **重要安全提醒**:

1. **不要提交这些文件到 Git 仓库**
2. **配置完成后建议删除本地文件**
3. **证书密码请使用密码管理器保存**
4. **定期轮换证书和 profiles**
5. **如果泄露，立即在 Apple Developer 网站撤销证书**

## 快速复制命令

\`\`\`bash
# 复制证书 Base64
cat certificate.p12.base64 | pbcopy

# 复制 Profile Base64
cat profile.mobileprovision.base64 | pbcopy
\`\`\`

## 故障排除

如果构建失败:

1. 检查证书是否过期
2. 检查 Profile 是否过期
3. 确认 Bundle ID 匹配
4. 查看 GitHub Actions 日志

详细文档: .github/CODE-SIGNING-GUIDE.md

---

**生成时间**: $(date)
**工具版本**: export-signing-credentials.sh v1.0
EOF

log_success "已生成配置指南: GITHUB_SECRETS_SETUP.md"
echo ""

# ==================== 完成 ====================
echo ""
echo "══════════════════════════════════════════════════════════"
echo "  ✅ 导出完成！"
echo "══════════════════════════════════════════════════════════"
echo ""
log_success "所有文件已导出到: $OUTPUT_DIR"
echo ""
echo "导出的文件:"
echo "  ✓ certificate.p12"
echo "  ✓ certificate.p12.base64"
echo "  ✓ profile.mobileprovision"
echo "  ✓ profile.mobileprovision.base64"
echo "  ✓ GITHUB_SECRETS_SETUP.md"
echo ""
log_info "下一步:"
echo "  1. 打开配置指南: cat $OUTPUT_DIR/GITHUB_SECRETS_SETUP.md"
echo "  2. 按照指南配置 GitHub Secrets"
echo "  3. 在 GitHub Actions 中触发构建测试"
echo ""
log_warning "安全提醒:"
echo "  • 不要将这些文件提交到 Git"
echo "  • 配置完成后建议删除本地文件"
echo "  • 妥善保管证书密码"
echo ""
echo "══════════════════════════════════════════════════════════"
