import SwiftUI
import ThemeKit

struct OnboardingCallCardView: View {
    let payload: CallCardPayload?
    let onBook: (String) -> Void

    @State private var phoneNumber: String = ""
    @State private var isCalling: Bool = false
    @State private var hasFinishedCall: Bool = false

    init(
        payload: CallCardPayload?,
        onBook: @escaping (String) -> Void
    ) {
        self.payload = payload
        self.onBook = onBook
        _hasFinishedCall = State(initialValue: payload?.hasFinished ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payload?.headline ?? "预约回电")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.Palette.textPrimary)
                Text(payload?.note ?? "填写手机号，健康顾问会主动来电确认你的定制方案。")
                    .font(.footnote)
                    .foregroundColor(.Palette.textSecondary)
            }

            if requiresPhoneNumber {
                HStack(alignment: .center, spacing: 8) {
                    Text("手机号")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.Palette.textSecondary)
                    TextField("请输入手机号", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(Color.Palette.bgMuted)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundColor(.Palette.textPrimary)
                }
            }

            Button {
                startCall()
            } label: {
                HStack {
                    Spacer()
                    if hasFinishedCall {
                        Text("已完成通话")
                            .font(.callout.weight(.semibold))
                    } else if isCalling {
                        ProgressView()
                            .padding(.trailing, 6)
                        Text(payload?.loadingTitle ?? "拨号中…")
                            .font(.callout.weight(.semibold))
                    } else {
                        Text(payload?.ctaTitle ?? "预约健康顾问来电")
                            .font(.callout.weight(.semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(hasFinishedCall || isCalling ? Color.Palette.surfaceElevatedBorder : Color.Palette.successMain)
                .foregroundColor(hasFinishedCall || isCalling ? Color.Palette.textSecondary : Color.Palette.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isCalling || hasFinishedCall)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Palette.surfaceElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.Palette.surfaceElevatedBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            phoneNumber = payload?.phoneNumber ?? ""
        }
        .onChange(of: payload?.phoneNumber ?? "") { _, newValue in
            phoneNumber = newValue
        }
    }
}

#Preview {
    OnboardingCallCardView(
        payload: CallCardPayload(
            phoneNumber: "13800000000",
            headline: "给我 10 分钟，聊聊你的压力和想法，才能精准给方案。",
            note: "接听后我会快速确认你的生活节律，再把方案拆成锁屏小任务推送给你。",
            ctaTitle: "📞 接听 Pascal 的来电",
            requiresPhoneNumber: true,
            loadingTitle: "通话中...",
            hasFinished: false
        ),
        onBook: { _ in }
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
}

private extension OnboardingCallCardView {
    var requiresPhoneNumber: Bool {
        payload?.requiresPhoneNumber ?? true
    }

    func startCall() {
        guard !isCalling else { return }
        isCalling = true
        let phone = requiresPhoneNumber ? phoneNumber : (payload?.phoneNumber ?? phoneNumber)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            onBook(phone)
            isCalling = false
            hasFinishedCall = true
        }
    }
}
