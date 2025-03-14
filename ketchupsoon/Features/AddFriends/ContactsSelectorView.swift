import SwiftUI
import Contacts
import ContactsUI

struct ContactsSelectorView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    
    // State for selected contacts
    @State private var contacts: [ContactItem] = []
    @State private var selectedContactIds: Set<String> = []
    @State private var searchQuery = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            AddFriendViewColors.backgroundGradient
                .ignoresSafeArea()
            
            // Decorative background elements
            Circle()
                .fill(AddFriendViewColors.purple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .position(x: 350, y: 150)
            
            Circle()
                .fill(AddFriendViewColors.pinkRed.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .position(x: 50, y: 650)
            
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Contacts")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss()
                        }
                    }) {
                        Circle()
                            .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("✕")
                                    .font(.system(size: 20))
                                    .foregroundColor(AddFriendViewColors.textPrimary)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AddFriendViewColors.textPrimary.opacity(0.6))
                        .padding(.leading, 15)
                    
                    TextField("", text: $searchQuery)
                        .placeholder(when: searchQuery.isEmpty) {
                            Text("search contacts...")
                                .foregroundColor(AddFriendViewColors.textTertiary)
                        }
                        .foregroundColor(AddFriendViewColors.textPrimary)
                        .padding(.vertical, 15)
                }
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(AddFriendViewColors.separator, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Selection controls
                HStack {
                    Button(action: {
                        toggleSelectAll()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isAllSelected() ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isAllSelected() ? AddFriendViewColors.mint : AddFriendViewColors.textSecondary)
                            
                            Text(isAllSelected() ? "Deselect All" : "Select All")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AddFriendViewColors.textPrimary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                        )
                    }
                    
                    Spacer()
                    
                    Text("\(selectedContactIds.count) selected")
                        .font(.system(size: 14))
                        .foregroundColor(AddFriendViewColors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                // Contacts list
                if isLoading {
                    // Loading view
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AddFriendViewColors.textPrimary))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, minHeight: 200)
                    Spacer()
                } else if let error = errorMessage {
                    // Error view
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(AddFriendViewColors.pinkRed)
                        
                        Text(error)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(AddFriendViewColors.textSecondary)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    Spacer()
                } else if filteredContacts.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(AddFriendViewColors.textSecondary)
                        
                        if searchQuery.isEmpty {
                            Text("No contacts found")
                                .font(.system(size: 16))
                                .foregroundColor(AddFriendViewColors.textSecondary)
                        } else {
                            Text("No contacts match '\(searchQuery)'")
                                .font(.system(size: 16))
                                .foregroundColor(AddFriendViewColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    Spacer()
                } else {
                    // Contacts list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredContacts) { contact in
                                ContactSelectionRow(
                                    contact: contact,
                                    isSelected: selectedContactIds.contains(contact.id),
                                    onToggle: { toggleContact(contact) }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Add padding for the invite button
                    }
                }
                
                Spacer()
            }
            
            // Bottom invite button
            VStack {
                Spacer()
                
                Button(action: {
                    inviteSelected()
                }) {
                    Text("Invite Selected (\(selectedContactIds.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            Group {
                                if selectedContactIds.isEmpty {
                                    AddFriendViewColors.cardBackground
                                } else {
                                    AddFriendViewColors.purplePinkGradient
                                }
                            }
                        )
                        .cornerRadius(25)
                        .glow(color: selectedContactIds.isEmpty ? .clear : AddFriendViewColors.purple, radius: 8, opacity: 0.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(selectedContactIds.isEmpty ? AddFriendViewColors.separator : Color.clear, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .disabled(selectedContactIds.isEmpty)
            }
            
            // Toast notification
            if showToast {
                VStack {
                    Spacer()
                    
                    Text(toastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(AddFriendViewColors.cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(AddFriendViewColors.separator, lineWidth: 1)
                                )
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            loadContacts()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredContacts: [ContactItem] {
        if searchQuery.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchQuery) ||
                contact.phone.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    // MARK: - Methods
    private func loadContacts() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let contactStore = CNContactStore()
            
            // Request access to contacts
            contactStore.requestAccess(for: .contacts) { granted, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error accessing contacts: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                
                guard granted else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Permission to access contacts was denied"
                        self.isLoading = false
                    }
                    return
                }
                
                // Fetch contacts
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                var contactItems: [ContactItem] = []
                
                do {
                    try contactStore.enumerateContacts(with: request) { contact, _ in
                        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else {
                            return
                        }
                        
                        let fullName = [contact.givenName, contact.familyName]
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                        
                        if !fullName.isEmpty {
                            let initials = getInitials(from: fullName)
                            let contactItem = ContactItem(
                                id: "\(fullName)_\(phoneNumber)",
                                name: fullName,
                                phone: phoneNumber,
                                initials: initials
                            )
                            contactItems.append(contactItem)
                        }
                    }
                    
                    // Sort contacts by name
                    contactItems.sort { $0.name < $1.name }
                    
                    DispatchQueue.main.async {
                        self.contacts = contactItems
                        self.isLoading = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Error fetching contacts: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        return components.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
    
    private func toggleContact(_ contact: ContactItem) {
        if selectedContactIds.contains(contact.id) {
            selectedContactIds.remove(contact.id)
        } else {
            selectedContactIds.insert(contact.id)
        }
    }
    
    private func isAllSelected() -> Bool {
        return !contacts.isEmpty && selectedContactIds.count == contacts.count
    }
    
    private func toggleSelectAll() {
        if isAllSelected() {
            // Deselect all
            selectedContactIds.removeAll()
        } else {
            // Select all
            selectedContactIds = Set(contacts.map { $0.id })
        }
    }
    
    private func inviteSelected() {
        // In a real implementation, this would send invitations to the selected contacts
        
        let selectedContacts = contacts.filter { selectedContactIds.contains($0.id) }
        showToast("Invitations sent to \(selectedContacts.count) contacts")
        
        // Here you would typically make API calls to send the invitations
        
        // After sending, dismiss the view or clear selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showToast = true
        }
        
        // Auto-hide toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showToast = false
            }
        }
    }
}

// MARK: - Contact Item Model
struct ContactItem: Identifiable {
    let id: String
    let name: String
    let phone: String
    let initials: String
}

// MARK: - Contact Selection Row
struct ContactSelectionRow: View {
    let contact: ContactItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Profile circle with initials
                ZStack {
                    Circle()
                        .stroke(AddFriendViewColors.outline, lineWidth: 1)
                        .background(Circle().fill(AddFriendViewColors.cardBackground.opacity(0.7)))
                        .frame(width: 50, height: 50)
                    
                    Text(contact.initials)
                        .font(.system(size: 16))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                }
                
                // Contact info
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 16))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                    
                    Text(contact.phone)
                        .font(.system(size: 12))
                        .foregroundColor(AddFriendViewColors.textSecondary)
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? AddFriendViewColors.mint : AddFriendViewColors.separator, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(AddFriendViewColors.mint)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AddFriendViewColors.mint.opacity(0.5) : AddFriendViewColors.separator, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Previews
#Preview {
    ContactsSelectorView()
} 