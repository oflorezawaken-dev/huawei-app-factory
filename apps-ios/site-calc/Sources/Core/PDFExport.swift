import Foundation
import PDFKit
import UIKit

/// Printable PDF export of a job (F009): the job name, the date, the tape
/// with its labels and running results, each solver result with the inputs
/// it came from, and the material list. Free forever, behind no purchase.
enum PDFExport {
    static func generate(job: SiteJob, precision: FractionPrecision, system: MeasurementSystem,
                          metricUnit: LengthUnit) -> Data {
        let pageWidth: CGFloat = 612 // US Letter, 72dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let titleFont = UIFont.boldSystemFont(ofSize: 18)
        let sectionFont = UIFont.boldSystemFont(ofSize: 14)
        let bodyFont = UIFont.systemFont(ofSize: 11)

        return renderer.pdfData { context in
            var y: CGFloat = margin
            var pageStarted = false

            func newPageIfNeeded(_ needed: CGFloat) {
                if !pageStarted || y + needed > pageHeight - margin {
                    context.beginPage()
                    pageStarted = true
                    y = margin
                }
            }

            func draw(_ text: String, font: UIFont, extraSpacing: CGFloat = 4) {
                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                let maxWidth = pageWidth - margin * 2
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin], attributes: attributes, context: nil)
                newPageIfNeeded(bounding.height + extraSpacing)
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: maxWidth, height: bounding.height),
                                         withAttributes: attributes)
                y += bounding.height + extraSpacing
            }

            newPageIfNeeded(0)
            draw(job.name, font: titleFont)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            draw(dateFormatter.string(from: job.updatedAt), font: bodyFont)
            if !job.note.isEmpty { draw(job.note, font: bodyFont) }

            if !job.tapeLines.isEmpty {
                draw("Tape", font: sectionFont)
                for line in job.tapeLines {
                    let shown = line.runningResult ?? line.operand
                    let op = line.operatorApplied.map(operatorSymbol) ?? ""
                    let display = QuantityFormatting.display(shown, precision: precision, system: system,
                                                              metricUnit: metricUnit)
                    let label = line.label.isEmpty ? "" : " (\(line.label))"
                    draw("\(op) \(display)\(label)", font: bodyFont)
                }
            }

            for result in job.solverResults {
                draw(result.title, font: sectionFont)
                draw(result.inputsSummary, font: bodyFont)
                for value in result.values {
                    let display = QuantityFormatting.display(value.quantity, precision: precision, system: system,
                                                              metricUnit: metricUnit)
                    draw("\(value.label): \(display)", font: bodyFont)
                }
            }

            for list in job.materialLists {
                draw(list.title, font: sectionFont)
                for line in list.lines {
                    draw("\(line.label): \(line.exactQuantity) exact, \(line.roundedQuantity) \(line.unit) to buy",
                         font: bodyFont)
                }
            }
        }
    }

    private static func operatorSymbol(_ op: TapeOperator) -> String {
        switch op {
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "x"
        case .divide: return "/"
        case .onCentre: return "o.c."
        }
    }
}
