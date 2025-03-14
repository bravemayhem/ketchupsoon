import SwiftUI
import Contacts
import ContactsUI
import MessageUI

// MARK: - Invite Via Text Content Component
/// This component contains just the invite via text content without full screen navigation elements.
/// It can be reused in other views like AddFriendView for dynamic tab content.
public struct InviteViaTextContent: View {
    // State variables
    @State private var searchText = ""
    @State private var invitationMessage: String
    
    // User information
    private let userName: String
    
    // Contact management
    @StateObject private var contactsManager = ContactsManager.shared
    @State private var contacts: [CNContact] = []
    @State private var filteredContacts: [CNContact] = []
    @State private var selectedContacts: [CNContact] = []
    @State private var isContactsLoaded = false
    @State private var isLoadingContacts = false
    
    // SMS composer
    @State private var showingSMSComposer = false
    @State private var showingContactsAccessAlert = false
    @State private var showingNoSMSCapabilityAlert = false
    
    public init(userName: String = UserDefaults.standard.string(forKey: "userName") ?? "Me") {
        self.userName = userName
        // Initialize the message with the user's name instead of hardcoded "Alex"
        self._invitationMessage = State(initialValue: "Hey! I want to ketchup with you!\nDownload this app so we can\nschedule time to hang out:\nketchupsoon.app/download\n- \(userName)")
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Search box
            searchBox()
            
            // Contact search results (only shown when searching)
            if !searchText.isEmpty {
                contactSearchResults()
            }
            
            // Selected Contacts Section
            selectedContactsSection()
            
            // Invitation Message Section
            invitationMessageSection()
            
            // Message Preview Section
            messagePreviewSection()
            
            // Send Button
            sendButton()
                .padding(.top, 10)
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
        .onAppear {
            loadContacts()
        }
        .sheet(isPresented: $showingSMSComposer) {
            // Create a message composer for multiple recipients
            if !selectedContacts.isEmpty,
               let phoneNumber = selectedContacts.first?.phoneNumbers.first?.value.stringValue {
                MessageComposeView(recipient: phoneNumber, message: invitationMessage)
            }
        }
        .alert("Contacts Access Required", isPresented: $showingContactsAccessAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow access to your contacts in Settings to use this feature.")
        }
        .alert("SMS Not Available", isPresented: $showingNoSMSCapabilityAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your device doesn't support sending SMS messages.")
        }
    }
    
    // MARK: - Methods
    
    // Load contacts from device
    private func loadContacts() {
        guard !isContactsLoaded && !isLoadingContacts else { return }
        
        isLoadingContacts = true
        
        Task {
            // Request access to contacts
            let accessGranted = await contactsManager.requestAccess()
            
            if accessGranted {
                // Fetch contacts
                let fetchedContacts = await contactsManager.fetchContacts()
                
                await MainActor.run {
                    self.contacts = fetchedContacts
                    self.isContactsLoaded = true
                    self.isLoadingContacts = false
                    self.applySearchFilter()
                }
            } else {
                await MainActor.run {
                    self.isLoadingContacts = false
                    self.showingContactsAccessAlert = true
                }
            }
        }
    }
    
    // Apply search filter to contacts
    private func applySearchFilter() {
        guard !searchText.isEmpty else {
            filteredContacts = []
            return
        }
        
        let query = searchText.lowercased()
        filteredContacts = contacts.filter { contact in
            let firstName = contact.givenName.lowercased()
            let lastName = contact.familyName.lowercased()
            let fullName = "\(firstName) \(lastName)".lowercased()
            
            // Also search phone numbers
            let phoneMatch = contact.phoneNumbers.contains { phoneNumber in
                phoneNumber.value.stringValue.contains(query)
            }
            
            return firstName.contains(query) || lastName.contains(query) || fullName.contains(query) || phoneMatch
        }
    }
    
    // Get contact display name
    private func getContactDisplayName(_ contact: CNContact) -> String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        if firstName.isEmpty && lastName.isEmpty {
            return "Unknown"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
    
    // Get contact initials
    private func getContactInitials(_ contact: CNContact) -> String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        
        var initials = ""
        
        if !firstName.isEmpty, let firstInitial = firstName.first {
            initials.append(firstInitial)
        }
        
        if !lastName.isEmpty, let lastInitial = lastName.first {
            initials.append(lastInitial)
        }
        
        return initials.uppercased()
    }
    
    // Get contact phone number
    private func getContactPhoneNumber(_ contact: CNContact) -> String {
        if let phone = contact.phoneNumbers.first?.value.stringValue {
            return phone
        }
        return "No phone number"
    }
    
    // Toggle contact selection
    private func toggleContactSelection(_ contact: CNContact) {
        if selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
            selectedContacts.removeAll { $0.identifier == contact.identifier }
        } else {
            selectedContacts.append(contact)
        }
    }
    
    // Send invites
    private func sendInvites() {
        guard !selectedContacts.isEmpty else { return }
        
        // Check if device can send SMS
        if !MFMessageComposeViewController.canSendText() {
            showingNoSMSCapabilityAlert = true
            return
        }
        
        showingSMSComposer = true
    }
    
    // MARK: - Component Views
    
    private func searchBox() -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textPrimary.opacity(0.6))
                .padding(.leading, 15)
            
            TextField("search contacts...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .padding(.vertical, 15)
                .onChange(of: searchText) { oldValue, newValue in
                    applySearchFilter()
                }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(AppColors.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
        )
    }
    
    private func contactSearchResults() -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if isLoadingContacts {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.textPrimary))
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if filteredContacts.isEmpty {
                Text("No contacts found")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(filteredContacts, id: \.identifier) { contact in
                            Button(action: {
                                toggleContactSelection(contact)
                            }) {
                                HStack {
                                    // Contact initials or image
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.cardBackground)
                                            .frame(width: 40, height: 40)
                                        
                                        Text(getContactInitials(contact))
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                    
                                    // Contact info
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(getContactDisplayName(contact))
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        if !contact.phoneNumbers.isEmpty {
                                            Text(getContactPhoneNumber(contact))
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Selection indicator
                                    if selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.mint)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.cardBackground.opacity(0.7))
                                )
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: 250)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.backgroundSecondary.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.separator, lineWidth: 1)
                )
        )
    }
    
    private func selectedContactsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("selected contacts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Contact chips container
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if selectedContacts.isEmpty {
                        // Placeholder text when no contacts selected
                        Text("Select contacts to invite")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, 20)
                            .frame(maxHeight: .infinity)
                    } else {
                        // Display selected contacts
                        ForEach(selectedContacts, id: \.identifier) { contact in
                            ContactChip(
                                initials: getContactInitials(contact), 
                                name: getContactDisplayName(contact).lowercased(),
                                onRemove: {
                                    selectedContacts.removeAll { $0.identifier == contact.identifier }
                                }
                            )
                        }
                        
                        // Add more chip if contacts are selected
                        if !selectedContacts.isEmpty {
                            AddMoreChip()
                                .onTapGesture {
                                    searchText = ""
                                    applySearchFilter()
                                }
                        }
                    }
                }
                .padding(.vertical, 27) // Center content in the container
                .padding(.horizontal, 20)
            }
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            )
        }
    }
    
    private func invitationMessageSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("invitation message")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Message Editor with nested containers matching reference photo
            ZStack {
                // Outer container
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                
                // Inner content
                VStack {
                    ZStack(alignment: .topLeading) {
                        // Inner container
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.backgroundSecondary)
                        
                        // Editable Text Content
                        TextEditor(text: $invitationMessage)
                            .scrollContentBackground(.hidden) // Hide default background
                            .background(Color.clear)
                            .font(.system(size: 15.5))
                            .foregroundColor(AppColors.textPrimary.opacity(0.9))
                            .padding(10)
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
        }
    }
    
    private func messagePreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("preview")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            
            // Message Preview Bubble
            HStack {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.accentGradient2.opacity(0.6))
                        .frame(width: 250, height: 40)
                    
                    let previewText = invitationMessage.count > 30 
                        ? "\(invitationMessage.prefix(30))..." 
                        : invitationMessage
                    
                    Text(previewText)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textPrimary.opacity(0.9))
                        .padding(.leading, 15)
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppColors.cardBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
            )
        }
    }
    
    private func sendButton() -> some View {
        Button(action: {
            sendInvites()
        }) {
            Text("send invites")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    Capsule()
                        .fill(AppColors.accentGradient2)
                        .glow(color: AppColors.purple, radius: 6, opacity: 0.5)
                )
        }
        .disabled(selectedContacts.isEmpty)
        .opacity(selectedContacts.isEmpty ? 0.5 : 1.0)
    }
}

// MARK: - Supporting Components

struct ContactChip: View {
    let initials: String
    let name: String
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 28, height: 28)
                
                Text(initials)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Name
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 4)
            
            // Remove button
            Button(action: {
                onRemove?()
            }) {
                ZStack {
                    Circle()
                        .fill(AppColors.textPrimary.opacity(0.2))
                        .frame(width: 20, height: 20)
                    
                    Text("×")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(
            Capsule()
                .fill(AppColors.accentGradient2)
                .glow(color: AppColors.purple, radius: 6, opacity: 0.5)
        )
    }
}

struct AddMoreChip: View {
    var body: some View {
        Text("+ more")
            .font(.system(size: 12))
            .foregroundColor(AppColors.textPrimary.opacity(0.7))
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(AppColors.cardBackground)
                    .overlay(
                        Capsule()
                            .stroke(AppColors.separator, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Preview
struct InviteViaTextContent_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            InviteViaTextContent(userName: "Taylor")
        }
    }
} 
