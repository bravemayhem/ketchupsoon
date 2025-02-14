import SwiftUI
import MessageUI

struct SMSCalendarLinkView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let recipient: String
    let message: String
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = [recipient]
        controller.body = message
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: SMSCalendarLinkView
        
        init(parent: SMSCalendarLinkView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.dismiss()
        }
    }
    
    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }
} 