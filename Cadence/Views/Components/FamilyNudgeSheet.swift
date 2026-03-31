import SwiftUI

struct FamilyNudgeSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var customMessage: String = ""
    @State private var copied = false

    private var nudge: FamilyNudge {
        FamilyNudgeService.createNudge(for: event)
    }

    private var finalMessage: String {
        let msg = customMessage.isEmpty ? nudge.message : customMessage
        return "\(msg)\n\nTracked with Cadence — Track life's natural rhythm\nhttps://apps.apple.com/app/cadence"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CadenceTheme.spacingLG) {
                    // Event header
                    VStack(spacing: CadenceTheme.spacingSM) {
                        Image(systemName: event.emoji)
                            .font(.system(size: 44))
                            .foregroundStyle(event.accentColor)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle().fill(event.accentColor.opacity(0.12))
                            )

                        Text(event.name)
                            .font(.title3.weight(.bold))

                        statusBadge
                    }
                    .padding(.top, CadenceTheme.spacingMD)

                    // Message preview
                    VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                        Text("Message")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CadenceTheme.textSecondary)

                        TextField("Customize your message...", text: $customMessage, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(CadenceTheme.backgroundSecondary)
                            )

                        if customMessage.isEmpty {
                            Text(nudge.message)
                                .font(.subheadline)
                                .foregroundStyle(CadenceTheme.textTertiary)
                                .italic()
                                .padding(.horizontal, 4)
                        }
                    }

                    // App promo note
                    HStack(spacing: CadenceTheme.spacingSM) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.teal)
                        Text("A link to Cadence will be included so they can track it too.")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.textTertiary)
                    }

                    // Action buttons
                    VStack(spacing: CadenceTheme.spacingSM) {
                        ShareLink(item: finalMessage) {
                            Label("Send Reminder", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule().fill(event.accentColor)
                                )
                        }

                        Button {
                            UIPasteboard.general.string = finalMessage
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label(
                                copied ? "Copied!" : "Copy to Clipboard",
                                systemImage: copied ? "checkmark" : "doc.on.doc"
                            )
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(event.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .strokeBorder(event.accentColor, lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(.top, CadenceTheme.spacingSM)
                }
                .padding(.horizontal, CadenceTheme.spacingLG)
                .padding(.bottom, CadenceTheme.spacingXL)
            }
            .navigationTitle("Remind Someone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let stats = IntervalEngine.compute(for: event)
        if let stats = stats, stats.isOverdue {
            Text("Overdue by \(Int(stats.overdueByDays)) days")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(CadenceTheme.urgencyHigh))
        } else if let days = event.daysSinceLastLog {
            Text("Last done \(Int(days))d ago")
                .font(.caption.weight(.medium))
                .foregroundStyle(CadenceTheme.textSecondary)
        }
    }
}

#Preview {
    let event = Event(name: "Change HVAC Filter", emoji: "fan.fill", accentColorHex: "#7EB5D6", category: .home)
    return FamilyNudgeSheet(event: event)
}
