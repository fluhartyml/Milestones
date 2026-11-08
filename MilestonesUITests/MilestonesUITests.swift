//
//  MilestonesUITests.swift
//  MilestonesUITests
//
//  The shakedown robot. REM: his rule 2026-11-06: after each edit an Xcode robot shakes the app
//  down — the new design works, assistive features aren't broken, and the app can be driven with
//  no eyes and no trackpad (accessibility identifiers, not screen positions).
//
//  REM: run with Location reset first, so the app is truly on its first launch:
//    xcrun simctl privacy <sim> reset location com.inkwell.Milestones
//  Tests run in name order: test1 sees the first-launch ask, test2 sees what a "no" leaves behind.
//

import XCTest

final class MilestonesUITests: XCTestCase {

    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    /// Line 001.12: Apple's Location pop-up appears at first launch, before anything is tapped.
    @MainActor
    func test1_FirstLaunchAsksForLocation() throws {
        let app = XCUIApplication()
        app.launch()

        let dontAllow = springboard.buttons["Don’t Allow"]
        XCTAssertTrue(dontAllow.waitForExistence(timeout: 10),
                      "Apple's Location question did not appear at first launch")
        attachScreenshot("first launch — Location question")
        // The "by accident" case from his word: tap Don't Allow.
        if dontAllow.exists { dontAllow.tap() }
    }

    /// Line 001.12: after a no, Settings says Location is off and Access Location opens the Settings app.
    @MainActor
    func test2_SettingsAccessLocationAfterNo() throws {
        let app = XCUIApplication()
        app.launch()
        dismissAnyAppleAlert()
        skipNameAsk(app)

        // REM: iOS 27's tab bar doesn't report as a TabBar element (seen 11-07), so find the tab by name.
        let settingsTab = app.buttons["Settings"].firstMatch
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "No Settings tab")
        settingsTab.tap()

        let status = app.staticTexts["locationStatus"].firstMatch
        let statusLabel = app.descendants(matching: .any)["locationStatus"]
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5), "No Location status on Settings")
        let words = status.exists ? status.label : statusLabel.label
        XCTAssertTrue(words.contains("Location is off"), "Status after a no reads: \(words)")

        let button = app.buttons["accessLocation"]
        XCTAssertTrue(button.exists, "No Access Location button")
        XCTAssertEqual(button.label, "Access Location")
        attachScreenshot("Settings after a no")

        // Assistive check on the new screen.
        // REM: 2026-11-07 Apple's .textClipped / .dynamicType checks flag any custom text size (the 18 pt
        // rule needs one) even though the text grows and wraps. Same call as Rep Crew's robot: those two
        // are guarded by test3_TextGrowsWithTextSize, which measures it, instead.
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped])) { issue in
            print("AUDIT [Settings] \(issue.auditType) — \(issue.compactDescription) — \(issue.element?.debugDescription.prefix(120) ?? "")")
            return false
        }

        button.tap()
        let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(settingsApp.wait(for: .runningForeground, timeout: 10),
                      "Access Location did not open the Settings app")
        attachScreenshot("Settings app opened")
    }

    /// REM: his 18 pt rule — "the user's text-size setting wins". Measures it instead of trusting the audit:
    /// the Settings heading at the default size and at the largest accessibility size must at least double.
    @MainActor
    func test3_TextGrowsWithTextSize() throws {
        func headingHeight(_ size: String?) -> CGFloat {
            let app = XCUIApplication()
            if let size { app.launchArguments += ["-UIPreferredContentSizeCategoryName", size] }
            app.launch()
            dismissAnyAppleAlert()
            skipNameAsk(app)
            let settingsTab = app.buttons["Settings"].firstMatch
            XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "No Settings tab")
            settingsTab.tap()
            let heading = app.staticTexts["Location"].firstMatch
            XCTAssertTrue(heading.waitForExistence(timeout: 5), "No Location heading on Settings")
            let height = heading.frame.height
            print("TEXTSIZE \(size ?? "default"): heading height \(height)")
            app.terminate()
            return height
        }
        let normal = headingHeight(nil)
        let largest = headingHeight("UICTContentSizeCategoryAccessibilityXXXL")
        XCTAssertGreaterThanOrEqual(largest, normal * 2, "Text didn't grow with the text-size setting")
    }

    /// Line 002.1: first launch asks "What should we call you?"; the journal greets you; Settings can change it.
    @MainActor
    func test4_FirstLaunchAsksYourName() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestFreshStart"]
        app.launch()
        dismissAnyAppleAlert()

        let field = app.textFields["nameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "No name question at first launch")
        XCTAssertTrue(app.staticTexts["What should we call you?"].exists, "Name question has no heading")
        XCTAssertFalse(app.buttons["nameContinue"].isEnabled, "Continue should wait for a name")
        field.tap()
        field.typeText("Robot")
        XCTAssertTrue(app.buttons["nameContinue"].isEnabled, "Continue stayed off after typing")
        attachScreenshot("name question, typed")
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped])) { issue in
            print("AUDIT [Name] \(issue.auditType) — \(issue.compactDescription) — \(issue.element?.debugDescription.prefix(120) ?? "")")
            return false
        }
        app.buttons["nameContinue"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "Name question didn't close")

        let journalTab = app.buttons["Journal"].firstMatch
        XCTAssertTrue(journalTab.waitForExistence(timeout: 5), "No Journal tab")
        journalTab.tap()
        let greeting = app.staticTexts["greeting"]
        XCTAssertTrue(greeting.waitForExistence(timeout: 5), "No greeting on the journal")
        XCTAssertEqual(greeting.label, "Hello, Robot")
        attachScreenshot("journal greeting")

        app.buttons["Settings"].firstMatch.tap()
        let settingsName = app.textFields["settingsName"]
        var swipes = 0
        while !settingsName.exists && swipes < 6 { app.swipeUp(); swipes += 1 }
        XCTAssertTrue(settingsName.exists, "No name field in Settings")
        XCTAssertEqual(settingsName.value as? String, "Robot", "Settings doesn't show the saved name")

        // A second launch must not ask again.
        app.terminate()
        let again = XCUIApplication()
        again.launch()
        XCTAssertFalse(again.textFields["nameField"].waitForExistence(timeout: 3), "Name question came back on the second launch")
    }

    /// Line 032: Settings → Daily Reminder. Turning it on asks Apple's question; after Allow, the time picker shows.
    @MainActor
    func test5_DailyReminderInSettings() throws {
        let app = XCUIApplication()
        app.launch()
        dismissAnyAppleAlert()
        skipNameAsk(app)
        app.buttons["Settings"].firstMatch.tap()
        let toggle = app.switches["reminderToggle"].firstMatch
        var swipes = 0
        while !(toggle.exists && toggle.isHittable) && swipes < 8 { app.swipeUp(); swipes += 1 }
        XCTAssertTrue(toggle.exists, "No Daily Reminder switch in Settings")
        // A switch's tap lands on its label in a Form row; tap the switch itself at its right edge.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
        let time = app.datePickers["reminderTime"].firstMatch
        XCTAssertTrue(time.waitForExistence(timeout: 5), "No time picker after turning the reminder on")
        XCTAssertEqual(toggle.value as? String, "1", "The reminder switch didn't stay on")
        attachScreenshot("Daily Reminder on")
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting([.dynamicType, .textClipped])) { issue in
            print("AUDIT [Reminder] \(issue.auditType) — \(issue.compactDescription) — \(issue.element?.debugDescription.prefix(120) ?? "")")
            return false
        }
    }

    // MARK: - Helpers

    /// Earlier tests aren't about the name: tap Not Now if the question is up.
    @MainActor
    private func skipNameAsk(_ app: XCUIApplication) {
        let skip = app.buttons["nameSkip"]
        if skip.waitForExistence(timeout: 3) { skip.tap() }
    }

    @MainActor
    private func dismissAnyAppleAlert() {
        let dontAllow = springboard.buttons["Don’t Allow"]
        if dontAllow.waitForExistence(timeout: 3) { dontAllow.tap() }
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
