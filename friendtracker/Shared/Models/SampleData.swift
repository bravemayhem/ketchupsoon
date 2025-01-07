import Foundation
import SwiftData

actor SampleData {
    static let activities = [
        "Coffee",
        "Lunch",
        "Dinner",
        "Movie",
        "Walk",
        "Video Call",
        "Phone Call",
        "Game Night"
    ]
    
    @MainActor
    static func createPreviewContainer() -> ModelContainer {
        let schema = Schema([Friend.self, Hangout.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let modelContext = container.mainContext
            
            // Safely unwrap all date calculations
            guard let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()),
                  let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                  let twentyOneDaysAgo = Calendar.current.date(byAdding: .day, value: -21, to: Date()),
                  let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                  let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()),
                  let twoDaysFuture = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
                  let fiveDaysFuture = Calendar.current.date(byAdding: .day, value: 5, to: Date())
            else {
                fatalError("Date calculation failed in SampleData.createPreviewContainer()")
            }
            
            // Create sample friends with safely unwrapped dates
            let friends = [
                Friend(
                    name: "Aleah Goldstein",
                    lastSeen: twoMonthsAgo, // Previously force unwrapped
                    location: "Remote",
                    phoneNumber: "+1234567890"
                ),
                Friend(
                    name: "Julian Gamboa",
                    lastSeen: twoDaysAgo, // Previously force unwrapped
                    location: "Local",
                    phoneNumber: "+1234567891"
                ),
                Friend(
                    name: "Maddie Powell",
                    lastSeen: twentyOneDaysAgo, // Previously force unwrapped
                    location: "Local",
                    phoneNumber: "+1234567892"
                ),
                Friend(
                    name: "Maddi Rose",
                    lastSeen: fiveDaysAgo, // Previously force unwrapped
                    location: "Local",
                    phoneNumber: "+1234567893"
                ),
                Friend(
                    name: "Emma Thompson",
                    lastSeen: oneMonthAgo, // Previously force unwrapped
                    location: "Remote",
                    phoneNumber: "+1234567894"
                ),
                Friend(
                    name: "James Wilson",
                    lastSeen: Date(),
                    location: "Local",
                    phoneNumber: "+1234567895"
                )
            ]
            
            // Add some scheduled hangouts with safely unwrapped dates
            let jamesHangout = Hangout(
                date: twoDaysFuture, // Previously force unwrapped
                activity: "Coffee",
                location: "Blue Bottle",
                isScheduled: true,
                friend: friends[5]
            )
            friends[5].hangouts.append(jamesHangout)
            
            let maddieHangout = Hangout(
                date: fiveDaysFuture, // Previously force unwrapped
                activity: "Lunch",
                location: "Italian Place",
                isScheduled: true,
                friend: friends[2]
            )
            friends[2].hangouts.append(maddieHangout)
            
            friends.forEach { modelContext.insert($0) }
            return container
            
        } catch {
            fatalError("Could not create preview container: \(error.localizedDescription)")
        }
    }
} 
