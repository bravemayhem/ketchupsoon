import SwiftUI
import SwiftData
import MessageUI

struct FriendDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme
    let friend: Friend
    let presentationMode: PresentationMode
    @State private var showingDatePicker = false
    @State private var lastSeenDate = Date()
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    
    enum PresentationMode {
        case sheet(Binding<Bool>)
        case navigation
    }
    
    var body: some View {
        List {
            Section {
                // Last Seen
                HStack {
                    Text("Last Seen")
                    Spacer()
                    Button(friend.lastSeenText) {
                        lastSeenDate = friend.lastSeen ?? Date()
                        showingDatePicker = true
                    }
                    .foregroundStyle(.secondary)
                }
                
                // Location
                HStack {
                    Text("Location")
                    Spacer()
                    Text(friend.location)
                        .foregroundStyle(.secondary)
                }
                
                if let phoneNumber = friend.phoneNumber {
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(phoneNumber)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Actions") {
                if friend.phoneNumber != nil {
                    Button(action: {
                        showingMessageSheet = true
                    }) {
                        Label("Send Message", systemImage: "message.fill")
                    }
                }
                
                Button(action: {
                    showingScheduler = true
                }) {
                    Label("Schedule Hangout", systemImage: "calendar")
                }
                
                Button(action: {
                    friend.lastSeen = Date()
                }) {
                    Label("Mark as Seen Today", systemImage: "checkmark.circle.fill")
                }
            }
            
            if !friend.hangouts.isEmpty {
                Section("Upcoming Hangouts") {
                    ForEach(friend.scheduledHangouts) { hangout in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hangout.activity)
                                .font(.headline)
                            Text(hangout.location)
                                .foregroundStyle(.secondary)
                            Text(hangout.formattedDate)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .sheet(let isPresented) = presentationMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented.wrappedValue = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $lastSeenDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Last Seen Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            friend.lastSeen = lastSeenDate
                            showingDatePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingScheduler) {
            NavigationStack {
                SchedulerView(initialFriend: friend)
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageComposeView(recipient: friend.phoneNumber ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(
            friend: Friend(
                name: "Preview Friend",
                lastSeen: Date(),
                location: "Local",
                phoneNumber: "+1234567890"
            ),
            presentationMode: .navigation
        )
    }
    .modelContainer(for: Friend.self)
    .environmentObject(Theme.shared)
} 