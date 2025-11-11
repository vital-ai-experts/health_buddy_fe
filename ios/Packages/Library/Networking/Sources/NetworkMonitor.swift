import Foundation
import Network

/// Network connectivity monitor
/// Monitors network status changes and provides real-time updates
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.high.ThriveBuddy.NetworkMonitor")

    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var connectionType: ConnectionType = .unknown

    public enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    /// Start monitoring network status
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let isConnected = path.status == .satisfied
            let connectionType = self.getConnectionType(from: path)

            DispatchQueue.main.async {
                self.isConnected = isConnected
                self.connectionType = connectionType

                if isConnected {
                    print("✅ [NetworkMonitor] Network connected: \(connectionType)")
                } else {
                    print("❌ [NetworkMonitor] Network disconnected")
                }
            }
        }

        monitor.start(queue: queue)
        print("🔍 [NetworkMonitor] Started monitoring network status")
    }

    /// Stop monitoring network status
    public func stopMonitoring() {
        monitor.cancel()
        print("⏹️ [NetworkMonitor] Stopped monitoring network status")
    }

    /// Wait for network to become available
    /// - Parameter timeout: Maximum wait time in seconds (default: 30)
    /// - Returns: true if network became available within timeout, false otherwise
    public func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        // If already connected, return immediately
        if isConnected {
            return true
        }

        let startTime = Date()

        // Wait for connection with timeout
        while !isConnected {
            // Check timeout
            if Date().timeIntervalSince(startTime) > timeout {
                print("⏱️ [NetworkMonitor] Connection wait timeout after \(timeout)s")
                return false
            }

            // Wait 0.1 seconds before checking again
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        print("✅ [NetworkMonitor] Connection established after \(Date().timeIntervalSince(startTime))s")
        return true
    }

    // MARK: - Private Methods

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}
