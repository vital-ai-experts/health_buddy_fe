//
//  HealthBuddyApp.swift
//  HealthBuddy
//
//  Created by High on 2025/9/17.
//

import SwiftUI
import SwiftData
import DomainHealth

@main
@MainActor
struct HealthBuddyApp: App {
    // 创建 SwiftData 模型容器
    let modelContainer: ModelContainer

    init() {
        AppComposition.bootstrap()
        do {
            // 配置 SwiftData 模型
            let schema = Schema([
                HealthSection.self,
                HealthRow.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
