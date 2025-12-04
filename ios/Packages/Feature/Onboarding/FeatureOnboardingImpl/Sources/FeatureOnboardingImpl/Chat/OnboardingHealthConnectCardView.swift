import SwiftUI
import ThemeKit
import DomainHealth
import LibraryServiceLoader

struct OnboardingHealthConnectCardView: View {
    enum ConnectState {
        case idle
        case requesting
        case analyzing
        case finished
    }

    let payload: HealthConnectCardPayload?
    let onAuthorized: () -> Void

    @State private var state: ConnectState = .idle
    @State private var errorMessage: String?
    private let authorizationService: AuthorizationService?

    init(
        payload: HealthConnectCardPayload?,
        onAuthorized: @escaping () -> Void,
        authorizationService: AuthorizationService? = ServiceManager.shared.resolveOptional(AuthorizationService.self)
    ) {
        self.payload = payload
        self.onAuthorized = onAuthorized
        self.authorizationService = authorizationService
        if payload?.isFinished == true {
            _state = State(initialValue: .finished)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payload?.title ?? "连接 Apple Health")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.Palette.textPrimary)
                Text(payload?.description ?? "需要访问你的运动、睡眠和心率等基础数据，用于定制方案。")
                    .font(.footnote)
                    .foregroundColor(.Palette.textSecondary)
            }

            Button {
                connect()
            } label: {
                HStack {
                    Spacer()
                    if state == .finished {
                        Text("已完成分析")
                            .font(.callout.weight(.semibold))
                    } else if state == .analyzing {
                        ProgressView()
                            .padding(.trailing, 6)
                        Text(payload?.loadingTitle ?? "正在分析...")
                            .font(.callout.weight(.semibold))
                    } else {
                        Text(payload?.connectButtonTitle ?? "🔗 连接 Apple Health")
                            .font(.callout.weight(.semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(state == .analyzing || state == .finished ? Color.Palette.surfaceElevatedBorder : Color.Palette.successMain)
                .foregroundColor(state == .analyzing || state == .finished ? Color.Palette.textSecondary : Color.Palette.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(state != .idle)

            if state == .analyzing || state == .finished {
                Text(payload?.analyzingHint ?? "Pascal 正在分析数据...")
                    .font(.footnote)
                    .foregroundColor(.Palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.Palette.dangerMain)
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

private extension OnboardingHealthConnectCardView {
    func connect() {
        guard state == .idle else { return }
        errorMessage = nil

        Task { @MainActor in
            state = .requesting

            if let authorizationService {
                do {
                    let result = try await authorizationService.requestAuthorization()
                    guard result == .authorized else {
                        errorMessage = "需要健康数据权限，稍后可在系统设置开启。"
                        state = .idle
                        return
                    }
                } catch {
                    errorMessage = "授权失败，请稍后再试。"
                    state = .idle
                    return
                }
            }

            state = .analyzing
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            onAuthorized()
            state = .finished
        }
    }
}

#Preview {
    OnboardingHealthConnectCardView(
        payload: HealthConnectCardPayload(
            title: "连接 Apple Health",
            description: "允许获取运动、睡眠与心率数据，便于实时调整方案。",
            connectButtonTitle: "🔗 连接 Apple Health",
            loadingTitle: "正在分析...",
            analyzingHint: "Pascal 正在分析数据...",
            isFinished: false
        ),
        onAuthorized: {}
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
}
