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
