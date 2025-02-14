import SwiftUI
import SwiftData

struct FriendHangoutsSection: View {
    let hangouts: [Hangout]
    
    var body: some View {
        if !hangouts.isEmpty {
            Section("Upcoming Hangouts") {
                ForEach(hangouts) { hangout in
                    VStack(alignment: .leading, spacing: AppTheme.spacingTiny) {
                        Text(hangout.title)
                            .font(AppTheme.headlineFont)
                            .foregroundColor(AppColors.label)
                        Text(hangout.location)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                        Text(hangout.formattedDate)
                            .font(AppTheme.captionFont)
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                    .padding(.vertical, AppTheme.spacingTiny)
                }
            }
            .listRowBackground(AppColors.secondarySystemBackground)
        }
    }
}

#Preview("FriendHangoutsSection - With Hangouts") {
    let container: ModelContainer = {
        let schema = Schema([Friend.self, Tag.self, Hangout.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext
        
        let friend = Friend(
            name: "Alice Smith",
            lastSeen: Date(),
            location: "Local",
            phoneNumber: "(555) 123-4567"
        )
        context.insert(friend)
        
        let hangouts = [
            Hangout(
                date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                title: "Coffee",
                location: "Starbucks",
                isScheduled: true,
                friends: [friend]
            ),
            Hangout(
                date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                title: "Lunch",
                location: "Italian Restaurant",
                isScheduled: true,
                friends: [friend]
            )
        ]
        hangouts.forEach { context.insert($0) }
        
        return container
    }()
    
    let hangouts = try! container.mainContext.fetch(FetchDescriptor<Hangout>())
    
    return NavigationStack {
        List {
            FriendHangoutsSection(hangouts: hangouts)
        }
        .listStyle(.insetGrouped)
    }
    .modelContainer(container)
} 
