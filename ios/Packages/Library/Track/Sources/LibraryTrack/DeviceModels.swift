//
//  DeviceModels.swift
//  LibraryTrack
//
//  Models for device registration and reporting
//

import Foundation

// MARK: - Device Platform Enum

/// Device platform enum matching the IDL base.thrift DevicePlatform
public enum DevicePlatform: String, Codable {
    case ios = "iOS"
    case android = "Android"
    case web = "Web"
}

// MARK: - Request Models

/// Request model for device registration
public struct RegisterDeviceRequest: Codable {
    public let platform: DevicePlatform
    public let uniqueIdentifier: String
    public let deviceToken: String

    public init(platform: DevicePlatform, uniqueIdentifier: String, deviceToken: String) {
        self.platform = platform
        self.uniqueIdentifier = uniqueIdentifier
        self.deviceToken = deviceToken
    }
}

/// Request model for reporting device info
public struct ReportDeviceInfoRequest: Codable {
    public let deviceId: String
    public let deviceToken: String

    public init(deviceId: String, deviceToken: String) {
        self.deviceId = deviceId
        self.deviceToken = deviceToken
    }
}

// MARK: - Response Models

/// Response model for device registration
public struct RegisterDeviceResponse: Codable {
    public let deviceId: String
}

/// Response model for reporting device info
public struct ReportDeviceInfoResponse: Codable {
    // Empty response
}
