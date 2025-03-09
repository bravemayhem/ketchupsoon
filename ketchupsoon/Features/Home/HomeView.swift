import SwiftUI
import SwiftData

// Import the shared component
import SwiftUI

struct HomeView: View {
    // State for selected friends
    @State private var selectedFriends: Set<String> = []
    @State private var searchText: String = ""
    @State private var pendingFriendRequests: Int = 3
    
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
        ZStack(alignment: .bottom) { // Use ZStack for layering with alignment at bottom
            // Main content
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
                        VStack(alignment: .leading, spacing: 10) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.leading, 15)
                                
                                ZStack(alignment: .leading) {
                                    
                                    TextField("", text: $searchText)
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 14))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.trailing, 15)
                            }
                            .frame(height: 40)
                            .background(Color(UIColor.systemGray6).opacity(0.3))
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.top, 20)
                            
                            // Consolidated section title
                            HStack {
                                Text("your friends")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
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
                            .padding(.top, 20)
                            
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
                        
                            }
                            .padding(.top, 10)
                            
                            // Add extra spacing at the bottom to account for the action panel
                            Spacer(minLength: 150)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .background(
                AppColors.backgroundGradient
                    .ignoresSafeArea()
            )
            
            // Bottom action panel as a separate layer
            VStack(spacing: 0) {
                // Selection count and schedule button in the same row
                HStack {
                    Text("\(selectedFriends.count) friends selected")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Schedule button
                    Button(action: {
                        // Schedule action
                    }) {
                        HStack {                            
                            Text("schedule meetup")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 20)
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
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.systemBackground).opacity(0.1))
            .background(.ultraThinMaterial)
            .padding(.bottom, 70) // Add padding to position above tab bar
            .zIndex(999) // Ensure it's above everything
        }
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

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
