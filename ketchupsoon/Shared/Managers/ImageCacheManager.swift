import Foundation
import UIKit
import OSLog
import CryptoKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    private let logger = OSLog(subsystem: "com.ketchupsoon", category: "ImageCacheManager")
    
    // In-memory cache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // File manager for disk operations
    private let fileManager = FileManager.default
    
    // Cache directory URL
    private var cacheDirectoryURL: URL? {
        return try? fileManager.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("ImageCache", isDirectory: true)
    }
    
    private init() {
        // Set limits for memory cache
        memoryCache.countLimit = 100
        
        // Create cache directory if it doesn't exist
        createCacheDirectory()
    }
    
    // MARK: - Public Methods
    
    /// Get an image from the cache. Checks memory first, then disk.
    func getImage(for key: String) -> UIImage? {
        // First check memory cache (fastest)
        if let cachedImage = memoryCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Then check disk cache
        return loadImageFromDisk(with: key)
    }
    
    /// Store an image in both memory and disk cache
    func storeImage(_ image: UIImage, for key: String) {
        // Store in memory
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Store on disk
        saveImageToDisk(image, with: key)
    }
    
    /// Remove an image from both memory and disk cache
    func removeImage(for key: String) {
        // Remove from memory
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk
        removeImageFromDisk(with: key)
    }
    
    /// Clear all cached images from both memory and disk
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        clearDiskCache()
    }
    
    // MARK: - Private Methods
    
    private func createCacheDirectory() {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            return
        }
        
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
            } catch {
                os_log("Failed to create cache directory: %@", log: logger, type: .error, error.localizedDescription)
            }
        }
    }
    
    private func fileURL(for key: String) -> URL? {
        guard let cacheDirectoryURL = cacheDirectoryURL else {
            return nil
        }
        
        // Create a filename from the key using SHA256 hash for consistency and security
        let filename = key.sha256Hash + ".cache"
        return cacheDirectoryURL.appendingPathComponent(filename)
    }
    
    private func saveImageToDisk(_ image: UIImage, with key: String) {
        guard let fileURL = fileURL(for: key),
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        do {
            try data.write(to: fileURL)
        } catch {
            os_log("Failed to write image to disk: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func loadImageFromDisk(with key: String) -> UIImage? {
        guard let fileURL = fileURL(for: key),
              fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let image = UIImage(data: data)
            
            // If loading succeeded, also cache in memory for faster access next time
            if let image = image {
                memoryCache.setObject(image, forKey: key as NSString)
            }
            
            return image
        } catch {
            os_log("Failed to load image from disk: %@", log: logger, type: .error, error.localizedDescription)
            return nil
        }
    }
    
    private func removeImageFromDisk(with key: String) {
        guard let fileURL = fileURL(for: key),
              fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            os_log("Failed to remove image from disk: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func clearDiskCache() {
        guard let cacheDirectoryURL = cacheDirectoryURL,
              fileManager.fileExists(atPath: cacheDirectoryURL.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: cacheDirectoryURL)
            createCacheDirectory() // Recreate the directory after clearing
        } catch {
            os_log("Failed to clear disk cache: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
}

// MARK: - String Extension

extension String {
    // SHA256 hash implementation using CryptoKit (available in iOS 13+)
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
} 