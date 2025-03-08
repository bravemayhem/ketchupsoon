import SwiftUI
import SwiftData

struct Home1View: View {
    // State for selected friends
    @State private var selectedFriends: Set<String> = []
    @State private var searchText: String = ""
    
    // Sample friends data
    let friends = [
        FriendItem(id: "1", name: "sarah", emoji: "🌟", lastHangout: "3 months", gradient: [AppColors.gradient1Start, AppColors.gradient1End]),
        FriendItem(id: "2", name: "jordan", emoji: "🎮", lastHangout: "2 weeks", gradient: [AppColors.gradient2Start, AppColors.gradient2End]),
        FriendItem(id: "3", name: "alex", emoji: "🎵", lastHangout: "1 month", gradient: [AppColors.gradient3Start, AppColors.gradient3End]),
        FriendItem(id: "4", name: "taylor", emoji: "🎨", lastHangout: "yesterday", gradient: [AppColors.gradient4Start, AppColors.gradient4End]),
        FriendItem(id: "5", name: "marcus", emoji: "🚀", lastHangout: "3 weeks", gradient: [AppColors.gradient5Start, AppColors.gradient5End]),
        FriendItem(id: "6", name: "ethan", emoji: "🌲", lastHangout: "6 months", gradient: [AppColors.gradient1Start, AppColors.gradient1End]),
        FriendItem(id: "7", name: "sofia", emoji: "🏄", lastHangout: "8 months", gradient: [AppColors.gradient2Start, AppColors.gradient2End]),
        FriendItem(id: "8", name: "noah", emoji: "🎭", lastHangout: "5 months", gradient: [AppColors.gradient3Start, AppColors.gradient3End])
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    // Background decoration
                    Circle()
                        .fill(AppColors.purple.opacity(0.3))
                        .frame(width: 400, height: 400)
                        .blur(radius: 50)
                        .offset(x: 150, y: -50)
                    
                    Circle()
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 360, height: 360)
                        .blur(radius: 50)
                        .offset(x: -150, y: 300)
                    
                    // Playful small decorative elements
                    Circle()
                        .fill(AppColors.mint.opacity(0.8))
                        .frame(width: 16, height: 16)
                        .offset(x: -140, y: 180)
                    
                    Circle()
                        .fill(AppColors.accentSecondary.opacity(0.8))
                        .frame(width: 10, height: 10)
                        .offset(x: 150, y: 400)
                    
                    Circle()
                        .fill(AppColors.accent.opacity(0.8))
                        .frame(width: 12, height: 12)
                        .offset(x: -130, y: 500)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.purple.opacity(0.8))
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(30))
                        .offset(x: 120, y: 220)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppColors.accentSecondary.opacity(0.8))
                        .frame(width: 10, height: 10)
                        .rotationEffect(.degrees(-15))
                        .offset(x: -130, y: 380)
                    
                    // Actual content
                    VStack(alignment: .leading, spacing: 20) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.leading, 15)
                            
                            TextField("find your peeps...", text: $searchText)
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 14))
                            
                            Spacer()
                            
                            Image(systemName: "mic.fill")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.trailing, 15)
                        }
                        .frame(height: 50)
                        .background(Color(UIColor.systemGray6).opacity(0.3))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.top, 20)
                        
                        // Section title
                        HStack {
                            Text("select friends")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("for hangout")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.accent)
                            
                            Spacer()
                            
                            // Cancel button
                            Button(action: {
                                // Cancel action
                                selectedFriends.removeAll()
                            }) {
                                Text("X")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 50, height: 30)
                                    .background(Color(UIColor.systemGray6).opacity(0.3))
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 10)
                        
                        // Friend grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(friends) { friend in
                                FriendAvatarView(
                                    friend: friend,
                                    isSelected: selectedFriends.contains(friend.id),
                                    onSelect: {
                                        toggleFriendSelection(friend.id)
                                    }
                                )
                            }
                            
                            // Add friend button
                            Button(action: {
                                // Add friend action
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(
                                                Color.white.opacity(0.2),
                                                lineWidth: 2,
                                                dash: [4, 2]
                                            )
                                            .frame(width: 90, height: 90)
                                        
                                        Text("+")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    
                                    Text("add friend")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.top, 5)
                                }
                            }
                        }
                        .padding(.top, 10)
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(
            AppColors.backgroundGradient
                .ignoresSafeArea()
        )
        .overlay(
            // Bottom action panel
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Selection count
                    HStack {
                        Text("\(selectedFriends.count) friends selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 10) {
                        // Cancel button
                        Button(action: {
                            // Cancel action
                            selectedFriends.removeAll()
                        }) {
                            Text("cancel")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 100, height: 40)
                                .background(Color(UIColor.systemGray6).opacity(0.3))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        // Schedule button
                        Button(action: {
                            // Schedule action
                        }) {
                            HStack {
                                // Stylized tomato icon
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [AppColors.gradient1Start, AppColors.gradient1End]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 24, height: 24)
                                        .shadow(color: AppColors.accent.opacity(0.5), radius: 4, x: 0, y: 0)
                                    
                                    // Simple face for the tomato
                                    VStack(spacing: 0) {
                                        HStack(spacing: 4) {
                                            Rectangle()
                                                .frame(width: 7, height: 3)
                                                .cornerRadius(1)
                                                .foregroundColor(.black)
                                            
                                            Rectangle()
                                                .frame(width: 7, height: 3)
                                                .cornerRadius(1)
                                                .foregroundColor(.black)
                                        }
                                        .offset(y: -1)
                                        
                                        Path { path in
                                            path.move(to: CGPoint(x: -4, y: 3))
                                            path.addQuadCurve(to: CGPoint(x: 4, y: 3), control: CGPoint(x: 0, y: 5))
                                        }
                                        .stroke(Color.black, lineWidth: 1.5)
                                        .offset(y: 1)
                                    }
                                    .frame(width: 24, height: 24)
                                }
                                
                                Text("schedule ketchup")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 240, height: 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.gradient1Start, AppColors.gradient1End]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: AppColors.accent.opacity(0.5), radius: 6, x: 0, y: 0)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground).opacity(0.1))
                .background(.ultraThinMaterial)
            }
        )
    }
    
    // Toggle friend selection
    private func toggleFriendSelection(_ id: String) {
        if selectedFriends.contains(id) {
            selectedFriends.remove(id)
        } else {
            selectedFriends.insert(id)
        }
    }
}

// Friend model - renamed to avoid conflicts with existing Friend model
struct FriendItem: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let lastHangout: String
    let gradient: [Color]
}

// Friend Avatar View
struct FriendAvatarView: View {
    let friend: FriendItem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                ZStack {
                    // Selection glow for selected friends
                    if isSelected {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: friend.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .opacity(0.3)
                            .frame(width: 96, height: 96)
                    }
                    
                    // Main avatar circle
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: friend.gradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 90, height: 90)
                        .shadow(color: friend.gradient[0].opacity(0.3), radius: 6, x: 0, y: 0)
                    
                    // Inner circle
                    Circle()
                        .fill(AppColors.cardBackground)
                        .frame(width: 80, height: 80)
                    
                    // Emoji
                    Text(friend.emoji)
                        .font(.system(size: 30))
                    
                    // Selection indicator
                    if isSelected {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: friend.gradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("✓")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 30, y: -30)
                    }
                }
                
                // Friend name
                Text(friend.name)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, 5)
                
                // Last hangout label
                Text(friend.lastHangout)
                    .font(.system(size: 10))
                    .foregroundColor(friend.gradient[0].opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(friend.gradient[0].opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Preview
struct Home1View_Previews: PreviewProvider {
    static var previews: some View {
        Home1View()
    }
}