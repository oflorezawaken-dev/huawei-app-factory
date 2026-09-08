import XCTest
@testable import PriceJar

/// Exhaustive coverage of F004's conversion table. Every assertion compares
/// against a Decimal computed independently in the test itself (never a
/// value copy-pasted from the production code), so a wrong constant in
/// `UnitNormalization` cannot pass by agreeing with itself.
final class UnitNormalizationTests: XCTestCase {
    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    // MARK: - Base quantity: mass

    func testGramBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .gram), 1)
    }
    func testGramBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 500, unit: .gram), 500)
    }
    func testKilogramBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .kilogram), 1000)
    }
    func testKilogramBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 2.5, unit: .kilogram), 2500)
    }
    func testPoundBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .pound), d("453.59237"))
    }
    func testPoundBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 2, unit: .pound), d("907.18474"))
    }
    func testOunceBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .ounce), d("28.349523125"))
    }
    func testOunceBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 16, unit: .ounce), d("453.5923700"))
    }

    // MARK: - Base quantity: volume

    func testMilliliterBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .milliliter), 1)
    }
    func testLiterBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .liter), 1000)
    }
    func testLiterBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1.5, unit: .liter), 1500)
    }
    func testUSGallonBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .usGallon), d("3785.411784"))
    }
    func testUSFluidOunceBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .usFluidOunce), d("29.5735295625"))
    }
    func testUSFluidOunceBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 8, unit: .usFluidOunce), d("236.5882365"))
    }
    func testImperialFluidOunceBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .imperialFluidOunce), d("28.4130625"))
    }
    func testImperialFluidOunceBaseQuantityScales() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 20, unit: .imperialFluidOunce), d("568.26125"))
    }

    // MARK: - Base quantity: count

    func testItemBaseQuantity() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 1, unit: .item), 1)
    }
    func testItemBaseQuantityPackOfN() {
        XCTAssertEqual(UnitNormalization.baseQuantity(packageSize: 12, unit: .item), 12)
    }

    // MARK: - Unit price: mass

    func testUnitPriceGrams() throws {
        let price = try UnitNormalization.unitPrice(price: 2, packageSize: 500, unit: .gram)
        XCTAssertEqual(price, d("0.0040"))
    }
    func testUnitPriceKilograms() throws {
        let price = try UnitNormalization.unitPrice(price: 5, packageSize: 2, unit: .kilogram)
        XCTAssertEqual(price, d("0.0025"))
    }
    func testUnitPricePounds() throws {
        let price = try UnitNormalization.unitPrice(price: 3, packageSize: 1, unit: .pound)
        let expected = UnitNormalization.rounded(3 / d("453.59237"), scale: 4)
        XCTAssertEqual(price, expected)
    }
    func testUnitPriceOunces() throws {
        let price = try UnitNormalization.unitPrice(price: 4, packageSize: 8, unit: .ounce)
        let expected = UnitNormalization.rounded(4 / (8 * d("28.349523125")), scale: 4)
        XCTAssertEqual(price, expected)
    }

    // MARK: - Unit price: volume

    func testUnitPriceMilliliters() throws {
        let price = try UnitNormalization.unitPrice(price: 1.5, packageSize: 750, unit: .milliliter)
        XCTAssertEqual(price, UnitNormalization.rounded(d("1.5") / 750, scale: 4))
    }
    func testUnitPriceLiters() throws {
        let price = try UnitNormalization.unitPrice(price: 1.05, packageSize: 1, unit: .liter)
        XCTAssertEqual(price, UnitNormalization.rounded(d("1.05") / 1000, scale: 4))
    }
    func testUnitPriceUSGallon() throws {
        let price = try UnitNormalization.unitPrice(price: 3, packageSize: 1, unit: .usGallon)
        XCTAssertEqual(price, UnitNormalization.rounded(3 / d("3785.411784"), scale: 4))
    }
    func testUnitPriceUSFluidOunce() throws {
        let price = try UnitNormalization.unitPrice(price: 2, packageSize: 16, unit: .usFluidOunce)
        XCTAssertEqual(price, UnitNormalization.rounded(2 / (16 * d("29.5735295625")), scale: 4))
    }
    func testUnitPriceImperialFluidOunce() throws {
        let price = try UnitNormalization.unitPrice(price: 2, packageSize: 16, unit: .imperialFluidOunce)
        XCTAssertEqual(price, UnitNormalization.rounded(2 / (16 * d("28.4130625")), scale: 4))
    }
    func testUSAndImperialFluidOunceDifferButAreBothValid() throws {
        let us = try UnitNormalization.unitPrice(price: 1, packageSize: 1, unit: .usFluidOunce)
        let imperial = try UnitNormalization.unitPrice(price: 1, packageSize: 1, unit: .imperialFluidOunce)
        XCTAssertNotEqual(us, imperial)
    }

    // MARK: - Unit price: count

    func testUnitPriceItemPackOfN() throws {
        let price = try UnitNormalization.unitPrice(price: 3.60, packageSize: 12, unit: .item)
        XCTAssertEqual(price, UnitNormalization.rounded(d("3.60") / 12, scale: 4))
    }
    func testUnitPriceSingleItem() throws {
        let price = try UnitNormalization.unitPrice(price: 1.20, packageSize: 1, unit: .item)
        XCTAssertEqual(price, d("1.2000"))
    }

    // MARK: - Errors

    func testNonPositivePackageSizeThrows() {
        XCTAssertThrowsError(try UnitNormalization.unitPrice(price: 1, packageSize: 0, unit: .gram)) { error in
            XCTAssertEqual(error as? UnitNormalizationError, .nonPositivePackageSize)
        }
    }
    func testNegativePackageSizeThrows() {
        XCTAssertThrowsError(try UnitNormalization.unitPrice(price: 1, packageSize: -5, unit: .gram))
    }

    func testMassNeverInterconvertsWithVolume() {
        XCTAssertThrowsError(try UnitNormalization.validateDimension(entryUnit: .milliliter, itemDimension: .mass)) { error in
            XCTAssertEqual(error as? UnitNormalizationError,
                            .dimensionMismatch(entryDimension: .volume, itemDimension: .mass))
        }
    }
    func testVolumeNeverInterconvertsWithMass() {
        XCTAssertThrowsError(try UnitNormalization.validateDimension(entryUnit: .kilogram, itemDimension: .volume))
    }
    func testCountNeverInterconvertsWithMass() {
        XCTAssertThrowsError(try UnitNormalization.validateDimension(entryUnit: .item, itemDimension: .mass))
    }
    func testMatchingDimensionDoesNotThrow() {
        XCTAssertNoThrow(try UnitNormalization.validateDimension(entryUnit: .gram, itemDimension: .mass))
    }

    // MARK: - Display units

    func testDisplayUnitPerKilogram() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.004"), displayUnit: .perKilogram)
        XCTAssertEqual(displayPrice, 4)
    }
    func testDisplayUnitPer100Grams() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.004"), displayUnit: .per100Grams)
        XCTAssertEqual(displayPrice, d("0.4"))
    }
    func testDisplayUnitPerPound() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.01"), displayUnit: .perPound)
        XCTAssertEqual(displayPrice, d("4.5359237"))
    }
    func testDisplayUnitPerLiter() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.002"), displayUnit: .perLiter)
        XCTAssertEqual(displayPrice, 2)
    }
    func testDisplayUnitPer100Milliliters() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.002"), displayUnit: .per100Milliliters)
        XCTAssertEqual(displayPrice, d("0.2"))
    }
    func testDisplayUnitPerFluidOunce() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("0.01"), displayUnit: .perFluidOunce)
        XCTAssertEqual(displayPrice, d("0.295735295625"))
    }
    func testDisplayUnitPerItem() {
        let displayPrice = UnitNormalization.displayUnitPrice(baseUnitPrice: d("1.5"), displayUnit: .perItem)
        XCTAssertEqual(displayPrice, d("1.5"))
    }

    func testDisplayUnitsForMassExcludeVolumeAndCount() {
        let units = DisplayUnit.displayUnits(for: .mass)
        XCTAssertEqual(Set(units), [.perKilogram, .per100Grams, .perPound])
    }
    func testDisplayUnitsForVolumeExcludeMassAndCount() {
        let units = DisplayUnit.displayUnits(for: .volume)
        XCTAssertEqual(Set(units), [.perLiter, .per100Milliliters, .perFluidOunce])
    }
    func testDisplayUnitsForCountIsPerItemOnly() {
        XCTAssertEqual(DisplayUnit.displayUnits(for: .count), [.perItem])
    }

    func testSystemDefaultDisplayUnitMetricMass() {
        XCTAssertEqual(DisplayUnit.systemDefault(for: .mass, metric: true), .perKilogram)
    }
    func testSystemDefaultDisplayUnitImperialMass() {
        XCTAssertEqual(DisplayUnit.systemDefault(for: .mass, metric: false), .perPound)
    }
    func testSystemDefaultDisplayUnitMetricVolume() {
        XCTAssertEqual(DisplayUnit.systemDefault(for: .volume, metric: true), .perLiter)
    }
    func testSystemDefaultDisplayUnitImperialVolume() {
        XCTAssertEqual(DisplayUnit.systemDefault(for: .volume, metric: false), .perFluidOunce)
    }
    func testSystemDefaultDisplayUnitCount() {
        XCTAssertEqual(DisplayUnit.systemDefault(for: .count, metric: true), .perItem)
        XCTAssertEqual(DisplayUnit.systemDefault(for: .count, metric: false), .perItem)
    }

    func testRoundedUsesPlainRounding() {
        XCTAssertEqual(UnitNormalization.rounded(d("1.23455"), scale: 4), d("1.2346"))
        XCTAssertEqual(UnitNormalization.rounded(d("1.23445"), scale: 4), d("1.2345"))
    }

    /// The module's own comment promises this file never uses Double or
    /// Float; this test reads the source back (with comments stripped, since
    /// the promise itself is written in prose that names both words) and
    /// fails the build if either appears in actual code, so the promise
    /// cannot silently rot.
    func testUnitNormalizationSourceNeverUsesFloatingPoint() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Core/UnitNormalization.swift")
        let source = try String(contentsOf: url, encoding: .utf8)
        let code = source.split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                guard let range = line.range(of: "//") else { return String(line) }
                return String(line[line.startIndex..<range.lowerBound])
            }
            .joined(separator: "\n")
        XCTAssertFalse(code.contains("Double"), "UnitNormalization.swift must never use Double")
        XCTAssertFalse(code.contains("Float"), "UnitNormalization.swift must never use Float")
    }
}
