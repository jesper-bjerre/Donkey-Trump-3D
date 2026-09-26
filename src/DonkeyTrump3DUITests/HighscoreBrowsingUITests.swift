import XCTest

@MainActor
final class HighscoreBrowsingUITests: HighscoreUITestCase {
    func testTitleListAndEmptyReadOnlyRefresh() {
        for fixture in ["rank-1", "empty"] {
            launch(fixture); app.buttons["highscoreOpen"].tap()
            if fixture == "empty" { XCTAssertTrue(app.staticTexts["No scores yet"].waitForExistence(timeout: 4)) }
            else {
                let row = app.otherElements["highscoreRow1"]
                XCTAssertTrue(row.waitForExistence(timeout: 4)); XCTAssertTrue(row.isHittable)
                XCTAssertEqual(row.label, "Rank 1, Duplicate, 20000 points")
            }
            XCTAssertFalse(app.textFields["highscoreName"].exists)
            app.buttons["highscoreRefresh"].tap()
            XCTAssertTrue(app.buttons["highscoreClose"].isHittable)
            app.buttons["highscoreClose"].tap()
            XCTAssertTrue(app.buttons["highscoreOpen"].waitForExistence(timeout: 2))
        }
    }
    func testStartDuringHungFetchAndNoLateReopening() {
        launch("hang"); app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["highscoreLoading"].exists)
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["highscoreClose"].exists)
    }
    func testStaleErrorAndLargeLandscapeNavigation() {
        app.launchArguments = ["-highscoreFixture", "refresh-fails", "-highscoreUITest", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.buttons["highscoreRefresh"].waitForExistence(timeout: 4))
        app.buttons["highscoreRefresh"].tap()
        XCTAssertTrue(app.staticTexts["highscoreStale"].waitForExistence(timeout: 4))
        for orientation in [UIDeviceOrientation.landscapeRight, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            let close = app.buttons["highscoreClose"]
            let reachable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: close)
            XCTAssertEqual(XCTWaiter.wait(for: [reachable], timeout: 2), .completed)
            XCTAssertTrue(app.buttons["Start Game"].isHittable)
        }
    }
}
