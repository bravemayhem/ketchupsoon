import SwiftUI
import ContactsUI
import SwiftData

struct ContactViewController: UIViewControllerRepresentable {
    let contactIdentifier: String
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    func makeCoordinator() -> Coordinator {
        print("DEBUG: Creating coordinator")
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UINavigationController {
        print("DEBUG: makeUIViewController called")
        let navController = UINavigationController()
        navController.modalPresentationStyle = .pageSheet
        navController.isModalInPresentation = true
        
        if let sheet = navController.sheetPresentationController {
            print("DEBUG: Configuring initial sheet presentation")
            sheet.prefersGrabberVisible = true
            sheet.detents = [.large()]
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = 12
        }
        
        // Add a loading view controller initially
        let loadingVC = UIHostingController(rootView: 
            ProgressView("Loading Contact...")
                .progressViewStyle(.circular)
        )
        navController.setViewControllers([loadingVC], animated: false)
        
        // Load contact after ensuring view is ready
        Task { @MainActor in
            // Small delay to ensure view hierarchy is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if context.coordinator.isLoadingContact == false {
                loadContact(into: navController, context: context)
            }
        }
        
        return navController
    }
    
    private func loadContact(into navController: UINavigationController, context: Context) {
        // Prevent multiple simultaneous loads
        guard !context.coordinator.isLoadingContact else {
            print("DEBUG: Already loading contact, skipping")
            return
        }
        
        context.coordinator.isLoadingContact = true
        
        Task {
            do {
                print("DEBUG: Requesting contacts access")
                let granted = await ContactsManager.shared.requestAccess()
                guard granted else {
                    print("DEBUG: Contacts access denied")
                    await MainActor.run {
                        context.coordinator.isLoadingContact = false
                        context.coordinator.showAlert(
                            title: "Contacts Access Required",
                            message: "Please enable contacts access in Settings to view contact details."
                        ) {
                            self.isPresented = false
                        }
                    }
                    return
                }
                
                print("DEBUG: Fetching contact for identifier: \(contactIdentifier)")
                let contact = try await ContactsManager.shared.getContactViewController(for: contactIdentifier)
                
                await MainActor.run {
                    guard isPresented else {
                        context.coordinator.isLoadingContact = false
                        return
                    }
                    
                    print("DEBUG: Setting up CNContactViewController")
                    let contactVC = CNContactViewController(for: contact)
                    contactVC.allowsEditing = true
                    contactVC.allowsActions = true
                    contactVC.delegate = context.coordinator
                    
                    context.coordinator.contactIdentifier = contactIdentifier
                    
                    // Only set view controllers if we're still meant to be presented
                    if isPresented {
                        print("DEBUG: Setting view controllers")
                        // Use animated: false to prevent potential race conditions
                        navController.setViewControllers([contactVC], animated: false)
                    }
                    
                    context.coordinator.isLoadingContact = false
                }
            } catch {
                print("DEBUG: Error loading contact: \(error.localizedDescription)")
                await MainActor.run {
                    context.coordinator.isLoadingContact = false
                    context.coordinator.showAlert(
                        title: "Error Loading Contact",
                        message: error.localizedDescription
                    ) {
                        self.isPresented = false
                    }
                }
            }
        }
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        print("DEBUG: updateUIViewController called, isPresented: \(isPresented)")
        
        if !isPresented && uiViewController.presentedViewController != nil {
            print("DEBUG: Dismissing view controller due to isPresented = false")
            context.coordinator.cleanupPresentation()
            
            Task { @MainActor in
                uiViewController.dismiss(animated: true)
            }
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
        print("DEBUG: Dismantling view controller")
        coordinator.cleanupPresentation()
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactViewController
        var contactIdentifier: String?
        var isLoadingContact = false
        
        init(parent: ContactViewController) {
            print("DEBUG: Initializing coordinator")
            self.parent = parent
            super.init()
        }
        
        func cleanupPresentation() {
            print("DEBUG: Cleaning up presentation, clearing contactIdentifier")
            contactIdentifier = nil
            isLoadingContact = false
        }
        
        func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
            Task { @MainActor in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let viewController = windowScene.windows.first?.rootViewController {
                    let alert = UIAlertController(
                        title: title,
                        message: message,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        completion?()
                    })
                    viewController.present(alert, animated: true)
                } else {
                    completion?()
                }
            }
        }
        
        // MARK: - CNContactViewControllerDelegate
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            print("DEBUG: Contact view controller did complete, contact: \(contact != nil)")
            Task { @MainActor in
                if let identifier = contactIdentifier,
                   let friend = try? parent.modelContext.fetch(FetchDescriptor<Friend>(
                    predicate: #Predicate<Friend> { friend in
                        friend.contactIdentifier == identifier
                    }
                   )).first {
                    if await ContactsManager.shared.handleContactChange(for: friend) {
                        print("DEBUG: Successfully synced contact info for \(friend.name)")
                    } else {
                        print("DEBUG: Failed to sync contact info for \(friend.name)")
                        showAlert(
                            title: "Sync Error",
                            message: "Failed to sync contact information. Please try again."
                        )
                    }
                }
                
                print("DEBUG: Setting isPresented to false and cleaning up")
                parent.isPresented = false
                cleanupPresentation()
            }
        }
        
        func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
            print("DEBUG: Should perform default action for property: \(property.key)")
            return true
        }
        
        func contactViewController(_ viewController: CNContactViewController, shouldShowLinkedContacts contact: CNContact) -> Bool {
            print("DEBUG: Should show linked contacts")
            return true
        }
    }
}

#Preview {
    Text("Contact View Controller Preview")
        .sheet(isPresented: .constant(true)) {
            ContactViewController(
                contactIdentifier: "example-id",
                isPresented: .constant(true)
            )
        }
        .modelContainer(for: [Friend.self])
} 
