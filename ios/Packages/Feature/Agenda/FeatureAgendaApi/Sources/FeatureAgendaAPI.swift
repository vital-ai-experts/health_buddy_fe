import SwiftUI

/// Builder protocol for Agenda feature
public protocol FeatureAgendaBuildable {
    /// Build the agenda tab view for the main tab bar
    /// - Returns: The agenda tab view
    func makeAgendaTabView() -> AnyView

    /// Build the agenda settings view where users can start/stop the live activity
    /// - Returns: The agenda settings view
    func makeAgendaSettingsView() -> AnyView
}

/// Service protocol for managing Agenda Live Activity
public protocol AgendaService {
    /// Start the agenda live activity
    func startAgenda() async throws

    /// Stop the agenda live activity
    func stopAgenda() async throws

    /// Check if agenda is currently active
    var isAgendaActive: Bool { get }

    /// Update the agenda with new data
    func updateAgenda(title: String, text: String) async throws

    /// Restore agenda if it was previously active (called on app launch)
    func restoreAgendaIfNeeded() async
}
