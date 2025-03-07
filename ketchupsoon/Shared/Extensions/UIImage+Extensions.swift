// using in redesigned version of ketchupsoon

import UIKit

// Extension to add utility methods to UIImage
extension UIImage {
    /// Resizes an image to the specified size while maintaining aspect ratio
    /// - Parameter size: The target size for the resized image
    /// - Returns: A new UIImage resized to the specified dimensions, or nil if resizing fails
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 