import XCTest

@MainActor
final class HighscoreFailureUITests: HighscoreUITestCase {
    private func evidence() -> [String:Int] {
        let item = app.staticTexts["highscoreTestEvidence"]
        XCTAssertTrue(item.waitForExistence(timeout: 3))
        return Dictionary(uniqueKeysWithValues: item.label.split(separator: ";").compactMap { part in
            let bits = part.split(separator: "="); guard bits.count == 2, let value = Int(bits[1]) else { return nil }
            return (String(bits[0]), value)
        })
    }
    func testOfflineQualificationReconnectAndRelaunchNeverPost() {
        launch("offline-first", completed: true)
        XCTAssertTrue(app.staticTexts["highscoreError"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["highscoreError"].label.contains("personal best"))
        let before = evidence(); XCTAssertGreaterThanOrEqual(before["best"] ?? 0, 1200)
        app.buttons["highscoreRefresh"].tap()
        XCTAssertTrue(app.staticTexts["No scores yet"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.textFields["highscoreName"].exists)
        XCTAssertEqual(evidence()["posts"], before["posts"])
        launch("empty")
        XCTAssertGreaterThanOrEqual(evidence()["best"] ?? 0, 1200)
        XCTAssertEqual(evidence()["posts"], before["posts"])
        app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.staticTexts["No scores yet"].waitForExistence(timeout: 4))
        XCTAssertEqual(evidence()["posts"], before["posts"])
    }
    func testLostAcknowledgementIsUnconfirmedAndNoDeferredPost() {
        launch("save-ack-lost", completed: true)
        let field = app.textFields["highscoreName"]; XCTAssertTrue(field.waitForExistence(timeout: 4))
        let before = evidence(); field.tap(); field.typeText("Test"); tapSubmit()
        XCTAssertTrue(app.staticTexts["highscoreError"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.staticTexts["highscoreError"].label, "We couldn't confirm whether your score was saved.")
        XCTAssertEqual(evidence()["posts"], (before["posts"] ?? 0) + 1)
        app.buttons["highscoreRefresh"].tap()
        XCTAssertTrue(app.scrollViews["highscoreList"].waitForExistence(timeout: 4))
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["Play Again"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.textFields["highscoreName"].exists)
        launch("empty")
        XCTAssertEqual(evidence()["posts"], (before["posts"] ?? 0) + 1)
    }
    func testBackgroundAbandonsPendingQualification() {
        launch("hang", completed: true)
        let before = evidence()
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["Play Again"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["highscoreClose"].exists)
        XCTAssertEqual(evidence()["posts"], before["posts"])
    }
}
