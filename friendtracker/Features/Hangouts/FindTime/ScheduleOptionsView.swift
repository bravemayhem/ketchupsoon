import SwiftUI
import Foundation

enum PollMode {
    case timeSlots
    case availability
}

enum SelectionType {
    case oneOnOne
    case poll
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
    @Published var pollId: String?
    
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
    
    func saveAndCreatePoll() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Create poll in Supabase
            let pollId = try await SupabaseManager.shared.createPoll(
                title: eventName,
                timeRanges: timeRanges,
                selectionType: selectionType
            )
            
            self.pollId = pollId
            
            // Get the web URL for the poll
            let baseUrl = Bundle.main.infoDictionary?["SUPABASE_PROJECT_URL"] as? String ?? "https://friendtracker.app"
            shareURL = URL(string: "\(baseUrl)/schedule/\(pollId)")
            
            if shareURL == nil {
                throw NSError(domain: "ScheduleOptionsView", code: 500, 
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create share URL"])
            }
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
                
                if viewModel.pollId != nil {
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
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Text("Share Poll")
                                    .foregroundColor(AppColors.accent)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                } else {
                    Section {
                        Button(action: {
                            Task {
                                await viewModel.saveAndCreatePoll()
                            }
                        }) {
                            HStack {
                                Text("Save Poll")
                                    .foregroundColor(AppColors.accent)
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                        }
                        .disabled(viewModel.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    }
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
                    PollResponsesView()
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
