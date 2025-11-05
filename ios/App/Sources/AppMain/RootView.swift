//
//  RootView.swift
//  HealthBuddy
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import FeatureHealthKitApi
import LibraryServiceLoader

struct RootView: View {
    @State private var showingSplash: Bool = true

    private let healthKitFeature: FeatureHealthKitBuildable

    init(
        healthKitFeature: FeatureHealthKitBuildable = ServiceManager.shared.resolve(FeatureHealthKitBuildable.self)
    ) {
        self.healthKitFeature = healthKitFeature
    }

    var body: some View {
        ZStack {
            // HealthKit 主界面
            healthKitFeature.makeHealthKitDemoView()

            // Splash 启动画面
            if showingSplash {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        SplashView()
                    }
                    .zIndex(999)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: showingSplash)
                    .task {
                        await initializeApp()
                    }
            }
        }
    }

    // MARK: - Private Methods

    /// 初始化应用，显示启动画面
    private func initializeApp() async {
        let minimumSplashDuration: UInt64 = 1_500_000_000 // 1.5秒
        let startTime = DispatchTime.now()

        let elapsedTime = DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds
        if elapsedTime < minimumSplashDuration {
            try? await Task.sleep(nanoseconds: minimumSplashDuration - elapsedTime)
        }

        await MainActor.run {
            showingSplash = false
        }
    }
}

#Preview {
    RootView(
        healthKitFeature: PreviewHealthKitFeature()
    )
}

private struct PreviewHealthKitFeature: FeatureHealthKitBuildable {
    func makeAuthorizationView(onAuthorized: @escaping () -> Void) -> AnyView {
        AnyView(Text("Authorization Preview"))
    }

    func makeDashboardView() -> AnyView {
        AnyView(Text("Dashboard Preview"))
    }

    func makeHealthKitDemoView() -> AnyView {
        AnyView(Text("HealthKit Preview"))
    }
}
