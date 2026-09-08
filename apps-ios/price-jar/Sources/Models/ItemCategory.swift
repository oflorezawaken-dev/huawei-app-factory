import Foundation

/// The category filter chips on the Price Book. Stored as a raw string on
/// `Item` so SwiftData never needs to migrate an enum's storage format.
enum ItemCategory: String, CaseIterable, Identifiable, Sendable {
    case produce
    case dairy
    case meatAndFish
    case bakery
    case pantry
    case frozen
    case beverages
    case household
    case personalCare
    case other

    var id: String { rawValue }

    /// Localizable.xcstrings key for this category's display name.
    var localizationKey: String { "category.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .produce: return "leaf"
        case .dairy: return "drop"
        case .meatAndFish: return "fish"
        case .bakery: return "birthday.cake"
        case .pantry: return "cabinet"
        case .frozen: return "snowflake"
        case .beverages: return "cup.and.saucer"
        case .household: return "house"
        case .personalCare: return "heart"
        case .other: return "shippingbox"
        }
    }
}
