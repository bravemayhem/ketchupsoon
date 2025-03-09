import SwiftUI

struct CreateMeetupView: View {
    // State variables
    @State private var selectedFriends = ["sarah", "jordan", "alex"]
    @State private var assistanceType = 2 // 0: time, 1: activities, 2: both
    @State private var searchText = ""
    @State private var selectedActivity = 0 // 0: coffee, 1: food, 2: outdoors, 3: games
    @State private var showReviewIdeas = false // New state variable to control navigation
    @Environment(\.dismiss) private var dismiss
    
    // Friend emoji avatars
    let friendEmojis = ["🌟", "🎮", "🎵"]
    
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
                    
                    // MARK: - Friends Selection
                    friendSelectionView
                    
                    // MARK: - AI Magic
                    aiMagicView
                    
                    // MARK: - Date/Time Selection
                    dateTimeSelectionView
                    
                    // MARK: - Activity Selection
                    activitySelectionView
                    
                    // MARK: - Location Field
                    locationFieldView
                    
                    // MARK: - Submit Button
                    submitButtonView
                    
                    // Bottom spacer
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showReviewIdeas) {
            ReviewKetchupIdeasView()
        }
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
                Text("create a")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5)
                
                Text("meetup")
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
    
    // MARK: - Friend Selection View
    private var friendSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("who's coming?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(AppColors.cardBackground))
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .clayMorphism()
                
                // Friend avatars
                HStack(spacing: 30) {
                    ForEach(0..<selectedFriends.count, id: \.self) { index in
                        // FriendAvatarView is now moved to a shared component at Shared/Components/FriendAvatarView.swift
                        FriendAvatarView(
                            emoji: friendEmojis[index],
                            name: selectedFriends[index],
                            gradient: AppColors.avatarGradients[index % AppColors.avatarGradients.count]
                        )
                    }
                    
                    // Add friend button
                    Button(action: {
                        // Add friend action
                    }) {
                        VStack {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5,3]))
                                    .frame(width: 60, height: 60)
                                
                                Text("+")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            
                            Text("add")
                                .font(.system(size: 12))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - AI Magic View
    private var aiMagicView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ai magic ✨")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                ZStack {
                    Circle()
                        .fill(AppColors.purple.opacity(0.3))
                        .frame(width: 24, height: 24)
                    
                    Text("ai")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .padding(.leading, 5)
            }
            
            VStack(spacing: 20) {
                AIOptionButton(
                    title: "help find the best time",
                    isSelected: assistanceType == 0,
                    action: { assistanceType = 0 }
                )
                
                AIOptionButton(
                    title: "suggest fun activities",
                    isSelected: assistanceType == 1,
                    action: { assistanceType = 1 }
                )
                
                AIOptionButton(
                    title: "do both!",
                    isSelected: assistanceType == 2,
                    action: { assistanceType = 2 }
                )
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(AppColors.cardBackground))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(
                        gradient: Gradient(colors: [Color(AppColors.gradient2Start), Color(AppColors.gradient2End)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
            .clayMorphism()
        }
    }
    
    // MARK: - Date/Time Selection View
    private var dateTimeSelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("when works?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("date")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Button(action: {
                            // Date picker action
                        }) {
                            HStack {
                                Text("let ai suggest")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("📆")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            .padding(.horizontal, 15)
                            .frame(height: 45)
                            .background(Color(AppColors.cardBackground).opacity(0.7))
                            .cornerRadius(22.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22.5)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("time")
                            .font(.system(size: 14))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Button(action: {
                            // Time picker action
                        }) {
                            HStack {
                                Text("let ai suggest")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("⏰")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            .padding(.horizontal, 15)
                            .frame(height: 45)
                            .background(Color(AppColors.cardBackground).opacity(0.7))
                            .cornerRadius(22.5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22.5)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(AppColors.cardBackground))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clayMorphism()
        }
    }
    
    // MARK: - Activity Selection View
    private var activitySelectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("what's the vibe?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                ActivityButton(
                    emoji: "☕",
                    label: "coffee",
                    isSelected: selectedActivity == 0,
                    action: { selectedActivity = 0 }
                )
                
                ActivityButton(
                    emoji: "🍽️",
                    label: "food",
                    isSelected: selectedActivity == 1,
                    action: { selectedActivity = 1 }
                )
                
                ActivityButton(
                    emoji: "🥾",
                    label: "outdoors",
                    isSelected: selectedActivity == 2,
                    action: { selectedActivity = 2 }
                )
                
                ActivityButton(
                    emoji: "🎮",
                    label: "games",
                    isSelected: selectedActivity == 3,
                    action: { selectedActivity = 3 }
                )
            }
        }
    }
    
    // MARK: - Location Field View
    private var locationFieldView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("where at?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                TextField("search for a place...", text: $searchText)
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                
                Text("📍")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.trailing, 15)
            }
            .frame(height: 50)
            .background(Color(AppColors.cardBackground))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clayMorphism()
        }
    }
    
    // MARK: - Submit Button View
    private var submitButtonView: some View {
        Button(action: {
            // Show the review ideas view
            showReviewIdeas = true
        }) {
            Text("generate ideas 🚀")
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
        .padding(.top, 10)
    }
}

// MARK: - Supporting Views

// FriendAvatarView is now moved to a shared component at Shared/Components/FriendAvatarView.swift

struct AIOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Radio button
                ZStack {
                    Circle()
                        .fill(isSelected ? 
                              LinearGradient(
                                gradient: Gradient(colors: [Color(AppColors.gradient2Start), Color(AppColors.gradient2End)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ) : 
                              LinearGradient(
                                gradient: Gradient(colors: [Color(AppColors.cardBackground), Color(AppColors.cardBackground)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    if isSelected {
                        Text("✓")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }
                .glow(color: isSelected ? AppColors.purple : .clear, radius: 3, opacity: 0.6)
                
                // Option text
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}

struct ActivityButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? 
                              LinearGradient(
                                gradient: Gradient(colors: [Color(AppColors.gradient1Start), Color(AppColors.gradient1End)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ) : 
                              LinearGradient(
                                gradient: Gradient(colors: [Color(AppColors.cardBackground), Color(AppColors.cardBackground)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                        .frame(width: 70, height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    Text(emoji)
                        .font(.system(size: 28))
                }
                .glow(color: isSelected ? AppColors.accent : .clear, radius: 6, opacity: 0.6)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.7))
            }
        }
    }
}

// Preview
struct CreateMeetupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateMeetupView()
    }
} 