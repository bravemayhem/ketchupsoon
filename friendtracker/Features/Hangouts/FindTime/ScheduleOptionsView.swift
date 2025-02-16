import SwiftUI

extension Date {
    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }
}

enum PollMode {
    case timeSlots
    case availability
}

enum SelectionType {
    case oneOnOne
    case poll
}

struct TimeRange: Identifiable, Codable {
    let id: String
    let start: Date
    let end: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: start)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // Add Codable conformance for Supabase JSON format
    enum CodingKeys: String, CodingKey {
        case id
        case start = "start_time"
        case end = "end_time"
    }
    
    init(id: String = UUID().uuidString, start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        let dateFormatter = ISO8601DateFormatter()
        
        let startString = try container.decode(String.self, forKey: .start)
        guard let startDate = dateFormatter.date(from: startString) else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: container, debugDescription: "Invalid date format")
        }
        start = startDate
        
        let endString = try container.decode(String.self, forKey: .end)
        guard let endDate = dateFormatter.date(from: endString) else {
            throw DecodingError.dataCorruptedError(forKey: .end, in: container, debugDescription: "Invalid date format")
        }
        end = endDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(start.ISO8601Format(), forKey: .start)
        try container.encode(end.ISO8601Format(), forKey: .end)
    }
    
    func splitIntoTimeSlots(duration: TimeInterval) -> [TimeRange] {
        print("⏰ Splitting range into slots: \(start.hour):\(start.minute) - \(end.hour):\(end.minute)")
        print("   Duration: \(duration/60) minutes")
        
        let calendar = Calendar.current
        var slots: [TimeRange] = []
        
        // Create start date
        var startComponents = DateComponents()
        startComponents.year = calendar.component(.year, from: start)
        startComponents.month = calendar.component(.month, from: start)
        startComponents.day = calendar.component(.day, from: start)
        startComponents.hour = calendar.component(.hour, from: start)
        startComponents.minute = calendar.component(.minute, from: start)
        
        // Create end date with the full range
        var endComponents = startComponents
        endComponents.hour = calendar.component(.hour, from: end)
        endComponents.minute = calendar.component(.minute, from: end)
        
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
                
                slots.append(TimeRange(start: startSlot.date, end: endSlot.date))
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
    @Published var selectionType: SelectionType = .poll
    @Published var slotDuration: TimeInterval = 1800 // 30 minutes in seconds
    @Published var eventName: String = ""
    @Published var isLoading = false
    @Published var shareURL: URL?
    @Published var error: Error?
    
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
                            ranges.append(TimeRange(start: start.date, end: endSlot.date))
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
                ranges.append(TimeRange(start: start.date, end: endSlot.date))
                print("   Added final range: \(start.hour):\(start.minute) - \(endHour):\(endMinute)")
            }
        }
        
        let sortedRanges = ranges.sorted { $0.start < $1.start }
        print("📦 Created availability ranges:")
        sortedRanges.forEach { range in
            let endHour = Calendar.current.component(.hour, from: range.end)
            let endMinute = Calendar.current.component(.minute, from: range.end)
            print("   Range: \(Calendar.current.component(.hour, from: range.start)):\(Calendar.current.component(.minute, from: range.start)) - \(endHour):\(endMinute)")
        }
        return sortedRanges
    }
    
    private func create30MinuteSlots(from range: TimeRange) -> [TimeRange] {
        print("⏰ Creating 30-minute slots for range: \(range.start.hour):\(range.start.minute) - \(range.end.hour):\(range.end.minute)")
        var slots: [TimeRange] = []
        
        // Calculate total minutes for comparison
        let endMinutes = range.end.hour * 60 + range.end.minute
        
        var currentHour = range.start.hour
        var currentMinute = range.start.minute
        
        while (currentHour * 60 + currentMinute) < endMinutes {
            let startSlot = TimeSlot(date: range.start, hour: currentHour, minute: currentMinute)
            
            // Calculate end time
            var endMinute = currentMinute + 30
            var endHour = currentHour
            if endMinute >= 60 {
                endHour += 1
                endMinute -= 60
            }
            
            let endSlot = TimeSlot(date: range.start, hour: endHour, minute: endMinute)
            slots.append(TimeRange(start: startSlot.date, end: endSlot.date))
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
        print("⏰ Creating 1-hour slots for range: \(range.start.hour):\(range.start.minute) - \(range.end.hour):\(range.end.minute)")
        var slots: [TimeRange] = []
        
        // Calculate the total minutes in the range
        let startMinutes = range.start.hour * 60 + range.start.minute
        let endMinutes = range.end.hour * 60 + range.end.minute
        let totalMinutes = endMinutes - startMinutes
        
        // Create slots if we have at least 60 minutes
        if totalMinutes >= 60 {
            var currentHour = range.start.hour
            var currentMinute = range.start.minute
            
            while (currentHour * 60 + currentMinute + 60) <= endMinutes {
                let startSlot = TimeSlot(date: range.start, 
                                       hour: currentHour, 
                                       minute: currentMinute)
                
                // Calculate end time (1 hour later)
                let endHour = currentHour + 1
                let endMinute = currentMinute
                
                let endSlot = TimeSlot(date: range.start, 
                                     hour: endHour, 
                                     minute: endMinute)
                
                slots.append(TimeRange(start: startSlot.date, end: endSlot.date))
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
                print("   Range: \(range.start.hour):\(range.start.minute) - \(range.end.hour):\(range.end.minute + 30)")
            }
            
        case .timeSlots:
            if slotDuration == 1800 { // 30 minutes
                timeRanges = originalRanges.flatMap(create30MinuteSlots)
            } else { // 1 hour
                timeRanges = originalRanges.flatMap(create1HourSlots)
            }
            
            print("📊 Time slot ranges (duration: \(slotDuration/60) minutes):")
            timeRanges.forEach { range in
                print("   Slot: \(range.start.hour):\(range.start.minute) - \(range.end.hour):\(range.end.minute)")
            }
        }
    }
    
    func createAndSharePoll() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TODO: Implement API call to create poll
            // let response = try await createPoll(
            //     eventName: eventName,
            //     selectionType: selectionType,
            //     displayMode: pollMode,
            //     timeSlots: timeRanges
            // )
            // shareURL = response.shareURL
            
            // For now, simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            shareURL = URL(string: "https://friendtracker.app/schedule/123")
        } catch {
            self.error = error
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

struct ScheduleOptionsView: View {
    @StateObject private var viewModel: PollOptionsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResponses = false
    @State private var showingShareSheet = false
    
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
                    Picker("Selection Type", selection: $viewModel.selectionType) {
                        Text("1:1").tag(SelectionType.oneOnOne)
                        Text("Poll").tag(SelectionType.poll)
                    }
                    .pickerStyle(.segmented)
                    
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
                } header: {
                    Text("Poll Settings")
                        .textCase(nil)
                        .font(.headline)
                        .foregroundColor(.primary)
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
                
                if viewModel.shareURL != nil {
                    Section {
                        Button(action: {
                            showingResponses = true
                        }) {
                            HStack {
                                Text("View Responses")
                                    .foregroundColor(AppColors.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.createAndSharePoll()
                            if viewModel.shareURL != nil {
                                showingShareSheet = true
                            }
                        }
                    }) {
                        HStack {
                            Text(viewModel.shareURL == nil ? "Share" : "Share Again")
                                .foregroundColor(AppColors.accent)
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .disabled(viewModel.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
            }
            .navigationTitle("Schedule Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .sheet(isPresented: $showingResponses) {
                NavigationStack {
                    PollResponsesView(
                        eventName: viewModel.eventName,
                        selectionType: viewModel.selectionType
                    )
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.shareURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let timeSlots: Set<TimeSlot> = [
        TimeSlot(date: Date(), hour: 10, minute: 0),
        TimeSlot(date: Date(), hour: 10, minute: 30),
        TimeSlot(date: Date().addingTimeInterval(86400), hour: 14, minute: 30),
        TimeSlot(date: Date().addingTimeInterval(86400), hour: 15, minute: 0)
    ]
    return ScheduleOptionsView(selectedTimeSlots: timeSlots)
} 
