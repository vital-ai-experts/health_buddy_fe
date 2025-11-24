//
//  HealthKitManager.swift
//  PlayAnything
//
//  Created by High on 2025/9/17.
//

import Foundation
import HealthKit
import LibraryBase

/// 负责与 HealthKit 交互的底层客户端，提供授权与数据拉取能力。
public final class HealthKitManager {
    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private var observerQueries: [HKObserverQuery] = []
    private var updateHandlers: [(HKSampleType) -> Void] = []

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

    private var characteristicReadTypes: Set<HKObjectType> {
        var set = Set<HKObjectType>()

        // 基础个人信息
        if let t = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) { set.insert(t) }
        if let t = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { set.insert(t) }

        // 身体测量（作为个人特征使用的基础字段）
        if let t = HKObjectType.quantityType(forIdentifier: .height) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMass) { set.insert(t) }

        return set
    }

    private var readTypes: Set<HKObjectType> {
        var set = characteristicReadTypes

        // MARK: - 活动与健身数据
        if let t = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceCycling) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceSwimming) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .distanceWheelchair) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .pushCount) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .flightsClimbed) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .nikeFuel) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .appleStandTime) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .appleMoveTime) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .appleStandHour) { set.insert(t) }

        // 运动速度与步频
        if let t = HKObjectType.quantityType(forIdentifier: .walkingSpeed) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .walkingStepLength) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .runningSpeed) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .runningStrideLength) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .runningPower) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount) { set.insert(t) }

        // Physical Effort - 体力消耗评分 (iOS 17+)
        if #available(iOS 17.0, *) {
            if let t = HKObjectType.quantityType(forIdentifier: .physicalEffort) { set.insert(t) }
            if let t = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) { set.insert(t) }
        }

        // MARK: - 心肺健康
        if let t = HKObjectType.quantityType(forIdentifier: .heartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .vo2Max) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .respiratoryRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) { set.insert(t) }

        // 心电图相关
        if let t = HKObjectType.categoryType(forIdentifier: .lowHeartRateEvent) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .highHeartRateEvent) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .irregularHeartRhythmEvent) { set.insert(t) }
        set.insert(HKObjectType.electrocardiogramType())

        // MARK: - 身体测量
        if let t = HKObjectType.quantityType(forIdentifier: .height) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMass) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .leanBodyMass) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .waistCircumference) { set.insert(t) }

        // MARK: - 营养与水分
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryCholesterol) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryFiber) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietarySugar) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryProtein) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietarySodium) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryWater) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) { set.insert(t) }

        // 维生素与矿物质
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryVitaminA) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryVitaminC) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryCalcium) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryIron) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryPotassium) { set.insert(t) }

        // MARK: - 睡眠与正念
        if let t = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .mindfulSession) { set.insert(t) }

        // MARK: - 生殖健康
        if let t = HKObjectType.categoryType(forIdentifier: .menstrualFlow) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .intermenstrualBleeding) { set.insert(t) }

        // MARK: - 个人特征（年龄、性别）
        if let t = HKObjectType.categoryType(forIdentifier: .cervicalMucusQuality) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .ovulationTestResult) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .sexualActivity) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .basalBodyTemperature) { set.insert(t) }

        // 孕期相关
        if let t = HKObjectType.categoryType(forIdentifier: .pregnancy) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .lactation) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .contraceptive) { set.insert(t) }

        // MARK: - 听力与环境
        if let t = HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .environmentalAudioExposureEvent) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .headphoneAudioExposureEvent) { set.insert(t) }

        // MARK: - 移动性指标
        if let t = HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .sixMinuteWalkTestDistance) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .stairAscentSpeed) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .stairDescentSpeed) { set.insert(t) }

        // MARK: - 其他健康指标
        if let t = HKObjectType.quantityType(forIdentifier: .bodyTemperature) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .bloodGlucose) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .numberOfTimesFallen) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .peakExpiratoryFlowRate) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .forcedExpiratoryVolume1) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .forcedVitalCapacity) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .inhalerUsage) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .insulinDelivery) { set.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .numberOfAlcoholicBeverages) { set.insert(t) }

        // 症状相关
        if let t = HKObjectType.categoryType(forIdentifier: .abdominalCramps) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .bloating) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .headache) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .fatigue) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .nausea) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .chestTightnessOrPain) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .dizziness) { set.insert(t) }
        if let t = HKObjectType.categoryType(forIdentifier: .shortnessOfBreath) { set.insert(t) }

        // 牙齿护理
        if let t = HKObjectType.categoryType(forIdentifier: .toothbrushingEvent) { set.insert(t) }

        // 洗手
        if let t = HKObjectType.categoryType(forIdentifier: .handwashingEvent) { set.insert(t) }

        // UV暴露
        if let t = HKObjectType.quantityType(forIdentifier: .uvExposure) { set.insert(t) }

        // 时间在阳光下 (iOS 17+)
        if #available(iOS 17.0, *) {
            if let t = HKObjectType.quantityType(forIdentifier: .timeInDaylight) { set.insert(t) }
        }

        return set
    }

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
    /// 批量获取所有健康数据并转换为JSON字符串
    /// 返回格式：{ yesterday_data: "", today_data: "", recent_data: "" }
    func fetchRecentDataAsJSON() async throws -> String {
        let calendar = Calendar.current
        let now = Date()

        // 计算昨天：昨天0点到昨天23:59:59
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart),
              let yesterdayEnd = calendar.date(byAdding: .second, value: -1, to: todayStart) else {
            throw makeError("无法计算时间范围")
        }

        // 计算今天：今天0点到现在
        let todayEnd = now

        // 计算最近3小时
        guard let recent3HoursStart = calendar.date(byAdding: .hour, value: -3, to: now) else {
            throw makeError("无法计算最近3小时范围")
        }

        // 获取三个时间段的数据
        let yesterdayData = try await fetchAllHealthDataForPeriod(start: yesterdayStart, end: yesterdayEnd, isDateRange: true)
        let todayData = try await fetchAllHealthDataForPeriod(start: todayStart, end: todayEnd, isDateRange: true)
        let recentData = try await fetchAllHealthDataForPeriod(start: recent3HoursStart, end: now, isDateRange: false)

        // 转换为JSON字符串
        let yesterdayJSON = try convertToJSONString(yesterdayData)
        let todayJSON = try convertToJSONString(todayData)
        let recentJSON = try convertToJSONString(recentData)

        // 构建最终的数据包
        let finalData: [String: String] = [
            "yesterday_data": yesterdayJSON,
            "today_data": todayJSON,
            "recent_data": recentJSON
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: finalData, options: [.sortedKeys, .prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw makeError("无法将健康数据转换为JSON字符串")
        }

        return jsonString
    }

    /// 将数据字典转换为JSON字符串
    private func convertToJSONString(_ data: [String: Any]) throws -> String {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.sortedKeys])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw makeError("无法将数据转换为JSON字符串")
        }
        return jsonString
    }

    /// 格式化日期为用户时区日期字符串 (yyyyMMdd)
    private func formatDateToLocalDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 获取指定时间段的所有健康数据（新格式）
    /// - Parameters:
    ///   - start: 开始时间
    ///   - end: 结束时间
    ///   - isDateRange: 是否为日期范围(true则返回date字段，false则返回start_time/end_time)
    /// - Returns: 格式化的健康数据字典
    private func fetchAllHealthDataForPeriod(start: Date, end: Date, isDateRange: Bool) async throws -> [String: Any] {
        var indicators: [[String: Any]] = []

        await withTaskGroup(of: [String: Any]?.self) { group in
            // MARK: - 活动与健身数据
            if let type = HKObjectType.quantityType(forIdentifier: .stepCount) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count(), key: "stepCount", displayName: "步数")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter(), key: "distanceWalkingRunning", displayName: "步行+跑步距离")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter(), key: "distanceCycling", displayName: "骑行距离")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .distanceSwimming) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter(), key: "distanceSwimming", displayName: "游泳距离")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .flightsClimbed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count(), key: "flightsClimbed", displayName: "爬楼层数")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .minute(), key: "exerciseTime", displayName: "锻炼时间")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .kilocalorie(), key: "activeEnergyBurned", displayName: "活动能量")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .kilocalorie(), key: "basalEnergyBurned", displayName: "静息能量")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .appleStandTime) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .minute(), key: "standTime", displayName: "站立时间")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .appleMoveTime) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .minute(), key: "moveTime", displayName: "活动时间")
                }
            }

            // 运动指标
            if let type = HKObjectType.quantityType(forIdentifier: .walkingSpeed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter().unitDivided(by: .second()), key: "walkingSpeed", displayName: "步行速度", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .runningSpeed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter().unitDivided(by: .second()), key: "runningSpeed", displayName: "跑步速度", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .walkingStepLength) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter(), key: "walkingStepLength", displayName: "步长", options: .discreteAverage)
                }
            }

            // MARK: - 心肺健康
            if let type = HKObjectType.quantityType(forIdentifier: .heartRate) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count().unitDivided(by: .minute()), key: "heartRate", displayName: "心率", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count().unitDivided(by: .minute()), key: "restingHeartRate", displayName: "静息心率", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count().unitDivided(by: .minute()), key: "walkingHeartRateAverage", displayName: "步行平均心率", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .secondUnit(with: .milli), key: "heartRateVariability", displayName: "心率变异性", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .vo2Max) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .literUnit(with: .milli).unitDivided(by: .gramUnit(with: .kilo).unitMultiplied(by: .minute())), key: "vo2Max", displayName: "最大摄氧量", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .percent(), key: "oxygenSaturation", displayName: "血氧饱和度", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .respiratoryRate) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count().unitDivided(by: .minute()), key: "respiratoryRate", displayName: "呼吸频率", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .millimeterOfMercury(), key: "bloodPressureSystolic", displayName: "收缩压", aggregation: .average)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .millimeterOfMercury(), key: "bloodPressureDiastolic", displayName: "舒张压", aggregation: .average)
                }
            }

            // MARK: - 身体测量（使用样本查询，取最新值）
            if let type = HKObjectType.quantityType(forIdentifier: .height) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .meter(), key: "height", displayName: "身高", aggregation: .latest)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bodyMass) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .gramUnit(with: .kilo), key: "bodyMass", displayName: "体重", aggregation: .latest)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .count(), key: "bodyMassIndex", displayName: "BMI", aggregation: .latest)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .leanBodyMass) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .gramUnit(with: .kilo), key: "leanBodyMass", displayName: "瘦体重", aggregation: .latest)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .percent(), key: "bodyFatPercentage", displayName: "体脂率", aggregation: .latest)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .waistCircumference) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .meter(), key: "waistCircumference", displayName: "腰围", aggregation: .latest)
                }
            }

            // MARK: - 营养
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .kilocalorie(), key: "dietaryEnergy", displayName: "饮食能量")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .liter(), key: "dietaryWater", displayName: "饮水量")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryProtein) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gram(), key: "dietaryProtein", displayName: "蛋白质")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gram(), key: "dietaryCarbohydrates", displayName: "碳水化合物")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gram(), key: "dietaryFat", displayName: "脂肪")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gramUnit(with: .milli), key: "dietaryCaffeine", displayName: "咖啡因")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietarySugar) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gram(), key: "dietarySugar", displayName: "糖分")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryFiber) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gram(), key: "dietaryFiber", displayName: "纤维")
                }
            }

            // 维生素
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminA) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gramUnit(with: .micro), key: "vitaminA", displayName: "维生素A")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminC) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gramUnit(with: .milli), key: "vitaminC", displayName: "维生素C")
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .dietaryVitaminD) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .gramUnit(with: .micro), key: "vitaminD", displayName: "维生素D")
                }
            }

            // MARK: - 睡眠 (使用离散数据,保留睡眠阶段信息)
            if let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                group.addTask {
                    try? await self.fetchSleepAnalysisData(type: type, start: start, end: end)
                }
            }

            // MARK: - 正念
            if let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
                group.addTask {
                    try? await self.fetchHourlyCategoryData(type: type, start: start, end: end, key: "mindfulSession", displayName: "正念时长")
                }
            }

            // MARK: - 其他健康指标（使用样本查询）
            if let type = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .degreeCelsius(), key: "bodyTemperature", displayName: "体温", aggregation: .average)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .bloodGlucose) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter()), key: "bloodGlucose", displayName: "血糖", aggregation: .average)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .numberOfTimesFallen) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .count(), key: "numberOfTimesFallen", displayName: "跌倒次数")
                }
            }

            // MARK: - 听力
            if let type = HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .decibelAWeightedSoundPressureLevel(), key: "environmentalAudioExposure", displayName: "环境音量", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .decibelAWeightedSoundPressureLevel(), key: "headphoneAudioExposure", displayName: "耳机音量", options: .discreteAverage)
                }
            }

            // MARK: - 移动性
            if let type = HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .percent(), key: "walkingDoubleSupportPercentage", displayName: "步行双支撑百分比", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .percent(), key: "walkingAsymmetryPercentage", displayName: "步行不对称百分比", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .stairAscentSpeed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter().unitDivided(by: .second()), key: "stairAscentSpeed", displayName: "上楼速度", options: .discreteAverage)
                }
            }
            if let type = HKObjectType.quantityType(forIdentifier: .stairDescentSpeed) {
                group.addTask {
                    try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .meter().unitDivided(by: .second()), key: "stairDescentSpeed", displayName: "下楼速度", options: .discreteAverage)
                }
            }

            // MARK: - UV暴露（使用样本查询，取平均值）
            if let type = HKObjectType.quantityType(forIdentifier: .uvExposure) {
                group.addTask {
                    try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .count(), key: "uvExposure", displayName: "紫外线暴露", aggregation: .average)
                }
            }

            // iOS 17+ 专属数据
            if #available(iOS 17.0, *) {
                if let type = HKObjectType.quantityType(forIdentifier: .physicalEffort) {
                    group.addTask {
                        // physicalEffort 的单位是 kcal/(hr·kg)，即千卡/(小时·千克)
                        let unit = HKUnit.kilocalorie().unitDivided(by: HKUnit.hour()).unitDivided(by: HKUnit.gramUnit(with: .kilo))
                        return try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: unit, key: "physicalEffort", displayName: "体力消耗", options: .discreteAverage)
                    }
                }
                if let type = HKObjectType.quantityType(forIdentifier: .timeInDaylight) {
                    group.addTask {
                        try? await self.fetchHourlyQuantityData(type: type, start: start, end: end, unit: .minute(), key: "timeInDaylight", displayName: "日光时间")
                    }
                }
                if let type = HKObjectType.quantityType(forIdentifier: .appleSleepingWristTemperature) {
                    group.addTask {
                        try? await self.fetchHourlySampleData(type: type, start: start, end: end, unit: .degreeCelsius(), key: "sleepingWristTemperature", displayName: "睡眠手腕温度", aggregation: .average)
                    }
                }
            }

            for await result in group {
                if let indicator = result {
                    indicators.append(indicator)
                }
            }
        }

        // 构建最终数据结构
        var result: [String: Any] = [:]

        if isDateRange {
            // 日期范围模式：使用 date 字段
            result["date"] = formatDateToLocalDate(start)
        } else {
            // 时间范围模式：使用 start_time 和 end_time 字段
            result["start_time"] = formatDateToISO8601(start)
            result["end_time"] = formatDateToISO8601(end)
        }

        // 添加个人特征信息（仅在日期范围模式下添加一次）
        if isDateRange {
            var characteristics: [String: Any] = [:]

            // 获取年龄
            if let age = try? getAge() {
                characteristics["age"] = age
            }

            // 获取性别
            if let biologicalSex = try? getBiologicalSex() {
                characteristics["biological_sex"] = biologicalSex
            }

            // 获取身高（米）
            if let latestHeight = try? await getLatestQuantityValue(
                identifier: .height,
                unit: .meter(),
                start: start,
                end: end
            ) {
                characteristics["height"] = latestHeight
            }

            // 获取体重（千克）
            if let latestBodyMass = try? await getLatestQuantityValue(
                identifier: .bodyMass,
                unit: .gramUnit(with: .kilo),
                start: start,
                end: end
            ) {
                characteristics["weight"] = latestBodyMass
            }

            if !characteristics.isEmpty {
                result["characteristics"] = characteristics
            }
        }

        result["indicators"] = indicators
        return result
    }

    /// 格式化日期为ISO8601字符串
    private func formatDateToISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 获取用户年龄
    private func getAge() throws -> Int? {
        guard let dateOfBirth = try? healthStore.dateOfBirthComponents().date else {
            return nil
        }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year
    }

    /// 获取用户生理性别
    private func getBiologicalSex() throws -> String? {
        let biologicalSex = try healthStore.biologicalSex()
        switch biologicalSex.biologicalSex {
        case .notSet:
            return nil
        case .female:
            return "female"
        case .male:
            return "male"
        case .other:
            return "other"
        @unknown default:
            return nil
        }
    }

    /// 获取指定数量类型的最近一次数值
    private func getLatestQuantityValue(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let sample: HKQuantitySample? = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples?.first as? HKQuantitySample))
                }
            }
            healthStore.execute(query)
        }

        if let sample {
            return sample.quantity.doubleValue(for: unit)
        }

        return nil
    }

    /// 获取数量类型的健康数据
    private func fetchQuantityData(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        key: String
    ) async throws -> (String, [[String: Any]]) {
        let samples = try await fetchQuantitySamples(type: type, start: start, end: end, limit: HKObjectQueryNoLimit, unit: unit)

        // 安全地转换数值，跳过单位不兼容的样本
        let dataPoints: [[String: Any]] = samples.compactMap { sample in
            do {
                let value = try sample.quantity.doubleValue(for: unit)
                return [
                    "start": ISO8601DateFormatter().string(from: sample.startDate),
                    "end": ISO8601DateFormatter().string(from: sample.endDate),
                    "value": value
                ]
            } catch {
                // 单位不兼容时跳过此样本
                Log.w("⚠️ 跳过单位不兼容的样本 (\(key)): \(error)", category: "HealthKit")
                return nil
            }
        }

        return (key, dataPoints)
    }

    /// 获取分类类型的健康数据
    private func fetchCategoryData(
        type: HKCategoryType,
        start: Date,
        end: Date,
        key: String
    ) async throws -> (String, [[String: Any]]) {
        let samples = try await fetchCategorySamples(type: type, start: start, end: end, limit: HKObjectQueryNoLimit)

        let dataPoints: [[String: Any]] = samples.map { sample in
            [
                "start": ISO8601DateFormatter().string(from: sample.startDate),
                "end": ISO8601DateFormatter().string(from: sample.endDate),
                "value": sample.value
            ]
        }

        return (key, dataPoints)
    }

    /// 格式化日期时间为本地时区格式：20251114_14
    private func formatDateToLocalHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HH"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 获取按小时聚合的数量类型健康数据（使用统计查询）
    private func fetchHourlyQuantityData(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        key: String,
        displayName: String,
        options: HKStatisticsOptions = .cumulativeSum
    ) async throws -> [String: Any]? {
        let statistics = try await fetchHourlyStatistics(
            type: type,
            start: start,
            end: end,
            unit: unit,
            options: options
        )

        // 如果没有数据,返回nil而不是空数据
        guard !statistics.isEmpty else {
            return nil
        }

        let hourlyData = statistics.map { stat in
            [
                "hour": formatDateToLocalHour(stat.start),
                "value": stat.value
            ] as [String: Any]
        }

        // 计算总值
        let value: Double
        let aggregationMethod: String
        if options.contains(.cumulativeSum) {
            value = statistics.reduce(0) { $0 + $1.value }
            aggregationMethod = "sum"
        } else {
            value = statistics.reduce(0) { $0 + $1.value } / Double(statistics.count)
            aggregationMethod = "average"
        }

        // 构建结果,只有当有多个小时数据时才添加hour_items
        var result: [String: Any] = [
            "key": key,
            "name": displayName,
            "unit": unit.unitString,
            "value": value,
            "aggregation_method": aggregationMethod
        ]

        // 只有当有小时级数据且数量>1时才添加hour_items
        if hourlyData.count > 1 {
            result["hour_items"] = hourlyData
        }

        return result
    }

    /// 获取按小时聚合的数量类型健康数据（使用样本查询，适用于不支持统计选项的类型）
    private func fetchHourlySampleData(
        type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit,
        key: String,
        displayName: String,
        aggregation: SampleAggregation = .sum
    ) async throws -> [String: Any]? {
        let samples = try await fetchQuantitySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit,
            unit: unit
        )

        // 如果没有数据,返回nil
        guard !samples.isEmpty else {
            return nil
        }

        // 将samples按小时聚合
        var hourlyDict: [String: [Double]] = [:]
        for sample in samples {
            let hourKey = formatDateToLocalHour(sample.startDate)
            if let value = try? sample.quantity.doubleValue(for: unit) {
                hourlyDict[hourKey, default: []].append(value)
            }
        }

        let hourlyData = hourlyDict.map { (hour, values) in
            let aggregatedValue: Double
            switch aggregation {
            case .sum:
                aggregatedValue = values.reduce(0, +)
            case .average:
                aggregatedValue = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
            case .latest:
                aggregatedValue = values.last ?? 0
            }
            return [
                "hour": hour,
                "value": aggregatedValue
            ] as [String: Any]
        }.sorted { ($0["hour"] as? String ?? "") < ($1["hour"] as? String ?? "") }

        // 计算总值
        let value: Double
        let aggregationMethod: String
        switch aggregation {
        case .sum:
            value = hourlyData.reduce(0) { $0 + ($1["value"] as? Double ?? 0) }
            aggregationMethod = "sum"
        case .average:
            value = hourlyData.reduce(0) { $0 + ($1["value"] as? Double ?? 0) } / Double(hourlyData.count)
            aggregationMethod = "average"
        case .latest:
            value = hourlyData.last?["value"] as? Double ?? 0
            aggregationMethod = "latest"
        }

        // 构建结果
        var result: [String: Any] = [
            "key": key,
            "name": displayName,
            "unit": unit.unitString,
            "value": value,
            "aggregation_method": aggregationMethod
        ]

        // 只有当有小时级数据且数量>1时才添加hour_items
        if hourlyData.count > 1 {
            result["hour_items"] = hourlyData
        }

        return result
    }

    /// 样本聚合方式
    enum SampleAggregation {
        case sum      // 求和（用于累积类型如营养摄入）
        case average  // 平均值（用于离散类型如体温、血压）
        case latest   // 最新值（用于身体测量如体重、身高）
    }

    /// 获取睡眠分析数据（离散数据，保留睡眠阶段信息）
    private func fetchSleepAnalysisData(
        type: HKCategoryType,
        start: Date,
        end: Date
    ) async throws -> [String: Any]? {
        let samples = try await fetchCategorySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit
        )

        // 如果没有数据,返回nil
        guard !samples.isEmpty else {
            return nil
        }

        // 睡眠阶段映射
        let sleepStageNames: [Int: String] = [
            0: "in_bed",           // HKCategoryValueSleepAnalysis.inBed
            1: "asleep_unspecified", // HKCategoryValueSleepAnalysis.asleepUnspecified
            2: "awake",            // HKCategoryValueSleepAnalysis.awake
            3: "asleep_core",      // HKCategoryValueSleepAnalysis.asleepCore
            4: "asleep_deep",      // HKCategoryValueSleepAnalysis.asleepDeep
            5: "asleep_rem"        // HKCategoryValueSleepAnalysis.asleepREM
        ]

        // 转换为离散数据
        let sleepSamples = samples.map { sample -> [String: Any] in
            let stage = sleepStageNames[sample.value] ?? "unknown"
            return [
                "stage": stage,
                "start_time": formatDateToISO8601(sample.startDate),
                "end_time": formatDateToISO8601(sample.endDate),
                "duration_minutes": sample.endDate.timeIntervalSince(sample.startDate) / 60.0
            ]
        }.sorted {
            ($0["start_time"] as? String ?? "") < ($1["start_time"] as? String ?? "")
        }

        // 统计总睡眠时长（不包括清醒和在床上）
        let totalSleepMinutes = samples
            .filter { [2, 3, 4, 5].contains($0.value) } // 排除in_bed(0)和awake(1)
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60.0 }

        return [
            "key": "sleepAnalysis",
            "name": "睡眠分析",
            "unit": "分钟",
            "value": totalSleepMinutes,
            "aggregation_method": "sum",
            "samples": sleepSamples  // 使用samples而不是hour_items
        ]
    }

    /// 获取按小时聚合的分类类型健康数据（如站立小时）
    private func fetchHourlyCategoryData(
        type: HKCategoryType,
        start: Date,
        end: Date,
        key: String,
        displayName: String
    ) async throws -> [String: Any]? {
        let samples = try await fetchCategorySamples(
            type: type,
            start: start,
            end: end,
            limit: HKObjectQueryNoLimit
        )

        // 如果没有数据,返回nil
        guard !samples.isEmpty else {
            return nil
        }

        // 将分类数据按小时聚合
        var hourlyDict: [String: Int] = [:]
        for sample in samples {
            let hourKey = formatDateToLocalHour(sample.startDate)
            hourlyDict[hourKey, default: 0] += 1
        }

        let hourlyData = hourlyDict.map { (hour, count) in
            [
                "hour": hour,
                "count": count
            ] as [String: Any]
        }.sorted { ($0["hour"] as? String ?? "") < ($1["hour"] as? String ?? "") }

        let totalCount = hourlyData.reduce(0) { $0 + ($1["count"] as? Int ?? 0) }

        // 构建结果
        var result: [String: Any] = [
            "key": key,
            "name": displayName,
            "unit": "次",
            "value": totalCount,
            "aggregation_method": "count"
        ]

        // 只有当有小时级数据且数量>1时才添加hour_items
        if hourlyData.count > 1 {
            result["hour_items"] = hourlyData
        }

        return result
    }

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

    public struct HourlyStatistic {
        public let start: Date
        public let end: Date
        public let value: Double
    }

    internal func fetchHourlyStatistics(
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

    internal func fetchQuantitySamples(
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

    internal func fetchCategorySamples(
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
        NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
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
        public enum Kind: String, CaseIterable {
            // 活动与健身
            case steps, distance, cycling, swimming, flights, exerciseTime, activeEnergy, basalEnergy, standTime, moveTime

            // 心肺健康
            case heartRate, restingHeartRate, walkingHeartRate, hrv, vo2Max, oxygenSaturation, respiratoryRate, bloodPressure

            // 身体测量
            case height, weight, bmi, leanBodyMass, bodyFat, waistCircumference

            // 营养
            case dietaryEnergy, water, protein, carbs, fat, caffeine, vitamins

            // 睡眠与正念
            case sleep, mindfulness

            // 生殖健康
            case menstrualFlow, basalBodyTemperature

            // 听力与环境
            case audioExposure, uvExposure

            // 移动性
            case walkingSpeed, walkingAsymmetry, stairSpeed

            // 其他健康指标
            case bodyTemperature, bloodGlucose, numberOfTimesFallen

            // 症状
            case symptoms

            public var jsonKey: String {
                return self.rawValue
            }
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

// MARK: - Background Delivery

public extension HealthKitManager {
    /// 启用后台数据推送，监听健康数据变化
    func enableBackgroundDelivery(updateHandler: @escaping (HKSampleType) -> Void) {
        updateHandlers.append(updateHandler)

        // 为所有读取类型启用后台推送
        let quantityTypes = readTypes.compactMap { $0 as? HKQuantityType }
        let categoryTypes = readTypes.compactMap { $0 as? HKCategoryType }

        // 启用步数后台推送
        for type in quantityTypes {
            enableBackgroundDelivery(for: type)
        }

        // 启用分类类型（如睡眠）的后台推送
        for type in categoryTypes {
            enableBackgroundDelivery(for: type)
        }
    }

    /// 为特定类型启用后台推送
    private func enableBackgroundDelivery(for sampleType: HKSampleType) {
        // 启用后台推送频率（immediate 表示立即推送）
        healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
            if success {
                Log.i("✅ 已启用 \(sampleType.identifier) 的后台推送", category: "HealthKit")
                self.startObserverQuery(for: sampleType)
            } else if let error = error {
                Log.e("❌ 启用后台推送失败: \(error.localizedDescription)", category: "HealthKit")
            }
        }
    }

    /// 启动观察者查询
    private func startObserverQuery(for sampleType: HKSampleType) {
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] query, completionHandler, error in
            guard let self = self else {
                completionHandler()
                return
            }

            if let error = error {
                Log.e("❌ 观察者查询错误: \(error.localizedDescription)", category: "HealthKit")
                completionHandler()
                return
            }

            Log.i("📱 检测到 \(sampleType.identifier) 数据更新", category: "HealthKit")

            // 通知所有注册的处理器
            for handler in self.updateHandlers {
                handler(sampleType)
            }

            // 完成后台任务
            completionHandler()
        }

        observerQueries.append(query)
        healthStore.execute(query)
    }

    /// 停止所有观察者查询
    func stopBackgroundDelivery() {
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
        updateHandlers.removeAll()

        // 禁用所有类型的后台推送
        let quantityTypes = readTypes.compactMap { $0 as? HKQuantityType }
        let categoryTypes = readTypes.compactMap { $0 as? HKCategoryType }

        for type in quantityTypes {
            healthStore.disableBackgroundDelivery(for: type) { _, _ in }
        }

        for type in categoryTypes {
            healthStore.disableBackgroundDelivery(for: type) { _, _ in }
        }
    }
}
