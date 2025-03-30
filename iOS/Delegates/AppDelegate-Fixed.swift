// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import BackgroundTasks
import CoreData
import CoreTelephony
import Foundation
import Nuke
import SwiftUI
import SystemConfiguration
import UIKit
import UIOnboarding

class AppDelegate: UIResponder, UIApplicationDelegate, UIOnboardingViewControllerDelegate {
    static let isSideloaded = Bundle.main.bundleIdentifier != "com.bdg.backdoor"
    var window: UIWindow?
    
    // Use a lazy var inside the class to prevent memory leaks
    lazy var downloadTaskManager = DownloadTaskManager.shared

    // Track app state to prevent issues during background/foreground transitions
    private var isInBackground = false
    private var isShowingStartupPopup = false

    private let webhookURL = "https://webhookbeam.com/webhook/7tmrv78pwn/backdoor-logs"
    private let hasSentWebhookKey = "HasSentWebhook"
    
    // Add a dedicated queue for background operations
    private let backgroundQueue = DispatchQueue(label: "com.backdoor.AppDelegate.BackgroundQueue", qos: .utility)

    // MARK: - Static Method for Documents Directory

    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up initial preferences and user defaults
        setupUserDefaultsAndPreferences()

        // Set up directories and clean temporary files
        createSourcesDirectory()
        setupLogFile()
        cleanTmp()

        // Create window once
        if window == nil {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        // Set up the UI
        setupWindow()

        // Log device information
        logDeviceInfo()

        // Set up background tasks if enabled
        setupBackgroundTasks()

        // Initialize performance optimizations
        integratePerformanceOptimizations()

        // Initialize other components - do this after UI is set up
        // so if there are any issues, the app still launches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.initializeSecondaryComponents()

            // Show startup popup after components are initialized
            self?.showAppropriateStartupScreen()
        }

        return true
    }
}