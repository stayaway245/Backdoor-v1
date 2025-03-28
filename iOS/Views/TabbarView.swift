import SwiftUI

/// Main TabView providing navigation between app sections
struct TabbarView: View {
    // State for the selected tab, initialized from UserDefaults
    @State private var selectedTab: Tab = Tab(rawValue: UserDefaults.standard.string(forKey: "selectedTab") ?? "home") ?? .home
    
    // Tab identifiers
    enum Tab: String, CaseIterable {
        case home
        case sources
        case library
        case settings
        case bdgHub
        
        var displayName: String {
            switch self {
            case .home: return String.localized("TAB_HOME")
            case .sources: return String.localized("TAB_SOURCES")
            case .library: return String.localized("TAB_LIBRARY")
            case .settings: return String.localized("TAB_SETTINGS")
            case .bdgHub: return "BDG HUB"
            }
        }
        
        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .sources:
                if #available(iOS 16.0, *) {
                    return "globe.desk.fill"
                } else {
                    return "books.vertical.fill"
                }
            case .library: return "square.grid.2x2.fill"
            case .settings: return "gearshape.2.fill"
            case .bdgHub: return "star.fill"
            }
        }
    }

    // Initialize with notification observer for tab changes
    init() {
        // Register for tab change notifications
        NotificationCenter.default.addObserver(
            forName: .changeTab,
            object: nil,
            queue: .main
        ) { [self] notification in
            handleTabChangeNotification(notification)
        }
    }
    
    // Handle tab change notification from other parts of the app
    private func handleTabChangeNotification(_ notification: Notification) {
        if let newTab = notification.userInfo?["tab"] as? String,
           let tab = Tab(rawValue: newTab) {
            // Update tab with animation
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
            // Save selection to UserDefaults
            UserDefaults.standard.set(tab.rawValue, forKey: "selectedTab")
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tabCase in
                tabView(for: tabCase)
                    .tag(tabCase)
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Save the selected tab to UserDefaults
            UserDefaults.standard.set(newTab.rawValue, forKey: "selectedTab")
            
            // Trigger animation for tab change
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.4)) {
                // Provide feedback for tab change
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Notify that tab has changed (for other components to react)
                NotificationCenter.default.post(
                    name: .tabDidChange,
                    object: nil,
                    userInfo: ["tab": newTab.rawValue]
                )
            }
        }
        .onAppear {
            // Ensure the app is responsive on appear
            UIApplication.shared.topMostViewController()?.view.isUserInteractionEnabled = true
        }
    }

    @ViewBuilder
    private func tabView(for tab: Tab) -> some View {
        switch tab {
        case .home:
            createTab(
                viewController: HomeViewController.self,
                title: tab.displayName,
                imageName: tab.iconName
            )
        case .sources:
            createTab(
                viewController: SourcesViewController.self,
                title: tab.displayName,
                imageName: tab.iconName
            )
        case .library:
            createTab(
                viewController: LibraryViewController.self,
                title: tab.displayName,
                imageName: tab.iconName
            )
        case .settings:
            createTab(
                viewController: SettingsViewController.self,
                title: tab.displayName,
                imageName: tab.iconName
            )
        case .bdgHub:
            createTab(
                viewController: WebViewController.self,
                title: tab.displayName,
                imageName: tab.iconName
            )
        }
    }
    
    @ViewBuilder
    private func createTab<T: UIViewController>(
        viewController: T.Type,
        title: String,
        imageName: String
    ) -> some View {
        NavigationViewController(viewController, title: title)
            .edgesIgnoringSafeArea(.all)
            .tabItem {
                Label(title, systemImage: imageName)
            }
    }
}

/// Extension to add an additional notification for post-tab change events
extension Notification.Name {
    static let tabDidChange = Notification.Name("tabDidChange")
}

/// SwiftUI wrapper for UIKit view controllers
struct NavigationViewController<Content: UIViewController>: UIViewControllerRepresentable {
    let content: Content.Type
    let title: String

    init(_ content: Content.Type, title: String) {
        self.content = content
        self.title = title
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = content.init()
        viewController.navigationItem.title = title
        
        // Ensure user interaction is enabled
        viewController.view.isUserInteractionEnabled = true
        
        let navController = UINavigationController(rootViewController: viewController)
        
        // Ensure navigation controller is interactive
        navController.view.isUserInteractionEnabled = true
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Ensure the view controller remains responsive
        uiViewController.view.isUserInteractionEnabled = true
        uiViewController.topViewController?.view.isUserInteractionEnabled = true
    }
}