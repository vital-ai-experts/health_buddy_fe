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
PROJECT_PATH="${REPO_ROOT}/ThriveBody.xcodeproj"
SCHEME="ThriveBody"
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

# 显示进度动画
show_progress() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    # 检查是否是交互式终端
    if [ -t 1 ]; then
        # 交互式终端：显示动画
        while kill -0 $pid 2>/dev/null; do
            i=$(( (i+1) %10 ))
            printf "\r${BLUE}[进行中]${NC} ${message} ${spin:$i:1}"
            sleep 0.1
        done
        # 清除整行
        printf "\r\033[K"
    else
        # 非交互式终端：静默等待进程结束
        while kill -0 $pid 2>/dev/null; do
            sleep 0.5
        done
    fi
}

# 查找并返回当前启动的模拟器 UDID
find_booted_simulator() {
    local booted_udid=$(xcrun simctl list devices | grep "(Booted)" | head -1 | grep -E -o "[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}")
    echo "$booted_udid"
}

# 查找并返回当前连接的真机信息
# 返回格式: "设备名称|UDID|DevicectlID"
find_connected_device() {
    # 使用 devicectl 查找第一个连接的 iPhone 设备 (查找 Model 列包含 iPhone 的设备)
    # 匹配状态为 connected 或 available 的 iPhone 设备
    local device_info=$(xcrun devicectl list devices 2>/dev/null | awk '/iPhone/ && (/connected/ || /available/) {print; exit}')

    if [ -z "$device_info" ]; then
        echo ""
        return
    fi

    local device_name=$(echo "$device_info" | awk '{print $1}')
    local devicectl_id=$(echo "$device_info" | awk '{print $3}')

    # 使用 xctrace 获取传统的 UDID（xcodebuild 需要）
    local device_udid=$(xcrun xctrace list devices 2>&1 | grep "$device_name" | grep -v "Simulator" | head -1 | grep -E -o '\([0-9A-F]{8}-[0-9A-F-]{15,}\)' | tr -d '()')

    echo "${device_name}|${device_udid}|${devicectl_id}"
}

# 安装并启动 App
# 参数: app_path device_udid device_name devicectl_id
install_and_launch_app() {
    local app_path="$1"
    local device_udid="$2"
    local device_name="$3"
    local devicectl_id="$4"

    # 从 Info.plist 中获取 Bundle ID
    local bundle_id=$(plutil -extract CFBundleIdentifier raw -o - "${app_path}/Info.plist" 2>/dev/null)

    if [ -z "$bundle_id" ]; then
        log_error "无法从 Info.plist 获取 Bundle ID"
        return 1
    fi

    log_info "准备安装和启动 App..."
    log_info "Bundle ID: ${bundle_id}"

    if [ "$DEVICE_TYPE" = "simulator" ]; then
        # 模拟器模式
        if [ -z "$device_udid" ]; then
            log_error "未找到正在运行的模拟器"
            log_info "请先启动一个模拟器，或使用 Xcode 打开模拟器"
            return 1
        fi

        log_info "安装目标模拟器: ${device_name} (${device_udid})"

        # 安装 App
        log_info "正在安装 App 到模拟器..."
        if xcrun simctl install "$device_udid" "$app_path" 2>&1; then
            log_success "App 安装成功"
        else
            log_error "App 安装失败"
            return 1
        fi

        # 启动 App
        log_info "正在启动 App..."
        if xcrun simctl launch "$device_udid" "$bundle_id" 2>&1; then
            log_success "App 启动成功"
        else
            log_error "App 启动失败"
            return 1
        fi

    else
        # 真机模式
        if [ -z "$device_udid" ]; then
            log_error "未找到连接的 iPhone 真机"
            log_info "请确保设备已连接并信任此电脑"
            return 1
        fi

        log_info "安装目标设备: ${device_name} (${device_udid})"

        if [ -z "$devicectl_id" ]; then
            log_error "无法获取设备的 devicectl identifier"
            log_info "请确保设备已连接并处于可用状态"
            return 1
        fi

        log_info "正在安装 App 到真机..."
        # 使用 xcrun devicectl 安装应用
        if xcrun devicectl device install app --device "$devicectl_id" "$app_path" 2>&1 | grep -v "^$"; then
            log_success "App 已安装到真机"

            # 获取 Bundle ID 并启动应用
            log_info "正在启动 App..."
            LAUNCH_OUTPUT=$(xcrun devicectl device process launch --device "$devicectl_id" "$bundle_id" 2>&1)
            LAUNCH_RESULT=$?

            if [ $LAUNCH_RESULT -eq 0 ]; then
                echo "$LAUNCH_OUTPUT" | grep -v "^$"
                log_success "App 启动成功"
            else
                # 检查是否是设备锁定导致的失败
                if echo "$LAUNCH_OUTPUT" | grep -q "Locked"; then
                    log_warning "设备已锁定，无法自动启动 App"
                    log_info "请解锁设备并手动启动 App"
                else
                    log_warning "App 安装成功，但启动失败（请手动启动）"
                fi
            fi
        else
            log_error "App 安装到真机失败"
            return 1
        fi
    fi

    return 0
}

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    -c, --clean             在构建前执行清理
    -r, --release           使用 Release 配置构建
    -a, --archive           创建归档并导出 .ipa (仅适用于真机)
    -i, --install           构建后自动安装并启动 App
    -d, --destination       指定目标设备: simulator 或 device (默认: simulator)
                            会自动确定构建目标和安装设备

示例:
    $0                              # 快速构建到模拟器
    $0 -c                           # 清理后构建
    $0 -r                           # Release 模式构建
    $0 -a                           # 创建归档并生成 .ipa
    $0 -i                           # 构建并安装到当前启动的模拟器
    $0 -i -d device                 # 构建并安装到连接的真机
    $0 -r -i -d device              # Release模式构建并安装到真机
    $0 -d device                    # 构建真机版本（不安装）

EOF
}

# 解析命令行参数
CLEAN_BUILD=false
CREATE_ARCHIVE=false
INSTALL_APP=false
DEVICE_TYPE="simulator"

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
        -r|--release)
            CONFIGURATION="Release"
            shift
            ;;
        -a|--archive)
            CREATE_ARCHIVE=true
            CONFIGURATION="Release"
            shift
            ;;
        -i|--install)
            INSTALL_APP=true
            shift
            ;;
        -d|--destination)
            DEVICE_TYPE="$2"
            if [ "$DEVICE_TYPE" != "simulator" ] && [ "$DEVICE_TYPE" != "device" ]; then
                log_error "无效的目标设备: $DEVICE_TYPE (必须是 simulator 或 device)"
                exit 1
            fi
            shift 2
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 根据 device-type 自动设置 DESTINATION
if [ "$DEVICE_TYPE" = "simulator" ]; then
    # 模拟器模式：尝试使用当前运行的模拟器，否则使用默认
    DEVICE_UDID=$(find_booted_simulator)
    if [ -n "$DEVICE_UDID" ]; then
        DEVICE_NAME=$(xcrun simctl list devices | grep "$DEVICE_UDID" | sed -E 's/^[[:space:]]*([^(]+).*/\1/' | xargs)
        DESTINATION="platform=iOS Simulator,id=${DEVICE_UDID}"
        log_info "检测到运行中的模拟器: ${DEVICE_NAME}"
    else
        # 使用默认模拟器
        DEVICE_UDID=""
        DEVICE_NAME="iPhone 17 Pro"
        DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
        log_warning "未检测到运行中的模拟器，使用默认: iPhone 17 Pro"
    fi
else
    # 真机模式
    DEVICE_INFO=$(find_connected_device)
    if [ -n "$DEVICE_INFO" ]; then
        DEVICE_NAME=$(echo "$DEVICE_INFO" | cut -d'|' -f1)
        DEVICE_UDID=$(echo "$DEVICE_INFO" | cut -d'|' -f2)
        DEVICECTL_ID=$(echo "$DEVICE_INFO" | cut -d'|' -f3)

        if [ -z "$DEVICE_UDID" ]; then
            log_error "无法获取设备 UDID"
            log_info "请确保设备已连接并信任此电脑"
            exit 1
        fi

        DESTINATION="platform=iOS,id=${DEVICE_UDID}"
        log_info "检测到连接的设备: ${DEVICE_NAME} (${DEVICE_UDID})"
    else
        log_error "未检测到连接的 iPhone 设备"
        log_info "请确保设备已连接并信任此电脑"
        exit 1
    fi
fi

# 打印配置信息
log_info "构建配置:"
echo "  项目: ${SCHEME}"
echo "  配置: ${CONFIGURATION}"
echo "  目标设备: ${DEVICE_TYPE}"
echo "  构建目标: ${DESTINATION}"
echo "  清理: ${CLEAN_BUILD}"
echo "  自动安装: ${INSTALL_APP}"
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

# 生成带时间戳的日志文件名
BUILD_LOG_FILE="${BUILD_DIR}/xcodebuild_$(date +%Y%m%d_%H%M%S).log"

# 开始计时
START_TIME=$(date +%s)

# 清理构建（如果需要）
if [ "$CLEAN_BUILD" = true ]; then
    echo "=== 清理构建 ===" >> "${BUILD_LOG_FILE}"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${BUILD_LOG_FILE}"
    echo "" >> "${BUILD_LOG_FILE}"

    xcodebuild -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -destination "${DESTINATION}" \
               -configuration "${CONFIGURATION}" \
               clean >> "${BUILD_LOG_FILE}" 2>&1 &

    show_progress $! "清理构建缓存"
    set +e  # 临时禁用 errexit
    wait $!
    CLEAN_RESULT=$?
    set -e  # 重新启用 errexit

    if [ $CLEAN_RESULT -ne 0 ]; then
        log_warning "清理命令执行有警告，继续构建..."
    else
        # 清理本地 build 目录（保留日志文件）
        if [ -d "${BUILD_DIR}" ]; then
            # 临时保存日志文件
            TMP_LOG=$(mktemp)
            cp "${BUILD_LOG_FILE}" "${TMP_LOG}"

            rm -rf "${BUILD_DIR}"
            mkdir -p "${BUILD_DIR}"

            # 恢复日志文件
            mv "${TMP_LOG}" "${BUILD_LOG_FILE}"
        fi

        log_success "清理完成"
    fi
fi

# 构建项目
if [ "$CREATE_ARCHIVE" = true ]; then
    log_info "开始归档..."
    echo ""

    ARCHIVE_PATH="${BUILD_DIR}/ThriveBody.xcarchive"
    EXPORT_PATH="${BUILD_DIR}"

    # 创建归档
    echo "=== 开始归档 ===" >> "${BUILD_LOG_FILE}"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${BUILD_LOG_FILE}"
    echo "配置: ${CONFIGURATION}" >> "${BUILD_LOG_FILE}"
    echo "" >> "${BUILD_LOG_FILE}"

    xcodebuild archive \
               -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -configuration "${CONFIGURATION}" \
               -allowProvisioningUpdates \
               -archivePath "${ARCHIVE_PATH}" >> "${BUILD_LOG_FILE}" 2>&1 &

    show_progress $! "正在归档"
    set +e  # 临时禁用 errexit
    wait $!
    BUILD_RESULT=$?
    set -e  # 重新启用 errexit

    if [ $BUILD_RESULT -ne 0 ]; then
        log_error "归档失败，完整错误日志: ${BUILD_LOG_FILE}"
        echo ""
        log_info "最近的错误信息:"
        tail -20 "${BUILD_LOG_FILE}" | grep -i "error:" || tail -10 "${BUILD_LOG_FILE}"
    else
        log_success "归档完成"
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

            echo "" >> "${BUILD_LOG_FILE}"
            echo "=== 导出 IPA ===" >> "${BUILD_LOG_FILE}"
            echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${BUILD_LOG_FILE}"
            echo "" >> "${BUILD_LOG_FILE}"

            xcodebuild -exportArchive \
                       -archivePath "${ARCHIVE_PATH}" \
                       -exportPath "${EXPORT_PATH}" \
                       -exportOptionsPlist "${EXPORT_OPTIONS}" >> "${BUILD_LOG_FILE}" 2>&1 &

            show_progress $! "正在导出 IPA"
            set +e  # 临时禁用 errexit
            wait $!
            EXPORT_RESULT=$?
            set -e  # 重新启用 errexit

            if [ $EXPORT_RESULT -eq 0 ]; then
                log_success "IPA 导出成功"
            else
                log_error "IPA 导出失败"
                log_info "查看详细错误: ${BUILD_LOG_FILE}"
            fi
        fi
    fi
else
    # 设置自定义构建路径
    SYMROOT="${BUILD_DIR}"
    DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"

    # 写入构建日志头部
    echo "=== 开始构建 ===" >> "${BUILD_LOG_FILE}"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "${BUILD_LOG_FILE}"
    echo "配置: ${CONFIGURATION}" >> "${BUILD_LOG_FILE}"
    echo "目标: ${DESTINATION}" >> "${BUILD_LOG_FILE}"
    echo "" >> "${BUILD_LOG_FILE}"

    # 后台执行构建，前台显示进度
    xcodebuild -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -destination "${DESTINATION}" \
               -configuration "${CONFIGURATION}" \
               -allowProvisioningUpdates \
               SYMROOT="${SYMROOT}" \
               OBJROOT="${DERIVED_DATA_PATH}" \
               build >> "${BUILD_LOG_FILE}" 2>&1 &

    show_progress $! "正在构建"
    set +e  # 临时禁用 errexit
    wait $!
    BUILD_RESULT=$?
    set -e  # 重新启用 errexit

    # 如果构建失败，提示查看日志文件
    if [ $BUILD_RESULT -ne 0 ]; then
        log_error "构建失败，完整错误日志: ${BUILD_LOG_FILE}"
        echo ""
        log_info "最近的错误信息:"
        tail -20 "${BUILD_LOG_FILE}" | grep -i "error:" || tail -10 "${BUILD_LOG_FILE}"
    else
        log_success "构建完成"
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
    log_info "构建日志: ${BUILD_LOG_FILE}"

    # 显示输出路径
    if [ "$CREATE_ARCHIVE" = true ]; then
        # 归档模式
        if [ -d "${ARCHIVE_PATH}" ]; then
            ARCHIVE_SIZE=$(du -sh "${ARCHIVE_PATH}" | cut -f1)
            log_info "归档大小: ${ARCHIVE_SIZE}"
            log_info "归档路径: ${ARCHIVE_PATH}"
        fi

        IPA_FILE="${EXPORT_PATH}/ThriveBody.ipa"
        if [ -f "${IPA_FILE}" ]; then
            IPA_SIZE=$(du -sh "${IPA_FILE}" | cut -f1)
            log_info "IPA 大小: ${IPA_SIZE}"
            log_info "IPA 路径: ${IPA_FILE}"
        fi
    else
        # 普通构建模式
        if [ "$DEVICE_TYPE" = "simulator" ]; then
            APP_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/ThriveBody.app"
        else
            APP_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos/ThriveBody.app"
        fi

        if [ -d "${APP_PATH}" ]; then
            APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
            log_info "App 大小: ${APP_SIZE}"
            log_info "App 路径: ${APP_PATH}"
        else
            # 尝试查找 .app 文件
            APP_PATH=$(find "${BUILD_DIR}" -name "ThriveBody.app" -type d | head -1)
            if [ -n "${APP_PATH}" ]; then
                APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
                log_info "App 大小: ${APP_SIZE}"
                log_info "App 路径: ${APP_PATH}"
            fi
        fi

        # 如果需要安装和启动 App
        if [ "$INSTALL_APP" = true ] && [ -n "${APP_PATH}" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            # 模拟器模式下 DEVICECTL_ID 为空，真机模式下传递
            if install_and_launch_app "${APP_PATH}" "${DEVICE_UDID}" "${DEVICE_NAME}" "${DEVICECTL_ID:-}"; then
                log_success "App 已成功安装并启动！"
            else
                log_warning "App 构建成功，但安装/启动失败"
            fi
        fi
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    log_error "构建失败！ ❌"
    log_info "构建时间: ${MINUTES}分${SECONDS}秒"
    log_info "完整日志: ${BUILD_LOG_FILE}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "提示: 查看日志文件获取详细错误信息"
    exit 1
fi
