import SwiftUI

struct FriendCardStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    static let primary = FriendCardStyle(
        backgroundColor: .blue,
        foregroundColor: .white
    )
    
    static let secondary = FriendCardStyle(
        backgroundColor: Color(.systemBackground),
        foregroundColor: .blue
    )
}

struct FriendCard: View {
    let friend: Friend
    let buttonTitle: String
    let style: FriendCardStyle
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend name and last seen
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 18, weight: .semibold))
                Text(friend.lastSeenText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Location
            Text(friend.location)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // Connect button
            Button(action: action) {
                Text(buttonTitle)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(style.backgroundColor)
                    .foregroundColor(style.foregroundColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    FriendCard(
        friend: Friend(name: "John Doe"),
        buttonTitle: "Connect",
        style: .secondary,
        action: {}
    )
} 