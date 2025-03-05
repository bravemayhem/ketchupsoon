import UIKit
import SwiftUI

// MARK: - UIApplication Extensions

extension UIApplication {
    /// Returns the root view controller of the key window
    var rootController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
} 