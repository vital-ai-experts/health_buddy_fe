import SwiftUI
import ThemeKit

struct OnboardingSingleChoiceCardView: View {
    let payload: SingleChoiceCardPayload?
    let onSelect: (SingleChoiceCardPayload.Option) -> Void

    @State private var selectedId: String?
    @State private var isLocked: Bool = false
    @State private var selectedTitle: String?

    init(
        payload: SingleChoiceCardPayload?,
        onSelect: @escaping (SingleChoiceCardPayload.Option) -> Void
    ) {
        self.payload = payload
        self.onSelect = onSelect
        if let preset = payload?.selectedId,
           let option = payload?.options.first(where: { $0.id == preset }) {
            _selectedId = State(initialValue: preset)
            _selectedTitle = State(initialValue: option.title)
            _isLocked = State(initialValue: true)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payload?.title ?? "请选择")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.Palette.textPrimary)
                if let description = payload?.description {
                    Text(description)
                        .font(.footnote)
                        .foregroundColor(.Palette.textSecondary)
                }
            }

            VStack(spacing: 10) {
                ForEach(payload?.options ?? []) { option in
                    Button {
                        handleSelect(option)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Image(systemName: selectedId == option.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedId == option.id ? .Palette.successMain : .Palette.textSecondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .foregroundColor(.Palette.textPrimary)
                                    .font(.callout.weight(.semibold))
                                if let subtitle = option.subtitle {
                                    Text(subtitle)
                                        .foregroundColor(.Palette.textSecondary)
                                        .font(.footnote)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.Palette.bgMuted)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selectedId == option.id ? Color.Palette.successMain.opacity(0.7) : Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isLocked)
                }
            }

            if isLocked {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = selectedTitle {
                        Text("已选择：\(title)")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.Palette.textPrimary)
                    }
                    if let cta = payload?.ctaTitle {
                        Text(cta)
                            .font(.footnote)
                            .foregroundColor(.Palette.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension OnboardingSingleChoiceCardView {
    func handleSelect(_ option: SingleChoiceCardPayload.Option) {
        guard !isLocked else { return }
        selectedId = option.id
        selectedTitle = option.title
        isLocked = true
        onSelect(option)
    }
}

#Preview {
    OnboardingSingleChoiceCardView(
        payload: SingleChoiceCardPayload(
            title: "你的性别",
            description: "选择后继续定制方案",
            options: [
                .init(id: "male", title: "男", subtitle: nil),
                .init(id: "female", title: "女", subtitle: nil),
                .init(id: "secret", title: "保密", subtitle: nil)
            ],
            ctaTitle: "正在生成下一步...",
            selectedId: nil
        ),
        onSelect: { _ in }
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
}
