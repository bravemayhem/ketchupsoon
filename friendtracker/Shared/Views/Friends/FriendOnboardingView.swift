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
        
        modelContext.insert(friend)
    }
}
