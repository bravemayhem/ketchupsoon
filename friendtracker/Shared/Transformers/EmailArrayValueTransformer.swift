import Foundation

/// A value transformer for storing multiple email addresses for manually added friends.
/// This transformer is only used for friends that are not linked to system contacts.
/// For contact-linked friends, emails are managed through the Contacts framework.
@objc(EmailArrayValueTransformer)
final class EmailArrayValueTransformer: ValueTransformer {
    
    static let name = NSValueTransformerName("EmailArrayValueTransformer")
    
    /// Required override to specify what class we transform from
    override class func transformedValueClass() -> AnyClass {
        return NSArray.self
    }
    
    /// Required override to indicate that we support reverse transformations
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    /// Registers the transformer.
    public static func register() {
        let transformer = EmailArrayValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let emails = value as? [String] else {
            return try? JSONSerialization.data(withJSONObject: [], options: [])
        }
        
        do {
            return try JSONSerialization.data(withJSONObject: emails, options: [])
        } catch {
            print("❌ Failed to transform email array: \(error)")
            return try? JSONSerialization.data(withJSONObject: [], options: [])
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return [] }
        
        do {
            let array = try JSONSerialization.jsonObject(with: data, options: []) as? [String]
            return array ?? []
        } catch {
            print("❌ Failed to reverse transform email array: \(error)")
            return []
        }
    }
} 