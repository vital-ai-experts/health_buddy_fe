import SwiftUI
import FeatureAgendaApi

/// Builder for Agenda feature views
public final class AgendaBuilder: FeatureAgendaBuildable {
    public init() {}

    public func makeAgendaTabView() -> AnyView {
        AnyView(AgendaTabView())
    }

    public func makeAgendaSettingsView() -> AnyView {
        AnyView(AgendaSettingsView())
    }

    public func makeDungeonDetailView() -> AnyView {
        AnyView(DungeonDetailView())
    }

    public func makeDungeonDetailView(onStart: @escaping () -> Void) -> AnyView {
        AnyView(DungeonDetailView(onStart: onStart))
    }
}
