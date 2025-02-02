import SwiftUI
import SwiftData

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
                        Button {
                            showingFriendPicker = true
                        } label: {
                            HStack {
                                Text("Add Friends")
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    } else {
                        ForEach(viewModel.selectedFriends) { friend in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(friend.name)
                                    if let email = friend.email, !email.isEmpty {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("No email address")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Button {
                            showingFriendPicker = true
                        } label: {
                            HStack {
                                Text("Add More Friends")
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
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
