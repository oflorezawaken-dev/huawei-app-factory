import Foundation

/// Looks up a String Catalog key and, if arguments are given, formats it.
/// Used wherever a sentence needs to be built from dynamic pieces: SwiftUI's
/// `Text("key \(value)")` would otherwise mint a new, untranslated catalog
/// key out of the literal-plus-placeholder text at every call site, instead
/// of reusing one translated key.
func localized(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return args.isEmpty ? format : String(format: format, arguments: args)
}

/// A field's label with the unit a bare number typed into it means, e.g.
/// "Total rise (in)".
///
/// Not decoration. Every solver field used to take a bare number as decimal
/// feet with nothing on screen saying so, so "111" in the stair solver's total
/// rise silently meant 111 feet. The unit a field assumes has to be visible in
/// the field, in every language -- the abbreviations come from
/// QuantityFormatting, which is the same table the results use.
func fieldLabel(_ key: String, _ unit: LengthUnit) -> String {
    "\(localized(key)) (\(QuantityFormatting.unitSuffix(unit)))"
}
