import SwiftUI
import SwiftData

// MARK: - EmailDropdownMenu
struct EmailDropdownMenu: View {
    let friend: Friend
    @ObservedObject var viewModel: CreateHangoutViewModel
    @State private var isExpanded = false
    @State private var showingAddEmailSheet = false
    @State private var newEmailInput = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with current selection and arrow
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    if let selectedEmail = viewModel.getSelectedEmail(for: friend) {
                        Text(selectedEmail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select Email")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Primary email
                    if let primaryEmail = friend.email {
                        EmailOptionRow(
                            email: primaryEmail,
                            isSelected: viewModel.getSelectedEmail(for: friend) == primaryEmail,
                            systemImage: "envelope.fill"
                        ) {
                            viewModel.setSelectedEmail(primaryEmail, for: friend)
                            isExpanded = false
                        }
                    }
                    
                    // Additional emails
                    ForEach(friend.additionalEmails, id: \.self) { email in
                        EmailOptionRow(
                            email: email,
                            isSelected: viewModel.getSelectedEmail(for: friend) == email,
                            systemImage: "envelope"
                        ) {
                            viewModel.setSelectedEmail(email, for: friend)
                            isExpanded = false
                        }
                    }
                    
                    // Add email button
                    Button(action: {
                        newEmailInput = ""
                        showingAddEmailSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Add Email")
                                .foregroundColor(.accentColor)
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 8)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .sheet(isPresented: $showingAddEmailSheet) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Email Address", text: $newEmailInput)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } footer: {
                        Text("This email will be saved to the contact")
                    }
                }
                .navigationTitle("Add Email")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddEmailSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if viewModel.isValidEmail(newEmailInput) {
                                friend.additionalEmails.append(newEmailInput)
                                viewModel.setSelectedEmail(newEmailInput, for: friend)
                                showingAddEmailSheet = false
                                isExpanded = false
                            }
                        }
                        .disabled(!viewModel.isValidEmail(newEmailInput))
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - EmailOptionRow
struct EmailOptionRow: View {
    let email: String
    let isSelected: Bool
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(isSelected ? .accentColor : .gray)
                Text(email)
                    .foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .font(.caption)
        }
    }
}

// MARK: - FriendListItem
struct FriendListItem: View {
    let friend: Friend
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(friend.name)
            EmailDropdownMenu(friend: friend, viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// MARK: - EmailEditView
struct EmailEditView: View {
    let friend: Friend
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        if viewModel.tempEmail(for: friend) == nil {
            Button(action: {
                viewModel.startEditingEmail(for: friend)
            }) {
                Text("Add Email")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(BorderlessButtonStyle())
        } else {
            HStack {
                TextField("Enter email", text: viewModel.emailBinding(for: friend))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .font(.caption)
                
                Button(action: {
                    viewModel.saveEmail(for: friend)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(!viewModel.isValidEmail(viewModel.tempEmail(for: friend) ?? ""))
                
                Button(action: {
                    viewModel.cancelEditingEmail(for: friend)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

// MARK: - AddFriendButton
struct AddFriendButton: View {
    let action: () -> Void
    let title: String
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.accentColor)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

// MARK: - CreateHangoutView
struct CreateHangoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CreateHangoutViewModel
    @State private var showingFriendPicker = false
    
    init(initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil, initialSelectedFriends: [Friend]? = nil) {
        _viewModel = StateObject(wrappedValue: CreateHangoutViewModel(
            modelContext: ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false))),
            initialDate: initialDate,
            initialLocation: initialLocation,
            initialTitle: initialTitle,
            initialSelectedFriends: initialSelectedFriends
        ))
        
        // Configure UIDatePicker to snap to 5-minute intervals
        UIDatePicker.appearance().minuteInterval = 5
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if viewModel.selectedFriends.isEmpty {
                        AddFriendButton(action: { showingFriendPicker = true }, title: "Add Friends")
                    } else {
                        ForEach(viewModel.selectedFriends) { friend in
                            FriendListItem(friend: friend, viewModel: viewModel)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.removeFriend(viewModel.selectedFriends[index])
                            }
                        }
                        
                        AddFriendButton(action: { showingFriendPicker = true }, title: "Add More Friends")
                    }
                } header: {
                    Text("Friends")
                } footer: {
                    if !viewModel.selectedFriends.isEmpty {
                        let missingEmails = viewModel.selectedFriends.filter { $0.email?.isEmpty ?? true }.count
                        if missingEmails > 0 {
                            Text("\(missingEmails) friend\(missingEmails > 1 ? "s" : "") missing email address\(missingEmails > 1 ? "es" : "") - they won't receive calendar invites")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    ForEach(viewModel.manualAttendees) { attendee in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(attendee.name)
                                Text(attendee.email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: {
                                viewModel.removeManualAttendee(attendee)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    VStack {
                        TextField("Name", text: $viewModel.newManualAttendeeName)
                            .textContentType(.name)
                        
                        HStack {
                            TextField("Email", text: $viewModel.newManualAttendeeEmail)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            Button(action: {
                                viewModel.addManualAttendee(
                                    name: viewModel.newManualAttendeeName,
                                    email: viewModel.newManualAttendeeEmail
                                )
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(viewModel.newManualAttendeeName.isEmpty || 
                                    !viewModel.newManualAttendeeEmail.contains("@"))
                        }
                    }
                } header: {
                    Text("Additional Attendees")
                } footer: {
                    Text("Add people who aren't using KetchupSoon yet")
                }
                
                Section("Hangout Title") {
                    TextField("Enter title", text: $viewModel.hangoutTitle)
                }
                
                DateTimeSection(viewModel: viewModel)
                
                Section("Location") {
                    TextField("Enter location", text: $viewModel.selectedLocation)
                }
                
                ScheduleButtonSection(viewModel: viewModel)
            }
            .navigationTitle("Create Hangout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFriendPicker) {
                FriendPickerView(selectedFriends: $viewModel.selectedFriends, selectedTime: viewModel.selectedDate)
            }
            .sheet(isPresented: $viewModel.showingCustomDurationInput) {
                CustomDurationInputView(viewModel: viewModel)
            }
        }
        .alert("Remove from Wishlist?", isPresented: $viewModel.showingWishlistPrompt) {
            Button("Keep on Wishlist") {
                dismiss()
            }
            Button("Remove from Wishlist") {
                viewModel.removeFromWishlist()
                dismiss()
            }
        } message: {
            Text("You've scheduled time with \(viewModel.selectedFriends.map(\.name).joined(separator: ", ")). Would you like to remove them from your wishlist?")
        }
    }
}

#Preview {
    CreateHangoutView(initialDate: Date())
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}
