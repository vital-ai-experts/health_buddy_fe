//
//  NetworkingBootstrap.swift
//  LibraryNetworking
//
//  Bootstrap configuration for networking layer
//

import Foundation

/// Bootstrap configuration for the Networking library
@MainActor
public enum NetworkingBootstrap {
    /// Configure the networking layer with required providers
    /// - Parameter commonParamsProvider: Provider for common query parameters (region, language, device_id, etc.)
    public static func configure(commonParamsProvider: CommonParamsProvider) {
        APIClient.shared.setCommonParamsProvider(commonParamsProvider)
    }
}
