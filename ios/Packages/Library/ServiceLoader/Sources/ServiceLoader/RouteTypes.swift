// RouteTypes.swift
import SwiftUI

/// Routing presentation mode: push or sheet
public enum RoutePresentation {
    case push
    case sheet
}

/// Context after parsing URL for navigation routes
public struct RouteContext {
    public let url: URL
    public let path: String          // Logical path, e.g., /user/profile
    public let query: [String: String]
    public let presentationHint: RoutePresentation?   // Parsed from URL query param (e.g., ?present=sheet)

    public init(url: URL, path: String, query: [String: String], presentationHint: RoutePresentation?) {
        self.url = url
        self.path = path
        self.query = query
        self.presentationHint = presentationHint
    }
}

/// Route match stored in NavigationPath / sheet
public struct RouteMatch: Hashable, Identifiable {
    public let id = UUID()
    public let path: String
    public let context: RouteContext

    public init(path: String, context: RouteContext) {
        self.path = path
        self.context = context
    }

    // Custom Hashable implementation since RouteContext contains URL which is not Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path)
    }

    public static func == (lhs: RouteMatch, rhs: RouteMatch) -> Bool {
        lhs.id == rhs.id && lhs.path == rhs.path
    }
}

/// Protocol for route registration with view builders
public protocol RouteRegistering {
    func register(
        path: String,
        defaultPresentation: RoutePresentation,
        builder: @escaping (RouteContext) -> AnyView
    )
}
