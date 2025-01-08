import SwiftUI
import SwiftData

struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let contact: (name: String, identifier: String?, phoneNumber: String?, imageData: Data?)
    
    @State private var friendName = ""
    @State private var phoneNumber = ""
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
                if !isFromContacts {
                    Section("Friend Details") {
                        TextField("Name", text: $friendName)
                        TextField("Phone Number (Optional)", text: $phoneNumber)
                    }
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
        }
    }
    
    private func addFriend() {
        let friend = Friend(
            name: isFromContacts ? contact.name : friendName,
            lastSeen: hasLastSeen ? lastSeenDate : nil,
            location: FriendLocation.local.rawValue,
            contactIdentifier: contact.identifier,
            needsToConnectFlag: wantToConnectSoon,
            phoneNumber: isFromContacts ? contact.phoneNumber : (phoneNumber.isEmpty ? nil : phoneNumber),
            photoData: contact.imageData,
            catchUpFrequency: hasCatchUpFrequency ? selectedFrequency : nil
        )
        
        modelContext.insert(friend)
    }
}
