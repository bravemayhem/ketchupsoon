import SwiftUI
import SwiftData

// MARK: - CreateHangoutView
struct CreateHangoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CreateHangoutViewModel
    
    init(friend: Friend, initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil) {
        _viewModel = StateObject(wrappedValue: CreateHangoutViewModel(
            friend: friend,
            modelContext: ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: false))),
            initialDate: initialDate,
            initialLocation: initialLocation,
            initialTitle: initialTitle
        ))
        
        // Configure UIDatePicker to snap to 5-minute intervals
        UIDatePicker.appearance().minuteInterval = 5
    }
    
    var body: some View {
        NavigationStack {
            Form {
                FriendSection(friendName: viewModel.friend.name)
                
                Section("Hangout Title") {
                    TextField("Enter title", text: $viewModel.hangoutTitle)
                }
                
                EmailRecipientsSection(viewModel: viewModel)
                
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
            Text("You've scheduled time with \(viewModel.friend.name). Would you like to remove them from your wishlist?")
        }
    }
}

#Preview {
    CreateHangoutView(friend: Friend(name: "Test Friend"))
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}
