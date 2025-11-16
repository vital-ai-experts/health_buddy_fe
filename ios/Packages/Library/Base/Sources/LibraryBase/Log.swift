import Foundation
import OSLog

/// Log utility class that wraps os.Logger with convenient log level methods
///
/// Usage:
/// ```swift
/// Log.d("Development message")
/// Log.i("Informational message")
/// Log.w("Warning message")
/// Log.e("Error occurred")
/// ```
public enum Log {

    /// Logger subsystem identifier
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.thrivebody.app"

    /// Default logger instance
    private static let logger = Logger(subsystem: subsystem, category: "App")

    // MARK: - Public Logging Methods

    /// Logs a debug/development message (only visible in development builds)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs (defaults to "App")
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public static func d(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs an informational message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs (defaults to "App")
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public static func i(
        _ message: String,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(function) - \(message)")
    }

    /// Logs a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object to include in the log
    ///   - category: Optional category for organizing logs (defaults to "App")
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public static func w(
        _ message: String,
        error: Error? = nil,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            logger.warning("[\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            logger.warning("[\(fileName):\(line)] \(function) - \(message)")
        }
    }

    /// Logs an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - error: Optional error object to include in the log
    ///   - category: Optional category for organizing logs (defaults to "App")
    ///   - file: Source file (auto-populated)
    ///   - function: Function name (auto-populated)
    ///   - line: Line number (auto-populated)
    public static func e(
        _ message: String,
        error: Error? = nil,
        category: String = "App",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            logger.error("[\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            logger.error("[\(fileName):\(line)] \(function) - \(message)")
        }
    }
}
