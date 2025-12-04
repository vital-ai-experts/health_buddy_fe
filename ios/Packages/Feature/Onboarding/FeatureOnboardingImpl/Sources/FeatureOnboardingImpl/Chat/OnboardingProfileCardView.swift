import SwiftUI
import ThemeKit

struct OnboardingProfileInfoCardView: View {
    let payload: ProfileCardPayload?
    let onConfirm: (ProfileDraft) -> Void

    @State private var editingField: ProfileFieldUpdate?
    @State private var gender: String = "-"
    @State private var age: Int = 0
    @State private var height: Int = 0
    @State private var weight: Int = 0
    @State private var tempGender: String = ""
    @State private var tempNumber: Int = 0

    init(payload: ProfileCardPayload?, onConfirm: @escaping (ProfileDraft) -> Void) {
        self.payload = payload
        self.onConfirm = onConfirm
        _gender = State(initialValue: payload?.gender ?? "-")
        _age = State(initialValue: payload?.age ?? 0)
        _height = State(initialValue: payload?.height ?? 0)
        _weight = State(initialValue: payload?.weight ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoGrid

            Button {
                onConfirm(ProfileDraft(gender: gender, age: age, height: height, weight: weight))
            } label: {
                HStack {
                    Spacer()
                    Text("确认基本信息")
                        .font(.callout.weight(.semibold))
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.Palette.successMain)
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
        .sheet(item: $editingField) { field in
            editor(for: field)
        }
    }

    @ViewBuilder
    private var infoGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("基础信息", systemImage: "person.crop.rectangle")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.Palette.successMain)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    infoTile(title: "性别", value: gender, unit: "") {
                        tempGender = gender
                        editingField = .gender(gender)
                    }
                    infoTile(title: "年龄", value: "\(age)", unit: "岁") {
                        tempNumber = age
                        editingField = .age(age)
                    }
                }
                GridRow {
                    infoTile(title: "身高", value: "\(height)", unit: "cm") {
                        tempNumber = height
                        editingField = .height(height)
                    }
                    infoTile(title: "体重", value: "\(weight)", unit: "kg") {
                        tempNumber = weight
                        editingField = .weight(weight)
                    }
                }
            }
        }
    }

    private func infoTile(title: String, value: String, unit: String, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.Palette.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.Palette.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.footnote)
                        .foregroundColor(.Palette.textSecondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Palette.bgMuted)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private func editor(for field: ProfileFieldUpdate) -> some View {
        switch field {
        case .gender:
            GenderPickerSheet(
                selected: tempGender,
                onConfirm: { value in
                    gender = value
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
        case .age:
            NumberPickerSheet(
                title: "年龄",
                range: 10...90,
                unit: "岁",
                value: $tempNumber,
                onConfirm: { value in
                    age = value
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
        case .height:
            NumberPickerSheet(
                title: "身高",
                range: 120...220,
                unit: "cm",
                value: $tempNumber,
                onConfirm: { value in
                    height = value
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
        case .weight:
            NumberPickerSheet(
                title: "体重",
                range: 30...150,
                unit: "kg",
                value: $tempNumber,
                onConfirm: { value in
                    weight = value
                    editingField = nil
                },
                onCancel: { editingField = nil }
            )
        }
    }
}

#Preview {
    OnboardingProfileInfoCardView(
        payload: ProfileCardPayload(
            gender: "男",
            age: 30,
            height: 178,
            weight: 72,
            issues: [],
            selectedIssueId: ""
        ),
        onConfirm: { _ in }
    )
    .padding()
    .background(Color.Palette.bgBase)
    .preferredColorScheme(.dark)
}
