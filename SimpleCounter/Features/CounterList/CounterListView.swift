import SimpleCounterCore
import SwiftUI

struct CounterListView: View {
    @State var viewModel: CounterListViewModel
    @State private var showAddCounter = false
    @State private var counterToEdit: Counter?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.counters.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Simple Counter")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCounter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCounter) {
                AddEditCounterView(
                    counterRepository: viewModel.counterRepository,
                    counterToEdit: nil
                )
            }
            .sheet(item: $counterToEdit) { counter in
                AddEditCounterView(
                    counterRepository: viewModel.counterRepository,
                    counterToEdit: counter
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refresh()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Private

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No counters yet")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Add Counter") {
                showAddCounter = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.counters) { counter in
                NavigationLink {
                    CounterDetailView(
                        viewModel: CounterDetailViewModel(
                            counter: counter,
                            counterRepository: viewModel.counterRepository,
                            entryRepository: viewModel.entryRepository
                        )
                    )
                } label: {
                    CounterCardView(
                        counter: counter,
                        currentCount: viewModel.currentCounts[counter.id] ?? 0
                    )
                }
                .contextMenu {
                    Button("Edit") {
                        counterToEdit = counter
                    }
                    Button("Delete", role: .destructive) {
                        viewModel.delete(counter)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    CounterListView(
        viewModel: CounterListViewModel(
            counterRepository: CounterRepository(db: AppDatabase.makePreview()),
            entryRepository: CountEntryRepository(db: AppDatabase.makePreview())
        )
    )
}
