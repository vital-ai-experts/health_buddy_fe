//
//  CustomTabBar.swift
//  ThriveBody
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI
import LibraryServiceLoader

/// 自定义TabBar，支持液态玻璃拖动效果
struct CustomTabBar: View {
    @Binding var selectedTab: RouteManager.Tab
    let onChatTapped: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isDragging: Bool = false
    @Namespace private var animation

    private let tabs: [(tab: RouteManager.Tab, icon: String, title: String)] = [
        (.agenda, "calendar", "今天"),
        (.profile, "person.fill", "关于我")
    ]

    var body: some View {
        HStack(spacing: 12) {
            // TabBar容器
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, item in
                    TabBarItem(
                        icon: item.icon,
                        title: item.title,
                        isSelected: selectedTab == item.tab
                    )
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = item.tab
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    // 液态玻璃背景
                    glassBackground

                    // 液态玻璃选中指示器
                    GeometryReader { geometry in
                        let tabWidth = geometry.size.width / CGFloat(tabs.count)
                        let selectedIndex = tabs.firstIndex(where: { $0.tab == selectedTab }) ?? 0

                        Capsule()
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25))
                            .frame(width: tabWidth - 16, height: 44)
                            .offset(x: CGFloat(selectedIndex) * tabWidth + 8, y: 0)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
                    }
                }
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        updateSelectionFromDrag(location: value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            // 圆形对话按钮
            Button(action: onChatTapped) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: "message.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var glassBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.95 : 0.85)
    }

    private func updateSelectionFromDrag(location: CGPoint) {
        // 获取TabBar容器的总宽度
        let screenWidth = UIScreen.main.bounds.width - 32 - 56 - 12 - 24 // 减去所有padding
        let tabWidth = screenWidth / CGFloat(tabs.count)
        let index = Int(location.x / tabWidth)

        if index >= 0 && index < tabs.count {
            let newTab = tabs[index].tab
            if newTab != selectedTab {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = newTab
                }
            }
        }
    }
}

/// TabBar单个Item
private struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)

            Text(title)
                .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(
            selectedTab: .constant(.agenda),
            onChatTapped: { print("Chat tapped") }
        )
        .preferredColorScheme(.dark)
    }
    .background(Color.black)
}
