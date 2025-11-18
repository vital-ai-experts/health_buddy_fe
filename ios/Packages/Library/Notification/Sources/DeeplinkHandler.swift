//
//  DeeplinkHandler.swift
//  LibraryNotification
//
//  Created by Claude on 2025/11/15.
//

import Foundation
import Combine
import LibraryBase

/// Deeplink 类型
public enum DeeplinkDestination: Equatable {
    case dailyReport(msgId: String, from: String)
    case main  // 主页，不需要导航
    case unknown(url: String)
}

/// Deeplink 处理器
/// 负责解析和发布 deeplink 事件
@MainActor
public class DeeplinkHandler: ObservableObject {
    /// 单例
    public static let shared = DeeplinkHandler()

    /// Deeplink 事件发布者
    @Published public private(set) var pendingDeeplink: DeeplinkDestination?

    private init() {}

    /// 处理 deeplink URL
    /// - Parameter urlString: deeplink URL 字符串
    public func handle(_ urlString: String) {
        Log.i("🔗 收到 Deeplink: \(urlString)", category: "Notification")

        guard let url = URL(string: urlString),
              url.scheme == "thrivebody" else {
            Log.w("⚠️ 无效的 deeplink URL: \(urlString)", category: "Notification")
            pendingDeeplink = .unknown(url: urlString)
            return
        }

        let destination = parseDeeplink(url)
        Log.i("✅ Deeplink 解析结果: \(destination)", category: "Notification")
        pendingDeeplink = destination
    }

    /// 清除待处理的 deeplink
    public func clearPendingDeeplink() {
        pendingDeeplink = nil
    }

    /// 解析 deeplink URL
    private func parseDeeplink(_ url: URL) -> DeeplinkDestination {
        let host = url.host ?? ""

        switch host {
        case "main":
            // 主页 deeplink，不需要导航
            return .main
        case "daily_report":
            return parseDailyReport(url)
        default:
            return .unknown(url: url.absoluteString)
        }
    }

    /// 解析 daily_report deeplink
    private func parseDailyReport(_ url: URL) -> DeeplinkDestination {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        var msgId = ""
        var from = ""

        for item in queryItems {
            switch item.name {
            case "msg_id":
                msgId = item.value ?? ""
            case "from":
                from = item.value ?? ""
            default:
                break
            }
        }

        return .dailyReport(msgId: msgId, from: from)
    }
}
