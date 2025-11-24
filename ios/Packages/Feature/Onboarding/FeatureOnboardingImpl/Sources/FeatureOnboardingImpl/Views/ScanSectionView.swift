import SwiftUI

struct ScanSectionView: View {
    let isCompleted: Bool
    let lines: [OnboardingScanLine]

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                if isCompleted {
                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.green.opacity(0.6), radius: 8)
                    Text("已生成初步诊断")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    ProgressView()
                        .tint(.green)
                    Text("正在同步你的身体数据")
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
            }

            ScanTickerView(lines: lines)
                .frame(maxHeight: 360)
        }
    }
}

private struct ScanTickerView: View {
    let lines: [OnboardingScanLine]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                ForEach(lines) { line in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.green.opacity(0.9))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.6), radius: 8)
                        Text(line.text)
                            .foregroundColor(.white)
                            .font(.callout)
                        Spacer()
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding(18)
        }
    }
}
