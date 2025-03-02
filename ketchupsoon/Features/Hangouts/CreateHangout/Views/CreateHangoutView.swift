import SwiftUI
import SwiftData

// MARK: - CreateHangoutView
struct CreateHangoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: CreateHangoutViewModel
    @State private var showingFriendPicker = false
    @State private var localTitle: String = ""
    @FocusState private var isEditingTitle: Bool
    @State private var isViewLoaded = false
    let onEventCreated: (() -> Void)?
    
    init(initialDate: Date? = nil, initialLocation: String? = nil, initialTitle: String? = nil, initialSelectedFriends: [Friend]? = nil, onEventCreated: (() -> Void)? = nil) {
        let container = try! ModelContainer(for: Friend.self, Hangout.self, Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        
        _viewModel = StateObject(wrappedValue: CreateHangoutViewModel(
            modelContext: context,
            initialDate: initialDate,
            initialLocation: initialLocation,
            initialTitle: initialTitle,
            initialSelectedFriends: initialSelectedFriends
        ))
        
        self.onEventCreated = onEventCreated
        
        // Initialize localTitle in init to avoid delays in onAppear
        _localTitle = State(initialValue: initialTitle ?? "")
        
        // Configure UIDatePicker to snap to 5-minute intervals
        UIDatePicker.appearance().minuteInterval = 5
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Hangout Title") {
                    // Use a local state variable for the text field to optimize updates
                    TextField("Enter title", text: $localTitle)
                        .onAppear {
                            // Only set this once when the view appears
                            if !isViewLoaded {
                                localTitle = viewModel.hangoutTitle
                                isViewLoaded = true
                            }
                        }
                        .onChange(of: localTitle) { oldValue, newValue in
                            // Only update viewModel when editing is finished or after a short delay
                            if !isEditingTitle {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    viewModel.hangoutTitle = newValue
                                }
                            }
                        }
                        .onSubmit {
                            viewModel.hangoutTitle = localTitle
                        }
                        .focused($isEditingTitle)
                }
                
                FriendsSection(viewModel: viewModel, showingFriendPicker: $showingFriendPicker)
                
                // Additional Attendee section can added back in later if and when needed
                
                DateTimeSection(viewModel: viewModel)
                
                Section("Location") {
                    // Let's also optimize the location text field
                    TextField("Enter location", text: Binding(
                        get: { viewModel.selectedLocation },
                        set: { newValue in
                            // Debounce updates to reduce layout recalculations
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.selectedLocation = newValue
                            }
                        }
                    ))
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
            .onChange(of: viewModel.isCreatingEvent) { wasCreating, isCreating in
                if wasCreating && !isCreating && viewModel.errorMessage == nil {
                    // Event was successfully created (creation finished and no error)
                    onEventCreated?()  // Call the completion handler
                    dismiss()
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
