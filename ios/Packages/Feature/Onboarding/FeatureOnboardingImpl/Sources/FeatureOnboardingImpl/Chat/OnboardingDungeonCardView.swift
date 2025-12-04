import SwiftUI
import ThemeKit
import FeatureAgendaApi
import LibraryServiceLoader

struct OnboardingDungeonCardView: View {
    @EnvironmentObject private var flowController: OnboardingFlowController

    let payload: DungeonCardPayload?
    @State private var showDetail = false
    private let agendaFeature: FeatureAgendaBuildable

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(payload?.title ?? "已加入副本")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.Palette.textPrimary)
                if let subtitle = payload?.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.Palette.textSecondary)
                }
                if let detail = payload?.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.Palette.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Button(action: { showDetail = true }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text(payload?.secondaryAction ?? "查看详情")
                    }
                    .font(.callout.weight(.semibold))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.Palette.warningBgSoft)
                    .foregroundColor(.Palette.warningText)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: onStartDungeon) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text(payload?.primaryAction ?? "开启副本")
                    }
                    .font(.callout.weight(.semibold))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.Palette.warningMain)
                    .foregroundColor(.Palette.textOnAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
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
        .sheet(isPresented: $showDetail) {
            agendaFeature.makeDungeonDetailView {
                showDetail = false
                onStartDungeon()
            }
        }
    }

    init(
        payload: DungeonCardPayload?,
        agendaFeature: FeatureAgendaBuildable = ServiceManager.shared.resolveOptional(FeatureAgendaBuildable.self) ?? PreviewAgendaFeature()
    ) {
        self.payload = payload
        self.agendaFeature = agendaFeature
    }
    
    private func onStartDungeon() {
        flowController.finish()
    }
}

#Preview {
    let payload = DungeonCardPayload(
        title: "已加入副本，查看今日任务吧！",
        subtitle: "睡眠恢复计划",
        detail: "我们已为你生成今日的优先任务。点击查看详情或直接开启副本，任务会同步到首页。",
        primaryAction: "开启副本",
        secondaryAction: "查看详情"
    )
    return OnboardingDungeonCardView(
        payload: payload,
        agendaFeature: PreviewAgendaFeature()
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
    .environmentObject(OnboardingFlowController(finish: {}))
}

private struct PreviewAgendaFeature: FeatureAgendaBuildable {
    func makeAgendaTabView() -> AnyView { AnyView(Text("Agenda Tab")) }
    func makeAgendaSettingsView() -> AnyView { AnyView(Text("Agenda Settings")) }
    func makeDungeonDetailView() -> AnyView { AnyView(Text("Dungeon Detail")) }
    func makeDungeonDetailView(onStart: @escaping () -> Void) -> AnyView {
        AnyView(
            VStack {
                Text("Dungeon Detail Preview")
                Button("Start", action: onStart)
            }
        )
    }
}
