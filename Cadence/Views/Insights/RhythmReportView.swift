import SwiftUI
import SwiftData

struct RhythmReportView: View {
    @Query private var events: [Event]
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    private var report: MonthlyReport {
        RhythmReportEngine.monthlyReport(events: events)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Gradient header
                headerSection

                VStack(spacing: CadenceTheme.spacingLG) {
                    // Stats grid
                    statsGrid

                    // Most consistent highlight
                    if let eventName = report.mostConsistentEvent,
                       let emoji = report.mostConsistentEmoji,
                       let percent = report.consistencyPercent {
                        mostConsistentCard(name: eventName, emoji: emoji, percent: percent)
                    }

                    // Busiest day callout
                    if let day = report.busiestDay {
                        busiestDayCard(day: day)
                    }

                    // Insights
                    if !report.insights.isEmpty {
                        insightsSection
                    }

                    // Share button
                    shareButton
                        .padding(.bottom, CadenceTheme.spacingXL)
                }
                .padding(.horizontal, CadenceTheme.cardPadding)
                .padding(.top, CadenceTheme.spacingLG)
            }
        }
        .background(CadenceTheme.backgroundPrimary)
        .navigationTitle("Rhythm Report")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [CadenceTheme.teal, CadenceTheme.sage],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: CadenceTheme.spacingSM) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))

                Text(report.month)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)

                Text("Rhythm Report")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.vertical, CadenceTheme.spacingXL)
        }
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28
            )
        )
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: CadenceTheme.spacingSM) {
            statCell(value: "\(report.totalLogs)", label: "Total Logs", icon: "chart.bar.fill")
            statCell(value: "\(report.activeEvents)", label: "Active Events", icon: "square.grid.2x2.fill")
            statCell(
                value: report.consistencyPercent.map { "\($0)%" } ?? "--",
                label: "Consistency",
                icon: "target"
            )
        }
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(CadenceTheme.teal)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(CadenceTheme.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(CadenceTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cadenceCard()
    }

    // MARK: - Most Consistent Card

    private func mostConsistentCard(name: String, emoji: String, percent: Int) -> some View {
        HStack(spacing: CadenceTheme.spacingMD) {
            // Progress ring with SF Symbol
            ZStack {
                Circle()
                    .stroke(CadenceTheme.sage.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: Double(percent) / 100.0)
                    .stroke(CadenceTheme.sage, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Image(systemName: emoji)
                    .font(.title3)
                    .foregroundStyle(CadenceTheme.sage)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text("Most Consistent")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .textCase(.uppercase)

                Text(name)
                    .font(.headline)
                    .foregroundStyle(CadenceTheme.textPrimary)

                Text("\(percent)% on time")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.sage)
            }

            Spacer()
        }
        .cadenceCard(accent: CadenceTheme.sage)
    }

    // MARK: - Busiest Day

    private func busiestDayCard(day: String) -> some View {
        HStack(spacing: CadenceTheme.spacingMD) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(CadenceTheme.sand)

            VStack(alignment: .leading, spacing: 2) {
                Text("Busiest Day")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .textCase(.uppercase)

                Text(day)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CadenceTheme.textPrimary)
            }

            Spacer()
        }
        .cadenceCard(accent: CadenceTheme.sand)
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
            Text("Insights")
                .font(.headline)
                .foregroundStyle(CadenceTheme.textPrimary)
                .padding(.leading, CadenceTheme.spacingXS)

            ForEach(Array(report.insights.enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insightIcon(for: index))
                        .font(.system(size: 16))
                        .foregroundStyle(CadenceTheme.teal)
                        .frame(width: 24)
                        .padding(.top, 2)

                    Text(insight)
                        .font(.subheadline)
                        .foregroundStyle(CadenceTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .cadenceCard()
            }
        }
    }

    private func insightIcon(for index: Int) -> String {
        let icons = ["chart.bar.fill", "target", "calendar", "arrow.up.right", "exclamationmark.circle"]
        return icons[index % icons.count]
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            shareImage = reportShareCard.renderAsImage(size: CGSize(width: 390, height: 520))
            showShareSheet = true
        } label: {
            Label("Share Report", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [CadenceTheme.teal, CadenceTheme.sage],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: CadenceTheme.teal.opacity(0.4), radius: 12, y: 6)
                )
        }
    }

    // MARK: - Share Card Image

    private var reportShareCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [CadenceTheme.teal, CadenceTheme.sage],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 12, y: 0)

                Text(report.month)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Rhythm Report")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(report.totalLogs)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("logs")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    VStack(spacing: 4) {
                        Text("\(report.activeEvents)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("events")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    if let percent = report.consistencyPercent {
                        VStack(spacing: 4) {
                            Text("\(percent)%")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            Text("consistency")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.2))
                )

                if let eventName = report.mostConsistentEvent {
                    Text("Most consistent: \(eventName)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Text("Tracked with Cadence")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 20)
            }
            .padding(24)
        }
        .frame(width: 390, height: 520)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RhythmReportView()
    }
    .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
