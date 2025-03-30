import Foundation

extension UIApplication {
    /// Returns from the foreground app to the home screen.
    func returnToHomeScreen() {
        LSApplicationWorkspace.default()
            .openApplication(withBundleID: "com.apple.springboard")
    }
}
