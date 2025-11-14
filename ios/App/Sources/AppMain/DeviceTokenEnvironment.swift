//
//  DeviceTokenEnvironment.swift
//  ThriveBody
//
//  Created by Claude on 2025/11/14.
//

import SwiftUI

/// 设备令牌环境键
/// 用于在视图层级中传递 device token
private struct DeviceTokenKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    var deviceToken: String? {
        get { self[DeviceTokenKey.self] }
        set { self[DeviceTokenKey.self] = newValue }
    }
}
