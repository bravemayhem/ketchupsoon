import SwiftUI
import SwiftData

// MARK: - Updated FriendOnboardingView
struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FriendDetail.OnboardingViewModel
    @State private var showingTagsSheet = false
    @State private var cityService = CitySearchService()
    @Query(sort: [SortDescriptor<Tag>(\.name)]) private var allTags: [Tag]
    
    init(contact: (name: String, identifier: String?, phoneNumber: String?, imageData: Data?, city: String?)) {
        let input = FriendDetail.NewFriendInput(
            name: contact.name,
            identifier: contact.identifier,
            phoneNumber: contact.phoneNumber,
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
                    lastSeenDate: $viewModel.lastSeenDate
                )
            }
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
        }
    }
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleAdd() {
        viewModel.selectedCity = cityService.selectedCity
        viewModel.createFriend(in: modelContext)
        dismiss()
    }
}

#Preview("From Contacts") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "John Smith",
                identifier: "123",
                phoneNumber: "(555) 123-4567",
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
                imageData: nil,
                city: nil
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

