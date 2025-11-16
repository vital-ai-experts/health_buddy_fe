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
/// Note: UniqueIdentifier is stored in Keychain for enhanced security
public final class UserDefaultsDeviceStorage: DeviceStorage {
    private let deviceIdKey = "com.hehigh.thrivebody.deviceId"
    private let uniqueIdentifierKey = "com.hehigh.thrivebody.uniqueIdentifier"
    private let keychainUniqueIdentifierKey = "com.hehigh.thrivebody.keychain.uniqueIdentifier"
    private let defaults = UserDefaults.standard
    private let keychain = KeychainManager.shared

    public init() {
        // Migrate existing uniqueIdentifier from UserDefaults to Keychain
        migrateUniqueIdentifierToKeychain()
    }

    // MARK: - Device ID (UserDefaults)

    public func saveDeviceId(_ deviceId: String) throws {
        defaults.set(deviceId, forKey: deviceIdKey)
    }

    public func getDeviceId() -> String? {
        return defaults.string(forKey: deviceIdKey)
    }

    public func deleteDeviceId() throws {
        defaults.removeObject(forKey: deviceIdKey)
    }

    // MARK: - Unique Identifier (Keychain)

    public func saveUniqueIdentifier(_ identifier: String) throws {
        try keychain.save(identifier, forKey: keychainUniqueIdentifierKey)
    }

    public func getUniqueIdentifier() -> String? {
        return keychain.get(forKey: keychainUniqueIdentifierKey)
    }

    // MARK: - Migration

    /// Migrate uniqueIdentifier from UserDefaults to Keychain
    /// This is a one-time migration for existing users
    private func migrateUniqueIdentifierToKeychain() {
        // Check if uniqueIdentifier exists in UserDefaults
        guard let oldIdentifier = defaults.string(forKey: uniqueIdentifierKey) else {
            return
        }

        // Check if it's already in Keychain
        if keychain.get(forKey: keychainUniqueIdentifierKey) != nil {
            // Already migrated, remove from UserDefaults
            defaults.removeObject(forKey: uniqueIdentifierKey)
            return
        }

        // Migrate to Keychain
        do {
            try keychain.save(oldIdentifier, forKey: keychainUniqueIdentifierKey)
            // Remove from UserDefaults after successful migration
            defaults.removeObject(forKey: uniqueIdentifierKey)
        } catch {
            // If migration fails, keep the old value in UserDefaults as fallback
            // The app will continue to use the Keychain in future calls
            print("⚠️ Failed to migrate uniqueIdentifier to Keychain: \(error.localizedDescription)")
        }
    }
}
