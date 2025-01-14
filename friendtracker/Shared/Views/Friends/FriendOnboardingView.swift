import SwiftUI
import SwiftData

struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let contact: (name: String, identifier: String?, phoneNumber: String?, imageData: Data?, city: String?)
    
    @State private var friendName = ""
    @State private var phoneNumber = ""
    @State private var citySearchText = ""
    @State private var selectedCity: String?
    @State private var hasLastSeen = false
    @State private var lastSeenDate = Date()
    @State private var hasCatchUpFrequency = false
    @State private var selectedFrequency: CatchUpFrequency = .monthly
    @State private var wantToConnectSoon = false
    @State private var selectedTags: Set<String> = []
    @State private var newTagName = ""
    
    private var isFromContacts: Bool {
        !contact.name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Friend Details") {
                    if !isFromContacts {
                        TextField("Name", text: $friendName)
                        TextField("Phone Number (Optional)", text: $phoneNumber)
                    } else {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(contact.name)
                                .foregroundColor(AppColors.secondaryLabel)
                        }
                        
                        if let phone = contact.phoneNumber {
                            HStack {
                                Text("Phone")
                                Spacer()
                                Text(phone)
                                    .foregroundColor(AppColors.secondaryLabel)
                            }
                        }
                    }
                    
                    CitySearchField(searchText: $citySearchText, selectedCity: $selectedCity)
                }
                // Predefined tags
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Tag.predefinedTags, id: \.self) { tagName in
                                TagSelectionButton(
                                    tagName: tagName,
                                    isSelected: selectedTags.contains(tagName),
                                    action: {
                                        if selectedTags.contains(tagName) {
                                            selectedTags.remove(tagName)
                                        } else {
                                            selectedTags.insert(tagName)
                                        }
                                    }
                                )
                            }
                        }
                        // Custom tag input
                        HStack {
                            TextField("Add custom tag, ex: gym, bayarea", text: $newTagName)
                            Button("Add") {
                                addCustomTag()
                            }
                        }
                    }
                }
                
                /* {
                    // Predefined tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Tag.predefinedTags, id: \.self) { tagName in
                                TagSelectionButton(
                                    tagName: tagName,
                                    isSelected: selectedTags.contains(tagName),
                                    action: {
                                        if selectedTags.contains(tagName) {
                                            selectedTags.remove(tagName)
                                        } else {
                                            selectedTags.insert(tagName)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(AppColors.secondarySystemBackground)
                    
                    // Custom tag input
                    HStack {
                        TextField("Add custom tag, ex: gym, bayarea", text: $newTagName)
                        Button("Add") {
                            addCustomTag()
                        }
                        .foregroundColor(AppColors.accent)
                        .disabled(newTagName.isEmpty)
                    }
                    .padding(.horizontal, 8)
                    .listRowBackground(AppColors.secondarySystemBackground)
                    
                    // Custom tags list
                    let customTags = selectedTags.filter { !Tag.predefinedTags.contains($0) }
                    if !customTags.isEmpty {
                        Divider()
                            .padding(.horizontal, 16)
                            .listRowBackground(AppColors.secondarySystemBackground)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(customTags), id: \.self) { tagName in
                                    TagSelectionButton(
                                        tagName: tagName,
                                        isSelected: true,
                                        action: {
                                            selectedTags.remove(tagName)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(AppColors.secondarySystemBackground)
                    }
                } */
                
                Section("Connect Soon") {
                    Toggle("Want to connect soon?", isOn: $wantToConnectSoon)
                }
                
                Section("Catch Up Frequency") {
                    Toggle("Set catch up goal?", isOn: $hasCatchUpFrequency)
                    
                    if hasCatchUpFrequency {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayText).tag(frequency)
                            }
                        }
                    }
                }
                
                Section("Last Seen") {
                    Toggle("Add last seen date?", isOn: $hasLastSeen)
                    
                    if hasLastSeen {
                        DatePicker(
                            "Last Seen Date",
                            selection: $lastSeenDate,
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
                        addFriend()
                        dismiss()
                    }
                    .disabled(!isFromContacts && friendName.isEmpty)
                }
            }
            .onAppear {
                if let contactCity = contact.city {
                    citySearchText = contactCity
                    selectedCity = contactCity
                }
            }
        }
    }
    
    private func addCustomTag() {
        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tagName.isEmpty else { return }
        
        selectedTags.insert(tagName)
        newTagName = ""
    }
    
    private func addFriend() {
        let friend = Friend(
            name: isFromContacts ? contact.name : friendName,
            lastSeen: hasLastSeen ? lastSeenDate : nil,
            location: selectedCity,
            contactIdentifier: contact.identifier,
            needsToConnectFlag: wantToConnectSoon,
            phoneNumber: isFromContacts ? contact.phoneNumber : (phoneNumber.isEmpty ? nil : phoneNumber),
            photoData: contact.imageData,
            catchUpFrequency: hasCatchUpFrequency ? selectedFrequency : nil
        )
        
        // Add selected tags
        for tagName in selectedTags {
            if let existingTag = try? modelContext.fetch(FetchDescriptor<Tag>()).first(where: { $0.name == tagName }) {
                friend.tags.append(existingTag)
            } else {
                let newTag = Tag(name: tagName, isPredefined: Tag.predefinedTags.contains(tagName))
                modelContext.insert(newTag)
                friend.tags.append(newTag)
            }
        }
        
        modelContext.insert(friend)
    }
}

struct TagSelectionButton: View {
    let tagName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tagName)")
                .font(AppTheme.captionFont)
                .foregroundColor(isSelected ? .white : AppColors.label)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.accent : AppColors.systemBackground)
                .clipShape(Capsule())
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

