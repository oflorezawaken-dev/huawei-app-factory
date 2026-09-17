import Foundation

/// Builds the one worked sample job offered on first run (F011): a small
/// deck with a tape, a roof result and a material list, so the app is a
/// populated tool in ten seconds rather than an empty keypad -- which is also
/// what an App Store reviewer sees first.
enum SampleJobFactory {
    static func makeSampleJob() -> SiteJob {
        let firstLine = TapeLine(operatorApplied: nil, operand: .length(Length(14, .feet) + Length(3, .inches)
            + Length(Rational(5, 8), .inches)), label: "sample.tape.label.joist".localized)
        var secondLine = TapeLine(operatorApplied: .add,
                                   operand: .length(Length(9, .feet) + Length(11, .inches)
                                       + Length(Rational(3, 4), .inches)))
        secondLine.label = "sample.tape.label.beam".localized
        let lines = TapeEngine.recompute([firstLine, secondLine])

        let roof = try? RoofSolver.solve(rise: nil, run: Length(15, .feet), diagonal: nil,
                                          pitchPer12: Rational(7))
        var solverResults: [SavedSolverResult] = []
        if let roof {
            solverResults.append(SavedSolverResult(
                kind: .roof, title: "sample.solver.roofTitle".localized,
                inputsSummary: "sample.solver.roofSummary".localized,
                values: [
                    LabeledQuantity(label: "roof.rise".localized, quantity: .length(roof.rise)),
                    LabeledQuantity(label: "roof.commonRafter".localized, quantity: .length(roof.commonRafter)),
                ]))
        }

        let deckArea = AreaVolumeSolver.rectangleArea(width: Length(14, .feet), height: Length(10, .feet))
        let boards = MaterialEstimator.deckingBoards(coverageWidth: Length(10, .feet),
                                                       boardWidth: Length(Rational(11, 2), .inches),
                                                       gap: Length(Rational(1, 4), .inches))
        let concreteBags = MaterialEstimator.concreteBags(
            volume: AreaVolumeSolver.circularFootingVolume(radius: Length(6, .inches), depth: Length(12, .inches)),
            bagYieldCubicFeet: Rational(3, 5))
        _ = deckArea
        let materialList = SavedMaterialList(title: "sample.material.title".localized, lines: [
            MaterialLine(label: "material.decking".localized,
                         exactQuantity: LengthFormatting.decimalString(boards.exact, decimalPlaces: 2),
                         roundedQuantity: "\(boards.roundedUp)", unit: "material.unit.boards".localized),
            MaterialLine(label: "material.concrete".localized,
                         exactQuantity: LengthFormatting.decimalString(concreteBags.exact, decimalPlaces: 2),
                         roundedQuantity: "\(concreteBags.roundedUp)", unit: "material.unit.bags".localized),
        ])

        return SiteJob(name: "sample.jobName".localized, isSample: true, tapeLines: lines,
                       solverResults: solverResults, materialLists: [materialList])
    }
}
