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
    
    // MARK: - Required delegate methods
    
    func didFinishOnboarding(onboardingViewController: UIOnboardingViewController) {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        Preferences.isOnboardingActive = false
        let tabBarController = UIHostingController(rootView: TabbarView())
        let transition = CATransition()
        transition.type = .fade
        transition.duration = 0.3
        window?.layer.add(transition, forKey: kCATransition)
        window?.rootViewController = tabBarController
        FloatingButtonManager.shared.show()
    }

    // MARK: - Setup Methods
    
    private func setupUserDefaultsAndPreferences() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, forKey: "currentVersion")
        if userDefaults.data(forKey: UserDefaults.signingDataKey) == nil {
            userDefaults.signingOptions = UserDefaults.defaultSigningData
        }

        let generatedString = AppDelegate.generateRandomString()
        if Preferences.pPQCheckString.isEmpty {
            Preferences.pPQCheckString = generatedString
        }
    }
    
    private func createSourcesDirectory() {
        let fileManager = FileManager.default
        let documentsURL = AppDelegate.getDocumentsDirectory()
        let sourcesURL = documentsURL.appendingPathComponent("Apps")
        let certsURL = documentsURL.appendingPathComponent("Certificates")
        if !fileManager.fileExists(atPath: sourcesURL.path) {
            try! fileManager.createDirectory(at: sourcesURL, withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: certsURL.path) {
            try! fileManager.createDirectory(at: certsURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func setupLogFile() {
        let logFilePath = AppDelegate.getDocumentsDirectory().appendingPathComponent("logs.txt")
        if FileManager.default.fileExists(atPath: logFilePath.path) {
            do {
                try FileManager.default.removeItem(at: logFilePath)
            } catch {
                Debug.shared.log(message: "Error removing existing logs.txt: \(error)", type: .error)
            }
        }
        do {
            try "".write(to: logFilePath, atomically: true, encoding: .utf8)
        } catch {
            Debug.shared.log(message: "Error removing existing logs.txt: \(error)", type: .error)
        }
    }
    
    private func cleanTmp() {
        let fileManager = FileManager.default
        let tmpDirectory = NSHomeDirectory() + "/tmp"
        if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory) {
            for file in files {
                try? fileManager.removeItem(atPath: tmpDirectory + "/" + file)
            }
        }
    }
    
    private func setupWindow() {
        // Ensure we don't recreate window if it exists
        guard window != nil else {
            Debug.shared.log(message: "Window is nil in setupWindow", type: .error)
            return
        }

        if Preferences.isOnboardingActive {
            // Don't show onboarding right away - will show it later in showAppropriateStartupScreen
            // Just set up the main UI for now
            setupMainUI()
        } else {
            setupMainUI()
        }

        DispatchQueue.main.async { [weak self] in
            self?.window?.tintColor = Preferences.appTintColor.uiColor
            self?.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: Preferences.preferredInterfaceStyle) ?? .unspecified
            self?.window?.makeKeyAndVisible()
        }
    }
    
    private func setupMainUI() {
        let tabBarController = UIHostingController(rootView: TabbarView())
        window?.rootViewController = tabBarController
    }
    
    private func logDeviceInfo() {
        Debug.shared.log(message: "Version: \(UIDevice.current.systemVersion)")
        Debug.shared.log(message: "Name: \(UIDevice.current.name)")
        Debug.shared.log(message: "Model: \(UIDevice.current.model)")
        Debug.shared.log(message: "Backdoor Version: \(logAppVersionInfo())\n")
    }
    
    private func logAppVersionInfo() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            return "App Version: \(version) (\(build))"
        }
        return ""
    }
    
    private func setupBackgroundTasks() {
        if Preferences.appUpdates {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "kh.crysalis.backdoor.sourcerefresh", using: nil) { [weak self] task in
                guard let self = self else { return }
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            scheduleAppRefresh()
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "kh.crysalis.backdoor.sourcerefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            Debug.shared.log(message: "Background refresh scheduled successfully", type: .info)
        } catch {
            Debug.shared.log(message: "Could not schedule app refresh: \(error.localizedDescription)", type: .info)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        let operation = SourceRefreshOperation()
        task.expirationHandler = { operation.cancel() }
        operation.completionBlock = { task.setTaskCompleted(success: !operation.isCancelled) }
        backgroundQueue.addOperation(operation)
    }
    
    func integratePerformanceOptimizations() {
        OptimizationIntegrator.shared.integrateOptimizations(in: UIApplication.shared)
    }
    
    private func initializeSecondaryComponents() {
        // Initialize image pipeline
        imagePipline()

        // Setup AI integration
        AppContextManager.shared.setupAIIntegration()

        // Show floating button only if not showing startup popup
        if !isShowingStartupPopup {
            FloatingButtonManager.shared.show()
        }

        // These operations are moved to background to avoid blocking app launch
        backgroundQueue.async { [weak self] in
            guard let self = self else { return }

            // Add default repositories if needed
            self.addDefaultRepos()

            // Download certificates if needed
            self.giveUserDefaultSSLCerts()

            // Send device info to webhook (with error handling)
            self.sendDeviceInfoToWebhook()

            // Refresh sources if needed
            if Preferences.appUpdates {
                let backgroundQueue = OperationQueue()
                backgroundQueue.qualityOfService = .background
                let operation = SourceRefreshOperation()
                backgroundQueue.addOperation(operation)
            }
        }
    }
    
    private func showAppropriateStartupScreen() {
        // Only show startup screens on fresh launch, not when returning from background
        if isInBackground {
            Debug.shared.log(message: "Returning from background, skipping startup screens", type: .info)
            return
        }

        // If this is a new version, we might want to show the popup again
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let savedVersion = UserDefaults.standard.string(forKey: "currentAppVersionKey") ?? ""
        let isNewVersion = currentVersion != savedVersion && !savedVersion.isEmpty

        // Only show one type of startup screen - prioritize onboarding if needed
        if Preferences.isOnboardingActive {
            showOnboardingScreen()
        } else if isNewVersion {
            // For version updates, we can optionally show a different popup or the same one
            UserDefaults.standard.set(false, forKey: "hasShownStartupPopupKey")
            UserDefaults.standard.set(currentVersion, forKey: "currentAppVersionKey")
            showStartupPopupIfNeeded()
        } else {
            showStartupPopupIfNeeded()
        }
    }
    
    private func showOnboardingScreen() {
        // Implementation placeholder
        Debug.shared.log(message: "Showing onboarding screen", type: .info)
    }
    
    private func showStartupPopupIfNeeded() {
        // Implementation placeholder
        Debug.shared.log(message: "Checking if startup popup needed", type: .info)
    }
    
    private func imagePipline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
                config.requestCachePolicy = .reloadIgnoringLocalCacheData
                config.timeoutIntervalForRequest = 15
                config.timeoutIntervalForResource = 30
                return DataLoader(configuration: config)
            }()
            let dataCache = try? DataCache(name: "kh.crysalis.backdoor.datacache")
            let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024
            imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache
            $0.imageCache = imageCache
            $0.dataLoader = dataLoader
            $0.dataCachePolicy = .automatic
            $0.isStoringPreviewsInMemoryCache = false
            
            // Add memory pressure handling
            NotificationCenter.default.addObserver(imageCache, selector: #selector(ImageCache.removeAllImages), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        }
        ImagePipeline.shared = pipeline
    }
    
    private func addDefaultRepos() {
        if !Preferences.defaultRepos {
            CoreDataManager.shared.saveSource(
                name: "Backdoor Repository",
                id: "com.bdg.backdoor-repo",
                iconURL: URL(string: "https://raw.githubusercontent.com/814bdg/App/refs/heads/main/Wing3x.png?raw=true"),
                url: "https://raw.githubusercontent.com/BDGHubNoKey/Backdoor/refs/heads/main/App-repo.json"
            ) { _ in
                Debug.shared.log(message: "Added default repos!")
                Preferences.defaultRepos = false
            }
        }
    }
    
    private func giveUserDefaultSSLCerts() {
        if !Preferences.gotSSLCerts {
            // Use the version with completion handler
            getCertificates {
                // Mark as obtained regardless of success to prevent repeated attempts
                DispatchQueue.main.async {
                    Preferences.gotSSLCerts = true
                }
            }
        }
    }
    
    private func getCertificates(completion: @escaping () -> Void) {
        // Implementation for certificate download
        Debug.shared.log(message: "Getting certificates", type: .info)
        completion()
    }
    
    private func sendDeviceInfoToWebhook() {
        // Implementation to send device info
        Debug.shared.log(message: "Sending device info to webhook", type: .info)
    }
    
    static func generateRandomString(length: Int = 8) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in characters.randomElement()! })
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