import Foundation
import SwiftData

/// A model for storing app settings
@Model
final class Setting {
    // Unique identifier for the setting
    @Attribute(.unique) var key: String
    
    // Value stored as a string (can be converted as needed)
    var stringValue: String?
    
    // Value stored as an integer
    var intValue: Int?
    
    // Value stored as a boolean
    var boolValue: Bool?
    
    // Value stored as a date
    var dateValue: Date?
    
    // Metadata
    var lastUpdated: Date
    
    init(key: String, 
         stringValue: String? = nil, 
         intValue: Int? = nil, 
         boolValue: Bool? = nil, 
         dateValue: Date? = nil) {
        self.key = key
        self.stringValue = stringValue
        self.intValue = intValue
        self.boolValue = boolValue
        self.dateValue = dateValue
        self.lastUpdated = Date()
    }
} 