import SimpleCounterCore
import SwiftUI

struct CounterCardView: View {
    let counter: Counter
    let currentCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Text(counter.emoji)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text(counter.name)
                    .font(.headline)

                subtitleText
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(currentCount)")
                .font(.title2.monospacedDigit().bold())
                .foregroundStyle(goalColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Private

    private var subtitleText: some View {
        if let goal = counter.goal {
            Text("\(counter.resetInterval.displayName) · goal \(goal)")
        } else {
            Text(counter.resetInterval.displayName)
        }
    }

    private var goalColor: Color {
        guard let goal = counter.goal else { return .primary }
        return currentCount >= goal ? .red : .primary
    }

    private var accessibilityLabel: String {
        var label = "\(counter.name), \(currentCount)"
        if let goal = counter.goal {
            label += " of \(goal)"
        }
        label += ", \(counter.resetInterval.displayName)"
        return label
    }
}

#Preview {
    List {
        CounterCardView(counter: .preview, currentCount: 7)
        CounterCardView(counter: Counter(name: "Water", emoji: "💧", resetInterval: .daily, goal: 8), currentCount: 8)
        CounterCardView(counter: Counter(name: "Steps", emoji: "👟", resetInterval: .weekly), currentCount: 12450)
    }
    .listStyle(.plain)
}
