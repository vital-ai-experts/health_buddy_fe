#!/usr/bin/env bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
PROJECT_PATH="${REPO_ROOT}/HealthBuddy.xcodeproj"
SCHEME="HealthBuddy"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
BUILD_DIR="${REPO_ROOT}/build"
CONFIGURATION="Debug"

# 日志函数
log_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

log_error() {
    echo -e "${RED}[错误]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help          显示帮助信息
    -c, --clean         在构建前执行清理
    -v, --verbose       显示详细构建输出
    -d, --destination   指定构建目标 (默认: iPhone 17 Pro)
    --release           使用 Release 配置构建
    --archive           创建归档并导出 .ipa (仅适用于真机)

示例:
    $0                              # 快速构建到 build 目录
    $0 --clean                      # 清理后构建
    $0 --verbose                    # 显示详细输出
    $0 -d "iPhone 16 Pro"          # 指定其他模拟器
    $0 --release                    # Release 模式构建
    $0 --archive                    # 创建归档并生成 .ipa

EOF
}

# 解析命令行参数
CLEAN_BUILD=false
VERBOSE=false
CREATE_ARCHIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--destination)
            DESTINATION="platform=iOS Simulator,name=$2"
            shift 2
            ;;
        --release)
            CONFIGURATION="Release"
            shift
            ;;
        --archive)
            CREATE_ARCHIVE=true
            CONFIGURATION="Release"
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 打印配置信息
log_info "构建配置:"
echo "  项目: ${SCHEME}"
echo "  配置: ${CONFIGURATION}"
echo "  目标: ${DESTINATION}"
echo "  清理: ${CLEAN_BUILD}"
echo "  输出: ${BUILD_DIR}"
echo ""

# 检查项目文件是否存在
if [ ! -d "${PROJECT_PATH}" ]; then
    log_error "未找到项目文件: ${PROJECT_PATH}"
    log_info "尝试运行: scripts/generate_project.sh"
    exit 1
fi

# 切换到项目根目录
cd "${REPO_ROOT}"

# 创建构建输出目录
mkdir -p "${BUILD_DIR}"

# 开始计时
START_TIME=$(date +%s)

# 清理构建（如果需要）
if [ "$CLEAN_BUILD" = true ]; then
    log_info "清理构建缓存..."
    xcodebuild -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -destination "${DESTINATION}" \
               -configuration "${CONFIGURATION}" \
               clean > /dev/null 2>&1

    # 清理本地 build 目录
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
        mkdir -p "${BUILD_DIR}"
    fi

    log_success "清理完成"
fi

# 构建项目
if [ "$CREATE_ARCHIVE" = true ]; then
    log_info "开始归档..."
    echo ""

    ARCHIVE_PATH="${BUILD_DIR}/HealthBuddy.xcarchive"
    EXPORT_PATH="${BUILD_DIR}"

    # 创建归档
    if [ "$VERBOSE" = true ]; then
        xcodebuild archive \
                   -project "${PROJECT_PATH}" \
                   -scheme "${SCHEME}" \
                   -configuration "${CONFIGURATION}" \
                   -archivePath "${ARCHIVE_PATH}"
        BUILD_RESULT=$?
    else
        BUILD_LOG=$(mktemp)
        xcodebuild archive \
                   -project "${PROJECT_PATH}" \
                   -scheme "${SCHEME}" \
                   -configuration "${CONFIGURATION}" \
                   -archivePath "${ARCHIVE_PATH}" 2>&1 | tee "${BUILD_LOG}" | \
                   grep --line-buffered -E "^\*\*|error:|warning:|note:|Building|Compiling|Linking|Signing" || true
        BUILD_RESULT=${PIPESTATUS[0]}

        if [ $BUILD_RESULT -ne 0 ]; then
            echo ""
            log_error "归档失败，完整错误日志:"
            echo ""
            cat "${BUILD_LOG}"
        fi
        rm -f "${BUILD_LOG}"
    fi

    # 如果归档成功，导出 IPA
    if [ $BUILD_RESULT -eq 0 ]; then
        log_info "导出 IPA..."

        # 尝试从归档中自动获取 Team ID
        TEAM_ID=$(grep -A1 "<key>Team</key>" "${ARCHIVE_PATH}/Info.plist" | grep string | sed -E 's/.*<string>(.*)<\/string>.*/\1/' | head -1)

        if [ -z "${TEAM_ID}" ]; then
            log_warning "无法自动获取 Team ID，尝试从代码签名获取..."
            # 尝试从本地开发证书获取
            TEAM_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | sed -E 's/.*\((.*)\).*/\1/')
        fi

        if [ -z "${TEAM_ID}" ]; then
            log_error "无法获取 Team ID，跳过 IPA 导出"
            log_info "归档文件已保存: ${ARCHIVE_PATH}"
        else
            log_info "使用 Team ID: ${TEAM_ID}"

            # 创建 ExportOptions.plist
            EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"
            cat > "${EXPORT_OPTIONS}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

            EXPORT_LOG=$(mktemp)
            if xcodebuild -exportArchive \
                       -archivePath "${ARCHIVE_PATH}" \
                       -exportPath "${EXPORT_PATH}" \
                       -exportOptionsPlist "${EXPORT_OPTIONS}" > "${EXPORT_LOG}" 2>&1; then
                log_success "IPA 导出成功"
            else
                log_error "IPA 导出失败"
                if [ "$VERBOSE" = true ]; then
                    cat "${EXPORT_LOG}"
                else
                    log_info "查看详细错误: cat ${EXPORT_LOG}"
                fi
            fi
            rm -f "${EXPORT_LOG}"
        fi
    fi
else
    log_info "开始构建..."
    echo ""

    # 设置自定义构建路径
    SYMROOT="${BUILD_DIR}"
    DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"

    if [ "$VERBOSE" = true ]; then
        # 详细模式：显示所有输出
        xcodebuild -project "${PROJECT_PATH}" \
                   -scheme "${SCHEME}" \
                   -destination "${DESTINATION}" \
                   -configuration "${CONFIGURATION}" \
                   SYMROOT="${SYMROOT}" \
                   OBJROOT="${DERIVED_DATA_PATH}" \
                   build
        BUILD_RESULT=$?
    else
        # 简洁模式：只显示重要信息
        BUILD_LOG=$(mktemp)

        xcodebuild -project "${PROJECT_PATH}" \
                   -scheme "${SCHEME}" \
                   -destination "${DESTINATION}" \
                   -configuration "${CONFIGURATION}" \
                   SYMROOT="${SYMROOT}" \
                   OBJROOT="${DERIVED_DATA_PATH}" \
                   build 2>&1 | tee "${BUILD_LOG}" | \
                   grep --line-buffered -E "^\*\*|error:|warning:|note:|Building|Compiling|Linking|Signing" || true

        BUILD_RESULT=${PIPESTATUS[0]}

        # 如果构建失败，显示完整错误日志
        if [ $BUILD_RESULT -ne 0 ]; then
            echo ""
            log_error "构建失败，完整错误日志:"
            echo ""
            cat "${BUILD_LOG}"
        fi

        rm -f "${BUILD_LOG}"
    fi
fi

# 计算构建时间
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $BUILD_RESULT -eq 0 ]; then
    log_success "构建成功！ ✅"
    log_info "构建时间: ${MINUTES}分${SECONDS}秒"

    # 显示输出路径
    if [ "$CREATE_ARCHIVE" = true ]; then
        # 归档模式
        if [ -d "${ARCHIVE_PATH}" ]; then
            ARCHIVE_SIZE=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
            log_info "归档大小: ${ARCHIVE_SIZE}"
            log_info "归档路径: ${ARCHIVE_PATH}"
        fi

        IPA_FILE="${EXPORT_PATH}/HealthBuddy.ipa"
        if [ -f "${IPA_FILE}" ]; then
            IPA_SIZE=$(du -sh "${IPA_FILE}" | cut -f1)
            log_info "IPA 大小: ${IPA_SIZE}"
            log_info "IPA 路径: ${IPA_FILE}"
        fi
    else
        # 普通构建模式
        APP_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/HealthBuddy.app"
        if [ -d "${APP_PATH}" ]; then
            APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
            log_info "App 大小: ${APP_SIZE}"
            log_info "App 路径: ${APP_PATH}"
        else
            # 尝试查找 .app 文件
            APP_PATH=$(find "${BUILD_DIR}" -name "HealthBuddy.app" -type d | head -1)
            if [ -n "${APP_PATH}" ]; then
                APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
                log_info "App 大小: ${APP_SIZE}"
                log_info "App 路径: ${APP_PATH}"
            fi
        fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    log_error "构建失败！ ❌"
    log_info "构建时间: ${MINUTES}分${SECONDS}秒"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "提示: 使用 -v 参数查看详细输出"
    exit 1
fi
