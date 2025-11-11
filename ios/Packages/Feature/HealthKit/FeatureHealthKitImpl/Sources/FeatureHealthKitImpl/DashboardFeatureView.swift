//
//  DashboardFeatureView.swift
//  DashboardFeature
//
//  Created by Codex on 2025/2/14.
//

import SwiftUI
import SwiftData
import DomainHealth
import LibraryServiceLoader

public struct DashboardFeatureView: View {
    private let dataService: HealthDataService

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HealthSection.createdAt, order: .reverse)
    private var savedSections: [HealthSection]

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentSections: [HealthDisplaySection] = []

    public init(dataService: HealthDataService = ServiceManager.shared.resolve(HealthDataService.self)) {
        self.dataService = dataService
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                actionButtons

                if isLoading {
                    ProgressView("正在同步数据…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let errorMessage {
                    errorBanner(errorMessage)
                }

                if !currentSections.isEmpty {
                    Text("当前数据")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)

                    ForEach(currentSections) { section in
                        sectionVisual(for: section)
                    }
                }

                if !savedSections.isEmpty {
                    Text("历史记录")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)

                    ForEach(savedSections) { section in
                        historySectionCard(for: section)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Health 数据概览")
        .task { await syncDataIfNeeded() }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("同步最近24小时数据", action: sync)
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
            Button("清除错误", action: { errorMessage = nil })
                .buttonStyle(.bordered)
                .disabled(errorMessage == nil)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func sectionVisual(for section: HealthDisplaySection) -> some View {
        VStack(spacing: 16) {
            if !section.chartSeries.isEmpty {
                CareKitChartView(section: section)
                    .frame(height: chartHeight(for: section.kind))
            } else {
                emptyChartPlaceholder(for: section)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyChartPlaceholder(for section: HealthDisplaySection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.headline)
            Text("暂无可视化数据")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func chartHeight(for kind: HealthDisplaySection.Kind) -> CGFloat {
        switch kind {
        case .steps, .activeEnergy:
            return 280
        case .heartRate, .sleep:
            return 260
        }
    }

    private func historySectionCard(for section: HealthSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.title)
                    .font(.headline)
                Spacer()
                Text(section.createdAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(section.rows.enumerated()), id: \.offset) { index, row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.headline)
                        .font(.subheadline)
                        .bold()
                    Text(row.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < section.rows.count - 1 {
                    Divider()
                        .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    private func syncDataIfNeeded() async {
        guard currentSections.isEmpty else { return }
        await syncData()
    }

    private func sync() {
        Task { await syncData() }
    }

    @MainActor
    private func syncData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let sections = try await dataService.fetchLatestSections()
            currentSections = sections
            try dataService.persist(sections, into: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            currentSections = []
        }

        isLoading = false
    }
}

#Preview {
    DashboardFeatureView(dataService: PreviewDataService())
        .modelContainer(for: [HealthSection.self, HealthRow.self], inMemory: true)
}

private final class PreviewDataService: HealthDataService {
    func fetchLatestSections() async throws -> [HealthDisplaySection] {
        [
            HealthDisplaySection(
                kind: .steps,
                title: "步数（最近24小时）",
                rows: [
                    HealthDisplayRow(headline: "2,500 步", detail: "02-14 08:00 - 09:00")
                ],
                chartSeries: [
                    HealthDisplaySeries(
                        id: .steps,
                        title: "步数",
                        unitTitle: "步",
                        points: stride(from: 0, to: 6, by: 1).map { index -> HealthDisplayPoint in
                            let start = Calendar.current.date(byAdding: .hour, value: -index, to: .now) ?? .now
                            let value = Double(600 + (index * 150))
                            return HealthDisplayPoint(start: start, end: start.addingTimeInterval(1800), value: value)
                        }.sorted { $0.start < $1.start }
                    )
                ]
            )
        ]
    }

    func persist(_ sections: [HealthDisplaySection], into context: ModelContext) throws {}

    func fetchRecentDataAsJSON() async throws -> String {
        return "{\"preview\": true}"
    }
}
