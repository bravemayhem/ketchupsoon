/*
import SwiftUI
import ContactsUI
import SwiftData

/*
// Coordinator class to handle UIKit interactions
private class ContactViewCoordinator: NSObject {
    var parent: ContactView
    var isPresenting = false
    
    init(parent: ContactView) {
        self.parent = parent
        super.init()
        print("👁 Debug: Coordinator initialized")
    }
    
    @objc func dismissContact() {
        print("👁 Debug: Dismissing contact")
        isPresenting = false
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        let rootVC = window?.rootViewController
        rootVC?.dismiss(animated: true)
        parent.isPresented = false
    }
    
    func presentContact(_ contact: CNContact) {
        guard !isPresenting else {
            print("👁 Debug: Already presenting, skipping")
            return
        }
        
        print("👁 Debug: Attempting to present contact")
        isPresenting = true
        
        let contactVC = CNContactViewController(for: contact)
        contactVC.delegate = self
        contactVC.allowsEditing = true
        contactVC.allowsActions = true
        
        let navigationController = UINavigationController(rootViewController: contactVC)
        navigationController.modalPresentationStyle = .fullScreen
        
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissContact)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self, self.isPresenting else { return }
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                print("👁 Debug: Found root view controller, presenting")
                rootVC.present(navigationController, animated: true) {
                    print("👁 Debug: Contact view presented")
                }
            } else {
                print("👁 Debug: Failed to find root view controller")
                self.isPresenting = false
            }
        }
    }
}

extension ContactViewCoordinator: CNContactViewControllerDelegate {
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        print("👁 Debug: Contact view controller did complete")
        dismissContact()
    }
}
*/

/*
struct ContactView: UIViewControllerRepresentable {
    let contactIdentifier: String
    @Binding var isPresented: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        // Start with an empty navigation controller
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        
        // Load the contact asynchronously
        Task {
            do {
                let contact = try await ContactsManager.shared.getContactViewController(for: contactIdentifier)
                await MainActor.run {
                    let contactVC = CNContactViewController(for: contact)
                    contactVC.delegate = context.coordinator
                    contactVC.allowsEditing = true
                    contactVC.allowsActions = true
                    
                    contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
                        barButtonSystemItem: .done,
                        target: context.coordinator,
                        action: #selector(Coordinator.dismissContact)
                    )
                    
                    navigationController.setViewControllers([contactVC], animated: false)
                }
            } catch {
                print("👁 Error loading contact: \(error)")
                isPresented = false
            }
        }
        
        return navigationController
    }
    
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        // Handle any updates if needed
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        var parent: ContactView
        
        init(_ parent: ContactView) {
            self.parent = parent
        }
        
        @objc func dismissContact() {
            parent.isPresented = false
        }
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            parent.isPresented = false
        }
    }
}
*/

// Temporary empty view for testing
struct ContactView: View {
    let contactIdentifier: String
    @Binding var isPresented: Bool
    
    var body: some View {
        Color.clear
            .onAppear {
                print("👁 Debug: Empty ContactView appeared")
            }
            .onDisappear {
                print("👁 Debug: Empty ContactView disappeared")
            }
    }
}

// Public interface - now we can use it directly in a sheet
extension View {
    func contactSheet(identifier: String, isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            ContactView(
                contactIdentifier: identifier,
                isPresented: isPresented
            )
        }
    }
}

#Preview {
    Text("Contact View Preview")
        .contactSheet(identifier: "example-id", isPresented: .constant(true))
}
*/ 
