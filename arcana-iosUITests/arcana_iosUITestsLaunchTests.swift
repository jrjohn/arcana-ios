//
//  arcana_iosUITestsLaunchTests.swift
//  arcana-iosUITests
//
//  Created by John on 2025/11/15.
//

import XCTest

final class arcana_iosUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for main screen to load
        let arcanaTitle = app.staticTexts["Arcana"]
        XCTAssertTrue(arcanaTitle.waitForExistence(timeout: 10), "App should launch to main screen")

        // Take screenshot of launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Main View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchAndNavigateToUserList() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for main screen with longer timeout
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 15))

        // Take screenshot of main screen
        var attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "01 - Main Screen"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Ensure button is hittable before tapping
        sleep(1)
        manageUsersButton.tap()

        // Wait for navigation to complete
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 10))

        // Wait for user list to load
        sleep(2)

        // Take screenshot of user list
        attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "02 - User List Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchWithInteraction() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify app is interactive with longer timeout
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 15))

        // Ensure button is hittable before tapping
        sleep(1)

        // Tap button to verify it's responsive
        manageUsersButton.tap()

        // Wait for navigation with longer timeout
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 10),
                     "App should be interactive and navigate successfully")

        // Wait for screen to stabilize
        sleep(1)

        // Take screenshot showing successful interaction
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Interactive Launch - User List"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
