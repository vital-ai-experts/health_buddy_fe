import Foundation
import SwiftUI

/// 路由管理器，负责处理应用内路由跳转
@MainActor
public final class RouteManager: ObservableObject, RouteRegistering {
    public static let shared = RouteManager()

    /// 路由展示层级（Surface）
    public enum RouteSurface: Hashable, Equatable {
        case tab        // 在当前 tab 的 NavigationStack 中展示
        case sheet      // 以 sheet 形式展示
        case fullscreen // 以全屏形式展示
    }

    /// 解析 URL 后的上下文
    public struct RouteContext: Hashable, Equatable {
        public let url: URL
        public let scheme: String
        public let host: String?
        public let path: String
        public let queryItems: [String: String]
        public let surfaceHint: RouteSurface?

        public init(
            url: URL,
            scheme: String,
            host: String?,
            path: String,
            queryItems: [String: String],
            surfaceHint: RouteSurface?
        ) {
            self.url = url
            self.scheme = scheme
            self.host = host
            self.path = path
            self.queryItems = queryItems
            self.surfaceHint = surfaceHint
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
        public let defaultSurface: RouteSurface
        public let builder: (RouteContext) -> AnyView

        public init(
            defaultSurface: RouteSurface,
            builder: @escaping (RouteContext) -> AnyView
        ) {
            self.defaultSurface = defaultSurface
            self.builder = builder
        }
    }

    // 为每个 tab 维护独立的导航路径
    @Published public var chatPath = NavigationPath()
    @Published public var profilePath = NavigationPath()
    @Published public var currentTab: Tab = .chat {
        didSet {
            print("[RouteManager] 📍 Current tab changed to: \(currentTab)")
        }
    }

    @Published public var activeSheet: RouteMatch?
    @Published public var activeFullscreen: RouteMatch?
    @Published public var pendingChatMessage: String?

    public var onLoginSuccess: (() -> Void)?
    public var onLogout: (() -> Void)?

    private var viewRoutes: [String: RouteEntry] = [:]
    private let lock = NSLock()

    public enum Tab {
        case chat
        case agenda
        case profile
    }

    public init() {}

    /// 注册 SwiftUI 路由
    /// - Parameters:
    ///   - path: 逻辑路径
    ///   - defaultSurface: 默认展示层级
    ///   - builder: 构建对应 View 的闭包
    public func register(
        path: String,
        defaultSurface: RouteSurface = .tab,
        builder: @escaping (RouteContext) -> AnyView
    ) {
        lock.lock()
        viewRoutes[path] = RouteEntry(defaultSurface: defaultSurface, builder: builder)
        lock.unlock()
    }

    /// 打开 URL 对应的 SwiftUI 路由
    /// - Parameters:
    ///   - url: 目标 URL
    ///   - on: 期望的展示层级（可覆盖默认与 query 提示）
    public func open(url: URL, on surface: RouteSurface? = nil) {
        let context = parse(url: url)
        open(with: context, on: surface)
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
        activeFullscreen = nil
    }

    public func handleLogoutRequested() {
        onLogout?()
    }

    /// 预置一条待发送的聊天消息
    public func enqueueChatMessage(_ message: String) {
        pendingChatMessage = message
    }

    /// 消费已处理的待发送聊天消息
    public func clearPendingChatMessage(_ message: String) {
        if pendingChatMessage == message {
            pendingChatMessage = nil
        }
    }

    /// 构建 URL
    /// - Parameters:
    ///   - scheme: URL scheme，例如 "thrivebody"
    ///   - host: 主机名（可选）
    ///   - path: 路径，例如 "/settings"
    ///   - queryItems: 查询参数
    /// - Returns: 构建的 URL
    public func buildURL(
        scheme: String = "thrivebody",
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

    private func open(with context: RouteContext, on surface: RouteSurface? = nil) {
        lock.lock()
        guard let entry = viewRoutes[context.path] else {
            lock.unlock()
            print("[RouteManager] ⚠️ No route registered for path: \(context.path)")
            return
        }
        lock.unlock()

        let match = RouteMatch(path: context.path, context: context)
        let targetSurface = surface ?? context.surfaceHint ?? entry.defaultSurface

        switch targetSurface {
        case .tab:
            // 根据当前 tab 往对应的 path 中 append
            switch currentTab {
            case .chat:
                print("[RouteManager] 🚀 open: \(context.path) on Chat tab, current path.count = \(chatPath.count)")
                chatPath.append(match)
            case .agenda:
                print("[RouteManager] 🚀 open: \(context.path) on Agenda tab")
                // Agenda tab 暂时不支持导航
            case .profile:
                print("[RouteManager] 🚀 open: \(context.path) on Profile tab, current path.count = \(profilePath.count)")
                profilePath.append(match)
            }
        case .sheet:
            print("[RouteManager] 📄 Showing on sheet surface")
            activeSheet = match
        case .fullscreen:
            print("[RouteManager] 🖥️ Showing on fullscreen surface")
            activeFullscreen = match
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

        let surfaceHint: RouteSurface?
        if let present = queryItems["present"]?.lowercased() {
            switch present {
            case "tab":
                surfaceHint = .tab
            case "sheet":
                surfaceHint = .sheet
            case "fullscreen":
                surfaceHint = .fullscreen
            default:
                surfaceHint = nil
            }
        } else {
            surfaceHint = nil
        }

        return RouteContext(
            url: url,
            scheme: scheme,
            host: host,
            path: path,
            queryItems: queryItems,
            surfaceHint: surfaceHint
        )
    }
}

/// 给能注册路由的对象使用的协议
public protocol RouteRegistering {
    func register(
        path: String,
        defaultSurface: RouteManager.RouteSurface,
        builder: @escaping (RouteManager.RouteContext) -> AnyView
    )
}

public typealias RouteSurface = RouteManager.RouteSurface
public typealias RouteContext = RouteManager.RouteContext
public typealias RouteMatch = RouteManager.RouteMatch
