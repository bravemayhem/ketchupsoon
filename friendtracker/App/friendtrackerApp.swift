//
//  friendtrackerApp.swift
//  friendtracker
//
//  Created by Amineh Beltran on 12/11/24.
//

import SwiftUI
import SwiftData

@main
struct FriendTrackerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: Friend.self, Hangout.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            print("Successfully initialized container")
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !ProcessInfo.processInfo.isPreview {
                        Task { @MainActor in
                            await insertSampleDataIfNeeded()
                        }
                    }
                }
        }
        .modelContainer(container)
    }
    
    @MainActor
    private func insertSampleDataIfNeeded() async {
        let context = container.mainContext
        
        // Check if we already have data
        let descriptor = FetchDescriptor<Friend>()
        
        do {
            let existingFriends = try context.fetch(descriptor)
            guard existingFriends.isEmpty else { return }
            
            print("Inserting sample data...")
            
            // Create sample friends
            let friends: [(Friend, Date?)] = [
                (Friend(name: "Sarah Kim", lastSeen: Date(), location: FriendLocation.local.rawValue), Calendar.current.date(byAdding: .day, value: 1, to: Date())!),
                (Friend(name: "Mike Chen", lastSeen: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, location: FriendLocation.local.rawValue), Calendar.current.date(byAdding: .day, value: 3, to: Date())!),
                (Friend(name: "Lisa Wong", lastSeen: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, location: FriendLocation.local.rawValue), Calendar.current.date(byAdding: .day, value: 7, to: Date())!),
                (Friend(name: "Alex Johnson", lastSeen: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, location: FriendLocation.local.rawValue), nil),
                (Friend(name: "Diana Park", lastSeen: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, location: FriendLocation.local.rawValue), nil),
                (Friend(name: "James Lee", lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, location: FriendLocation.remote.rawValue), nil)
            ]
            
            // Insert friends and their hangouts
            for (friend, hangoutDate) in friends {
                context.insert(friend)
                
                if let date = hangoutDate {
                    let activity: String
                    let location: String
                    
                    switch friend.name {
                    case "Sarah Kim":
                        activity = "Coffee at Blue Bottle"
                        location = "Downtown"
                    case "Mike Chen":
                        activity = "Basketball Game"
                        location = "City Arena"
                    case "Lisa Wong":
                        activity = "Lunch"
                        location = "Italian Place"
                    default:
                        continue
                    }
                    
                    let hangout = Hangout(
                        date: date,
                        activity: activity,
                        location: location,
                        isScheduled: true,
                        friend: friend
                    )
                    context.insert(hangout)
                }
            }
            
            // Save changes
            try context.save()
            print("Sample data inserted successfully")
        } catch {
            print("Error inserting sample data: \(error)")
        }
    }
}

extension ProcessInfo {
    var isPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
