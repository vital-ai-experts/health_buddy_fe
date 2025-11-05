#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
APP_DIR="${REPO_ROOT}/App"
SPEC_PATH="${REPO_ROOT}/project.yml"
# 读取项目名以决定生成的 .xcodeproj 名称
PROJECT_NAME=$(awk -F': ' '/^name:/ {print $2; exit}' "${SPEC_PATH}")
APP_PROJECT_PATH="${REPO_ROOT}/${PROJECT_NAME}.xcodeproj"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "[错误] 未检测到 XcodeGen。请先安装: brew install xcodegen" >&2
  exit 1
fi

echo "[信息] 使用规范: ${SPEC_PATH}"
echo "[信息] 目标输出: ${APP_PROJECT_PATH}"

pushd "${REPO_ROOT}" >/dev/null
xcodegen generate --spec "${SPEC_PATH}"
popd >/dev/null

echo "[完成] Xcode 工程已生成到: ${APP_PROJECT_PATH}"

