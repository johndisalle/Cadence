import SwiftUI
import PDFKit

struct PDFExportService {

    @MainActor
    static func generateSummary(events: [Event], title: String = "Cadence Summary") -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let titleString = NSAttributedString(string: title, attributes: titleAttrs)
            titleString.draw(at: CGPoint(x: margin, y: y))
            y += 44

            // Subtitle
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subtitle = NSAttributedString(
                string: "Generated \(dateFormatter.string(from: Date())) • Powered by Cadence",
                attributes: subtitleAttrs
            )
            subtitle.draw(at: CGPoint(x: margin, y: y))
            y += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: y))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.separator.setStroke()
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            y += 20

            let activeEvents = events.filter { !$0.isArchived }.sorted { ($0.logs.count) > ($1.logs.count) }

            for event in activeEvents {
                if y > pageHeight - 120 {
                    context.beginPage()
                    y = margin
                }

                // Event header
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                    .foregroundColor: UIColor.label
                ]
                let header = NSAttributedString(
                    string: event.name,
                    attributes: headerAttrs
                )
                header.draw(at: CGPoint(x: margin, y: y))
                y += 28

                // Stats
                let stats = IntervalEngine.compute(for: event)
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel
                ]

                let logCount = event.logs.count
                let lastLogged = event.lastLoggedDate?.dayOnlyFormatted ?? "Never"
                let rhythm = stats?.rhythm ?? "Not enough data"

                let body = NSAttributedString(
                    string: "\(logCount) logs • \(rhythm) • Last: \(lastLogged)",
                    attributes: bodyAttrs
                )
                body.draw(at: CGPoint(x: margin + 10, y: y))
                y += 20

                if let insight = stats?.insight {
                    let insightAttr = NSAttributedString(
                        string: insight,
                        attributes: [
                            .font: UIFont.italicSystemFont(ofSize: 11),
                            .foregroundColor: UIColor.tertiaryLabel
                        ]
                    )
                    insightAttr.draw(at: CGPoint(x: margin + 10, y: y))
                    y += 18
                }

                y += 12
            }

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .light),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let footer = NSAttributedString(
                string: "Cadence — Track life's natural rhythm",
                attributes: footerAttrs
            )
            footer.draw(at: CGPoint(x: margin, y: pageHeight - margin))
        }

        return data
    }
}
