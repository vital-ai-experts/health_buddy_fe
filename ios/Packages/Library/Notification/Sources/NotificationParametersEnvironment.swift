//
//  NotificationParametersEnvironment.swift
//  LibraryNotification
//
//  Created by Claude on 2025/11/15.
//

import SwiftUI

/// 通知参数环境键
/// 用于在视图层级中传递通知携带的参数
private struct NotificationParametersKey: EnvironmentKey {
    static let defaultValue: [String: String]? = nil
}

public extension EnvironmentValues {
    var notificationParameters: [String: String]? {
        get { self[NotificationParametersKey.self] }
        set { self[NotificationParametersKey.self] = newValue }
    }
}
