import XCTest

@MainActor
final class HighscoreNonqualificationUITests: HighscoreUITestCase {
    func testBelowCutoff() { assertMiss("below-cutoff", score: 0) }
    func testEqualCutoff() { assertMiss("equal-cutoff", score: 200) }
    func testCutoffChangesDuringNameEntry() {
        launch("cutoff-race", completed: true)
        let field = app.textFields["highscoreName"]; XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Løkke"); app.buttons["highscoreSubmit"].tap()
        let bottom = app.otherElements["highscoreRow100"]
        XCTAssertTrue(bottom.waitForExistence(timeout: 5)); XCTAssertTrue(bottom.isHittable)
        XCTAssertTrue(app.staticTexts["The list changed while you entered your name. Try again to reach the top 100."].exists)
        XCTAssertFalse(app.otherElements["highscoreSelectedRow"].exists)
        XCTAssertEqual(app.staticTexts["highscoreFinalScore"].label, "Final score: 300")
    }
    private func assertMiss(_ fixture: String, score: Int) {
        launch(fixture, completed: true)
        let bottom = app.otherElements["highscoreRow100"]
        XCTAssertTrue(bottom.waitForExistence(timeout: 5)); XCTAssertTrue(bottom.isHittable)
        XCTAssertFalse(app.textFields["highscoreName"].exists)
        XCTAssertEqual(app.staticTexts["highscoreFinalScore"].label, "Final score: \(score)")
        app.buttons["Play Again"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.scrollViews["highscoreList"].exists)
    }
}
