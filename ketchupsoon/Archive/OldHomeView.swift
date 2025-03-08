/*
 * DEPRECATED: This file contains the old home view that is no longer in use.
 * We've switched to using Home1View as our main home page.
 * This file is kept for reference purposes only.
 */

import SwiftUI
import SwiftData

struct OldHomeView: View {
    // This view will display the home design from our Gen Z redesign
    
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
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.purple.opacity(0.8))
                        .frame(width: 15, height: 15)
                        .rotationEffect(.degrees(30))
                        .offset(x: 120, y: 220)
                    
                    // Actual content
                    VStack(alignment: .leading, spacing: 20) {

                        // Your Circle section - updated to "my crew"
                        Text("my crew")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        // Circle avatar rows
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 30) {
                                CircleAvatar(emoji: "🌟", name: "sarah", gradientColors: [AppColors.gradient1Start, AppColors.gradient1End])
                                CircleAvatar(emoji: "🚀", name: "alex", gradientColors: [AppColors.gradient2Start, AppColors.gradient2End])
                                CircleAvatar(emoji: "🎸", name: "jordan", gradientColors: [AppColors.gradient3Start, AppColors.gradient3End])
                                CircleAvatar(emoji: "🎨", name: "taylor", gradientColors: [AppColors.gradient4Start, AppColors.gradient4End])
                                AddCircleAvatar()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                        
                        // Friend updates section - updated to "the good stuff 💯"
                        Text("the good stuff 💯")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        // Promotion card
                        FriendUpdateCard(
                            gradientColors: [AppColors.gradient2Start, AppColors.gradient2End],
                            avatarEmoji: "🚀",
                            name: "alex",
                            timeAgo: "2h ago",
                            updateText: "just got promoted to senior designer! 🎉",
                            primaryButtonText: "hype them up!",
                            secondaryButtonText: "send confetti 🎊"
                        )
                        .padding(.bottom, 20)
                        
                        // Birthday card
                        FriendUpdateCard(
                            gradientColors: [AppColors.gradient1Start, AppColors.gradient1End],
                            avatarEmoji: "🌟",
                            name: "sarah",
                            timeAgo: "tomorrow!",
                            updateText: "birthday coming up! 🎂 gonna be epic",
                            primaryButtonText: "plan something!",
                            secondaryButtonText: "send birthday vibes"
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .overlay(
                // Quick Add FAB with glow effect
                ZStack {
                    Circle()
                        .fill(AppColors.accentGradient1)
                        .frame(width: 70, height: 70)
                        .shadow(color: AppColors.accent.opacity(0.5), radius: 12, x: 0, y: 0)
                    
                    Text("+")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            )
        }
        // Don't ignore safe area at the top to show system status bar
        .background(
            AppColors.backgroundGradient
                .ignoresSafeArea()
        )
    }
}

// MARK: - Supporting Views

// Circle Avatar component - Updated with claymorphism and glow
struct CircleAvatar: View {
    let emoji: String
    let name: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                    .shadow(color: gradientColors[0].opacity(0.3), radius: 6, x: 0, y: 0)
                
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 58, height: 58)
                
                Text(emoji)
                    .font(.system(size: 30))
            }
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .padding(.top, 5)
        }
    }
}

// Add Circle Avatar component - Updated with claymorphism
struct AddCircleAvatar: View {
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(0.3),
                        lineWidth: 2,
                        dash: [4, 2]
                    )
                    .frame(width: 64, height: 64)
                
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 58, height: 58)
                
                Text("+")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text("add")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 5)
        }
    }
}

// Friend Update Card component - Updated with claymorphism
struct FriendUpdateCard: View {
    let gradientColors: [Color]
    let avatarEmoji: String
    let name: String
    let timeAgo: String
    let updateText: String
    let primaryButtonText: String
    let secondaryButtonText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header with claymorphism
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .opacity(0.2)
                    .frame(height: 60)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                
                HStack {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 40, height: 40)
                        
                        Text(avatarEmoji)
                            .font(.system(size: 18))
                    }
                    
                    // Name and time
                    VStack(alignment: .leading) {
                        Text(name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
            }
            
            // Card content with claymorphism
            VStack(alignment: .leading, spacing: 10) {
                // Update message
                Text(updateText)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .background(Rectangle().fill(gradientColors[0].opacity(0.15)))
                    .cornerRadius(16)
                    .padding(.top, 15)
                
                // Action buttons with glow effect
                HStack(spacing: 10) {
                    // Primary button - with glow
                    Button(action: {}) {
                        Text(primaryButtonText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: gradientColors[0].opacity(0.5), radius: 6, x: 0, y: 0)
                    }
                    
                    // Secondary button - with claymorphism
                    Button(action: {}) {
                        Text(secondaryButtonText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(AppColors.cardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Tab Button for new bottom navigation
struct TabButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Pill indicator for active tab
            if isActive {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AppColors.accentGradient1)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 5)
                    .offset(y: -2)
            }
            
            Text(icon)
                .font(.system(size: 24))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Extensions

// Extension for creating rounded corners only on specific corners
extension View {
    func newcornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct newRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Extension for creating dashed borders
extension Shape {
    func strokeBorder<S>(_ content: S, lineWidth: CGFloat, dash: [CGFloat] = []) -> some View where S : ShapeStyle {
        return self
            .stroke(content, style: StrokeStyle(lineWidth: lineWidth, dash: dash))
    }
}

#Preview {
    OldHomeView()
}
