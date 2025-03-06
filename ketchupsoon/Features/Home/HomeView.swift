import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Milestone.date, order: .reverse) private var allMilestones: [Milestone]
    @Query(filter: #Predicate<Friend> { $0._needsToConnectFlag == true }) private var wishlistFriends: [Friend]
    
    // Query all hangouts and filter in computed property
    @Query(sort: \Hangout.date) private var allHangouts: [Hangout]
    
    // Computed property to filter hangouts
    var upcomingHangouts: [Hangout] {
        allHangouts.filter { $0.date > Date() && !$0.isCompleted }
    }
    
    // Computed property to get recent and upcoming moments
    var milestones: [Milestone] {
        // Get moments from the last 2 weeks and upcoming 2 weeks
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        
        return allMilestones.filter { milestone in
            !milestone.isArchived && 
            milestone.date >= twoWeeksAgo && 
            milestone.date <= twoWeeksFromNow
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Activity summary section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Your Circle Activity")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(upcomingHangouts.count + wishlistFriends.count) active connections")
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    
                    HStack(spacing: 15) {
                        ActivityCard(
                            title: "Upcoming",
                            value: "\(upcomingHangouts.count)",
                            subtitle: "Ketchups",
                            icon: "calendar",
                            color: LinearGradient(
                                colors: [AppColors.accent, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        
                        ActivityCard(
                            title: "Wishlist",
                            value: "\(wishlistFriends.count)",
                            subtitle: "Friends",
                            icon: "star",
                            color: LinearGradient(
                                colors: [Color(hex: "6B66FF"), Color(hex: "9146FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.secondarySystemBackground)
                )
                .padding(.horizontal)
                
                // Upcoming Ketchups section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Upcoming Ketchups")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: KetchupsView(showConfetti: .constant(false))) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    
                    if !upcomingHangouts.isEmpty {
                        ForEach(upcomingHangouts.prefix(2)) { hangout in
                            KetchupCardView(hangout: hangout)
                        }
                    } else {
                        EmptyStateCard(
                            title: "No Upcoming Ketchups",
                            message: "Time to schedule some quality time with friends!",
                            buttonText: "Schedule Ketchup",
                            icon: "calendar.badge.plus"
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.secondarySystemBackground)
                )
                .padding(.horizontal)
                
                // Wishlist section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Your Wishlist")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: WishlistView(showConfetti: .constant(false))) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    
                    if !wishlistFriends.isEmpty {
                        ForEach(wishlistFriends.prefix(2)) { friend in
                            FriendWishlistCardView(friend: friend)
                        }
                    } else {
                        EmptyStateCard(
                            title: "No Friends in Wishlist",
                            message: "Add friends you want to catch up with soon!",
                            buttonText: "Add to Wishlist",
                            icon: "person.fill.badge.plus"
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.secondarySystemBackground)
                )
                .padding(.horizontal)
                
                // New Moments section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Moments")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        NavigationLink(destination: MomentsView()) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    
                    if milestones.isEmpty {
                        EmptyStateCard(
                            title: "No Recent Moments",
                            message: "Stay updated on important events in your friends' lives.",
                            buttonText: "Add Moment",
                            icon: "party.popper"
                        )
                        .onTapGesture {
                            createSampleMoments()
                        }
                    } else {
                        ForEach(milestones.prefix(2)) { milestone in
                            MomentCard(milestone: milestone)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.secondarySystemBackground)
                )
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .background(
                ZStack {
                    // Background decorative elements like the blobs from the HTML design
                    Circle()
                        .fill(Color(hex: "6B66FF").opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: 150, y: -50)
                    
                    Circle()
                        .fill(Color(hex: "FF6B6B").opacity(0.3))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -150, y: 500)
                    
                    Circle()
                        .fill(Color(hex: "9146FF").opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: 50, y: 300)
                }
            )
        }
        .background(AppColors.systemBackground)
        .onAppear {
            // Initialize sample data for preview/demo purposes
            if ProcessInfo.processInfo.isPreview && allMilestones.isEmpty {
                createSampleMoments()
            }
        }
    }
    
    private func createSampleMoments() {
        // Only create samples if we have friends but no moments
        if !allMilestones.isEmpty { return }
        
        let sampleMoments = [
            (type: MilestoneType.newJob, title: "Started at Apple as Senior Designer", description: "After 5 years at Google, excited for this new chapter!", daysOffset: -3),
            (type: MilestoneType.birthday, title: "Turning 30!", description: "Celebrating with a small dinner party at home.", daysOffset: 5),
            (type: MilestoneType.graduation, title: "Graduated from Stanford", description: "Finally got my Masters in Computer Science!", daysOffset: -7)
        ]
        
        let friendsToUse = wishlistFriends.isEmpty ? 
            (try? modelContext.fetch(FetchDescriptor<Friend>())) ?? [] : 
            Array(wishlistFriends)
        
        guard !friendsToUse.isEmpty else { return }
        
        for (index, momentData) in sampleMoments.enumerated() {
            let friendIndex = index % friendsToUse.count
            let friend = friendsToUse[friendIndex]
            
            let date = Calendar.current.date(byAdding: .day, value: momentData.daysOffset, to: Date()) ?? Date()
            
            // Create a new moment using the proper SwiftData model
            friend.addMilestone(
                type: momentData.type,
                title: momentData.title,
                description: momentData.description,
                date: date
            )
        }
        
        // Save changes
        try? modelContext.save()
    }
}

// Activity Card Component
struct ActivityCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: LinearGradient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.system(size: 36, weight: .bold))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryLabel)
                    .padding(.leading, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.systemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Custom KetchupCard View for real data
struct KetchupCardView: View {
    let hangout: Hangout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hangout.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(formattedDateTime)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryLabel)
            }
            
            HStack {
                // Avatar stack
                ZStack(alignment: .leading) {
                    if hangout.friends.first != nil {
                        Circle()
                            .fill(LinearGradient(
                                colors: [AppColors.accent, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                    }
                    
                    if hangout.friends.count > 1 {
                        Circle()
                            .fill(Color(hex: "6B66FF").opacity(0.9))
                            .frame(width: 32, height: 32)
                            .padding(.leading, 16)
                    }
                }
                
                Text(friendsText)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryLabel)
                    .padding(.leading, 8)
                
                Spacer()
                
                Text("Upcoming")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accent.opacity(0.2))
                    .foregroundColor(AppColors.accent)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.systemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var formattedDateTime: String {
        let date = hangout.date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var locationText = ""
        if !hangout.location.isEmpty {
            locationText = " • \(hangout.location)"
        }
        
        return "\(dateFormatter.string(from: date))\(locationText)"
    }
    
    private var friendsText: String {
        if hangout.friends.isEmpty {
            return "No friends added"
        } else if hangout.friends.count == 1 {
            return "with \(hangout.friends[0].name)"
        } else {
            return "with \(hangout.friends[0].name) and \(hangout.friends.count - 1) more"
        }
    }
}

// Custom FriendWishlistCard for real data
struct FriendWishlistCardView: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            Circle()
                .fill(LinearGradient(
                    colors: [AppColors.accent, Color.orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Last seen \(friend.lastSeenText)")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryLabel)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text("Schedule")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.systemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Empty State Card Component
struct EmptyStateCard: View {
    let title: String
    let message: String
    let buttonText: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppColors.secondaryLabel)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryLabel)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Text(buttonText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.systemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Moment Card Component
struct MomentCard: View {
    let milestone: Milestone
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Friend avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [AppColors.accent, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: milestone.type.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.friendName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(milestone.title)
                        .font(.subheadline)
                        .foregroundColor(AppColors.label)
                }
                
                Spacer()
                
                // Date badge
                Text(milestone.timeframe)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryLabel)
            }
            
            if let description = milestone.milestoneDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryLabel)
                    .padding(.top, 4)
                    .padding(.leading, 52) // Align with the text above
            }
            
            HStack {
                Spacer()
                
                // Milestone type badge
                Text(milestone.type.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(milestone.type.color.opacity(0.2))
                    .foregroundColor(milestone.type.color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.systemBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// Replace the #Preview macro with a PreviewProvider
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: ketchupsoon.Milestone.self, Friend.self, Hangout.self, Tag.self,
                configurations: config
            )
                    
            return AnyView(HomeView()
                .modelContainer(container))
        } catch {
            return AnyView(Text("Failed to create preview: \(error.localizedDescription)"))
        }
    }
} 
