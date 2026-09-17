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
