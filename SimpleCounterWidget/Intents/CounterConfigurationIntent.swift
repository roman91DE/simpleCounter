import AppIntents
import WidgetKit

/// Widget configuration intent — lets the user pick which counter this widget instance tracks.
struct CounterConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Counter"
    static var description = IntentDescription("Choose which counter to display.")

    @Parameter(title: "Counter")
    var counter: CounterEntity?
}
