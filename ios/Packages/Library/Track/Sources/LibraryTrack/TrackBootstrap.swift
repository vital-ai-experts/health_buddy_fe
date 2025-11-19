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
    public static func configure() {
        APIClient.shared.setCommonParamsProvider(CommonParamsProviderImpl.shared)
    }
}
