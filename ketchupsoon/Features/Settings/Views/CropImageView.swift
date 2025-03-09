import SwiftUI
import UIKit
import TOCropViewController

struct CropImageView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onCrop: (UIImage) -> Void
    var onCancel: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> TOCropViewController {
        // Ensure we have an image, otherwise create a dummy
        let imageToCrop = image ?? UIImage()
        let cropVC = TOCropViewController(image: imageToCrop)
        cropVC.delegate = context.coordinator
        return cropVC
    }
    
    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, TOCropViewControllerDelegate {
        var parent: CropImageView
        
        init(_ parent: CropImageView) {
            self.parent = parent
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onCrop(image)
            cropViewController.dismiss(animated: true, completion: nil)
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            parent.onCancel()
            cropViewController.dismiss(animated: true, completion: nil)
        }
    }
} 
