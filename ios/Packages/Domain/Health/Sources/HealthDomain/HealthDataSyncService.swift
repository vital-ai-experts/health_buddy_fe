//
//  HealthDataSyncService.swift
//  DomainHealth
//
//  Created by High on 2025/11/12.
//

import Foundation
import HealthKit
import LibraryBase
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
                    Log.w("⚠️ HealthKit 不可用，跳过后台同步", category: "Health")
                    return
                }

                // 检查授权状态
                let authStatus = await healthKitManager.authorizationStatus()
                guard authStatus == .authorized else {
                    Log.w("⚠️ HealthKit 未授权，跳过后台同步", category: "Health")
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

                Log.i("✅ 后台健康数据同步已启动", category: "Health")
            } catch {
                Log.e("❌ 启动后台同步失败: \(error.localizedDescription)", category: "Health")
            }
        }
    }

    /// 停止后台同步
    public func stopBackgroundSync() {
        healthKitManager.stopBackgroundDelivery()
        Log.i("⏹️ 后台健康数据同步已停止", category: "Health")
    }

    /// 同步健康数据到服务器
    @MainActor
    private func syncHealthData() async {
        // 防止重复同步
        guard !isSyncInProgress else {
            Log.w("⚠️ 同步正在进行中，跳过本次请求", category: "Health")
            return
        }

        isSyncInProgress = true
        defer { isSyncInProgress = false }

        do {
            Log.i("📤 开始同步健康数据...", category: "Health")

            // 使用统一的健康数据采集方法
            let healthDataJSON = try await healthKitManager.fetchRecentDataAsJSON()

            // 上传到服务器
            try await uploadToServer(healthDataJSON)

            Log.i("✅ 健康数据同步成功", category: "Health")
        } catch {
            Log.e("❌ 健康数据同步失败: \(error.localizedDescription)", category: "Health")
        }
    }

    /// 上传数据到服务器
    private func uploadToServer(_ healthDataJSON: String) async throws {
        let apiClient = APIClient.shared

        // 将JSON字符串转换为字典
        guard let jsonData = healthDataJSON.data(using: .utf8),
              let dataDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
            throw NSError(domain: "HealthDataSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析健康数据JSON"])
        }

        // 创建可编码的请求体
        let requestBody = HealthDataUploadRequest(
            yesterdayData: dataDict["yesterday_data"] ?? "{}",
            todayData: dataDict["today_data"] ?? "{}",
            recentData: dataDict["recent_data"] ?? "{}"
        )

        // 构建 API 端点
        let endpoint = APIEndpoint(
            path: "/health/report",
            method: .post,
            body: requestBody,
            requiresAuth: true
        )

        // 发送 POST 请求
        let response: UploadResponse = try await apiClient.request(
            endpoint,
            responseType: UploadResponse.self
        )

        Log.i("✅ 服务器响应: \(response.message ?? "成功")", category: "Health")
    }
}

// MARK: - Request/Response Models

/// 健康数据上传请求体
private struct HealthDataUploadRequest: Encodable {
    let yesterdayData: String
    let todayData: String
    let recentData: String

    enum CodingKeys: String, CodingKey {
        case yesterdayData = "yesterday_data"
        case todayData = "today_data"
        case recentData = "recent_data"
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
