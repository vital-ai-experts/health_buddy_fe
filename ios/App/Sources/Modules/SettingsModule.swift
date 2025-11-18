// SettingsModule.swift
import Foundation
import SwiftUI
import LibraryServiceLoader
import FeatureAccountImpl
import FeatureAgendaApi

/// Settings module for routing registration
enum SettingsModule {
    /// Register settings-related routes
    /// - Parameter router: The router to register routes on
    static func registerRoutes(on router: RouteRegistering) {
        // Settings route: thrivebody://settings
        router.register(
            path: "/settings",
            defaultPresentation: .push
        ) { _ in
            AnyView(SettingsView())
        }

        // Agenda settings route: thrivebody://settings/agenda
        router.register(
            path: "/settings/agenda",
            defaultPresentation: .push
        ) { _ in
            if let agendaBuilder = ServiceManager.shared.resolveOptional(FeatureAgendaBuildable.self) {
                return AnyView(agendaBuilder.makeAgendaSettingsView())
            } else {
                return AnyView(
                    Text("Agenda settings not available")
                        .foregroundColor(.secondary)
                )
            }
        }

        // About route: thrivebody://about
        router.register(
            path: "/about",
            defaultPresentation: .push
        ) { _ in
            AnyView(AboutView())
        }
    }
}
