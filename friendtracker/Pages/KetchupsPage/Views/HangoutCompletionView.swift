import SwiftUI
import SwiftData

struct HangoutCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let hangout: Hangout
    @State private var showingMissedHangoutOptions = false
    @State private var showingCalendarOverlay = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Did your hangout with \(hangout.friend?.name ?? "") happen?")
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
                    hangout.friend?.needsToConnectFlag = true
                    modelContext.delete(hangout)
                    dismiss()
                }
                
                Button("Discard") {
                    hangout.friend?.needsToConnectFlag = false
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
        if let friend = hangout.friend {
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
        activity: "Coffee",
        location: "Starbucks",
        isScheduled: true,
        friend: friend
    )
    
    HangoutCompletionView(hangout: hangout)
        .modelContainer(container)
}
