//
//  CustomChartStyle.swift
//  DashboardFeature
//
//  Created by Claude Code
//

#if canImport(CareKitUI)
import UIKit
import CareKitUI

/// 自定义颜色样式，遵循 OCKColorStyler 协议
struct CustomColorStyle: OCKColorStyler {
    var label: UIColor { .label }
    var secondaryLabel: UIColor { .secondaryLabel }
    var tertiaryLabel: UIColor { .tertiaryLabel }
    var quaternaryLabel: UIColor { .quaternaryLabel }
    var customBackground: UIColor { .systemBackground }
    var secondaryCustomBackground: UIColor { .secondarySystemBackground }
    var tertiaryCustomBackground: UIColor { .tertiarySystemBackground }
    var customGroupedBackground: UIColor { .systemGroupedBackground }
    var secondaryCustomGroupedBackground: UIColor { .secondarySystemGroupedBackground }
    var tertiaryCustomGroupedBackground: UIColor { .tertiarySystemGroupedBackground }
    var separator: UIColor { .separator.withAlphaComponent(0.3) }
    var opaqueSeparator: UIColor { .opaqueSeparator }
    var customFill: UIColor { .systemFill }
    var secondaryCustomFill: UIColor { .secondarySystemFill }
    var tertiaryCustomFill: UIColor { .tertiarySystemFill }
    var quaternaryCustomFill: UIColor { .quaternarySystemFill }
}

/// 自定义尺寸样式，遵循 OCKDimensionStyler 协议
struct CustomDimensionStyle: OCKDimensionStyler {
    var separatorHeight: CGFloat { 1.0 }
    var lineWidth1: CGFloat { 2.0 }
    var lineWidth2: CGFloat { 4.0 }
    var stackSpacing1: CGFloat { 8.0 }
    var stackSpacing2: CGFloat { 16.0 }
    var pointSize1: CGFloat { 10.0 }
    var pointSize2: CGFloat { 14.0 }
    var pointSize3: CGFloat { 18.0 }
    var directionalInsets1: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    }
    var directionalInsets2: NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}

/// 自定义动画样式，遵循 OCKAnimationStyler 协议
struct CustomAnimationStyle: OCKAnimationStyler {
    var stateChangeDuration: Double { 0.3 }
}

/// 自定义外观样式，遵循 OCKAppearanceStyler 协议
struct CustomAppearanceStyle: OCKAppearanceStyler {
    var cornerRadius1: CGFloat { 8.0 }
    var cornerRadius2: CGFloat { 12.0 }
    var borderWidth1: CGFloat { 1.0 }
    var borderWidth2: CGFloat { 2.0 }
    var shadowOpacity1: Float { 0.1 }
    var shadowRadius1: CGFloat { 4.0 }
    var shadowOffset1: CGSize { CGSize(width: 0, height: 2) }
}

/// 主自定义样式，整合所有样式组件
struct CustomChartStyle: OCKStyler {
    var color: OCKColorStyler { CustomColorStyle() }
    var dimension: OCKDimensionStyler { CustomDimensionStyle() }
    var animation: OCKAnimationStyler { CustomAnimationStyle() }
    var appearance: OCKAppearanceStyler { CustomAppearanceStyle() }
}

#endif
