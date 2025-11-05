//
//  HealthDataModels.swift
//  PlayAnything
//
//  Created by High on 2025/9/19.
//

import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
public final class HealthSection {
    public var kind: SectionKind
    public var title: String
    @Relationship(deleteRule: .cascade) public var rows: [HealthRow]
    public var createdAt: Date

    public init(kind: SectionKind, title: String, rows: [HealthRow] = []) {
        self.kind = kind
        self.title = title
        self.rows = rows
        self.createdAt = Date()
    }
}

@Model
public final class HealthRow {
    public var headline: String
    public var detail: String
    public var recordedAt: Date
    public var createdAt: Date

    public init(headline: String, detail: String, recordedAt: Date = Date()) {
        self.headline = headline
        self.detail = detail
        self.recordedAt = recordedAt
        self.createdAt = Date()
    }
}

// 使用枚举来定义类型
public enum SectionKind: Int, Codable, CaseIterable {
    case steps = 0
    case heartRate = 1
    case activeEnergy = 2
    case sleep = 3
    
    public var displayName: String {
        switch self {
        case .steps: return "步数"
        case .heartRate: return "心率"
        case .activeEnergy: return "主动能量"
        case .sleep: return "睡眠"
        }
    }

    public var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .heartRate: return "heart.fill"
        case .activeEnergy: return "flame.fill"
        case .sleep: return "bed.double.fill"
        }
    }
}
