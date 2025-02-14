import SwiftUI
import SwiftData

struct HangoutCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let hangout: Hangout
    @State private var showingMissedHangoutOptions = false
    @State private var showingCalendarOverlay = false
    
    private var friendNames: String {
        hangout.friends.map(\.name).joined(separator: ", ")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Did your hangout with \(friendNames) happen?")
                        .font(.headline)
                } footer: {
                    Text("This will help us keep track of when you last connected.")
                }
                
                Section {
                    Button("Yes, it happened") {
                        markHangoutComplete()
                    }
                    .foregroundColor(.green)
                    
                    Button("No, it didn't happen") {
                        showingMissedHangoutOptions = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Hangout Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "What would you like to do?",
                isPresented: $showingMissedHangoutOptions,
                titleVisibility: .visible
            ) {
                Button("Reschedule") {
                    hangout.needsReschedule = true
                    showingCalendarOverlay = true
                }
                
                Button("Move to Wish List") {
                    for friend in hangout.friends {
                        friend.needsToConnectFlag = true
                    }
                    modelContext.delete(hangout)
                    dismiss()
                }
                
                Button("Discard") {
                    for friend in hangout.friends {
                        friend.needsToConnectFlag = false
                    }
                    modelContext.delete(hangout)
                    dismiss()
                }
                
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("How would you like to handle the missed hangout?")
            }
            .sheet(isPresented: $showingCalendarOverlay, onDismiss: {
                if hangout.needsReschedule {
                    modelContext.delete(hangout)
                }
                dismiss()
            }) {
                CalendarOverlayView()
            }
        }
    }
    
    private func markHangoutComplete() {
        for friend in hangout.friends {
            friend.lastSeen = hangout.date
            friend.needsToConnectFlag = false
        }
        hangout.isCompleted = true
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, configurations: config)
    let friend = Friend(name: "Test Friend")
    let hangout = Hangout(
        date: Date(),
        title: "Coffee",
        location: "Starbucks",
        isScheduled: true,
        friends: [friend]
    )
    
    HangoutCompletionView(hangout: hangout)
        .modelContainer(container)
}
