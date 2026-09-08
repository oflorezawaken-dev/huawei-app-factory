import XCTest

/// Walks the app's real screens and leaves it in a populated state, so the
/// captures double as store screenshots. Launches with -FactoryUITest (which
/// suppresses the ATT prompt and the banner -- a system alert would hide the
/// whole hierarchy from XCUITest, and a "Test mode" banner is not shippable)
/// and -FactorySeedSampleData so the price book starts populated instead of
/// depending on tapping through First Run.
/// Waits are 20s throughout, not because the app is slow but because a cold CI
/// runner is: the first launch pays for SwiftData store creation, sample-data
/// seeding and Swift Charts' first render at once. 10s passed on a warm Mac and
/// intermittently failed on GitHub's macOS runner.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-FactoryUITest", "-FactorySeedSampleData", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testCaptureMainScreens() throws {
        // 1. Price Book, populated by the seeded sample data.
        XCTAssertTrue(tabButton("Price Book").waitForExistence(timeout: 20))
        tabButton("Price Book").tap()
        XCTAssertTrue(app.buttons["priceBook.row.Bananas"].waitForExistence(timeout: 20))
        capture(named: "01-priceBook")

        // 2. Item History, with its trend chart from the seeded price history.
        app.buttons["priceBook.row.Bananas"].tap()
        XCTAssertTrue(app.otherElements["history.chart"].waitForExistence(timeout: 20)
                      || app.staticTexts["history.best"].waitForExistence(timeout: 20))
        capture(named: "02-itemHistory")

        // 3. Record a price and see the Good Price? verdict -- the screen the
        // whole app is judged on.
        app.buttons["history.recordPrice"].tap()
        let priceField = app.textFields["record.price"]
        XCTAssertTrue(priceField.waitForExistence(timeout: 20))
        priceField.tap()
        priceField.typeText("0.85")
        app.buttons["record.save"].tap()
        XCTAssertTrue(app.buttons["verdict.save"].waitForExistence(timeout: 20))
        capture(named: "03-verdict")
        app.buttons["verdict.save"].tap()
        XCTAssertTrue(app.buttons["history.recordPrice"].waitForExistence(timeout: 20),
                      "saving should dismiss both sheets back to Item History")

        // 4. Shopping List, with one item added from the price book. Switching
        // tabs works regardless of how deep Price Book's own navigation stack is.
        tabButton("Shopping List").tap()
        XCTAssertTrue(app.buttons["shoppingList.addFromBook"].waitForExistence(timeout: 20))
        app.buttons["shoppingList.addFromBook"].tap()
        settle()
        let addRow = app.buttons["shoppingList.addFromBook.row.Bananas"]
        XCTAssertTrue(addRow.waitForExistence(timeout: 20))
        addRow.tap()
        // Address the row by the identifier ShoppingListView sets, not by its text:
        // a string subscript matches the accessibility IDENTIFIER, and SwiftUI only
        // sometimes derives one from a label -- which is why this passed locally and
        // on main but failed on the PR runner. The row is otherElements, not a
        // button, and ShoppingListView now marks it .accessibilityElement(.contain)
        // so the identifier attaches to something queryable at all.
        XCTAssertTrue(app.otherElements["shoppingList.row.Bananas"].waitForExistence(timeout: 20),
                      "the item added from the price book never appeared in the list")
        capture(named: "04-shoppingList")

        // 5. Stats, evidence drawn from the seeded history.
        tabButton("Stats").tap()
        settle()
        capture(named: "05-stats")
    }

    private func tabButton(_ label: String) -> XCUIElement {
        // A TabView's tab buttons do not inherit an accessibility identifier
        // from their tab content, so they must be addressed by their label
        // text through the tab bar itself.
        app.tabBars.buttons[label]
    }

    /// Wait for the screen to stop moving before capturing; a screenshot
    /// taken mid-transition produces a blurred store asset.
    private func settle() {
        _ = app.wait(for: .runningForeground, timeout: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
    }

    private func capture(named name: String) {
        settle()
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
