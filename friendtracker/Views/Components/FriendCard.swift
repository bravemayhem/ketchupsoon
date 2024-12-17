import SwiftUI

struct FriendCard: View {
    @EnvironmentObject private var theme: Theme
    let friend: Friend
    let buttonTitle: String
    let buttonStyle: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .black
            case .secondary, .outline: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary, .outline: return .primary
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(friend.name)
                .font(.title2)
                .bold()
                .foregroundColor(theme.primaryText)
            
            Text(friend.lastSeenText)
                .foregroundColor(theme.secondaryText)
            
            Text(friend.location)
                .foregroundColor(theme.secondaryText)
            
            HStack {
                Spacer()
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.primaryText, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .shadow(color: Color.black.opacity(theme.shadowOpacity), radius: theme.shadowRadius, x: theme.shadowOffset.x, y: theme.shadowOffset.y)
        )
    }
}

#Preview {
    FriendCard(
        friend: Friend(name: "Preview Friend"),
        buttonTitle: "Connect",
        buttonStyle: .primary,
        action: {}
    )
    .environmentObject(Theme.shared)
} 