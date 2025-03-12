import SwiftUI
import SwiftData

struct FriendProfileView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @State private var isFavorite = false
    
    let friend: FriendModel
    
    // Profile appearance (using a default gradient for the ring)
    private let profileRingGradient: LinearGradient = AppColors.accentGradient2
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background with decorative elements
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Use our shared decorative elements
            DecorativeBubbles.profile
            BackgroundElementFactory.profileElements()
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile content view
                    friendProfileContentView
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .foregroundColor(.white)
            
            // Action buttons at bottom
            bottomActionButtons
            
            // Back button
            backButton
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Friend Profile Content View
    private var friendProfileContentView: some View {
        VStack(spacing: 20) {
            // Profile picture
            ZStack {
                // Gradient ring with enhanced glow effect
                Circle()
                    .fill(profileRingGradient)
                    .frame(width: 150, height: 150)
                    .modifier(GlowModifier(color: AppColors.purple, radius: 12, opacity: 0.8))
                    .shadow(color: AppColors.purple.opacity(0.5), radius: 8, x: 0, y: 0)
                
                // Profile image or emoji
                if let profileImageURL = friend.profileImageURL, !profileImageURL.isEmpty {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } placeholder: {
                        ZStack {
                            // Show emoji placeholder while loading
                            Text("😎")
                                .font(.system(size: 50))
                                .frame(width: 140, height: 140)
                            
                            // Add a progress indicator
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                } else {
                    // Emoji placeholder when no image is available
                    Text("😎")
                        .font(.system(size: 50))
                        .frame(width: 140, height: 140)
                }
            }
            .padding(.top, 20)
            
            // User name
            Text(friend.name)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(.top, 10)
            
            // User bio (as regular text)
            if let bio = friend.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
                    .padding(.top, 2)
            }
            
            // User info as simple text lines with emoji
            VStack(spacing: 12) {
                
                if let phoneNumber = friend.phoneNumber, !phoneNumber.isEmpty {
                    HStack(spacing: 8) {
                        Text("📱")
                        Text(formatPhoneForDisplay(phoneNumber))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let birthday = friend.birthday {
                    HStack(spacing: 8) {
                        Text("🎂")
                        Text(formatBirthdayForDisplay(birthday))
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .clayMorphism(cornerRadius: 30)
        .padding(.horizontal, 10)
    }
    
    // MARK: - Bottom Action Buttons
    private var bottomActionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                Button(action: {
                    // Handle message action
                }) {
                    Text("message")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 41/255, green: 37/255, blue: 97/255),
                                Color(red: 21/255, green: 17/255, blue: 50/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 41/255, green: 37/255, blue: 97/255, opacity: 0.5), radius: 4)
                }
                
                Button(action: {
                    // Handle schedule action
                }) {
                    HStack {
                        Text("schedule")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [AppColors.gradient2Start, AppColors.gradient2End]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .cornerRadius(25)
                    .shadow(color: AppColors.gradient2Start.opacity(0.5), radius: 5)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
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
    
    // MARK: - Helper Functions
    
    // Helper to format phone number for display
    private func formatPhoneForDisplay(_ phone: String) -> String {
        // Only keep digits
        let cleaned = phone.filter { $0.isNumber }
        
        // For short numbers, just return the original
        if cleaned.count < 10 {
            return phone
        }
        
        var formatted = ""
        
        // If there are more than 10 digits, add the extra digits at the beginning
        if cleaned.count > 10 {
            let extraDigits = String(cleaned.prefix(cleaned.count - 10))
            formatted += extraDigits + " "
        }
        
        // Get the last 10 digits for standard formatting
        let lastTenDigits = cleaned.count > 10 ? 
            String(cleaned.suffix(10)) : cleaned
        
        // Format the last 10 digits as (XXX) XXX-XXXX
        for (index, character) in lastTenDigits.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            formatted.append(character)
        }
        
        return formatted
    }
    
    // Helper to format birthday for display
    private func formatBirthdayForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    // Create a sample friend for preview
    let sampleFriend = FriendModel(
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

