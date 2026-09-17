import Foundation

/// RFC 4180 CSV export of a job (F009): UTF-8 with a BOM, ISO 8601 dates, a
/// period decimal separator regardless of device locale, one row per tape
/// line and per material line, each carrying the exact decimal value in
/// inches and millimetres alongside the formatted display value. No money
/// column exists anywhere, because no money value exists to put in one.
enum CSVExport {
    static let header = ["section", "label", "operator", "exact_inches", "exact_mm",
                          "display", "unit", "is_sample", "job_name", "date"]

    static func generate(job: SiteJob, precision: FractionPrecision, system: MeasurementSystem,
                          metricUnit: LengthUnit) -> String {
        let iso = ISO8601DateFormatter()
        let dateString = iso.string(from: job.updatedAt)
        let sampleFlag = job.isSample ? "true" : "false"

        var rows: [[String]] = [header]

        for line in job.tapeLines {
            let shown = line.runningResult ?? line.operand
            rows.append([
                "tape", line.label, line.operatorApplied?.rawValue ?? "",
                QuantityFormatting.exactInches(line.operand), QuantityFormatting.exactMillimeters(line.operand),
                QuantityFormatting.display(shown, precision: precision, system: system, metricUnit: metricUnit),
                QuantityFormatting.unitLabel(line.operand), sampleFlag, job.name, dateString,
            ])
        }

        for result in job.solverResults {
            for value in result.values {
                rows.append([
                    "solver:\(result.kind.rawValue)", "\(result.title) - \(value.label)", "",
                    QuantityFormatting.exactInches(value.quantity), QuantityFormatting.exactMillimeters(value.quantity),
                    QuantityFormatting.display(value.quantity, precision: precision, system: system,
                                                metricUnit: metricUnit),
                    QuantityFormatting.unitLabel(value.quantity), sampleFlag, job.name, dateString,
                ])
            }
        }

        for list in job.materialLists {
            for line in list.lines {
                rows.append([
                    "material:\(list.title)", line.label, "", "", "",
                    "\(line.exactQuantity) / \(line.roundedQuantity)", line.unit, sampleFlag, job.name, dateString,
                ])
            }
        }

        let body = rows.map { row in row.map(field).joined(separator: ",") }.joined(separator: "\r\n")
        return "\u{FEFF}" + body + "\r\n"
    }

    /// RFC 4180 field quoting: a field containing a comma, a quote or a
    /// newline is wrapped in quotes, with internal quotes doubled.
    private static func field(_ raw: String) -> String {
        guard raw.contains(",") || raw.contains("\"") || raw.contains("\n") || raw.contains("\r") else { return raw }
        return "\"" + raw.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
