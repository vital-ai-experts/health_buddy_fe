import SwiftUI
import UIKit

struct CallSectionView: View {
    @Binding var name: String
    @Binding var phoneNumber: String
    let callState: OnboardingCallState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("预约回电")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("填写联系方式，健康顾问会主动来电确认你的定制方案。")
                    .foregroundColor(.white.opacity(0.75))
                    .font(.callout)
            }

            CallTextField(
                title: "姓名",
                placeholder: "请输入姓名",
                text: $name,
                keyboardType: .default
            )

            CallTextField(
                title: "手机号",
                placeholder: "请输入手机号",
                text: $phoneNumber,
                keyboardType: .phonePad
            )

            if callState != .idle {
                HStack(spacing: 10) {
                    if callState.isProcessing {
                        ProgressView()
                            .tint(.green)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green.opacity(0.9))
                    }

                    Text(callState.buttonTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Text("你的隐私将被严格保护，仅用于本次健康顾问回访。")
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.top, 4)
        }
    }
}

private struct CallTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.none)
                .disableAutocorrection(true)
                .padding()
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .foregroundColor(.white)
        }
    }
}
