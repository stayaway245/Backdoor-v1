import UIKit

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
}

// Define notification names in a central location
// These notification names need to be unique across the app
extension Notification.Name {
    // Used for tab switching across the app - use this constant instead of creating new instances
    static let changeTab = Notification.Name("com.backdoor.notifications.changeTab")
    // Note: showAIAssistant is defined in FloatingButtonManager.swift
}
