import SwiftUI
import ThemeKit

struct OnboardingCallCardView: View {
    let payload: CallCardPayload?
    let onBook: (String) -> Void

    @State private var phoneNumber: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payload?.headline ?? "预约回电")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                Text(payload?.note ?? "填写手机号，健康顾问会主动来电确认你的定制方案。")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("手机号")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                TextField("请输入手机号", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textInputAutocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.white)
            }

            Button {
                onBook(phoneNumber)
            } label: {
                HStack {
                    Spacer()
                    Text("预约健康顾问来电")
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.Palette.successMain)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
