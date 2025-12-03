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
                    .foregroundColor(.Palette.textPrimary)
                Text(payload?.note ?? "填写手机号，健康顾问会主动来电确认你的定制方案。")
                    .font(.footnote)
                    .foregroundColor(.Palette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
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
                .background(Color.Palette.infoMain)
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
        .onAppear {
            phoneNumber = payload?.phoneNumber ?? ""
        }
        .onChange(of: payload?.phoneNumber ?? "") { _, newValue in
            phoneNumber = newValue
        }
    }
}
