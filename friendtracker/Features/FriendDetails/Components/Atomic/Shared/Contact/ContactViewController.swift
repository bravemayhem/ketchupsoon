import SwiftUI
import ContactsUI
import SwiftData


struct ContactView: UIViewControllerRepresentable {
    let contactIdentifier: String
    let friend: Friend
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
            // Sync contact changes back to our Friend model
            if contact != nil {
                Task {
                    await ContactsManager.shared.handleContactChange(for: parent.friend)
                }
            }
            parent.isPresented = false
        }
    }
}

#Preview {
    Text("Contact View Preview")
        .contactSheet(
            identifier: "example-id",
            friend: Friend(name: "Test Friend"),
            isPresented: .constant(true)
        )
}

extension View {
    func contactSheet(identifier: String, friend: Friend, isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            ContactView(
                contactIdentifier: identifier,
                friend: friend,
                isPresented: isPresented
            )
        }
    }
}


