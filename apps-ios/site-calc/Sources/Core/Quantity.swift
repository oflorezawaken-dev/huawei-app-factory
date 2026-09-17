import Foundation

/// A tape entry can hold a length, an area, a volume, or a dimensionless
/// count (e.g. the result of dividing a length by a length, or a percentage).
/// This is the dynamic wrapper the tape needs since a single expression can
/// change dimensionality mid-flight -- multiplying two lengths on the tape
/// really does turn the running result into an area (F001).
enum Quantity: Equatable, Codable {
    case length(Length)
    case area(Area)
    case volume(Volume)
    case count(Rational)

    enum ArithmeticError: Error, Equatable { case incompatibleOperands, divisionByZero }

    private enum CodingKeys: String, CodingKey { case kind, value }
    private enum Kind: String, Codable { case length, area, volume, count }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .length: self = .length(try container.decode(Length.self, forKey: .value))
        case .area: self = .area(try container.decode(Area.self, forKey: .value))
        case .volume: self = .volume(try container.decode(Volume.self, forKey: .value))
        case .count: self = .count(try container.decode(Rational.self, forKey: .value))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .length(let v): try container.encode(Kind.length, forKey: .kind); try container.encode(v, forKey: .value)
        case .area(let v): try container.encode(Kind.area, forKey: .kind); try container.encode(v, forKey: .value)
        case .volume(let v): try container.encode(Kind.volume, forKey: .kind); try container.encode(v, forKey: .value)
        case .count(let v): try container.encode(Kind.count, forKey: .kind); try container.encode(v, forKey: .value)
        }
    }

    var isZero: Bool {
        switch self {
        case .length(let l): return l.inches.isZero
        case .area(let a): return a.squareInches.isZero
        case .volume(let v): return v.cubicInches.isZero
        case .count(let c): return c.isZero
        }
    }

    static func add(_ a: Quantity, _ b: Quantity) throws -> Quantity {
        switch (a, b) {
        case (.length(let x), .length(let y)): return .length(x + y)
        case (.area(let x), .area(let y)): return .area(x + y)
        case (.volume(let x), .volume(let y)): return .volume(x + y)
        case (.count(let x), .count(let y)): return .count(x + y)
        default: throw ArithmeticError.incompatibleOperands
        }
    }

    static func subtract(_ a: Quantity, _ b: Quantity) throws -> Quantity {
        switch (a, b) {
        case (.length(let x), .length(let y)): return .length(x - y)
        case (.area(let x), .area(let y)): return .area(x - y)
        case (.volume(let x), .volume(let y)): return .volume(x - y)
        case (.count(let x), .count(let y)): return .count(x - y)
        default: throw ArithmeticError.incompatibleOperands
        }
    }

    static func multiply(_ a: Quantity, _ b: Quantity) throws -> Quantity {
        switch (a, b) {
        case (.length(let x), .length(let y)): return .area(x * y)
        case (.area(let x), .length(let y)), (.length(let y), .area(let x)): return .volume(x * y)
        case (.length(let x), .count(let y)), (.count(let y), .length(let x)): return .length(x * y)
        case (.area(let x), .count(let y)), (.count(let y), .area(let x)): return .area(x * y)
        case (.volume(let x), .count(let y)), (.count(let y), .volume(let x)): return .volume(x * y)
        case (.count(let x), .count(let y)): return .count(x * y)
        default: throw ArithmeticError.incompatibleOperands
        }
    }

    static func divide(_ a: Quantity, _ b: Quantity) throws -> Quantity {
        guard !b.isZero else { throw ArithmeticError.divisionByZero }
        switch (a, b) {
        case (.length(let x), .length(let y)): return .count(x / y)
        case (.area(let x), .area(let y)): return .count(x / y)
        case (.volume(let x), .volume(let y)): return .count(x / y)
        case (.area(let x), .length(let y)): return .length(x / y)
        case (.volume(let x), .area(let y)): return .length(x / y)
        case (.volume(let x), .length(let y)): return .area(x / y)
        case (.length(let x), .count(let y)): return .length(x / y)
        case (.area(let x), .count(let y)): return .area(x / y)
        case (.volume(let x), .count(let y)): return .volume(x / y)
        case (.count(let x), .count(let y)): return .count(x / y)
        default: throw ArithmeticError.incompatibleOperands
        }
    }
}
