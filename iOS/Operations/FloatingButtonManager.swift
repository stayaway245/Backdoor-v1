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
    private let floatingButton = FloatingAIButton()
    private var window: UIWindow?
    
    // Thread-safe state tracking with a dedicated queue
    private let stateQueue = DispatchQueue(label: "com.backdoor.floatingButtonState")
    private var _isPresentingChat = false
    private var isPresentingChat: Bool {
        get { stateQueue.sync { return _isPresentingChat } }
        set { stateQueue.sync { _isPresentingChat = newValue } }
    }
    
    // Track window state
    private var isWindowSetUp = false
    
    private init() {
        // Log initialization
        Debug.shared.log(message: "FloatingButtonManager initialized", type: .info)
        
        // Set up notification observers
        setupObservers()
        
        // Set up the AI interaction
        setupAIInteraction()
    }
    
    deinit {
        // Clean up observers to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
        Debug.shared.log(message: "FloatingButtonManager deinit", type: .debug)
    }
    
    private func setupObservers() {
        // Observe orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        
        // Observe interface style changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateButtonAppearance),
            name: NSNotification.Name("UIInterfaceStyleChanged"),
            object: nil
        )
        
        // Listen for button taps
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAIRequest),
            name: .showAIAssistant,
            object: nil
        )
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    private func setupWindow() {
        // Avoid setting up window multiple times
        guard !isWindowSetUp else { return }
        
        // Get the active window scene
        guard let scene = UIApplication.shared.connectedScenes.first(where: { 
            $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive
        }) as? UIWindowScene else {
            Debug.shared.log(message: "No active window scene found", type: .error)
            return
        }
        
        // Create the floating button window
        let newWindow = UIWindow(windowScene: scene)
        newWindow.windowLevel = .alert + 1  // Above alerts but below critical system UI
        newWindow.backgroundColor = .clear
        
        // Create and set up the root view controller (required for window)
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        newWindow.rootViewController = rootVC
        
        // Add the floating button to the window's view
        rootVC.view.addSubview(floatingButton)
        
        // Position the button
        let safeArea = scene.windows.first?.safeAreaInsets ?? .zero
        floatingButton.center = CGPoint(
            x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
            y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom
        )
        
        // Make the window visible
        newWindow.isHidden = false
        
        // Store reference and mark as set up
        self.window = newWindow
        isWindowSetUp = true
        
        Debug.shared.log(message: "Floating button window set up successfully", type: .info)
    }
    
    @objc private func handleOrientationChange() {
        // Re-position button when orientation changes
        guard let window = window, let scene = window.windowScene else {
            return
        }
        
        let safeArea = scene.windows.first?.safeAreaInsets ?? .zero
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.floatingButton.center = CGPoint(
                x: scene.coordinateSpace.bounds.width - 40 - safeArea.right,
                y: scene.coordinateSpace.bounds.height - 100 - safeArea.bottom
            )
        }
    }
    
    @objc private func handleAppDidBecomeActive() {
        // Ensure the button is shown when app becomes active
        if !isPresentingChat {
            DispatchQueue.main.async { [weak self] in
                self?.show()
            }
        }
    }
    
    @objc private func handleAppWillResignActive() {
        // Optional: You might want to hide the button when app resigns active
        // This depends on your app's requirements
    }
    
    @objc private func updateButtonAppearance() {
        // Update the floating button appearance when theme changes
        floatingButton.updateAppearance()
    }
    
    /// Show the floating button
    func show() {
        // Create window if needed
        if !isWindowSetUp {
            setupWindow()
        }
        
        guard let window = window else {
            Debug.shared.log(message: "Cannot show floating button: window is nil", type: .error)
            return
        }
        
        // Make window and button visible
        window.isHidden = false
        floatingButton.isHidden = false
    }
    
    /// Hide the floating button
    func hide() {
        // Simply hide the button without destroying the window
        floatingButton.isHidden = true
    }
    
    private func setupAIInteraction() {
        // Register app commands for the AI assistant
        
        // Command: add source
        AppContextManager.shared.registerCommand("add source") { sourceURL, completion in
            guard let _ = URL(string: sourceURL) else {
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
        // Ensure we're on the main thread for UI operations
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Prevent multiple presentations
            if self.isPresentingChat {
                Debug.shared.log(message: "Already presenting chat, ignoring request", type: .warning)
                return
            }
            
            // Set flag to prevent multiple presentations
            self.isPresentingChat = true
            
            // Prepare for AI chat by refreshing context
            guard let topVC = UIApplication.shared.topMostViewController() else {
                Debug.shared.log(message: "Could not find top view controller to present chat", type: .error)
                self.isPresentingChat = false
                return
            }
            
            AppContextManager.shared.updateContext(topVC)
            CustomAIContextProvider.shared.refreshContext()
            
            // Create a new chat session to avoid issues with corrupted or nil values
            do {
                let title = "Chat on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                let session = try CoreDataManager.shared.createAIChatSession(title: title)
                self.presentChatInterface(with: session, from: topVC)
            } catch {
                Debug.shared.log(message: "Failed to create chat session: \(error.localizedDescription)", type: .error)
                self.isPresentingChat = false
                
                // Show error alert
                self.showErrorAlert(message: "Could not start chat. Please try again.", on: topVC)
            }
        }
    }
    
    private func presentChatInterface(with session: ChatSession, from presenter: UIViewController) {
        // Create and configure the chat interface
        let chatVC = ChatViewController(session: session)
        let navController = UINavigationController(rootViewController: chatVC)
        
        // Add completion handler to reset state
        chatVC.dismissHandler = { [weak self] in
            self?.isPresentingChat = false
        }
        
        // Determine the best presentation style for the device
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad-specific presentation
            navController.modalPresentationStyle = .formSheet
            navController.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            // iPhone presentation with sheet style when possible
            if #available(iOS 15.0, *), let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            } else {
                // Fallback for older iOS versions
                navController.modalPresentationStyle = .fullScreen
            }
        }
        
        // Use try-catch to handle potential presentation errors
        do {
            // If already presenting a different modal, dismiss it first
            if presenter.presentedViewController != nil {
                presenter.dismiss(animated: true) { [weak self, weak presenter, weak navController] in
                    guard let self = self, let presenter = presenter, let navController = navController else {
                        self?.isPresentingChat = false
                        return
                    }
                    
                    presenter.present(navController, animated: true) {
                        Debug.shared.log(message: "Custom AI assistant presented successfully after dismissing previous modal", type: .info)
                    }
                }
            } else {
                // Present directly if no other modal is active
                presenter.present(navController, animated: true) { [weak self] in
                    Debug.shared.log(message: "Custom AI assistant presented successfully", type: .info)
                }
            }
        } catch {
            Debug.shared.log(message: "Error presenting chat interface: \(error.localizedDescription)", type: .error)
            isPresentingChat = false
            
            // Show error alert
            showErrorAlert(message: "Could not open chat interface. Please try again.", on: presenter)
        }
    }
    
    private func showErrorAlert(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
}
