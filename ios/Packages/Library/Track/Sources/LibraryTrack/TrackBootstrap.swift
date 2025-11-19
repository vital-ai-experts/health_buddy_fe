//
//  TrackBootstrap.swift
//  LibraryTrack
//
//  Bootstrap configuration for tracking layer
//

import Foundation
import LibraryNetworking

/// Bootstrap configuration for the Track library
@MainActor
public enum TrackBootstrap {
    /// Configure the tracking layer
    /// - Registers CommonParamsProvider to Networking layer
    /// - Initializes device tracking components
    public static func configure() {
        // Register common params provider to networking layer
        // This ensures all API requests include device tracking parameters
        APIClient.shared.setCommonParamsProvider(CommonParamsProviderImpl.shared)
    }
}
