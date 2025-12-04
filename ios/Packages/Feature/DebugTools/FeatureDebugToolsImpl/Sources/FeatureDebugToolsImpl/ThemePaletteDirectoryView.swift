import SwiftUI
import ThemeKit

struct ThemePaletteDirectoryView: View {
    var body: some View {
        List {
            Section("色板预览（左右为浅/深模式）") {
                ForEach(Color.Palette.allSwatches, id: \.name) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                        Spacer()
                        HStack(spacing: 8) {
                            ColorSwatch(color: item.color, scheme: .light)
                            ColorSwatch(color: item.color, scheme: .dark)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("ThemeKit 目录")
    }
}

private struct ColorSwatch: View {
    let color: Color
    let scheme: ColorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .frame(width: 60, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.Palette.borderSubtle, lineWidth: 1)
            )
            .environment(\.colorScheme, scheme)
    }
}

#Preview {
    NavigationStack {
        ThemePaletteDirectoryView()
    }
    .preferredColorScheme(.dark)
}
