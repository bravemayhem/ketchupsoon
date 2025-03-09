import SwiftUI

struct ReviewKetchupIdeasView: View {
    // State variables
    @State private var selectedFriends = ["sarah", "jordan", "alex"]
    @State private var friendEmojis = ["🌟", "🎮", "🎵"]
    @State private var personalNote = "Really hope we can make coffee work!"
    @Environment(\.dismiss) private var dismiss
    
    // Suggestion data
    private let suggestions = [
        SuggestionItem(
            emoji: "☕",
            activity: "Coffee",
            location: "Café Luna",
            dateTime: "Saturday, March 15 • 2:00 PM",
            isMostLiked: true,
            colorHex: "#FF2D55"
        ),
        SuggestionItem(
            emoji: "🍽️",
            activity: "Brunch",
            location: "The Morning Spot",
            dateTime: "Sunday, March 16 • 11:00 AM",
            isMostLiked: false,
            colorHex: "#5E17EB"
        ),
        SuggestionItem(
            emoji: "🎮",
            activity: "Games",
            location: "Game Knight",
            dateTime: "Monday, March 17 • 6:30 PM",
            isMostLiked: false,
            colorHex: "#FF9500"
        )
    ]
    
    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer
            
            // MARK: - Main Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Spacer for status bar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                    
                    // MARK: - Header
                    headerView
                    
                    // MARK: - Friends Section
                    friendsSection
                    
                    // MARK: - Ideas Section
                    Text("review ketchup ideas ✨")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // MARK: - Suggestion Cards
                    ForEach(suggestions) { suggestion in
                        SuggestionCardView(suggestion: suggestion)
                    }
                    
                    // MARK: - Regenerate Button
                    Button(action: {
                        // Regenerate action
                    }) {
                        Text("regenerate ideas ↻")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(AppColors.cardBackground).opacity(0.5))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // MARK: - Personal Note
                    VStack(alignment: .leading, spacing: 10) {
                        Text("add a personal note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Add a note to your friends...", text: $personalNote)
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding()
                            .frame(height: 60)
                            .background(Color(AppColors.cardBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .clayMorphism()
                    }
                    
                    // MARK: - Send Button
                    Button(action: {
                        // Send action
                    }) {
                        Text("send to friends 🙌")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(AppColors.gradient1Start), Color(AppColors.gradient1End)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(27)
                            .glow(color: AppColors.accent, radius: 8, opacity: 0.6)
                    }
                    
                    // Bottom spacer
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Gradient background
            AppColors.backgroundGradient.ignoresSafeArea()
            
            // Decorative blurred circles
            Circle()
                .fill(AppColors.purple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .offset(x: 150, y: -50)
            
            Circle()
                .fill(AppColors.accent.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .offset(x: -150, y: 500)
            
            // Small decorative elements
            Circle()
                .fill(AppColors.mint.opacity(0.8))
                .frame(width: 16, height: 16)
                .offset(x: -140, y: 180)
            
            Circle()
                .fill(AppColors.accentSecondary.opacity(0.8))
                .frame(width: 10, height: 10)
                .offset(x: 150, y: 400)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.purple.opacity(0.8))
                .frame(width: 15, height: 15)
                .rotationEffect(.degrees(30))
                .offset(x: 120, y: 220)
            
            // Noise texture overlay
            Rectangle()
                .fill(Color.white.opacity(0.03))
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Text("review")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5)
                
                Text(" ketchup ideas")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .kerning(-0.5)
            }
            
            // Back button
            Button(action: {
                dismiss()
            }) {
                Circle()
                    .fill(Color(AppColors.cardBackground))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("←")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .padding(.bottom, 15)
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("you and 3 friends")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 5) {
                ForEach(0..<selectedFriends.count, id: \.self) { index in
                    FriendChipView(
                        name: selectedFriends[index],
                        emoji: friendEmojis[index],
                        gradientIndex: index
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views and Models

struct SuggestionItem: Identifiable {
    let id = UUID()
    let emoji: String
    let activity: String
    let location: String
    let dateTime: String
    let isMostLiked: Bool
    let colorHex: String
    
    var title: String {
        return "\(activity) @ \(location)"
    }
}

struct SuggestionCardView: View {
    let suggestion: SuggestionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                // Activity icon
                ZStack {
                    Circle()
                        .fill(Color(hex: suggestion.colorHex).opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Text(suggestion.emoji)
                        .font(.system(size: 14))
                }
                
                // Activity title
                Text(suggestion.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Edit button
                Button(action: {
                    // Edit action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(AppColors.cardBackground))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        
                        Text("✏️")
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Date and time
            Text(suggestion.dateTime)
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            // Most liked badge (if applicable)
            if suggestion.isMostLiked {
                Text("most liked!")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(AppColors.gradient1Start), Color(AppColors.gradient1End)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ).opacity(0.2)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            }
            
            Spacer()
                .frame(height: 20)
        }
        .frame(height: 120)
        .background(Color(AppColors.cardBackground))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .clayMorphism()
    }
}

struct FriendChipView: View {
    let name: String
    let emoji: String
    let gradientIndex: Int
    
    private var gradient: LinearGradient {
        let gradients = [
            LinearGradient(
                gradient: Gradient(colors: [Color(AppColors.gradient1Start), Color(AppColors.gradient1End)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color(AppColors.gradient2Start), Color(AppColors.gradient2End)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            LinearGradient(
                gradient: Gradient(colors: [Color(AppColors.gradient3Start), Color(AppColors.gradient3End)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ]
        return gradients[gradientIndex % gradients.count]
    }
    
    var body: some View {
        HStack(spacing: 5) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color(AppColors.cardBackground))
                    .frame(width: 28, height: 28)
                
                Text(emoji)
                    .font(.system(size: 14))
            }
            
            // Name
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.trailing, 10)
        }
        .padding(.leading, 5)
        .frame(height: 36)
        .background(gradient)
        .cornerRadius(18)
        .glow(color: gradient.stops[0].color, radius: 6, opacity: 0.5)
    }
}

// MARK: - Preview
struct ReviewKetchupIdeasView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewKetchupIdeasView()
    }
} 