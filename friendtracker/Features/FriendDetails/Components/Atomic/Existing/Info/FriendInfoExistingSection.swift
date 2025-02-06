// CURRENTLY USED FOR EXISTING FRIENDS

import SwiftUI
import SwiftData
import UIKit
import ContactsUI

private struct ContactSheetItem: Identifiable {
    let id: String
    var error: Error?
}

struct FriendInfoExistingSection: View {
    let friend: Friend
    @Bindable var cityService: CitySearchService
    @State private var editableName: String
    @State private var editablePhone: String
    @State private var editableEmail: String
    @State private var showingAddEmailAlert = false
    @State private var newEmailInput = ""
    @State private var isUpdatingContact = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var activeSheet: ActiveSheet?
    @State private var showingContactView = false
    @State private var presentedContactIdentifier: ContactSheetItem? = nil
    
    private enum ActiveSheet: Identifiable {
        case addEmail
        
        var id: Int {
            switch self {
            case .addEmail: return 2
            }
        }
    }
    
    init(friend: Friend, cityService: CitySearchService) {
        self.friend = friend
        self._cityService = Bindable(wrappedValue: cityService)
        self._editableName = State(initialValue: friend.name)
        self._editablePhone = State(initialValue: friend.phoneNumber ?? "")
        self._editableEmail = State(initialValue: friend.email ?? "")
    }
    
    var body: some View {
        Section("Friend Details") {
            // Name
            if friend.contactIdentifier != nil {
                Button {
                    if let identifier = friend.contactIdentifier {
                        Task {
                            do {
                                let _ = try await ContactsManager.shared.getContactViewController(for: identifier)
                                presentedContactIdentifier = ContactSheetItem(id: identifier)
                            } catch {
                                presentedContactIdentifier = ContactSheetItem(
                                    id: identifier,
                                    error: error
                                )
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Name")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        Text(friend.name)
                            .foregroundColor(AppColors.accent)
                    }
                }
            } else {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $editableName)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                        .onChange(of: editableName) { _, newValue in
                            friend.name = newValue
                        }
                }
            }
            
            // Phone
            if friend.contactIdentifier != nil {
                Button {
                    if let identifier = friend.contactIdentifier {
                        Task {
                            do {
                                let _ = try await ContactsManager.shared.getContactViewController(for: identifier)
                                presentedContactIdentifier = ContactSheetItem(id: identifier)
                            } catch {
                                presentedContactIdentifier = ContactSheetItem(
                                    id: identifier,
                                    error: error
                                )
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Phone")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        if let phone = friend.phoneNumber {
                            Text(phone)
                                .foregroundColor(AppColors.accent)
                        } else {
                            Text("Not set")
                                .foregroundColor(AppColors.tertiaryLabel)
                        }
                    }
                }
            } else {
                HStack {
                    Text("Phone")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    TextField("Not set", text: $editablePhone)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(AppColors.secondaryLabel)
                        .onChange(of: editablePhone) { _, newValue in
                            friend.phoneNumber = newValue.isEmpty ? nil : newValue
                        }
                }
            }
            
            // Email
            if friend.contactIdentifier != nil {
                Menu {
                    // Primary email
                    if let primaryEmail = friend.email {
                        Button {
                            // No action needed, it's already primary
                        } label: {
                            HStack {
                                Text(primaryEmail)
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    // Additional emails
                    ForEach(friend.additionalEmails, id: \.self) { email in
                        Button {
                            Task {
                                await setPrimaryEmail(email)
                            }
                        } label: {
                            Text(email)
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        activeSheet = .addEmail
                    } label: {
                        Label("Add New Email", systemImage: "plus")
                    }
                } label: {
                    HStack {
                        Text("Email")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        if let primaryEmail = friend.email {
                            HStack(spacing: 4) {
                                Text(primaryEmail)
                                    .foregroundColor(AppColors.accent)
                                if isUpdatingContact {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .tint(AppColors.accent)
                                }
                            }
                        } else {
                            Text("Not set")
                                .foregroundColor(AppColors.tertiaryLabel)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(AppColors.secondaryLabel)
                            .font(.caption)
                    }
                }
                .disabled(isUpdatingContact)
            } else {
                manualEmailView
            }
            
            // City
            CitySearchField(service: cityService)
        }
        .sheet(item: $presentedContactIdentifier) { item in
            ContactViewControllerRepresentable(
                contactIdentifier: item.id,
                friend: friend,
                isPresented: Binding(
                    get: { presentedContactIdentifier != nil },
                    set: { if !$0 { presentedContactIdentifier = nil } }
                )
            )
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addEmail:
                NavigationStack {
                    Form {
                        Section {
                            TextField("Email Address", text: $newEmailInput)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        } footer: {
                            if friend.contactIdentifier != nil {
                                Text("This email will be saved to the contact")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(AppColors.systemBackground)
                    .navigationTitle("Add New Email")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newEmailInput = ""
                                activeSheet = nil
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addNewEmail(newEmailInput)
                                activeSheet = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var manualEmailView: some View {
        Menu {
            // Primary email
            if let primaryEmail = friend.email {
                Button {
                    // No action needed, it's already primary
                } label: {
                    HStack {
                        Text(primaryEmail)
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            // Additional emails
            ForEach(friend.additionalEmails, id: \.self) { email in
                Button {
                    setPrimaryEmailLocally(email)
                } label: {
                    Text(email)
                }
            }
            
            Divider()
            
            // Add new email option
            Button {
                activeSheet = .addEmail
            } label: {
                Label("Add New Email", systemImage: "plus")
            }
        } label: {
            HStack {
                Text("Email")
                    .foregroundColor(AppColors.label)
                Spacer()
                if let primaryEmail = friend.email {
                    Text(primaryEmail)
                        .foregroundColor(AppColors.secondaryLabel)
                } else {
                    Text("Not set")
                        .foregroundColor(AppColors.tertiaryLabel)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundColor(AppColors.secondaryLabel)
                    .font(.caption)
            }
        }
    }
    
    private func addNewEmail(_ email: String) {
        guard !email.isEmpty else { return }
        
        // Add to additional emails if we already have a primary
        if friend.email != nil {
            var currentAdditional = friend.additionalEmails
            currentAdditional.append(email)
            friend.additionalEmails = currentAdditional
        } else {
            // Set as primary if we don't have one
            friend.email = email
        }
        
        // If this is a contact-imported friend, sync with Contacts
        if let identifier = friend.contactIdentifier {
            Task {
                await updateContactWithEmails(identifier: identifier)
            }
        }
        
        newEmailInput = ""
    }
    
    private func setPrimaryEmail(_ email: String) async {
        guard let identifier = friend.contactIdentifier else { return }
        
        // Update local state
        if let currentPrimary = friend.email {
            var additional = friend.additionalEmails
            additional.append(currentPrimary)
            additional.removeAll { $0 == email }
            friend.additionalEmails = additional
        }
        friend.email = email
        
        // Update contact
        await updateContactWithEmails(identifier: identifier)
    }
    
    private func setPrimaryEmailLocally(_ email: String) {
        if let currentPrimary = friend.email {
            var additional = friend.additionalEmails
            additional.append(currentPrimary)
            additional.removeAll { $0 == email }
            friend.additionalEmails = additional
        }
        friend.email = email
    }
    
    private func updateContactWithEmails(identifier: String) async {
        await MainActor.run {
            isUpdatingContact = true
        }
        
        do {
            try await ContactsManager.shared.updateContactEmails(
                identifier: identifier,
                primaryEmail: friend.email,
                additionalEmails: friend.additionalEmails
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        
        await MainActor.run {
            isUpdatingContact = false
        }
    }
}

// Add this SwiftUI wrapper for CNContactViewController
struct ContactViewControllerRepresentable: UIViewControllerRepresentable {
    let contactIdentifier: String
    let friend: Friend
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> CNContactViewController {
        Task {
            do {
                let contact = try await ContactsManager.shared.getContactViewController(for: contactIdentifier)
                let controller = CNContactViewController(for: contact)
                controller.delegate = context.coordinator
                return controller
            } catch {
                isPresented = false
                return CNContactViewController()
            }
        }
        return CNContactViewController()
    }
    
    func updateUIViewController(_ uiViewController: CNContactViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let parent: ContactViewControllerRepresentable
        
        init(parent: ContactViewControllerRepresentable) {
            self.parent = parent
        }
        
        func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
            Task {
                if let _ = contact {
                    let syncSuccessful = await ContactsManager.shared.handleContactChange(for: parent.friend)
                    if !syncSuccessful {
                        // Handle sync failure
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .init("ContactSyncError"),
                                object: nil,
                                userInfo: ["message": "Failed to sync contact changes"]
                            )
                        }
                    }
                }
                await MainActor.run {
                    parent.isPresented = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            FriendInfoExistingSection(
                friend: Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "San Francisco",
                    phoneNumber: "(415) 555-0123",
                    catchUpFrequency: .monthly
                ),
                cityService: {
                    let service = CitySearchService()
                    service.selectedCity = "San Francisco"
                    return service
                }()
            )
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(for: [Friend.self, Tag.self, Hangout.self])
} 
