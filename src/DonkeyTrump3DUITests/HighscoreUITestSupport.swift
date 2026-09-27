import XCTest

@MainActor
class HighscoreUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    /// SceneKit keeps rendering while the keyboard animates; wait for the
    /// controls' visible frames to settle before synthesizing a tap or capture.
    func waitForNameFormLayout() {
        var previous: [CGRect] = []
        var stableSince = ProcessInfo.processInfo.systemUptime
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { [self] _, _ in
            let controls = [app.textFields["highscoreName"], app.buttons["highscoreSubmit"], app.buttons["highscoreCancel"]]
            let frames = controls.map { $0.frame }
            if frames != previous {
                previous = frames; stableSince = ProcessInfo.processInfo.systemUptime
                return false
            }
            let window = app.windows.firstMatch.frame
            let keyboard = app.keyboards.firstMatch
            return controls.allSatisfy { $0.isHittable } &&
                frames.allSatisfy { window.contains($0) && (!keyboard.exists || $0.maxY <= keyboard.frame.minY) } &&
                ProcessInfo.processInfo.systemUptime - stableSince >= 0.5
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 8), .completed)
    }

    func tapSubmit() {
        waitForNameFormLayout()
        app.buttons["highscoreSubmit"].tap()
    }

    func launch(_ fixture: String, completed: Bool = false) {
        app.launchArguments = ["-highscoreFixture", fixture, "-highscoreUITest"]
        if completed { app.launchArguments += ["-highscoreCompletedRun"] }
        app.launch()
    }
}
