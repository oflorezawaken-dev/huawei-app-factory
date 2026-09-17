import Foundation

/// Right-angle and roof geometry (F004). Pure geometry, no lookup table and no
/// limit of its own: given any two of rise, run and diagonal, or a pitch plus
/// one length, it returns the rest, the common rafter length, the pitch in
/// both rise-per-twelve and degrees, and an equal-pitch hip or valley length.
///
/// Square root and arctangent are the only floating-point operations in this
/// module (F001's solver-boundary exception); their Double results are
/// converted straight back into the exact dimensional type at a resolution of
/// 1/1,000,000 inch -- far finer than the 1/64 in display ever shows -- so
/// display rounding, not this conversion, is what the user sees.
enum RoofSolver {
    enum InputError: Error, Equatable { case insufficientInputs }

    private static let chainingResolution = 1_000_000

    struct Result: Equatable {
        let rise: Length
        let run: Length
        let commonRafter: Length
        /// Rise per 12 inches of run, e.g. 7.0 for a "7-in-12" pitch.
        let pitchPer12: Double
        let pitchDegrees: Double
        let hipOrValley: Length
    }

    /// Provide exactly two of rise/run/diagonal, or a pitch (rise per 12
    /// inches of run) plus exactly one of rise/run/diagonal.
    static func solve(rise: Length?, run: Length?, diagonal: Length?, pitchPer12: Rational?) throws -> Result {
        var rise = rise, run = run

        if let pitch = pitchPer12 {
            let ratio = boundaryValue(of: pitch) / 12.0 // rise / run
            if run == nil, let r = rise {
                run = Length(inches: rationalApproximating(boundaryValue(of: r.inches) / ratio,
                                                            denominator: chainingResolution))
            } else if rise == nil, let r = run {
                rise = Length(inches: rationalApproximating(boundaryValue(of: r.inches) * ratio,
                                                             denominator: chainingResolution))
            } else if rise == nil, run == nil, let d = diagonal {
                let dv = boundaryValue(of: d.inches)
                let runValue = dv / (1 + ratio * ratio).squareRoot()
                rise = Length(inches: rationalApproximating(runValue * ratio, denominator: chainingResolution))
                run = Length(inches: rationalApproximating(runValue, denominator: chainingResolution))
            }
        }

        if rise == nil, let r = run, let d = diagonal {
            let value = boundaryValue(of: d.inches) * boundaryValue(of: d.inches) - boundaryValue(of: r.inches) * boundaryValue(of: r.inches)
            rise = Length(inches: rationalApproximating(max(value, 0).squareRoot(), denominator: chainingResolution))
        }
        if run == nil, let r = rise, let d = diagonal {
            let value = boundaryValue(of: d.inches) * boundaryValue(of: d.inches) - boundaryValue(of: r.inches) * boundaryValue(of: r.inches)
            run = Length(inches: rationalApproximating(max(value, 0).squareRoot(), denominator: chainingResolution))
        }

        guard let finalRise = rise, let finalRun = run else { throw InputError.insufficientInputs }

        let riseValue = boundaryValue(of: finalRise.inches)
        let runValue = boundaryValue(of: finalRun.inches)
        let commonRafterValue = (riseValue * riseValue + runValue * runValue).squareRoot()
        let commonRafter = diagonal ?? Length(inches: rationalApproximating(commonRafterValue,
                                                                              denominator: chainingResolution))
        let pitchDegrees = atan2(riseValue, runValue) * 180 / .pi
        let pitchPer12Value = runValue == 0 ? 0 : (riseValue / runValue) * 12
        let hipValue = (2 * runValue * runValue + riseValue * riseValue).squareRoot()
        let hip = Length(inches: rationalApproximating(hipValue, denominator: chainingResolution))

        return Result(rise: finalRise, run: finalRun, commonRafter: commonRafter,
                       pitchPer12: pitchPer12Value, pitchDegrees: pitchDegrees, hipOrValley: hip)
    }
}
