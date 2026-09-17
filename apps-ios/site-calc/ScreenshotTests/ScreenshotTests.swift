import XCTest

/// Walks the app's real screens and leaves it in a populated state -- these
/// screenshots double as the store assets, so an invented UI cannot survive.
///
/// The order is deliberate and is the guideline 4.2 mitigation from the
/// proposal: a reviewer who opens this listing must see a tool -- a saved job,
/// a material list, a solved roof -- before they see anything that resembles
/// "a calculator".
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-FactoryUITest", "-FactoryUITestFirstRun",
                                 "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testCaptureMainScreens() throws {
        try loadTheSampleJob()
        try buildATape()
        try solveARoof()
        try solveAStair()
        try estimateMaterial()
        try saveAJob()
        captureSettings()
        captureRemoveAds()
    }

    // MARK: - screens

    /// First Run offers a worked sample job -- a tape, a roof result and a
    /// material list. Taking it is what a new user does and what a reviewer
    /// sees, and it is the difference between a Jobs screen that shows the
    /// app working and one that shows an empty list.
    private func loadTheSampleJob() throws {
        let load = app.buttons["firstRun.loadSample"]
        XCTAssertTrue(load.waitForExistence(timeout: 15), "First Run never appeared")
        capture(named: "07-firstrun")
        load.tap()
        XCTAssertTrue(app.tabBars.buttons.element(boundBy: 0).waitForExistence(timeout: 15),
                      "the app never got past First Run")
    }

    /// 14' 3-5/8" + 9' 11-3/4". The headline sum from the spec, entered the way
    /// a user enters it: digits, a unit key, a fraction, an operator.
    private func buildATape() throws {
        tab("tab.calculator").tap()
        for key in ["keypad.digit.1", "keypad.digit.4", "keypad.unit.feet",
                    "keypad.digit.3", "keypad.unit.inches",
                    "keypad.digit.5", "keypad.fraction", "keypad.digit.8",
                    "keypad.add",
                    "keypad.digit.9", "keypad.unit.feet",
                    "keypad.digit.1", "keypad.digit.1", "keypad.unit.inches",
                    "keypad.digit.3", "keypad.fraction", "keypad.digit.4",
                    "keypad.equals"] {
            tapKey(key)
        }
        XCTAssertTrue(app.staticTexts["calculator.result"].waitForExistence(timeout: 10),
                      "the calculator never produced a result")
        assertEveryKeyIsOnScreen()
        capture(named: "04-calculator")
    }

    private func solveARoof() throws {
        tab("tab.solvers").tap()
        tapCell("solvers.roof")
        type("180", into: "roof.run")
        type("7", into: "roof.pitch")
        XCTAssertTrue(app.descendants(matching: .any)["roof.result.pitchDegrees"].waitForExistence(timeout: 10),
                      "the roof solver never produced a result")
        capture(named: "05-roof")
        back()
    }

    private func solveAStair() throws {
        tapCell("solvers.stair")
        type("111", into: "stair.totalRise")
        type("7.75", into: "stair.maxRiser")
        type("10", into: "stair.minTread")
        let solve = app.buttons["stair.solve"]
        if solve.waitForExistence(timeout: 5), solve.isEnabled { solve.tap() }
        capture(named: "06-stair")
        XCTAssertTrue(app.descendants(matching: .any)["stair.result.riserCount"].waitForExistence(timeout: 10),
                      "the stair solver never produced a result")
        back()
    }

    /// The spec's published slab: 20 ft by 30 ft at 4 in thick -> 200 cu ft,
    /// 7.41 cu yd, 334 bags. The thickness is typed as 4" on purpose: this
    /// screen's bare numbers are feet, and an explicit mark has to beat that.
    private func estimateMaterial() throws {
        tapCell("solvers.materials")
        type("20", into: "material.field.a")
        type("30", into: "material.field.b")
        type("4\"", into: "material.field.c")
        let add = app.buttons["material.addToList"]
        if add.waitForExistence(timeout: 5), add.isEnabled { add.tap() }
        let lines = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "material.line."))
        XCTAssertTrue(lines.element(boundBy: 0).waitForExistence(timeout: 10),
                      "the estimator produced no material line")
        capture(named: "03-materials")
        back()
    }

    private func saveAJob() throws {
        tab("tab.jobs").tap()
        let new = app.buttons["jobs.new"]
        XCTAssertTrue(new.waitForExistence(timeout: 10), "the jobs screen never appeared")
        new.tap()
        let name = app.textFields["jobs.newName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "the new-job sheet never appeared")
        name.tap()
        name.typeText("Kitchen extension")
        app.buttons["jobs.newSave"].tap()
        XCTAssertTrue(app.buttons["jobs.row.Kitchen extension"].waitForExistence(timeout: 10),
                      "the saved job never appeared in the list")
        let sample = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "jobs.sampleBadge."))
        XCTAssertTrue(sample.element(boundBy: 0).waitForExistence(timeout: 10),
                      "the sample job is missing, so the Jobs screenshot would be an empty list")
        capture(named: "01-jobs")

        // The sample job's own screen: a tape, a solved roof and a material
        // list in one place. This is the app being a tool, which is the
        // guideline 4.2 argument made in pictures.
        let sampleRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "jobs.row."))
        for index in 0..<sampleRow.count where sampleRow.element(boundBy: index).identifier != "jobs.row.Kitchen extension" {
            sampleRow.element(boundBy: index).tap()
            break
        }
        XCTAssertTrue(app.textFields["jobDetail.name"].waitForExistence(timeout: 10),
                      "the job detail screen never appeared")
        capture(named: "02-jobdetail")
        back()
    }

    private func captureSettings() {
        tab("tab.settings").tap()
        capture(named: "08-settings")
    }

    /// Apple asks for a screenshot of the purchase itself when an in-app
    /// purchase goes to review. Captured from the real screen rather than
    /// mocked up, for the same reason as every other asset here.
    private func captureRemoveAds() {
        let open = app.buttons["settings.ads.remove"]
        guard open.waitForExistence(timeout: 10) else {
            XCTFail("Settings has no Remove Ads row to open")
            return
        }
        open.tap()
        XCTAssertTrue(app.descendants(matching: .any)["removeAds.unlocksNothing"].waitForExistence(timeout: 10),
                      "the Remove Ads screen never appeared")
        capture(named: "09-removeads")
    }

    /// The unit tests prove KeypadLayout computes a keypad that fits. They
    /// cannot prove the view draws the size it was given: `.bordered` added its
    /// own padding around the measured frame, every key shipped ~22pt wider
    /// than measured, and half the keypad hung off the right edge -- in a store
    /// screenshot. This reads the frames the app actually rendered.
    private func assertEveryKeyIsOnScreen() {
        let screen = app.windows.element(boundBy: 0).frame
        XCTAssertFalse(screen.isEmpty, "no window to measure against")
        let keys = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "keypad."))
        XCTAssertGreaterThan(keys.count, 10, "the keypad did not render")
        for index in 0..<keys.count {
            let key = keys.element(boundBy: index)
            guard key.exists else { continue }
            let frame = key.frame
            XCTAssertTrue(screen.contains(frame),
                          "key '\(key.identifier)' at \(frame) is outside the screen \(screen)")
            XCTAssertGreaterThanOrEqual(min(frame.width, frame.height), 44,
                                        "key '\(key.identifier)' is \(frame.size), under the 44pt minimum")
        }
    }

    // MARK: - helpers

    private func tab(_ identifier: String) -> XCUIElement {
        let button = app.tabBars.buttons[identifier]
        if button.waitForExistence(timeout: 15) { return button }
        // Some iOS versions expose the tab by its label rather than the
        // identifier set on the tab content, so fall back before failing.
        let byLabel = app.tabBars.buttons.element(boundBy: tabIndex(for: identifier))
        XCTAssertTrue(byLabel.waitForExistence(timeout: 10), "tab '\(identifier)' never appeared")
        return byLabel
    }

    private func tabIndex(for identifier: String) -> Int {
        switch identifier {
        case "tab.calculator": return 0
        case "tab.solvers": return 1
        case "tab.jobs": return 2
        default: return 3
        }
    }

    private func tapKey(_ identifier: String) {
        let key = app.buttons[identifier]
        XCTAssertTrue(key.waitForExistence(timeout: 10), "keypad key '\(identifier)' never appeared")
        key.tap()
    }

    /// A row in a List is a button on some iOS versions and a cell on others.
    private func tapCell(_ identifier: String) {
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 5) { button.tap(); return }
        let cell = app.cells[identifier]
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "row '\(identifier)' never appeared")
        cell.tap()
    }

    /// Types into a field and then reads it back, exactly.
    ///
    /// Both halves are load-bearing. A decimalPad keyboard covers the fields
    /// below it, so a tap can land on the keyboard and the digits go somewhere
    /// else entirely -- which is how a stair screenshot shipped a minimum tread
    /// of "17280.00110" and a riser height computed from it. The first version
    /// of this check asked whether the field *contained* what was typed, and
    /// "17280.00110" contains "10", so it passed. Equality, not containment.
    private func type(_ text: String, into identifier: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "field '\(identifier)' never appeared")
        if !field.isHittable { dismissKeyboard() }
        XCTAssertTrue(field.isHittable, "field '\(identifier)' is covered and could not be reached")
        field.tap()
        if let existing = field.value as? String, !existing.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText(text)
        XCTAssertEqual(field.value as? String, text,
                       "typed '\(text)' into '\(identifier)'")
    }

    /// decimalPad has no return key, so the keyboard stays up and covers the
    /// results -- both for the next tap and for the screenshot.
    private func dismissKeyboard() {
        guard app.keyboards.element(boundBy: 0).exists else { return }
        let done = app.buttons["keyboard.done"]
        if done.exists, done.isHittable {
            done.tap()
        } else {
            app.navigationBars.staticTexts.element(boundBy: 0).tap()
        }
        settle()
        XCTAssertFalse(app.keyboards.element(boundBy: 0).exists,
                       "the keyboard is still covering the screen about to be captured")
    }

    private func back() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists { backButton.tap() }
        settle()
    }

    /// Wait for the screen to stop moving before capturing; a screenshot taken
    /// mid-transition is what produced blurred store assets on Android.
    private func settle() {
        _ = app.wait(for: .runningForeground, timeout: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
    }

    private func capture(named name: String) {
        dismissKeyboard()
        settle()
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
