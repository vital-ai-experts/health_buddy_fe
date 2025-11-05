//
//  ServiceContracts.swift
//  HealthDomain
//
//  Created by Codex on 2025/2/14.
//

import Foundation
import SwiftData
import LibraryServiceLoader

/// 健康权限状态，对应 Feature 层的授权路由。
public enum AuthorizationState: Equatable {
    case unavailable
    case notDetermined
    case denied
    case authorized
}

/// 健康数据展示模型，用于 Feature 层展示与 SwiftData 持久化。
public struct HealthDisplaySection: Identifiable, Equatable {
    public enum Kind: Int {
        case steps
        case heartRate
        case activeEnergy
        case sleep
    }

    public var id: Kind { kind }
    public let kind: Kind
    public let title: String
    public let rows: [HealthDisplayRow]
    public let chartSeries: [HealthDisplaySeries]

    public init(kind: Kind, title: String, rows: [HealthDisplayRow], chartSeries: [HealthDisplaySeries] = []) {
        self.kind = kind
        self.title = title
        self.rows = rows
        self.chartSeries = chartSeries
    }
}

public struct HealthDisplayRow: Identifiable, Equatable {
    public let id = UUID()
    public let headline: String
    public let detail: String

    public init(headline: String, detail: String) {
        self.headline = headline
        self.detail = detail
    }
}

public struct HealthDisplaySeries: Identifiable, Equatable {
    public enum Identifier: Hashable {
        case steps
        case heartRate
        case activeEnergy
        case sleep
    }

    public let id: Identifier
    public let title: String
    public let unitTitle: String
    public let points: [HealthDisplayPoint]

    public init(id: Identifier, title: String, unitTitle: String, points: [HealthDisplayPoint]) {
        self.id = id
        self.title = title
        self.unitTitle = unitTitle
        self.points = points
    }
}

public struct HealthDisplayPoint: Equatable {
    public let start: Date
    public let end: Date
    public let value: Double

    public init(start: Date, end: Date, value: Double) {
        self.start = start
        self.end = end
        self.value = value
    }
}

@MainActor
public protocol AuthorizationService {
    func currentStatus() async -> AuthorizationState
    func requestAuthorization() async throws -> AuthorizationState
}

@MainActor
public protocol HealthDataService {
    func fetchLatestSections() async throws -> [HealthDisplaySection]
    func persist(_ sections: [HealthDisplaySection], into context: ModelContext) throws
}
