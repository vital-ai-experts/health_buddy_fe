import SwiftUI
import LibraryServiceLoader

/// Agenda 主 Tab 视图，展示健康管理每日任务
struct AgendaTabView: View {
    @EnvironmentObject private var router: RouteManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Agenda Tab")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)

                Text("重新设计中...")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.94))
        .onAppear {
            router.currentTab = .agenda
        }
    }
}

#Preview {
    AgendaTabView()
        .environmentObject(RouteManager())
}
