import XCTest

@MainActor
final class HighscorePublicationUITests: HighscoreUITestCase {
    func testNameDialogCancelAndInvalidName() {
        launch("empty", completed: true)
        XCTAssertTrue(app.textFields["highscoreName"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["highscoreNameDialog"].exists)
        XCTAssertTrue(app.staticTexts["New highscore!"].exists)
        XCTAssertFalse(app.staticTexts["Your name and score will be public. You do not need to use your real name."].exists)
        XCTAssertTrue(app.textFields["highscoreName"].isHittable)
        XCTAssertTrue(app.buttons["highscoreSubmit"].isHittable)
        capture("name-dialog")
        tapSubmitEdge()
        XCTAssertTrue(app.staticTexts["highscoreNameError"].exists)
        waitForNameFormLayout()
        tapEdge(app.buttons["highscoreCancel"])
        XCTAssertTrue(app.buttons["Play Again"].exists)
        XCTAssertFalse(app.textFields["highscoreName"].exists)
    }
    func testLargeNameFormKeepsKeyboardAndNavigationUsable() {
        app.launchArguments = ["-highscoreFixture", "rank-50", "-highscoreUITest", "-highscoreCompletedRun", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let field = app.textFields["highscoreName"]; XCTAssertTrue(field.waitForExistence(timeout: 4))
        waitForNameFormLayout()
        tapFieldEdge(field); field.typeText("Test")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        for orientation in [UIDeviceOrientation.landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: field)
            let settled = XCTWaiter.wait(for: [visible], timeout: 5)
            if settled != .completed { capture("rotation-field-failure") }
            XCTAssertEqual(settled, .completed)
            field.tap() // Restore keyboard focus after the system rotates.
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
            XCTAssertEqual(field.value as? String, "Test")
            XCTAssertTrue(field.isHittable)
            XCTAssertTrue(app.buttons["highscoreSubmit"].isHittable)
            XCTAssertTrue(app.buttons["highscoreCancel"].isHittable)
            let close = app.buttons["highscoreClose"]
            let reachable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: close)
            XCTAssertEqual(XCTWaiter.wait(for: [reachable], timeout: 3), .completed)
            waitForNameFormLayout()
            capture("name-dialog-large-keyboard-\(orientation.rawValue)")
        }
        XCTAssertTrue(app.buttons["highscoreSubmit"].isHittable)
        XCTAssertTrue(app.buttons["highscoreClose"].isHittable)
        XCTAssertTrue(app.buttons["Play Again"].isHittable)
        XCTAssertTrue(app.buttons["Return to Title"].isHittable)
        tapSubmitEdge()
        XCTAssertTrue(app.otherElements["highscoreSelectedRow"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }
    func testLargeNameFormCancelAndCloseEdges() {
        for identifier in ["highscoreCancel", "highscoreClose"] {
            app.launchArguments = ["-highscoreFixture", "rank-50", "-highscoreUITest", "-highscoreCompletedRun", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            let field = app.textFields["highscoreName"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            waitForNameFormLayout()
            tapFieldEdge(field)
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
            waitForNameFormLayout()
            tapEdge(app.buttons[identifier])
            XCTAssertTrue(app.buttons["Play Again"].waitForExistence(timeout: 4))
            XCTAssertFalse(field.exists)
            app.terminate()
        }
    }
    private func tapEdge(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.15)).tap()
    }
    private func tapFieldEdge(_ field: XCUIElement) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
    }
    private func tapSubmitEdge() {
        waitForNameFormLayout()
        tapEdge(app.buttons["highscoreSubmit"])
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testRank1IsVisible() { assertPublished("rank-1", rank: 1) }
    func testRank50IsCentred() { assertPublished("rank-50", rank: 50) }
    func testRank100IsVisible() { assertPublished("rank-100", rank: 100) }
    private func assertPublished(_ fixture: String, rank: Int) {
        launch(fixture, completed: true)
        let field = app.textFields["highscoreName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        waitForNameFormLayout()
        tapFieldEdge(field); field.typeText("Løkke")
        tapSubmitEdge()
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
