import XCTest

@MainActor
final class HighscoreRealSubmissionUITests: HighscoreUITestCase {
    func test2600PointSubmissionThroughRealBackend() throws {
        guard let origin = ProcessInfo.processInfo.environment["DT3D_SCORE_TEST_ORIGIN"],
              let run = ProcessInfo.processInfo.environment["DT3D_SCORE_TEST_RUN"] else {
            throw XCTSkip("Requires an explicitly owned loopback backend and run ID")
        }
        app.launchArguments = ["-highscoreUITest", "-highscoreIntegration", "-highscoreLocalOrigin", origin,
                               "-highscoreCompletedRun", "-highscoreRunID", run, "-highscoreRunScore", "2600"]
        app.launch()
        let field = app.textFields["highscoreName"]
        XCTAssertTrue(field.waitForExistence(timeout: 12), app.staticTexts["highscoreError"].label)
        waitForNameFormLayout()
        field.tap(); field.typeText("UI Score Check")
        tapSubmit()
        let selected = app.otherElements["highscoreSelectedRow"]
        XCTAssertTrue(selected.waitForExistence(timeout: 12), app.staticTexts["highscoreError"].label)
        XCTAssertTrue(selected.label.contains("2600"))
        XCTAssertTrue(selected.label.contains("UI Score Check"))
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "real-backend-2600-submitted"; attachment.lifetime = .keepAlways; add(attachment)
    }
}
