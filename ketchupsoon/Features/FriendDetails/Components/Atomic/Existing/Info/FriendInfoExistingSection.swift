// CURRENTLY USED FOR EXISTING FRIENDS

import SwiftUI
import SwiftData


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
    
    private enum ActiveSheet: Identifiable {
        case contact
        case addEmail
        case birthday
        
        var id: Int {
            switch self {
            case .contact: return 1
            case .addEmail: return 2
            case .birthday: return 3
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
                    activeSheet = .contact
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
                    activeSheet = .contact
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
                emailMenuView
            } else {
                manualEmailView
            }
            
            // Birthday
            Button {
                activeSheet = .birthday
            } label: {
                HStack {
                    Text("Birthday")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    if let birthday = friend.birthday {
                        Text(formatBirthday(birthday))
                            .foregroundColor(AppColors.secondaryLabel)
                    } else {
                        Text("Not set")
                            .foregroundColor(AppColors.tertiaryLabel)
                    }
                }
            }
            
            // City
            CitySearchField(service: cityService)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .sheet(item: $activeSheet, onDismiss: {
            print("👁 Sheet dismissed")
            activeSheet = nil
        }) { sheet in
            switch sheet {
            case .contact:
                if let identifier = friend.contactIdentifier {
                    ContactDisplayView(
                        contactIdentifier: identifier,
                        position: "existing_info",
                        isPresented: Binding(
                            get: { activeSheet == .contact },
                            set: { if !$0 { activeSheet = nil } }
                        )
                    )
                    .background(Color.clear)
                }
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
            case .birthday:
                NavigationStack {
                    VStack {
                        DatePicker(
                            "Birthday",
                            selection: Binding(
                                get: { friend.birthday ?? Date() },
                                set: { friend.birthday = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                    }
                    .navigationTitle("Select Birthday")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                activeSheet = nil
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                activeSheet = nil
                            }
                        }
                        
                        ToolbarItem(placement: .destructiveAction) {
                            Button("Clear") {
                                friend.birthday = nil
                                activeSheet = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private var emailMenuView: some View {
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
        .task {
            // Sync contact info when menu is opened
            if friend.contactIdentifier != nil {
                await MainActor.run { isUpdatingContact = true }
                let success = await ContactsManager.shared.syncContactInfo(for: friend)
                if !success {
                    await MainActor.run {
                        errorMessage = "Failed to sync contact information"
                        showingError = true
                    }
                }
                await MainActor.run { isUpdatingContact = false }
            }
        }
        .disabled(isUpdatingContact)
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
    
    private func formatBirthday(_ date: Date) -> String {
        return DateFormatter.birthday.string(from: date)
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
