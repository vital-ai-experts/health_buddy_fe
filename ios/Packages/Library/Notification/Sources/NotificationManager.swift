//
//  NotificationManager.swift
//  LibraryNotification
//
//  Created by Claude on 2025/11/14.
//

import Foundation
import UserNotifications
import UIKit
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
            // Auto-start Live Activity if user is logged in
            await autoStartLiveActivityIfNeeded()
        } else {
            Log.e("❌ 通知权限被拒绝", category: "Notification")
        }
    }

    /// 检查通知权限状态
    public func checkNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    /// 自动启动 Live Activity（如果满足条件）
    /// 条件：同时满足有通知权限且已登录
    public func autoStartLiveActivityIfNeeded() async {
        // Check if notification permission is granted
        let hasNotificationPermission = await checkNotificationPermission()
        guard hasNotificationPermission else {
            Log.i("ℹ️ [NotificationManager] 没有通知权限，跳过自动启动 Live Activity", category: "Notification")
            return
        }

        // Check if user is logged in
        let isLoggedIn = UserDefaultsTokenStorage.shared.getToken() != nil
        guard isLoggedIn else {
            Log.i("ℹ️ [NotificationManager] 用户未登录，跳过自动启动 Live Activity", category: "Notification")
            return
        }

        // Both conditions are met, auto-start Live Activity
        Log.i("✅ [NotificationManager] 满足条件，自动启动 Live Activity", category: "Notification")

        if #available(iOS 16.1, *) {
            // Check if Live Activity is already active
            if LiveActivityManager.shared.isAgendaActive {
                Log.i("ℹ️ [NotificationManager] Live Activity 已经在运行中", category: "Notification")
                return
            }

            // Start Live Activity with default values
            do {
                // Get user ID from token or use default
                let userId = "auto-start"
                try await LiveActivityManager.shared.startAgendaActivity(userId: userId)
                Log.i("✅ [NotificationManager] Live Activity 已自动启动", category: "Notification")
            } catch {
                Log.e("❌ [NotificationManager] 自动启动 Live Activity 失败: \(error.localizedDescription)", error: error, category: "Notification")
            }
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
        guard let accessToken = UserDefaultsTokenStorage.shared.getToken() else {
            Log.w("⚠️ [NotificationManager] 用户未登录，稍后会在登录后上报", category: "Notification")
            return
        }

        // Get Live Activity token if available
        var liveActivityToken: String?
        if #available(iOS 16.1, *) {
            liveActivityToken = LiveActivityManager.shared.liveActivityToken
        }

        // 上报设备信息
        await DeviceTrackManager.shared.report(
            deviceToken: deviceToken,
            accessToken: accessToken,
            liveActivityToken: liveActivityToken
        )
    }

    /// 上报设备信息（包含 Live Activity Token）
    /// 当 Live Activity push token 更新时调用
    public func reportDeviceInfoWithLiveActivityToken() async {
        await reportDeviceInfoIfPossible()
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
        if let deeplinkString = userInfo["deeplink"] as? String,
           let url = URL(string: deeplinkString) {
            Log.i("🔗 提取到 deeplink: \(deeplinkString)", category: "Notification")
            Task { @MainActor in
                UIApplication.shared.open(url)
            }
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
