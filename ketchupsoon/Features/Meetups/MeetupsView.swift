import SwiftUI

struct MeetupsView: View {
    // State variables
    @State private var meetups = Meetup.samples
    @State private var showCreateMeetup = false
    @State private var selectedMeetup: Meetup?
    @State private var showDetailView = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer
            
            // MARK: - Main Content
            VStack(spacing: 0) {
                // MARK: - Header
                headerView
                
                // MARK: - Meetups List
                if meetups.isEmpty {
                    emptyStateView
                } else {
                    meetupListView
                }
            }
        }
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .sheet(isPresented: $showCreateMeetup) {
            CreateMeetupView()
        }
        .sheet(isPresented: $showDetailView) {
            if let selectedMeetup = selectedMeetup {
                MeetupDetailView(meetup: selectedMeetup)
            }
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
        HStack {
            Text("meetups")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .kerning(-0.5)
            
            Spacer()
            
            Button(action: {
                showCreateMeetup = true
            }) {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.gradient1Start,
                            AppColors.gradient1End
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text("+")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                    .glow(color: AppColors.accent, radius: 8, opacity: 0.6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 44) // Status bar space
        .padding(.bottom, 20)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 72))
                .foregroundColor(AppColors.textSecondary)
            
            Text("No meetups yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Create your first meetup by tapping the + button")
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showCreateMeetup = true
            }) {
                Text("Create a meetup")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 54)
                    .frame(minWidth: 200)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.gradient1Start, AppColors.gradient1End]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(27)
                    .glow(color: AppColors.accent, radius: 8, opacity: 0.6)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Meetup List View
    private var meetupListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(meetups) { meetup in
                    meetupCardView(meetup)
                        .onTapGesture {
                            selectedMeetup = meetup
                            showDetailView = true
                        }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Meetup Card View
    private func meetupCardView(_ meetup: Meetup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(meetup.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack {
                Text(meetup.dateTimeString)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("\(meetup.participants.count) friends")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack {
                // Display up to 3 participant avatars
                ZStack {
                    ForEach(0..<min(meetup.participants.count, 3), id: \.self) { i in
                        Circle()
                            .fill(AppColors.avatarGradients[i % AppColors.avatarGradients.count])
                            .frame(width: 32, height: 32)
                            .offset(x: CGFloat(-16 * i))
                    }
                }
                .frame(width: 64, alignment: .leading)
                
                Spacer()
                
                Text(meetup.activityType.emoji)
                    .font(.system(size: 20))
            }
            
            if let notes = meetup.notes {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(AppColors.cardBackground))
        .cornerRadius(16)
        .clayMorphism(cornerRadius: 16)
    }
}

struct MeetupsView_Previews: PreviewProvider {
    static var previews: some View {
        MeetupsView()
    }
} 