import UIKit
import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let showAIAssistant = Notification.Name("showAIAssistant")
}

/// Manages the floating AI button across the app
final class FloatingButtonManager {
    // Singleton instance
    static let shared = FloatingButtonManager()
    
    // UI components
    private let floatingButton: FloatingAIButton
    private var window: UIWindow?
    
    // State tracking
    private var isPresentingChat = false
    
    private init() {
        // Initialize components
        floatingButton = FloatingAIButton()
        setupWindow()
        setupAIInteraction()
        
        // Log initialization
        Debug.shared.log(message: "FloatingButtonManager initialized with custom AI", type: .info)
    }
    
    private func setupWindow() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        window = UIWindow(windowScene: scene)
        window?.windowLevel = .alert
        window?.rootViewController = UIViewController()
        window?.isHidden = false
        window?.addSubview(floatingButton)
        
        let safeArea = window?.safeAreaInsets ?? .zero
        floatingButton.center = CGPoint(x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
                                      y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleOrientationChange),
                                             name: UIDevice.orientationDidChangeNotification,
                                             object: nil)
        
        // Also observe interface style changes
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(updateButtonAppearance),
                                             name: NSNotification.Name("UIInterfaceStyleChanged"),
                                             object: nil)
    }
    
    @objc private func handleOrientationChange() {
        guard let scene = window?.windowScene else { return }
        let safeArea = window?.safeAreaInsets ?? .zero
        UIView.animate(withDuration: 0.3) {
            self.floatingButton.center = CGPoint(x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
                                              y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom)
        }
    }
    
    @objc private func updateButtonAppearance() {
        // Update the floating button appearance when theme changes
        floatingButton.updateAppearance()
    }
    
    /// Show the floating button
    func show() {
        floatingButton.isHidden = false
    }
    
    /// Hide the floating button
    func hide() {
        floatingButton.isHidden = true
    }
    
    private func setupAIInteraction() {
        // Listen for button taps
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAIRequest),
                                             name: .showAIAssistant,
                                             object: nil)
        
        // Register app commands for the AI assistant
        
        // Command: add source
        AppContextManager.shared.registerCommand("add source") { sourceURL, completion in
            guard URL(string: sourceURL) != nil else {
                Debug.shared.log(message: "Invalid source URL: \(sourceURL)", type: .error)
                completion("Invalid source URL")
                return
            }
            CoreDataManager.shared.saveSource(name: "Custom Source", id: UUID().uuidString, iconURL: nil, url: sourceURL) { error in
                if let error = error {
                    Debug.shared.log(message: "Failed to add source: \(error)", type: .error)
                    completion("Failed to add source: \(error.localizedDescription)")
                } else {
                    Debug.shared.log(message: "Added source: \(sourceURL)", type: .success)
                    completion("Source added successfully")
                }
            }
        }
        
        // Command: list sources
        AppContextManager.shared.registerCommand("list sources") { _, completion in
            let sources = CoreDataManager.shared.getAZSources()
            let sourceNames = sources.map { $0.name ?? "Unnamed" }.joined(separator: "\n")
            completion(sourceNames.isEmpty ? "No sources available" : sourceNames)
        }
        
        // Command: list downloaded apps
        AppContextManager.shared.registerCommand("list downloaded apps") { _, completion in
            let apps = CoreDataManager.shared.getDatedDownloadedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.version ?? "Unknown"))" }.joined(separator: "\n")
            completion(appNames.isEmpty ? "No downloaded apps" : appNames)
        }
        
        // Command: list signed apps
        AppContextManager.shared.registerCommand("list signed apps") { _, completion in
            let apps = CoreDataManager.shared.getDatedSignedApps()
            let appNames = apps.map { "\($0.name ?? "Unnamed") (\($0.bundleidentifier ?? "Unknown"))" }.joined(separator: "\n")
            completion(appNames.isEmpty ? "No signed apps" : appNames)
        }
        
        // Command: list certificates
        AppContextManager.shared.registerCommand("list certificates") { _, completion in
            let certificates = CoreDataManager.shared.getDatedCertificate()
            let certNames = certificates.map { $0.certData?.name ?? "Unnamed" }.joined(separator: "\n")
            completion(certNames.isEmpty ? "No certificates" : certNames)
        }
        
        // Command: navigate to
        AppContextManager.shared.registerCommand("navigate to") { screen, completion in
            guard let _ = UIApplication.shared.topMostViewController() as? UIHostingController<TabbarView> else {
                Debug.shared.log(message: "Cannot navigate: Not on main tab bar", type: .error)
                completion("Cannot navigate: Not on main screen")
                return
            }
            
            var targetTab: String
            switch screen.lowercased() {
            case "home":
                targetTab = "home"
            case "sources":
                targetTab = "sources"
            case "library":
                targetTab = "library"
            case "settings":
                targetTab = "settings"
            case "bdg hub", "bdghub", "hub":
                targetTab = "bdgHub"
            default:
                Debug.shared.log(message: "Unknown screen: \(screen)", type: .warning)
                completion("Unknown screen: \(screen)")
                return
            }
            
            UserDefaults.standard.set(targetTab, forKey: "selectedTab")
            NotificationCenter.default.post(name: .changeTab, object: nil, userInfo: ["tab": targetTab])
            completion("Navigated to \(screen)")
        }
        
        // Command: system info
        AppContextManager.shared.registerCommand("system info") { _, completion in
            let device = UIDevice.current
            let info = """
                Device: \(device.name) (\(device.model))
                iOS: \(device.systemVersion)
                App: Backdoor \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                """
            completion(info)
        }
        
        // Command: refresh context
        AppContextManager.shared.registerCommand("refresh context") { _, completion in
            if let topVC = UIApplication.shared.topMostViewController() {
                AppContextManager.shared.updateContext(topVC)
                CustomAIContextProvider.shared.refreshContext()
                completion("Context refreshed successfully")
            } else {
                completion("Failed to refresh context: Could not determine current screen")
            }
        }
    }
    
    @objc private func handleAIRequest() {
        // Prevent multiple presentations
        guard !isPresentingChat else { return }
        isPresentingChat = true
        
        // Prepare for AI chat by refreshing context
        if let topVC = UIApplication.shared.topMostViewController() {
            AppContextManager.shared.updateContext(topVC)
        }
        CustomAIContextProvider.shared.refreshContext()
        
        // Create and configure the chat interface
        let chatVC = ChatViewController()
        let navController = UINavigationController(rootViewController: chatVC)
        
        // Determine the best presentation style for the device
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad-specific presentation
            navController.modalPresentationStyle = .formSheet
            navController.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            // iPhone presentation with sheet style when possible
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            } else {
                // Fallback for older iOS versions
                navController.modalPresentationStyle = .fullScreen
            }
        }
        
        // Present the chat interface
        if let topVC = UIApplication.shared.topMostViewController() {
            // If already presenting a different modal, dismiss it first
            if topVC.presentedViewController != nil {
                topVC.dismiss(animated: true) {
                    topVC.present(navController, animated: true) {
                        Debug.shared.log(message: "Custom AI assistant presented successfully", type: .info)
                        self.isPresentingChat = false
                    }
                }
            } else {
                // Present directly if no other modal is active
                topVC.present(navController, animated: true) {
                    Debug.shared.log(message: "Custom AI assistant presented successfully", type: .info)
                    self.isPresentingChat = false
                }
            }
        } else {
            Debug.shared.log(message: "Could not find top view controller to present chat", type: .error)
            isPresentingChat = false
        }
    }
}
