# GitHub Secrets 配置示例

本文档说明如何配置 GitHub Secrets 用于 iOS 项目的 CI/CD。

## 什么是 GitHub Secrets?

GitHub Secrets 是一种安全存储敏感信息的方式,如:
- 证书密码
- API 密钥
- 访问令牌
- 代码签名凭证

## 配置步骤

### 1. 访问仓库设置

1. 打开仓库页面
2. 点击 "Settings"
3. 在左侧菜单中选择 "Secrets and variables" > "Actions"
4. 点击 "New repository secret"

### 2. 添加 Secrets

根据需要添加以下 secrets:

## 常用 Secrets 列表

### 代码签名相关

#### CERT_PASSWORD
- **描述**: 证书密码
- **用途**: 导入开发证书
- **示例值**: `your-cert-password`

#### PROVISIONING_PROFILE
- **描述**: Provisioning Profile (Base64 编码)
- **用途**: 代码签名
- **获取方式**:
  ```bash
  base64 -i YourProfile.mobileprovision | pbcopy
  ```

#### CERTIFICATE_P12
- **描述**: P12 证书文件 (Base64 编码)
- **用途**: 代码签名
- **获取方式**:
  ```bash
  base64 -i YourCert.p12 | pbcopy
  ```

### App Store Connect

#### APP_STORE_CONNECT_API_KEY
- **描述**: App Store Connect API Key (Base64 编码)
- **用途**: 自动上传到 TestFlight/App Store
- **获取**: App Store Connect > Users and Access > Keys

#### APP_STORE_CONNECT_ISSUER_ID
- **描述**: Issuer ID
- **用途**: App Store Connect API 认证

#### APP_STORE_CONNECT_KEY_ID
- **描述**: Key ID
- **用途**: App Store Connect API 认证

### 通知相关

#### SLACK_WEBHOOK_URL
- **描述**: Slack Webhook URL
- **用途**: 构建结果通知
- **格式**: `https://hooks.slack.com/services/XXX/YYY/ZZZ`

#### DISCORD_WEBHOOK_URL
- **描述**: Discord Webhook URL
- **用途**: 构建结果通知

### Firebase (可选)

#### FIREBASE_TOKEN
- **描述**: Firebase CI token
- **用途**: 自动发布到 Firebase App Distribution
- **获取**:
  ```bash
  firebase login:ci
  ```

#### FIREBASE_APP_ID
- **描述**: Firebase App ID
- **用途**: Firebase App Distribution

## 在 Workflow 中使用 Secrets

### 基本用法

```yaml
env:
  CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}

steps:
  - name: Use secret
    run: |
      echo "Using certificate password"
      # 使用 $CERT_PASSWORD
```

### 代码签名示例

```yaml
- name: Import signing certificate
  env:
    CERTIFICATE_P12: ${{ secrets.CERTIFICATE_P12 }}
    CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}
  run: |
    # 创建临时 keychain
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain

    # 解码并导入证书
    echo "$CERTIFICATE_P12" | base64 -d > cert.p12
    security import cert.p12 -k build.keychain -P "$CERT_PASSWORD" -T /usr/bin/codesign

    # 设置 keychain 权限
    security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

- name: Install provisioning profile
  env:
    PROVISIONING_PROFILE: ${{ secrets.PROVISIONING_PROFILE }}
  run: |
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "$PROVISIONING_PROFILE" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
```

### 通知示例

```yaml
- name: Send Slack notification
  if: always()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "Build ${{ job.status }}: ${{ github.repository }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Build Status*: ${{ job.status }}\n*Branch*: ${{ github.ref_name }}\n*Commit*: ${{ github.sha }}"
            }
          }
        ]
      }
```

### TestFlight 上传示例

```yaml
- name: Upload to TestFlight
  env:
    APP_STORE_CONNECT_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
    APP_STORE_CONNECT_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
    APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
  run: |
    # 保存 API Key
    mkdir -p ~/.appstoreconnect/private_keys
    echo "$APP_STORE_CONNECT_API_KEY" | base64 -d > ~/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_KEY_ID}.p8

    # 使用 xcrun altool 上传
    xcrun altool --upload-app \
      --type ios \
      --file "build/ThriveBody.ipa" \
      --apiKey "$APP_STORE_CONNECT_KEY_ID" \
      --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID"
```

## 最佳实践

### 1. 最小权限原则

只添加必需的 secrets,不要过度暴露敏感信息。

### 2. 定期轮换

定期更新和轮换敏感凭证:
- API 密钥: 每 90 天
- 证书: 按 Apple 要求

### 3. 环境隔离

为不同环境使用不同的 secrets:
- `DEV_API_KEY`
- `PROD_API_KEY`

### 4. 审计访问

定期检查谁有权访问 secrets:
- Settings > Security > Audit log

### 5. 使用环境 Secrets

为不同部署环境配置不同的 secrets:

```yaml
jobs:
  deploy:
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        env:
          API_KEY: ${{ secrets.PROD_API_KEY }}
```

## 安全注意事项

### ❌ 不要做的事

1. **不要打印 secrets**
   ```yaml
   # ❌ 错误
   run: echo "API Key: ${{ secrets.API_KEY }}"
   ```

2. **不要在日志中暴露 secrets**
   ```yaml
   # ❌ 错误
   run: curl -H "Authorization: $SECRET" ... -v
   ```

3. **不要提交 secrets 到代码仓库**
   ```yaml
   # ❌ 错误
   env:
     API_KEY: "hardcoded-key"
   ```

### ✅ 应该做的事

1. **使用 secrets 引用**
   ```yaml
   # ✅ 正确
   env:
     API_KEY: ${{ secrets.API_KEY }}
   ```

2. **隐藏敏感输出**
   ```yaml
   # ✅ 正确
   run: |
     echo "::add-mask::${{ secrets.API_KEY }}"
     # 使用 API_KEY
   ```

3. **验证 secrets 存在**
   ```yaml
   # ✅ 正确
   - name: Check secrets
     if: ${{ secrets.API_KEY == '' }}
     run: |
       echo "Error: API_KEY not set"
       exit 1
   ```

## 故障排除

### Secret 未找到

**错误信息**: `The secret 'XXX' was not found`

**解决方法**:
1. 检查 secret 名称拼写
2. 确认 secret 已添加
3. 检查是否在正确的环境中

### Secret 值不正确

**症状**: 认证失败或构建错误

**检查步骤**:
1. 重新生成 secret 值
2. 检查 Base64 编码是否正确
3. 验证 secret 未过期

### 无法访问 Secret

**可能原因**:
- 权限不足
- Secret 仅在特定环境可用
- 仓库 fork 无法访问 secrets

## 参考资源

- [GitHub Secrets 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Apple 代码签名文档](https://developer.apple.com/documentation/security/code_signing)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)

## 示例完整 Workflow

查看 `.github/workflows/` 目录中的示例工作流,了解如何在实际项目中使用这些 secrets。

---

**注意**: 本文档仅作为示例和参考。实际使用时请根据项目需求调整。
