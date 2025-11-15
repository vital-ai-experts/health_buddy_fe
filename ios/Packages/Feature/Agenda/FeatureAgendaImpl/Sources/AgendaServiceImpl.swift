import Foundation
import FeatureAgendaApi
import LibraryNotification

/// Implementation of AgendaService
public final class AgendaServiceImpl: AgendaService {
    private let weatherService = WeatherService()
    private var updateTimer: Timer?

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

        // Start periodic updates
        startPeriodicUpdates()

        // Save state for auto-restore
        UserDefaults.standard.set(true, forKey: agendaStateKey)
        print("💾 Agenda state saved")
    }

    @MainActor
    public func stopAgenda() async throws {
        guard #available(iOS 16.1, *) else {
            return
        }

        // Stop periodic updates
        stopPeriodicUpdates()

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

    // MARK: - Periodic Updates

    @MainActor
    private func startPeriodicUpdates() {
        // Stop existing timer if any
        stopPeriodicUpdates()

        // Create timer for 10-second intervals
        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicUpdate()
            }
        }

        // Add timer to RunLoop with .common mode to ensure it fires even during UI interactions
        RunLoop.main.add(timer, forMode: .common)
        updateTimer = timer

        print("✅ Started periodic updates (every 10 seconds)")
    }

    @MainActor
    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("✅ Stopped periodic updates")
    }

    @MainActor
    private func performPeriodicUpdate() async {
        guard #available(iOS 16.1, *) else { return }
        guard LiveActivityManager.shared.isAgendaActive else {
            stopPeriodicUpdates()
            return
        }

        let weather = await weatherService.fetchWeatherSafely()
        let task = TaskGenerator.generateContextualTask()

        do {
            try await LiveActivityManager.shared.updateAgendaActivity(
                weather: weather,
                task: task
            )
            print("✅ Periodic update completed: \(task)")
        } catch {
            print("❌ Failed to perform periodic update: \(error)")
        }
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
