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
    
    // UI components - using a direct approach rather than separate window
    private let floatingButton = FloatingAIButton()
    
    // Thread-safe state tracking with a dedicated queue
    private let stateQueue = DispatchQueue(label: "com.backdoor.floatingButtonState")
    private var _isPresentingChat = false
    private var isPresentingChat: Bool {
        get { stateQueue.sync { return _isPresentingChat } }
        set { stateQueue.sync { _isPresentingChat = newValue } }
    }
    
    // Track setup state
    private var isSetUp = false
    private weak var parentViewController: UIViewController?
    private weak var parentView: UIView?
    
    // Recovery counter to prevent excessive retries
    private var recoveryAttempts = 0
    private let maxRecoveryAttempts = 3
    
    private init() {
        // Log initialization
        Debug.shared.log(message: "FloatingButtonManager initialized", type: .info)
        
        // Configure the floating button
        configureFloatingButton()
        
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
    
    private func configureFloatingButton() {
        // Configure the button's appearance
        floatingButton.layer.zPosition = 999 // Ensure it's above other views
        floatingButton.isUserInteractionEnabled = true
        
        // Add a shadow for better visibility
        floatingButton.layer.shadowColor = UIColor.black.cgColor
        floatingButton.layer.shadowOpacity = 0.3
        floatingButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        floatingButton.layer.shadowRadius = 4
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
        
        // Listen for tab changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabChange),
            name: .changeTab,
            object: nil
        )
    }
    
    @objc private func handleTabChange(_ notification: Notification) {
        // When tab changes, we need to reattach the button to the new view controller
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.updateButtonPosition()
        }
    }
    
    private func attachToRootView() {
        // Find the top view controller to add the button to
        guard let rootVC = UIApplication.shared.topMostViewController() else {
            Debug.shared.log(message: "No root view controller found", type: .error)
            return
        }
        
        // Remember the parent for later repositioning
        parentViewController = rootVC
        parentView = rootVC.view
        
        // Calculate position based on safe area
        let safeArea = rootVC.view.safeAreaInsets
        let maxX = rootVC.view.bounds.width - 40 - safeArea.right
        let maxY = rootVC.view.bounds.height - 100 - safeArea.bottom
        
        // Add to view and position
        floatingButton.translatesAutoresizingMaskIntoConstraints = false
        floatingButton.removeFromSuperview() // Remove from previous parent if any
        rootVC.view.addSubview(floatingButton)
        
        // Set frame instead of constraints for better positioning with draggable behavior
        floatingButton.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        floatingButton.center = CGPoint(x: maxX, y: maxY)
        
        isSetUp = true
        
        Debug.shared.log(message: "Floating button attached to root view", type: .info)
    }
    
    @objc private func handleOrientationChange() {
        updateButtonPosition()
    }
    
    private func updateButtonPosition() {
        guard let parentVC = parentViewController, parentVC.view.window != nil else {
            // View is not in window hierarchy, try to re-attach
            if recoveryAttempts < maxRecoveryAttempts {
                recoveryAttempts += 1
                Debug.shared.log(message: "Trying to recover floating button (attempt \(recoveryAttempts))", type: .warning)
                
                DispatchQueue.main.async { [weak self] in
                    self?.attachToRootView()
                }
            }
            return
        }
        
        // Reset recovery counter
        recoveryAttempts = 0
        
        // Update position based on current orientation and safe area
        let safeArea = parentVC.view.safeAreaInsets
        let maxX = parentVC.view.bounds.width - 40 - safeArea.right
        let maxY = parentVC.view.bounds.height - 100 - safeArea.bottom
        
        UIView.animate(withDuration: 0.3) {
            self.floatingButton.center = CGPoint(x: maxX, y: maxY)
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
        // No need to do anything special here, button should stay with view
    }
    
    @objc private func updateButtonAppearance() {
        // Update the floating button appearance when theme changes
        floatingButton.updateAppearance()
    }
    
    /// Show the floating button
    func show() {
        // Attach to root view if needed
        if !isSetUp || parentView?.window == nil {
            attachToRootView()
        }
        
        // Make button visible
        floatingButton.isHidden = false
        
        // Update position to ensure it's in the right place
        updateButtonPosition()
    }
    
    /// Hide the floating button
    func hide() {
        // Simply hide the button
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
            
            // Provide haptic feedback to confirm button tap
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            // Set flag to prevent multiple presentations
            self.isPresentingChat = true
            
            // Hide the floating button while presenting
            self.hide()
            
            // Find the top view controller on which to present the chat
            guard let topVC = UIApplication.shared.topMostViewController() else {
                Debug.shared.log(message: "Could not find top view controller to present chat", type: .error)
                self.isPresentingChat = false
                self.show() // Show the button again
                return
            }
            
            // Verify the view controller is in a valid state to present
            if topVC.isBeingDismissed || topVC.isBeingPresented || topVC.isMovingFromParent || topVC.isMovingToParent {
                Debug.shared.log(message: "View controller is in transition, delaying chat presentation", type: .warning)
                
                // Delay and retry once the transition completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.isPresentingChat = false
                    self?.handleAIRequest()
                }
                return
            }
            
            // Prepare for AI chat by refreshing context safely
            do {
                // Update AI context
                AppContextManager.shared.updateContext(topVC)
                CustomAIContextProvider.shared.refreshContext()
                
                // Create a new chat session
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                let timestamp = dateFormatter.string(from: Date())
                let title = "Chat on \(timestamp)"
                
                // Create the session
                let session = try CoreDataManager.shared.createAIChatSession(title: title)
                
                // Present the chat interface with the new session
                self.presentChatInterfaceSafely(with: session, from: topVC)
            } catch {
                Debug.shared.log(message: "Failed to create chat session: \(error.localizedDescription)", type: .error)
                self.isPresentingChat = false
                self.show() // Show the button again
                
                // Show error alert
                self.showErrorAlert(message: "Chat initialization failed. Please try again later.", on: topVC)
            }
        }
    }
    
    private func presentChatInterfaceSafely(with session: ChatSession, from presenter: UIViewController) {
        // Create chat view controller with the session
        let chatVC = ChatViewController(session: session)
        
        // Ensure we have a valid dismissal handler
        chatVC.dismissHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.isPresentingChat = false
                self?.show() // Show the button again
            }
        }
        
        // Wrap in navigation controller for better presentation
        let navController = UINavigationController(rootViewController: chatVC)
        
        // Configure presentation style based on device
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad-specific presentation
            navController.modalPresentationStyle = .formSheet
            navController.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            // iPhone presentation
            if #available(iOS 15.0, *) {
                if let sheet = navController.sheetPresentationController {
                    // Use sheet presentation for iOS 15+
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                    sheet.preferredCornerRadius = 24
                    
                    // Add delegate to handle dismissal properly
                    sheet.delegate = chatVC as? UISheetPresentationControllerDelegate
                }
            } else {
                // Fallback for older iOS versions
                navController.modalPresentationStyle = .fullScreen
            }
        }
        
        // Ensure safe presentation
        self.presentViewControllerSafely(navController, from: presenter)
    }
    
    private func presentViewControllerSafely(_ viewController: UIViewController, from presenter: UIViewController) {
        // Handle pending dismissals of any currently presented view controller
        if let presentedVC = presenter.presentedViewController {
            // If there's already a presented VC, dismiss it first
            presentedVC.dismiss(animated: true) { [weak self, weak presenter, weak viewController] in
                guard let self = self, 
                      let presenter = presenter,
                      let viewController = viewController,
                      !presenter.isBeingDismissed else {
                    self?.isPresentingChat = false
                    self?.show()
                    return
                }
                
                // Now present the chat interface
                self.performPresentation(viewController, from: presenter)
            }
        } else {
            // No existing presentation, present directly
            performPresentation(viewController, from: presenter)
        }
    }
    
    private func performPresentation(_ viewController: UIViewController, from presenter: UIViewController) {
        presenter.present(viewController, animated: true) { [weak self] in
            // Log success
            Debug.shared.log(message: "AI assistant presented successfully", type: .info)
        }
    }
    
    private func showErrorAlert(message: String, on viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Chat Error",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Ensure button is shown after alert dismissal
            self?.show()
        })
        
        // Present alert with a slight delay to ensure any pending transitions complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if viewController.presentedViewController == nil && !viewController.isBeingDismissed {
                viewController.present(alert, animated: true)
            } else {
                // If we can't present, at least log the error
                Debug.shared.log(message: "Could not present error alert: \(message)", type: .error)
                self.isPresentingChat = false
                self.show()
            }
        }
    }
}
