import SwiftUI

struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let hour: Int
    let minute: Int
    
    var timeString: String {
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
}

@MainActor
class FindTimeViewModel: ObservableObject {
    @Published var selectedTimeSlots: Set<TimeSlot> = []
    @Published var currentWeekStart: Date = Date()
    @Published var calendarEvents: [Date: [CalendarManager.CalendarEvent]] = [:]
    @Published var isDragging = false
    @Published var dragStartPoint: CGPoint?
    @Published var gridScrollOffset: CGFloat = 0
    
    private var calendarManager: CalendarManager
    
    init() {
        self.calendarManager = CalendarManager.shared
    }
    
    var visibleDays: [Date] {
        (0...2).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }
    
    @MainActor
    func loadEvents() async {
        for date in visibleDays {
            let events = await calendarManager.fetchEventsForDate(date)
            self.calendarEvents[date] = events
        }
    }
    
    func hasEvent(for slot: TimeSlot) -> Bool {
        guard let events = calendarEvents[slot.date] else { return false }
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: slot.date)
        components.month = calendar.component(.month, from: slot.date)
        components.day = calendar.component(.day, from: slot.date)
        components.hour = slot.hour
        components.minute = slot.minute
        
        guard let slotDate = calendar.date(from: components) else { return false }
        
        return events.contains { event in
            guard let eventStartDate = event.event.startDate,
                  let eventEndDate = event.event.endDate else {
                return false
            }
            return slotDate >= eventStartDate && slotDate < eventEndDate
        }
    }
    
    func eventDetailsForSlot(_ slot: TimeSlot) -> [String] {
        guard let events = calendarEvents[slot.date] else { return [] }
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: slot.date)
        components.month = calendar.component(.month, from: slot.date)
        components.day = calendar.component(.day, from: slot.date)
        components.hour = slot.hour
        components.minute = slot.minute
        
        guard let slotDate = calendar.date(from: components) else { return [] }
        
        return events.compactMap { event in
            guard let eventStartDate = event.event.startDate,
                  let eventEndDate = event.event.endDate,
                  slotDate >= eventStartDate && slotDate < eventEndDate else {
                return nil
            }
            return event.event.title ?? "Untitled Event"
        }
    }
    
    func toggleTimeSlot(_ slot: TimeSlot) {
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots.remove(slot)
        } else {
            selectedTimeSlots.insert(slot)
        }
    }
    
    func moveToNextWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: 3, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }
    
    func moveToPreviousWeek() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -3, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }
}

struct FindTimeView: View {
    @StateObject private var viewModel = FindTimeViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint?
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and date range
            titleSection
            
            // Week header (stays fixed)
            weekHeader
                .background(Color(.systemBackground))
            
            // Main grid with time column
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(9...17, id: \.self) { hour in
                        TimeRowWithGrid(hour: hour, viewModel: viewModel)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Bottom buttons
            bottomButtons
        }
        .task {
            await viewModel.loadEvents()
        }
        .onChange(of: viewModel.currentWeekStart) { _, _ in
            Task {
                await viewModel.loadEvents()
            }
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Create Poll Options")
                .font(.title)
                .foregroundColor(.primary)
            
            HStack {
                Button(action: viewModel.moveToPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                Text(weekRangeText)
                    .foregroundColor(.secondary)
                
                Button(action: viewModel.moveToNextWeek) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button("Edit event") {
                    // TODO: Implement edit
                }
                .foregroundColor(AppColors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var weekHeader: some View {
        HStack(spacing: 0) {
            // Spacer for time column
            Rectangle()
                .fill(.clear)
                .frame(width: 60, height: 32)
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(viewModel.visibleDays, id: \.self) { date in
                    VStack(spacing: 0) {
                        Text(dayOfWeek(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(dayOfMonth(date))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var bottomButtons: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Create Poll") {
                showingShareSheet = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedTimeSlots.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startText = formatter.string(from: viewModel.currentWeekStart)
        if let endDate = Calendar.current.date(byAdding: .day, value: 2, to: viewModel.currentWeekStart) {
            let endText = formatter.string(from: endDate)
            return "\(startText) - \(endText)"
        }
        return startText
    }
    
    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct TimeRowWithGrid: View {
    let hour: Int
    @ObservedObject var viewModel: FindTimeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach([0, 30], id: \.self) { minute in
                HStack(spacing: 0) {
                    // Time label
                    TimeLabel(hour: hour, minute: minute)
                        .frame(width: 70)
                    
                    // Grid cells
                    HStack(spacing: 0) {
                        ForEach(viewModel.visibleDays, id: \.self) { date in
                            let slot = TimeSlot(date: date, hour: hour, minute: minute)
                            TimeSlotCell(
                                isSelected: viewModel.selectedTimeSlots.contains(slot),
                                hasEvent: viewModel.hasEvent(for: slot),
                                eventDetails: viewModel.eventDetailsForSlot(slot),
                                onTap: { viewModel.toggleTimeSlot(slot) }
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                handleDrag(gesture: gesture, hour: hour, minute: minute)
                            }
                    )
                }
            }
        }
    }
    
    private func handleDrag(gesture: DragGesture.Value, hour: Int, minute: Int) {
        let location = gesture.location
        // Calculate which cell was dragged based on location.x
        let cellWidth = (UIScreen.main.bounds.width - 60) / 3 // Subtract time column width
        let dayIndex = Int(location.x / cellWidth)
        
        guard dayIndex >= 0 && dayIndex < viewModel.visibleDays.count else { return }
        
        let date = viewModel.visibleDays[dayIndex]
        let slot = TimeSlot(date: date, hour: hour, minute: minute)
        
        // Only toggle if we haven't already selected this slot
        if !viewModel.selectedTimeSlots.contains(slot) {
            viewModel.toggleTimeSlot(slot)
        }
    }
}

struct TimeLabel: View {
    let hour: Int
    let minute: Int
    
    var body: some View {
        Text(timeString)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(height: 32)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 8)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }
}

struct TimeSlotCell: View {
    let isSelected: Bool
    let hasEvent: Bool
    let eventDetails: [String]
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(backgroundColor)
                .frame(height: 32)
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            
            if hasEvent {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(eventDetails, id: \.self) { title in
                        Text(title)
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var backgroundColor: Color {
        if hasEvent {
            return Color.gray.opacity(0.15)
        }
        return isSelected ? AppColors.futureGreen.opacity(0.3) : Color.gray.opacity(0.05)
    }
}

#Preview {
    FindTimeView()
} 
