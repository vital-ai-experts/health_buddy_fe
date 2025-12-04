import SwiftUI
import ThemeKit

struct NumberPickerSheet: View {
    let title: String
    let range: ClosedRange<Int>
    let unit: String
    @Binding var value: Int
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Picker(title, selection: $value) {
                    ForEach(Array(range), id: \.self) { number in
                        Text("\(number) \(unit)").tag(number)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 250)
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        onConfirm(value)
                    }
                }
            }
        }
    }
}
