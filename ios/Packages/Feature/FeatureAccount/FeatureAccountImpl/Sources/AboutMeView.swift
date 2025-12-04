import SwiftUI
import DomainAuth
import LibraryServiceLoader
import LibraryBase
import ThemeKit

/// 关于我页面 - 展示AI对用户的全部理解和数字孪生
public struct AboutMeView: View {
    @State private var user: DomainAuth.User?
    @State private var isLoading = true
    @State private var showingInfoSheet = false
    @State private var editingSection: AboutMeSection?
    @State private var aboutMeData = AboutMeData.mock

    private let authService: AuthenticationService

    public init(
        authService: AuthenticationService = ServiceManager.shared.resolve(AuthenticationService.self)
    ) {
        self.authService = authService
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部：头像和昵称
                headerSection
                    .padding(.top, 32)
                    .padding(.bottom, 40)

                // AI对用户的理解内容
                contentSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.Palette.bgBase)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserInfo()
        }
        .sheet(isPresented: $showingInfoSheet) {
            infoSheetContent
        }
        .sheet(item: $editingSection) { section in
            AboutMeEditSheet(section: section, data: $aboutMeData)
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 16) {
            if isLoading {
                ProgressView()
            } else {
                // 头像 - 猫猫
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.Palette.warningMain.opacity(0.3), Color.Palette.warningMain.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text("🐱")
                        .font(.system(size: 48))
                }

                // 昵称
                Text("凌安")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.Palette.textPrimary)
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Content Section

    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 24) {
            // 模块标题：关于我
            sectionHeader(
                title: "关于我",
                showInfo: true,
                onInfoTapped: { showingInfoSheet = true }
            )

            // 更新时间 - 特殊样式的浅灰色文字
            HStack {
                Text("内容更新：\(aboutMeData.updateTime)")
                    .font(.system(size: 13))
                    .foregroundColor(.Palette.textSecondary.opacity(0.5))
                Spacer()
            }
            .padding(.bottom, 8)

            // 近期模式回溯
            RecentPatternCardView(
                data: aboutMeData.recentPattern,
                onEdit: { editingSection = .recentPattern }
            )

            // 目标与核心驱动
            GoalsCardView(
                data: aboutMeData.goals,
                onEdit: { editingSection = .goals }
            )

            // 生理信息
            BioHardwareCardView(
                data: aboutMeData.bioHardware,
                onEdit: { editingSection = .bioHardware }
            )

            // 行为与偏好
            NeuroSoftwareCardView(
                data: aboutMeData.neuroSoftware,
                onEdit: { editingSection = .neuroSoftware }
            )

            // 历史档案
            ArchivesCardView(
                data: aboutMeData.archives,
                onEdit: { editingSection = .archives }
            )
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, showInfo: Bool = false, onInfoTapped: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.Palette.textPrimary)

            if showInfo {
                Button(action: onInfoTapped) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.Palette.textSecondary)
                        .foregroundColor(.Palette.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.bottom, 8)
    }

    // MARK: - Info Sheet

    @ViewBuilder
    private var infoSheetContent: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("这是基于我们过去的 42 次对话、Onboarding 访谈以及 14 天的穿戴数据，我为你构建的\"数字孪生\"。")
                        .font(.system(size: 16))
                        .foregroundColor(.Palette.textPrimary)
                        .lineSpacing(6)

                    Text("如果我有理解错的地方，请随时点击修正。你的修正会让我的决策更精准。")
                        .font(.system(size: 16))
                        .foregroundColor(.Palette.textPrimary)
                        .lineSpacing(6)
                }
                .padding(24)
            }
            .navigationTitle("关于数字孪生")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        showingInfoSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Data Loading

    private func loadUserInfo() async {
        isLoading = true
        do {
            user = try await authService.getCurrentUser()
        } catch {
            Log.e("Failed to load user info: \(error)", category: "AboutMe")
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        AboutMeView()
    }
}
