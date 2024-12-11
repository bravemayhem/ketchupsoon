import SwiftUI

struct FriendDetailView: View {
    let friend: Friend
    @Environment(\.dismiss) private var dismiss
    
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
                            // Handle message action
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                Text("Send Message")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
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