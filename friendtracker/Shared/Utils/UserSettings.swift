import Foundation

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let phoneNumber = "UserPhoneNumber"
        static let email = "UserEmail"
        static let name = "UserName"
    }
    
    @Published private(set) var phoneNumber: String?
    @Published private(set) var email: String?
    @Published private(set) var name: String?
    
    var hasPhoneNumber: Bool {
        guard let phone = phoneNumber else { return false }
        return !phone.isEmpty
    }
    
    private init() {
        // Load initial values from UserDefaults
        self.phoneNumber = defaults.string(forKey: Keys.phoneNumber)
        self.email = defaults.string(forKey: Keys.email)
        self.name = defaults.string(forKey: Keys.name)
    }
    
    func updatePhoneNumber(_ newValue: String?) {
        phoneNumber = newValue?.standardizedPhoneNumber()
        defaults.set(phoneNumber, forKey: Keys.phoneNumber)
    }
    
    func updateEmail(_ newValue: String?) {
        email = newValue
        defaults.set(email, forKey: Keys.email)
    }
    
    func updateName(_ newValue: String?) {
        name = newValue
        defaults.set(name, forKey: Keys.name)
    }
    
    func clearAll() {
        phoneNumber = nil
        email = nil
        name = nil
        defaults.removeObject(forKey: Keys.phoneNumber)
        defaults.removeObject(forKey: Keys.email)
        defaults.removeObject(forKey: Keys.name)
    }
} 