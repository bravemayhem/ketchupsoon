import Foundation

@objc(EmailArrayValueTransformer)
final class EmailArrayValueTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return data
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return data
    }
}

extension NSValueTransformerName {
    static let emailArrayTransformer = NSValueTransformerName(rawValue: "EmailArrayValueTransformer")
}

extension EmailArrayValueTransformer {
    static func register() {
        ValueTransformer.setValueTransformer(
            EmailArrayValueTransformer(),
            forName: .emailArrayTransformer
        )
    }
} 