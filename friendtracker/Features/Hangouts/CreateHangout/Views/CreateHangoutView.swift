import SwiftUI
import SwiftData

// MARK: - CreateHangoutView
struct CreateHangoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CreateHangoutViewModel
    @State private var showingFriendPicker = false
    
    init(initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil, initialSelectedFriends: [Friend]? = nil) {
        // Use a StateObject wrapper to initialize the viewModel with the default values
        // The actual modelContext will be injected from the environment
        _viewModel = StateObject(wrappedValue: CreateHangoutViewModel(
            modelContext: ModelContext(try! ModelContainer(for: Friend.self, Hangout.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))),
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
                // Test Connection Section
                Section("Supabase Connection") {
                    Button(action: {
                        Task {
                            await viewModel.testSupabaseConnection()
                        }
                    }) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                            Text("Test Connection")
                            Spacer()
                            if viewModel.isTestingConnection {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    
                    if let result = viewModel.connectionTestResult {
                        Text(result)
                            .font(.footnote)
                            .foregroundColor(result.contains("✅") ? .green : .red)
                    }
                }
                
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
            .task {
                // Update the viewModel to use the environment's modelContext
                viewModel.updateModelContext(modelContext)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Friend.self, Hangout.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    CreateHangoutView(initialDate: Date())
        .modelContainer(container)
}
