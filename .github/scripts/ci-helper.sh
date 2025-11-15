#!/usr/bin/env bash
set -euo pipefail

# GitHub CI 辅助脚本
# 用于触发构建、查看状态、下载日志和产物

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 gh CLI 是否已安装
check_gh_cli() {
    if ! command -v gh >/dev/null 2>&1; then
        log_error "GitHub CLI (gh) 未安装"
        log_info "请访问 https://cli.github.com/ 安装 gh CLI"
        log_info "或使用 Homebrew: brew install gh"
        exit 1
    fi

    # 检查是否已登录
    if ! gh auth status >/dev/null 2>&1; then
        log_error "GitHub CLI 未登录"
        log_info "请运行: gh auth login"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
GitHub CI 辅助脚本 - iOS 项目构建管理

用法: $0 <命令> [选项]

命令:
    trigger         触发新的构建
    status          查看最新构建状态
    list            列出最近的构建记录
    logs            下载构建日志
    download        下载构建产物
    watch           实时监控构建状态
    cancel          取消正在运行的构建

触发构建选项:
    $0 trigger [选项]
        -c, --config <Debug|Release>     构建配置 (默认: Debug)
        -t, --type <simulator|archive>   构建类型 (默认: simulator)
        --clean                          清理构建
        -b, --branch <branch>            指定分支 (默认: 当前分支)
        -w, --workflow <name>            工作流名称 (默认: manual-build.yml)

下载日志选项:
    $0 logs [选项]
        -r, --run <run-id>               指定 run ID (默认: 最新)
        -o, --output <dir>               输出目录 (默认: ./ci-logs)

下载产物选项:
    $0 download [选项]
        -r, --run <run-id>               指定 run ID (默认: 最新)
        -o, --output <dir>               输出目录 (默认: ./ci-artifacts)
        -n, --name <artifact-name>       只下载指定的 artifact

示例:
    # 触发 Debug 模拟器构建
    $0 trigger

    # 触发 Release 归档构建
    $0 trigger -c Release -t archive

    # 触发清理构建
    $0 trigger --clean -c Release

    # 查看最新构建状态
    $0 status

    # 列出最近 5 次构建
    $0 list

    # 下载最新构建的日志
    $0 logs

    # 下载指定构建的产物
    $0 download -r 123456

    # 实时监控构建
    $0 watch

EOF
}

# 触发构建
trigger_build() {
    local config="Debug"
    local build_type="simulator"
    local clean_build="false"
    local branch=""
    local workflow="manual-build.yml"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                config="$2"
                shift 2
                ;;
            -t|--type)
                build_type="$2"
                shift 2
                ;;
            --clean)
                clean_build="true"
                shift
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -w|--workflow)
                workflow="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                return 1
                ;;
        esac
    done

    # 如果未指定分支,使用当前分支
    if [ -z "$branch" ]; then
        branch=$(git rev-parse --abbrev-ref HEAD)
    fi

    log_info "触发构建..."
    log_info "  工作流: $workflow"
    log_info "  分支: $branch"
    log_info "  配置: $config"
    log_info "  类型: $build_type"
    log_info "  清理: $clean_build"

    # 触发工作流
    gh workflow run "$workflow" \
        --ref "$branch" \
        -f configuration="$config" \
        -f build_type="$build_type" \
        -f clean_build="$clean_build" \
        -f upload_ipa="true"

    if [ $? -eq 0 ]; then
        log_success "构建已触发"
        log_info "等待工作流启动..."
        sleep 3

        # 获取最新的 run
        local run_id=$(gh run list --workflow="$workflow" --limit 1 --json databaseId --jq '.[0].databaseId')
        log_info "Run ID: $run_id"
        log_info "查看状态: gh run view $run_id"
        log_info "查看网页: gh run view $run_id --web"
    else
        log_error "触发构建失败"
        return 1
    fi
}

# 查看构建状态
show_status() {
    log_info "获取最新构建状态..."

    gh run list --limit 5 --json databaseId,status,conclusion,createdAt,headBranch,displayTitle \
        --jq '.[] | "ID: \(.databaseId) | \(.status) | \(.conclusion // "pending") | \(.headBranch) | \(.displayTitle)"' | \
        while read -r line; do
            echo "$line"
        done
}

# 列出构建记录
list_runs() {
    log_info "最近的构建记录:"
    echo ""

    gh run list --limit 10
}

# 下载日志
download_logs() {
    local run_id=""
    local output_dir="./ci-logs"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--run)
                run_id="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                return 1
                ;;
        esac
    done

    # 如果未指定 run_id,获取最新的
    if [ -z "$run_id" ]; then
        run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
        log_info "使用最新的 Run ID: $run_id"
    fi

    # 创建输出目录
    mkdir -p "$output_dir"

    log_info "下载构建日志..."
    log_info "  Run ID: $run_id"
    log_info "  输出目录: $output_dir"

    # 下载日志 artifact
    gh run download "$run_id" -p "*build-logs*" -D "$output_dir"

    if [ $? -eq 0 ]; then
        log_success "日志下载完成: $output_dir"

        # 查找并显示构建报告
        if find "$output_dir" -name "build-report.md" -type f | head -1 | xargs -I {} cat {}; then
            echo ""
            log_info "构建报告已保存在上述目录中"
        fi
    else
        log_error "日志下载失败"
        return 1
    fi
}

# 下载产物
download_artifacts() {
    local run_id=""
    local output_dir="./ci-artifacts"
    local artifact_name=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--run)
                run_id="$2"
                shift 2
                ;;
            -o|--output)
                output_dir="$2"
                shift 2
                ;;
            -n|--name)
                artifact_name="$2"
                shift 2
                ;;
            *)
                log_error "未知参数: $1"
                return 1
                ;;
        esac
    done

    # 如果未指定 run_id,获取最新的
    if [ -z "$run_id" ]; then
        run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
        log_info "使用最新的 Run ID: $run_id"
    fi

    # 创建输出目录
    mkdir -p "$output_dir"

    log_info "下载构建产物..."
    log_info "  Run ID: $run_id"
    log_info "  输出目录: $output_dir"

    # 下载产物
    if [ -n "$artifact_name" ]; then
        gh run download "$run_id" -n "$artifact_name" -D "$output_dir"
    else
        gh run download "$run_id" -D "$output_dir"
    fi

    if [ $? -eq 0 ]; then
        log_success "产物下载完成: $output_dir"

        # 显示下载的文件
        log_info "下载的文件:"
        find "$output_dir" -type f | while read -r file; do
            size=$(du -sh "$file" | cut -f1)
            echo "  - $(basename "$file") ($size)"
        done
    else
        log_error "产物下载失败"
        return 1
    fi
}

# 实时监控构建
watch_build() {
    log_info "监控最新构建..."

    # 获取最新的 run ID
    local run_id=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')

    log_info "Run ID: $run_id"
    log_info "按 Ctrl+C 停止监控"
    echo ""

    gh run watch "$run_id"
}

# 取消构建
cancel_build() {
    log_info "获取正在运行的构建..."

    # 获取正在运行的 run
    local run_id=$(gh run list --limit 1 --json databaseId,status --jq '.[] | select(.status == "in_progress") | .databaseId')

    if [ -z "$run_id" ]; then
        log_warning "没有正在运行的构建"
        return 0
    fi

    log_warning "取消构建 Run ID: $run_id"
    read -p "确认取消? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh run cancel "$run_id"
        log_success "构建已取消"
    else
        log_info "已取消操作"
    fi
}

# 主函数
main() {
    # 检查 gh CLI
    check_gh_cli

    # 如果没有参数,显示帮助
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # 解析命令
    local command="$1"
    shift

    case $command in
        trigger)
            trigger_build "$@"
            ;;
        status)
            show_status
            ;;
        list)
            list_runs
            ;;
        logs)
            download_logs "$@"
            ;;
        download)
            download_artifacts "$@"
            ;;
        watch)
            watch_build
            ;;
        cancel)
            cancel_build
            ;;
        -h|--help)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
