//
//  AuthAppForTeslaUITests.swift
//  AuthAppForTeslaUITests
//
//  Created by Kim Hansen on 30/10/2021.
//

import XCTest

let refreshToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ilg0RmNua0RCUVBUTnBrZTZiMnNuRi04YmdVUSJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsImF1ZCI6Imh0dHBzOi8vYXV0aC50ZXNsYS5jb20vb2F1dGgyL3YzL3Rva2VuIiwiaWF0IjoxNjM1NjgxODYwLCJzY3AiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiXSwiZGF0YSI6eyJ2IjoiMSIsImF1ZCI6Imh0dHBzOi8vb3duZXItYXBpLnRlc2xhbW90b3JzLmNvbS8iLCJzdWIiOiIyMWZmMTg0MC0wMjU1LTQ0ODYtODU5Mi1lOGRlOTY1MWM1ZWUiLCJzY3AiOlsib3BlbmlkIiwiZW1haWwiLCJvZmZsaW5lX2FjY2VzcyJdLCJhenAiOiJvd25lcmFwaSIsImFtciI6WyJwd2QiXSwiYXV0aF90aW1lIjoxNjM1NjgxODYwfX0.NvyVC_8fkJmZLU0SWnAJJC8_k5jcHiNA54j0NYuAI15x3dTs2l8w27_uhdRsDbSWx8_YY0xcl8XTscxjhE4i7Ffc8S1Nn4rRsjgqkXZRlLFMn4A2vjnpzj-TlbMxlLHR0eIiE688nrJSkveoZ7h8_h9DB-wTgdmNUGR3tZkABRrefTHt4xGWL_HRX27cVV3worfdOiWlhBolDb_RrRzwzrFJjCz566liyJbChsfmfVExSDfFZHN7uDPp8V67HJKlvD1-aN-7ejUeAOjZz_isKBta5f1Zeq4QHOx9FyPH2YR5X3mUVRPp4yr3x8q_Nr8xNoB1DAkM2T2-G6yrcSmdjaoOvM2GV0RUSdl4j9KOTlWz8JqF-gczJJFeKEas1BwcPP2GL0jGpi_pD0L251Xcly9W0IUK_xpScBH1TbHDfBsu22tWdYoeQvpN2cG6krCdac-KuARLw4zOw2PWEQ3yjDftH0zD-2tWCpHxGYKJUany-_tooMC7kTtapIJnDk9DVoqU3f5raDLnVq_CfTcjfw3yUH2dY3YYqOLe-TWKt3pv0ae9IsD_XF5Y5vXYOP-7Oq5jK5I6R6j46dl1tm5S4yajQkWsTB3yDm667nth17OxEwhA8gzDKEBtagq79OT9hv14RGvLzVgiWrwNo8Rk0kz9NvPW_1mKdOJZRSHLhno"

extension XCUIElement {
    // The following is a workaround for inputting text in the
    //simulator when the keyboard is hidden
    func setText(text: String, application: XCUIApplication) {
        UIPasteboard.general.string = text
        doubleTap()
        application.menuItems["Paste"].tap()
    }
    
    func forceTapElement() {
        if self.isHittable {
            self.tap()
        } else {
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0))
            coordinate.tap()
        }
    }
}

class AuthAppForTeslaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        let app = XCUIApplication()
        setupSnapshot(app)
//        app.launch()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testScreenshots() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing", "token:\(refreshToken)"]
        app.launch()

        snapshot("loginscreen")

        app.buttons["loginButton"].forceTapElement()
        
        
        
        
        app.buttons["refreshTokensButton"].forceTapElement()
        
        let tabBar = XCUIApplication().tabBars["Tab Bar"]
        
        
                
        
//        app.otherElements["aboutTab"].forceTapElement()
        tabBar.buttons["About"].tap()
        snapshot("aboutscreen")
        
//        app.tabBars.buttons["homeTab"].forceTapElement()
        tabBar.buttons["Home"].tap()
        snapshot("mainscreen")
//        app.otherElements["homeMenu"].forceTapElement()
////        app.menus["homeMenu"].forceTapElement()
////        app.images["homeMenu"].forceTapElement()
////        app.buttons["homeMenu"].forceTapElement()
//
//
////        app.menus["homeMenu"].forceTapElement()
////        XCUIApplication().buttons["homeTab"].tap()
////
//        app.buttons["logoutButton"].forceTapElement()
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
