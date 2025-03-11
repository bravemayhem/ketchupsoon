import SwiftUI

struct StyledDatePicker: View {
    @Binding var selectedDate: Date
    @Binding var isShowingPicker: Bool
    var onSave: () -> Void
    
    // Animation state
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom header
                VStack(spacing: 8) {
                    Text("Birthday")
                        .font(.custom("SpaceGrotesk-Bold", size: 20))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor(red: 21/255, green: 17/255, blue: 50/255, alpha: 0.95)),
                            Color(UIColor(red: 25/255, green: 21/255, blue: 58/255, alpha: 0.95))
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Month/Year selector
                MonthYearSelector(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(AppColors.cardBackground)
                
                // Custom calendar grid
                CalendarGrid(selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(AppColors.cardBackground)
                
                // Action buttons
                HStack {
                    Button(action: {
                        isShowingPicker = false
                    }) {
                        Text("Cancel")
                            .font(.custom("SpaceGrotesk-Medium", size: 16))
                            .foregroundColor(AppColors.accent)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: {
                        onSave()
                        isShowingPicker = false
                    }) {
                        Text("Done")
                            .font(.custom("SpaceGrotesk-Medium", size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppColors.gradient1Start,
                                        AppColors.gradient1End
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(16)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
            .frame(maxHeight: 550)
        }
        .transition(.opacity)
    }
}

// Month and Year selector with custom styling
struct MonthYearSelector: View {
    @Binding var selectedDate: Date
    @State private var showYearPicker = false
    
    // State for wheel picker components
    @State private var selectedMonthIndex: Int = 0
    @State private var selectedDay: Int = 1
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    // Month names for the picker
    private let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    
    // Range of years to show in picker (current year - 80 to current year + 10)
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 80)...(currentYear + 10))
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            // Month year selector row
            HStack {
                // Make the month-year text tappable to show year picker
                Button(action: {
                    initializeDateComponents()
                    showYearPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text(selectedDate.monthYearString())
                            .font(.custom("SpaceGrotesk-Bold", size: 18))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent.opacity(0.8))
                    }
                    .padding(.vertical, 4)
                }
                
                Spacer()
                
                // Month navigation buttons (keep these for quick month changes)
                HStack(spacing: 12) {
                    MonthNavigationButton(direction: .left, action: { moveMonth(by: -1) })
                    MonthNavigationButton(direction: .right, action: { moveMonth(by: 1) })
                }
            }
            
            // Year picker (shown conditionally)
            if showYearPicker {
                wheelPickerView
            }
        }
    }
    
    // Wheel-style picker view - improved for better visibility
    private var wheelPickerView: some View {
        VStack(spacing: 12) {
            Text("Select Date")
                .font(.custom("SpaceGrotesk-Bold", size: 16))
                .foregroundColor(.white)
                .padding(.top, 12)
            
            HStack {
                // Month picker - improved visibility
                Picker("Month", selection: $selectedMonthIndex) {
                    ForEach(0..<months.count, id: \.self) { index in
                        Text(months[index])
                            .font(.custom("SpaceGrotesk-Medium", size: 16))
                            .foregroundColor(.white)
                            .tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 150) // Added fixed height for visibility
                .background(Color.black.opacity(0.3)) // Added background for contrast
                .cornerRadius(8)
                .onChange(of: selectedMonthIndex) {
                    adjustDayIfNeeded()
                }
                
                // Day picker - improved visibility
                Picker("Day", selection: $selectedDay) {
                    ForEach(1...daysInMonth(month: selectedMonthIndex + 1, year: selectedYear), id: \.self) { day in
                        Text("\(day)")
                            .font(.custom("SpaceGrotesk-Medium", size: 16))
                            .foregroundColor(.white)
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60, height: 150) // Added fixed height for visibility
                .background(Color.black.opacity(0.3)) // Added background for contrast
                .cornerRadius(8)
                
                // Year picker - improved visibility
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        // Use string constructor to avoid locale-based comma formatting
                        Text(String(year))
                            .font(.custom("SpaceGrotesk-Medium", size: 16))
                            .foregroundColor(.white)
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 150) // Added fixed height for visibility
                .background(Color.black.opacity(0.3)) // Added background for contrast
                .cornerRadius(8)
                .onChange(of: selectedYear) {
                    adjustDayIfNeeded()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    showYearPicker = false
                }) {
                    Text("Cancel")
                        .font(.custom("SpaceGrotesk-Medium", size: 14))
                        .foregroundColor(AppColors.accent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                }
                
                Button(action: {
                    updateSelectedDate()
                    showYearPicker = false
                }) {
                    Text("Done")
                        .font(.custom("SpaceGrotesk-Medium", size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(AppColors.accentGradient)
                        .cornerRadius(16)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color(UIColor(red: 15/255, green: 12/255, blue: 40/255, alpha: 1)))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.top, 8)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: showYearPicker)
    }
    
    // Initialize the component values from the current selectedDate
    private func initializeDateComponents() {
        let calendar = Calendar.current
        selectedMonthIndex = calendar.component(.month, from: selectedDate) - 1
        selectedDay = calendar.component(.day, from: selectedDate)
        selectedYear = calendar.component(.year, from: selectedDate)
    }
    
    // Calculate days in the selected month
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month)
        let date = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    // Adjust the selected day if the month/year changes to a month with fewer days
    private func adjustDayIfNeeded() {
        let maxDays = daysInMonth(month: selectedMonthIndex + 1, year: selectedYear)
        if selectedDay > maxDays {
            selectedDay = maxDays
        }
    }
    
    // Update the selectedDate based on the picker values
    private func updateSelectedDate() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonthIndex + 1
        components.day = selectedDay
        
        if let date = calendar.date(from: components) {
            selectedDate = date
        }
    }
    
    // Helper function to move month forward or backward
    private func moveMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// Extract year button to its own view
struct YearButton: View {
    let year: Int
    let selectedYear: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(year)")
                .font(.custom("SpaceGrotesk-Medium", size: 16))
                .foregroundColor(yearTextColor)
                .frame(width: 60, height: 36)
                .background(yearBackground)
        }
    }
    
    // Extracted properties to simplify view
    private var yearTextColor: Color {
        year == selectedYear ? .white : .white.opacity(0.7)
    }
    
    @ViewBuilder
    private var yearBackground: some View {
        if year == selectedYear {
            AppColors.accentGradient.cornerRadius(10)
        } else {
            Color.white.opacity(0.05).cornerRadius(10)
        }
    }
}

// Navigation direction enum
enum NavigationDirection {
    case up, down, left, right
    
    var systemImageName: String {
        switch self {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }
    
    var size: CGFloat {
        switch self {
        case .up, .down: return 12
        case .left, .right: return 16
        }
    }
    
    var buttonSize: CGSize {
        switch self {
        case .up, .down: return CGSize(width: 24, height: 24)
        case .left, .right: return CGSize(width: 30, height: 30)
        }
    }
}

// Extract year navigation button
struct YearNavigationButton: View {
    let direction: NavigationDirection
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction.systemImageName)
                .font(.system(size: direction.size, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: direction.buttonSize.width, height: direction.buttonSize.height)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

// Extract month navigation button
struct MonthNavigationButton: View {
    let direction: NavigationDirection
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: direction.systemImageName)
                .font(.system(size: direction.size, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .frame(width: direction.buttonSize.width, height: direction.buttonSize.height)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

// Calendar day struct to ensure unique IDs
struct CalendarDay: Identifiable, Hashable {
    let date: Date
    let id = UUID()
    let isPlaceholder: Bool
    
    static func placeholder(at index: Int) -> CalendarDay {
        // Create unique placeholder with index to avoid duplicates
        return CalendarDay(date: Date.distantPast.addingTimeInterval(Double(index)), isPlaceholder: true)
    }
}

// Custom calendar grid
struct CalendarGrid: View {
    @Binding var selectedDate: Date
    
    // Calendar object to use for date calculations
    private let calendar = Calendar.current
    
    // Days of the week
    private let daysOfWeek = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Day of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.custom("SpaceGrotesk-Medium", size: 12))
                        .foregroundColor(Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid - now using CalendarDay with unique IDs
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth()) { calendarDay in
                    let isSelected = !calendarDay.isPlaceholder && calendar.isDate(calendarDay.date, inSameDayAs: selectedDate)
                    CalendarDayView(calendarDay: calendarDay, isSelected: isSelected) {
                        if !calendarDay.isPlaceholder {
                            selectedDate = calendarDay.date
                        }
                    }
                }
            }
        }
    }
    
    // Generate all days visible in current month view - now returns CalendarDay objects with unique IDs
    private func daysInMonth() -> [CalendarDay] {
        var days = [CalendarDay]()
        
        let monthRange = calendar.range(of: .day, in: .month, for: selectedDate)!
        let firstDayOfMonth = firstDay(of: selectedDate)
        
        // Get the weekday of the first day (0 is Sunday, 6 is Saturday in our array)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Add empty days for the days of the previous month that appear in the first week
        if firstWeekday > 0 {
            for i in 0..<firstWeekday {
                days.append(CalendarDay.placeholder(at: i))
            }
        }
        
        // Add all days of current month
        for day in 1...monthRange.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(CalendarDay(date: date, isPlaceholder: false))
            }
        }
        
        // Add days to complete the last week if needed
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            for i in 0..<remainingDays {
                days.append(CalendarDay.placeholder(at: firstWeekday + i + 100)) // Use different offset to avoid any potential overlap
            }
        }
        
        return days
    }
    
    // Get the first day of month for a given date
    private func firstDay(of date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }
}

// Individual day cell in calendar - updated to use CalendarDay
struct CalendarDayView: View {
    let calendarDay: CalendarDay
    let isSelected: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            dayContent
        }
        .disabled(calendarDay.isPlaceholder)
    }
    
    // Extracted day content to simplify the view
    private var dayContent: some View {
        Group {
            if isSelected && !calendarDay.isPlaceholder {
                selectedDayView
            } else {
                normalDayView
            }
        }
    }
    
    // Extracted selected day view
    private var selectedDayView: some View {
        Text(dayNumber)
            .font(.custom("SpaceGrotesk-Medium", size: 16))
            .foregroundColor(.white)
            .frame(width: 35, height: 35)
            .background(
                AppColors.accentGradient
                    .clipShape(Circle())
            )
    }
    
    // Extracted normal day view
    private var normalDayView: some View {
        Text(dayNumber)
            .font(.custom("SpaceGrotesk-Medium", size: 16))
            .foregroundColor(textColor)
            .frame(width: 35, height: 35)
    }
    
    // Get day number as string or empty for placeholders
    private var dayNumber: String {
        if calendarDay.isPlaceholder {
            return ""
        }
        return "\(calendar.component(.day, from: calendarDay.date))"
    }
    
    // Text color based on selection state
    private var textColor: Color {
        if calendarDay.isPlaceholder {
            return Color.clear
        }
        return isSelected ? Color.white : Color.white.opacity(0.9)
    }
}

// Date formatting extension
extension Date {
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

#Preview {
    ZStack {
        Color(UIColor(red: 13/255, green: 10/255, blue: 34/255, alpha: 1))
            .edgesIgnoringSafeArea(.all)
        
        StyledDatePicker(
            selectedDate: .constant(Date()),
            isShowingPicker: .constant(true),
            onSave: {}
        )
    }
} 

