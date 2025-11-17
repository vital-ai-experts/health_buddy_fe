import Foundation
import FeatureAgendaApi
import LibraryNotification
import LibraryBase

/// Implementation of AgendaService
public final class AgendaServiceImpl: AgendaService {
    private let weatherService = WeatherService()

    // UserDefaults key for persisting agenda state
    private let agendaStateKey = "com.thrivebody.agenda.isActive"

    public init() {}

    /// Check if agenda was previously active and restart if needed
    @MainActor
    public func restoreAgendaIfNeeded() async {
        let wasActive = UserDefaults.standard.bool(forKey: agendaStateKey)

        if wasActive {
            Log.i("📱 Restoring previously active Agenda...", category: "Agenda")
            do {
                try await startAgenda()
                Log.i("✅ Agenda successfully restored", category: "Agenda")
            } catch {
                Log.e("❌ Failed to restore Agenda: \(error)", category: "Agenda")
                // Clear the flag if restoration fails
                UserDefaults.standard.set(false, forKey: agendaStateKey)
            }
        }
    }

    // MARK: - AgendaService Protocol

    @MainActor
    public func startAgenda() async throws {
        guard #available(iOS 16.1, *) else {
            throw AgendaError.notSupported
        }

        // Start live activity with default values
        try await LiveActivityManager.shared.startAgendaActivity(
            userId: "current_user" // TODO: Get from auth service
        )

        // Save state for auto-restore
        UserDefaults.standard.set(true, forKey: agendaStateKey)
        Log.i("💾 Agenda state saved", category: "Agenda")
        Log.i("✅ Agenda started - updates will be pushed from server", category: "Agenda")
    }

    @MainActor
    public func stopAgenda() async throws {
        guard #available(iOS 16.1, *) else {
            return
        }

        // Stop live activity
        await LiveActivityManager.shared.stopAgendaActivity()

        // Clear saved state
        UserDefaults.standard.set(false, forKey: agendaStateKey)
        Log.i("💾 Agenda state cleared", category: "Agenda")
    }

    @MainActor
    public var isAgendaActive: Bool {
        if #available(iOS 16.1, *) {
            return LiveActivityManager.shared.isAgendaActive
        }
        return false
    }

    @MainActor
    public func updateAgenda(title: String, text: String) async throws {
        guard #available(iOS 16.1, *) else {
            throw AgendaError.notSupported
        }

        try await LiveActivityManager.shared.updateAgendaActivity(
            title: title,
            text: text
        )
    }
}

enum AgendaError: LocalizedError {
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Live Activities are not supported on this iOS version (requires iOS 16.1+)"
        }
    }
}
