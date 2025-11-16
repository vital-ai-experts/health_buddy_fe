//
//  DeviceStorage.swift
//  LibraryTrack
//
//  Storage protocol and implementation for device tracking data
//

import Foundation

// MARK: - Storage Protocol

/// Protocol for storing device tracking data
public protocol DeviceStorage {
    func saveDeviceId(_ deviceId: String) throws
    func getDeviceId() -> String?
    func deleteDeviceId() throws

    func saveUniqueIdentifier(_ identifier: String) throws
    func getUniqueIdentifier() -> String?
}

// MARK: - UserDefaults Implementation

/// UserDefaults-based implementation of DeviceStorage
public final class UserDefaultsDeviceStorage: DeviceStorage {
    private let deviceIdKey = "com.hehigh.thrivebody.deviceId"
    private let uniqueIdentifierKey = "com.hehigh.thrivebody.uniqueIdentifier"
    private let defaults = UserDefaults.standard

    public init() {}

    public func saveDeviceId(_ deviceId: String) throws {
        defaults.set(deviceId, forKey: deviceIdKey)
    }

    public func getDeviceId() -> String? {
        return defaults.string(forKey: deviceIdKey)
    }

    public func deleteDeviceId() throws {
        defaults.removeObject(forKey: deviceIdKey)
    }

    public func saveUniqueIdentifier(_ identifier: String) throws {
        defaults.set(identifier, forKey: uniqueIdentifierKey)
    }

    public func getUniqueIdentifier() -> String? {
        return defaults.string(forKey: uniqueIdentifierKey)
    }
}
