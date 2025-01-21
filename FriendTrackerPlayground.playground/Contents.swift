import SwiftUI
import SwiftData
import PlaygroundSupport

// MARK: - Preview Container Setup
let schema = Schema([Friend.self, Tag.self, Hangout.self])
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try! ModelContainer(for: schema, configurations: config)

// Create a sample friend
let context = container.mainContext
let friend = Friend(
    name: "Emma Thompson",
    lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
    location: "San Francisco",
    needsToConnectFlag: true,
    phoneNumber: "+1234567890",
    catchUpFrequency: .monthly
)

// Add a sample hangout
let hangout = Hangout(
    date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
    activity: "Coffee at Blue Bottle",
    location: "Hayes Valley",
    isScheduled: true,
    friend: friend
)

context.insert(friend)
context.insert(hangout)

// Create the preview
let previewView = NavigationStack {
    FriendDetailForm(friend: friend)
}
.modelContainer(container)

// Set the live view
PlaygroundPage.current.setLiveView(previewView) 