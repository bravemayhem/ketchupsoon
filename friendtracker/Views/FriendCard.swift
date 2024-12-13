import SwiftUI

struct FriendCard: View {
    let friend: Friend
    @State private var showingDetail = false
    
    var body: some View {
        CardButton(
            friend: friend,
            showingDetail: $showingDetail
        )
    }
}

// Simplified button component
private struct CardButton: View {
    let friend: Friend
    @Binding var showingDetail: Bool
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            CardContent(friend: friend)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            FriendDetailView(friend: friend)
        }
    }
}

// Simplified content component
private struct CardContent: View {
    let friend: Friend
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                // Top section with name and badges
                VStack(alignment: .leading, spacing: 8) {
                    // Name row
                    Text(friend.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Theme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    
                    // Badges row
                    HStack(spacing: 8) {
                        if friend.isInnerCircle {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("Inner Circle")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Theme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.primary.opacity(0.1))
                            )
                        }
                        
                        if friend.isLocal {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                Text("Local")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(Theme.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.secondaryText.opacity(0.1))
                            )
                        }
                    }
                }
                
                Divider()
                    .background(Theme.cardBorder)
                    .padding(.vertical, 2)
                
                // Bottom section with info and photo
                HStack(alignment: .center) {
                    // Info column
                    VStack(alignment: .leading, spacing: 6) {
                        // Frequency row
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                            Text(friend.frequency)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(Theme.secondaryText)
                        
                        
                        // Last hangout row
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                            Text("\(friend.lastHangoutWeeks) weeks since last hangout")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(Theme.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Profile photo
                    ProfileImage(friend: friend)
                        .frame(width: 64, height: 64)
                }
                .padding(.top, -4)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            // Status tags overlay
            HStack(spacing: 8) {
                if friend.isActive {
                    ActiveTag()
                }
                if friend.isOverdue {
                    OverdueTag()
                }
            }
            .padding(12)
        }
        .background(NeoBrutalistBackground())
        .padding(.horizontal)
    }
}

// Updated OverdueTag with improved styling
private struct OverdueTag: View {
    var body: some View {
        Text("overdue")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "#E57373"))
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

// New ActiveTag component
private struct ActiveTag: View {
    var body: some View {
        Text("active")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "#4CAD73")) // Green color for active status
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 2,
                x: 0,
                y: 1
            )
    }
}

// Updated ProfileImage with improved styling
private struct ProfileImage: View {
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

// New InitialsAvatar component
private struct InitialsAvatar: View {
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

#Preview {
    FriendCard(friend: Friend(
        id: UUID(),
        name: "John Doe",
        frequency: "Weekly check-in",
        lastHangoutWeeks: 2,
        phoneNumber: "+1234567890",
        isInnerCircle: true,
        isLocal: true,
        photoData: nil
    ))
} 