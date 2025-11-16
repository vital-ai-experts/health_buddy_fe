import SwiftUI
import FeatureAgendaApi

/// Builder for Agenda feature views
final class AgendaBuilder: FeatureAgendaBuildable {
    func makeAgendaSettingsView() -> AnyView {
        AnyView(AgendaSettingsView())
    }
}
