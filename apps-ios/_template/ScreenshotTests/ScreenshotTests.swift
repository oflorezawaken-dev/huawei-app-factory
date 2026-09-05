import XCTest

/// Walks the app and attaches a screenshot of each main screen. These are the
/// only way to see the app without a device, and they double as the store
/// screenshots, so an invented UI cannot survive.
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-FactoryUITest", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testCaptureMainScreens() throws {
        // Seed one item so the screens are not all empty states.
        tab("All").tap()
        XCTAssertTrue(app.buttons["all.add"].waitForExistence(timeout: 10))
        app.buttons["all.add"].tap()

        let title = app.textFields["edit.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Monstera")
        capture(named: "03-edit")
        app.buttons["edit.save"].tap()

        // Assert the saved item is actually on screen. The row's accessibility
        // identifier is "all.row.<title>" (set in ItemListView), not the title
        // itself, since a string subscript matches identifier, not label.
        XCTAssertTrue(app.buttons["all.row.Monstera"].waitForExistence(timeout: 10),
                      "the saved item never appeared in the list")
        capture(named: "02-all")

        tab("Today").tap()
        settle()
        capture(named: "01-today")

        tab("Settings").tap()
        settle()
        capture(named: "04-settings")
    }

    private func tab(_ label: String) -> XCUIElement {
        let button = app.tabBars.buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "tab '\(label)' never appeared")
        return button
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
