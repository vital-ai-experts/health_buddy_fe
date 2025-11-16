//
//  MainApp.swift
//  MainApp
//
//  Created by High on 2025/9/17.
//

import SwiftUI
import SwiftData
import DomainHealth
import FeatureChatImpl
import LibraryBase

@main
@MainActor
struct MainApp: App {
    // 集成 AppDelegate 处理推送通知
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // 创建 SwiftData 模型容器
    let modelContainer: ModelContainer

    init() {
        // 先配置服务
        AppComposition.bootstrap()

        do {
            // 配置 SwiftData 模型 - 使用迁移计划处理字段重命名
            let schema = Schema([
                HealthSection.self,
                HealthRow.self,
                LocalChatMessage.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            // 创建容器，启用自动迁移
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: nil,  // SwiftData 会尝试自动轻量级迁移
                configurations: [modelConfiguration]
            )

            Log.i("✅ SwiftData 模型容器初始化成功", category: "App")

            // 添加诊断：检查数据库中的消息数量
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<LocalChatMessage>()
            if let count = try? context.fetchCount(descriptor) {
                Log.i("📊 数据库中现有 \(count) 条消息", category: "App")
            }
        } catch {
            // 降级处理：使用内存模式
            Log.e("❌ 无法初始化持久化 ModelContainer: \(error)", category: "App")
            Log.w("⚠️ 可能原因: 模型字段变更(timestamp->createdAt)导致迁移失败", category: "App")
            Log.w("⚠️ 使用内存模式代替（数据将不会持久化）", category: "App")

            do {
                let schema = Schema([
                    HealthSection.self,
                    HealthRow.self,
                    LocalChatMessage.self
                ])

                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true  // 降级为内存模式
                )

                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )

                Log.i("✅ SwiftData 内存模式初始化成功", category: "App")
            } catch {
                // 真正无法恢复的错误
                fatalError("无法初始化 ModelContainer（包括内存模式）: \(error)")
            }
        }

        // 启动后台健康数据同步（异步，不会阻塞启动）
        HealthDataSyncService.shared.startBackgroundSync()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
