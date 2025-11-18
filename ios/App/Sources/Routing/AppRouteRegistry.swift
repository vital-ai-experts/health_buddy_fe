// AppRouteRegistry.swift
import Foundation
import LibraryServiceLoader

/// Central registry that configures all module routes
enum AppRouteRegistry {
    static func configure(router: RouteRegistering) {
        // Account module routes (login, register, account settings)
        AccountModule.registerRoutes(on: router)

        // Settings module routes (settings, agenda settings, about)
        SettingsModule.registerRoutes(on: router)

        #if DEBUG
        // Debug tools routes (only in DEBUG builds)
        DebugToolsFeatureModule.registerRoutes(on: router)
        #endif

        // Add more module registrations here as needed
        // ChatModule.registerRoutes(on: router)
        // HealthModule.registerRoutes(on: router)
    }
}
