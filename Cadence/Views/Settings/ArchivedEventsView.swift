import SwiftUI
import SwiftData

struct ArchivedEventsView: View {
    @Query(filter: #Predicate<Event> { $0.isArchived },
           sort: \Event.name)
    private var archivedEvents: [Event]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if archivedEvents.isEmpty {
                ContentUnavailableView(
                    "No Archived Events",
                    systemImage: "archivebox",
                    description: Text("Events you archive will appear here.")
                )
            } else {
                ForEach(archivedEvents, id: \.id) { event in
                    HStack(spacing: 12) {
                        Image(systemName: event.emoji)
                            .font(.title3)
                            .foregroundStyle(event.accentColor)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.name)
                                .font(.body.weight(.medium))
                            Text("\(event.logs.count) logs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            event.isArchived = false
                        } label: {
                            Text("Restore")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(CadenceTheme.teal)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let event = archivedEvents[index]
                        modelContext.delete(event)
                    }
                }
            }
        }
        .navigationTitle("Archived Events")
    }
}

#Preview {
    NavigationStack {
        ArchivedEventsView()
    }
    .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
