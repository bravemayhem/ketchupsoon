import SwiftUI

struct FriendCard: View {
    let friend: Friend
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(friend.name)
                        .font(.system(size: 22, weight: .regular, design: .default))
                        .foregroundColor(Theme.primaryText)
                    Spacer()
                    if friend.isOverdue {
                        Text("overdue")
                            .font(.system(size: 13, weight: .medium, design: .default))
                            .foregroundColor(Theme.error)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.error.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.error.opacity(0.5), lineWidth: 1.5)
                                    )
                            )
                            .shadow(color: Theme.error.opacity(0.3), radius: 4, x: 0, y: 0)
                    }
                }
                
                Text(friend.frequency)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Theme.secondaryText)
                
                Text("\(friend.lastHangoutWeeks) weeks since last hangout")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Theme.secondaryText.opacity(0.8))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.cardBackground)
                    .shadow(
                        color: Color.black.opacity(Theme.shadowOpacity),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.cardBorder, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            FriendDetailView(friend: friend)
        }
    }
}

#Preview {
    FriendCard(friend: Friend(
        name: "John Doe",
        frequency: "Weekly check-in",
        lastHangoutWeeks: 2,
        phoneNumber: "+1234567890"
    ))
} 