import XCTest

/// Walks the app's real screens and leaves it in a populated state -- these
/// screenshots double as the store assets, so an invented UI cannot survive.
/// Launches with -FactorySeedSampleData so the run is deterministic and does
/// not depend on tapping through First Run.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-FactoryUITest", "-FactorySeedSampleData", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testCaptureMainScreens() throws {
        // 1. Dashboard, populated with sample data.
        XCTAssertTrue(app.buttons["dashboard.logshift"].waitForExistence(timeout: 15))
        capture(named: "01-dashboard")

        // 2. Log Shift: fill the core loop's fields.
        app.buttons["dashboard.logshift"].tap()
        let cashTips = app.textFields["logshift.cashtips"]
        XCTAssertTrue(cashTips.waitForExistence(timeout: 10))
        cashTips.tap()
        cashTips.typeText("42")
        let chargeTips = app.textFields["logshift.chargetips"]
        chargeTips.tap()
        chargeTips.typeText("118")
        app.navigationBars.firstMatch.tap() // dismiss the keyboard before capturing
        capture(named: "02-logshift")

        let saveButton = app.buttons["logshift.save"]
        XCTAssertTrue(saveButton.waitForHittability(timeout: 5))
        saveButton.tap()

        // 3. Shift Summary appears after the save completes.
        let summaryValue = app.staticTexts["summary.effectivehourly.value"]
        XCTAssertTrue(summaryValue.waitForExistence(timeout: 10))
        capture(named: "03-summary")
        let doneButton = app.buttons["summary.done"]
        XCTAssertTrue(doneButton.waitForHittability(timeout: 5))
        doneButton.tap()

        // 4. Shift History, grouped and populated.
        tab("History").tap()
        XCTAssertTrue(app.otherElements["history.list"].waitForExistence(timeout: 10)
                      || app.collectionViews["history.list"].waitForExistence(timeout: 5)
                      || app.tables["history.list"].waitForExistence(timeout: 5))
        settle()
        capture(named: "04-history")

        // 5. Reports, with real charts from the sample data.
        tab("Reports").tap()
        settle()
        capture(named: "05-reports")
    }

    private func tab(_ label: String) -> XCUIElement {
        // A TabView's tab buttons do not inherit an accessibility identifier
        // from the tab content, so they are addressed by their visible label
        // instead. Falls back to a plain button match for the (here unused,
        // but kept for consistency with the factory template) iPad case,
        // where the same tabs render without a tab bar at all.
        let tabBarButton = app.tabBars.buttons[label]
        if tabBarButton.waitForExistence(timeout: 5) { return tabBarButton }
        let plainButton = app.buttons[label]
        XCTAssertTrue(plainButton.waitForExistence(timeout: 10), "tab '\(label)' never appeared")
        return plainButton
    }

    /// Wait for the screen to stop moving before capturing; a screenshot taken
    /// mid-transition is what produced blurred store assets on Android.
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

extension XCUIElement {
    /// Waits for hittability, not just existence: a view behind a presented
    /// sheet is still in the accessibility tree, so `waitForExistence` alone
    /// can return true for a control the test cannot actually tap yet.
    func waitForHittability(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
