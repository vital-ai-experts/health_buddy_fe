//
//  NotificationManager.swift
//  ThriveBody
//
//  Created by Claude on 2025/11/14.
//

import Foundation
import UserNotifications

/// 推送通知管理器
/// 负责管理设备的推送通知令牌和通知权限
@MainActor
class NotificationManager: ObservableObject {
    /// 单例
    static let shared = NotificationManager()

    /// 设备令牌（存储在内存中）
    @Published private(set) var deviceToken: String?

    private init() {}

    /// 请求通知权限
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

        if granted {
            print("✅ 通知权限已授予")
        } else {
            print("❌ 通知权限被拒绝")
        }
    }

    /// 保存设备令牌
    func setDeviceToken(_ token: Data) {
        // 将 Data 转换为十六进制字符串
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString

        print("📱 Device Token 已保存:")
        print("   \(tokenString)")
    }

    /// 记录注册失败
    func didFailToRegister(error: Error) {
        print("❌ 推送通知注册失败: \(error.localizedDescription)")
    }
}
