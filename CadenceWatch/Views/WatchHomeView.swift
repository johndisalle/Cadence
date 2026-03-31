import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        NavigationStack {
            Group {
                if connectivity.events.isEmpty {
                    emptyState
                } else {
                    eventList
                }
            }
            .navigationTitle("Cadence")
        }
    }

    // MARK: - Event List

    private var eventList: some View {
        List {
            ForEach(connectivity.events) { event in
                NavigationLink(value: event.id) {
                    WatchEventRow(event: event)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: event.colorHex).opacity(0.12))
                )
            }
        }
        .listStyle(.carousel)
        .navigationDestination(for: String.self) { eventID in
            if let event = connectivity.events.first(where: { $0.id == eventID }) {
                WatchEventDetailView(event: event)
                    .environmentObject(connectivity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    connectivity.requestSync()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption2)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "#5BA4A4"))

            Text("Open Cadence on\niPhone to sync")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Event Row

struct WatchEventRow: View {
    let event: WatchEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.emoji)
                .font(.title3)
                .foregroundStyle(Color(hex: event.colorHex))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .lineLimit(1)

                Text(event.timeSinceLog)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            urgencyDot
        }
        .padding(.vertical, 4)
    }

    private var urgencyDot: some View {
        Circle()
            .fill(Color(hex: event.urgencyTier.color))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Preview

#Preview {
    let manager = WatchConnectivityManager.shared
    return WatchHomeView()
        .environmentObject(manager)
}
