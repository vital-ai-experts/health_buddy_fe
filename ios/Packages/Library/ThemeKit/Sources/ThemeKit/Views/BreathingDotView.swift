import SwiftUI

public struct BreathingDotConfiguration {
    public var outerSize: CGFloat?
    public var middleSize: CGFloat?
    public var innerSize: CGFloat
    public var outerScaleRange: ClosedRange<CGFloat>
    public var middleScaleRange: ClosedRange<CGFloat>
    public var overallScaleRange: ClosedRange<CGFloat>
    public var outerBlur: CGFloat
    public var middleBlur: CGFloat
    public var innerShadowRadius: CGFloat
    public var innerShadowOpacity: Double
    public var useSecondaryForMiddle: Bool
    public var useSecondaryForOverall: Bool
    public var primaryAnimation: Animation
    public var secondaryAnimation: Animation?
    public var secondaryDelay: Double

    public init(
        outerSize: CGFloat? = nil,
        middleSize: CGFloat? = nil,
        innerSize: CGFloat = 36,
        outerScaleRange: ClosedRange<CGFloat> = 1.2...2.2,
        middleScaleRange: ClosedRange<CGFloat> = 1.0...1.6,
        overallScaleRange: ClosedRange<CGFloat> = 0.92...1.04,
        outerBlur: CGFloat = 28,
        middleBlur: CGFloat = 12,
        innerShadowRadius: CGFloat = 18,
        innerShadowOpacity: Double = 0.6,
        useSecondaryForMiddle: Bool = false,
        useSecondaryForOverall: Bool = false,
        primaryAnimation: Animation = .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
        secondaryAnimation: Animation? = nil,
        secondaryDelay: Double = 0
    ) {
        self.outerSize = outerSize
        self.middleSize = middleSize
        self.innerSize = innerSize
        self.outerScaleRange = outerScaleRange
        self.middleScaleRange = middleScaleRange
        self.overallScaleRange = overallScaleRange
        self.outerBlur = outerBlur
        self.middleBlur = middleBlur
        self.innerShadowRadius = innerShadowRadius
        self.innerShadowOpacity = innerShadowOpacity
        self.useSecondaryForMiddle = useSecondaryForMiddle
        self.useSecondaryForOverall = useSecondaryForOverall
        self.primaryAnimation = primaryAnimation
        self.secondaryAnimation = secondaryAnimation
        self.secondaryDelay = secondaryDelay
    }
}

public extension BreathingDotConfiguration {
    @MainActor static let onboarding = BreathingDotConfiguration()

    @MainActor static let splash = BreathingDotConfiguration(
        outerSize: 200,
        middleSize: 90,
        innerSize: 34,
        outerScaleRange: 0.85...1.25,
        middleScaleRange: 0.94...1.08,
        overallScaleRange: 0.98...1.02,
        outerBlur: 32,
        middleBlur: 12,
        innerShadowRadius: 26,
        innerShadowOpacity: 0.7,
        useSecondaryForMiddle: true,
        useSecondaryForOverall: true,
        primaryAnimation: .easeInOut(duration: 2.2).repeatForever(autoreverses: true),
        secondaryAnimation: .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
        secondaryDelay: 0.4
    )
}

public struct BreathingDotView: View {
    private let configuration: BreathingDotConfiguration
    @State private var primary = false
    @State private var secondary = false

    public init(configuration: BreathingDotConfiguration = .onboarding) {
        self.configuration = configuration
    }

    public var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.18))
                .frame(square: configuration.outerSize)
                .scaleEffect(scale(for: configuration.outerScaleRange, isActive: primary))
                .blur(radius: configuration.outerBlur)

            Circle()
                .fill(Color.green.opacity(0.45))
                .frame(square: configuration.middleSize)
                .scaleEffect(scale(for: configuration.middleScaleRange, isActive: secondaryDriver))
                .blur(radius: configuration.middleBlur)

            Circle()
                .fill(Color.green)
                .frame(width: configuration.innerSize, height: configuration.innerSize)
                .shadow(color: Color.green.opacity(configuration.innerShadowOpacity), radius: configuration.innerShadowRadius)
        }
        .scaleEffect(scale(for: configuration.overallScaleRange, isActive: overallDriver))
        .onAppear(perform: startAnimations)
    }

    private var secondaryDriver: Bool {
        configuration.useSecondaryForMiddle ? secondary : primary
    }

    private var overallDriver: Bool {
        configuration.useSecondaryForOverall ? secondary : primary
    }

    private func scale(for range: ClosedRange<CGFloat>, isActive: Bool) -> CGFloat {
        isActive ? range.upperBound : range.lowerBound
    }

    private func startAnimations() {
        withAnimation(configuration.primaryAnimation) {
            primary = true
        }

        guard configuration.useSecondaryForMiddle || configuration.useSecondaryForOverall else {
            return
        }

        let secondaryAnimation = (configuration.secondaryAnimation ?? configuration.primaryAnimation)
            .delay(configuration.secondaryDelay)

        withAnimation(secondaryAnimation) {
            secondary = true
        }
    }
}

private extension View {
    @ViewBuilder
    func frame(square: CGFloat?) -> some View {
        if let square {
            frame(width: square, height: square)
        } else {
            self
        }
    }
}
