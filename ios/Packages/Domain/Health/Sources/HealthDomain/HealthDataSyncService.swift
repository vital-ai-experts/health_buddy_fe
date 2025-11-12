//
//  HealthDataSyncService.swift
//  DomainHealth
//
//  Created by High on 2025/11/12.
//

import Foundation
import HealthKit
import LibraryNetworking

/// 后台健康数据同步服务，负责聚合并上传数据到服务器
public final class HealthDataSyncService {
    public static let shared = HealthDataSyncService()

    private let healthKitManager = HealthKitManager.shared
    private var isSyncInProgress = false
    private let syncQueue = DispatchQueue(label: "com.thrivebody.healthsync", qos: .background)

    private init() {}

    /// 启动后台同步监听
    public func startBackgroundSync() {
        // 在后台线程检查权限并启动同步
        Task {
            do {
                // 检查 HealthKit 是否可用
                guard HKHealthStore.isHealthDataAvailable() else {
                    print("⚠️ HealthKit 不可用，跳过后台同步")
                    return
                }

                // 检查授权状态
                let authStatus = await healthKitManager.authorizationStatus()
                guard authStatus == .authorized else {
                    print("⚠️ HealthKit 未授权，跳过后台同步")
                    return
                }

                // 启动后台数据推送
                healthKitManager.enableBackgroundDelivery { [weak self] sampleType in
                    guard let self = self else { return }

                    // 在后台队列执行同步
                    self.syncQueue.async {
                        Task {
                            await self.syncHealthData()
                        }
                    }
                }

                print("✅ 后台健康数据同步已启动")
            } catch {
                print("❌ 启动后台同步失败: \(error.localizedDescription)")
            }
        }
    }

    /// 停止后台同步
    public func stopBackgroundSync() {
        healthKitManager.stopBackgroundDelivery()
        print("⏹️ 后台健康数据同步已停止")
    }

    /// 同步健康数据到服务器
    @MainActor
    private func syncHealthData() async {
        // 防止重复同步
        guard !isSyncInProgress else {
            print("⚠️ 同步正在进行中，跳过本次请求")
            return
        }

        isSyncInProgress = true
        defer { isSyncInProgress = false }

        do {
            print("📤 开始同步健康数据...")

            // 获取最近24小时的聚合数据
            let aggregatedData = try await fetchAndAggregateData()

            // 上传到服务器
            try await uploadToServer(aggregatedData)

            print("✅ 健康数据同步成功")
        } catch {
            print("❌ 健康数据同步失败: \(error.localizedDescription)")
        }
    }

    /// 获取并聚合最近24小时的健康数据
    private func fetchAndAggregateData() async throws -> [String: Any] {
        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -1, to: end) else {
            throw NSError(domain: "HealthDataSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法计算时间范围"])
        }

        // 构建聚合数据结构
        var aggregatedData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "timeRange": [
                "start": ISO8601DateFormatter().string(from: start),
                "end": ISO8601DateFormatter().string(from: end)
            ],
            "data": [String: Any]()
        ]

        var dataDict: [String: Any] = [:]

        // 并发获取所有健康数据类型
        await withTaskGroup(of: (String, [String: Any]?).self) { group in
            // 步数
            if let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount) {
                group.addTask {
                    do {
                        let data = try await self.fetchHourlyData(
                            type: stepsType,
                            start: start,
                            end: end,
                            unit: .count(),
                            key: "steps",
                            displayName: "步数"
                        )
                        return ("steps", data)
                    } catch {
                        print("❌ 获取步数失败: \(error)")
                        return ("steps", nil)
                    }
                }
            }

            // 心率
            if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
                group.addTask {
                    do {
                        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                        let data = try await self.fetchHourlyData(
                            type: heartRateType,
                            start: start,
                            end: end,
                            unit: bpmUnit,
                            key: "heartRate",
                            displayName: "心率",
                            options: .discreteAverage
                        )
                        return ("heartRate", data)
                    } catch {
                        print("❌ 获取心率失败: \(error)")
                        return ("heartRate", nil)
                    }
                }
            }

            // 主动能量
            if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                group.addTask {
                    do {
                        let data = try await self.fetchHourlyData(
                            type: energyType,
                            start: start,
                            end: end,
                            unit: .kilocalorie(),
                            key: "activeEnergy",
                            displayName: "主动能量"
                        )
                        return ("activeEnergy", data)
                    } catch {
                        print("❌ 获取主动能量失败: \(error)")
                        return ("activeEnergy", nil)
                    }
                }
            }

            // 运动时间
            if let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
                group.addTask {
                    do {
                        let data = try await self.fetchHourlyData(
                            type: exerciseType,
                            start: start,
                            end: end,
                            unit: .minute(),
                            key: "exerciseTime",
                            displayName: "运动时间"
                        )
                        return ("exerciseTime", data)
                    } catch {
                        print("❌ 获取运动时间失败: \(error)")
                        return ("exerciseTime", nil)
                    }
                }
            }

            // 站立小时
            if let standType = HKObjectType.categoryType(forIdentifier: .appleStandHour) {
                group.addTask {
                    do {
                        let data = try await self.fetchCategoryData(
                            type: standType,
                            start: start,
                            end: end,
                            key: "standHours",
                            displayName: "站立小时"
                        )
                        return ("standHours", data)
                    } catch {
                        print("❌ 获取站立小时失败: \(error)")
                        return ("standHours", nil)
                    }
                }
            }

            // 睡眠分析
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                group.addTask {
                    do {
                        let data = try await self.fetchSleepData(
                            type: sleepType,
                            start: start,
                            end: end
                        )
                        return ("sleep", data)
                    } catch {
                        print("❌ 获取睡眠数据失败: \(error)")
                        return ("sleep", nil)
                    }
                }
            }

            // HRV - 心率变异性
            if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
                group.addTask {
                    do {
                        let data = try await self.fetchDiscreteData(
                            type: hrvType,
                            start: start,
                            end: end,
                            unit: HKUnit.secondUnit(with: .milli),
                            key: "hrv",
                            displayName: "心率变异性"
                        )
                        return ("hrv", data)
                    } catch {
                        print("❌ 获取HRV失败: \(error)")
                        return ("hrv", nil)
                    }
                }
            }

            // RHR - 静息心率
            if let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
                group.addTask {
                    do {
                        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                        let data = try await self.fetchDiscreteData(
                            type: rhrType,
                            start: start,
                            end: end,
                            unit: bpmUnit,
                            key: "rhr",
                            displayName: "静息心率"
                        )
                        return ("rhr", data)
                    } catch {
                        print("❌ 获取静息心率失败: \(error)")
                        return ("rhr", nil)
                    }
                }
            }

            // Physical Effort - 体力消耗评分
            if #available(iOS 17.0, *) {
                if let effortType = HKObjectType.quantityType(forIdentifier: .physicalEffort) {
                    group.addTask {
                        do {
                            // physicalEffort 的单位是 kcal/(hr·kg)，即千卡/(小时·千克)
                            let unit = HKUnit.kilocalorie().unitDivided(by: HKUnit.hour()).unitDivided(by: HKUnit.gramUnit(with: .kilo))
                            let data = try await self.fetchDiscreteData(
                                type: effortType,
                                start: start,
                                end: end,
                                unit: unit,
                                key: "physicalEffort",
                                displayName: "体力消耗"
                            )
                            return ("physicalEffort", data)
                        } catch {
                            print("❌ 获取体力消耗失败: \(error)")
                            return ("physicalEffort", nil)
                        }
                    }
                }
            }

            // Activity - 活动数据综合
            group.addTask {
                do {
                    let activityData = try await self.fetchActivityData(start: start, end: end)
                    return ("activity", activityData)
                } catch {
                    print("❌ 获取活动数据失败: \(error)")
                    return ("activity", nil)
                }
            }

            // VO2 Max - 最大摄氧量
            if let vo2MaxType = HKObjectType.quantityType(forIdentifier: .vo2Max) {
                group.addTask {
                    do {
                        let unit = HKUnit.literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo)).unitDivided(by: .minute())
                        let data = try await self.fetchDiscreteData(
                            type: vo2MaxType,
                            start: start,
                            end: end,
                            unit: unit,
                            key: "vo2Max",
                            displayName: "最大摄氧量"
                        )
                        return ("vo2Max", data)
                    } catch {
                        print("❌ 获取VO2 Max失败: \(error)")
                        return ("vo2Max", nil)
                    }
                }
            }

            // 步行平均心率
            if let walkingHRType = HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage) {
                group.addTask {
                    do {
                        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                        let data = try await self.fetchDiscreteData(
                            type: walkingHRType,
                            start: start,
                            end: end,
                            unit: bpmUnit,
                            key: "walkingHeartRate",
                            displayName: "步行平均心率"
                        )
                        return ("walkingHeartRate", data)
                    } catch {
                        print("❌ 获取步行心率失败: \(error)")
                        return ("walkingHeartRate", nil)
                    }
                }
            }

            for await (key, value) in group {
                if let value = value {
                    dataDict[key] = value
                }
            }
        }

        aggregatedData["data"] = dataDict

        return aggregatedData
    }

    /// 获取按小时聚合的数据
    private func fetchHourlyData(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        key: String,
        displayName: String,
        options: HKStatisticsOptions = .cumulativeSum
    ) async throws -> [String: Any] {
        let statistics = try await healthKitManager.fetchHourlyStatistics(
            type: type,
            start: start,
            end: end,
            unit: unit,
            options: options
        )

        let hourlyData = statistics.map { stat in
            [
                "hour": ISO8601DateFormatter().string(from: stat.start),
                "value": stat.value
            ]
        }

        return [
            "displayName": displayName,
            "unit": unit.unitString,
            "hourlyData": hourlyData,
            "total": statistics.reduce(0) { $0 + $1.value },
            "average": statistics.isEmpty ? 0 : statistics.reduce(0) { $0 + $1.value } / Double(statistics.count)
        ]
    }

    /// 获取分类数据（如站立小时）
    private func fetchCategoryData(
        type: HKCategoryType,
        start: Date,
        end: Date,
        key: String,
        displayName: String
    ) async throws -> [String: Any] {
        let samples = try await healthKitManager.fetchCategorySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit
        )

        let dataPoints = samples.map { sample in
            [
                "start": ISO8601DateFormatter().string(from: sample.startDate),
                "end": ISO8601DateFormatter().string(from: sample.endDate),
                "value": sample.value
            ]
        }

        return [
            "displayName": displayName,
            "dataPoints": dataPoints,
            "count": samples.count
        ]
    }

    /// 获取睡眠数据
    private func fetchSleepData(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [String: Any] {
        let samples = try await healthKitManager.fetchCategorySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit
        )

        let sleepStages = samples.map { sample in
            let stageName: String
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                stageName = "inBed"
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                stageName = "asleepCore"
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                stageName = "asleepDeep"
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                stageName = "asleepREM"
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                stageName = "awake"
            default:
                stageName = "unknown"
            }

            return [
                "start": ISO8601DateFormatter().string(from: sample.startDate),
                "end": ISO8601DateFormatter().string(from: sample.endDate),
                "stage": stageName,
                "duration": sample.endDate.timeIntervalSince(sample.startDate) / 60 // 分钟
            ] as [String: Any]
        }

        // 计算总睡眠时间
        let totalSleepMinutes = samples.reduce(0.0) { total, sample in
            total + (sample.endDate.timeIntervalSince(sample.startDate) / 60)
        }

        // 计算睡眠质量评分 (简单算法: 深睡和REM占比)
        let deepSleepMinutes = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }
            .reduce(0.0) { $0 + ($1.endDate.timeIntervalSince($1.startDate) / 60) }
        let remSleepMinutes = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
            .reduce(0.0) { $0 + ($1.endDate.timeIntervalSince($1.startDate) / 60) }

        let sleepScore: Double
        if totalSleepMinutes > 0 {
            let qualitySleepRatio = (deepSleepMinutes + remSleepMinutes) / totalSleepMinutes
            sleepScore = min(100, qualitySleepRatio * 200) // 转换为0-100分
        } else {
            sleepScore = 0
        }

        return [
            "displayName": "睡眠",
            "stages": sleepStages,
            "totalSleepMinutes": totalSleepMinutes,
            "totalSleepHours": totalSleepMinutes / 60,
            "deepSleepMinutes": deepSleepMinutes,
            "remSleepMinutes": remSleepMinutes,
            "sleepScore": sleepScore
        ]
    }

    /// 获取离散数据（如HRV、静息心率等）
    private func fetchDiscreteData(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        key: String,
        displayName: String
    ) async throws -> [String: Any] {
        let samples = try await healthKitManager.fetchQuantitySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit,
            unit: unit
        )

        // 安全地转换数值，处理单位不兼容的情况
        let dataPoints = samples.compactMap { sample -> [String: Any]? in
            do {
                // 尝试转换单位
                let value = try sample.quantity.doubleValue(for: unit)
                return [
                    "timestamp": ISO8601DateFormatter().string(from: sample.startDate),
                    "value": value
                ]
            } catch {
                // 如果单位不兼容，尝试使用样本自带的首选单位
                print("⚠️ 单位转换失败 (\(key)): \(error), 使用默认单位")
                return nil
            }
        }

        let values = samples.compactMap { sample -> Double? in
            try? sample.quantity.doubleValue(for: unit)
        }

        let average = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let min = values.min() ?? 0
        let max = values.max() ?? 0

        return [
            "displayName": displayName,
            "unit": unit.unitString,
            "dataPoints": dataPoints,
            "average": average,
            "min": min,
            "max": max,
            "count": samples.count
        ]
    }

    /// 获取活动数据综合信息
    private func fetchActivityData(start: Date, end: Date) async throws -> [String: Any] {
        var activityData: [String: Any] = [
            "displayName": "活动数据"
        ]

        // 获取站立时间
        if let standTimeType = HKObjectType.quantityType(forIdentifier: .appleStandTime) {
            let standTime = try? await healthKitManager.fetchHourlyStatistics(
                type: standTimeType,
                start: start,
                end: end,
                unit: .minute()
            )
            if let standTime = standTime {
                activityData["standTimeMinutes"] = standTime.reduce(0) { $0 + $1.value }
            }
        }

        // 获取移动时间
        if let moveTimeType = HKObjectType.quantityType(forIdentifier: .appleMoveTime) {
            let moveTime = try? await healthKitManager.fetchHourlyStatistics(
                type: moveTimeType,
                start: start,
                end: end,
                unit: .minute()
            )
            if let moveTime = moveTime {
                activityData["moveTimeMinutes"] = moveTime.reduce(0) { $0 + $1.value }
            }
        }

        // 活动环完成度（基于已有数据计算）
        let moveMinutes = activityData["moveTimeMinutes"] as? Double ?? 0
        let standMinutes = activityData["standTimeMinutes"] as? Double ?? 0

        // 简单的活动评分 (0-100)
        let activityScore = min(100, (moveMinutes / 30.0 + standMinutes / 12.0) * 50 / 2)

        activityData["activityScore"] = activityScore

        return activityData
    }

    /// 上传数据到服务器
    private func uploadToServer(_ data: [String: Any]) async throws {
        let apiClient = APIClient.shared

        // 创建可编码的请求体
        let requestBody = HealthDataUploadRequest(data: data)

        // 构建 API 端点
        let endpoint = APIEndpoint(
            path: "/data/healthkit_auto",
            method: .post,
            body: requestBody,
            requiresAuth: true
        )

        // 发送 POST 请求
        let response: UploadResponse = try await apiClient.request(
            endpoint,
            responseType: UploadResponse.self
        )

        print("✅ 服务器响应: \(response.message ?? "成功")")
    }
}

// MARK: - Request/Response Models

private struct HealthDataUploadRequest: Encodable {
    let data: [String: Any]

    enum CodingKeys: String, CodingKey {
        case timestamp, timeRange, data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let timestamp = data["timestamp"] as? String {
            try container.encode(timestamp, forKey: .timestamp)
        }

        if let timeRange = data["timeRange"] as? [String: String] {
            try container.encode(timeRange, forKey: .timeRange)
        }

        if let healthData = data["data"] as? [String: Any] {
            // 将字典转换为 JSON 数据再编码
            let jsonData = try JSONSerialization.data(withJSONObject: healthData)
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            try container.encode(AnyCodable(jsonObject), forKey: .data)
        }
    }
}

/// 用于编码任意 JSON 值的包装器
private struct AnyCodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let string as String:
            try container.encode(string)
        case let number as Double:
            try container.encode(number)
        case let number as Int:
            try container.encode(number)
        case let bool as Bool:
            try container.encode(bool)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: "Invalid value type"
                )
            )
        }
    }
}

private struct UploadResponse: Codable {
    let success: Bool?
    let message: String?
}
