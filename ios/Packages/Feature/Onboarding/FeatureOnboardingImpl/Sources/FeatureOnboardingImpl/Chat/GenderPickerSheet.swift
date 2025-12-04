import SwiftUI
import ThemeKit

struct GenderPickerSheet: View {
    let options: [String] = ["男", "女", "其他"]
    @State var selected: String
    let onConfirm: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Text(option)
                        Spacer()
                        if option == selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.Palette.successMain)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selected = option
                    }
                }
            }
            .navigationTitle("选择性别")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        onConfirm(selected)
                    }
                }
            }
        }
    }
}
