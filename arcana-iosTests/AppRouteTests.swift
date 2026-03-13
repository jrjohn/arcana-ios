//
//  AppRouteTests.swift
//  arcana-iosTests
//
//  Tests for AppRoute, UserFormMode, and NavGraph
//

import Testing
import Foundation
import Dependencies
@testable import arcana_ios

// MARK: - AppRoute Tests

struct AppRouteTests {

    @Test("AppRoute.id is unique per route")
    func testRouteIds() {
        let user = User.mock(id: "test-123")

        let mainId = AppRoute.main.id
        let listId = AppRoute.userList.id
        let detailId = AppRoute.userDetail(user).id
        let createId = AppRoute.userForm(mode: .create).id
        let settingsId = AppRoute.settings.id

        let ids = [mainId, listId, detailId, createId, settingsId]
        let uniqueIds = Set(ids)
        #expect(uniqueIds.count == ids.count)
    }

    @Test("AppRoute.title returns correct values")
    func testRouteTitles() {
        let user = User.mock()
        #expect(AppRoute.main.title == "Home")
        #expect(AppRoute.userList.title == "Users")
        #expect(AppRoute.userDetail(user).title == "User Details")
        #expect(AppRoute.userForm(mode: .create).title == "Create User")
        #expect(AppRoute.userForm(mode: .edit(user)).title == "Edit User")
        #expect(AppRoute.settings.title == "Settings")
    }

    @Test("AppRoute.analyticsName returns correct values")
    func testRouteAnalyticsNames() {
        let user = User.mock()
        #expect(AppRoute.main.analyticsName == "main_screen")
        #expect(AppRoute.userList.analyticsName == "user_list_screen")
        #expect(AppRoute.userDetail(user).analyticsName == "user_detail_screen")
        #expect(AppRoute.userForm(mode: .create).analyticsName == "user_create_screen")
        #expect(AppRoute.userForm(mode: .edit(user)).analyticsName == "user_edit_screen")
        #expect(AppRoute.settings.analyticsName == "settings_screen")
    }

    @Test("AppRoute.Identifiable conforms correctly")
    func testRouteIdentifiable() {
        let user1 = User.mock(id: "user-1")
        let user2 = User.mock(id: "user-2")

        let route1 = AppRoute.userDetail(user1)
        let route2 = AppRoute.userDetail(user2)

        #expect(route1.id != route2.id)
    }

    @Test("AppRoute.Hashable conforms correctly")
    func testRouteHashable() {
        let route1 = AppRoute.main
        let route2 = AppRoute.main
        let route3 = AppRoute.userList

        var routeSet: Set<AppRoute> = [route1, route2, route3]
        #expect(routeSet.count == 2) // main and userList
    }
}

// MARK: - UserFormMode Tests

struct UserFormModeTests {

    @Test("UserFormMode.create has correct id")
    func testCreateModeId() {
        let mode = UserFormMode.create
        #expect(mode.id == "create")
    }

    @Test("UserFormMode.edit has correct id")
    func testEditModeId() {
        let user = User.mock(id: "user-42")
        let mode = UserFormMode.edit(user)
        #expect(mode.id == "edit_user-42")
    }

    @Test("UserFormMode.Hashable conforms correctly")
    func testModeHashable() {
        let user = User.mock()
        let create1 = UserFormMode.create
        let create2 = UserFormMode.create
        let edit1 = UserFormMode.edit(user)

        var modeSet: Set<UserFormMode> = [create1, create2, edit1]
        #expect(modeSet.count == 2)
    }
}

// MARK: - NavGraph Tests

@MainActor
struct NavGraphTests {

    @Test("NavGraph initializes with empty path")
    func testInitialization() {
        let navGraph = NavGraph()
        #expect(navGraph.path.isEmpty)
        #expect(navGraph.presentedSheet == nil)
        #expect(navGraph.presentedFullScreenCover == nil)
        #expect(navGraph.alertToShow == nil)
    }

    @Test("NavGraph.push adds route to path")
    func testPush() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.push(.userList)
        #expect(navGraph.path.count == 1)
        #expect(navGraph.path[0] == .userList)
    }

    @Test("NavGraph.pop removes last route")
    func testPop() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.push(.userList)
        navGraph.push(.settings)
        navGraph.pop()

        #expect(navGraph.path.count == 1)
        #expect(navGraph.path[0] == .userList)
    }

    @Test("NavGraph.pop does nothing when stack empty")
    func testPopEmptyStack() {
        let navGraph = NavGraph()
        navGraph.pop() // Should not crash
        #expect(navGraph.path.isEmpty)
    }

    @Test("NavGraph.popToRoot clears entire stack")
    func testPopToRoot() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.push(.userList)
        navGraph.push(.settings)
        navGraph.popToRoot()

        #expect(navGraph.path.isEmpty)
    }

    @Test("NavGraph.popTo goes to specific route")
    func testPopTo() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.push(.userList)
        navGraph.push(.settings)
        navGraph.popTo(.userList)

        #expect(navGraph.path.count == 1)
        #expect(navGraph.path[0] == .userList)
    }

    @Test("NavGraph.presentSheet sets presented sheet")
    func testPresentSheet() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.presentSheet(.userForm(mode: .create))
        #expect(navGraph.presentedSheet != nil)

        navGraph.dismissSheet()
        #expect(navGraph.presentedSheet == nil)
    }

    @Test("NavGraph.presentFullScreenCover sets cover")
    func testPresentFullScreenCover() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.presentFullScreenCover(.settings)
        #expect(navGraph.presentedFullScreenCover != nil)

        navGraph.dismissFullScreenCover()
        #expect(navGraph.presentedFullScreenCover == nil)
    }

    @Test("NavGraph.showAlert and dismissAlert work")
    func testAlertManagement() {
        let navGraph = NavGraph()
        let alertConfig = AlertConfig(title: "Test", message: "Test message")

        navGraph.showAlert(alertConfig)
        #expect(navGraph.alertToShow != nil)

        navGraph.dismissAlert()
        #expect(navGraph.alertToShow == nil)
    }

    @Test("NavGraph convenience navigation methods work")
    func testConvenienceNavigation() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.navigateToUserList()
        #expect(navGraph.path.contains(.userList))

        navGraph.navigateToSettings()
        #expect(navGraph.path.contains(.settings))

        navGraph.navigateToMain()
        #expect(navGraph.path.isEmpty)
    }

    @Test("NavGraph.navigateToUserDetail pushes detail route")
    func testNavigateToUserDetail() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        let user = User.mock()
        navGraph.navigateToUserDetail(user)

        #expect(navGraph.path.count == 1)
        if case .userDetail(let u) = navGraph.path[0] {
            #expect(u.id == user.id)
        } else {
            Issue.record("Expected userDetail route")
        }
    }

    @Test("NavGraph.presentCreateUserForm shows sheet")
    func testPresentCreateUserForm() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        navGraph.presentCreateUserForm()
        #expect(navGraph.presentedSheet != nil)
    }

    @Test("NavGraph.presentEditUserForm shows sheet")
    func testPresentEditUserForm() {
        let navGraph = withDependencies {
            $0.analyticsTracker = MockAnalyticsTracker()
        } operation: {
            NavGraph()
        }

        let user = User.mock()
        navGraph.presentEditUserForm(user)
        #expect(navGraph.presentedSheet != nil)
    }
}

// MARK: - AlertConfig Tests

struct AlertConfigTests {

    @Test("AlertConfig initializes correctly")
    func testAlertConfigInit() {
        let alert = AlertConfig(title: "Test Alert", message: "Test message")
        #expect(alert.title == "Test Alert")
        #expect(alert.message == "Test message")
        #expect(alert.primaryButton == nil)
        #expect(alert.secondaryButton == nil)
    }

    @Test("AlertConfig with buttons initializes correctly")
    func testAlertConfigWithButtons() {
        var tapped = false
        let button = AlertConfig.AlertButton(title: "OK") { tapped = true }
        let alert = AlertConfig(
            title: "Confirm",
            message: "Are you sure?",
            primaryButton: button
        )

        #expect(alert.primaryButton != nil)
        alert.primaryButton?.action()
        #expect(tapped == true)
    }

    @Test("AlertConfig.id is unique per instance")
    func testAlertConfigUniqueId() {
        let alert1 = AlertConfig(title: "Alert 1")
        let alert2 = AlertConfig(title: "Alert 2")
        #expect(alert1.id != alert2.id)
    }
}
