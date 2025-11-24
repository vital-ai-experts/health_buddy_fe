import SwiftUI
import FeatureOnboardingApi
import LibraryBase
import LibraryServiceLoader
import ThemeKit

private enum OnboardingStep: Int, CaseIterable {
    case intro
    case scan
    case profile

    var title: String {
        switch self {
        case .intro: return "极简启动"
        case .scan: return "数据扫描"
        case .profile: return "确认信息"
        }
    }
}

private struct ScanLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

private struct OnboardingIssueOption: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
}

private struct OnboardingProfileSnapshot {
    let gender: String
    let age: Int
    let height: Int
    let weight: Int
}

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @State private var introLine1Started = false
    @State private var introLine2Started = false
    @State private var introLine3Started = false
    @State private var introTypingCompleted = false

    private var shouldShowProgressAndButton: Bool {
        viewModel.step != .intro || introTypingCompleted
    }

    init(
        onComplete: @escaping () -> Void,
        stateManager: OnboardingStateManaging = ServiceManager.shared.resolve(OnboardingStateManaging.self)
    ) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            stateManager: stateManager,
            onComplete: onComplete
        ))
    }

    var body: some View {
        ZStack {
            background(for: viewModel.step)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 0)

                switch viewModel.step {
                case .intro:
                    introSection
                case .scan:
                    scanSection
                case .profile:
                    profileSection
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.step == .intro {
                BreathingDotView()
                    .padding(.trailing, -12)
                    .padding(.bottom, 100)
            }
        }
        .overlay(alignment: .top) {
            if shouldShowProgressAndButton {
                progressIndicator
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) {
            if shouldShowProgressAndButton {
                primaryButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .onChange(of: viewModel.step) { _, newValue in
            if newValue == .scan {
                viewModel.startScanIfNeeded()
            }
            if newValue == .intro && !introLine1Started {
                introLine1Started = true
            }
        }
        .onAppear {
            if !introLine1Started {
                introLine1Started = true
            }
        }
        .animation(.easeInOut(duration: 0.35), value: shouldShowProgressAndButton)
    }

    private var progressIndicator: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.step.rawValue ? Color.green.opacity(0.9) : Color.white.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TypingTextView(
                text: "你的身体每时每刻都在产生数据，但你从未真正读懂它。",
                font: .title3.weight(.semibold),
                color: .white,
                start: introLine1Started,
                charactersPerSecond: 14,
                initialDelay: 0.05
            ) {
                introLine2Started = true
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TypingTextView(
                text: "我们不提供通用的健康建议。",
                font: .body,
                color: Color.white.opacity(0.85),
                start: introLine2Started,
                charactersPerSecond: 18,
                initialDelay: 0.05
            ) {
                introLine3Started = true
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TypingTextView(
                text: "我们读取你的生物数据，为你定制每天的行动战术。",
                font: .body,
                color: Color.white.opacity(0.85),
                start: introLine3Started,
                charactersPerSecond: 18,
                initialDelay: 0.05
            ) {
                introTypingCompleted = true
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -160)
    }

    private var scanSection: some View {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                if viewModel.isScanCompleted {
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

            ScanTicker(lines: viewModel.visibleScanLines)
                .frame(maxHeight: 360)
        }
    }

    private var profileSection: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("确认信息")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                }

                ProfileCard(snapshot: viewModel.profileSnapshot)

                VStack(alignment: .leading, spacing: 10) {
                    Label("关键问题", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.green.opacity(0.9))

                    VStack(spacing: 12) {
                        ForEach(viewModel.issueOptions) { option in
                            IssueRow(
                                option: option,
                                isSelected: viewModel.selectedIssueID == option.id
                            ) {
                                viewModel.selectIssue(option.id)
                            }
                        }
                    }
                }

                if let selected = viewModel.selectedIssue {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("已选策略")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green.opacity(0.9))
                        Text(selected.title)
                            .foregroundColor(.white)
                            .font(.body)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var primaryButton: some View {
        Button(action: {
            viewModel.handlePrimaryAction()
        }) {
            HStack {
                Text(viewModel.primaryButtonTitle)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.bold))
            }
            .foregroundColor(.black)
            .padding()
            .background(viewModel.isPrimaryButtonDisabled ? Color.white.opacity(0.35) : Color.green.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.green.opacity(0.35), radius: 12, y: 6)
        }
        .disabled(viewModel.isPrimaryButtonDisabled)
    }

    @ViewBuilder
    private func background(for step: OnboardingStep) -> some View {
        return Color.black
//        switch step {
//        case .intro:
//            Color.black
//        case .scan:
//            LinearGradient(
//                colors: [
//                    Color.black,
//                    Color(red: 0.03, green: 0.18, blue: 0.10)
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        case .profile:
//            LinearGradient(
//                colors: [
//                    Color.black,
//                    Color(red: 0.07, green: 0.09, blue: 0.12)
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        }
    }
}

@MainActor
private final class OnboardingViewModel: ObservableObject {
    @Published var step: OnboardingStep = .intro
    @Published var visibleScanLines: [ScanLine] = []
    @Published var isScanCompleted = false
    @Published var selectedIssueID: String

    let issueOptions: [OnboardingIssueOption]
    let profileSnapshot = OnboardingProfileSnapshot(
        gender: "男",
        age: 30,
        height: 178,
        weight: 75
    )

    private let scanLines: [ScanLine] = [
        ScanLine(text: "正在读取过去 30 天睡眠记录..."),
        ScanLine(text: "发现异常静息心率波动..."),
        ScanLine(text: "识别到深夜屏幕使用模式"),
        ScanLine(text: "···"),
        ScanLine(text: "初步诊断生成中...")
    ]

    private let stateManager: OnboardingStateManaging
    private let onComplete: () -> Void
    private var scanTask: Task<Void, Never>?

    init(
        stateManager: OnboardingStateManaging,
        onComplete: @escaping () -> Void
    ) {
        self.stateManager = stateManager
        self.onComplete = onComplete

        self.issueOptions = [
            OnboardingIssueOption(
                id: "fatigue",
                title: "虽然睡够了 7 小时，但醒来依然像没睡一样累",
                detail: "AI 检测到深睡占比 < 10%"
            ),
            OnboardingIssueOption(
                id: "focus",
                title: "下午 3 点后注意力很难集中，必须靠咖啡续命",
                detail: "AI 检测到日间久坐 + 心率变异性低"
            ),
            OnboardingIssueOption(
                id: "bloat",
                title: "体重正常，但经常感觉身体“沉重”或水肿",
                detail: "AI 检测到步数与卡路里消耗不匹配"
            )
        ]

        selectedIssueID = issueOptions.first?.id ?? "fatigue"
    }

    var primaryButtonTitle: String {
        switch step {
        case .intro:
            return "连接我的身体数据"
        case .scan:
            return isScanCompleted ? "查看 AI 生成的信息" : "初步诊断生成中..."
        case .profile:
            return "确认并生成战术"
        }
    }

    var isPrimaryButtonDisabled: Bool {
        step == .scan && !isScanCompleted
    }

    var selectedIssue: OnboardingIssueOption? {
        issueOptions.first { $0.id == selectedIssueID }
    }

    func handlePrimaryAction() {
        switch step {
        case .intro:
            withAnimation(.easeInOut(duration: 0.4)) {
                step = .scan
            }
            startScanIfNeeded()

        case .scan:
            guard isScanCompleted else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                step = .profile
            }

        case .profile:
            finishOnboarding()
        }
    }

    func selectIssue(_ id: String) {
        selectedIssueID = id
    }

    func startScanIfNeeded() {
        guard scanTask == nil else { return }
        visibleScanLines = []
        isScanCompleted = false

        scanTask = Task { [weak self] in
            guard let self else { return }

            for line in scanLines {
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        visibleScanLines.append(line)
                    }
                }
            }

            try? await Task.sleep(nanoseconds: 800_000_000)

            await MainActor.run {
                withAnimation {
                    isScanCompleted = true
                }
            }
        }
    }

    private func finishOnboarding() {
        stateManager.saveOnboardingID(OnboardingStateManager.mockOnboardingID)
        stateManager.markOnboardingAsCompleted()
        Log.i("✅ Onboarding 完成，使用 mock ID: \(OnboardingStateManager.mockOnboardingID)", category: "Onboarding")
        onComplete()
    }

    deinit {
        scanTask?.cancel()
    }
}

// MARK: - Components

private struct ScanTicker: View {
    let lines: [ScanLine]

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

private struct ProfileCard: View {
    let snapshot: OnboardingProfileSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("基础信息", systemImage: "sparkles")
                    .foregroundColor(.green.opacity(0.9))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }

            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow(alignment: .top) {
                    infoTile(title: "性别", value: snapshot.gender)
                    infoTile(title: "年龄", value: "\(snapshot.age)")
                }
                GridRow(alignment: .top) {
                    infoTile(title: "身高", value: "\(snapshot.height) cm")
                    infoTile(title: "体重", value: "\(snapshot.weight) kg")
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.6))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct IssueRow: View {
    let option: OnboardingIssueOption
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.green.opacity(0.95))
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(option.title)
                        .font(.callout.weight(.semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Text(option.detail)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.12) : Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.green.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private final class PreviewOnboardingStateManager: OnboardingStateManaging {
    var hasCompletedOnboarding = false
    private var onboardingID: String?

    func markOnboardingAsCompleted() {
        hasCompletedOnboarding = true
    }

    func resetOnboardingState() {
        hasCompletedOnboarding = false
        onboardingID = nil
    }

    func shouldShowOnboarding(isAuthenticated: Bool) -> Bool {
        !isAuthenticated && !hasCompletedOnboarding
    }

    func saveOnboardingID(_ id: String) {
        onboardingID = id
    }

    func getOnboardingID() -> String? {
        onboardingID
    }

    func clearOnboardingID() {
        onboardingID = nil
    }
}

#Preview {
    OnboardingView(
        onComplete: {},
        stateManager: PreviewOnboardingStateManager()
    )
        .environment(\.colorScheme, .dark)
}
