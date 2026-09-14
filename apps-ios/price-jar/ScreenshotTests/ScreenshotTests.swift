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
        tapTab("Price Book")
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
        // Hittable, not merely existing. A view behind a presented sheet is still
        // in the accessibility tree, so waitForExistence here returned true while
        // both sheets were still up -- the assertion claimed to prove the sheets
        // had dismissed and proved nothing of the sort. The test then tapped a
        // tab that was covered, the tap was swallowed, and the failure surfaced
        // 20s later at an unrelated assertion.
        let backOnHistory = app.buttons["history.recordPrice"]
        XCTAssertTrue(backOnHistory.waitForExistence(timeout: 20),
                      "Item History never came back after saving")
        XCTAssertTrue(backOnHistory.wait(for: \.isHittable, toEqual: true, timeout: 20),
                      "saving should dismiss both sheets back to Item History")

        // 4. Shopping List, with one item added from the price book. Switching
        // tabs works regardless of how deep Price Book's own navigation stack is.
        tapTab("Shopping List")
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
        tapTab("Stats")
        settle()
        capture(named: "05-stats")

        // 6. Settings, for the in-app purchase review screenshot. Apple reviews
        // the Remove Ads product separately from the app and requires a shot of
        // the screen that offers it; App Review rejected 1.0.0 (4) partly for
        // not having one. Capturing it here means it is produced by every build
        // instead of being taken by hand, and it is NOT a store screenshot --
        // store/screenshots holds those, and this one is not copied there.
        tapTab("Settings")
        XCTAssertTrue(app.buttons["settings.ads.remove"].waitForExistence(timeout: 20),
                      "the Remove Ads purchase must be on screen for the review shot")
        capture(named: "06-settings-iap")
    }

    /// Tapping a tab the instant a sheet has dismissed is not safe: the tab
    /// exists while it is still animating back into place, and a tap sent then is
    /// swallowed. The screen never changes, and the next assertion spends its
    /// whole 20s on an app that is simply still where it was -- which is how this
    /// test failed twice on CI at `shoppingList.addFromBook`, looking like a slow
    /// screen rather than a lost tap.
    private func tapTab(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = tabButton(label)
        XCTAssertTrue(tab.waitForExistence(timeout: 20),
                      "the \(label) tab never appeared", file: file, line: line)
        XCTAssertTrue(tab.wait(for: \.isHittable, toEqual: true, timeout: 20),
                      "the \(label) tab existed but never became hittable", file: file, line: line)
        tab.tap()
    }

    private func tabButton(_ label: String) -> XCUIElement {
        // A TabView's tab buttons do not inherit an accessibility identifier
        // from their tab content, so they are addressed by their visible label.
        // Which element holds them differs by device: iPhone renders a tab bar,
        // iPad renders the tabs as plain buttons in a top bar with no tabBars
        // element at all, and their identifiers there are the SF Symbol names.
        // The label is the only thing common to both.
        let inTabBar = app.tabBars.buttons[label]
        if inTabBar.exists { return inTabBar }
        return app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
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
