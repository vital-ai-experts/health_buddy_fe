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
    
    /// Debug 控制台镜像开关（仅 DEBUG 生效）
    private static let mirrorToConsole = true

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
        let logger = makeLogger(category: category)
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(function) - \(message, privacy: .public)")
        mirror(message: message, level: "DEBUG", category: category)
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
        let logger = makeLogger(category: category)
        let fileName = (file as NSString).lastPathComponent
        logger.info("[\(fileName):\(line)] \(function) - \(message, privacy: .public)")
        mirror(message: message, level: "INFO", category: category)
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
        let logger = makeLogger(category: category)
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            logger.warning("[\(fileName):\(line)] \(function) - \(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
            mirror(message: "\(message): \(error.localizedDescription)", level: "WARN", category: category)
        } else {
            logger.warning("[\(fileName):\(line)] \(function) - \(message, privacy: .public)")
            mirror(message: message, level: "WARN", category: category)
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
        let logger = makeLogger(category: category)
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            logger.error("[\(fileName):\(line)] \(function) - \(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
            mirror(message: "\(message): \(error.localizedDescription)", level: "ERROR", category: category)
        } else {
            logger.error("[\(fileName):\(line)] \(function) - \(message, privacy: .public)")
            mirror(message: message, level: "ERROR", category: category)
        }
    }
    
    // MARK: - Helpers
    private static func makeLogger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
    
    /// 镜像到 Xcode 控制台（DEBUG 环境下），防止 Console.app 过滤看不到
    private static func mirror(message: String, level: String, category: String) {
        #if DEBUG
        guard mirrorToConsole else { return }
        print("[\(level)][\(category)] \(message)")
        #endif
    }
}
