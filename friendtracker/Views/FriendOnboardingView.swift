import SwiftUI
import SwiftData

struct FriendOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let contact: (name: String, identifier: String?, phoneNumber: String?, imageData: Data?)
    
    @State private var hasLastSeen = false
    @State private var lastSeenDate = Date()
    @State private var hasCatchUpFrequency = false
    @State private var selectedFrequency: CatchUpFrequency = .monthly
    @State private var customDays: Int?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Last Seen") {
                    Toggle("Have you met before?", isOn: $hasLastSeen)
                    
                    if hasLastSeen {
                        DatePicker(
                            "Last Seen Date",
                            selection: $lastSeenDate,
                            in: ...Date(),
                            displayedComponents: [.date]
                        )
                    }
                }
                
                Section("Catch Up Frequency") {
                    Toggle("Set catch up goal?", isOn: $hasCatchUpFrequency)
                    
                    if hasCatchUpFrequency {
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                        
                        if selectedFrequency == .custom {
                            Stepper(
                                "Every \(customDays ?? 30) days",
                                value: Binding(
                                    get: { customDays ?? 30 },
                                    set: { customDays = $0 }
                                ),
                                in: 1...365
                            )
                        }
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
                }
            }
        }
    }
    
    private func addFriend() {
        let friend = Friend(
            name: contact.name,
            lastSeen: hasLastSeen ? lastSeenDate : nil,
            location: FriendLocation.local.rawValue,
            contactIdentifier: contact.identifier,
            phoneNumber: contact.phoneNumber,
            photoData: contact.imageData,
            needsToConnectFlag: false,
            catchUpFrequency: hasCatchUpFrequency ? selectedFrequency.rawValue : nil,
            customCatchUpDays: hasCatchUpFrequency && selectedFrequency == .custom ? customDays : nil
        )
        modelContext.insert(friend)
    }
} 