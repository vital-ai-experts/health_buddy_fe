# iOS 代码签名和 Provisioning Profile 配置指南

## 当前构建脚本的签名方案

### 📊 现状分析

#### Simulator 构建 ✅
```bash
./scripts/build.sh -d simulator
```
- **无需代码签名**
- **无需 provisioning profile**
- **可以直接在 CI 环境运行**
- **适用场景**: 开发、测试、CI 快速验证

#### Archive 构建 ⚠️
```bash
./scripts/build.sh -a -r
```

当前使用的方式（`build.sh` line 378）:
```bash
xcodebuild archive \
  -allowProvisioningUpdates \  # 允许自动更新 profiles
  -signingStyle automatic      # 使用自动签名
```

**问题**:
- ❌ CI 环境没有本地证书
- ❌ CI 环境没有 provisioning profiles
- ❌ 自动签名需要 Apple Developer 账号登录
- ❌ `-allowProvisioningUpdates` 在 CI 环境无法工作

**结果**: Archive 构建在 GitHub Actions 中**会失败**！

---

## 解决方案

### 方案 1: 仅使用 Simulator 构建（当前可用）✅

**适用场景**:
- 持续集成验证
- 代码质量检查
- 快速测试

**操作**:
```bash
# 本地
./ios/scripts/build.sh -d simulator

# GitHub Actions (已配置)
# 选择 build_type: simulator
```

**优点**:
- ✅ 无需配置证书
- ✅ 构建速度快
- ✅ 适合 CI/CD

**缺点**:
- ❌ 无法生成可发布的 IPA
- ❌ 无法测试真机功能

---

### 方案 2: 配置 GitHub Actions 代码签名（推荐）⭐

完整配置 CI 环境的证书和 provisioning profiles，支持 Archive 构建。

#### 步骤 1: 准备证书和 Provisioning Profile

##### 1.1 导出开发证书 (.p12)

在 macOS 上：

```bash
# 打开钥匙串访问 (Keychain Access)
open /Applications/Utilities/Keychain\ Access.app

# 找到你的开发证书：
# "Apple Development: Your Name (Team ID)"
# 或 "iPhone Developer: Your Name"

# 右键点击证书 → 导出 → 保存为 .p12 文件
# 设置密码（记住这个密码，后面需要用）
```

或使用命令行：

```bash
# 查看可用的证书
security find-identity -v -p codesigning

# 导出证书（替换 CERT_NAME 为你的证书名称）
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities \
  -f pkcs12 \
  -o certificate.p12 \
  -P "your_password"
```

##### 1.2 获取 Provisioning Profile

方式 A - 从 Apple Developer 网站下载:

1. 访问: https://developer.apple.com/account/resources/profiles/list
2. 选择或创建 Development Profile
3. 下载 `.mobileprovision` 文件

方式 B - 从本地 Xcode 导出:

```bash
# 查找本地的 provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 找到对应的 profile (可以用文本编辑器打开查看)
# 复制到工作目录
cp ~/Library/MobileDevice/Provisioning\ Profiles/XXXXX.mobileprovision ./profile.mobileprovision
```

##### 1.3 转换为 Base64 (用于 GitHub Secrets)

```bash
# 转换证书
base64 -i certificate.p12 | pbcopy
# 内容已复制到剪贴板，准备粘贴到 GitHub Secrets

# 转换 provisioning profile
base64 -i profile.mobileprovision | pbcopy
# 内容已复制到剪贴板，准备粘贴到 GitHub Secrets
```

#### 步骤 2: 配置 GitHub Secrets

访问: https://github.com/vital-ai-experts/health_buddy_fe/settings/secrets/actions

添加以下 secrets:

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `CERTIFICATE_P12_BASE64` | (粘贴 base64 编码的证书) | 开发证书 |
| `CERTIFICATE_PASSWORD` | (证书导出时设置的密码) | 证书密码 |
| `PROVISIONING_PROFILE_BASE64` | (粘贴 base64 编码的 profile) | Provisioning Profile |
| `KEYCHAIN_PASSWORD` | (随机生成一个密码) | CI 临时 keychain 密码 |

可选（用于自动上传到 App Store Connect）:

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID | API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID | Issuer ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | (base64 编码的 .p8 文件) | API Key |

#### 步骤 3: 更新 GitHub Actions Workflow

我会创建一个新的 workflow 配置，包含代码签名步骤。

---

### 方案 3: 使用 Fastlane（推荐用于复杂项目）

Fastlane 是 iOS 自动化工具，可以简化代码签名和发布流程。

#### 安装 Fastlane

```bash
# 使用 Bundler (推荐)
cd ios
echo "gem 'fastlane'" > Gemfile
bundle install

# 或使用 Homebrew
brew install fastlane
```

#### 初始化 Fastlane

```bash
cd ios
fastlane init
```

#### 配置 Fastfile

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build for simulator"
  lane :build_simulator do
    build_app(
      scheme: "ThriveBody",
      destination: "generic/platform=iOS Simulator",
      skip_package_ipa: true,
      skip_archive: true,
      configuration: "Debug"
    )
  end

  desc "Build and sign IPA"
  lane :build_release do
    # 同步证书和 profiles
    match(
      type: "development",  # 或 "adhoc", "appstore"
      readonly: true
    )

    # 构建和签名
    build_app(
      scheme: "ThriveBody",
      configuration: "Release",
      export_method: "development",
      output_directory: "./build"
    )
  end

  desc "Upload to TestFlight"
  lane :beta do
    build_release

    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
```

#### 在 GitHub Actions 中使用

```yaml
- name: Build with Fastlane
  working-directory: ./ios
  run: |
    bundle install
    bundle exec fastlane build_simulator
```

---

## 详细配置步骤

### 为 GitHub Actions 配置代码签名

#### 第 1 步: 导出证书脚本

创建辅助脚本来导出证书:

```bash
#!/bin/bash
# scripts/export-certificates.sh

echo "导出 iOS 开发证书和 Provisioning Profiles"
echo "============================================"

# 导出证书
echo "1. 导出证书..."
CERT_NAME=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | sed -E 's/.*"(.*)".*/\1/')

if [ -z "$CERT_NAME" ]; then
    echo "错误: 未找到开发证书"
    exit 1
fi

echo "找到证书: $CERT_NAME"
read -sp "请输入导出密码: " CERT_PASSWORD
echo ""

security export -k ~/Library/Keychains/login.keychain-db \
    -t identities \
    -f pkcs12 \
    -o ./certificate.p12 \
    -P "$CERT_PASSWORD"

echo "✅ 证书已导出: certificate.p12"

# 导出 provisioning profile
echo ""
echo "2. 导出 Provisioning Profile..."
PROFILE_PATH=$(ls -t ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | head -1)

if [ -z "$PROFILE_PATH" ]; then
    echo "错误: 未找到 Provisioning Profile"
    exit 1
fi

cp "$PROFILE_PATH" ./profile.mobileprovision
echo "✅ Profile 已导出: profile.mobileprovision"

# 转换为 Base64
echo ""
echo "3. 转换为 Base64..."
echo ""
echo "=== CERTIFICATE_P12_BASE64 ==="
base64 -i certificate.p12
echo ""
echo "=== PROVISIONING_PROFILE_BASE64 ==="
base64 -i profile.mobileprovision
echo ""
echo "=== CERTIFICATE_PASSWORD ==="
echo "$CERT_PASSWORD"
echo ""

echo "✅ 完成！请将上述内容添加到 GitHub Secrets"
echo ""
echo "GitHub Secrets 配置:"
echo "https://github.com/vital-ai-experts/health_buddy_fe/settings/secrets/actions"
```

#### 第 2 步: GitHub Actions 签名步骤

在 workflow 中添加签名配置:

```yaml
# .github/workflows/ios-archive.yml

- name: Import signing certificate
  env:
    CERTIFICATE_P12_BASE64: ${{ secrets.CERTIFICATE_P12_BASE64 }}
    CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    # 创建临时 keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db

    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
    security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

    # 导入证书
    echo "$CERTIFICATE_P12_BASE64" | base64 --decode > certificate.p12
    security import certificate.p12 \
      -P "$CERTIFICATE_PASSWORD" \
      -A \
      -t cert \
      -f pkcs12 \
      -k "$KEYCHAIN_PATH"

    security list-keychain -d user -s "$KEYCHAIN_PATH"
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

- name: Install provisioning profile
  env:
    PROVISIONING_PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE_BASE64 }}
  run: |
    PP_PATH=$RUNNER_TEMP/profile.mobileprovision
    echo "$PROVISIONING_PROFILE_BASE64" | base64 --decode > "$PP_PATH"

    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    cp "$PP_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/

- name: Build and sign archive
  working-directory: ./ios
  run: |
    ./scripts/build.sh -a -r

- name: Cleanup keychain
  if: always()
  run: |
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    security delete-keychain "$KEYCHAIN_PATH" || true
```

---

## 不同签名方式对比

| 方式 | 适用场景 | 优点 | 缺点 |
|------|---------|------|------|
| **Automatic Signing** | 本地开发 | 简单，无需手动配置 | CI 环境不可用 |
| **Manual Signing** | CI/CD | 完全控制，可重复构建 | 需要手动管理证书 |
| **Fastlane Match** | 团队协作 | 证书共享，自动化 | 需要 Git 仓库存储证书 |

---

## 当前项目建议

### 短期方案（立即可用）✅

**使用 Simulator 构建进行 CI 验证**

```bash
# GitHub Actions
选择 build_type: simulator
```

**优点**:
- 无需配置证书
- 构建速度快
- 已经配置完成

**缺点**:
- 无法生成 IPA

### 中期方案（需要配置）⭐

**配置 GitHub Secrets 支持 Archive 构建**

步骤:
1. 导出证书和 provisioning profile
2. 转换为 Base64
3. 添加到 GitHub Secrets
4. 使用更新的 workflow

**优点**:
- 可以生成 IPA
- 支持真机测试
- 支持发布到 TestFlight

**缺点**:
- 需要一次性配置

### 长期方案（推荐）🚀

**使用 Fastlane + Match**

**优点**:
- 完整的自动化流程
- 证书集中管理
- 团队协作友好
- 支持多环境

**缺点**:
- 学习曲线
- 需要额外配置

---

## 常见问题

### Q1: 为什么 Simulator 构建不需要签名？

**A**: Simulator 运行在 Mac 上，是 x86_64/arm64 架构，不需要 iOS 设备的代码签名机制。

### Q2: 证书过期了怎么办？

**A**:
1. 在 Apple Developer 网站重新生成证书
2. 重新导出并更新 GitHub Secrets
3. 更新本地的 provisioning profiles

### Q3: 可以使用 Distribution 证书吗？

**A**: 可以，但需要：
- 使用 Ad Hoc 或 App Store provisioning profile
- 修改 ExportOptions.plist 的 method 为 "ad-hoc" 或 "app-store"

### Q4: 如何验证证书是否正确？

**A**:
```bash
# 查看证书信息
security find-identity -v -p codesigning

# 查看 provisioning profile 信息
security cms -D -i profile.mobileprovision
```

### Q5: Build 失败提示 "No provisioning profile found"

**A**: 检查：
1. Provisioning profile 是否正确安装
2. Bundle ID 是否匹配
3. 证书是否在 profile 中
4. Profile 是否过期

---

## 下一步

选择一个方案：

### 方案 A: 继续使用 Simulator（最简单）
```bash
# 无需额外配置，当前已可用
./.github/scripts/trigger-with-token.sh -c Debug -b simulator
```

### 方案 B: 配置完整签名（推荐）
1. 按照本文档导出证书和 profiles
2. 添加到 GitHub Secrets
3. 我会创建支持签名的 workflow

### 方案 C: 使用 Fastlane（长期推荐）
1. 安装 Fastlane
2. 配置 Fastfile
3. 集成到 CI/CD

---

## 参考资源

- [Apple Code Signing](https://developer.apple.com/support/code-signing/)
- [GitHub Actions - iOS](https://docs.github.com/en/actions/deployment/deploying-xcode-applications)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane Match](https://docs.fastlane.tools/actions/match/)

---

**创建时间**: 2025-11-15
**适用版本**: iOS 17.0+, Xcode 15.2+
