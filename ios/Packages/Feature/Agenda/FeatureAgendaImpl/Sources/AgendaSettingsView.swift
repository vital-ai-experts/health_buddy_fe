import SwiftUI
import FeatureAgendaApi
import LibraryServiceLoader
import LibraryBase

struct AgendaSettingsView: View {
    @StateObject private var viewModel = AgendaSettingsViewModel()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Agenda Live Activity")
                                .font(.headline)

                            Text(viewModel.isActive ? "Active" : "Inactive")
                                .font(.subheadline)
                                .foregroundStyle(viewModel.isActive ? .green : .secondary)
                        }

                        Spacer()
                    }

                    Text("Display your health tasks on the lock screen with live updates every 5 minutes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section {
                if viewModel.isActive {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.stopAgenda()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Agenda")
                        }
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.startAgenda()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Start Agenda")
                        }
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    FeatureRow(icon: "cloud.sun.fill", text: "Real-time weather updates")
                    FeatureRow(icon: "figure.run", text: "Personalized health tasks")
                    FeatureRow(icon: "arrow.clockwise", text: "Auto-refresh every 5 minutes")
                    FeatureRow(icon: "lock.shield.fill", text: "Works even when app is closed")
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Agenda Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.checkStatus()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

@MainActor
final class AgendaSettingsViewModel: ObservableObject {
    @Published var isActive = false
    @Published var errorMessage: String?

    private let agendaService: AgendaService

    init() {
        // Resolve AgendaService from ServiceManager
        self.agendaService = ServiceManager.shared.resolve(AgendaService.self)
    }

    func checkStatus() async {
        isActive = agendaService.isAgendaActive
    }

    func startAgenda() async {
        errorMessage = nil

        do {
            try await agendaService.startAgenda()
            isActive = true
        } catch {
            errorMessage = error.localizedDescription
            Log.e("❌ Failed to start agenda: \(error)", category: "Agenda")
        }
    }

    func stopAgenda() async {
        errorMessage = nil

        do {
            try await agendaService.stopAgenda()
            isActive = false
        } catch {
            errorMessage = error.localizedDescription
            Log.e("❌ Failed to stop agenda: \(error)", category: "Agenda")
        }
    }
}

#Preview {
    NavigationStack {
        AgendaSettingsView()
    }
}
