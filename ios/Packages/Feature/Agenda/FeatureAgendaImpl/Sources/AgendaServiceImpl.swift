import Foundation
import FeatureAgendaApi
import LibraryNotification

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
            print("📱 Restoring previously active Agenda...")
            do {
                try await startAgenda()
                print("✅ Agenda successfully restored")
            } catch {
                print("❌ Failed to restore Agenda: \(error)")
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

        // Fetch initial data
        let weather = await weatherService.fetchWeatherSafely()
        let task = TaskGenerator.generateContextualTask()

        // Start live activity
        try await LiveActivityManager.shared.startAgendaActivity(
            userId: "current_user", // TODO: Get from auth service
            initialWeather: weather,
            initialTask: task
        )

        // Save state for auto-restore
        UserDefaults.standard.set(true, forKey: agendaStateKey)
        print("💾 Agenda state saved")
        print("✅ Agenda started - updates will be pushed from server")
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
        print("💾 Agenda state cleared")
    }

    @MainActor
    public var isAgendaActive: Bool {
        if #available(iOS 16.1, *) {
            return LiveActivityManager.shared.isAgendaActive
        }
        return false
    }

    @MainActor
    public func updateAgenda(weather: String, task: String) async throws {
        guard #available(iOS 16.1, *) else {
            throw AgendaError.notSupported
        }

        try await LiveActivityManager.shared.updateAgendaActivity(
            weather: weather,
            task: task
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
