import XCTest

@MainActor
final class MacWorkspaceDemoUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunchesShellRoutesAndCommandPalette() throws {
    let app = XCUIApplication()
    app.launch()

    let shell = app.descendants(matching: .any)["mac-workspace-shell"]
    XCTAssertTrue(shell.waitForExistence(timeout: 10))

    let window = app.windows.firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 4))

    let inboxRoute = app.descendants(matching: .any)["mac-workspace-route-inbox"]
    XCTAssertTrue(inboxRoute.waitForExistence(timeout: 4))
    XCTAssertGreaterThanOrEqual(window.frame.minX, 0)
    XCTAssertGreaterThanOrEqual(inboxRoute.frame.minX, window.frame.minX)
    XCTAssertLessThanOrEqual(inboxRoute.frame.maxX, window.frame.maxX)

    XCTAssertTrue(
      app.descendants(matching: .any)["mac-workspace-sidebar-presentation-picker"]
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
