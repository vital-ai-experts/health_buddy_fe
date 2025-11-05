//
//  HealthKitManager.swift
//  PlayAnything
//
//  Created by High on 2025/9/17.
//

import Foundation
import HealthKit

/// 负责与 HealthKit 交互的底层客户端，提供授权与数据拉取能力。
public final class HealthKitManager {
    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "MM-dd"
        return formatter
    }()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private let readTypes: Set<HKObjectType> = {
        var set = Set<HKObjectType>()
        if let t = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .appleStandHour) { set.insert(t) }
        return set
    }()

    private let writeTypes = Set<HKSampleType>()

    public init() {}
}

// MARK: - Authorization

public extension HealthKitManager {
    /// 当前 HealthKit 授权状态快照
    func authorizationStatus() async -> HealthKitAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        do {
            let status = try await requestStatusForAuthorization()
            switch status {
            case .shouldRequest, .unknown:
                return .notDetermined
            case .unnecessary:
                return .authorized
            @unknown default:
                return .authorized
            }
        } catch {
            return .authorized
        }
    }

    /// 请求 HealthKit 授权
    @discardableResult
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw makeError("此设备不支持 HealthKit。")
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        return true
    }
}

// MARK: - Data Fetching

public extension HealthKitManager {
    /// 获取最近24小时的健康数据
    func fetchRecentData() async throws -> [HealthDataSection] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw makeError("此设备不支持 HealthKit。")
        }

        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -1, to: end) else {
            throw makeError("无法计算时间范围")
        }

        var sections: [HealthDataSection] = []

        await withTaskGroup(of: HealthDataSection?.self) { group in
            // 获取步数（按小时聚合）
            if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        let statistics = try await self.fetchHourlyStatistics(type: stepsType, start: start, end: end, unit: .count())

                        let rows = statistics.isEmpty
                            ? [HealthDataRow(headline: "暂无数据", detail: "最近24小时内未记录步数。")]
                            : statistics.prefix(5).map { stat in
                                let steps = Int(stat.value)
                                return HealthDataRow(headline: "\(steps) 步", detail: self.intervalLabel(start: stat.start, end: stat.end))
                            }

                        let chartSeries = statistics.isEmpty
                            ? []
                            : [HealthDataSeries(
                                id: .steps,
                                title: "步数",
                                unitTitle: "步",
                                points: statistics.map { stat in
                                    HealthDataPoint(
                                        start: stat.start,
                                        end: stat.end,
                                        value: stat.value
                                    )
                                }
                            )]

                        return HealthDataSection(kind: .steps, title: "步数（最近24小时）", rows: rows, chartSeries: chartSeries)
                    } catch {
                        return HealthDataSection(
                            kind: .steps,
                            title: "步数（最近24小时）",
                            rows: [HealthDataRow(headline: "无法读取", detail: error.localizedDescription)],
                            chartSeries: []
                        )
                    }
                }
            }

            // 获取心率（按小时聚合平均值）
            if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        let statistics = try await self.fetchHourlyStatistics(type: heartRateType, start: start, end: end, unit: bpmUnit, options: .discreteAverage)

                        let rows = statistics.isEmpty
                            ? [HealthDataRow(headline: "暂无数据", detail: "最近24小时内未记录心率。")]
                            : statistics.prefix(5).map { stat in
                                let bpm = Int(round(stat.value))
                                return HealthDataRow(headline: "\(bpm) 次/分", detail: self.intervalLabel(start: stat.start, end: stat.end))
                            }

                        let chartSeries = statistics.isEmpty
                            ? []
                            : [HealthDataSeries(
                                id: .heartRate,
                                title: "心率",
                                unitTitle: "次/分",
                                points: statistics.map { stat in
                                    HealthDataPoint(
                                        start: stat.start,
                                        end: stat.end,
                                        value: stat.value
                                    )
                                }
                            )]

                        return HealthDataSection(kind: .heartRate, title: "心率（最近24小时）", rows: rows, chartSeries: chartSeries)
                    } catch {
                        return HealthDataSection(
                            kind: .heartRate,
                            title: "心率（最近24小时）",
                            rows: [HealthDataRow(headline: "无法读取", detail: error.localizedDescription)],
                            chartSeries: []
                        )
                    }
                }
            }

            // 获取主动能量（按小时聚合）
            if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        let statistics = try await self.fetchHourlyStatistics(type: energyType, start: start, end: end, unit: .kilocalorie())

                        let rows = statistics.isEmpty
                            ? [HealthDataRow(headline: "暂无数据", detail: "最近24小时内未记录主动能量。")]
                            : statistics.prefix(5).map { stat in
                                return HealthDataRow(headline: String(format: "%.1f 千卡", stat.value), detail: self.intervalLabel(start: stat.start, end: stat.end))
                            }

                        let chartSeries = statistics.isEmpty
                            ? []
                            : [HealthDataSeries(
                                id: .activeEnergy,
                                title: "主动能量",
                                unitTitle: "千卡",
                                points: statistics.map { stat in
                                    HealthDataPoint(
                                        start: stat.start,
                                        end: stat.end,
                                        value: stat.value
                                    )
                                }
                            )]

                        return HealthDataSection(kind: .activeEnergy, title: "主动能量（最近24小时）", rows: rows, chartSeries: chartSeries)
                    } catch {
                        return HealthDataSection(
                            kind: .activeEnergy,
                            title: "主动能量（最近24小时）",
                            rows: [HealthDataRow(headline: "无法读取", detail: error.localizedDescription)],
                            chartSeries: []
                        )
                    }
                }
            }

            // 获取睡眠分析
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    do {
                        let samples = try await self.fetchCategorySamples(type: sleepType, start: start, end: end, limit: 100)
                        let rows = samples.isEmpty
                            ? [HealthDataRow(headline: "暂无数据", detail: "最近24小时未记录睡眠。")]
                            : samples.prefix(5).map { sample in
                                HealthDataRow(headline: self.sleepLabel(for: sample.value), detail: self.intervalLabel(start: sample.startDate, end: sample.endDate))
                            }

                        // 为睡眠生成图表数据（将睡眠阶段转换为数值）
                        let chartSeries: [HealthDataSeries] = samples.isEmpty
                            ? []
                            : [HealthDataSeries(
                                id: .sleep,
                                title: "睡眠阶段",
                                unitTitle: "",
                                points: samples.map { sample in
                                    // 将睡眠阶段映射到数值：深睡=3, 浅睡=2, 快速眼动=2.5, 在床=1, 清醒=0.5
                                    let value: Double
                                    switch sample.value {
                                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                                        value = 3.0
                                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                                        value = 2.5
                                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                                        value = 2.0
                                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                                        value = 1.0
                                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                                        value = 0.5
                                    default:
                                        value = 0
                                    }
                                    return HealthDataPoint(
                                        start: sample.startDate,
                                        end: sample.endDate,
                                        value: value
                                    )
                                }
                            )]

                        return HealthDataSection(kind: .sleep, title: "睡眠（最近24小时）", rows: rows, chartSeries: chartSeries)
                    } catch {
                        return HealthDataSection(
                            kind: .sleep,
                            title: "睡眠（最近24小时）",
                            rows: [HealthDataRow(headline: "无法读取", detail: error.localizedDescription)],
                            chartSeries: []
                        )
                    }
                }
            }

            for await section in group {
                if let section {
                    sections.append(section)
                }
            }
        }

        sections.sort { $0.kind.rawValue < $1.kind.rawValue }

        if sections.isEmpty {
            throw makeError("最近24小时未检索到可展示的数据。")
        }

        return sections
    }
}

// MARK: - Helpers

private extension HealthKitManager {
    func intervalLabel(start: Date, end: Date) -> String {
        let startDay = dayFormatter.string(from: start)
        let startTime = timeFormatter.string(from: start)
        let endDay = dayFormatter.string(from: end)
        let endTime = timeFormatter.string(from: end)

        if Calendar.current.isDate(start, inSameDayAs: end) {
            return "\(startDay) \(startTime) - \(endTime)"
        } else {
            return "\(startDay) \(startTime) ~ \(endDay) \(endTime)"
        }
    }

    func sleepLabel(for value: Int) -> String {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue: return "在床"
        case HKCategoryValueSleepAnalysis.asleepCore.rawValue: return "浅睡"
        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue: return "深睡"
        case HKCategoryValueSleepAnalysis.asleepREM.rawValue: return "快速眼动"
        case HKCategoryValueSleepAnalysis.awake.rawValue: return "清醒"
        default: return "其他（\(value)）"
        }
    }

    struct HourlyStatistic {
        let start: Date
        let end: Date
        let value: Double
    }

    func fetchHourlyStatistics(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        options: HKStatisticsOptions = .cumulativeSum
    ) async throws -> [HourlyStatistic] {
        // 对齐到整点
        let calendar = Calendar.current
        guard let alignedStart = calendar.date(bySetting: .minute, value: 0, of: start),
              let alignedStartWithSecond = calendar.date(bySetting: .second, value: 0, of: alignedStart) else {
            throw makeError("无法对齐时间")
        }

        let anchorDate = alignedStartWithSecond
        let interval = DateComponents(hour: 1)

        let predicate = HKQuery.predicateForSamples(withStart: alignedStartWithSecond, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let collection = collection else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [HourlyStatistic] = []
                collection.enumerateStatistics(from: alignedStartWithSecond, to: end) { statistics, _ in
                    let value: Double
                    if options.contains(.cumulativeSum) {
                        value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                    } else if options.contains(.discreteAverage) {
                        value = statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
                    } else {
                        value = 0
                    }

                    // 只添加有数据的时间段
                    if value > 0 {
                        results.append(HourlyStatistic(
                            start: statistics.startDate,
                            end: statistics.endDate,
                            value: value
                        ))
                    }
                }

                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }

    func fetchQuantitySamples(
        type: HKQuantityType,
        start: Date,
        end: Date,
        limit: Int,
        unit: HKUnit
    ) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    func fetchCategorySamples(
        type: HKCategoryType,
        start: Date,
        end: Date,
        limit: Int
    ) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
            }
            healthStore.execute(query)
        }
    }

    func requestStatusForAuthorization() async throws -> HKAuthorizationRequestStatus {
        try await withCheckedThrowingContinuation { continuation in
            healthStore.getRequestStatusForAuthorization(toShare: writeTypes, read: readTypes) { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    func makeError(_ msg: String) -> NSError {
        NSError(domain: "HealthKitDemo", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}

// MARK: - Data Structures

public extension HealthKitManager {
    enum HealthKitAuthorizationState {
        case unavailable
        case notDetermined
        case denied
        case authorized
    }

    struct HealthDataSection: Identifiable {
        public enum Kind: Int {
            case steps
            case heartRate
            case activeEnergy
            case sleep
        }

        public var id: Kind { kind }
        public let kind: Kind
        public let title: String
        public let rows: [HealthDataRow]
        public let chartSeries: [HealthDataSeries]
    }

    struct HealthDataRow: Identifiable {
        public let id = UUID()
        public let headline: String
        public let detail: String
    }

    struct HealthDataSeries: Identifiable, Equatable {
        public enum Identifier: Hashable {
            case steps
            case heartRate
            case activeEnergy
            case sleep
        }

        public let id: Identifier
        public let title: String
        public let unitTitle: String
        public let points: [HealthDataPoint]
    }

    struct HealthDataPoint: Equatable {
        public let start: Date
        public let end: Date
        public let value: Double
    }
}
