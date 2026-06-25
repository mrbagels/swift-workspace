import XCTest

@MainActor
final class MacWorkspaceDemoUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchesShellRoutesAndCommandPalette() throws {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(
      app.descendants(matching: .any)["mac-workspace-shell"]
        .waitForExistence(timeout: 10)
    )
    XCTAssertTrue(
      app.descendants(matching: .any)["mac-workspace-route-inbox"]
        .waitForExistence(timeout: 4)
    )
    app.typeKey("k", modifierFlags: .command)

    let searchField = app.textFields["mac-workspace-command-palette-search-field"]
    XCTAssertTrue(searchField.waitForExistence(timeout: 4))
    searchField.click()
    searchField.typeText("settings")

    XCTAssertTrue(
      app.descendants(matching: .any)["mac-workspace-command-palette-row-route-settings"]
        .waitForExistence(timeout: 4)
    )
  }
}
