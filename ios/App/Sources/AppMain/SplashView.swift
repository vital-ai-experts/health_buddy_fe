//
//  SplashView.swift
//  HealthBuddy
//
//  Created by Claude on 2025/10/22.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var heartbeatAnimation = false
    @State private var showAppName = false

    var body: some View {
        ZStack {
            // 浅绿色健康主题渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.95, blue: 0.88), // 很浅的薄荷绿
                    Color(red: 0.75, green: 0.92, blue: 0.82), // 浅绿色
                    Color(red: 0.65, green: 0.88, blue: 0.76)  // 稍深的浅绿色
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 动态背景效果
            HealthBackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Logo with heartbeat animation
                ZStack {
                    // 脉冲效果
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.73, blue: 0.50).opacity(0.3), // 绿色脉冲
                                    Color(red: 0.35, green: 0.73, blue: 0.50).opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)

                    // 主图标 - App Logo
                    Image("LaunchLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color(red: 0.35, green: 0.73, blue: 0.50).opacity(0.4), radius: 20, x: 0, y: 10)
                        .scaleEffect(logoScale)
                        .scaleEffect(heartbeatAnimation ? 1.05 : 1.0)
                        .opacity(logoOpacity)
                }

                // App 名称 - 使用深绿色
                Text("HealthBuddy")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.55, blue: 0.40))
                    .opacity(showAppName ? 1.0 : 0.0)
                    .offset(y: showAppName ? 0 : 20)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Logo 缩放和淡入动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.8)) {
            logoOpacity = 1.0
        }

        // App 名称延迟出现
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showAppName = true
        }

        // 脉冲动画
        withAnimation(
            .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: false)
        ) {
            pulseScale = 1.5
        }

        // 心跳动画
        withAnimation(
            .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(0.5)
        ) {
            heartbeatAnimation = true
        }
    }
}

// MARK: - 健康主题背景动画视图

struct HealthBackgroundView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // 浮动的心形粒子效果 - 使用珊瑚色和绿色
            ForEach(0..<5) { index in
                Image(systemName: "heart.fill")
                    .font(.system(size: CGFloat.random(in: 20...40)))
                    .foregroundColor(
                        index % 2 == 0
                        ? Color(red: 0.98, green: 0.55, blue: 0.50).opacity(0.15) // 珊瑚色
                        : Color(red: 0.35, green: 0.73, blue: 0.50).opacity(0.15) // 绿色
                    )
                    .offset(
                        x: animate ? CGFloat.random(in: -150...150) : CGFloat.random(in: -50...50),
                        y: animate ? CGFloat.random(in: -200...200) : CGFloat.random(in: -100...100)
                    )
                    .rotationEffect(.degrees(animate ? Double.random(in: -30...30) : 0))
                    .blur(radius: 3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 4.0...7.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: animate
                    )
            }

            // 脉冲波纹效果 - 绿色主题
            ForEach(0..<2) { index in
                Circle()
                    .stroke(Color(red: 0.35, green: 0.73, blue: 0.50).opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 2.0 : 1.0)
                    .opacity(animate ? 0.0 : 0.3)
                    .animation(
                        .easeOut(duration: 3.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 1.5),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    SplashView()
}
