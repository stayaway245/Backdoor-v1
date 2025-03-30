extension UINavigationController {
    func shouldPresentFullScreen() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.modalPresentationStyle = .formSheet
        } else {
            self.modalPresentationStyle = .fullScreen
        }
    }
}
