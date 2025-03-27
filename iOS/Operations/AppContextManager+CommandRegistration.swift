import UIKit
import CoreData
import SwiftUI

// MARK: - Command Registration Extension for AppContextManager
extension AppContextManager {
    
    /// Registers all available commands with the AI assistant
    func registerAllCommands() {
        // Navigation commands
        registerCommand("navigate to") { [weak self] screen, completion in
            guard let self = self else { completion("System error"); return }
            self.navigateToScreen(screen, completion: completion)
        }
        
        // Source management commands
        registerCommand("add source") { [weak self] sourceURL, completion in
            guard let self = self else { completion("System error"); return }
            self.addSource(sourceURL, completion: completion)
        }
        
        registerCommand("list sources") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.listSources(completion: completion)
        }
        
        registerCommand("refresh sources") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.refreshSources(completion: completion)
        }
        
        // App and library management
        registerCommand("download app") { [weak self] appInfo, completion in
            guard let self = self else { completion("System error"); return }
            self.downloadApp(appInfo, completion: completion)
        }
        
        registerCommand("sign app") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.signApp(appName, completion: completion)
        }
        
        registerCommand("install app") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.installApp(appName, completion: completion)
        }
        
        registerCommand("list downloaded apps") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.listDownloadedApps(completion: completion)
        }
        
        registerCommand("list signed apps") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.listSignedApps(completion: completion)
        }
        
        registerCommand("delete app") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.deleteApp(appName, completion: completion)
        }
        
        // Certificate management
        registerCommand("list certificates") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.listCertificates(completion: completion)
        }
        
        registerCommand("select certificate") { [weak self] certName, completion in
            guard let self = self else { completion("System error"); return }
            self.selectCertificate(certName, completion: completion)
        }
        
        registerCommand("import certificate") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.importCertificate(completion: completion)
        }
        
        // Settings management
        registerCommand("change theme") { [weak self] theme, completion in
            guard let self = self else { completion("System error"); return }
            self.changeTheme(theme, completion: completion)
        }
        
        registerCommand("toggle setting") { [weak self] setting, completion in
            guard let self = self else { completion("System error"); return }
            self.toggleSetting(setting, completion: completion)
        }
        
        registerCommand("get app info") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.getAppInfo(appName, completion: completion)
        }
        
        // Advanced operations
        registerCommand("resign app") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.resignApp(appName, completion: completion)
        }
        
        registerCommand("add tweak") { [weak self] tweakInfo, completion in
            guard let self = self else { completion("System error"); return }
            self.addTweak(tweakInfo, completion: completion)
        }
        
        registerCommand("modify bundle id") { [weak self] bundleIdInfo, completion in
            guard let self = self else { completion("System error"); return }
            self.modifyBundleId(bundleIdInfo, completion: completion)
        }
        
        registerCommand("get app status") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            self.getAppStatus(completion: completion)
        }
        
        registerCommand("open app") { [weak self] appName, completion in
            guard let self = self else { completion("System error"); return }
            self.openApp(appName, completion: completion)
        }
        
        // Help commands
        registerCommand("help") { [weak self] topic, completion in
            guard let self = self else { completion("System error"); return }
            self.provideHelp(topic, completion: completion)
        }
        
        registerCommand("list commands") { [weak self] _, completion in
            guard let self = self else { completion("System error"); return }
            let commands = self.availableCommands().joined(separator: "\n")
            completion("Available commands:\n\(commands)")
        }
    }
}
