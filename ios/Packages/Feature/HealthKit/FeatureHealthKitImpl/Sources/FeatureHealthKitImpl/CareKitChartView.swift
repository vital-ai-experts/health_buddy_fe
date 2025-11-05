//
//  CareKitChartView.swift
//  DashboardFeature
//
//  Created by Codex on 2025/3/2.
//

import SwiftUI
import DomainHealth

#if canImport(CareKitUI)
import CareKitUI

struct CareKitChartView: UIViewRepresentable {
    let section: HealthDisplaySection

    func makeCoordinator() -> Coordinator {
        Coordinator(section: section)
    }

    func makeUIView(context: Context) -> OCKCartesianChartView {
        let chart = OCKCartesianChartView(type: context.coordinator.plotType)

        // 应用自定义样式
        chart.customStyle = CustomChartStyle()

        // 配置标题区域
        chart.headerView.titleLabel.text = section.title
        chart.headerView.titleLabel.font = .preferredFont(forTextStyle: .headline)
        chart.headerView.detailLabel.text = context.coordinator.subtitle
        chart.headerView.detailLabel.font = .preferredFont(forTextStyle: .subheadline)
        chart.headerView.iconImageView?.isHidden = true

        // 配置图表区域
        chart.graphView.numberFormatter = context.coordinator.numberFormatter
        chart.graphView.horizontalAxisMarkers = context.coordinator.axisMarkers
        chart.graphView.dataSeries = context.coordinator.dataSeries
        chart.graphView.selectedIndex = context.coordinator.defaultSelectedIndex

        // 注意：CareKit 的某些版本可能不支持以下属性
        // 如果您的 CareKit 版本支持，可以取消注释以下代码
        // chart.graphView.horizontalGridlines = true
        // if let range = context.coordinator.valueRange {
        //     chart.graphView.minimumValue = range.lowerBound
        //     chart.graphView.maximumValue = range.upperBound
        // }

        chart.isUserInteractionEnabled = true
        chart.accessibilityIdentifier = context.coordinator.accessibilityIdentifier

        // 保存图表引用以便交互
        context.coordinator.chartView = chart

        // 添加手势识别器以增强交互
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        chart.graphView.addGestureRecognizer(tapGesture)
        chart.graphView.isUserInteractionEnabled = true

        // 配置辅助功能
        configureAccessibility(for: chart, context: context)

        return chart
    }

    private func configureAccessibility(for chart: OCKCartesianChartView, context: Context) {
        // 确保图表本身不是单一的辅助功能元素，而是容器
        chart.isAccessibilityElement = false
        chart.accessibilityElements = [chart.headerView, chart.graphView]

        // 为标题配置辅助功能
        chart.headerView.titleLabel.isAccessibilityElement = true
        chart.headerView.titleLabel.accessibilityLabel = section.title
        chart.headerView.titleLabel.accessibilityTraits = .header

        // 为副标题配置辅助功能
        if let subtitle = context.coordinator.subtitle {
            chart.headerView.detailLabel.isAccessibilityElement = true
            chart.headerView.detailLabel.accessibilityLabel = subtitle
            chart.headerView.detailLabel.accessibilityTraits = .staticText
        }

        // 为图表配置辅助功能描述
        chart.graphView.isAccessibilityElement = true
        chart.graphView.accessibilityLabel = context.coordinator.accessibilityDescription
        chart.graphView.accessibilityHint = "双击查看详细数据点"
        chart.graphView.accessibilityTraits = .updatesFrequently
    }

    func updateUIView(_ uiView: OCKCartesianChartView, context: Context) {
        context.coordinator.update(with: section)
        uiView.headerView.titleLabel.text = section.title
        uiView.headerView.detailLabel.text = context.coordinator.subtitle
        uiView.graphView.numberFormatter = context.coordinator.numberFormatter
        uiView.graphView.horizontalAxisMarkers = context.coordinator.axisMarkers
        uiView.graphView.dataSeries = context.coordinator.dataSeries
        uiView.graphView.selectedIndex = context.coordinator.defaultSelectedIndex
        uiView.accessibilityIdentifier = context.coordinator.accessibilityIdentifier
    }

    final class Coordinator {
        private(set) var section: HealthDisplaySection
        private(set) var axisMarkers: [String] = []
        private(set) var dataSeries: [OCKDataSeries] = []
        private(set) var numberFormatter: NumberFormatter = NumberFormatter()
        private(set) var plotType: OCKCartesianGraphView.PlotType = .line
        private(set) var defaultSelectedIndex: Int? = nil
        private(set) var subtitle: String? = nil
        private(set) var accessibilityIdentifier: String? = nil
        private(set) var accessibilityDescription: String = ""
        private(set) var valueRange: ClosedRange<CGFloat>? = nil
        weak var chartView: OCKCartesianChartView?

        init(section: HealthDisplaySection) {
            self.section = section
            configure()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let chartView = chartView else { return }

            let location = gesture.location(in: chartView.graphView)
            let graphFrame = chartView.graphView.bounds

            // 计算点击位置对应的数据索引
            let relativeX = location.x / graphFrame.width
            let dataIndex = Int(relativeX * CGFloat(dataSeries.first?.dataPoints.count ?? 0))

            // 更新选中的数据点
            if dataIndex >= 0 && dataIndex < (dataSeries.first?.dataPoints.count ?? 0) {
                chartView.graphView.selectedIndex = dataIndex

                // 提供触觉反馈
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                feedbackGenerator.impactOccurred()
            }
        }

        func update(with section: HealthDisplaySection) {
            self.section = section
            configure()
        }

        private func configure() {
            plotType = Self.plotType(for: section.kind)
            numberFormatter = Self.makeNumberFormatter(for: section.kind)
            dataSeries = section.chartSeries.map(Self.makeSeries)
            axisMarkers = Self.makeAxisMarkers(from: section)
            defaultSelectedIndex = axisMarkers.isEmpty ? nil : axisMarkers.count - 1
            subtitle = makeSubtitle(from: section)
            accessibilityIdentifier = makeAccessibilityIdentifier()
            accessibilityDescription = makeAccessibilityDescription()
            valueRange = calculateValueRange()
        }

        /// 计算图表的值范围，为某些数据类型提供更好的显示效果
        private func calculateValueRange() -> ClosedRange<CGFloat>? {
            // 对于某些健康数据类型，我们可以设置合理的默认范围
            switch section.kind {
            case .heartRate:
                // 心率通常在 40-200 bpm 范围内
                return 40...200
            case .sleep:
                // 睡眠时长通常显示 0-12 小时
                return 0...12
            case .steps, .activeEnergy:
                // 步数和能量消耗让 CareKit 自动计算范围
                return nil
            }
        }

        private func makeSubtitle(from section: HealthDisplaySection) -> String? {
            if let first = section.rows.first?.detail, !first.isEmpty {
                return first
            }
            if let series = section.chartSeries.first, let last = series.points.last {
                let valueText = numberFormatter.string(from: NSNumber(value: last.value)) ?? "\(last.value)"
                let timeText = Self.timeFormatter.string(from: last.end)
                if series.unitTitle.isEmpty {
                    return "\(valueText) @ \(timeText)"
                } else {
                    return "\(valueText) \(series.unitTitle) · \(timeText)"
                }
            }
            return nil
        }

        private func makeAccessibilityIdentifier() -> String? {
            "carekit.chart.\(section.kind)"
        }

        private func makeAccessibilityDescription() -> String {
            guard let series = section.chartSeries.first else {
                return section.title
            }

            let pointCount = series.points.count
            guard pointCount > 0 else {
                return "\(section.title)，暂无数据"
            }

            let values = series.points.map { $0.value }
            let avgValue = values.reduce(0, +) / Double(pointCount)
            let maxValue = values.max() ?? 0
            let minValue = values.min() ?? 0

            let avgText = numberFormatter.string(from: NSNumber(value: avgValue)) ?? "\(Int(avgValue))"
            let maxText = numberFormatter.string(from: NSNumber(value: maxValue)) ?? "\(Int(maxValue))"
            let minText = numberFormatter.string(from: NSNumber(value: minValue)) ?? "\(Int(minValue))"

            let unit = series.unitTitle.isEmpty ? "" : series.unitTitle

            return "\(section.title)，显示 \(pointCount) 个数据点。平均值 \(avgText) \(unit)，最高 \(maxText) \(unit)，最低 \(minText) \(unit)。"
        }

        private static func plotType(for kind: HealthDisplaySection.Kind) -> OCKCartesianGraphView.PlotType {
            switch kind {
            case .steps, .activeEnergy:
                return .bar
            case .heartRate, .sleep:
                return .line
            }
        }

        private static func makeNumberFormatter(for kind: HealthDisplaySection.Kind) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.locale = .autoupdatingCurrent
            switch kind {
            case .steps:
                formatter.maximumFractionDigits = 0
            case .activeEnergy:
                formatter.maximumFractionDigits = 1
            case .heartRate:
                formatter.maximumFractionDigits = 0
            case .sleep:
                formatter.maximumFractionDigits = 0
            }
            return formatter
        }

        private static func makeSeries(_ series: HealthDisplaySeries) -> OCKDataSeries {
            // 性能优化：如果数据点过多，进行下采样
            let sampledValues = sampleDataPoints(from: series.points)
            let title = series.unitTitle.isEmpty ? series.title : "\(series.title)（\(series.unitTitle)）"

            // 根据数据类型设置颜色、渐变和尺寸
            let (startColor, endColor, size) = seriesStyle(for: series.id)

            // 使用渐变初始化器创建数据系列
            let dataSeries = OCKDataSeries(
                values: sampledValues,
                title: title,
                gradientStartColor: startColor,
                gradientEndColor: endColor,
                size: size
            )

            return dataSeries
        }

        /// 根据健康数据类型返回样式配置
        private static func seriesStyle(for id: HealthDisplaySeries.ID) -> (UIColor, UIColor, CGFloat) {
            switch id {
            case .steps:
                return (
                    UIColor.systemBlue.withAlphaComponent(0.8),
                    UIColor.systemBlue.withAlphaComponent(0.3),
                    10
                )
            case .activeEnergy:
                return (
                    UIColor.systemRed.withAlphaComponent(0.8),
                    UIColor.systemRed.withAlphaComponent(0.3),
                    10
                )
            case .heartRate:
                return (
                    UIColor.systemPink.withAlphaComponent(0.6),
                    UIColor.systemPink.withAlphaComponent(0.2),
                    3
                )
            case .sleep:
                return (
                    UIColor.systemPurple.withAlphaComponent(0.6),
                    UIColor.systemPurple.withAlphaComponent(0.2),
                    3
                )
            }
        }

        /// 对数据点进行采样以提高性能
        /// 如果数据点数量超过合理范围，使用下采样保留关键数据点
        private static func sampleDataPoints(from points: [HealthDisplayPoint]) -> [CGFloat] {
            let maxDataPoints = 100  // 最大数据点数，避免性能问题

            if points.count <= maxDataPoints {
                return points.map { CGFloat($0.value) }
            }

            // 使用最大-最小采样算法，保留数据的极值特征
            var sampledValues: [CGFloat] = []
            let step = Double(points.count) / Double(maxDataPoints)

            for i in 0..<maxDataPoints {
                let startIndex = Int(Double(i) * step)
                let endIndex = min(Int(Double(i + 1) * step), points.count)

                if startIndex < endIndex {
                    let segment = points[startIndex..<endIndex]
                    // 保留该段的最大值和最小值（如果空间允许）
                    if let maxVal = segment.map({ $0.value }).max() {
                        sampledValues.append(CGFloat(maxVal))
                    }
                }
            }

            return sampledValues
        }

        private static func makeAxisMarkers(from section: HealthDisplaySection) -> [String] {
            guard let firstSeries = section.chartSeries.first else { return [] }
            let points = firstSeries.points
            guard !points.isEmpty else { return [] }

            // 根据时间跨度选择合适的日期格式
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent

            if let first = points.first, let last = points.last {
                let timeInterval = last.end.timeIntervalSince(first.start)

                if timeInterval <= 3600 {
                    // 1小时内 - 显示分钟和秒
                    formatter.dateFormat = "HH:mm:ss"
                } else if timeInterval <= 86400 {
                    // 24小时内 - 显示小时和分钟
                    formatter.dateFormat = "HH:mm"
                } else if timeInterval <= 604800 {
                    // 一周内 - 显示日期和小时
                    formatter.dateFormat = "MM-dd HH:mm"
                } else {
                    // 超过一周 - 只显示日期
                    formatter.dateFormat = "MM-dd"
                }
            } else {
                formatter.dateFormat = "HH:mm"
            }

            // 如果数据点超过 12 个，进行采样以提高性能
            // 根据 CareKit 文档，当数据点数超过屏幕像素数时，性能会下降
            let maxMarkers = 12
            if points.count > maxMarkers {
                let step = points.count / maxMarkers
                return stride(from: 0, to: points.count, by: step).map { index in
                    formatter.string(from: points[index].start)
                }
            }

            return points.map { formatter.string(from: $0.start) }
        }

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = .autoupdatingCurrent
            formatter.dateFormat = "MM-dd HH:mm"
            return formatter
        }()
    }
}
#else

struct CareKitChartView: View {
    let section: HealthDisplaySection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.headline)
            Text("CareKitUI 未可用，显示简化占位内容")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#endif
