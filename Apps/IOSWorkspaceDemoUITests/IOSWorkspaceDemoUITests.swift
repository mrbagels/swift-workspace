import XCTest

@MainActor
final class IOSWorkspaceDemoUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchesShellRoutesAndCommandSearch() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(
      app.descendants(matching: .any)["ios-workspace-shell"]
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.staticTexts["Route ID: inbox"]
        .waitForExistence(timeout: 4)
    )
    XCTAssertTrue(
      app.buttons["ios-workspace-command-search-button"]
        .waitForExistence(timeout: 4)
    )

    app.buttons["ios-workspace-command-search-button"].tap()

    let searchField = app.textFields["ios-workspace-command-search-field"]
    XCTAssertTrue(searchField.waitForExistence(timeout: 4))
    searchField.tap()
    searchField.typeText("settings")

    XCTAssertTrue(
      app.descendants(matching: .any)["ios-workspace-route-settings-search-row"]
        .waitForExistence(timeout: 4)
    )
  }
}
