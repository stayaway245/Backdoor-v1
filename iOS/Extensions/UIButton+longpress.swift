import Foundation
import UIKit

extension UIButton {
    private enum AssociatedKeys {
        static var longPressGestureRecognizer = "longPressGestureRecognizer"
    }

    var longPressGestureRecognizer: UILongPressGestureRecognizer? {
        get {
            withUnsafePointer(to: AssociatedKeys.longPressGestureRecognizer) {
                objc_getAssociatedObject(self, $0) as? UILongPressGestureRecognizer
            }
        }
        set {
            withUnsafePointer(to: AssociatedKeys.longPressGestureRecognizer) {
                objc_setAssociatedObject(self, $0, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
