import SwiftUI

public extension Color {
    enum Palette {
        public static let bgBase = Color("BgBase", bundle: .module)
        public static let bgMuted = Color("BgMuted", bundle: .module)

        public static let borderSubtle = Color("BorderSubtle", bundle: .module)
        public static let borderStrong = Color("BorderStrong", bundle: .module)

        public static let textPrimary = Color("TextPrimary", bundle: .module)
        public static let textSecondary = Color("TextSecondary", bundle: .module)
        public static let textDisabled = Color("TextDisabled", bundle: .module)
        public static let textOnAccent = Color("TextOnAccent", bundle: .module)

        public static let warningMain = Color("WarningMain", bundle: .module)
        public static let warningBgSoft = Color("WarningBgSoft", bundle: .module)
        public static let warningBorder = Color("WarningBorder", bundle: .module)
        public static let warningText = Color("WarningText", bundle: .module)
        public static let warningHover = Color("WarningHover", bundle: .module)
        public static let warningActive = Color("WarningActive", bundle: .module)

        public static let successMain = Color("SuccessMain", bundle: .module)
        public static let successBgSoft = Color("SuccessBgSoft", bundle: .module)
        public static let successBorder = Color("SuccessBorder", bundle: .module)
        public static let successText = Color("SuccessText", bundle: .module)
        public static let successHover = Color("SuccessHover", bundle: .module)
        public static let successActive = Color("SuccessActive", bundle: .module)

        public static let dangerMain = Color("DangerMain", bundle: .module)
        public static let dangerBgSoft = Color("DangerBgSoft", bundle: .module)

        public static let infoMain = Color("InfoMain", bundle: .module)
        public static let infoBgSoft = Color("InfoBgSoft", bundle: .module)

        public static let surfaceElevated = Color("SurfaceElevated", bundle: .module)
        public static let surfaceElevatedBorder = Color("SurfaceElevatedBorder", bundle: .module)

        /// 统一的色板列表，供调试/预览使用，避免多处手动同步
        public static let allSwatches: [(name: String, color: Color)] = [
            ("bgBase", bgBase),
            ("bgMuted", bgMuted),
            ("borderSubtle", borderSubtle),
            ("borderStrong", borderStrong),
            ("textPrimary", textPrimary),
            ("textSecondary", textSecondary),
            ("textDisabled", textDisabled),
            ("textOnAccent", textOnAccent),
            ("warningMain", warningMain),
            ("warningBgSoft", warningBgSoft),
            ("warningBorder", warningBorder),
            ("warningText", warningText),
            ("warningHover", warningHover),
            ("warningActive", warningActive),
            ("successMain", successMain),
            ("successBgSoft", successBgSoft),
            ("successBorder", successBorder),
            ("successText", successText),
            ("successHover", successHover),
            ("successActive", successActive),
            ("dangerMain", dangerMain),
            ("dangerBgSoft", dangerBgSoft),
            ("infoMain", infoMain),
            ("infoBgSoft", infoBgSoft),
            ("surfaceElevated", surfaceElevated),
            ("surfaceElevatedBorder", surfaceElevatedBorder)
        ]
    }
}
