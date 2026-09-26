import XCTest

@MainActor
class HighscoreUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func launch(_ fixture: String, completed: Bool = false) {
        app.launchArguments = ["-highscoreFixture", fixture, "-highscoreUITest"]
        if completed { app.launchArguments += ["-highscoreCompletedRun"] }
        app.launch()
    }
}
