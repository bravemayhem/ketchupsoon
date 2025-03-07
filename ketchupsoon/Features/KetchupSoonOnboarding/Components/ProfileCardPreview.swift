import SwiftUI

struct ProfileCardPreview: View {
    let profileData: KetchupSoonOnboardingViewModel.ProfileData
    
    var body: some View {
        VStack(spacing: 0) {
            // Card header
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.2)),
                            Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 0.2))
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 80)
            
            // Profile content
            VStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 1.0)),
                                    Color(UIColor(red: 255/255, green: 58/255, blue: 94/255, alpha: 1.0))
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)), lineWidth: 4)
                        )
                        .offset(y: -40)
                        .zIndex(1)
                    
                    Text(profileData.avatarEmoji)
                        .font(.system(size: 32))
                        .offset(y: -40)
                        .zIndex(2)
                    
                    VStack(spacing: 4) {
                        Text(profileData.name.isEmpty ? "Taylor Morgan" : profileData.name)
                            .font(.custom("SpaceGrotesk-Bold", size: 20))
                            .foregroundColor(.white)
                        
                        Text(profileData.bio.isEmpty ? "just vibing ✨" : profileData.bio)
                            .font(.custom("SpaceGrotesk-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .lineLimit(2)
                        
                        HStack(spacing: 10) {
                            Text("0 friends")
                                .font(.custom("SpaceGrotesk-Regular", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.2)))
                                .cornerRadius(999)
                            
                            Text("0 meetups")
                                .font(.custom("SpaceGrotesk-Regular", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(UIColor(red: 100/255, green: 66/255, blue: 255/255, alpha: 0.2)))
                                .cornerRadius(999)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.7)))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(width: 320)
        .shadow(color: Color.black.opacity(0.1), radius: 12)
    }
} 