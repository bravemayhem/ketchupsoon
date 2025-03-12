import SwiftUI
import SwiftData

// Import the shared component
import SwiftUI

struct HomeView: View {
    // State for selected friends
    @State private var selectedFriends: Set<String> = []
    @State private var searchText: String = ""
    @State private var pendingFriendRequests: Int = 3
    @State private var navigationActive = false
    
    // Sample friends data with complete details
    let friends = [
        FriendItem(
            id: "1", 
            name: "Sarah Johnson", 
            bio: "Adventure seeker and coffee enthusiast. Always up for hiking or trying new cafes.",
            phoneNumber: "+1 (206) 555-1234",
            email: "sarah.j@example.com",
            birthday: Date(timeIntervalSince1970: 791394000), // 1995-02-30
            emoji: "🌟", 
            lastHangout: "3 months", 
            gradient: [AppColors.gradient1Start, AppColors.gradient1End]
        ),
        FriendItem(
            id: "2", 
            name: "Jordan Chen", 
            bio: "Gaming enthusiast and craft beer connoisseur. Ask me about: 🎮 Elden Ring, 🏀 Warriors, 🍺 IPAs",
            phoneNumber: "+1 (415) 555-6789",
            email: "jordan.c@example.com",
            birthday: Date(timeIntervalSince1970: 759931200), // 1994-01-15
            emoji: "🎮", 
            lastHangout: "2 weeks", 
            gradient: [AppColors.gradient2Start, AppColors.gradient2End]
        ),
        FriendItem(
            id: "3", 
            name: "Alex Rivera", 
            bio: "Music producer by day, foodie by night. Let's catch a show or try that new restaurant!",
            phoneNumber: "+1 (512) 555-1212",
            email: "alex.r@example.com",
            birthday: Date(timeIntervalSince1970: 823046400), // 1996-01-01
            emoji: "🎵", 
            lastHangout: "1 month", 
            gradient: [AppColors.gradient3Start, AppColors.gradient3End]
        ),
        FriendItem(
            id: "4", 
            name: "Taylor Smith", 
            bio: "Artist, photographer, eternal student. Currently obsessed with watercolor and film photography.",
            phoneNumber: "+1 (503) 555-3434",
            email: "taylor.s@example.com",
            birthday: Date(timeIntervalSince1970: 728265600), // 1993-02-01
            emoji: "🎨", 
            lastHangout: "yesterday", 
            gradient: [AppColors.gradient4Start, AppColors.gradient4End]
        ),
        FriendItem(
            id: "5", 
            name: "Marcus Wong", 
            bio: "Tech startup founder and space enthusiast. Always working on something new!",
            phoneNumber: "+1 (212) 555-5678",
            email: "marcus.w@example.com",
            birthday: Date(timeIntervalSince1970: 696988800), // 1992-01-05
            emoji: "🚀", 
            lastHangout: "3 weeks", 
            gradient: [AppColors.gradient5Start, AppColors.gradient5End]
        ),
        FriendItem(
            id: "6", 
            name: "Ethan Miller", 
            bio: "Outdoor guide and environmental activist. Ask me about the best hiking trails!",
            phoneNumber: "+1 (303) 555-7890",
            email: "ethan.m@example.com",
            birthday: Date(timeIntervalSince1970: 855360000), // 1997-02-10
            emoji: "🌲", 
            lastHangout: "6 months", 
            gradient: [AppColors.gradient1Start, AppColors.gradient1End]
        ),
        FriendItem(
            id: "7", 
            name: "Sofia Rodriguez", 
            bio: "Surf instructor and marine biology student. The ocean is my second home.",
            phoneNumber: "+1 (619) 555-2345",
            email: "sofia.r@example.com",
            birthday: Date(timeIntervalSince1970: 886032000), // 1998-01-29
            emoji: "🏄", 
            lastHangout: "8 months", 
            gradient: [AppColors.gradient2Start, AppColors.gradient2End]
        ),
        FriendItem(
            id: "8", 
            name: "Noah Williams", 
            bio: "Theater director and improv coach. Life is a stage, and we're all players.",            
            phoneNumber: "+1 (312) 555-8765",
            email: "noah.w@example.com",
            birthday: Date(timeIntervalSince1970: 664675200), // 1991-01-25
            emoji: "🎭", 
            lastHangout: "5 months", 
            gradient: [AppColors.gradient3Start, AppColors.gradient3End]
        )
    ]
    
    var body: some View {
        NavigationStack {
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
                                        // Replace FriendAvatarView with our new component
                                        FriendAvatarWithProfileView(
                                            friend: friend,
                                            isSelected: selectedFriends.contains(friend.id),
                                            onSelect: {
                                                print("Friend \(friend.name) tapped for selection")
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
            .navigationBarHidden(true)
            .onAppear {
                print("HomeView appeared with NavigationStack")
            }
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
