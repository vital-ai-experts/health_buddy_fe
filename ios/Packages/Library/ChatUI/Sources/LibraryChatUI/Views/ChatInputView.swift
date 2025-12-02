import SwiftUI
import ThemeKit

/// 聊天输入框视图
public struct ChatInputView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let onSend: () -> Void

    public init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        isLoading: Bool,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self.isLoading = isLoading
        self.onSend = onSend
    }

    public var body: some View {
        HStack(spacing: 12) {
            // 输入框
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.Palette.bgMuted)
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isFocused)
                .disabled(isLoading)

            // 发送按钮
            Button(action: onSend) {
                Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(canSend ? Color.Palette.infoMain : Color.Palette.textDisabled)
            }
            .disabled(!canSend && !isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Hello"
        @FocusState private var isFocused: Bool
        
        var body: some View {
            VStack {
                Spacer()
                ChatInputView(
                    text: $text,
                    isFocused: $isFocused,
                    isLoading: false,
                    onSend: {}
                )
            }
        }
    }
    
    return PreviewWrapper()
}
