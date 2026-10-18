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
    func testFivePointSubmissionsThroughOwnedLoopback() throws {
        guard let text = ProcessInfo.processInfo.environment["DT3D_SCORE_TEST_ORIGIN"],
              let url = URL(string: text), url.scheme == "http", ["127.0.0.1", "localhost", "::1"].contains(url.host ?? ""),
              url.user == nil, url.password == nil, url.path.isEmpty, url.query == nil else {
            throw XCTSkip("Requires explicit owned loopback integration")
        }
        for score in [10, 1005] {
            let id = UUID()
            app.launchArguments = ["-highscoreUITest", "-highscoreIntegration", "-highscoreLocalOrigin", text,
                "-highscoreCompletedRun", "-highscoreRunID", id.uuidString, "-highscoreRunScore", String(score)]
            app.launch()
            let field = app.textFields["highscoreName"]
            XCTAssertTrue(field.waitForExistence(timeout: 12))
            waitForNameFormLayout(); field.tap(); field.typeText("Exact Check"); tapSubmit()
            let selected = app.otherElements["highscoreSelectedRow"]
            XCTAssertTrue(selected.waitForExistence(timeout: 12))
            XCTAssertTrue(selected.label.contains(String(score)))
            // Readback never replays POST. Process-restart persistence is covered by the real storage scope.
            let result = expectation(description: "Read exact score")
            URLSession.shared.dataTask(with: url.appendingPathComponent("api/v1/highscores")) { data, _, error in
                defer { result.fulfill() }
                XCTAssertNil(error)
                guard let data, let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let rows = object["entries"] as? [[String: Any]],
                      let row = rows.first(where: { ($0["entryId"] as? String)?.lowercased() == id.uuidString.lowercased() }) else {
                    XCTFail("Missing saved row"); return
                }
                XCTAssertEqual(row["score"] as? Int, score)
            }.resume()
            wait(for: [result], timeout: 12); app.terminate()
        }
    }

}
