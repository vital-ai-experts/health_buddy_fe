import SwiftUI

/// Builder protocol for Agenda feature
public protocol FeatureAgendaBuildable {
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

    /// Update the agenda with new task data
    func updateAgenda(weather: String, task: String) async throws
}
