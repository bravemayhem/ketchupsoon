import SwiftUI
import SwiftData

struct HangoutCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let hangout: Hangout
    
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
                        handleMissedHangout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Hangout Check-in")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func markHangoutComplete() {
        if let friend = hangout.friend {
            friend.lastSeen = hangout.date // Directly set the date instead of using updateLastSeen()
            friend.needsToConnectFlag = false
        }
        hangout.isCompleted = true
        dismiss()
    }
    
    private func handleMissedHangout() {
        if let friend = hangout.friend {
            // Reset the scheduled state
            hangout.isScheduled = false
            
            // Show options for handling missed hangout
            Task { @MainActor in
                let alert = UIAlertController(
                    title: "What would you like to do?",
                    message: "How would you like to handle the missed hangout?",
                    preferredStyle: .actionSheet
                )
                
                alert.addAction(UIAlertAction(title: "Reschedule", style: .default) { _ in
                    // Keep them in scheduled view but mark as needing reschedule
                    hangout.needsReschedule = true
                    dismiss()
                })
                
                alert.addAction(UIAlertAction(title: "Move to To Connect List", style: .default) { _ in
                    friend.needsToConnectFlag = true
                    modelContext.delete(hangout)
                    dismiss()
                })
                
                alert.addAction(UIAlertAction(title: "Hold Off", style: .default) { _ in
                    friend.needsToConnectFlag = false
                    modelContext.delete(hangout)
                    dismiss()
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    dismiss()
                })
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let viewController = windowScene.windows.first?.rootViewController {
                    viewController.present(alert, animated: true)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Friend.self, configurations: config)
    let friend = Friend(name: "Test Friend")
    let hangout = Hangout(
        date: Date(),
        activity: "Coffee",
        location: "Starbucks",  // Add location
        isScheduled: true,      // Add isScheduled
        friend: friend
    )
    
    HangoutCompletionView(hangout: hangout)
        .modelContainer(container)
}
