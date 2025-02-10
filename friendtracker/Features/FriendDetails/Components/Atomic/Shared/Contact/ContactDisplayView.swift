import SwiftUI
import ContactsUI
import SwiftData

struct ContactDisplayView: View {
    let contactIdentifier: String
    let position: String
    @Binding var isPresented: Bool
    @State private var contact: CNContact?
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let contact = contact {
                ContactView(
                    contact: contact,
                    position: position,
                    isPresented: $isPresented
                )
            } else if let errorMessage = errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                    Button("Dismiss") {
                        isPresented = false
                    }
                }
            } else {
                ProgressView("Loading contact...")
            }
        }
        .task {
            do {
                contact = try await ContactsManager.shared.getContactViewController(for: contactIdentifier)
            } catch ContactsManager.ContactError.contactNotFound {
                errorMessage = "Contact not found in your address book"
            } catch ContactsManager.ContactError.accessDenied {
                errorMessage = "Access to contacts was denied"
            } catch {
                errorMessage = "Failed to load contact: \(error.localizedDescription)"
            }
        }
    }
}
