import SwiftUI
import MessageUI

struct FriendDetailView: View {
    let friend: Friend
    @Environment(\.dismiss) private var dismiss
    @State private var showingMessageSheet = false
    @State private var messageResult: MessageComposeResult?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Last Hangout Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Hangout")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text("\(friend.lastHangoutWeeks) weeks ago")
                            .foregroundColor(friend.isOverdue ? .red : .primary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Availability Section (placeholder)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Availability")
                        .font(.headline)
                    Text("Wednesday evenings")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if MFMessageComposeViewController.canSendText() {
                                showingMessageSheet = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Send Message")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(friend.phoneNumber != nil ? .blue : .gray)
                            .cornerRadius(8)
                        }
                        .disabled(friend.phoneNumber == nil)
                        .sheet(isPresented: $showingMessageSheet) {
                            MessageComposeView(
                                recipient: friend.phoneNumber ?? "",
                                result: $messageResult
                            )
                        }
                        
                        NavigationLink(destination: SchedulerView(selectedFriend: friend)) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Schedule")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(friend.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    let recipient: String
    @Binding var result: MessageComposeResult?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.result = result
            controller.dismiss(animated: true)
        }
    }
} 