import Foundation
import FeatureAgendaApi
import LibraryNotification

/// Implementation of AgendaService
@MainActor
public final class AgendaServiceImpl: AgendaService {
    private let weatherService = WeatherService()
    private let liveActivityManager = LiveActivityManager.shared
    private var updateTimer: Timer?

    public init() {}

    // MARK: - AgendaService Protocol

    public func startAgenda() async throws {
        guard #available(iOS 16.1, *) else {
            throw AgendaError.notSupported
        }

        // Fetch initial data
        let weather = await weatherService.fetchWeatherSafely()
        let task = TaskGenerator.generateContextualTask()

        // Start live activity
        try await liveActivityManager.startAgendaActivity(
            userId: "current_user", // TODO: Get from auth service
            initialWeather: weather,
            initialTask: task
        )

        // Start periodic updates
        startPeriodicUpdates()
    }

    public func stopAgenda() async throws {
        guard #available(iOS 16.1, *) else {
            return
        }

        // Stop periodic updates
        stopPeriodicUpdates()

        // Stop live activity
        await liveActivityManager.stopAgendaActivity()
    }

    public var isAgendaActive: Bool {
        if #available(iOS 16.1, *) {
            return liveActivityManager.isAgendaActive
        }
        return false
    }

    public func updateAgenda(weather: String, task: String) async throws {
        guard #available(iOS 16.1, *) else {
            throw AgendaError.notSupported
        }

        try await liveActivityManager.updateAgendaActivity(
            weather: weather,
            task: task
        )
    }

    // MARK: - Periodic Updates

    private func startPeriodicUpdates() {
        // Stop existing timer if any
        stopPeriodicUpdates()

        // Create timer for 5-minute intervals
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 300, // 5 minutes = 300 seconds
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicUpdate()
            }
        }

        print("✅ Started periodic updates (every 5 minutes)")
    }

    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("✅ Stopped periodic updates")
    }

    private func performPeriodicUpdate() async {
        guard #available(iOS 16.1, *) else { return }
        guard liveActivityManager.isAgendaActive else {
            stopPeriodicUpdates()
            return
        }

        let weather = await weatherService.fetchWeatherSafely()
        let task = TaskGenerator.generateContextualTask()

        do {
            try await liveActivityManager.updateAgendaActivity(
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
