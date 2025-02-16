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
    
    static func == (lhs: TimeSlot, rhs: TimeSlot) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: lhs.date) == calendar.component(.year, from: rhs.date) &&
               calendar.component(.month, from: lhs.date) == calendar.component(.month, from: rhs.date) &&
               calendar.component(.day, from: lhs.date) == calendar.component(.day, from: rhs.date) &&
               lhs.hour == rhs.hour &&
               lhs.minute == rhs.minute
    }
    
    func hash(into hasher: inout Hasher) {
        let calendar = Calendar.current
        hasher.combine(calendar.component(.year, from: date))
        hasher.combine(calendar.component(.month, from: date))
        hasher.combine(calendar.component(.day, from: date))
        hasher.combine(hour)
        hasher.combine(minute)
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
        print("FindTimeViewModel: Toggling time slot - hour: \(slot.hour), minute: \(slot.minute)")
        if selectedTimeSlots.contains(slot) {
            print("FindTimeViewModel: Removing slot")
            selectedTimeSlots.remove(slot)
        } else {
            print("FindTimeViewModel: Adding slot")
            selectedTimeSlots.insert(slot)
        }
        print("FindTimeViewModel: Current selected slots count: \(selectedTimeSlots.count)")
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
    @State private var showingPollOptions = false
    @State private var gridDragActive: Bool = false
    @State private var gridDragSelectionMode: Bool? = nil  // true for selecting, false for deselecting
    @State private var gridLastDraggedCell: (row: Int, col: Int)? = nil
    @State private var scrollOffset: CGFloat = 0
    @State private var isDraggingTimeColumn = false
    @State private var lastDragValue: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Title and date range
            titleSection
            
            // Week header (stays fixed)
            weekHeader
                .background(Color(.systemBackground))
            
            // Main grid with time column wrapped in a ZStack to allow overlay
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(9...23, id: \.self) { hour in
                            TimeRowWithGrid(hour: hour, viewModel: viewModel)
                        }
                        // Add midnight (0:00) as the last row
                        TimeRowWithGrid(hour: 0, viewModel: viewModel)
                    }
                    .offset(y: scrollOffset)
                }
                // Event overlay: draws calendar events spanning multiple cells
                GeometryReader { geo in
                    EventOverlay(viewModel: viewModel, geo: geo)
                }
                // Overlay to capture drag across the grid
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { gesture in
                                    let location = gesture.location
                                    let timeColumnWidth: CGFloat = 70
                                    
                                    // Handle time column scrolling
                                    if location.x < timeColumnWidth {
                                        if !isDraggingTimeColumn {
                                            isDraggingTimeColumn = true
                                            lastDragValue = gesture.translation.height
                                        }
                                        
                                        let translation = gesture.translation.height - lastDragValue
                                        lastDragValue = gesture.translation.height
                                        
                                        let newOffset = scrollOffset + translation
                                        
                                        // Calculate bounds
                                        let totalHeight = CGFloat(31) * 32 // 31 half-hour slots (9am to midnight)
                                        let maxScroll = min(0, -(totalHeight - geo.size.height))
                                        
                                        // Clamp the offset between maxScroll and 0
                                        scrollOffset = max(maxScroll, min(0, newOffset))
                                        return
                                    }
                                    
                                    // If we're not in the time column, handle grid selection
                                    if isDraggingTimeColumn {
                                        isDraggingTimeColumn = false
                                        return
                                    }
                                    
                                    // Calculate grid position
                                    let availableWidth = geo.size.width - timeColumnWidth
                                    let colWidth = availableWidth / CGFloat(viewModel.visibleDays.count)
                                    
                                    // Lock to initial column if we're already dragging
                                    let col: Int
                                    if let (_, initialCol) = gridLastDraggedCell {
                                        col = initialCol
                                    } else {
                                        col = min(
                                            viewModel.visibleDays.count - 1,
                                            max(0, Int((location.x - timeColumnWidth) / colWidth))
                                        )
                                    }
                                    
                                    // Compute row: each cell row has fixed height 32
                                    // Adjust y position by scroll offset
                                    let adjustedY = location.y - scrollOffset
                                    let row = min(
                                        30, // Maximum row index (9am to midnight)
                                        max(0, Int(adjustedY / 32))
                                    )
                                    
                                    // Hours are from 9 to 0 (midnight), two rows per hour
                                    let hourValue = if row / 2 + 9 >= 24 {
                                        0 // midnight
                                    } else {
                                        9 + (row / 2)
                                    }
                                    let minuteValue = (row % 2 == 0) ? 0 : 30
                                    
                                    print("Overlay drag: location: \(location), adjusted y: \(adjustedY), col: \(col), row: \(row), hour: \(hourValue), minute: \(minuteValue)")
                                    
                                    // Validate indices
                                    guard col >= 0 && col < viewModel.visibleDays.count else {
                                        print("Overlay drag: invalid cell indices")
                                        return
                                    }
                                    
                                    let date = viewModel.visibleDays[col]
                                    let slot = TimeSlot(date: date, hour: hourValue, minute: minuteValue)
                                    
                                    if !gridDragActive {
                                        gridDragActive = true
                                        gridDragSelectionMode = !viewModel.selectedTimeSlots.contains(slot)
                                        gridLastDraggedCell = (row, col)
                                        
                                        if !viewModel.hasEvent(for: slot) {
                                            let modeText = gridDragSelectionMode == true ? "selecting" : "deselecting"
                                            print("Overlay drag: initial selection - mode: \(modeText)")
                                            if gridDragSelectionMode == true {
                                                viewModel.selectedTimeSlots.insert(slot)
                                            } else {
                                                viewModel.selectedTimeSlots.remove(slot)
                                            }
                                        }
                                    } else if (gridLastDraggedCell ?? (-1, -1)) != (row, col) {
                                        gridLastDraggedCell = (row, col)
                                        if !viewModel.hasEvent(for: slot) {
                                            let modeText = gridDragSelectionMode == true ? "selecting" : "deselecting"
                                            print("Overlay drag: applying selection at cell (row: \(row), col: \(col)) - mode: \(modeText)")
                                            if gridDragSelectionMode == true {
                                                viewModel.selectedTimeSlots.insert(slot)
                                            } else {
                                                viewModel.selectedTimeSlots.remove(slot)
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    print("Overlay drag ended")
                                    gridDragActive = false
                                    gridLastDraggedCell = nil
                                    gridDragSelectionMode = nil
                                    isDraggingTimeColumn = false
                                    
                                    // Add a small animation to settle
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1)) {
                                        let totalHeight = CGFloat(31) * 32
                                        let maxScroll = min(0, -(totalHeight - geo.size.height))
                                        scrollOffset = max(maxScroll, min(0, scrollOffset))
                                    }
                                }
                        )
                }
            }
            
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
        .sheet(isPresented: $showingPollOptions) {
            PollOptionsView(selectedTimeSlots: viewModel.selectedTimeSlots)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Enter Availability")
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
                showingPollOptions = true
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
                                onTap: {
                                    print("TimeRowWithGrid: Cell tapped for hour: \(hour), minute: \(minute)")
                                    viewModel.toggleTimeSlot(slot)
                                }
                            )
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
        }
    }
}

struct TimeLabel: View {
    let hour: Int
    let minute: Int
    
    var body: some View {
        VStack(spacing: 0) {
            if minute == 0 {
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .frame(height: 16, alignment: .bottom)
                    .offset(y: -8)
            } else {
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                    .frame(height: 16, alignment: .bottom)
                    .offset(y: -8)
            }
        }
        .frame(height: 32)
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
        .onTapGesture {
            print("TimeSlotCell: Tapped cell - isSelected: \(isSelected)")
            onTap()
        }
    }
    
    private var backgroundColor: Color {
        if hasEvent {
            return Color.gray.opacity(0.15)
        }
        return isSelected ? AppColors.futureGreen.opacity(0.3) : Color.gray.opacity(0.05)
    }
}

struct EventOverlay: View {
    @ObservedObject var viewModel: FindTimeViewModel
    let geo: GeometryProxy
    
    var body: some View {
        ForEach(Array(viewModel.visibleDays.enumerated()), id: \.offset) { index, day in
            let timeColumnWidth: CGFloat = 70
            let colWidth = (geo.size.width - timeColumnWidth) / CGFloat(viewModel.visibleDays.count)
            let x = timeColumnWidth + CGFloat(index) * colWidth
            
            ForEach(Array((viewModel.calendarEvents[day] ?? []).enumerated()), id: \.offset) { eventIndex, event in
                let calendar = Calendar.current
                if let gridStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day),
                   let gridEnd = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: day) {
                    
                    let eventStart = max(event.event.startDate ?? day, gridStart)
                    let eventEnd = min(event.event.endDate ?? day, gridEnd)
                    
                    let durationMinutes = eventEnd.timeIntervalSince(eventStart) / 60.0
                    let offsetMinutes = eventStart.timeIntervalSince(gridStart) / 60.0
                    
                    let cellHeight: CGFloat = 32
                    
                    // Round to nearest cell boundary
                    let cellsFromTop = Int(offsetMinutes / 30.0)
                    let y = CGFloat(cellsFromTop) * cellHeight
                    
                    // Calculate height to nearest cell boundary
                    let cellsSpanned = Int(ceil(durationMinutes / 30.0))
                    let height = CGFloat(max(1, cellsSpanned)) * cellHeight
                    
                    if height > 0 {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                            
                            Text(event.event.title ?? "Untitled Event")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .lineLimit(1)
                        }
                        .frame(width: colWidth, height: height)
                        .position(x: x + colWidth/2, y: y + height/2)
                    }
                }
            }
        }
    }
}

#Preview {
    FindTimeView()
} 
