import XCTest

@MainActor
final class HighscorePublicationUITests: HighscoreUITestCase {
    func testConsentCancelAndInvalidName() {
        launch("empty", completed: true)
        XCTAssertTrue(app.textFields["highscoreName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your name and score will be public. You do not need to use your real name."].exists)
        app.buttons["highscoreSubmit"].tap()
        XCTAssertTrue(app.staticTexts["highscoreNameError"].exists)
        app.buttons["highscoreCancel"].tap()
        XCTAssertTrue(app.buttons["Play Again"].exists)
        XCTAssertFalse(app.textFields["highscoreName"].exists)
    }
    func testLargeNameFormKeepsKeyboardAndNavigationUsable() {
        app.launchArguments = ["-highscoreFixture", "rank-50", "-highscoreUITest", "-highscoreCompletedRun", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let field = app.textFields["highscoreName"]; XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap(); field.typeText("Test")
        XCTAssertTrue(app.buttons["highscoreSubmit"].isHittable)
        XCTAssertTrue(app.buttons["highscoreClose"].isHittable)
        XCTAssertTrue(app.buttons["Play Again"].isHittable)
        XCTAssertTrue(app.buttons["Return to Title"].isHittable)
        app.buttons["highscoreSubmit"].tap()
        XCTAssertTrue(app.otherElements["highscoreSelectedRow"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }
    func testRank1IsVisible() { assertPublished("rank-1", rank: 1) }
    func testRank50IsCentred() { assertPublished("rank-50", rank: 50) }
    func testRank100IsVisible() { assertPublished("rank-100", rank: 100) }
    private func assertPublished(_ fixture: String, rank: Int) {
        launch(fixture, completed: true)
        let field = app.textFields["highscoreName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText("Løkke")
        app.buttons["highscoreSubmit"].tap()
        let selected = app.otherElements["highscoreSelectedRow"]
        XCTAssertTrue(selected.waitForExistence(timeout: 5))
        XCTAssertTrue(selected.isHittable)
        XCTAssertTrue(selected.label.contains("Rank \(rank)"))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        let list = app.scrollViews["highscoreList"]
        XCTAssertGreaterThanOrEqual(selected.frame.minY, list.frame.minY - 1)
        XCTAssertLessThanOrEqual(selected.frame.maxY, list.frame.maxY + 1)
        if rank == 50 { XCTAssertLessThan(abs(selected.frame.midY - list.frame.midY), 18) }
    }
}
