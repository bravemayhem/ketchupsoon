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
                FriendsSection(viewModel: viewModel, showingFriendPicker: $showingFriendPicker)
                
                AdditionalManualAttendeesSection(viewModel: viewModel)
                
                Section("Hangout Title") {
                    TextField("Enter title", text: $viewModel.hangoutTitle)
                }
                
                DateTimeSection(viewModel: viewModel)
                
                Section("Location") {
                    TextField("Enter location", text: $viewModel.selectedLocation)
                }
                
                ScheduleButtonSection(viewModel: viewModel)
            }
            .navigationTitle("Schedule Hangout")
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
            .sheet(isPresented: $viewModel.showingWishlistPrompt) {
                WishlistPromptView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingMessageSheet) {
                if let recipient = viewModel.messageRecipient,
                   let body = viewModel.messageBody {
                    SMSCalendarLinkView(recipient: recipient, message: body)
                }
            }
        }
    }
}

#Preview {
    CreateHangoutView(initialDate: Date())
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
}
