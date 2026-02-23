import SimpleCounterCore
import SwiftUI

struct CounterDetailView: View {
    @State var viewModel: CounterDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                countDisplay
                actionButtons
                statsSection
                if !viewModel.history.isEmpty {
                    HistoryChartView(
                        history: viewModel.history,
                        interval: viewModel.counter.resetInterval
                    )
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.counter.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Private

    private var header: some View {
        Text(viewModel.counter.emoji)
            .font(.system(size: 64))
            .accessibilityHidden(true)
    }

    private var countDisplay: some View {
        Text("\(viewModel.currentCount)")
            .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundStyle(goalExceededColor)
            .accessibilityLabel("Current count: \(viewModel.currentCount)")
            .contentTransition(.numericText())
            .animation(.bouncy, value: viewModel.currentCount)
    }

    private var goalExceededColor: Color {
        guard let goal = viewModel.counter.goal else { return .primary }
        return viewModel.currentCount >= goal ? .red : .primary
    }

    private var actionButtons: some View {
        HStack(spacing: 48) {
            Button {
                viewModel.decrement()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Decrement")

            Button {
                viewModel.increment()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.blue)
            }
            .accessibilityLabel("Increment")
        }
    }

    private var statsSection: some View {
        HStack(spacing: 0) {
            statCell(
                title: "Period",
                value: viewModel.counter.resetInterval.displayName.capitalized
            )

            Divider().frame(height: 40)

            if let goal = viewModel.counter.goal {
                statCell(
                    title: "Goal",
                    value: "\(goal)"
                )
                Divider().frame(height: 40)
            }

            statCell(
                title: "All time",
                value: "\(viewModel.history.map(\.1).reduce(0, +) + viewModel.currentCount)"
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        CounterDetailView(
            viewModel: CounterDetailViewModel(
                counter: .preview,
                counterRepository: CounterRepository(db: AppDatabase.makePreview()),
                entryRepository: CountEntryRepository(db: AppDatabase.makePreview())
            )
        )
    }
}
