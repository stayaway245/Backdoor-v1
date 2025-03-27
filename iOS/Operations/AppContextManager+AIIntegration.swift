import UIKit
import CoreData
import SwiftUI

// MARK: - AI Integration Extension for AppContextManager
extension AppContextManager {
    
    /// Initialize AI integration - call this at app startup
    func setupAIIntegration() {
        // Register all available commands
        registerAllCommands()
        
        // Setup observers for context updates
        setupContextObservers()
        
        Debug.shared.log(message: "AI Assistant integration initialized with \(availableCommands().count) commands", type: .info)
    }
    
    /// Setup context observation to keep AI updated with app state
    private func setupContextObservers() {
        // Observe tab changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabChange(_:)),
            name: .changeTab,
            object: nil
        )
        
        // Observe app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appEnteredForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Observe certificate changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(certificatesUpdated),
            name: Notification.Name("CertificatesUpdated"),
            object: nil
        )
        
        // Observe library changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(libraryUpdated),
            name: Notification.Name("lfetch"),
            object: nil
        )
    }
    
    @objc private func handleTabChange(_ notification: Notification) {
        if let newTab = notification.userInfo?["tab"] as? String {
            var screenName: String
            switch newTab {
            case "home": screenName = "Home"
            case "sources": screenName = "Sources"
            case "library": screenName = "Library"
            case "settings": screenName = "Settings"
            case "bdgHub": screenName = "BDG Hub"
            default: screenName = "Unknown"
            }
            
            // Update AI context with new screen
            let additionalData: [String: Any] = ["currentScreen": screenName]
            setAdditionalContextData(additionalData)
            
            Debug.shared.log(message: "AI context updated: Screen changed to \(screenName)", type: .debug)
        }
    }
    
    @objc private func appEnteredForeground() {
        // Refresh context when app becomes active
        if let topVC = UIApplication.shared.topMostViewController() {
            updateContext(topVC)
            Debug.shared.log(message: "AI context refreshed after app became active", type: .debug)
        }
    }
    
    @objc private func certificatesUpdated() {
        // Update AI context with new certificate information
        let certificates = CoreDataManager.shared.getDatedCertificate()
        let currentCert = CoreDataManager.shared.getCurrentCertificate()
        
        let additionalData: [String: Any] = [
            "certificates": certificates.map { $0.certData?.name ?? "Unnamed" },
            "currentCertificate": currentCert?.certData?.name ?? "None"
        ]
        
        setAdditionalContextData(additionalData)
        Debug.shared.log(message: "AI context updated: Certificate information refreshed", type: .debug)
    }
    
    @objc private func libraryUpdated() {
        // Update AI context with library information
        let downloadedApps = CoreDataManager.shared.getDatedDownloadedApps()
        let signedApps = CoreDataManager.shared.getDatedSignedApps()
        
        let additionalData: [String: Any] = [
            "downloadedApps": downloadedApps.map { AppInfo(name: $0.name ?? "Unnamed", version: $0.version ?? "Unknown").description },
            "signedApps": signedApps.map { SignedAppInfo(name: $0.name ?? "Unnamed", bundleIdentifier: $0.bundleidentifier ?? "Unknown", teamName: $0.teamName ?? "N/A").description }
        ]
        
        setAdditionalContextData(additionalData)
        Debug.shared.log(message: "AI context updated: Library information refreshed", type: .debug)
    }
    
    /// Enhance context with natural language understanding capabilities
    func enhanceContextWithNLU(_ textInput: String) -> (intent: String, parameter: String)? {
        // A simple intent mapping system
        // In a real implementation, this could use more sophisticated NLU
        
        // Check for app signing intent
        if textInput.matches(pattern: "(?i)sign\\s+(the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$") {
            let appName = textInput.extractMatch(pattern: "(?i)sign\\s+(the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$", groupIndex: 2)
            return ("sign app", appName ?? "")
        }
        
        // Check for navigation intent
        if textInput.matches(pattern: "(?i)(?:go\\s+to|navigate\\s+to|open|show)\\s+(?:the\\s+)?(.+?)\\s+(?:tab|screen|page|section)") {
            let screen = textInput.extractMatch(pattern: "(?i)(?:go\\s+to|navigate\\s+to|open|show)\\s+(?:the\\s+)?(.+?)\\s+(?:tab|screen|page|section)", groupIndex: 1)
            return ("navigate to", screen ?? "")
        }
        
        // Check for source adding intent
        if textInput.matches(pattern: "(?i)add\\s+(?:a\\s+)?(?:new\\s+)?source\\s+(?:with\\s+url\\s+|at\\s+|from\\s+)?(.+?)\\s*$") {
            let url = textInput.extractMatch(pattern: "(?i)add\\s+(?:a\\s+)?(?:new\\s+)?source\\s+(?:with\\s+url\\s+|at\\s+|from\\s+)?(.+?)\\s*$", groupIndex: 1)
            return ("add source", url ?? "")
        }
        
        // Check for installing app intent
        if textInput.matches(pattern: "(?i)install\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$") {
            let appName = textInput.extractMatch(pattern: "(?i)install\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$", groupIndex: 1)
            return ("install app", appName ?? "")
        }
        
        // Check for opening app intent
        if textInput.matches(pattern: "(?i)open\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$") {
            let appName = textInput.extractMatch(pattern: "(?i)open\\s+(?:the\\s+)?app\\s+(?:called\\s+|named\\s+)?(.+?)\\s*$", groupIndex: 1)
            return ("open app", appName ?? "")
        }
        
        // If no intent matched
        return nil
    }
}

// Helper extensions for string pattern matching
extension String {
    func matches(pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(self.startIndex..., in: self)
            return regex.firstMatch(in: self, range: range) != nil
        } catch {
            return false
        }
    }
    
    func extractMatch(pattern: String, groupIndex: Int) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(self.startIndex..., in: self)
            if let match = regex.firstMatch(in: self, range: range) {
                if match.numberOfRanges > groupIndex {
                    let group = match.range(at: groupIndex)
                    if group.location != NSNotFound,
                       let groupRange = Range(group, in: self) {
                        return String(self[groupRange])
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}
