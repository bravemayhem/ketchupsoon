import Foundation

public struct TimeSlot: Identifiable, Hashable {
    public let id = UUID()
    public let date: Date
    public let hour: Int
    public let minute: Int
    
    public init(date: Date, hour: Int, minute: Int) {
        self.date = date
        self.hour = hour
        self.minute = minute
    }
    
    public var timeString: String {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: date)
        components.month = calendar.component(.month, from: date)
        components.day = calendar.component(.day, from: date)
        components.hour = hour
        components.minute = minute
        
        guard let date = calendar.date(from: components) else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    public static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: lhs.date) == calendar.component(.year, from: rhs.date) &&
               calendar.component(.month, from: lhs.date) == calendar.component(.month, from: rhs.date) &&
               calendar.component(.day, from: lhs.date) == calendar.component(.day, from: rhs.date) &&
               lhs.hour == rhs.hour &&
               lhs.minute == rhs.minute
    }
    
    public func hash(into hasher: inout Hasher) {
        let calendar = Calendar.current
        hasher.combine(calendar.component(.year, from: date))
        hasher.combine(calendar.component(.month, from: date))
        hasher.combine(calendar.component(.day, from: date))
        hasher.combine(hour)
        hasher.combine(minute)
    }
}

public struct TimeRange: Identifiable {
    public let id = UUID()
    public let startSlot: TimeSlot
    public let endSlot: TimeSlot
    
    public init(startSlot: TimeSlot, endSlot: TimeSlot) {
        self.startSlot = startSlot
        self.endSlot = endSlot
    }
    
    public var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: "UTC")  // Use UTC to match stored times
        
        let calendar = Calendar.current
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!  // Use UTC calendar
        
        var startComponents = DateComponents()
        startComponents.timeZone = TimeZone(identifier: "UTC")  // Use UTC
        startComponents.year = utcCalendar.component(.year, from: startSlot.date)
        startComponents.month = utcCalendar.component(.month, from: startSlot.date)
        startComponents.day = utcCalendar.component(.day, from: startSlot.date)
        startComponents.hour = startSlot.hour
        startComponents.minute = startSlot.minute
        
        var endComponents = startComponents
        endComponents.hour = endSlot.hour
        endComponents.minute = endSlot.minute
        
        guard let startDate = utcCalendar.date(from: startComponents),
              let endDate = utcCalendar.date(from: endComponents) else {
            return ""
        }
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        formatter.timeZone = TimeZone(identifier: "UTC")  // Use UTC
        return formatter.string(from: startSlot.date)
    }
    
    public func splitIntoTimeSlots(duration: TimeInterval) -> [TimeRange] {
        print("⏰ Splitting range into slots: \(startSlot.hour):\(startSlot.minute) - \(endSlot.hour):\(endSlot.minute)")
        print("   Duration: \(duration/60) minutes")
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!  // Use UTC calendar
        var slots: [TimeRange] = []
        
        // Create start date
        var startComponents = DateComponents()
        startComponents.timeZone = TimeZone(identifier: "UTC")  // Use UTC
        startComponents.year = calendar.component(.year, from: startSlot.date)
        startComponents.month = calendar.component(.month, from: startSlot.date)
        startComponents.day = calendar.component(.day, from: startSlot.date)
        startComponents.hour = startSlot.hour
        startComponents.minute = startSlot.minute
        
        // Create end date with the full range
        var endComponents = DateComponents()
        endComponents.timeZone = TimeZone(identifier: "UTC")  // Use UTC
        endComponents.year = calendar.component(.year, from: endSlot.date)
        endComponents.month = calendar.component(.month, from: endSlot.date)
        endComponents.day = calendar.component(.day, from: endSlot.date)
        endComponents.hour = endSlot.hour
        endComponents.minute = endSlot.minute + 30 // Add 30 minutes to include the full end slot
        
        // Normalize end time if minutes >= 60
        if endComponents.minute ?? 0 >= 60 {
            endComponents.hour = (endComponents.hour ?? 0) + 1
            endComponents.minute = (endComponents.minute ?? 0) - 60
        }
        
        guard let startDate = calendar.date(from: startComponents),
              let rangeEndDate = calendar.date(from: endComponents) else {
            print("❌ Failed to create dates")
            return []
        }
        
        var currentStartDate = startDate
        
        while currentStartDate < rangeEndDate {
            guard let slotEndDate = calendar.date(byAdding: .minute, value: Int(duration/60), to: currentStartDate) else {
                print("❌ Failed to create slot end date")
                break
            }
            
            // For the last slot, make sure we don't exceed the range end
            let actualEndDate = min(slotEndDate, rangeEndDate)
            
            // Only add the slot if it's a full slot
            if actualEndDate.timeIntervalSince(currentStartDate) >= duration {
                let startSlot = TimeSlot(
                    date: currentStartDate,
                    hour: calendar.component(.hour, from: currentStartDate),
                    minute: calendar.component(.minute, from: currentStartDate)
                )
                
                let endComponents = calendar.dateComponents([.hour, .minute], from: actualEndDate)
                let endSlot = TimeSlot(
                    date: startSlot.date,
                    hour: endComponents.hour ?? 0,
                    minute: endComponents.minute ?? 0
                )
                
                slots.append(TimeRange(startSlot: startSlot, endSlot: endSlot))
                print("   Created slot: \(startSlot.hour):\(startSlot.minute) - \(endSlot.hour):\(endSlot.minute)")
            }
            
            // For 1-hour slots, slide by 30 minutes. For 30-minute slots, slide by the full duration
            let slideAmount = duration == 3600 ? 1800.0 : duration
            guard let nextStartDate = calendar.date(byAdding: .minute, value: Int(slideAmount/60), to: currentStartDate) else {
                print("❌ Failed to create next start date")
                break
            }
            currentStartDate = nextStartDate
        }
        
        print("📦 Created \(slots.count) slots")
        return slots
    }
} 
