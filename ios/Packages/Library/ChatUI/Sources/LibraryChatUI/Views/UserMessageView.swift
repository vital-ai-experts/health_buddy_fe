import SwiftUI
import ThemeKit

/// SwiftUI view for displaying user messages
public struct UserMessageView: View {
    let message: UserMessage
    let configuration: ChatConfiguration

    public init(message: UserMessage, configuration: ChatConfiguration = .default) {
        self.message = message
        self.configuration = configuration
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer(minLength: MessageViewConstants.MESSAGE_SPACING)

            VStack(alignment: .trailing, spacing: 4) {
                // 如果有图片，先显示图片
                if let images = message.images, !images.isEmpty {
                    VStack(alignment: .trailing, spacing: 8) {
                        ForEach(images, id: \.id) { imageItem in
                            MessageImageView(imageItem: imageItem)
                        }
                    }
                }

                // 如果有文本，显示文本
                if !message.text.isEmpty {
                    Text(message.text)
                        .font(configuration.messageFont)
                        .foregroundColor(configuration.userMessageTextColor)
                        .padding(12)
                        .background(configuration.userMessageBackgroundColor)
                        .cornerRadius(16)
                        .textSelection(.enabled)
                }

                if configuration.showTimestamp {
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// 用于显示消息中的图片
private struct MessageImageView: View {
    let imageItem: MessageImage

    var body: some View {
        Group {
            if let url = imageItem.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 200, height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipped()
                    case .failure:
                        mockPhotoPlaceholder
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let bundle = imageItem.bundle,
                      let uiImage = UIImage(named: imageItem.imageName, in: bundle, with: nil) {
                // 从指定 Bundle 加载图片
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipped()
            } else if let uiImage = UIImage(named: imageItem.imageName) {
                // 从主 Bundle 加载图片
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .clipped()
            } else {
                // 找不到图片时的占位符
                mockPhotoPlaceholder
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }

    /// 模拟照片的占位符视图
    private var mockPhotoPlaceholder: some View {
        ZStack {
            // 天空渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.cyan.opacity(0.4),
                    Color.white.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 8) {
                // 太阳图标
                Image(systemName: "sun.max.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.yellow)

                // 云朵
                Image(systemName: "cloud.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 20)
                    .foregroundColor(.white.opacity(0.9))
                    .offset(x: 25, y: -10)
            }
        }
        .frame(width: 200, height: 150)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UserMessageView(
            message: UserMessage(
                text: "Hello, how are you?",
                timestamp: Date(),
                goalTitle: "睡眠大师"
            )
        )

        UserMessageView(
            message: UserMessage(
                text: "This is a longer message to test how the view handles multiple lines of text. It should wrap properly and maintain good readability.",
                timestamp: Date()
            )
        )
    }
    .padding()
}
