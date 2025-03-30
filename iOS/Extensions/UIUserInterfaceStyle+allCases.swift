import UIKit

extension UIUserInterfaceStyle: @retroactive CaseIterable {
    public static var allCases: [UIUserInterfaceStyle] = [.unspecified, .dark, .light]
    var description: String {
        switch self {
            case .unspecified:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            @unknown default:
                return "Unknown Mode"
        }
    }
}
