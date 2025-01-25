import SwiftUI
import SwiftData

// MARK: - Updated FriendOnboardingView
struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FriendDetail.OnboardingViewModel
    @State private var showingTagsSheet = false
    @State private var showingDatePicker = false
    @State private var cityService = CitySearchService()
    @State private var error: FriendDetail.FriendError?
    @State private var showingError = false
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    
    init(contact: (name: String, identifier: String?, phoneNumber: String?, email: String?, imageData: Data?, city: String?)) {
        let input = FriendDetail.NewFriendInput(
            name: contact.name,
            identifier: contact.identifier,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            imageData: contact.imageData,
            city: contact.city
        )
        self._viewModel = State(initialValue: FriendDetail.OnboardingViewModel(input: input))
        
        // Initialize cityService if we have a city from contacts
        if let city = contact.city {
            let service = CitySearchService()
            service.searchInput = city
            service.selectedCity = city
            self._cityService = State(initialValue: service)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                FriendOnboardingDetailsSection(
                    isFromContacts: viewModel.isFromContacts,
                    contact: viewModel.input,
                    manualName: $viewModel.friendName,
                    phoneNumber: $viewModel.phoneNumber,
                    email: $viewModel.email,
                    cityService: cityService
                )
                
                FriendTagsSection(
                    tags: viewModel.selectedTags,
                    onManageTags: { showingTagsSheet = true }
                )
                
                FriendConnectSection(
                    wantToConnectSoon: $viewModel.wantToConnectSoon
                )
                
                FriendCatchUpSection(
                    hasCatchUpFrequency: $viewModel.hasCatchUpFrequency,
                    selectedFrequency: $viewModel.selectedFrequency
                )
                
                FriendLastSeenSection(
                    hasLastSeen: $viewModel.hasLastSeen,
                    lastSeenDate: $viewModel.lastSeenDate,
                    showingDatePicker: $showingDatePicker
                )
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.systemBackground)
            .listStyle(.insetGrouped)
            .navigationTitle("Add Friend Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: handleCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", action: handleAdd)
                        .disabled(!viewModel.isFromContacts && viewModel.friendName.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagsSheet) {
                TagsSelectionView(selectedTags: $viewModel.selectedTags)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(date: $viewModel.lastSeenDate, isPresented: $showingDatePicker)
            }
            .alert("Cannot Add Friend", isPresented: $showingError, presenting: error) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.message)
            }
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleAdd() {
        viewModel.selectedCity = cityService.selectedCity
        do {
            try viewModel.createFriend(in: modelContext)
            dismiss()
        } catch let friendError as FriendDetail.FriendError {
            error = friendError
            showingError = true
        } catch {
            print("Unexpected error: \(error)")
            dismiss()
        }
    }
}

#Preview("From Contacts") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "John Smith",
                identifier: "123",
                phoneNumber: "(555) 123-4567",
                email: "john.smith@email.com",
                imageData: nil,
                city: "San Francisco"
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

#Preview("Manual Entry") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "",
                identifier: nil,
                phoneNumber: nil,
                email: nil,
                imageData: nil,
                city: nil
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

