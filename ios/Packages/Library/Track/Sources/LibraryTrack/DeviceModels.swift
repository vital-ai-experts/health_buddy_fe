//
//  DeviceModels.swift
//  LibraryTrack
//
//  Models for device registration and reporting
//

import Foundation

// MARK: - Request Models

/// Request model for device registration
public struct RegisterDeviceRequest: Codable {
    public let devicePlatform: String
    public let uniqueIdentifier: String
    public let deviceToken: String

    public init(devicePlatform: String, uniqueIdentifier: String, deviceToken: String) {
        self.devicePlatform = devicePlatform
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
