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

#Preview("Email Edit (Add Mode)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    let friend = Friend(name: "John Smith", email: "john@example.com")
    
    return Form {
        Section {
            EmailEditView(friend: friend, viewModel: viewModel)
        }
    }
}

#Preview("Email Edit (Editing Mode)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    let friend = Friend(name: "Jane Doe", email: "")
    viewModel.startEditingEmail(for: friend)
    
    return Form {
        Section {
            EmailEditView(friend: friend, viewModel: viewModel)
        }
    }
} 
