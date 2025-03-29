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
    @available(*, deprecated, message: "Use NotificationNames.changeTab instead")
    static let changeTab = NotificationNames.changeTab
    // Note: showAIAssistant is defined in FloatingButtonManager.swift
}

// New centralized class for notification names to avoid ambiguity
public enum NotificationNames {
    static let changeTab = Notification.Name("com.backdoor.notifications.changeTab")
}
