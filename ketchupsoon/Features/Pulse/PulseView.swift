import SwiftUI

struct PulseView: View {
    // State for tab selection
    @State private var selectedTab: PulseTab = .upcoming
    
    enum PulseTab {
        case upcoming, past, pending
    }
    
    var body: some View {
        ZStack {
            // Background with gradients
            backgroundGradient
            
            // Content
            VStack(spacing: 0) {
                // Header
                header
                
                // Tab Buttons
                tabButtons
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 20) {
                        upcomingPulseList
                        
                        emptyState
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 70) // Make room for bottom nav bar
                }
                
                Spacer(minLength: 0)
            }
        }
        .padding(.bottom, 80)
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        ZStack {
            // Main background using app's background gradient
            AppColors.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Decorative blurred circles
            Circle()
                .fill(AppColors.purple)
                .frame(width: 400, height: 400)
                .position(x: 350, y: 150)
                .opacity(0.3)
                .blur(radius: 50)
            
            Circle()
                .fill(AppColors.accent)
                .frame(width: 360, height: 360)
                .position(x: 50, y: 650)
                .opacity(0.2)
                .blur(radius: 50)
            
            // Decorative small elements
            Circle()
                .fill(AppColors.mint)
                .frame(width: 16, height: 16)
                .position(x: 40, y: 180)
                .opacity(0.8)
            
            Circle()
                .fill(AppColors.accentSecondary)
                .frame(width: 10, height: 10)
                .position(x: 350, y: 400)
                .opacity(0.8)
            
            Circle()
                .fill(AppColors.accent)
                .frame(width: 12, height: 12)
                .position(x: 70, y: 500)
                .opacity(0.8)
            
            // Noise overlay
            Rectangle()
                .fill(Color.white)
                .opacity(0.03)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    // MARK: - Header
    private var header: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(AppColors.backgroundPrimary.opacity(0.7))
                .frame(height: 60)
            
            HStack {
                Text("your")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("pulse")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.leading, 20)
        }
    }
    
    // MARK: - Tab Buttons
    private var tabButtons: some View {
        HStack(spacing: 10) {
            // Upcoming Tab
            Button(action: {
                selectedTab = .upcoming
            }) {
                Text("upcoming")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 40)
                    .background(
                        selectedTab == .upcoming ?
                        AppColors.accentGradient1 :
                        LinearGradient(
                            colors: [AppColors.cardBackground, AppColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: selectedTab == .upcoming ? 0 : 1)
                    )
                    .shadow(color: selectedTab == .upcoming ? AppColors.accent.opacity(0.8) : .clear, radius: 8, x: 0, y: 0)
            }
            
            // Past Tab
            Button(action: {
                selectedTab = .past
            }) {
                Text("past")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 100, height: 40)
                    .background(
                        selectedTab == .past ?
                        AppColors.accentGradient1 :
                        LinearGradient(
                            colors: [AppColors.cardBackground, AppColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: selectedTab == .past ? 0 : 1)
                    )
                    .shadow(color: selectedTab == .past ? AppColors.accent.opacity(0.8) : .clear, radius: 8, x: 0, y: 0)
            }
            
            // Pending Tab
            Button(action: {
                selectedTab = .pending
            }) {
                Text("pending")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 110, height: 40)
                    .background(
                        selectedTab == .pending ?
                        AppColors.accentGradient1 :
                        LinearGradient(
                            colors: [AppColors.cardBackground, AppColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: selectedTab == .pending ? 0 : 1)
                    )
                    .shadow(color: selectedTab == .pending ? AppColors.accent.opacity(0.8) : .clear, radius: 8, x: 0, y: 0)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Upcoming Pulse List
    private var upcomingPulseList: some View {
        VStack(spacing: 20) {
            // Pulse Card 1: Coffee with Taylor
            PulseCard(
                title: "Coffee with Taylor",
                date: "tomorrow",
                activity: "☕",
                activityDetails: "Café Luna • 10:00 AM",
                location: "123 Main St.",
                participants: [("🎨", AppColors.mint)],
                gradientColors: [AppColors.gradient1Start, AppColors.gradient1End]
            )
            
            // Pulse Card 2: Group Hike & Picnic
            PulseCard(
                title: "Group Hike & Picnic",
                date: "Sat, Mar 15",
                activity: "🥾",
                activityDetails: "Sunset Trail • 2:00 PM",
                location: "Pine Ridge Park",
                participants: [
                    ("🌟", AppColors.accent),
                    ("🎮", AppColors.purple),
                    ("🎵", AppColors.accentSecondary)
                ],
                hasMoreParticipants: true,
                gradientColors: [AppColors.gradient2Start, AppColors.gradient2End]
            )
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground.opacity(0.3))
                .frame(height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            Color.white.opacity(0.05),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 2])
                        )
                )
            
            VStack(spacing: 10) {
                Text("that's all for now!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.5))
                
                Text("check back later for more")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.3))
            }
        }
    }
}

// MARK: - Pulse Card Component
struct PulseCard: View {
    let title: String
    let date: String
    let activity: String
    let activityDetails: String
    let location: String
    let participants: [(emoji: String, color: Color)]
    var hasMoreParticipants: Bool = false
    let gradientColors: [Color]
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Card Background
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.cardBackground)
                .frame(height: hasMoreParticipants ? 190 : 170)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Gradient Accent Bar
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 8, height: hasMoreParticipants ? 190 : 170)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Title & Date
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(date)
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                // Activity Details
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppColors.accent.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Text(activity)
                            .font(.system(size: 14))
                    }
                    
                    Text(activityDetails)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.8))
                }
                
                // Location & Map
                HStack {
                    Text(location)
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    Button(action: {
                        // Open map
                    }) {
                        Text("map 🗺️")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                
                // Participants
                VStack(alignment: .leading, spacing: 10) {
                    Text("with")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                    
                    HStack(spacing: 6) {
                        ForEach(0..<participants.count, id: \.self) { index in
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [participants[index].color, participants[index].color.opacity(0.7)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                
                                Text(participants[index].emoji)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if hasMoreParticipants {
                            Text("+ 1 more")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColors.cardBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button(action: {
                        // Reschedule action
                    }) {
                        Text("reschedule")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: gradientColors[0].opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        // Message action
                    }) {
                        Text("message")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        // Cancel action
                    }) {
                        Text("cancel")
                            .font(.system(size: 12))
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.cardBackground)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(20)
            .padding(.leading, 8)
        }
    }
}

// MARK: - Preview
struct PulseView_Previews: PreviewProvider {
    static var previews: some View {
        PulseView()
            .preferredColorScheme(.dark)
    }
} 
