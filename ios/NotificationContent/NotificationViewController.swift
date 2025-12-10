//
//  NotificationViewController.swift
//  NotificationContent
//
//  Custom notification content extension for ThriveBody
//

import UIKit
import UserNotifications
import UserNotificationsUI
import SwiftUI

/// Notification Content Extension Controller
/// Displays rich notification content using SwiftUI views similar to Live Activity
class NotificationViewController: UIViewController, UNNotificationContentExtension {

    private var hostingController: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        let categoryIdentifier = content.categoryIdentifier

        // Create appropriate view based on category
        let contentView: AnyView
        switch categoryIdentifier {
        case "AGENDA_BANNER":
            contentView = AnyView(
                AgendaNotificationView(
                    title: content.title,
                    bodyText: content.body
                )
            )
        case "INQUIRY_BANNER":
            contentView = AnyView(
                InquiryNotificationView(
                    title: content.title,
                    question: content.body
                )
            )
        default:
            contentView = AnyView(
                DefaultNotificationView(
                    title: content.title,
                    bodyText: content.body
                )
            )
        }

        // Remove existing hosting controller if any
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        // Add new hosting controller
        let hosting = UIHostingController(rootView: contentView)
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
        hostingController = hosting

        // Update preferred content size for taller notification
        preferredContentSize = CGSize(width: view.bounds.width, height: 280)
    }
}

// MARK: - Agenda Notification View

/// RPG-style notification view for Agenda tasks
struct AgendaNotificationView: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with app icon and status
            HStack(spacing: 10) {
                // App icon placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#10B981"), Color(hex: "#059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("ThriveBody")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("健康任务提醒")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                    Text("进行中")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "#F59E0B"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#FEF3C7"))
                )
            }

            Divider()

            // Task card
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(bodyText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#F3F4F6"))
            )

            // Action hint
            HStack {
                Spacer()
                Text("点击查看详情")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Inquiry Notification View

/// Notification view for Inquiry questions
struct InquiryNotificationView: View {
    let title: String
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Thinking emoji
                Text("👀")
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text("ThriveBody")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("想问你一个问题")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Question badge
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 12))
                    Text("问询")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(Color(hex: "#3B82F6"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#DBEAFE"))
                )
            }

            Divider()

            // Question content
            Text(question)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F3F4F6"))
                )

            // Action hint
            HStack {
                Spacer()
                Text("点击回答问题")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Default Notification View

/// Fallback view for other notification types
struct DefaultNotificationView: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 40, height: 40)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("ThriveBody")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)

                Text(bodyText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#F3F4F6"))
            )
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
