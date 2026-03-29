import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedEmoji = "📌"
    @State private var selectedColorHex = CadenceTheme.accentPresets[0].hex
    @State private var selectedCategory: EventCategory = .general
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var emojisForCategory: [String] {
        CadenceTheme.emojiPresets[selectedCategory] ?? CadenceTheme.emojiPresets[.general]!
    }

    private let emojiColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Name
                Section {
                    TextField("Event name", text: $name)
                        .font(.body)
                } header: {
                    Text("Name")
                }

                // MARK: - Category
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(EventCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }

                // MARK: - Emoji
                Section {
                    LazyVGrid(columns: emojiColumns, spacing: 12) {
                        ForEach(emojisForCategory, id: \.self) { emoji in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedEmoji = emoji
                                }
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedEmoji == emoji
                                                  ? Color(hex: selectedColorHex).opacity(0.2)
                                                  : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(selectedEmoji == emoji
                                                          ? Color(hex: selectedColorHex)
                                                          : Color.clear,
                                                          lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, CadenceTheme.spacingXS)
                } header: {
                    Text("Emoji")
                }

                // MARK: - Color
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(CadenceTheme.accentPresets, id: \.hex) { preset in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedColorHex = preset.hex
                                    }
                                } label: {
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.white, lineWidth: selectedColorHex == preset.hex ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color(hex: preset.hex).opacity(0.5),
                                                              lineWidth: selectedColorHex == preset.hex ? 2 : 0)
                                                .scaleEffect(selectedColorHex == preset.hex ? 1.25 : 1)
                                        )
                                        .scaleEffect(selectedColorHex == preset.hex ? 1.1 : 1.0)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(preset.name)
                            }
                        }
                        .padding(.vertical, CadenceTheme.spacingSM)
                        .padding(.horizontal, 2)
                    }
                } header: {
                    Text("Color")
                }

                // MARK: - Notes
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .font(.body)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Optional. Add any details you want to remember.")
                        .font(.caption)
                }

                // MARK: - Create Button
                Section {
                    Button {
                        createEvent()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Event")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSave ? Color(hex: selectedColorHex) : Color.gray.opacity(0.4))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedCategory) {
                // Reset emoji to first option when category changes
                if let firstEmoji = CadenceTheme.emojiPresets[selectedCategory]?.first {
                    selectedEmoji = firstEmoji
                }
            }
        }
    }

    // MARK: - Create

    private func createEvent() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let event = Event(
            name: trimmedName,
            emoji: selectedEmoji,
            accentColorHex: selectedColorHex,
            category: selectedCategory,
            customNotes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(event)
        dismiss()
    }
}

#Preview {
    AddEventView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
