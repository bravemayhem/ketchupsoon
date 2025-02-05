import Foundation

actor CacheManager {
    static let shared = CacheManager()
    
    private var cache: NSCache<NSString, AnyObject>
    private var expirationTimes: [String: Date]
    
    private init() {
        self.cache = NSCache<NSString, AnyObject>()
        self.expirationTimes = [:]
        
        // Set default cache limits
        cache.countLimit = 100 // Maximum number of items
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func set<T: AnyObject>(_ object: T, forKey key: String, expirationMinutes: Int = 30) {
        let expirationDate = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        expirationTimes[key] = expirationDate
        cache.setObject(object, forKey: key as NSString)
    }
    
    func get<T: AnyObject>(forKey key: String) -> T? {
        guard let expirationDate = expirationTimes[key],
              Date() < expirationDate else {
            // Cache expired or doesn't exist
            removeObject(forKey: key)
            return nil
        }
        
        return cache.object(forKey: key as NSString) as? T
    }
    
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        expirationTimes.removeValue(forKey: key)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        expirationTimes.removeAll()
    }
    
    // Helper method to generate cache keys
    static func makeKey(type: String, id: String) -> String {
        return "\(type)_\(id)"
    }
}

// MARK: - Cache Keys
extension CacheManager {
    enum CacheKey {
        static let friendsList = "friends_list"
        static let hangoutsList = "hangouts_list"
        static func friend(_ id: UUID) -> String {
            return makeKey(type: "friend", id: id.uuidString)
        }
        static func hangout(_ id: UUID) -> String {
            return makeKey(type: "hangout", id: id.uuidString)
        }
    }
} 