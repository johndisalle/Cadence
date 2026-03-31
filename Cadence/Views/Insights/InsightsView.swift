import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query private var events: [Event]
    @State private var showPaywall = false

    private var premium: PremiumManager { .shared }

    private var pulse: CadencePulse {
        InsightsEngine.generatePulse(events: events)
    }

    var body: some View {
        NavigationStack {
            Group {
                if !premium.canUseInsights() {
                    insightsPaywall
                } else if events.isEmpty {
                    EmptyStateView(
                        symbolName: "waveform.path.ecg",
                        title: "No Insights Yet",
                        subtitle: "Add some events and log them a few times. Cadence will learn your rhythms and offer smart suggestions."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: CadenceTheme.spacingLG) {
                            pulseSection
                            monthlyReportSection
                            suggestionsSection
                            breakdownSection
                        }
                        .padding(.horizontal, CadenceTheme.cardPadding)
                        .padding(.bottom, CadenceTheme.spacingXL)
                    }
                }
            }
            .navigationTitle("Insights")
            .background(CadenceTheme.backgroundPrimary)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Insights Paywall Teaser

    private var insightsPaywall: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(CadenceTheme.teal.opacity(0.4))

            VStack(spacing: CadenceTheme.spacingSM) {
                Text("AI Rhythm Insights")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textPrimary)

                Text("Get your weekly Cadence Pulse score, smart suggestions, and seasonal awareness.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showPaywall = true
            } label: {
                Label("Unlock with Cadence Pro", systemImage: "crown.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, CadenceTheme.spacingLG)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [CadenceTheme.teal, CadenceTheme.sage],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
            }

            Spacer()
            Spacer()
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Pulse Section

    private var pulseSection: some View {
        VStack(spacing: CadenceTheme.spacingMD) {
            PulseRingView(
                score: pulse.overallScore,
                accentColor: pulseColor
            )
            .padding(.top, CadenceTheme.spacingSM)

            Text(pulse.weeklyMessage)
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CadenceTheme.spacingMD)
        }
        .frame(maxWidth: .infinity)
        .cadenceCard()
    }

    private var pulseColor: Color {
        if pulse.overallScore >= 80 {
            return CadenceTheme.sage
        } else if pulse.overallScore >= 50 {
            return CadenceTheme.sand
        } else {
            return CadenceTheme.coral
        }
    }

    // MARK: - Monthly Report Section

    private var monthlyReportSection: some View {
        let report = RhythmReportEngine.monthlyReport(events: events)
        return NavigationLink {
            RhythmReportView()
        } label: {
            HStack(spacing: CadenceTheme.spacingMD) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(CadenceTheme.teal)

                VStack(alignment: .leading, spacing: 2) {
                    Text(report.month)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CadenceTheme.textPrimary)

                    HStack(spacing: CadenceTheme.spacingXS) {
                        Text("\(report.totalLogs) logs")
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.textSecondary)

                        if let percent = report.consistencyPercent {
                            Text("\u{2022} \(percent)% consistency")
                                .font(.caption)
                                .foregroundStyle(CadenceTheme.textSecondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textTertiary)
            }
            .cadenceCard(accent: CadenceTheme.teal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestions Section

    @ViewBuilder
    private var suggestionsSection: some View {
        if !pulse.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                Text("Smart Suggestions")
                    .font(.headline)
                    .foregroundStyle(CadenceTheme.textPrimary)
                    .padding(.leading, CadenceTheme.spacingXS)

                ForEach(pulse.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(CadenceTheme.sand)
                            .frame(width: 24)
                            .padding(.top, 2)

                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(CadenceTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .cadenceCard()
                }
            }
        }
    }

    // MARK: - Event Breakdown Section

    @ViewBuilder
    private var breakdownSection: some View {
        if !pulse.eventSummaries.isEmpty {
            VStack(alignment: .leading, spacing: CadenceTheme.spacingSM) {
                Text("Event Breakdown")
                    .font(.headline)
                    .foregroundStyle(CadenceTheme.textPrimary)
                    .padding(.leading, CadenceTheme.spacingXS)

                ForEach(pulse.eventSummaries, id: \.eventName) { summary in
                    eventSummaryRow(summary)
                }
            }
        }
    }

    private func eventSummaryRow(_ summary: EventSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: summary.emoji)
                .font(.title2)
                .frame(width: 36)
                .foregroundStyle(summary.onTrack ? CadenceTheme.sage : CadenceTheme.coral)

            VStack(alignment: .leading, spacing: 2) {
                Text(summary.eventName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(CadenceTheme.textPrimary)

                HStack(spacing: CadenceTheme.spacingXS) {
                    Text("\(summary.logsThisWeek) this week")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)

                    Text("vs \(summary.logsLastWeek) last week")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: CadenceTheme.spacingSM) {
                Image(systemName: summary.trend.icon)
                    .font(.caption)
                    .foregroundStyle(trendColor(for: summary.trend))

                Image(systemName: summary.onTrack ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(summary.onTrack ? CadenceTheme.sage : CadenceTheme.coral)
            }
        }
        .cadenceCard()
    }

    private func trendColor(for trend: WeeklyTrend) -> Color {
        switch trend {
        case .up: return CadenceTheme.sage
        case .down: return CadenceTheme.coral
        case .steady: return CadenceTheme.textSecondary
        }
    }
}

#Preview {
    InsightsView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
