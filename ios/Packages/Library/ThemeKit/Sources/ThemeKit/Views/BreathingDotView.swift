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
    @State private var tertiary = false

    private let particleSeeds: [ParticleSeed] = [
        .init(angle: .pi * 0.12, radius: 62, size: 6, speed: 5.2, phase: 0, opacity: 0.55),
        .init(angle: .pi * 0.38, radius: 74, size: 5, speed: 4.6, phase: 1.8, opacity: 0.38),
        .init(angle: .pi * 0.63, radius: 88, size: 7, speed: 6.8, phase: 0.4, opacity: 0.42),
        .init(angle: .pi * 1.1, radius: 96, size: 5.5, speed: 5.9, phase: 1.2, opacity: 0.52),
        .init(angle: .pi * 1.46, radius: 72, size: 4.5, speed: 4.2, phase: 2.6, opacity: 0.36),
        .init(angle: .pi * 1.86, radius: 84, size: 6.5, speed: 7.4, phase: 0.9, opacity: 0.41)
    ]

    public init(configuration: BreathingDotConfiguration = .onboarding) {
        self.configuration = configuration
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                layeredGlow

                floatingParticles(date: timeline.date)

                pulsatingLayers

                coreDot
            }
            .scaleEffect(scale(for: configuration.overallScaleRange, isActive: overallDriver))
            .onAppear(perform: startAnimations)
        }
    }

    private var secondaryDriver: Bool {
        configuration.useSecondaryForMiddle ? secondary : primary
    }

    private var overallDriver: Bool {
        configuration.useSecondaryForOverall ? secondary : primary
    }

    private var layeredGlow: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.green.opacity(0.18), Color.green.opacity(0.02)],
                        center: .center,
                        startRadius: 2,
                        endRadius: resolvedOuterSize
                    )
                )
                .frame(width: resolvedOuterSize * 1.45, height: resolvedOuterSize * 1.45)
                .blur(radius: configuration.outerBlur)

            Circle()
                .fill(Color.green.opacity(0.22))
                .frame(square: resolvedOuterSize)
                .scaleEffect(scale(for: configuration.outerScaleRange, isActive: primary))
                .blur(radius: configuration.outerBlur)

            Circle()
                .fill(Color.green.opacity(0.35))
                .frame(square: resolvedMiddleSize)
                .scaleEffect(scale(for: configuration.middleScaleRange, isActive: secondaryDriver))
                .blur(radius: configuration.middleBlur)
        }
    }

    private var pulsatingLayers: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.16))
                .frame(width: resolvedAccentSize, height: resolvedAccentSize)
                .scaleEffect(scale(for: accentScaleRange, isActive: tertiary))
                .blur(radius: 18)

            Circle()
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 1.2)
                .frame(width: resolvedAccentSize * 0.82, height: resolvedAccentSize * 0.82)
                .scaleEffect(scale(for: accentScaleRange, isActive: tertiary))
                .blur(radius: 8)

            Circle()
                .strokeBorder(Color.green.opacity(0.5), lineWidth: 1.8)
                .frame(width: configuration.innerSize * 1.4, height: configuration.innerSize * 1.4)
                .scaleEffect(scale(for: 0.94...1.08, isActive: secondaryDriver))
                .blur(radius: 6)
        }
    }

    private var coreDot: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.green, Color.green.opacity(0.8)],
                    center: .center,
                    startRadius: 2,
                    endRadius: configuration.innerSize
                )
            )
            .frame(width: configuration.innerSize, height: configuration.innerSize)
            .shadow(color: Color.green.opacity(configuration.innerShadowOpacity), radius: configuration.innerShadowRadius)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                    .blur(radius: 2)
                    .scaleEffect(scale(for: 0.9...1.1, isActive: primary))
            )
    }

    private func floatingParticles(date: Date) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let time = date.timeIntervalSinceReferenceDate

            for seed in particleSeeds {
                let oscillation = sin(time / seed.speed + seed.phase)
                let radius = seed.radius + CGFloat(oscillation) * 12
                let x = center.x + cos(seed.angle) * radius
                let y = center.y + sin(seed.angle) * radius

                var path = Path(
                    ellipseIn: CGRect(
                        x: x - seed.size / 2,
                        y: y - seed.size / 2,
                        width: seed.size,
                        height: seed.size
                    )
                )

                context.fill(path, with: .color(seed.color))
            }
        }
        .frame(width: resolvedOuterSize * 1.5, height: resolvedOuterSize * 1.5)
        .blur(radius: 6)
        .allowsHitTesting(false)
    }

    private var resolvedOuterSize: CGFloat {
        configuration.outerSize ?? configuration.innerSize * 5.2
    }

    private var resolvedMiddleSize: CGFloat {
        configuration.middleSize ?? configuration.innerSize * 2.6
    }

    private var resolvedAccentSize: CGFloat {
        resolvedMiddleSize * 1.42
    }

    private var accentScaleRange: ClosedRange<CGFloat> {
        0.86...1.24
    }

    private func scale(for range: ClosedRange<CGFloat>, isActive: Bool) -> CGFloat {
        isActive ? range.upperBound : range.lowerBound
    }

    private func startAnimations() {
        withAnimation(configuration.primaryAnimation) {
            primary = true
        }

        withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true).delay(0.6)) {
            tertiary = true
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

private struct ParticleSeed {
    let angle: Double
    let radius: CGFloat
    let size: CGFloat
    let speed: Double
    let phase: Double
    let opacity: Double

    var color: Color {
        Color.green.opacity(opacity)
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
