import SimpleCounterCore
import SwiftUI
import WidgetKit

struct CounterWidgetView: View {
    let entry: CounterWidgetEntry

    var body: some View {
        if let counter = entry.counter {
            widgetContent(counter: counter)
        } else {
            noCounterPlaceholder
        }
    }

    // MARK: - Private

    private func widgetContent(counter: Counter) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(counter.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Spacer()
                Text(counter.emoji)
                    .font(.caption)
            }

            Spacer()

            Text("\(entry.currentCount)")
                .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(goalColor(counter: counter))

            Spacer()

            HStack(spacing: 12) {
                Button(intent: CounterIntent(counterID: counter.id, delta: -1)) {
                    Image(systemName: "minus")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decrement \(counter.name)")

                Button(intent: CounterIntent(counterID: counter.id, delta: 1)) {
                    Image(systemName: "plus")
                        .font(.callout.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Increment \(counter.name)")
            }

            if let goal = counter.goal {
                Text("\(counter.resetInterval.displayName) · goal \(goal)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var noCounterPlaceholder: some View {
        VStack {
            Image(systemName: "plus.circle")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Add a counter\nin the app")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func goalColor(counter: Counter) -> Color {
        guard let goal = counter.goal else { return .primary }
        return entry.currentCount >= goal ? .red : .primary
    }
}

struct CounterWidget: Widget {
    let kind = "CounterWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CounterConfigurationIntent.self,
            provider: CounterWidgetProvider()
        ) { entry in
            CounterWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Counter")
        .description("Track your counter from the home screen.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    CounterWidget()
} timeline: {
    CounterWidgetEntry(date: .now, counter: .preview, currentCount: 7)
    CounterWidgetEntry(date: .now, counter: .preview, currentCount: 10)
}
