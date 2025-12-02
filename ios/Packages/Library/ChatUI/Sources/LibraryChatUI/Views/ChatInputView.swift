import SwiftUI
import ThemeKit

/// 聊天输入框视图
public struct ChatInputView: View {
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    let isLoading: Bool
    let tags: [ChatTag]
    @Binding var selectedTagId: String?
    let onSend: () -> Void

    public init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        isLoading: Bool,
        tags: [ChatTag] = [],
        selectedTagId: Binding<String?> = .constant(nil),
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self._isFocused = isFocused
        self.isLoading = isLoading
        self.tags = tags
        self._selectedTagId = selectedTagId
        self.onSend = onSend
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tags View
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tags) { tag in
                            let isSelected = selectedTagId == tag.id
                            Button(action: {
                                selectedTagId = isSelected ? nil : tag.id
                            }) {
                                Text(tag.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(isSelected ? Color.Palette.infoMain : Color.Palette.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.Palette.surfaceElevated)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(isSelected ? Color.Palette.infoMain : Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                                    )
                                    .shadow(color: Color.Palette.textPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            // Input Area
            ZStack(alignment: .bottomTrailing) {
                TextField("在这里输入...", text: $text, axis: .vertical)
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
        onSend()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool
        @State private var selectedTagId: String?
        
        var body: some View {
            VStack {
                Spacer()
                ChatInputView(
                    text: $text,
                    isFocused: $isFocused,
                    isLoading: false,
                    tags: [
                        ChatTag(id: "sleep_master", title: "睡眠大师"),
                        ChatTag(id: "strong_me", title: "强壮的我"),
                        ChatTag(id: "wall_street_wolf", title: "华尔街之狼")
                    ],
                    selectedTagId: $selectedTagId,
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
