import SwiftUI
import ThemeKit

struct OnboardingFinishCardView: View {
    @EnvironmentObject private var flowController: OnboardingFlowController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已加入副本，查看今日任务吧！")
                .font(.headline.weight(.bold))
                .foregroundColor(.Palette.textPrimary)

            Button {
                flowController.finish()
            } label: {
                HStack {
                    Spacer()
                    Text("启动")
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.Palette.warningMain)
                .foregroundColor(.Palette.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

#Preview {
    OnboardingFinishCardView()
        .padding()
        .background(Color.Palette.bgBase)
        .preferredColorScheme(.dark)
        .environmentObject(OnboardingFlowController(finish: {}))
}
