import SwiftUI
import SwiftData

struct FriendProfileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false
    
    let friend: Friend
    
    // Mock data for UI elements not yet in the Friend model
    @State private var friendsSince = "Oct 2023"
    @State private var ketchupsCount = 8
    @State private var lastKetchup = "2 weeks ago"
    @State private var location = "San Francisco, CA"
    @State private var status = "weekend warrior"
    @State private var availabilityTimes = ["weekends", "weeknights"]
    @State private var favoriteActivities = ["🎮 gaming", "🍺 bars", "🏀 sports"]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with decorative elements
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Use our shared decorative elements
            DecorativeBubbles.profile
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    profileHeaderSection
                    
                    // Mutual friends section
                    mutualFriendsSection
                    
                    // Availability section
                    availabilitySection
                    
                    // Upcoming hangouts section
                    upcomingHangoutsSection
                    
                    // Add spacer to ensure content is visible above action buttons
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal)
            }
            
            // Action buttons (fixed at bottom)
            bottomActionButtons
            
            // Back button
            backButton
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 20) {
                    // Profile picture
                    profileAvatarView
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(friend.name)
                            .font(.system(size: 24, weight: .bold))
                        
                        Text(status)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColors.accent.opacity(0.2))
                            .cornerRadius(12)
                        
                        // Location
                        HStack {
                            Text("📍")
                            Text(location)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                        
                        // Friends since
                        HStack {
                            Text("🤝")
                            Text("friends since \(friendsSince)")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                        
                        // Ketchup count
                        HStack {
                            Text("🍅")
                            Text("\(ketchupsCount) ketchups together")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                // Bio
                if let bio = friend.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
                
                // Last hangout and favorite badges
                HStack {
                    Text("last ketchup: \(lastKetchup)")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    Button(action: {
                        isFavorite.toggle()
                    }) {
                        HStack {
                            Text(isFavorite ? "remove favorite" : "add to favorites")
                                .font(.system(size: 14))
                            Text(isFavorite ? "★" : "☆")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Profile Avatar
    private var profileAvatarView: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 120, height: 120)
                .shadow(color: AppColors.gradient2Start.opacity(0.3), radius: 8, x: 0, y: 0)
            
            // Profile image or emoji
            if let profileImageURL = friend.profileImageURL, !profileImageURL.isEmpty {
                AsyncImage(url: URL(string: profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .frame(width: 110, height: 110)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            } else {
                // Default emoji placeholder
                Circle()
                    .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Text("😎")
                            .font(.system(size: 44))
                    )
            }
        }
    }
    
    // MARK: - Mutual Friends Section
    private var mutualFriendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("mutual friends")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            MutualFriendsView()
        }
    }
    
    // MARK: - Availability Section
    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("availability")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            AvailabilityView(
                availabilityTimes: availabilityTimes,
                favoriteActivities: favoriteActivities
            )
        }
    }
    
    // MARK: - Upcoming Hangouts Section
    private var upcomingHangoutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("upcoming together")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            NoUpcomingHangoutsView()
        }
    }
    
    // MARK: - Bottom Action Buttons
    private var bottomActionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Button(action: {
                    // Handle schedule action
                }) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 24, height: 24)
                                .shadow(color: AppColors.gradient2End.opacity(0.8), radius: 5)
                            
                            // Tomato icon
                            Text("🍅")
                                .font(.system(size: 14))
                        }
                        
                        Text("schedule ketchup")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .cornerRadius(25)
                    .shadow(color: AppColors.gradient2Start.opacity(0.5), radius: 5)
                }
                
                Button(action: {
                    // Handle message action
                }) {
                    Text("message")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(width: 110)
                        .background(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(
                Rectangle()
                    .fill(Color(red: 10/255, green: 8/255, blue: 40/255, opacity: 0.95))
                    .edgesIgnoringSafeArea(.bottom)
            )
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

// MARK: - Mutual Friends View
struct MutualFriendsView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                // Friend 1
                VStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.18, blue: 0.33),
                                    Color(red: 1.0, green: 0.58, blue: 0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(red: 1.0, green: 0.18, blue: 0.33, opacity: 0.5), radius: 5)
                        
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 40, height: 40)
                        
                        Text("🌟")
                            .font(.system(size: 16))
                    }
                    
                    Text("sarah")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                // Friend 2
                VStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.58, blue: 0.0),
                                    Color(red: 1.0, green: 0.18, blue: 0.33)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(red: 1.0, green: 0.18, blue: 0.33, opacity: 0.5), radius: 5)
                        
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 40, height: 40)
                        
                        Text("🎵")
                            .font(.system(size: 16))
                    }
                    
                    Text("alex")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                // Friend 3
                VStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.0, green: 0.96, blue: 0.63),
                                    Color(red: 0.37, green: 0.09, blue: 0.92)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                            .shadow(color: Color(red: 0.0, green: 0.96, blue: 0.63, opacity: 0.5), radius: 5)
                        
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 40, height: 40)
                        
                        Text("🎨")
                            .font(.system(size: 16))
                    }
                    
                    Text("taylor")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                // +2 more
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color(red: 21/255, green: 17/255, blue: 50/255))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Text("+2")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    
                    Text("more")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                // See all button
                Button(action: {
                    // See all mutual friends
                }) {
                    Text("see all")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .cornerRadius(17)
                        .overlay(
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
    }
}

// MARK: - Availability View
struct AvailabilityView: View {
    var availabilityTimes: [String]
    var favoriteActivities: [String]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 31/255, green: 24/255, blue: 59/255, opacity: 0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Prefers hangouts on")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(availabilityTimes.joined(separator: " & "))
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 21/255, green: 17/255, blue: 50/255))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
                
                VStack(alignment: .leading) {
                    Text("Favorite hangout types")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack {
                        ForEach(favoriteActivities, id: \.self) { activity in
                            // Alternate colors for variety
                            let colorIndex = favoriteActivities.firstIndex(of: activity) ?? 0
                            let colors: [(Color, Color)] = [
                                (Color(red: 1.0, green: 0.18, blue: 0.33), Color(red: 1.0, green: 0.18, blue: 0.33, opacity: 0.2)),
                                (Color(red: 0.37, green: 0.09, blue: 0.92), Color(red: 0.37, green: 0.09, blue: 0.92, opacity: 0.2)),
                                (Color(red: 1.0, green: 0.58, blue: 0.0), Color(red: 1.0, green: 0.58, blue: 0.0, opacity: 0.2))
                            ]
                            let (textColor, bgColor) = colors[colorIndex % colors.count]
                            
                            Text(activity)
                                .font(.system(size: 10))
                                .foregroundColor(textColor.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(bgColor)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - No Upcoming Hangouts View
struct NoUpcomingHangoutsView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 21/255, green: 17/255, blue: 50/255, opacity: 0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.white.opacity(0.05),
                            style: StrokeStyle(
                                lineWidth: 1,
                                dash: [4, 2]
                            )
                        )
                )
            
            Text("no upcoming ketchups scheduled")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.5))
                .padding()
        }
        .frame(height: 70)
    }
}

// MARK: - Preview
#Preview {
    // Create a sample friend for preview
    let sampleFriend = Friend(
        name: "Jordan Chen",
        profileImageURL: nil,
        email: "jordan@example.com",
        phoneNumber: "+1 (555) 123-4567",
        bio: "Gaming enthusiast and craft beer connoisseur. Ask me about: 🎮 Elden Ring, 🏀 Warriors, 🍺 IPAs",
        birthday: Date()
    )
    
    return FriendProfileView(friend: sampleFriend)
        .preferredColorScheme(.dark)
} 