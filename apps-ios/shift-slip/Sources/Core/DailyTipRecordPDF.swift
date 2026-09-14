import Foundation
import PDFKit
import UIKit

/// Renders the Daily Tip Record (F006/F009) as a printable PDF, laid out in
/// Publication 531's fields with the monthly total and the disclaimer footer.
/// A tax preparer or an employer is the audience, so this stays plain and
/// tabular rather than decorative.
enum DailyTipRecordPDF {
    static func render(
        lines: [DailyTipRecordLine],
        rangeTitle: String,
        employeeName: String,
        currencyCode: String,
        footerText: String
    ) -> Data {
        let pageWidth: CGFloat = 612 // US Letter, 72pt/inch
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let titleFont = UIFont.boldSystemFont(ofSize: 16)
        let headerFont = UIFont.boldSystemFont(ofSize: 9)
        let bodyFont = UIFont.systemFont(ofSize: 9)
        let footnoteFont = UIFont.italicSystemFont(ofSize: 8)

        let columns: [(String, CGFloat)] = [
            ("Date", 55), ("Employer", 85), ("Cash", 55), ("Charge", 55),
            ("Noncash", 55), ("Paid out", 55), ("Svc. charges", 65),
        ]
        let tableWidth = columns.reduce(0) { $0 + $1.1 }

        return renderer.pdfData { context in
            var y: CGFloat = margin
            func newPageIfNeeded(_ needed: CGFloat) {
                if y + needed > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
            }

            context.beginPage()
            "Daily Tip Record".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: titleFont])
            y += 22
            rangeTitle.draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: bodyFont])
            y += 14
            if !employeeName.isEmpty {
                "Employee: \(employeeName)".draw(at: CGPoint(x: margin, y: y), withAttributes: [.font: bodyFont])
                y += 14
            }
            y += 6

            func drawRow(_ values: [String], font: UIFont, y: CGFloat) {
                var x = margin
                for (index, (_, width)) in columns.enumerated() {
                    let text = index < values.count ? values[index] : ""
                    text.draw(in: CGRect(x: x, y: y, width: width - 4, height: 14),
                              withAttributes: [.font: font])
                    x += width
                }
            }

            newPageIfNeeded(16)
            drawRow(columns.map(\.0), font: headerFont, y: y)
            y += 12
            context.cgContext.move(to: CGPoint(x: margin, y: y))
            context.cgContext.addLine(to: CGPoint(x: margin + tableWidth, y: y))
            context.cgContext.strokePath()
            y += 4

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            for line in lines {
                newPageIfNeeded(16)
                drawRow([
                    dateFormatter.string(from: line.date) + (line.isSample ? " (sample)" : ""),
                    line.employerName.isEmpty ? line.businessName : line.employerName,
                    CurrencyFormatting.string(line.cashTips, currencyCode: currencyCode),
                    CurrencyFormatting.string(line.chargeTips, currencyCode: currencyCode),
                    CurrencyFormatting.string(line.noncashTips, currencyCode: currencyCode),
                    CurrencyFormatting.string(line.tipsPaidOut, currencyCode: currencyCode),
                    CurrencyFormatting.string(line.serviceCharges, currencyCode: currencyCode),
                ], font: bodyFont, y: y)
                y += 14
            }

            y += 6
            newPageIfNeeded(20)
            let total = DailyTipRecordEngine.monthTotal(lines)
            let totalCashTips = lines.reduce(Decimal(0)) { $0 + $1.cashTips }
            let totalChargeTips = lines.reduce(Decimal(0)) { $0 + $1.chargeTips }
            let totalPaidOut = lines.reduce(Decimal(0)) { $0 + $1.tipsPaidOut }
            let totalLine = "Total: cash tips \(CurrencyFormatting.string(totalCashTips, currencyCode: currencyCode)), "
                + "charge tips \(CurrencyFormatting.string(totalChargeTips, currencyCode: currencyCode)), "
                + "paid out \(CurrencyFormatting.string(totalPaidOut, currencyCode: currencyCode)), "
                + "service charges \(CurrencyFormatting.string(total.serviceCharges, currencyCode: currencyCode))"
            totalLine.draw(in: CGRect(x: margin, y: y, width: tableWidth, height: 28),
                            withAttributes: [.font: headerFont])
            y += 28

            newPageIfNeeded(24)
            footerText.draw(in: CGRect(x: margin, y: y, width: tableWidth, height: 40),
                             withAttributes: [.font: footnoteFont])
        }
    }
}
