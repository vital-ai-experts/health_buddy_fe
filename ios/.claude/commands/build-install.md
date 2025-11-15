# Build and Install Command

You are helping the user build and install the HealthBuddy iOS app.

## Parameter Parsing

Parse the user's input intelligently to determine build options. Users may provide arguments in various formats:
- `/build-install` -> Default: `scripts/build.sh -i`
- `/build-install device` -> `scripts/build.sh -i -d device`
- `/build-install install device` -> `scripts/build.sh -i -d device`
- `/build-install release device` -> `scripts/build.sh -r -i -d device`
- `/build-install archive` -> `scripts/build.sh -a`
- `/build-install clean` -> `scripts/build.sh -c`
- `/build-install release archive` -> `scripts/build.sh -r -a`

### Keyword Detection Rules

**Installation flag (-i)**:
- Keywords: `install`, `i`, `安装`, `启动`, `run`, `launch`
- Default: ENABLED (always install unless only building)

**Destination (-d)**:
- Keywords for `device`: `device`, `真机`, `physical`, `iphone`, `手机`
- Keywords for `simulator`: `simulator`, `sim`, `模拟器`, `仿真器`
- Default: `simulator`

**Configuration (-r)**:
- Keywords for `release`: `release`, `r`, `发布`, `production`, `prod`
- Keywords for `debug`: `debug`, `开发`, `dev`, `development`
- Default: `debug`

**Archive (-a)**:
- Keywords: `archive`, `a`, `归档`, `ipa`, `打包`, `package`
- Note: If archive is detected, do NOT add -i flag

**Clean (-c)**:
- Keywords: `clean`, `c`, `清理`, `清除`

## Execution Logic

1. **Parse the command arguments** from the user input after `/build-install`
2. **Build the command** based on detected keywords and defaults:
   ```
   scripts/build.sh [options]

   Where options are:
   -i (if not archive mode)
   -d device|simulator (default: simulator)
   -r (if release keyword detected)
   -a (if archive keyword detected)
   -c (if clean keyword detected)
   ```
3. **Execute the build command with auto-fix loop**:
   - Run `scripts/build.sh` with the determined options
   - If build fails:
     - Read and analyze the build log to identify compilation errors
     - Extract specific error messages (Swift errors, missing imports, type errors, etc.)
     - Use available tools (Edit, Write) to fix the identified errors
     - Re-run the build command

4. **Report results**:
   - Mention the command that was executed
   - Report success/failure
   - If auto-fixes were applied, summarize what was fixed
   - Point to log file location if needed

## Examples

```bash
# User: /build-install
# Execute: scripts/build.sh -i
# (Default: Debug, Simulator, Install)

# User: /build-install device
# Execute: scripts/build.sh -i -d device
# (Debug to physical device with install)

# User: /build-install release device
# Execute: scripts/build.sh -r -i -d device
# (Release to physical device with install)

# User: /build-install archive
# Execute: scripts/build.sh -a
# (Debug archive, no install)

# User: /build-install release archive
# Execute: scripts/build.sh -r -a
# (Release archive for App Store)

# User: /build-install clean device
# Execute: scripts/build.sh -c -i -d device
# (Clean build to device)
```

## Important Notes

- Always use defaults from build.sh script (Debug, Simulator, Install)
- Do NOT ask the user for options - parse from their input or use defaults
- Build logs are automatically saved to `build/xcodebuild_YYYYMMDD_HHMMSS.log`
- Archive creates .ipa at `build/HealthBuddy.ipa`
- The script auto-detects running simulator or connected device
- Device must be unlocked for app launch

## After Execution

Briefly report:
- What command was executed
- Build result (success/failure)
- Number of auto-fix attempts made (if any)
- Summary of fixes applied (if any)
- Where the app was installed (simulator/device)
- Log file path if build failed
