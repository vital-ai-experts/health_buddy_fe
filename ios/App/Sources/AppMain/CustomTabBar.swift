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
    @State private var indicatorOffset: CGFloat = 0
    @State private var isDragging: Bool = false

    private let tabs: [(tab: RouteManager.Tab, icon: String, title: String)] = [
        (.agenda, "calendar", "今天"),
        (.profile, "person.fill", "关于我")
    ]

    // 每个 tab item 的固定宽度
    private let tabItemWidth: CGFloat = 72
    // 内边距
    private let horizontalPadding: CGFloat = 8
    // TabBar 高度
    private let tabBarHeight: CGFloat = 56

    private var tabBarWidth: CGFloat {
        CGFloat(tabs.count) * tabItemWidth + horizontalPadding * 2
    }

    private var selectedIndex: Int {
        tabs.firstIndex(where: { $0.tab == selectedTab }) ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // TabBar容器 - 固定宽度
            ZStack {
                // 液态玻璃背景
                glassBackground

                // 选中指示器 - 跟随手指或选中状态
                indicatorView

                // Tab items
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, item in
                        TabBarItem(
                            icon: item.icon,
                            title: item.title,
                            isSelected: selectedTab == item.tab
                        )
                        .frame(width: tabItemWidth, height: tabBarHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = item.tab
                                indicatorOffset = CGFloat(index) * tabItemWidth
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
            .frame(width: tabBarWidth, height: tabBarHeight)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        // 计算拖动偏移量，限制在有效范围内
                        let maxOffset = CGFloat(tabs.count - 1) * tabItemWidth
                        let baseOffset = CGFloat(selectedIndex) * tabItemWidth
                        let newOffset = baseOffset + value.translation.width
                        indicatorOffset = min(max(0, newOffset), maxOffset)
                    }
                    .onEnded { _ in
                        // 根据当前位置确定最终选中的 tab
                        let targetIndex = Int(round(indicatorOffset / tabItemWidth))
                        let clampedIndex = min(max(0, targetIndex), tabs.count - 1)

                        // 先更新 selectedTab，然后动画移动到目标位置
                        // indicatorOffset 保持当前位置，动画会从当前位置移动到目标
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tabs[clampedIndex].tab
                            indicatorOffset = CGFloat(clampedIndex) * tabItemWidth
                        }
                        isDragging = false
                    }
            )
            .onChange(of: selectedTab) { _, _ in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        indicatorOffset = CGFloat(selectedIndex) * tabItemWidth
                    }
                }
            }
            .onAppear {
                indicatorOffset = CGFloat(selectedIndex) * tabItemWidth
            }

            // 对话按钮 - 紧跟 TabBar
            Button(action: onChatTapped) {
                VStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 22))
                    Text("对话")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
                .frame(width: tabBarHeight, height: tabBarHeight)
                .background(chatButtonBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // 间距放在对话按钮右边
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var indicatorView: some View {
        let indicatorWidth = tabItemWidth - 8
        let indicatorHeight = tabBarHeight - 8
        let xOffset = horizontalPadding + 4 + indicatorOffset

        Capsule()
            .fill(Color.white.opacity(colorScheme == .dark ? 0.15 : 0.25))
            .frame(width: indicatorWidth, height: indicatorHeight)
            .offset(x: xOffset - tabBarWidth / 2 + indicatorWidth / 2)
    }

    @ViewBuilder
    private var glassBackground: some View {
        // 使用普通模糊材质
        Capsule()
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.95 : 0.85)
    }

    @ViewBuilder
    private var chatButtonBackground: some View {
        // 使用普通模糊材质
        Circle()
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.95 : 0.85)
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
