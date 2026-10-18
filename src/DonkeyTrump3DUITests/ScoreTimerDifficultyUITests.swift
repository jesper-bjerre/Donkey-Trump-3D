import XCTest

@MainActor
final class ScoreTimerDifficultyUITests: XCTestCase {
    func testTimerStartsAndPauseExcludesElapsedTime() {
        let app = XCUIApplication()
        app.launchArguments = ["-autostart", "-highscoreUITest", "-highscoreFixture", "unavailable"]
        app.launch()
        let timer = app.staticTexts["attemptTimer"]
        XCTAssertTrue(timer.waitForExistence(timeout: 10))
        XCTAssertTrue(timer.label.hasPrefix("Time remaining"))
        app.buttons["Pause"].tap()
        let paused = timer.label
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 3))
        // Poll a visible paused state; no test-owned clock substitutes for adapter evidence.
        XCTAssertTrue(app.buttons["Restart from Level 1"].exists)
        XCTAssertEqual(timer.label, paused)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["Resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(timer.label, paused)
        app.buttons["Restart from Level 1"].tap()
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["gameScore"].exists)
    }
    func testGameplayFixturesCannotUseCombinedSyntheticPublication() {
        for args in [["-gameplayFixture"], ["-gameplayFixture", "unknown"],
                     ["-gameplayFixture", "upper-1", "-gameplaySeed", "91"],
                     ["-gameplayFixture", "upper-1", "-gameplaySeed", "bad"],
                     ["-gameplayFixture=upper-1"]] {
            let app = XCUIApplication()
            app.launchArguments = args + ["-highscoreUITest", "-highscoreFixture", "empty",
                "-highscoreCompletedRun", "-highscoreRunScore", "2147483600"]
            app.launch()
            let start = app.buttons["Start Game"]
            let pause = app.buttons["Pause"]
            XCTAssertTrue(start.waitForExistence(timeout: 4) || pause.waitForExistence(timeout: 4))
            XCTAssertFalse(app.textFields["highscoreName"].exists)
            if pause.exists {
                pause.tap(); app.buttons["Return to Title"].tap()
            }
            app.buttons["Highscores"].tap()
            XCTAssertTrue(app.staticTexts["highscoreError"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.textFields["highscoreName"].exists)
            app.terminate()
        }
    }

    func testRetainedMaximumTimeRescueShowsZeroBonusAndExactTotal() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-gameplayFixture", "retry-max-1", "-gameplaySeed", "91"]
        app.launch()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 10))
        let evidence = app.staticTexts["gameplayFixtureEvidence"]
        XCTAssertTrue(evidence.waitForExistence(timeout: 3))
        let storedBefore = evidence.label.components(separatedBy: ";")[0]
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.74))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.32, dy: 0.74))
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 2.5)
        XCTAssertTrue(app.staticTexts["Motzfeldt rescued!"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Completion +1000 · Time +0 · Total 1000"].exists)
        XCTAssertEqual(app.staticTexts["gameScore"].label, "1000")
        XCTAssertEqual(evidence.label, storedBefore + ";best=1000")
        XCTAssertFalse(app.textFields["highscoreName"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(evidence.waitForExistence(timeout: 10))
        XCTAssertEqual(evidence.label, storedBefore + ";best=0")
    }

}
