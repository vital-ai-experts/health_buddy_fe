import Foundation
import SwiftUI

/// 路由管理器，负责处理应用内路由跳转
@MainActor
public final class RouteManager: ObservableObject, RouteRegistering {
    public static let shared = RouteManager()

    /// 路由展示方式
    public enum RoutePresentation: Hashable, Equatable {
        case push
        case sheet
    }

    /// 解析 URL 后的上下文
    public struct RouteContext: Hashable, Equatable {
        public let url: URL
        public let scheme: String
        public let host: String?
        public let path: String
        public let queryItems: [String: String]
        public let presentationHint: RoutePresentation?

        public init(
            url: URL,
            scheme: String,
            host: String?,
            path: String,
            queryItems: [String: String],
            presentationHint: RoutePresentation?
        ) {
            self.url = url
            self.scheme = scheme
            self.host = host
            self.path = path
            self.queryItems = queryItems
            self.presentationHint = presentationHint
        }
    }

    /// 放在导航栈中的路由匹配
    public struct RouteMatch: Hashable, Identifiable {
        public let id = UUID()
        public let path: String
        public let context: RouteContext

        public init(path: String, context: RouteContext) {
            self.path = path
            self.context = context
        }
    }

    /// SwiftUI 构建信息
    public struct RouteEntry {
        public let defaultPresentation: RoutePresentation
        public let builder: (RouteContext) -> AnyView

        public init(
            defaultPresentation: RoutePresentation,
            builder: @escaping (RouteContext) -> AnyView
        ) {
            self.defaultPresentation = defaultPresentation
            self.builder = builder
        }
    }

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

    @Published public var path = NavigationPath()
    @Published public var activeSheet: RouteMatch?

    public var onLoginSuccess: (() -> Void)?
    public var onLogout: (() -> Void)?

    private var routeHandlers: [String: RouteHandler] = [:]
    private var viewRoutes: [String: RouteEntry] = [:]
    private let lock = NSLock()

    public init() {}

    /// 注册路由处理器
    /// - Parameters:
    ///   - path: 路由路径，例如 "/demo"
    ///   - handler: 路由处理闭包
    public func register(path: String, handler: @escaping RouteHandler) {
        lock.lock()
        defer { lock.unlock() }
        routeHandlers[path] = handler
    }

    /// 注册 SwiftUI 路由
    /// - Parameters:
    ///   - path: 逻辑路径
    ///   - defaultPresentation: 默认展示方式
    ///   - builder: 构建对应 View 的闭包
    public func register(
        path: String,
        defaultPresentation: RoutePresentation = .push,
        builder: @escaping (RouteContext) -> AnyView
    ) {
        lock.lock()
        viewRoutes[path] = RouteEntry(defaultPresentation: defaultPresentation, builder: builder)
        lock.unlock()
    }

    /// 处理 URL
    /// - Parameter url: 需要处理的 URL
    /// - Returns: 是否成功处理
    @discardableResult
    public func handle(url: URL) -> Bool {
        let context = parse(url: url)

        lock.lock()
        let hasViewRoute = viewRoutes[context.path] != nil
        var handler = routeHandlers[context.path]
        if handler == nil, let host = context.host {
            handler = routeHandlers[host] ?? routeHandlers["/\(host)"]
        }
        lock.unlock()

        if hasViewRoute {
            open(with: context)
            return true
        }

        if let handler = handler {
            let info = RouteInfo(
                scheme: context.scheme,
                host: context.host,
                path: context.path,
                queryItems: context.queryItems
            )
            handler(info)
            return true
        }

        return false
    }

    /// 打开 URL 对应的 SwiftUI 路由
    /// - Parameters:
    ///   - url: 目标 URL
    ///   - preferredPresentation: 期望的展示方式（可覆盖默认与 query 提示）
    public func open(url: URL, preferredPresentation: RoutePresentation? = nil) {
        let context = parse(url: url)
        open(with: context, preferredPresentation: preferredPresentation)
    }

    /// 根据匹配信息构建 View
    /// - Parameter match: 路由匹配信息
    /// - Returns: 对应的 AnyView
    public func buildView(for match: RouteMatch) -> AnyView {
        lock.lock()
        let entry = viewRoutes[match.path]
        lock.unlock()
        guard let entry = entry else {
            return AnyView(EmptyView())
        }
        return entry.builder(match.context)
    }

    public func handleLoginSuccess() {
        onLoginSuccess?()
        activeSheet = nil
    }

    public func handleLogoutRequested() {
        onLogout?()
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

    private func open(with context: RouteContext, preferredPresentation: RoutePresentation? = nil) {
        lock.lock()
        guard let entry = viewRoutes[context.path] else {
            lock.unlock()
            return
        }
        lock.unlock()

        let match = RouteMatch(path: context.path, context: context)
        let presentation = preferredPresentation ?? context.presentationHint ?? entry.defaultPresentation

        switch presentation {
        case .push:
            path.append(match)
        case .sheet:
            activeSheet = match
        }
    }

    private func parse(url: URL) -> RouteContext {
        let scheme = url.scheme ?? ""
        let host = url.host

        let path: String
        if let host = host {
            let components = [host] + url.pathComponents.filter { $0 != "/" }
            path = "/" + components.joined(separator: "/")
        } else {
            path = url.path.isEmpty ? "/" : url.path
        }

        var queryItems: [String: String] = [:]
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items {
                if let value = item.value {
                    queryItems[item.name] = value
                }
            }
        }

        let presentationHint: RoutePresentation?
        if let present = queryItems["present"]?.lowercased() {
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
            scheme: scheme,
            host: host,
            path: path,
            queryItems: queryItems,
            presentationHint: presentationHint
        )
    }
}

/// 给能注册路由的对象使用的协议
public protocol RouteRegistering {
    func register(
        path: String,
        defaultPresentation: RouteManager.RoutePresentation,
        builder: @escaping (RouteManager.RouteContext) -> AnyView
    )
}

public typealias RoutePresentation = RouteManager.RoutePresentation
public typealias RouteContext = RouteManager.RouteContext
public typealias RouteMatch = RouteManager.RouteMatch
