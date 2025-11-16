//
//  NotificationManager.swift
//  LibraryNotification
//
//  Created by Claude on 2025/11/14.
//

import Foundation
import UserNotifications
import LibraryBase
import LibraryTrack
import LibraryNetworking

/// 推送通知管理器
/// 负责管理设备的推送通知令牌和通知权限
@MainActor
public class NotificationManager: NSObject, ObservableObject {
    /// 单例
    public static let shared = NotificationManager()

    /// 设备令牌（存储在内存中）
    @Published public private(set) var deviceToken: String?

    private override init() {
        super.init()
        setupNotificationCenter()
    }

    /// 设置通知中心
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// 请求通知权限
    public func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

        if granted {
            Log.i("✅ 通知权限已授予", category: "Notification")
        } else {
            Log.e("❌ 通知权限被拒绝", category: "Notification")
        }
    }

    /// 保存设备令牌
    public func setDeviceToken(_ token: Data) {
        // 将 Data 转换为十六进制字符串
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        Log.i("📱 Device Token 已保存:", category: "Notification")
        Log.i("   \(tokenString)", category: "Notification")

        // 尝试上报设备信息（如果用户已登录）
        Task {
            await reportDeviceInfoIfPossible()
        }
    }

    /// 上报设备信息到服务器
    /// 当用户登录后，应主动调用此方法上报设备 token
    public func reportDeviceInfoIfPossible() async {
        // 检查是否有 device token
        guard let deviceToken = self.deviceToken else {
            Log.w("⚠️ [NotificationManager] 没有 device token，无法上报", category: "Notification")
            return
        }

        // 检查是否有 access token
        guard let accessToken = KeychainManager.shared.getToken() else {
            Log.w("⚠️ [NotificationManager] 用户未登录，稍后会在登录后上报", category: "Notification")
            return
        }

        // 上报设备信息
        do {
            try await DeviceTrackManager.shared.report(deviceToken: deviceToken, accessToken: accessToken)
            Log.i("✅ [NotificationManager] 设备信息上报成功", category: "Notification")
        } catch {
            Log.e("❌ [NotificationManager] 设备信息上报失败: \(error.localizedDescription)", error: error, category: "Notification")
        }
    }

    /// 记录注册失败
    public func didFailToRegister(error: Error) {
        Log.e("❌ 推送通知注册失败: \(error.localizedDescription)", category: "Notification")
    }

    /// 处理通知点击
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        Log.i("🔔 用户点击了通知", category: "Notification")
        Log.i("📦 通知内容: \(userInfo)", category: "Notification")

        // 提取 deeplink
        if let deeplinkString = userInfo["deeplink"] as? String {
            Log.i("🔗 提取到 deeplink: \(deeplinkString)", category: "Notification")
            DeeplinkHandler.shared.handle(deeplinkString)
        } else {
            Log.w("⚠️ 通知中没有 deeplink", category: "Notification")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// App 在前台时收到通知
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Log.i("📱 App 在前台收到通知", category: "Notification")
        // 在前台也显示通知
        completionHandler([.banner, .sound, .badge])
    }

    /// 用户点击通知
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo: userInfo)
        completionHandler()
    }
}
