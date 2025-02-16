import SwiftUI

enum PollMode {
    case timeSlots
    case availability
}

struct TimeRange: Identifiable {
    let id = UUID()
    let startSlot: TimeSlot
    let endSlot: TimeSlot
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = calendar.component(.year, from: startSlot.date)
        startComponents.month = calendar.component(.month, from: startSlot.date)
        startComponents.day = calendar.component(.day, from: startSlot.date)
        startComponents.hour = startSlot.hour
        startComponents.minute = startSlot.minute
        
        var endComponents = startComponents
        endComponents.hour = endSlot.hour
        endComponents.minute = endSlot.minute
        
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(from: endComponents) else {
            return ""
        }
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"  // This will show "Tuesday, February 18"
        return formatter.string(from: startSlot.date)
    }
    
    func splitIntoTimeSlots(duration: TimeInterval) -> [TimeRange] {
        print("⏰ Splitting range into slots: \(startSlot.hour):\(startSlot.minute) - \(endSlot.hour):\(endSlot.minute)")
        print("   Duration: \(duration/60) minutes")
        
        let calendar = Calendar.current
        var slots: [TimeRange] = []
        
        // Create start date
        var startComponents = DateComponents()
        startComponents.year = calendar.component(.year, from: startSlot.date)
        startComponents.month = calendar.component(.month, from: startSlot.date)
        startComponents.day = calendar.component(.day, from: startSlot.date)
        startComponents.hour = startSlot.hour
        startComponents.minute = startSlot.minute
        
        // Create end date with the full range
        var endComponents = DateComponents()
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

@MainActor
class PollOptionsViewModel: ObservableObject {
    @Published var timeRanges: [TimeRange]
    @Published var pollMode: PollMode = .availability
    @Published var slotDuration: TimeInterval = 1800 // 30 minutes in seconds
    @Published var eventName: String = ""
    
    private var originalRanges: [TimeRange] = []
    private var selectedTimeSlots: Set<TimeSlot>
    
    init(selectedTimeSlots: Set<TimeSlot>) {
        self.selectedTimeSlots = selectedTimeSlots
        self.originalRanges = PollOptionsViewModel.createAvailabilityRanges(from: selectedTimeSlots)
        self.timeRanges = self.originalRanges
    }
    
    private static func createAvailabilityRanges(from timeSlots: Set<TimeSlot>) -> [TimeRange] {
        print("🔍 Creating availability ranges from selected slots:")
        timeSlots.forEach { slot in
            print("   Selected slot: date: \(slot.date), hour: \(slot.hour), minute: \(slot.minute)")
        }
        
        // Group slots by date
        let slotsByDate = Dictionary(grouping: timeSlots) { slot in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: slot.date)
            return calendar.date(from: components) ?? slot.date
        }
        
        var ranges: [TimeRange] = []
        
        for (_, slots) in slotsByDate {
            // Sort slots by time for this date
            let sortedSlots = slots.sorted { slot1, slot2 in
                if slot1.hour == slot2.hour {
                    return slot1.minute < slot2.minute
                }
                return slot1.hour < slot2.hour
            }
            
            var currentRange: TimeSlot? = nil
            var lastSlot: TimeSlot? = nil
            
            for slot in sortedSlots {
                if let last = lastSlot {
                    // Check if this slot is 30 minutes after the last one
                    let isConsecutive = (slot.hour == last.hour && slot.minute == last.minute + 30) ||
                                      (slot.hour == last.hour + 1 && last.minute == 30 && slot.minute == 0)
                    
                    if isConsecutive {
                        lastSlot = slot
                    } else {
                        // End the current range
                        if let start = currentRange {
                            // Calculate proper end time (last slot + 30 minutes)
                            var endHour = last.hour
                            var endMinute = last.minute + 30
                            if endMinute >= 60 {
                                endHour += 1
                                endMinute -= 60
                            }
                            let endSlot = TimeSlot(date: last.date, hour: endHour, minute: endMinute)
                            ranges.append(TimeRange(startSlot: start, endSlot: endSlot))
                            print("   Added range: \(start.hour):\(start.minute) - \(endHour):\(endMinute)")
                        }
                        currentRange = slot
                        lastSlot = slot
                    }
                } else {
                    currentRange = slot
                    lastSlot = slot
                }
            }
            
            // Add the last range if exists
            if let start = currentRange, let last = lastSlot {
                // Calculate proper end time (last slot + 30 minutes)
                var endHour = last.hour
                var endMinute = last.minute + 30
                if endMinute >= 60 {
                    endHour += 1
                    endMinute -= 60
                }
                let endSlot = TimeSlot(date: last.date, hour: endHour, minute: endMinute)
                ranges.append(TimeRange(startSlot: start, endSlot: endSlot))
                print("   Added final range: \(start.hour):\(start.minute) - \(endHour):\(endMinute)")
            }
        }
        
        let sortedRanges = ranges.sorted { $0.startSlot.date < $1.startSlot.date }
        print("📦 Created availability ranges:")
        sortedRanges.forEach { range in
            let endHour = range.endSlot.hour
            let endMinute = range.endSlot.minute
            print("   Range: \(range.startSlot.hour):\(range.startSlot.minute) - \(endHour):\(endMinute)")
        }
        return sortedRanges
    }
    
    private func create30MinuteSlots(from range: TimeRange) -> [TimeRange] {
        print("⏰ Creating 30-minute slots for range: \(range.startSlot.hour):\(range.startSlot.minute) - \(range.endSlot.hour):\(range.endSlot.minute)")
        var slots: [TimeRange] = []
        
        // Calculate total minutes for comparison
        let endMinutes = range.endSlot.hour * 60 + range.endSlot.minute
        
        var currentHour = range.startSlot.hour
        var currentMinute = range.startSlot.minute
        
        while (currentHour * 60 + currentMinute) < endMinutes {
            let startSlot = TimeSlot(date: range.startSlot.date, hour: currentHour, minute: currentMinute)
            
            // Calculate end time
            var endMinute = currentMinute + 30
            var endHour = currentHour
            if endMinute >= 60 {
                endHour += 1
                endMinute -= 60
            }
            
            let endSlot = TimeSlot(date: range.startSlot.date, hour: endHour, minute: endMinute)
            slots.append(TimeRange(startSlot: startSlot, endSlot: endSlot))
            print("   Created 30-min slot: \(currentHour):\(currentMinute) - \(endHour):\(endMinute)")
            
            // Move to next slot
            currentMinute += 30
            if currentMinute >= 60 {
                currentHour += 1
                currentMinute -= 60
            }
        }
        
        return slots
    }
    
    private func create1HourSlots(from range: TimeRange) -> [TimeRange] {
        print("⏰ Creating 1-hour slots for range: \(range.startSlot.hour):\(range.startSlot.minute) - \(range.endSlot.hour):\(range.endSlot.minute)")
        var slots: [TimeRange] = []
        
        // Calculate the total minutes in the range
        let startMinutes = range.startSlot.hour * 60 + range.startSlot.minute
        let endMinutes = range.endSlot.hour * 60 + range.endSlot.minute
        let totalMinutes = endMinutes - startMinutes
        
        // Create slots if we have at least 60 minutes
        if totalMinutes >= 60 {
            var currentHour = range.startSlot.hour
            var currentMinute = range.startSlot.minute
            
            while (currentHour * 60 + currentMinute + 60) <= endMinutes {
                let startSlot = TimeSlot(date: range.startSlot.date, 
                                       hour: currentHour, 
                                       minute: currentMinute)
                
                // Calculate end time (1 hour later)
                let endHour = currentHour + 1
                let endMinute = currentMinute
                
                let endSlot = TimeSlot(date: range.startSlot.date, 
                                     hour: endHour, 
                                     minute: endMinute)
                
                slots.append(TimeRange(startSlot: startSlot, endSlot: endSlot))
                print("   Created 1-hour slot: \(startSlot.hour):\(startSlot.minute) - \(endHour):\(endMinute)")
                
                // Move to next slot start (30-minute increment)
                currentMinute += 30
                if currentMinute >= 60 {
                    currentHour += 1
                    currentMinute -= 60
                }
            }
        }
        
        return slots
    }
    
    func updateTimeRanges() {
        print("\n🔄 Updating time ranges for mode: \(pollMode)")
        switch pollMode {
        case .availability:
            timeRanges = originalRanges
            print("📊 Availability ranges:")
            timeRanges.forEach { range in
                print("   Range: \(range.startSlot.hour):\(range.startSlot.minute) - \(range.endSlot.hour):\(range.endSlot.minute + 30)")
            }
            
        case .timeSlots:
            if slotDuration == 1800 { // 30 minutes
                timeRanges = originalRanges.flatMap(create30MinuteSlots)
            } else { // 1 hour
                timeRanges = originalRanges.flatMap(create1HourSlots)
            }
            
            print("📊 Time slot ranges (duration: \(slotDuration/60) minutes):")
            timeRanges.forEach { range in
                print("   Slot: \(range.startSlot.hour):\(range.startSlot.minute) - \(range.endSlot.hour):\(range.endSlot.minute)")
            }
        }
    }
}

struct TimeRangeRow: View {
    let range: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(range.formattedDate)
                .font(.headline)
            Text(range.formattedTimeRange)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PollOptionsView: View {
    @StateObject private var viewModel: PollOptionsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(selectedTimeSlots: Set<TimeSlot>) {
        _viewModel = StateObject(wrappedValue: PollOptionsViewModel(selectedTimeSlots: selectedTimeSlots))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Event Name", text: $viewModel.eventName)
                        .textFieldStyle(.plain)
                } header: {
                    Text("Event Details")
                        .textCase(nil)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Section {
                    Picker("Poll Mode", selection: $viewModel.pollMode) {
                        Text("Availability").tag(PollMode.availability)
                        Text("Time Slots").tag(PollMode.timeSlots)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.pollMode) { _, _ in
                        viewModel.updateTimeRanges()
                    }
                    
                    if viewModel.pollMode == .timeSlots {
                        Picker("Slot Duration", selection: $viewModel.slotDuration) {
                            Text("30 min").tag(TimeInterval(1800))
                            Text("1 hour").tag(TimeInterval(3600))
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.slotDuration) { _, _ in
                            viewModel.updateTimeRanges()
                        }
                    }
                }
                
                Section {
                    ForEach(viewModel.timeRanges) { range in
                        TimeRangeRow(range: range)
                    }
                } header: {
                    Text("Your Available Times")
                        .textCase(nil)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                }
                
                Section {
                    Button(action: {
                        // TODO: Implement share functionality
                    }) {
                        HStack {
                            Text("Share Poll")
                                .foregroundColor(AppColors.accent)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    .disabled(viewModel.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Poll Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

#Preview {
    let timeSlots: Set<TimeSlot> = [
        TimeSlot(date: Date(), hour: 10, minute: 0),
        TimeSlot(date: Date(), hour: 10, minute: 30),
        TimeSlot(date: Date().addingTimeInterval(86400), hour: 14, minute: 30),
        TimeSlot(date: Date().addingTimeInterval(86400), hour: 15, minute: 0)
    ]
    return PollOptionsView(selectedTimeSlots: timeSlots)
} 
