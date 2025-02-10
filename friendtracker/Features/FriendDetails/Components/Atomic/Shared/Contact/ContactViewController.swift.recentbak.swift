/*
import SwiftUI
import ContactsUI
import SwiftData


struct ContactView: View {
    // Static presentation tracking
    private static var isCurrentlyPresenting = false
    
    let contactIdentifier: String
    let position: String
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var contactsManager = ContactsManager.shared
    @State private var contact: CNContact?
    @State private var error: String?
    @State private var isLoading = true
    @State private var hasLoadedContact = false
    @State private var delegate: ContactViewDelegate? // Store strong reference to delegate
    
    var body: some View {
        Group {
            if isLoading {
                ZStack {
                    Color.clear
                    ProgressView("Loading contact...")
                        .foregroundColor(.secondary)
                }
            } else if let error = error {
                Text(error)
                    .foregroundColor(.red)
            } else if contact != nil {
                Color.clear
            }
        }
        .task {
            print("👁 [Position: \(position)] ContactView task started")
            guard !ContactView.isCurrentlyPresenting else {
                print("👁 [Position: \(position)] Another presentation is in progress, dismissing")
                isPresented = false
                return
            }
            guard !hasLoadedContact else {
                print("👁 [Position: \(position)] Contact already loaded, skipping")
                return
            }
            await loadAndPresentContact()
        }
        .onDisappear {
            print("👁 [Position: \(position)] ContactView disappeared")
            ContactView.isCurrentlyPresenting = false
            delegate = nil // Clean up delegate reference
        }
    }
    
    private func loadAndPresentContact() async {
        guard !hasLoadedContact else {
            print("👁 [Position: \(position)] Prevented duplicate contact load")
            return
        }
        hasLoadedContact = true
        ContactView.isCurrentlyPresenting = true
        print("👁 [Position: \(position)] Starting contact load")
        
        do {
            let granted = await contactsManager.requestAccess()
            print("👁 [Position: \(position)] Access granted: \(granted)")
            if granted {
                contact = try await contactsManager.getContactViewController(for: contactIdentifier)
                print("👁 [Position: \(position)] Contact loaded successfully")
                await presentContact(contact!)
            } else {
                error = "Contact access not granted"
                isPresented = false
                ContactView.isCurrentlyPresenting = false
            }
        } catch {
            print("👁 [Position: \(position)] Error loading contact: \(error)")
            self.error = error.localizedDescription
            isPresented = false
            ContactView.isCurrentlyPresenting = false
        }
        isLoading = false
    }
    
    private func presentContact(_ contact: CNContact) async {
        print("👁 [Position: \(position)] Attempting to present contact")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            print("👁 [Position: \(position)] Failed to find root view controller")
            error = "Could not present contact"
            isPresented = false
            ContactView.isCurrentlyPresenting = false
            return
        }
        
        let contactVC = CNContactViewController(for: contact)
        contactVC.allowsEditing = true
        contactVC.allowsActions = true
        
        // Create and store delegate
        delegate = ContactViewDelegate(onDismiss: {
            print("👁 [Position: \(position)] Contact view controller dismissed")
            isPresented = false
            ContactView.isCurrentlyPresenting = false
        })
        contactVC.delegate = delegate
        
        let navigationController = UINavigationController(rootViewController: contactVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: delegate,
            action: #selector(ContactViewDelegate.dismissContact)
        )
        
        print("👁 [Position: \(position)] About to present contact view controller")
        await MainActor.run {
            rootVC.dismiss(animated: false) {
                rootVC.present(navigationController, animated: true) {
                    print("👁 [Position: \(position)] Contact view controller presented")
                }
            }
        }
    }
}

class ContactViewDelegate: NSObject, CNContactViewControllerDelegate {
    let onDismiss: () -> Void
    
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init()
    }
    
    @objc func dismissContact() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.dismiss(animated: true) {
                self.onDismiss()
            }
        } else {
            onDismiss()
        }
    }
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.dismiss(animated: true) {
                self.onDismiss()
            }
        } else {
            onDismiss()
        }
    }
}

#Preview {
    Text("Contact View Preview")
        .sheet(isPresented: .constant(true)) {
            ContactView(
                contactIdentifier: "example-id",
                position: "preview",
                isPresented: .constant(true)
            )
        }
        .modelContainer(for: [Friend.self])
} 


*/
