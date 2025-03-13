import SwiftUI

struct MeetupDetailView: View {
    let meetup: MeetupModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // MARK: - Background
            AppColors.backgroundGradient.ignoresSafeArea()
            
            // MARK: - Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Spacer for status bar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 44)
                    
                    // MARK: - Header
                    headerView
                    
                    // MARK: - Activity Badge
                    activityBadgeView
                    
                    // MARK: - Details
                    detailsView
                    
                    // MARK: - Participants
                    participantsView
                    
                    // MARK: - Notes
                    if let notes = meetup.notes {
                        notesView(notes)
                    }
                    
                    // MARK: - Action Buttons
                    actionButtonsView
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meetup.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .kerning(-0.5)
                
                Text(meetup.formattedDate)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
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
    
    // MARK: - Activity Badge
    private var activityBadgeView: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(meetup.activityTypeEnum.gradient)
                    .frame(width: 70, height: 70)
                    .glow(color: meetup.activityTypeEnum.gradient.stops[0].color, radius: 6, opacity: 0.5)
                
                Text(meetup.activityTypeEnum.emoji)
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meetup.activityTypeEnum.name.capitalized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                if meetup.isAiGenerated {
                    HStack {
                        Text("AI generated")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        
                        ZStack {
                            Circle()
                                .fill(AppColors.purple.opacity(0.3))
                                .frame(width: 18, height: 18)
                            
                            Text("ai")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(AppColors.cardBackground))
        .cornerRadius(16)
        .clayMorphism(cornerRadius: 16)
    }
    
    // MARK: - Details View
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(meetup.relativeDateString)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(meetup.timeString)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text(meetup.location)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("\(meetup.participants.count) friends")
                            .foregroundColor(.white)
                    }
                }
            }
            .font(.system(size: 16))
        }
        .padding()
        .background(Color(AppColors.cardBackground))
        .cornerRadius(16)
        .clayMorphism(cornerRadius: 16)
    }
    
    // MARK: - Participants View
    private var participantsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Who's coming")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                ForEach(0..<meetup.participants.count, id: \.self) { index in
                    let name = meetup.participants[index]
                    
                    VStack {
                        ZStack {
                            Circle()
                                .fill(AppColors.avatarGradients[index % AppColors.avatarGradients.count])
                                .frame(width: 60, height: 60)
                                .glow(color: AppColors.avatarGradients[index % AppColors.avatarGradients.count].stops[0].color, radius: 5, opacity: 0.5)
                            
                            Circle()
                                .fill(Color(AppColors.cardBackground))
                                .frame(width: 52, height: 52)
                            
                            Text(AppColors.avatarEmoji(for: name))
                                .font(.system(size: 20))
                        }
                        
                        Text(name)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(AppColors.cardBackground))
        .cornerRadius(16)
        .clayMorphism(cornerRadius: 16)
    }
    
    // MARK: - Notes View
    private func notesView(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(notes)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(AppColors.cardBackground))
        .cornerRadius(16)
        .clayMorphism(cornerRadius: 16)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // RSVP action
            }) {
                Text("I'm going! 🙌")
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
            
            Button(action: {
                // Share action
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    
                    Text("Share with friends")
                        .font(.system(size: 16))
                }
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(AppColors.cardBackground))
                .cornerRadius(27)
                .overlay(
                    RoundedRectangle(cornerRadius: 27)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.top, 10)
    }
}

struct MeetupDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MeetupDetailView(meetup: MeetupModel.samples[0])
    }
}

// MARK: - LinearGradient Extension
extension LinearGradient {
    var stops: [Gradient.Stop] {
        (Mirror(reflecting: self).descendant("gradient") as? Gradient)?.stops ?? []
    }
} 