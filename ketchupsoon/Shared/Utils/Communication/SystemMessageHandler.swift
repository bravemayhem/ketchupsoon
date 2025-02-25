import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    let recipient: String
    let message: String?
    @Environment(\.dismiss) private var dismiss
    
    init(recipient: String, message: String? = nil) {
        self.recipient = recipient
        self.message = message
    }
    
    static func canSendMessages() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        
        if !MFMessageComposeViewController.canSendText() {
            DispatchQueue.main.async {
                self.dismiss()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let viewController = windowScene.windows.first?.rootViewController {
                    let alertController = UIAlertController(
                        title: "Cannot Send Message",
                        message: "Message capability not available on this device",
                        preferredStyle: .alert
                    )
                    alertController.addAction(UIAlertAction(title: "OK", style: .default))
                    viewController.present(alertController, animated: true)
                }
            }
        } else {
            controller.recipients = [recipient]
            if let message = message {
                controller.body = message
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
            super.init()
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            DispatchQueue.main.async {
                self.parent.dismiss()
            }
        }
    }
} 