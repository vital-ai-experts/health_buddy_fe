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

    @State private var dragLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @Namespace private var animation

    private let tabs: [(tab: RouteManager.Tab, icon: String, title: String)] = [
        (.agenda, "calendar", "今天"),
        (.profile, "person.fill", "关于我")
    ]

    var body: some View {
        HStack(spacing: 0) {
            // TabBar容器
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, item in
                    TabBarItem(
                        icon: item.icon,
                        title: item.title,
                        isSelected: selectedTab == item.tab,
                        namespace: animation
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
            .frame(height: 50)
            .background(
                ZStack {
                    // 背景毛玻璃效果
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)

                    // 液态玻璃选中指示器
                    GeometryReader { geometry in
                        let tabWidth = geometry.size.width / CGFloat(tabs.count)
                        let selectedIndex = tabs.firstIndex(where: { $0.tab == selectedTab }) ?? 0

                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: tabWidth - 8, height: 40)
                            .offset(x: CGFloat(selectedIndex) * tabWidth + 4, y: 5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        dragLocation = value.location
                        updateSelectionFromDrag(location: value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )

            Spacer()
                .frame(width: 12)

            // 圆形对话按钮
            Button(action: onChatTapped) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 56, height: 56)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                    Image(systemName: "message.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }

    private func updateSelectionFromDrag(location: CGPoint) {
        // 获取TabBar容器的总宽度（需要考虑实际布局）
        // 这里简化处理：根据x位置判断选中哪个tab
        let screenWidth = UIScreen.main.bounds.width - 32 - 56 - 12 // 减去padding和按钮
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
    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .gray)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .white : .gray)
        }
        .frame(maxWidth: .infinity)
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
}
