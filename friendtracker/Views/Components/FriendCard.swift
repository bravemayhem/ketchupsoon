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
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ProfileImage(friend: friend)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(friend.name)
                        .font(.title3)
                        .bold()
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(friend.lastSeenText)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                    
                    Text(friend.location)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundColor(buttonStyle.foregroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(buttonStyle.backgroundColor)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 4
                )
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