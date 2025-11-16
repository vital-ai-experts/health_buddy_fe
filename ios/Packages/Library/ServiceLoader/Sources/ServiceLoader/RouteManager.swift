import Foundation

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
    
    
    private var routeHandlers: [String: RouteHandler] = [:]
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

