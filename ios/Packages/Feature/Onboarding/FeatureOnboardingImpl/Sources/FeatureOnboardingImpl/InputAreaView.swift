import SwiftUI

/// 输入区域视图
struct InputAreaView: View {
    @Binding var text: String
    var isInputFocused: FocusState<Bool>.Binding
    let isLoading: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("输入你的回答...", text: $text)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(24)
                .focused(isInputFocused)
                .submitLabel(.send)
                .onSubmit(onSubmit)
                .disabled(isLoading)
            
            // Send button
            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }
}

