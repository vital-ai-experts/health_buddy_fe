//
//  CommonParamsProviderImpl.swift
//  LibraryTrack
//
//  Common API parameters provider implementation
//

import Foundation
import LibraryNetworking

/// Implementation of CommonParamsProvider that provides device and locale information
/// for all API requests
@MainActor
public class CommonParamsProviderImpl: CommonParamsProvider {
    /// Shared singleton instance
    public static let shared = CommonParamsProviderImpl()

    private let deviceTrackManager: DeviceTrackManager

    private init(deviceTrackManager: DeviceTrackManager = .shared) {
        self.deviceTrackManager = deviceTrackManager
    }

    /// Returns common query parameters to be appended to every API request
    /// - Returns: Array of URLQueryItem containing:
    ///   - region: User's region code (e.g., "US", "GB", "CN")
    ///   - language: User's preferred language (e.g., "en", "zh")
    ///   - device_id: Device registration ID
    ///   - device_platform: Platform identifier ("ios")
    ///   - timezone: Timezone identifier (e.g., "America/New_York", "Asia/Shanghai")
    ///   - timezone_offset: Timezone offset in seconds from UTC
    public func getCommonQueryParams() -> [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        // 1. Region - from user's current locale
        if let regionCode = Locale.current.region?.identifier {
            queryItems.append(URLQueryItem(name: "region", value: regionCode))
        }

        // 2. Language - user's preferred language
        if let languageCode = Locale.current.language.languageCode?.identifier {
            queryItems.append(URLQueryItem(name: "language", value: languageCode))
        }

        // 3. Device ID - from DeviceTrackManager
        if let deviceId = deviceTrackManager.getDeviceId() {
            queryItems.append(URLQueryItem(name: "device_id", value: deviceId))
        }

        // 4. Device Platform - hardcoded as "ios"
        queryItems.append(URLQueryItem(name: "device_platform", value: "ios"))

        // 5. Timezone - current timezone identifier
        let timezone = TimeZone.current
        queryItems.append(URLQueryItem(name: "timezone", value: timezone.identifier))

        // 6. Timezone Offset - in seconds from UTC
        let timezoneOffset = timezone.secondsFromGMT()
        queryItems.append(URLQueryItem(name: "timezone_offset", value: String(timezoneOffset)))

        return queryItems
    }
}
