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
            
            // Add sample friends with varying last seen dates
            let friends = [
                Friend(
                    name: "Aleah Goldstein",
                    lastSeen: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
                    location: "Remote",
                    phoneNumber: "+1234567890"
                ),
                Friend(
                    name: "Julian Gamboa",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    location: "Local",
                    phoneNumber: "+1234567891"
                ),
                Friend(
                    name: "Maddie Powell",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                    location: "Local",
                    phoneNumber: "+1234567892"
                ),
                Friend(
                    name: "Maddi Rose",
                    lastSeen: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                    location: "Local",
                    phoneNumber: "+1234567893"
                ),
                Friend(
                    name: "Emma Thompson",
                    lastSeen: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
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
            
            // Add some scheduled hangouts
            let jamesHangout = Hangout(
                date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                activity: "Coffee",
                location: "Blue Bottle",
                isScheduled: true,
                friend: friends[5]
            )
            friends[5].hangouts.append(jamesHangout)
            
            let maddieHangout = Hangout(
                date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
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