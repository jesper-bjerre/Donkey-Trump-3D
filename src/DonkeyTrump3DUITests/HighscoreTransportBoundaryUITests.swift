import XCTest

@MainActor
final class HighscoreTransportBoundaryUITests: HighscoreUITestCase {
    func testLocalIntegrationNeverFollowsSaveRedirect() throws {
        guard let origin = ProcessInfo.processInfo.environment["DT3D_REDIRECT_TEST_ORIGIN"] else {
            throw XCTSkip("Start src/tests/support/highscore-http-fixture.py and set TEST_RUNNER_DT3D_REDIRECT_TEST_ORIGIN.")
        }
        app.launchArguments = ["-highscoreUITest", "-highscoreIntegration", "-highscoreLocalOrigin", origin, "-highscoreCompletedRun"]
        app.launch()
        let field = app.textFields["highscoreName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText("Redirect Guard")
        app.buttons["highscoreSubmit"].tap()
        XCTAssertTrue(app.staticTexts["highscoreError"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["highscoreError"].label, "We couldn't confirm whether your score was saved.")
        XCTAssertTrue(app.buttons["Play Again"].exists)
        XCTAssertFalse(app.otherElements["highscoreSelectedRow"].exists)
    }
}
