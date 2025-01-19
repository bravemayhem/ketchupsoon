import SwiftUI
import SwiftData

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
    
    private func handleCancel() {
        dismiss()
    }
    
    private func handleAdd() {
        viewModel.createFriend(in: modelContext)
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                FriendNameSection(
                    isFromContacts: viewModel.isFromContacts,
                    contactName: viewModel.input?.name,
                    manualName: $viewModel.friendName
                )
                
                FriendTagsSection(
                    tags: viewModel.selectedTags,
                    onManageTags: { showingTagsSheet = true }
                )
                .listRowBackground(AppColors.secondarySystemBackground)
                
                Section("Connect Soon") {
                    Toggle("Want to connect soon?", isOn: $viewModel.wantToConnectSoon)
                }
                
                Section("Catch Up Frequency") {
                    Toggle("Set catch up goal?", isOn: $viewModel.hasCatchUpFrequency)
                    
                    if viewModel.hasCatchUpFrequency {
                        Picker("Frequency", selection: $viewModel.selectedFrequency) {
                            ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayText).tag(frequency)
                            }
                        }
                    }
                }
                
                Section("Last Seen") {
                    Toggle("Add last seen date?", isOn: $viewModel.hasLastSeen)
                    
                    if viewModel.hasLastSeen {
                        DatePicker(
                            "Last Seen Date",
                            selection: $viewModel.lastSeenDate,
                            in: ...Date(),
                            displayedComponents: [.date]
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
