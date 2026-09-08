import XCTest

extension XCUICoordinate {
    /// Uses the destination's input type when focusing web fields or custom controls.
    func clickOrTap() {
        #if targetEnvironment(macCatalyst)
        click()
        #else
        tap()
        #endif
    }
}
