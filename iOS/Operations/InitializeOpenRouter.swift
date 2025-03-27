//
//  InitializeOpenRouter.swift
//  feather
//
//  Created on 3/27/25.
//  Copyright (c) 2025
//

import Foundation
import UIKit

/// Class to handle the initialization of OpenRouter API key
final class InitializeOpenRouter {
    static let shared = InitializeOpenRouter()
    
    private init() {}
    
    /// Sets up the OpenRouter API key when the app first launches or is updated
    func setupInitialAPIKey() {
        // Check if we've already set up the API key
        let initializationKey = "openrouter_api_initialized"
        let isInitialized = UserDefaults.standard.bool(forKey: initializationKey)
        
        if !isInitialized {
            // Initialize with the provided API key
            let initialKey = "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"
            
            do {
                try KeychainManager.shared.saveString(initialKey, forKey: "openrouter_api_key")
                OpenRouterService.shared.updateAPIKey(initialKey)
                
                // Mark as initialized to avoid re-setting on every launch
                UserDefaults.standard.set(true, forKey: initializationKey)
                
                Debug.shared.log(message: "OpenRouter API key initialized successfully", type: .success)
                
                // Show a one-time notification about the new AI service
                DispatchQueue.main.async {
                    self.showServiceTransitionAlert()
                }
            } catch {
                Debug.shared.log(message: "Failed to initialize OpenRouter API key: \(error)", type: .error)
            }
        }
    }
    
    /// Shows a one-time alert to inform users about the transition to OpenRouter
    private func showServiceTransitionAlert() {
        let alertKey = "openrouter_transition_alert_shown"
        let alertShown = UserDefaults.standard.bool(forKey: alertKey)
        
        guard !alertShown else { return }
        
        let keyWindow = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        if let rootViewController = keyWindow?.rootViewController {
            let alert = UIAlertController(
                title: "AI Assistant Updated",
                message: "Feather now uses OpenRouter for AI assistant capabilities. Your API key has been configured automatically.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            rootViewController.present(alert, animated: true)
            
            UserDefaults.standard.set(true, forKey: alertKey)
        }
    }
}
