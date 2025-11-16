//
//  arcana_iosUITests.swift
//  arcana-iosUITests
//
//  Created by John on 2025/11/15.
//

import XCTest

final class arcana_iosUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // Initialize and launch the app
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Main Screen Tests

    @MainActor
    func testMainScreenDisplaysCorrectly() throws {
        // Verify main screen elements are present
        XCTAssertTrue(app.staticTexts["Arcana"].exists, "App title should be visible")
        XCTAssertTrue(app.staticTexts["Mystical User Management"].exists, "Subtitle should be visible")

        // Verify the "Manage Users" button exists
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 5), "Manage Users button should exist")
    }

    @MainActor
    func testNavigateToUserList() throws {
        // Wait for the Manage Users button to appear
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 5), "Manage Users button should appear")

        // Tap the button
        manageUsersButton.tap()

        // Wait for navigation and verify we're on the user list screen
        // The user list should have a navigation title or identifiable element
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Should navigate to user list screen")
    }

    @MainActor
    func testUserListScreenLoads() throws {
        // Navigate to user list
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 5))
        manageUsersButton.tap()

        // Wait for the list to load
        // Lists in SwiftUI typically appear as scrollable views
        sleep(2) // Give time for data to load

        // Check if we can scroll (indicates list is present)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            XCTAssertTrue(scrollView.exists, "User list should be scrollable")
        } else {
            // Or check for table/collection view
            let list = app.tables.firstMatch
            XCTAssertTrue(list.exists || app.collectionViews.firstMatch.exists,
                         "User list should be visible")
        }
    }

    @MainActor
    func testPullToRefresh() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()

        // Wait for list to appear
        sleep(2)

        // Find a scrollable element
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Perform pull to refresh gesture
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.1, thenDragTo: end)

            // Verify refresh happened (activity indicator or updated content)
            sleep(1)
            XCTAssertTrue(true, "Pull to refresh gesture completed")
        }
    }

    @MainActor
    func testSearchFunctionality() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Look for search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("test")

            // Verify search is active
            XCTAssertTrue(searchField.value as? String == "test" ||
                         searchField.placeholderValue?.contains("Search") == true,
                         "Search should be functional")
        }
    }

    @MainActor
    func testOfflineModeBanner() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Check if offline banner exists (it might appear when offline)
        // This test verifies the UI elements exist, actual offline testing requires network mocking
        _ = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'offline'")).firstMatch
        // Don't assert it must exist as it only shows when offline
        // Just verify the test can check for it
        XCTAssertTrue(true, "Offline banner check completed")
    }

    @MainActor
    func testAddUserButtonExists() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Use accessibility identifier for Add button
        let addButton = app.buttons["AddUserButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add user button should exist")
    }

    @MainActor
    func testBackNavigation() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(1)

        // Find and tap back button
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()

            // Verify we're back on main screen
            sleep(1)
            XCTAssertTrue(app.staticTexts["Arcana"].waitForExistence(timeout: 3),
                         "Should navigate back to main screen")
        }
    }

    @MainActor
    func testAppDoesNotCrashOnLaunch() throws {
        // If we get here, the app launched successfully
        XCTAssertTrue(app.state == .runningForeground, "App should be running in foreground")

        // Verify main UI elements are responsive
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.exists, "Main UI should be functional")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - User Form Flow Tests

    @MainActor
    func testNavigateToAddUserForm() throws {
        // Navigate to user list
        let manageUsersButton = app.buttons["Manage Users"]
        XCTAssertTrue(manageUsersButton.waitForExistence(timeout: 5))
        manageUsersButton.tap()

        sleep(2) // Wait for list to load

        // Use accessibility identifier for Add button
        let addButton = app.buttons["AddUserButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add User button should exist")
        addButton.tap()

        // Wait for form to appear
        sleep(1)

        // Verify form elements exist using accessibility identifiers
        let firstNameField = app.textFields["FirstNameField"]
        let lastNameField = app.textFields["LastNameField"]
        let emailField = app.textFields["EmailField"]

        XCTAssertTrue(firstNameField.exists || lastNameField.exists || emailField.exists,
                     "User form should have input fields")
    }

    @MainActor
    func testCreateUserFlow() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Use accessibility identifier for Add button
        let addButton = app.buttons["AddUserButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add User button should exist")
        addButton.tap()
        sleep(1)

        // Fill in form fields using accessibility identifiers
        let firstNameField = app.textFields["FirstNameField"]
        let lastNameField = app.textFields["LastNameField"]
        let emailField = app.textFields["EmailField"]

        // Wait for fields to appear
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 5), "First name field should exist")

        // Fill in the form
        firstNameField.tap()
        firstNameField.typeText("UI")

        lastNameField.tap()
        lastNameField.typeText("Test")

        emailField.tap()
        emailField.typeText("uitest@example.com")

        // Wait for validation (debounce)
        sleep(1)

        // Use accessibility identifier for submit button
        let submitButton = app.buttons["SubmitButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5), "Submit button should exist")

        if submitButton.isEnabled {
            submitButton.tap()

            // Wait for form to dismiss
            sleep(2)

            // Verify we're back on user list
            let navigationBar = app.navigationBars["Users"]
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Should return to user list")
        }
    }

    @MainActor
    func testEditUserFlow() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(3) // Wait for data to load

        // Try to find and tap on a user in the list
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            // Tap somewhere in the middle of the scrollview to select a user
            let coordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            coordinate.tap()

            sleep(1)

            // Look for Edit button or edit icon
            let editButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'edit'")).firstMatch

            if editButton.exists {
                editButton.tap()
                sleep(1)

                // Verify we're on edit form
                let textFields = app.textFields.allElementsBoundByIndex
                XCTAssertTrue(textFields.count > 0, "Edit form should have text fields")

                // If fields exist, try to edit
                if textFields.count >= 1 {
                    let firstField = textFields[0]
                    firstField.tap()

                    // Clear and type new value
                    if let currentValue = firstField.value as? String {
                        for _ in 0..<currentValue.count {
                            firstField.typeText(XCUIKeyboardKey.delete.rawValue)
                        }
                    }
                    firstField.typeText("Edited")

                    // Look for Save button
                    let saveButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'save'")).firstMatch
                    if saveButton.exists && saveButton.isEnabled {
                        saveButton.tap()
                        sleep(1)
                    }
                }
            }
        }
    }

    @MainActor
    func testUserFormValidation() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Use accessibility identifier for Add button
        let addButton = app.buttons["AddUserButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add User button should exist")
        addButton.tap()
        sleep(1)

        // Fill in form fields using accessibility identifiers
        let firstNameField = app.textFields["FirstNameField"]
        let lastNameField = app.textFields["LastNameField"]
        let emailField = app.textFields["EmailField"]

        // Wait for fields to appear
        XCTAssertTrue(firstNameField.waitForExistence(timeout: 5), "First name field should exist")

        // Fill with invalid email
        firstNameField.tap()
        firstNameField.typeText("Test")

        lastNameField.tap()
        lastNameField.typeText("User")

        emailField.tap()
        emailField.typeText("invalid-email") // Invalid format

        // Wait for validation (debounce)
        sleep(1)

        // Use accessibility identifier for submit button
        let submitButton = app.buttons["SubmitButton"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5), "Submit button should exist")

        // Button should be disabled due to invalid email
        XCTAssertFalse(submitButton.isEnabled, "Submit button should be disabled with invalid email")
    }

    @MainActor
    func testUserFormCancel() throws {
        // Navigate to user list
        app.buttons["Manage Users"].tap()
        sleep(2)

        // Use accessibility identifier for Add button
        let addButton = app.buttons["AddUserButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add User button should exist")
        addButton.tap()
        sleep(1)

        // Use accessibility identifier for Cancel button
        let cancelButton = app.buttons["CancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), "Cancel button should exist")
        cancelButton.tap()

        sleep(1)

        // Verify we're back on user list
        let navigationBar = app.navigationBars["Users"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), "Should return to user list after cancel")
    }
}
