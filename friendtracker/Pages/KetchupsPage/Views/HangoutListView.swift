import SwiftUI
import SwiftData

struct HangoutListView: View {
    let title: String
    let hangouts: [Hangout]
    let maxItems: Int
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(hangouts.prefix(maxItems)) { hangout in
                    HangoutCard(hangout: hangout)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
        }
    }
}

#Preview {
    let friend = Friend(name: "Test Friend")
    let hangouts = [
        Hangout(
            date: Date().addingTimeInterval(86400),
            activity: "Coffee",
            location: "Starbucks",
            isScheduled: true,
            friend: friend
        ),
        Hangout(
            date: Date().addingTimeInterval(172800),
            activity: "Lunch",
            location: "Restaurant",
            isScheduled: true,
            friend: friend
        )
    ]
    
    return HangoutListView(title: "Upcoming", hangouts: hangouts, maxItems: 10)
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
} 