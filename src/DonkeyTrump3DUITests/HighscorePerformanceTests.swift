import XCTest

@MainActor
final class HighscorePerformanceTests: HighscoreUITestCase {
    func testContinuousStreamDoesNotExtendVisibleDeadline() throws {
        guard let origin = ProcessInfo.processInfo.environment["DT3D_STREAM_TEST_ORIGIN"] else { throw XCTSkip("Requires local streaming fixture") }
        app.launchArguments = ["-highscoreIntegration", "-highscoreLocalOrigin", origin, "-highscoreUITest", "-highscoreDeadlineProbe"]
        app.launch()
        let output = app.staticTexts["highscorePerformanceResult"]
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != 'pending'"), object: output)
        XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: 15), .completed)
        let result = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(output.label.utf8)) as? [String:Double])
        XCTAssertLessThanOrEqual(try XCTUnwrap(result["streamFailureVisibleMs"]), 8000)
        XCTAssertTrue(app.staticTexts["highscoreError"].exists)
        let attachment = XCTAttachment(string: output.label); attachment.name = "stream-deadline"; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testHundredPairedStartsAndRealStorageVisibleResults() throws {
        guard let origin = ProcessInfo.processInfo.environment["DT3D_PERFORMANCE_ORIGIN"] else {
            throw XCTSkip("Requires a test-owned loopback API/Azurite; see local-highscores.py")
        }
        app.launchArguments = ["-highscoreIntegration", "-highscoreLocalOrigin", origin, "-highscoreUITest", "-highscorePerformance"]
        app.launch()
        let output = app.staticTexts["highscorePerformanceResult"]
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != 'pending'"), object: output)
        XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: 300), .completed)
        let data = Data(output.label.utf8)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json"); attachment.name = "highscore-performance"; attachment.lifetime = .keepAlways; add(attachment)
        let result = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String:Any])
        let baseline = try XCTUnwrap(result["baselineMs"] as? [Double])
        let starts = try XCTUnwrap(result["startRestartMs"] as? [Double])
        XCTAssertEqual(baseline.count, 100); XCTAssertEqual(starts.count, 100)
        for (base, value) in zip(baseline, starts) { XCTAssertLessThan(value - base, 100) }
        for key in ["readVisibleMs", "postVisibleMs"] {
            let samples = try XCTUnwrap(result[key] as? [Double]); XCTAssertEqual(samples.count, 100)
            XCTAssertLessThanOrEqual(samples.sorted()[94], 2000)
        }
        XCTAssertLessThanOrEqual(try XCTUnwrap(result["hungFailureVisibleMs"] as? Double), 8000)
    }
}
