import SwiftUI
import ThemeKit

/// 问询卡片视图 - 用于主动向用户提问
struct InquiryCardView: View {
    let card: InquiryCard
    let onOptionSelected: ((String) -> Void)?  // 选项选中回调

    init(card: InquiryCard, onOptionSelected: ((String) -> Void)? = nil) {
        self.card = card
        self.onOptionSelected = onOptionSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 问题区域
            HStack(alignment: .top, spacing: 12) {
                Text(card.emoji)
                    .font(.system(size: 24))

                Text(card.question)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.Palette.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 选项按钮
            FlowLayout(spacing: 8) {
                ForEach(card.options) { option in
                    InquiryOptionButton(option: option) {
                        onOptionSelected?(option.actionId)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.Palette.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .shadow(color: Color.Palette.textPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

/// 问询选项按钮
private struct InquiryOptionButton: View {
    let option: InquiryOption
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(option.emoji)
                    .font(.system(size: 16))

                Text(option.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.Palette.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? Color.Palette.infoBgSoft : Color.Palette.bgBase)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// 自动换行布局
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // 换行
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let samples = InquiryCard.sampleCards

    return ScrollView {
        VStack(spacing: 16) {
            ForEach(samples) { card in
                InquiryCardView(card: card) { actionId in
                    print("Selected: \(actionId)")
                }
            }
        }
        .padding()
    }
    .background(Color.Palette.bgBase)
}
