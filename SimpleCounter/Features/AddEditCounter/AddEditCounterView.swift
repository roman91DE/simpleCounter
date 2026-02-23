import SimpleCounterCore
import SwiftUI

struct AddEditCounterView: View {
    let counterRepository: CounterRepository
    let counterToEdit: Counter?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var resetInterval: ResetInterval
    @State private var goalText: String
    @State private var errorMessage: String?

    init(counterRepository: CounterRepository, counterToEdit: Counter?) {
        self.counterRepository = counterRepository
        self.counterToEdit = counterToEdit
        _name = State(initialValue: counterToEdit?.name ?? "")
        _emoji = State(initialValue: counterToEdit?.emoji ?? "")
        _resetInterval = State(initialValue: counterToEdit?.resetInterval ?? .daily)
        _goalText = State(initialValue: counterToEdit?.goal.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Nicotine Gum", text: $name)
                }

                Section("Emoji") {
                    TextField("🍬", text: $emoji)
                        .onChange(of: emoji) { _, new in
                            // Keep only the first character if multiple are pasted
                            if new.count > 1 {
                                emoji = String(new.prefix(1))
                            }
                        }
                }

                Section("Resets") {
                    Picker("Reset interval", selection: $resetInterval) {
                        ForEach(ResetInterval.allCases, id: \.self) { interval in
                            Text(interval.displayName.capitalized).tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Optional", text: $goalText)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Goal")
                } footer: {
                    Text("Maximum count per period. Leave blank for no limit.")
                }
            }
            .navigationTitle(counterToEdit == nil ? "New Counter" : "Edit Counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Private

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !emoji.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var parsedGoal: Int? {
        guard !goalText.isEmpty, let value = Int(goalText), value > 0 else { return nil }
        return value
    }

    private func save() {
        do {
            if var existing = counterToEdit {
                existing.name = name.trimmingCharacters(in: .whitespaces)
                existing.emoji = emoji.trimmingCharacters(in: .whitespaces)
                existing.resetInterval = resetInterval
                existing.goal = parsedGoal
                try counterRepository.update(existing)
            } else {
                let counter = Counter(
                    name: name.trimmingCharacters(in: .whitespaces),
                    emoji: emoji.trimmingCharacters(in: .whitespaces),
                    resetInterval: resetInterval,
                    goal: parsedGoal
                )
                try counterRepository.insert(counter)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("New") {
    AddEditCounterView(
        counterRepository: CounterRepository(db: AppDatabase.makePreview()),
        counterToEdit: nil
    )
}

#Preview("Edit") {
    AddEditCounterView(
        counterRepository: CounterRepository(db: AppDatabase.makePreview()),
        counterToEdit: .preview
    )
}
