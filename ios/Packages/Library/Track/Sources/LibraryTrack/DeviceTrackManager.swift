//
//  DeviceTrackManager.swift
//  LibraryTrack
//
//  Device registration and tracking manager
//

import Foundation
import UIKit
import LibraryNetworking
import LibraryBase

/// Device tracking manager for registration and reporting
@MainActor
public class DeviceTrackManager {
    /// Shared singleton instance
    public static let shared = DeviceTrackManager()

    private let apiClient: APIClient
    private let storage: DeviceStorage

    /// Cached device ID
    private var cachedDeviceId: String?

    /// Cached unique identifier (IDFV or generated UUID)
    private var cachedUniqueIdentifier: String?

    private init(
        apiClient: APIClient = .shared,
        storage: DeviceStorage = UserDefaultsDeviceStorage()
    ) {
        self.apiClient = apiClient
        self.storage = storage

        // Load cached device ID and unique identifier
        self.cachedDeviceId = storage.getDeviceId()
        self.cachedUniqueIdentifier = storage.getUniqueIdentifier()
    }

    // MARK: - Public Methods

    /// Register device with the server
    /// This should be called after network status is confirmed
    /// The call is async and non-blocking
    /// Errors are logged internally and do not propagate to caller
    public func register(deviceToken: String = "") async {
        do {
            if let cachedDeviceId = cachedDeviceId, !cachedDeviceId.isEmpty {
                return
            }
            // Get unique identifier (IDFV or stored UUID)
            let uniqueIdentifier = getOrCreateUniqueIdentifier()

            // Create request
            let request = RegisterDeviceRequest(
                devicePlatform: "ios",
                uniqueIdentifier: uniqueIdentifier,
                deviceToken: deviceToken
            )

            let endpoint = APIEndpoint(
                path: "/device/register",
                method: .post,
                body: request,
                requiresAuth: false
            )

            let response: RegisterDeviceResponse = try await apiClient.request(endpoint, responseType: RegisterDeviceResponse.self)

            // Store device ID
            try storage.saveDeviceId(response.deviceId)
            cachedDeviceId = response.deviceId

            Log.i("✅ [DeviceTrack] 设备注册成功，Device ID: \(response.deviceId)", category: "DeviceTrack")
        } catch {
            Log.e("❌ [DeviceTrack] 设备注册失败: \(error.localizedDescription)", error: error, category: "DeviceTrack")
            // 注册失败不影响应用正常使用
        }
    }

    /// Report device info (device token) to server
    /// This should be called when the device token is received from push notifications
    /// Errors are logged internally and do not propagate to caller
    public func report(deviceToken: String, accessToken: String) async {
        do {
            guard let deviceId = getDeviceId() else {
                Log.w("⚠️ [DeviceTrack] 没有 device ID，无法上报设备信息", category: "DeviceTrack")
                return
            }

            let request = ReportDeviceInfoRequest(
                deviceId: deviceId,
                deviceToken: deviceToken
            )

            let endpoint = APIEndpoint(
                path: "/device/info/report",
                method: .post,
                body: request,
                requiresAuth: true
            )

            // Set auth token temporarily for this request
            let originalToken = apiClient.getAuthToken()
            apiClient.setAuthToken(accessToken)
            defer { apiClient.setAuthToken(originalToken) }

            let _: ReportDeviceInfoResponse = try await apiClient.request(endpoint, responseType: ReportDeviceInfoResponse.self)

            Log.i("✅ [DeviceTrack] 设备信息上报成功", category: "DeviceTrack")
        } catch {
            Log.e("❌ [DeviceTrack] 设备信息上报失败: \(error.localizedDescription)", error: error, category: "DeviceTrack")
        }
    }

    /// Get cached device ID
    /// Returns nil if device has not been registered yet
    public func getDeviceId() -> String? {
        return cachedDeviceId ?? storage.getDeviceId()
    }

    // MARK: - Private Methods

    /// Get or create unique identifier
    /// Uses IDFV if available, otherwise generates and stores a UUID
    /// Result is cached in memory to avoid repeated lookups
    private func getOrCreateUniqueIdentifier() -> String {
        // Return cached value if available
        if let cached = cachedUniqueIdentifier {
            Log.d("📱 [DeviceTrack] 使用缓存的唯一标识符: \(cached)", category: "DeviceTrack")
            return cached
        }

        // Check if we have a stored UUID
        if let storedUUID = storage.getUniqueIdentifier() {
            Log.d("📱 [DeviceTrack] 使用存储的 UUID: \(storedUUID)", category: "DeviceTrack")
            cachedUniqueIdentifier = storedUUID
            return storedUUID
        }

        // Try to get IDFV (Identifier for Vendor)
        if let idfv = UIDevice.current.identifierForVendor?.uuidString {
            Log.d("📱 [DeviceTrack] 使用 IDFV: \(idfv)", category: "DeviceTrack")
            cachedUniqueIdentifier = idfv
            // Save IDFV to storage for future use
            do {
                try storage.saveUniqueIdentifier(idfv)
            } catch {
                Log.w("⚠️ [DeviceTrack] 保存 IDFV 失败: \(error.localizedDescription)", category: "DeviceTrack")
            }
            return idfv
        }

        // Generate new UUID and store it
        let newUUID = UUID().uuidString
        do {
            try storage.saveUniqueIdentifier(newUUID)
            cachedUniqueIdentifier = newUUID
            Log.i("📱 [DeviceTrack] 生成并存储新 UUID: \(newUUID)", category: "DeviceTrack")
        } catch {
            Log.w("⚠️ [DeviceTrack] 保存 UUID 失败: \(error.localizedDescription)", category: "DeviceTrack")
        }

        return newUUID
    }
}

// MARK: - Error Types

public enum DeviceTrackError: LocalizedError {
    case noDeviceId

    public var errorDescription: String? {
        switch self {
        case .noDeviceId:
            return "Device ID not available. Please register device first."
        }
    }
}
