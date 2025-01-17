import SwiftUI
import SwiftData

/// View for adding new friends to the app, either manually or from contacts.
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
            Form {
                // Basic Info
                Section("Friend Details") {
                    if !viewModel.isFromContacts {
                        TextField("Name", text: $viewModel.friendName)
                        TextField("Phone Number (Optional)", text: $viewModel.phoneNumber)
                    } else {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(viewModel.input?.name ?? "")
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        
                        if let phone = viewModel.input?.phoneNumber {
                            HStack {
                                Text("Phone")
                                Spacer()
                                Text(phone)
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                        }
                    }
                    
                    CitySearchField(
                        searchText: $viewModel.citySearchText,
                        selectedCity: $viewModel.selectedCity
                    )
                }
                
                // Tags
                Section("Tags") {
                    Button(action: { showingTagsSheet = true }) {
                        HStack {
                            Text(viewModel.selectedTags.isEmpty ? "Add Tags" : "Manage Tags")
                            Spacer()
                            if !viewModel.selectedTags.isEmpty {
                                Text("\(viewModel.selectedTags.count) selected")
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                        }
                    }
                    
                    if !viewModel.selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.selectedTags)) { tag in
                                    TagView(tag: tag)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                
                // Connect Soon
                Section("Connect Soon") {
                    Toggle("Want to connect soon?", isOn: $viewModel.wantToConnectSoon)
                }
                
                // Catch Up Frequency
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
                
                // Last Seen
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addFriend(to: modelContext)
                        dismiss()
                    }
                    .disabled(!viewModel.isFromContacts && viewModel.friendName.isEmpty)
                }
            }
            .sheet(isPresented: $showingTagsSheet) {
                NavigationStack {
                    TagSelectionSheet(selectedTags: $viewModel.selectedTags, allTags: allTags)
                }
            }
        }
    }
}

struct TagSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTags: Set<Tag>
    let allTags: [Tag]
    @State private var showingAddTagSheet = false
    
    var body: some View {
        List {
            ForEach(allTags) { tag in
                Button {
                    if selectedTags.contains(tag) {
                        selectedTags.remove(tag)
                    } else {
                        selectedTags.insert(tag)
                    }
                } label: {
                    HStack {
                        Text("#\(tag.name)")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        if selectedTags.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Tags")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showingAddTagSheet = true
                } label: {
                    Label("Add Tag", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(friend: nil)
        }
    }
}

#Preview {
    NavigationStack {
        // From Contacts Preview
        FriendOnboardingView(
            contact: (
                name: "Aleah Smith",
                identifier: "123",
                phoneNumber: "(512) 348-4182",
                imageData: nil,
                city: "Austin"
            )
        )
    }
    .modelContainer(for: [Friend.self, Tag.self], inMemory: true)
}

#Preview("Manual Entry") {
    NavigationStack {
        // Manual Entry Preview
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