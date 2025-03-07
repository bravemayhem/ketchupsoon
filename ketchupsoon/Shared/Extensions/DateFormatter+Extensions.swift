import Foundation

extension DateFormatter {
    /// Shared formatter for displaying birthdays consistently throughout the app
    static let birthday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"  // More modern format (e.g., "Mar 7, 2025")
        return formatter
    }()
    
    /// Shared formatter for parsing user-input birthdays (more flexible format)
    static let birthdayInput: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
} 