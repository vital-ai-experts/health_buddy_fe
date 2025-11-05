//
//  AuthorizationFeatureView.swift
//  AuthorizationFeature
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import DomainHealth
import LibraryServiceLoader

public struct AuthorizationFeatureView: View {
    private let onAuthorized: () -> Void
    private let authorizationService: AuthorizationService

    @State private var status: AuthorizationState = .notDetermined
    @State private var isRequesting = false
    @State private var errorMessage: String?
    @State private var hasNotifiedAuthorized = false

    public init(
        onAuthorized: @escaping () -> Void,
        authorizationService: AuthorizationService = ServiceManager.shared.resolve(AuthorizationService.self)
    ) {
        self.onAuthorized = onAuthorized
        self.authorizationService = authorizationService
    }

    public var body: some View {
        VStack(spacing: 24) {
            header
            statusDescription
            requestButton
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            Task { await refreshStatus() }
        }
        .animation(.easeInOut, value: status)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.pink.gradient)
            Text("需要访问 Health 数据")
                .font(.title3)
                .bold()
        }
    }

    private var statusDescription: some View {
        VStack(spacing: 8) {
            Text(description(for: status))
                .font(.body)
                .multilineTextAlignment(.center)
            if status == .denied {
                Text("请在设置中开启 HealthKit 权限后重试。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var requestButton: some View {
        Button(action: requestAuthorization) {
            if isRequesting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(maxWidth: .infinity)
            } else {
                Text(buttonTitle(for: status))
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canRequest(for: status) || isRequesting)
    }

    private func refreshStatus() async {
        let newStatus = await authorizationService.currentStatus()
        await MainActor.run {
            status = newStatus
            handleAuthorizedIfNeeded(newStatus)
        }
    }

    private func requestAuthorization() {
        guard !isRequesting else { return }
        isRequesting = true
        errorMessage = nil

        Task {
            do {
                let newStatus = try await authorizationService.requestAuthorization()
                await MainActor.run {
                    status = newStatus
                    isRequesting = false
                    handleAuthorizedIfNeeded(newStatus)
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleAuthorizedIfNeeded(_ newStatus: AuthorizationState) {
        guard newStatus == .authorized, !hasNotifiedAuthorized else { return }
        hasNotifiedAuthorized = true
        onAuthorized()
    }

    private func description(for status: AuthorizationState) -> String {
        switch status {
        case .unavailable:
            return "此设备暂不支持 HealthKit，部分功能不可用。"
        case .notDetermined:
            return "我们需要从 HealthKit 读取最近的健康数据，以展示步数、心率等信息。"
        case .denied:
            return "当前没有读取权限，无法展示数据。请授予 HealthKit 权限。"
        case .authorized:
            return "已成功获取权限，可以访问健康数据。"
        }
    }

    private func buttonTitle(for status: AuthorizationState) -> String {
        switch status {
        case .unavailable:
            return "设备不支持"
        case .notDetermined:
            return "立即授权"
        case .denied:
            return "重新授权"
        case .authorized:
            return "已授权"
        }
    }

    private func canRequest(for status: AuthorizationState) -> Bool {
        switch status {
        case .unavailable, .authorized:
            return false
        case .notDetermined, .denied:
            return true
        }
    }
}

#Preview {
    AuthorizationFeatureView(
        onAuthorized: {},
        authorizationService: PreviewAuthorizationService()
    )
}

private final class PreviewAuthorizationService: AuthorizationService {
    private var status: AuthorizationState = .notDetermined

    func currentStatus() async -> AuthorizationState { status }

    func requestAuthorization() async throws -> AuthorizationState {
        status = .authorized
        return status
    }
}
