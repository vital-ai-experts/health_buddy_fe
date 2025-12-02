import SwiftUI
import ThemeKit

/// 聊天输入框视图
public struct ChatInputView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let onSend: () -> Void

    // Mock Tags
    private let mockTags = ["深度思考", "AI 创作", "豆包 P 图", "拍照搜题"]
    @State private var selectedTag: String?

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
        VStack(alignment: .leading, spacing: 12) {
            // Tags View
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mockTags, id: \.self) { tag in
                        Button(action: {
                            if selectedTag == tag {
                                selectedTag = nil
                            } else {
                                selectedTag = tag
                            }
                        }) {
                            Text(tag)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedTag == tag ? .blue : Color.Palette.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.Palette.surfaceElevated)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(selectedTag == tag ? Color.blue : Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                                )
                                .shadow(color: Color.Palette.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Input Area
            ZStack(alignment: .bottomTrailing) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 40) // Make room for the button
                    .background(Color.Palette.bgMuted)
                    .cornerRadius(12)
                    .lineLimit(1...3)
                    .focused($isFocused)
                    .disabled(isLoading)

                if canSend {
                    Button(action: handleSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color.Palette.infoMain)
                            .background(Circle().fill(Color.white)) // Add white background to button to cover text if needed
                    }
                    .padding(.bottom, 4)
                    .padding(.trailing, 4)
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private func handleSend() {
        if let tag = selectedTag {
            text = "#\(tag) \(text)"
        }
        onSend()
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
                    onSend: {
                        print("Sent: \(text)")
                        text = ""
                    }
                )
                .background(Color.white)
            }
        }
    }
    
    return PreviewWrapper()
}
