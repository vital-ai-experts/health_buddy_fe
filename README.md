# Health AI Frontend

Health AI 的所有客户端（iOS、Android、Web）都收敛在这个 monorepo。开始任何工作前请先阅读根目录和目标平台目录下的 `AGENTS.md`。

## 目录导航
- `AGENTS.md`：跨平台通用的协作与提交流程说明。
- `ios/`：当前唯一的活跃实现 **ThriveBody**。进入后请依次阅读：
  - `ios/AGENTS.md`：开发流程、模块边界、脚本与测试要求。
  - `ios/README.md`：项目概览、环境要求、脚本示例。
  - `ios/modularization.md`：分层架构与模块命名规范。
  - `ios/scripts/`：`build.sh`、`generate_project.sh` 等工具脚本。
- `android/`：预留目录。
- `web/`：预留目录。

如在文档或脚本中发现缺口，请先更新对应的 `AGENTS.md`/README，保持信息同步，再继续开发。
