import XCTest

@MainActor
final class HighscoreBrowsingUITests: HighscoreUITestCase {
    func testStartupProgressDisappearsWhenSceneIsReady() {
        app.launchArguments = ["-highscoreFixture", "hang", "-highscoreUITest", "-startupProgressTest"]
        app.launch()
        let progress = app.progressIndicators["startupProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Start Game"].isHittable)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "startup-progress"; capture.lifetime = .keepAlways; add(capture)
        XCTAssertTrue(progress.waitForNonExistence(timeout: 12))
        XCTAssertTrue(app.buttons["Start Game"].isHittable)
        app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["highscoreLoading"].exists)
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 3))
        XCTAssertFalse(progress.exists)
    }
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
    func testLaunchCanStartWithoutOpeningUnavailableHighscores() {
        launch("unavailable")
        XCTAssertTrue(app.buttons["Start Game"].isHittable)
        XCTAssertFalse(app.descendants(matching: .any)["highscoreLoading"].exists)
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 3))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 3))
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
