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
            // 配置 SwiftData 模型
            let schema = Schema([
                HealthSection.self,
                HealthRow.self,
                LocalChatMessage.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            print("✅ SwiftData 模型容器初始化成功")
        } catch {
            // 降级处理：使用内存模式
            print("⚠️ 无法初始化持久化 ModelContainer: \(error)")
            print("⚠️ 使用内存模式代替")

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

                print("✅ SwiftData 内存模式初始化成功")
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
