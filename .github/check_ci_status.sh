#!/bin/bash

# CI 状态检查脚本
# 用于检查当前分支的 GitHub Actions CI 状态
# 如果 CI 正在运行，则等待完成
# 如果 CI 失败，则打印失败日志

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查必需的环境变量
if [ -z "$GITHUB_CI_TOKEN" ]; then
    echo -e "${RED}错误: GITHUB_CI_TOKEN 环境变量未设置${NC}"
    exit 1
fi

# 去除 token 两端的引号（如果有）
GITHUB_CI_TOKEN=$(echo "$GITHUB_CI_TOKEN" | tr -d '"')

# 获取仓库信息
REPO_OWNER="vital-ai-experts"
REPO_NAME="health_buddy_fe"

# 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}当前分支: ${CURRENT_BRANCH}${NC}"

# GitHub API 基础 URL
API_BASE="https://api.github.com"

# 检查等待时间（秒）
CHECK_INTERVAL=10
MAX_WAIT_TIME=1800  # 最多等待 30 分钟

# 函数：调用 GitHub API
call_github_api() {
    local endpoint=$1
    curl -s -H "Authorization: token ${GITHUB_CI_TOKEN}" \
         -H "Accept: application/vnd.github.v3+json" \
         "${API_BASE}${endpoint}"
}

# 函数：获取最新的 workflow run
get_latest_workflow_run() {
    local branch=$1
    call_github_api "/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs?branch=${branch}&per_page=1"
}

# 函数：获取 workflow run 详情
get_workflow_run_details() {
    local run_id=$1
    call_github_api "/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${run_id}"
}

# 函数：获取 workflow run 的 jobs
get_workflow_jobs() {
    local run_id=$1
    call_github_api "/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${run_id}/jobs"
}

# 函数：获取 job 日志
get_job_logs() {
    local job_id=$1
    curl -s -L -H "Authorization: token ${GITHUB_CI_TOKEN}" \
         -H "Accept: application/vnd.github.v3+json" \
         "${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/actions/jobs/${job_id}/logs"
}

# 函数：获取 workflow run 的 artifacts
get_workflow_artifacts() {
    local run_id=$1
    call_github_api "/repos/${REPO_OWNER}/${REPO_NAME}/actions/runs/${run_id}/artifacts"
}

# 函数：下载 artifact
download_artifact() {
    local artifact_id=$1
    local output_file=$2

    echo -e "${BLUE}正在下载 artifact (ID: ${artifact_id})...${NC}"

    # 获取 artifact 下载 URL
    local download_url="${API_BASE}/repos/${REPO_OWNER}/${REPO_NAME}/actions/artifacts/${artifact_id}/zip"

    # 下载 artifact
    curl -L -H "Authorization: token ${GITHUB_CI_TOKEN}" \
         -H "Accept: application/vnd.github.v3+json" \
         "${download_url}" -o "${output_file}"

    if [ -f "${output_file}" ]; then
        echo -e "${GREEN}✓ Artifact 下载成功: ${output_file}${NC}"
        return 0
    else
        echo -e "${RED}✗ Artifact 下载失败${NC}"
        return 1
    fi
}

# 函数：解压缩并打印编译日志
extract_and_print_logs() {
    local zip_file=$1
    local temp_dir=$(mktemp -d)

    echo -e "${BLUE}正在解压缩 artifact...${NC}"

    # 解压缩到临时目录
    unzip -q "${zip_file}" -d "${temp_dir}"

    # 查找所有 .log 文件
    local log_files=$(find "${temp_dir}" -name "*.log" -type f)

    if [ -z "$log_files" ]; then
        echo -e "${YELLOW}未找到日志文件${NC}"
        rm -rf "${temp_dir}"
        return 1
    fi

    # 打印每个日志文件
    echo "$log_files" | while read -r log_file; do
        local log_name=$(basename "$log_file")
        echo -e "\n${YELLOW}==================================================${NC}"
        echo -e "${YELLOW}编译日志: ${log_name}${NC}"
        echo -e "${YELLOW}==================================================${NC}"

        # 检查日志文件大小
        local file_size=$(wc -l < "$log_file")

        if [ "$file_size" -gt 500 ]; then
            echo -e "${BLUE}日志文件较大 (${file_size} 行)，只显示包含错误和警告的部分...${NC}\n"

            # 首先尝试提取错误信息（grep 无匹配时返回 1，需要 || true 避免触发 set -e）
            local error_lines=$(grep -i -E "error|失败|fail|❌" "$log_file" | tail -n 100 || true)

            if [ -n "$error_lines" ]; then
                echo -e "${RED}=== 错误信息 ===${NC}"
                echo "$error_lines"
                echo ""
            fi

            # 然后提取警告信息（限制数量）
            local warning_lines=$(grep -i -E "warning|warn|⚠" "$log_file" | tail -n 50 || true)

            if [ -n "$warning_lines" ]; then
                echo -e "${YELLOW}=== 警告信息 (最后50条) ===${NC}"
                echo "$warning_lines"
                echo ""
            fi

            # 最后显示日志的最后部分
            echo -e "${BLUE}=== 日志末尾 (最后100行) ===${NC}"
            tail -n 100 "$log_file"
        else
            # 如果文件不大，直接显示全部内容
            cat "$log_file"
        fi

        echo -e "${YELLOW}==================================================${NC}"
    done

    # 清理临时目录
    rm -rf "${temp_dir}"
    rm -f "${zip_file}"

    return 0
}

# 函数：打印失败的 job 日志
print_failed_job_logs() {
    local run_id=$1

    echo -e "${RED}==================================================${NC}"
    echo -e "${RED}CI 失败 - 获取失败日志${NC}"
    echo -e "${RED}==================================================${NC}"

    jobs_response=$(get_workflow_jobs "$run_id")

    # 解析并打印每个失败的 job
    echo "$jobs_response" | jq -r '.jobs[] | select(.conclusion == "failure") | @json' | while read -r job; do
        job_name=$(echo "$job" | jq -r '.name')
        job_id=$(echo "$job" | jq -r '.id')

        echo -e "\n${RED}失败的 Job: ${job_name} (ID: ${job_id})${NC}"
        echo -e "${YELLOW}--------------------------------------------------${NC}"

        # 获取并打印日志
        logs=$(get_job_logs "$job_id")

        # 打印日志（只打印最后 200 行，避免输出过多）
        echo "$logs" | tail -n 200
        echo -e "${YELLOW}--------------------------------------------------${NC}"
    done

    # 尝试下载并解析 artifacts 中的编译日志
    echo -e "\n${BLUE}==================================================${NC}"
    echo -e "${BLUE}检查是否有编译日志 artifacts...${NC}"
    echo -e "${BLUE}==================================================${NC}"

    artifacts_response=$(get_workflow_artifacts "$run_id")
    total_artifacts=$(echo "$artifacts_response" | jq -r '.total_count')

    if [ "$total_artifacts" -eq 0 ]; then
        echo -e "${YELLOW}未找到 artifacts${NC}"
        return
    fi

    echo -e "${BLUE}找到 ${total_artifacts} 个 artifact(s)${NC}"

    # 查找 build-artifacts
    echo "$artifacts_response" | jq -r '.artifacts[] | @json' | while read -r artifact; do
        artifact_name=$(echo "$artifact" | jq -r '.name')
        artifact_id=$(echo "$artifact" | jq -r '.id')
        artifact_size=$(echo "$artifact" | jq -r '.size_in_bytes')

        echo -e "\n${BLUE}找到 Artifact: ${artifact_name} (ID: ${artifact_id}, 大小: ${artifact_size} bytes)${NC}"

        # 如果是 build-artifacts，下载并解析
        if [[ "$artifact_name" == "build-artifacts" ]] || [[ "$artifact_name" == *"build"* ]]; then
            local temp_zip="/tmp/artifact_${artifact_id}.zip"

            if download_artifact "$artifact_id" "$temp_zip"; then
                extract_and_print_logs "$temp_zip"
            else
                echo -e "${RED}无法下载 artifact${NC}"
            fi
        else
            echo -e "${YELLOW}跳过非编译日志 artifact: ${artifact_name}${NC}"
        fi
    done
}

# 主逻辑
echo -e "${BLUE}正在检查 ${CURRENT_BRANCH} 分支的 CI 状态...${NC}"

# 获取最新的 workflow run
workflow_runs=$(get_latest_workflow_run "$CURRENT_BRANCH")

# 检查是否有 workflow runs
total_count=$(echo "$workflow_runs" | jq -r '.total_count')

if [ "$total_count" -eq 0 ]; then
    echo -e "${YELLOW}当前分支没有 CI workflow runs${NC}"
    exit 0
fi

# 获取最新的 run ID 和状态
run_id=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].id')
run_status=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].status')
run_conclusion=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].conclusion')
workflow_name=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].name')
html_url=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].html_url')

echo -e "${BLUE}找到 Workflow Run:${NC}"
echo -e "  Workflow: ${workflow_name}"
echo -e "  Run ID: ${run_id}"
echo -e "  URL: ${html_url}"
echo -e "  状态: ${run_status}"
echo -e "  结论: ${run_conclusion}"

# 如果 CI 正在运行，等待完成
waited_time=0
while [ "$run_status" == "queued" ] || [ "$run_status" == "in_progress" ]; do
    echo -e "${YELLOW}CI 正在运行中... (已等待 ${waited_time} 秒)${NC}"

    if [ $waited_time -ge $MAX_WAIT_TIME ]; then
        echo -e "${RED}等待超时 (${MAX_WAIT_TIME} 秒)${NC}"
        exit 1
    fi

    sleep $CHECK_INTERVAL
    waited_time=$((waited_time + CHECK_INTERVAL))

    # 重新获取状态
    run_details=$(get_workflow_run_details "$run_id")
    run_status=$(echo "$run_details" | jq -r '.status')
    run_conclusion=$(echo "$run_details" | jq -r '.conclusion')
done

# 检查最终结果
echo -e "\n${BLUE}CI 已完成${NC}"
echo -e "  最终状态: ${run_status}"
echo -e "  结论: ${run_conclusion}"

if [ "$run_conclusion" == "success" ]; then
    echo -e "${GREEN}✓ CI 通过！${NC}"
    exit 0
elif [ "$run_conclusion" == "failure" ]; then
    echo -e "${RED}✗ CI 失败！${NC}"
    print_failed_job_logs "$run_id"
    exit 1
elif [ "$run_conclusion" == "cancelled" ]; then
    echo -e "${YELLOW}⚠ CI 被取消${NC}"
    exit 1
else
    echo -e "${YELLOW}⚠ CI 状态未知: ${run_conclusion}${NC}"
    exit 1
fi
