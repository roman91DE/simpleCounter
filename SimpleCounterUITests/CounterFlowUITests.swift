import XCTest

final class CounterFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_createCounterIncrementAndVerifyPersistence() {
        let app = XCUIApplication()
        app.launch()

        // Create a counter
        app.navigationBars.buttons["Add"].tap()
        let nameField = app.textFields["e.g. Nicotine Gum"]
        nameField.tap()
        nameField.typeText("Coffee")
        let emojiField = app.textFields["🍬"]
        emojiField.tap()
        emojiField.typeText("☕️")
        app.navigationBars.buttons["Save"].tap()

        // The counter should appear in the list
        XCTAssertTrue(app.staticTexts["Coffee"].waitForExistence(timeout: 2))

        // Tap to open detail
        app.staticTexts["Coffee"].tap()

        // Increment the counter
        let incrementButton = app.buttons["Increment"]
        incrementButton.tap()
        incrementButton.tap()
        incrementButton.tap()

        // Verify the count shows 3
        XCTAssertTrue(app.staticTexts["3"].waitForExistence(timeout: 2))

        // Background and return
        XCUIDevice.shared.press(.home)
        app.activate()

        // Count should persist
        XCTAssertTrue(app.staticTexts["3"].waitForExistence(timeout: 2))
    }
}
