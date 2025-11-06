import SwiftUI

/// 用户消息气泡视图
struct UserMessageBubble: View {
    let message: MessageItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Spacer()
            
            // Message bubble
            Text(message.text)
                .font(.body)
                .padding(16)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            // User Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
        }
    }
}

