//
//  HealthDomainBootstrap.swift
//  HealthDomain
//
//  Created by Codex on 2025/2/14.
//

import Foundation
import SwiftData
import LibraryServiceLoader

public enum HealthDomainBootstrap {
    @MainActor
    public static func configure(manager: ServiceManager = .shared) {
        let healthKitManager = HealthKitManager.shared
        let authorizationService = HealthKitAuthorizationService(healthKitManager: healthKitManager)
        let dataService = HealthKitDataService(healthKitManager: healthKitManager)

        manager.register(AuthorizationService.self) { authorizationService }
        manager.register(HealthDataService.self) { dataService }
    }
}

// MARK: - Authorization Service

@MainActor
final class HealthKitAuthorizationService: AuthorizationService {
    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    func currentStatus() async -> AuthorizationState {
        let status = await healthKitManager.authorizationStatus()
        return mapStatus(status)
    }

    func requestAuthorization() async throws -> AuthorizationState {
        try await healthKitManager.requestAuthorization()
        let status = await healthKitManager.authorizationStatus()
        let authState = mapStatus(status)

        // 授权成功后，启动后台同步并主动上报一次数据
        if authState == .authorized {
            Task {
                // 1. 启动后台数据同步监听
                HealthDataSyncService.shared.startBackgroundSync()

                // 2. 主动上报一次数据
                await HealthDataSyncService.shared.syncOnce()
            }
        }

        return authState
    }

    private func mapStatus(_ state: HealthKitManager.HealthKitAuthorizationState) -> AuthorizationState {
        switch state {
        case .unavailable:
            return .unavailable
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        }
    }
}

// MARK: - Health Data Service

@MainActor
final class HealthKitDataService: HealthDataService {
    private let healthKitManager: HealthKitManager

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    func fetchLatestSections() async throws -> [HealthDisplaySection] {
        let sections = try await healthKitManager.fetchRecentData()
        return sections.map { section in
            HealthDisplaySection(
                kind: mapKind(section.kind),
                title: section.title,
                rows: section.rows.map { HealthDisplayRow(headline: $0.headline, detail: $0.detail) },
                chartSeries: section.chartSeries.map(mapSeries(_:))
            )
        }
    }

    func persist(_ sections: [HealthDisplaySection], into context: ModelContext) throws {
        sections.forEach { section in
            let persistedSection = HealthSection(
                kind: SectionKind(rawValue: section.kind.rawValue) ?? .steps,
                title: section.title
            )

            section.rows.forEach { row in
                let persistedRow = HealthRow(headline: row.headline, detail: row.detail)
                persistedSection.rows.append(persistedRow)
            }

            context.insert(persistedSection)
        }

        try context.save()
    }

    func fetchRecentDataAsJSON() async throws -> String {
        return try await healthKitManager.fetchRecentDataAsJSON()
    }

    private func mapKind(_ kind: HealthKitManager.HealthDataSection.Kind) -> HealthDisplaySection.Kind {
        switch kind {
        case .steps:
            return .steps
        case .heartRate:
            return .heartRate
        case .activeEnergy:
            return .activeEnergy
        case .sleep:
            return .sleep
        // 其他所有新类型默认映射为 steps（仅用于兼容性，实际使用 JSON 接口）
        default:
            return .steps
        }
    }

    private func mapSeries(_ series: HealthKitManager.HealthDataSeries) -> HealthDisplaySeries {
        HealthDisplaySeries(
            id: mapSeriesIdentifier(series.id),
            title: series.title,
            unitTitle: series.unitTitle,
            points: series.points.map { HealthDisplayPoint(start: $0.start, end: $0.end, value: $0.value) }
        )
    }

    private func mapSeriesIdentifier(_ id: HealthKitManager.HealthDataSeries.Identifier) -> HealthDisplaySeries.Identifier {
        switch id {
        case .steps:
            return .steps
        case .heartRate:
            return .heartRate
        case .activeEnergy:
            return .activeEnergy
        case .sleep:
            return .sleep
        }
    }
}
