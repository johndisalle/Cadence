import SwiftUI
import SwiftData

struct EditEventView: View {
    @Bindable var event: Event
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var accentColorHex: String = ""
    @State private var category: EventCategory = .general
    @State private var customNotes: String = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Identity
                Section("Name & Icon") {
                    TextField("Event name", text: $name)

                    VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                        Text("Emoji")
                            .font(.subheadline)
                            .foregroundStyle(CadenceTheme.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                let presets = CadenceTheme.emojiPresets[category] ?? CadenceTheme.emojiPresets[.general]!
                                ForEach(presets, id: \.self) { e in
                                    Image(systemName: e)
                                        .font(.title2)
                                        .foregroundStyle(CadenceTheme.textPrimary)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(emoji == e ? Color(hex: accentColorHex).opacity(0.2) : Color.clear)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(emoji == e ? Color(hex: accentColorHex) : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture { emoji = e }
                                }
                            }
                        }
                    }
                }

                // MARK: - Color
                Section("Accent Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CadenceTheme.accentPresets, id: \.hex) { preset in
                            Circle()
                                .fill(Color(hex: preset.hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: accentColorHex == preset.hex ? 3 : 0)
                                )
                                .onTapGesture { accentColorHex = preset.hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Category
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(EventCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - Notes
                Section("Notes") {
                    TextField("Optional notes...", text: $customNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // MARK: - Archive
                Section {
                    Button {
                        event.isArchived.toggle()
                        dismiss()
                    } label: {
                        Label(
                            event.isArchived ? "Unarchive Event" : "Archive Event",
                            systemImage: event.isArchived ? "tray.and.arrow.up" : "archivebox"
                        )
                    }
                }

                // MARK: - Delete
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        applyChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Delete Event?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(event)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \"\(event.name)\" and all its logs. This cannot be undone.")
            }
            .onAppear {
                name = event.name
                emoji = event.emoji
                accentColorHex = event.accentColorHex
                category = event.category
                customNotes = event.customNotes ?? ""
            }
        }
    }

    private func applyChanges() {
        event.name = name.trimmingCharacters(in: .whitespaces)
        event.emoji = emoji
        event.accentColorHex = accentColorHex
        event.category = category
        event.customNotes = customNotes.isEmpty ? nil : customNotes
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Event.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let event = Event(name: "Water Plants", emoji: "leaf.fill", accentColorHex: "#7FA886", category: .home)
    container.mainContext.insert(event)

    return EditEventView(event: event)
        .modelContainer(container)
}
