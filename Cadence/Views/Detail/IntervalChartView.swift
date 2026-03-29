import SwiftUI
import SwiftData
import Charts

struct IntervalChartView: View {
    var event: Event

    @State private var animateChart = false

    private var intervals: [Double] {
        IntervalEngine.intervals(for: event)
    }

    private var average: Double {
        guard !intervals.isEmpty else { return 0 }
        return intervals.reduce(0, +) / Double(intervals.count)
    }

    private var dataPoints: [(index: Int, value: Double)] {
        intervals.enumerated().map { (index: $0.offset + 1, value: $0.element) }
    }

    private var peakIndex: Int? {
        dataPoints.max(by: { $0.value < $1.value })?.index
    }

    private var valleyIndex: Int? {
        dataPoints.min(by: { $0.value < $1.value })?.index
    }

    var body: some View {
        if intervals.count < 2 {
            placeholderView
        } else {
            chartView
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateChart = true
                    }
                }
        }
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(dataPoints, id: \.index) { point in
                LineMark(
                    x: .value("Log", point.index),
                    y: .value("Days", animateChart ? point.value : 0)
                )
                .foregroundStyle(event.accentColor.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Log", point.index),
                    y: .value("Days", animateChart ? point.value : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [event.accentColor.opacity(0.3), event.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            RuleMark(y: .value("Average", average))
                .foregroundStyle(event.accentColor.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("avg \(String(format: "%.1f", average))d")
                        .font(.caption2)
                        .foregroundStyle(CadenceTheme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(CadenceTheme.backgroundSecondary)
                        )
                }

            // Peak annotation
            if let peak = peakIndex,
               let point = dataPoints.first(where: { $0.index == peak }) {
                PointMark(
                    x: .value("Log", point.index),
                    y: .value("Days", animateChart ? point.value : 0)
                )
                .foregroundStyle(CadenceTheme.urgencyHigh)
                .symbolSize(40)
                .annotation(position: .top) {
                    Text("\(Int(round(point.value)))d")
                        .font(.caption2.bold())
                        .foregroundStyle(CadenceTheme.urgencyHigh)
                }
            }

            // Valley annotation
            if let valley = valleyIndex, valley != peakIndex,
               let point = dataPoints.first(where: { $0.index == valley }) {
                PointMark(
                    x: .value("Log", point.index),
                    y: .value("Days", animateChart ? point.value : 0)
                )
                .foregroundStyle(CadenceTheme.urgencyLow)
                .symbolSize(40)
                .annotation(position: .bottom) {
                    Text("\(Int(round(point.value)))d")
                        .font(.caption2.bold())
                        .foregroundStyle(CadenceTheme.urgencyLow)
                }
            }
        }
        .chartXAxisLabel("Log #", position: .bottom, alignment: .center)
        .chartYAxisLabel("Days between", position: .leading, alignment: .center)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: min(dataPoints.count, 6)))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 220)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36))
                .foregroundStyle(CadenceTheme.textTertiary)
            Text("Not enough data yet")
                .font(.headline)
                .foregroundStyle(CadenceTheme.textSecondary)
            Text("Log at least 2 times to see your interval chart.")
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Event.self, LogEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let event = Event(name: "Water Plants", emoji: "🪴", accentColorHex: "#7FA886", category: .home)
    let cal = Calendar.current
    let now = Date()
    for i in stride(from: 0, to: 60, by: 3) {
        let jitter = Int.random(in: -1...1)
        let date = cal.date(byAdding: .day, value: -(i + jitter), to: now)!
        let log = LogEntry(timestamp: date)
        event.logs.append(log)
    }
    container.mainContext.insert(event)

    return IntervalChartView(event: event)
        .padding()
        .modelContainer(container)
}
