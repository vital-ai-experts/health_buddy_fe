# Health AI Frontend – Agent Guide

This monorepo hosts every client surface for the Health AI experience. The root `AGENTS.md` is intentionally short; it only explains how to navigate the repo and how platform docs should be organized.

## Repository Layout
- `ios/` – ThriveBody iOS client. **Only active implementation right now.** Enter this directory and read `ios/AGENTS.md` plus the companion docs before touching any files.
- `android/` – Reserved for the future Android build. Keep it empty (or stubbed) until we spin up the platform-specific guide.
- `web/` – Reserved for future web clients. Same rule: no work without a local `AGENTS.md`.

## Workflow for Any Agent
1. Start at the repo root, pick the target platform directory, and immediately switch into it.
2. Read the platform’s own `AGENTS.md`, README, and scripts. Those files define tooling, build steps, and coding conventions that may differ across platforms.
3. Only edit files inside the chosen platform unless the platform guide explicitly tells you otherwise.
4. Surface blockers (missing tooling, unclear steps) by updating the platform docs instead of overloading this root file.

**Collaboration checklist**
- Read each module’s `README.md`, `AGENTS.md`, and adjacent docs first to understand its stack, conventions, and scripts.
- Think through architecture before coding:
  1. List every change the feature requires and decide which layer/module owns it.
  2. Judge whether an existing module can host the work or if you need to create a new one.
  3. Design clean, minimal interfaces for any module that exposes functionality to others.
- Validate changes whenever possible:
  1. Server-side work needs complete endpoint tests that pass.
  2. Web work needs a real browser verification run.
  3. Client work must at least compile successfully (e.g., GitHub CI green).
- Maintain documentation continuously:
  1. After each task, capture blockers caused by outdated docs and update them immediately.
  2. Keep project-wide docs at the root and module docs inside their respective module directories.
  3. Keep every doc concise and focused on critical information.

## CI Status Monitoring (for AI Agents in Sandboxed Environments)

**IMPORTANT**: If you are running in a sandboxed environment (Codex, Claude Code web sandbox, or similar CI/CD environment), you MUST follow this workflow after creating a Pull Request:

### Required Post-PR Workflow

1. **Check CI Status Immediately After Creating PR**:
   ```bash
   .github/check_ci_status.sh
   ```

   This script will:
   - Detect the current branch automatically
   - Query the latest CI workflow run status
   - Wait if CI is in progress (up to 30 minutes)
   - Print detailed failure logs if CI fails

2. **Fix Compilation Issues if CI Fails**:
   - The script automatically fetches and displays failure logs
   - Analyze the compilation errors from the logs
   - Make necessary code fixes
   - Commit and push the fixes
   - Re-run the CI status check to verify

3. **Iterative Fix Process**:
   ```bash
   # After fixing issues
   git add .
   git commit -m "fix: resolve CI compilation errors"
   git push

   # Check CI status again
   .github/check_ci_status.sh
   ```

### CI Status Check Script Usage

The `.github/check_ci_status.sh` script provides:
- ✅ Automatic branch detection
- ✅ Real-time CI status monitoring
- ✅ Auto-wait for in-progress CI runs
- ✅ Detailed failure log retrieval
- ✅ Color-coded output for easy reading

**Example Usage**:
```bash
# Basic check
.github/check_ci_status.sh

# Automated workflow
git push && .github/check_ci_status.sh
```

**Exit Codes**:
- `0` - CI passed or no CI runs found
- `1` - CI failed, cancelled, or timed out

### Why This Matters in Sandboxed Environments

In sandboxed environments like Codex or Claude Code web:
- You cannot manually test builds locally
- CI is the only validation mechanism
- Compilation errors must be caught and fixed via CI feedback
- The automated CI check ensures no broken code is merged

### Complete PR Workflow for Sandboxed Environments

```bash
# 1. Create your changes
# ... make code changes ...

# 2. Commit and push
git add .
git commit -m "feat: add new feature"
git push

# 3. Create PR (via GitHub web or CLI)
# ... create PR ...

# 4. IMMEDIATELY check CI status
.github/check_ci_status.sh

# 5. If CI fails, fix and repeat
# ... fix issues based on logs ...
git add .
git commit -m "fix: resolve CI errors"
git push
.github/check_ci_status.sh

# 6. Only merge when CI passes
```

**Required Environment Variables**:
- `GITHUB_CI_TOKEN` - GitHub Personal Access Token with `repo` and `actions` permissions

For more details on the CI status check script, see `.github/README.md`.


## Work with user
Remember! Answer in Chinese! 