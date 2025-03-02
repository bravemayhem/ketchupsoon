import Foundation
import Security

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
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
        // Load initial values from Keychain
        self.phoneNumber = getStringFromKeychain(key: Keys.phoneNumber)
        self.email = getStringFromKeychain(key: Keys.email)
        self.name = getStringFromKeychain(key: Keys.name)
    }
    
    func updatePhoneNumber(_ newValue: String?) {
        phoneNumber = newValue
        if let value = newValue {
            saveStringToKeychain(key: Keys.phoneNumber, value: value)
        } else {
            deleteFromKeychain(key: Keys.phoneNumber)
        }
    }
    
    func updateEmail(_ newValue: String?) {
        email = newValue
        if let value = newValue {
            saveStringToKeychain(key: Keys.email, value: value)
        } else {
            deleteFromKeychain(key: Keys.email)
        }
    }
    
    func updateName(_ newValue: String?) {
        name = newValue
        if let value = newValue {
            saveStringToKeychain(key: Keys.name, value: value)
        } else {
            deleteFromKeychain(key: Keys.name)
        }
    }
    
    func clearAll() {
        phoneNumber = nil
        email = nil
        name = nil
        deleteFromKeychain(key: Keys.phoneNumber)
        deleteFromKeychain(key: Keys.email)
        deleteFromKeychain(key: Keys.name)
    }
    
    // MARK: - Keychain Methods
    
    private func saveStringToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
        }
    }
    
    private func getStringFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let retrievedData = dataTypeRef as? Data {
            return String(data: retrievedData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 