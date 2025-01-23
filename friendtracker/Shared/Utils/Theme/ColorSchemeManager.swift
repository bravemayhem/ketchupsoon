import SwiftUI

class ColorSchemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false {
        didSet {
            colorScheme = isDarkMode ? .dark : .light
        }
    }
    @Published var colorScheme: ColorScheme = .light
    
    static let shared = ColorSchemeManager()
    
    private init() {
        colorScheme = isDarkMode ? .dark : .light
    }
} 