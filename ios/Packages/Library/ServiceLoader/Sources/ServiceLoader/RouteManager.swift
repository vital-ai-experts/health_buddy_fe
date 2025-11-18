import Foundation
import SwiftUI

/// 路由管理器，负责处理应用内路由跳转
public final class RouteManager: ObservableObject {
    public static let shared = RouteManager()

    /// 路由处理闭包类型
    public typealias RouteHandler = (RouteInfo) -> Void

    /// 路由信息结构
    public struct RouteInfo {
        public let scheme: String
        public let host: String?
        public let path: String
        public let queryItems: [String: String]

        public init(scheme: String, host: String?, path: String, queryItems: [String: String]) {
            self.scheme = scheme
            self.host = host
            self.path = path
            self.queryItems = queryItems
        }
    }

    /// Route entry with view builder
    public struct RouteEntry {
        public let defaultPresentation: RoutePresentation
        public let builder: (RouteContext) -> AnyView

        public init(defaultPresentation: RoutePresentation, builder: @escaping (RouteContext) -> AnyView) {
            self.defaultPresentation = defaultPresentation
            self.builder = builder
        }
    }

    // MARK: - Navigation State
    /// Navigation path for SwiftUI NavigationStack
    @Published public var navigationPath = NavigationPath()

    /// Active sheet route
    @Published public var activeSheet: RouteMatch?

    // MARK: - Private Storage
    private var routeHandlers: [String: RouteHandler] = [:]
    private var viewRoutes: [String: RouteEntry] = [:]
    private let lock = NSLock()

    private init() {}
    
    /// 注册路由处理器
    /// - Parameters:
    ///   - path: 路由路径，例如 "/demo"
    ///   - handler: 路由处理闭包
    public func register(path: String, handler: @escaping RouteHandler) {
        lock.lock()
        defer { lock.unlock() }
        routeHandlers[path] = handler
    }
    
    /// 处理 URL
    /// - Parameter url: 需要处理的 URL
    /// - Returns: 是否成功处理
    @discardableResult
    public func handle(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        let scheme = components.scheme ?? ""
        let host = components.host
        let path = components.path.isEmpty ? "/" : components.path
        
        // 解析查询参数
        var queryItems: [String: String] = [:]
        if let items = components.queryItems {
            for item in items {
                queryItems[item.name] = item.value ?? ""
            }
        }
        
        let routeInfo = RouteInfo(
            scheme: scheme,
            host: host,
            path: path,
            queryItems: queryItems
        )
        
        lock.lock()
        // 尝试匹配 path，如果失败则尝试匹配 host
        var handler = routeHandlers[path]
        if handler == nil, let host = host {
            handler = routeHandlers[host]
        }
        // 也尝试 "/host" 格式
        if handler == nil, let host = host {
            handler = routeHandlers["/\(host)"]
        }
        lock.unlock()
        
        if let handler = handler {
            handler(routeInfo)
            return true
        }
        
        return false
    }
    
    /// 构建 URL
    /// - Parameters:
    ///   - scheme: URL scheme，例如 "playany"
    ///   - host: 主机名（可选）
    ///   - path: 路径，例如 "/demo"
    ///   - queryItems: 查询参数
    /// - Returns: 构建的 URL
    public func buildURL(
        scheme: String = "playany",
        host: String? = nil,
        path: String,
        queryItems: [String: String] = [:]
    ) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems.map { 
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        return components.url
    }
}

// MARK: - RouteRegistering Protocol Conformance
extension RouteManager: RouteRegistering {
    public func register(
        path: String,
        defaultPresentation: RoutePresentation = .push,
        builder: @escaping (RouteContext) -> AnyView
    ) {
        lock.lock()
        defer { lock.unlock() }
        viewRoutes[path] = RouteEntry(
            defaultPresentation: defaultPresentation,
            builder: builder
        )
    }
}

// MARK: - Navigation API
extension RouteManager {

    /// Open a URL with optional presentation override
    public func open(url: URL, preferredPresentation: RoutePresentation? = nil) {
        let context = parseForNavigation(url: url)

        // Special handling: if path is "/main", don't navigate (already on main screen)
        if context.path == "/main" {
            return
        }

        lock.lock()
        guard let entry = viewRoutes[context.path] else {
            lock.unlock()
            print("[RouteManager] No view route registered for path: \(context.path)")
            // Fallback to legacy handler
            _ = handle(url: url)
            return
        }
        lock.unlock()

        let match = RouteMatch(path: context.path, context: context)

        let presentation =
            preferredPresentation
            ?? context.presentationHint
            ?? entry.defaultPresentation

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch presentation {
            case .push:
                self.navigationPath.append(match)
            case .sheet:
                self.activeSheet = match
            }
        }
    }

    /// Build view for a given route match
    public func buildView(for match: RouteMatch) -> AnyView {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = viewRoutes[match.path] else {
            return AnyView(EmptyView())
        }
        return entry.builder(match.context)
    }

    /// Dismiss the active sheet
    public func dismissSheet() {
        DispatchQueue.main.async { [weak self] in
            self?.activeSheet = nil
        }
    }

    /// Navigate back in the navigation stack
    public func navigateBack() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.navigationPath.isEmpty else { return }
            self.navigationPath.removeLast()
        }
    }

    /// Pop to root of navigation stack
    public func popToRoot() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.navigationPath.removeLast(self.navigationPath.count)
        }
    }

    // MARK: - URL Parsing for Navigation
    private func parseForNavigation(url: URL) -> RouteContext {
        // Convert host + path to logical path, e.g., thrivebody://user/profile -> /user/profile
        let path: String
        if let host = url.host {
            let components = [host] + url.pathComponents.filter { $0 != "/" }
            path = "/" + components.joined(separator: "/")
        } else {
            path = url.path.isEmpty ? "/" : url.path
        }

        // Parse query parameters to [String: String]
        var query: [String: String] = [:]
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items {
                if let value = item.value {
                    query[item.name] = value
                }
            }
        }

        // Parse presentation hint from ?present=sheet/push
        let presentationHint: RoutePresentation?
        if let present = query["present"]?.lowercased() {
            switch present {
            case "sheet":
                presentationHint = .sheet
            case "push":
                presentationHint = .push
            default:
                presentationHint = nil
            }
        } else {
            presentationHint = nil
        }

        return RouteContext(
            url: url,
            path: path,
            query: query,
            presentationHint: presentationHint
        )
    }
}

