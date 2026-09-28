import XCTest

@MainActor
final class ReleaseFlowsTests: HighscoreUITestCase {
    func testReportFormAndCancelRemainReachableInBothLandscapes() {
        launch("rank-1")
        app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.buttons["reportEntry1"].waitForExistence(timeout: 5))
        app.buttons["reportEntry1"].tap()
        for orientation in [UIDeviceOrientation.landscapeRight, .landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(app.buttons["reportSend"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["reportSend"].isHittable)
            XCTAssertTrue(app.buttons["reportCancel"].isHittable)
            XCTAssertFalse(app.keyboards.firstMatch.exists)
            XCTAssertTrue(app.buttons["Start Game"].isHittable)
        }
        app.buttons["reportCancel"].tap()
        XCTAssertTrue(app.buttons["reportEntry1"].waitForExistence(timeout: 3))
        app.buttons["openReports"].tap()
        XCTAssertTrue(app.buttons["reportClose"].waitForExistence(timeout: 3))
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["reportClose"].exists)
    }
    func testUnconfirmedReportDoesNotPreventStartingOrBecomeAnUploadQueue() {
        launch("rank-1")
        app.buttons["highscoreOpen"].tap()
        XCTAssertTrue(app.buttons["reportEntry1"].waitForExistence(timeout: 5))
        app.buttons["reportEntry1"].tap()
        app.buttons["reportSend"].tap()
        XCTAssertTrue(app.staticTexts["reportResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["reportCheckStatus"].isHittable)
        app.buttons["Start Game"].tap()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 3))
    }
}
