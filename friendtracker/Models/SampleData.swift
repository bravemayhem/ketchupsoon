import Foundation

struct SampleData {
    static let friends: [Friend] = [
        Friend(
            id: UUID(),
            name: "James Wilson",
            frequency: "Quarterly catch-up",
            lastHangoutWeeks: 6,
            phoneNumber: "+1234567890",
            isInnerCircle: true,
            isLocal: false
        ),
        Friend(
            id: UUID(),
            name: "Julian Gamboa",
            frequency: "Weekly check-in",
            lastHangoutWeeks: 4,
            phoneNumber: "+1234567891",
            isInnerCircle: true,
            isLocal: true
        ),
        Friend(
            id: UUID(),
            name: "Maddie Powell",
            frequency: "Monthly catch-up",
            lastHangoutWeeks: 2,
            phoneNumber: "+1234567892",
            isInnerCircle: false,
            isLocal: true
        ),
        Friend(
            id: UUID(),
            name: "Maddi Rose",
            frequency: "Weekly check-in",
            lastHangoutWeeks: 1,
            phoneNumber: "+1234567893",
            isInnerCircle: false,
            isLocal: true
        ),
        Friend(
            id: UUID(),
            name: "Emma Stammen",
            frequency: "Monthly catch-up",
            lastHangoutWeeks: 5,
            phoneNumber: "+1234567894",
            isInnerCircle: true,
            isLocal: false
        ),
        Friend(
            id: UUID(),
            name: "Vic Farina",
            frequency: "Monthly catch-up",
            lastHangoutWeeks: 5,
            phoneNumber: "+1234567894",
            isInnerCircle: true,
            isLocal: false
        )
    ]
    
    static let activities: [ActivitySuggestion] = [
        ActivitySuggestion(
            title: "Coffee catch-up",
            category: .general,
            duration: 3600, // 1 hour
            weatherDependent: false
        ),
        ActivitySuggestion(
            title: "Hiking nearby trail",
            category: .outdoor,
            duration: 7200, // 2 hours
            weatherDependent: true
        ),
        ActivitySuggestion(
            title: "Try new ramen place",
            category: .dinner,
            duration: 5400, // 1.5 hours
            weatherDependent: false
        ),
        ActivitySuggestion(
            title: "Beach day",
            category: .outdoor,
            duration: 14400, // 4 hours
            weatherDependent: true
        ),
        ActivitySuggestion(
            title: "Board game night",
            category: .general,
            duration: 10800, // 3 hours
            weatherDependent: false
        )
    ]
} 