import SwiftUI
import SwiftData

// MARK: - Updated FriendOnboardingView
struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FriendDetail.OnboardingViewModel
    @State private var showingTagsSheet = false
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
    }
    
    var body: some View {
        NavigationStack {
            BaseFriendForm(configuration: FormConfiguration.onboarding) { config in
                Group {
                    if config.showsName {
                        FriendNameSection(
                            isFromContacts: viewModel.isFromContacts,
                            contactName: viewModel.input?.name,
                            manualName: $viewModel.friendName
                        )
                    }
                    
                    if config.showsTags {
                        FriendTagsSection(
                            tags: viewModel.selectedTags,
                            onManageTags: { showingTagsSheet = true }
                        )
                    }
                    
                    if config.showsWishlist {
                        FriendConnectSection(
                            wantToConnectSoon: $viewModel.wantToConnectSoon
                        )
                    }
                    
                    if config.showsCatchUpFrequency {
                        FriendCatchUpSection(
                            hasCatchUpFrequency: $viewModel.hasCatchUpFrequency,
                            selectedFrequency: $viewModel.selectedFrequency
                        )
                    }
                    
                    if config.showsLastSeen {
                        FriendLastSeenSection(
                            hasLastSeen: $viewModel.hasLastSeen,
                            lastSeenDate: $viewModel.lastSeenDate
                        )
                    }
                }
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
        viewModel.createFriend(in: modelContext)
        dismiss()
    }
}

#Preview("Friend Onboarding") {
    NavigationStack {
        FriendOnboardingView(
            contact: (
                name: "John Doe",
                identifier: nil,
                phoneNumber: "(555) 123-4567",
                imageData: nil,
                city: "San Francisco"
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

