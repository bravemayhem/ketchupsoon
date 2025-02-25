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
                                if friend.email == nil {
                                    // If there's no primary email, set this as the primary
                                    friend.email = newEmailInput
                                } else {
                                    // If there's already a primary email, add to additional emails
                                    let currentEmails = Array(friend.additionalEmails)
                                    var updatedEmails = currentEmails
                                    updatedEmails.append(newEmailInput)
                                    friend.additionalEmails = updatedEmails
                                }
                                
                                // If this friend is linked to a contact, update the contact
                                if let identifier = friend.contactIdentifier {
                                    Task {
                                        do {
                                            try await ContactsManager.shared.updateContactEmails(
                                                identifier: identifier,
                                                primaryEmail: friend.email,
                                                additionalEmails: friend.additionalEmails
                                            )
                                        } catch {
                                            print("❌ Failed to update contact email: \(error)")
                                        }
                                    }
                                }
                                
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


// MARK: - Previews
#Preview("Email Dropdown") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    
    // Create sample friend with multiple emails
    let friend = Friend(name: "John Smith", email: "john@example.com")
    friend.additionalEmails = ["john.smith@work.com", "john.smith@personal.com"]
    
    return Form {
        EmailDropdownMenu(friend: friend, viewModel: viewModel)
    }
}

#Preview("Email Option Rows") {
    VStack(spacing: 10) {
        EmailOptionRow(
            email: "john@example.com",
            isSelected: true,
            systemImage: "envelope.fill",
            action: {}
        )
        EmailOptionRow(
            email: "john.smith@work.com",
            isSelected: false,
            systemImage: "envelope",
            action: {}
        )
    }
    .padding()
}

