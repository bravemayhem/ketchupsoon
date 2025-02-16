import SwiftUI

enum PollMode {
    case timeSlots
    case availability
}

struct TimeRange: Identifiable {
    let id = UUID()
    let startSlot: TimeSlot
    let endSlot: TimeSlot
    var isSelected: Bool = false
    
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
        endComponents.minute = endSlot.minute + 30 // Add 30 minutes to include the full range
        
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
        let calendar = Calendar.current
        var slots: [TimeRange] = []
        
        // Create start date
        var startComponents = DateComponents()
        startComponents.year = calendar.component(.year, from: startSlot.date)
        startComponents.month = calendar.component(.month, from: startSlot.date)
        startComponents.day = calendar.component(.day, from: startSlot.date)
        startComponents.hour = startSlot.hour
        startComponents.minute = startSlot.minute
        
        // Create end date
        var endComponents = startComponents
        endComponents.hour = endSlot.hour
        endComponents.minute = endSlot.minute + 30
        
        guard let startDate = calendar.date(from: startComponents),
              let rangeEndDate = calendar.date(from: endComponents) else {
            return []
        }
        
        var currentStartDate = startDate
        while currentStartDate < rangeEndDate {
            guard let slotEndDate = calendar.date(byAdding: .minute, value: Int(duration/60), to: currentStartDate),
                  slotEndDate <= rangeEndDate else {
                break
            }
            
            let startSlot = TimeSlot(
                date: currentStartDate,
                hour: calendar.component(.hour, from: currentStartDate),
                minute: calendar.component(.minute, from: currentStartDate)
            )
            
            let endSlot = TimeSlot(
                date: slotEndDate,
                hour: calendar.component(.hour, from: slotEndDate),
                minute: calendar.component(.minute, from: slotEndDate)
            )
            
            slots.append(TimeRange(startSlot: startSlot, endSlot: endSlot, isSelected: false))
            currentStartDate = slotEndDate
        }
        
        return slots
    }
}

@MainActor
class PollOptionsViewModel: ObservableObject {
    @Published var timeRanges: [TimeRange]
    @Published var showingFindTimeView = false
    @Published var pollMode: PollMode = .availability
    @Published var slotDuration: TimeInterval = 1800 // 30 minutes in seconds
    
    private var originalRanges: [TimeRange] = []
    
    init(selectedTimeSlots: Set<TimeSlot>) {
        self.originalRanges = PollOptionsViewModel.createTimeRanges(from: selectedTimeSlots)
        self.timeRanges = self.originalRanges
    }
    
    private static func createTimeRanges(from timeSlots: Set<TimeSlot>) -> [TimeRange] {
        // Sort time slots by date and time
        let sortedSlots = timeSlots.sorted { slot1, slot2 in
            if slot1.date == slot2.date {
                if slot1.hour == slot2.hour {
                    return slot1.minute < slot2.minute
                }
                return slot1.hour < slot2.hour
            }
            return slot1.date < slot2.date
        }
        
        var ranges: [TimeRange] = []
        var currentRange: (start: TimeSlot, end: TimeSlot)? = nil
        
        for slot in sortedSlots {
            if let current = currentRange {
                // Check if this slot is consecutive with current range
                let calendar = Calendar.current
                let currentEndComponents = DateComponents(
                    year: calendar.component(.year, from: current.end.date),
                    month: calendar.component(.month, from: current.end.date),
                    day: calendar.component(.day, from: current.end.date),
                    hour: current.end.hour,
                    minute: current.end.minute + 30
                )
                let slotComponents = DateComponents(
                    year: calendar.component(.year, from: slot.date),
                    month: calendar.component(.month, from: slot.date),
                    day: calendar.component(.day, from: slot.date),
                    hour: slot.hour,
                    minute: slot.minute
                )
                
                guard let currentEndDate = calendar.date(from: currentEndComponents),
                      let slotDate = calendar.date(from: slotComponents) else {
                    continue
                }
                
                if currentEndDate == slotDate {
                    // Extend current range
                    currentRange?.end = slot
                } else {
                    // End current range and start new one
                    ranges.append(TimeRange(startSlot: current.start, endSlot: current.end))
                    currentRange = (start: slot, end: slot)
                }
            } else {
                // Start new range
                currentRange = (start: slot, end: slot)
            }
        }
        
        // Add last range if exists
        if let lastRange = currentRange {
            ranges.append(TimeRange(startSlot: lastRange.start, endSlot: lastRange.end))
        }
        
        return ranges.sorted { $0.startSlot.date < $1.startSlot.date }
    }
    
    func updateTimeRanges() {
        switch pollMode {
        case .availability:
            timeRanges = originalRanges
        case .timeSlots:
            timeRanges = originalRanges.flatMap { $0.splitIntoTimeSlots(duration: slotDuration) }
        }
    }
    
    func toggleOption(_ range: TimeRange) {
        if let index = timeRanges.firstIndex(where: { $0.id == range.id }) {
            timeRanges[index].isSelected.toggle()
        }
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
                        TimeRangeRow(range: range) {
                            viewModel.toggleOption(range)
                        }
                    }
                } header: {
                    Text("Select your preferred time slots")
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
                    .disabled(viewModel.timeRanges.isEmpty)
                }
            }
            .navigationTitle("Poll Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Edit") {
                        viewModel.showingFindTimeView = true
                    }
                    .foregroundColor(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .sheet(isPresented: $viewModel.showingFindTimeView) {
                FindTimeView()
            }
        }
    }
}

struct TimeRangeRow: View {
    let range: TimeRange
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(range.formattedDate)
                        .font(.headline)
                    Text(range.formattedTimeRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if range.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.accent)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
        }
        .foregroundColor(.primary)
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