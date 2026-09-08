import XCTest

extension XCUIElement {
    /// Catalyst controls require mouse events; iOS controls require touch events.
    func clickOrTap() {
        #if targetEnvironment(macCatalyst)
        click()
        #else
        tap()
        #endif
    }
}
