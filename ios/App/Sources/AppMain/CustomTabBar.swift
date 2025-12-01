//
//  CustomTabBar.swift
//  ThriveBody
//
//  Created by Claude on 2025/12/01.
//

import SwiftUI
import LibraryServiceLoader

/// 自定义底部Tab栏，包含两个Tab按钮和一个圆形对话按钮
struct CustomTabBar: View {
    @Binding var selectedTab: RouteManager.Tab
    let onChatTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 左侧：两个Tab按钮
            HStack(spacing: 8) {
                TabButton(
                    title: "今天",
                    systemImage: "calendar",
                    isSelected: selectedTab == .agenda,
                    action: { selectedTab = .agenda }
                )

                TabButton(
                    title: "关于我",
                    systemImage: "person.fill",
                    isSelected: selectedTab == .profile,
                    action: { selectedTab = .profile }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.gray.opacity(0.2))
            )

            Spacer()

            // 右侧：圆形对话按钮
            Button(action: onChatTapped) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 56, height: 56)

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
}

/// 单个Tab按钮
private struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
            )
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
        .background(Color.black)
    }
    .preferredColorScheme(.dark)
}
