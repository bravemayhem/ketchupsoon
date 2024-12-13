import SwiftUI
import MessageUI

struct FriendDetailView: View {
    let friend: Friend
    @Environment(\.dismiss) private var dismiss
    @State private var showingMessageSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        ProfileImage(friend: friend)
                            .frame(width: 96, height: 96)
                        
                        Text(friend.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.primaryText)
                    }
                    .padding(.vertical)
                    
                    // Status Cards
                    HStack(spacing: 12) {
                        // Last Hangout Card
                        StatusCard(
                            icon: "clock",
                            title: "Last Hangout",
                            value: "\(friend.lastHangoutWeeks) weeks ago"
                        )
                        
                        // Frequency Card
                        StatusCard(
                            icon: "calendar",
                            title: "Frequency",
                            value: friend.frequency
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.primaryText)
                        
                        VStack(spacing: 12) {
                            // Message Button
                            QuickActionButton(
                                icon: "message.fill",
                                title: "Send Message",
                                isEnabled: friend.phoneNumber != nil
                            ) {
                                if MFMessageComposeViewController.canSendText() {
                                    showingMessageSheet = true
                                }
                            }
                            
                            // Log Hangout Button
                            QuickActionButton(
                                icon: "person.2.fill",
                                title: "Log Hangout",
                                style: .primary
                            ) {
                                // Handle hangout logging
                            }
                            
                            // Schedule Button
                            QuickActionButton(
                                icon: "calendar.badge.plus",
                                title: "Schedule Next Hangout"
                            ) {
                                // Handle scheduling
                            }
                        }
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageComposeView(recipient: friend.phoneNumber ?? "")
        }
    }
}

private struct StatusCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14))
            }
            .foregroundColor(Theme.secondaryText)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    var isEnabled: Bool = true
    var style: ButtonStyle = .secondary
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Theme.primary
            case .secondary: return Theme.cardBackground
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Theme.primary
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                style == .primary ? 
                    style.backgroundColor : 
                    style.backgroundColor.opacity(0.1)
            )
            .foregroundColor(isEnabled ? style.foregroundColor : .gray)
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

private struct MessageComposeView: UIViewControllerRepresentable {
    let recipient: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            dismiss()
        }
    }
}

#Preview {
    FriendDetailView(friend: SampleData.friends[0])
} 