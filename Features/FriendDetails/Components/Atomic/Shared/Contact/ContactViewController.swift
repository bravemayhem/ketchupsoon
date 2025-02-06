import SwiftUI

struct ContactViewController: View {
    @StateObject private var viewModel = ContactViewModel()
    @State private var isPresented = false

    var body: some View {
        Text("Contact View Controller")
    }

    private func showAlert(title: String, message: String) {
        // Implementation of showAlert function
    }
}

struct ContactViewController_Previews: PreviewProvider {
    static var previews: some View {
        ContactViewController()
    }
}

class ContactViewModel: ObservableObject {
    func handleContactChange() {
        print("DEBUG: Contact view controller did complete, contact: \(viewModel.contact != nil)")
        Task { @MainActor in
            let contactID: String = parent.contactIdentifier
            if let friend = try? parent.modelContext.fetch(FetchDescriptor<Friend>(
                predicate: #Predicate<Friend> { (friend: Friend) in
                    friend.contactIdentifier == contactID
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
            } else {
                print("DEBUG: Friend not found for identifier: \(parent.contactIdentifier)")
                showAlert(title: "Error", message: "Friend not found.")
            }
            
            print("DEBUG: Setting isPresented to false")
            parent.isPresented = false
        }
    }

    private func showAlert(title: String, message: String) {
        // Implementation of showAlert function
    }
} 