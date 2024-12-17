import SwiftUI

struct FriendCard: View {
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
            case .secondary: return .clear
            case .outline: return .clear
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
            
            Text(friend.lastSeenText)
                .foregroundStyle(.secondary)
            
            Text(friend.location)
                .foregroundStyle(.secondary)
            
            HStack {
                Spacer()
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundStyle(buttonStyle.foregroundColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(buttonStyle.backgroundColor)
                                .stroke(Color.primary, lineWidth: buttonStyle == .outline ? 1 : 0)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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
} 