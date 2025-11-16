//
//  AppDelegate.swift
//  ThriveBody
//
//  Created by Claude on 2025/11/14.
//

import UIKit
import UserNotifications
import LibraryNotification
import LibraryBase

/// 应用代理
/// 处理推送通知相关的系统回调
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 注册远程推送通知
        Log.i("🚀 开始注册远程推送通知...", category: "App")
        application.registerForRemoteNotifications()
        return true
    }

    // MARK: - 推送通知回调

    /// 成功注册远程推送通知
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            NotificationManager.shared.setDeviceToken(deviceToken)
        }
    }

    /// 注册远程推送通知失败
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            NotificationManager.shared.didFailToRegister(error: error)
        }
    }
}
