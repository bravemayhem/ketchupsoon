import SwiftUI

struct ProfileImage: View {
    let friend: Friend
    
    var body: some View {
        Group {
            if let profileImage = friend.profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
            } else {
                InitialsAvatar(name: friend.name)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 3,
            x: 0,
            y: 2
        )
    }
}

struct InitialsAvatar: View {
    let name: String
    
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .prefix(2)
            .map(String.init)
            .joined()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.secondaryBackground)
            
            Text(initials)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.primaryText)
        }
    }
} 