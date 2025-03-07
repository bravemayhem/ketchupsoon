import Foundation
import os.signpost
import SwiftUI
import UIKit

func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function): \(message)")
    #endif
}

// Added utility to verify font registration
func verifyFontRegistration() {
    #if DEBUG
    // List all registered font families
    let families = UIFont.familyNames.sorted()
    print("==== REGISTERED FONT FAMILIES ====")
    for family in families {
        print("👉 \(family)")
        
        // List all fonts in this family
        let fonts = UIFont.fontNames(forFamilyName: family).sorted()
        for font in fonts {
            print("  - \(font)")
        }
    }
    
    // Check for SpaceGrotesk specifically
    print("\n==== CHECKING FOR SPACEGROTESK ====")
    var spaceGroteskFound = false
    for family in families {
        if family.contains("Space") || family.contains("Grotesk") {
            print("Found potential family: \(family)")
            let fonts = UIFont.fontNames(forFamilyName: family)
            for font in fonts {
                if font.contains("SpaceGrotesk") || font.contains("Space Grotesk") {
                    print("✅ FOUND SpaceGrotesk font: \(font)")
                    spaceGroteskFound = true
                }
            }
        }
    }
    
    if !spaceGroteskFound {
        print("❌ NO SpaceGrotesk fonts found!")
    }
    
    // Check bundle paths for the font files
    print("\n==== CHECKING FONT FILE PATHS ====")
    if let bundlePath = Bundle.main.resourcePath {
        // Check paths for each SpaceGrotesk variant
        let variants = ["Bold", "Regular", "Medium", "Light", "SemiBold"]
        for variant in variants {
            let fontPath = bundlePath + "/Fonts/Space_Grotesk/static/SpaceGrotesk-\(variant).ttf"
            let exists = FileManager.default.fileExists(atPath: fontPath)
            print("\(exists ? "✅" : "❌") SpaceGrotesk-\(variant).ttf: \(exists ? "EXISTS" : "MISSING")")
        }
    }
    #endif
}

// Performance measurement utilities
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private let signpostID = OSSignpostID(log: .default)
    private lazy var log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.ketchupsoon", category: "Performance")
    
    func startMeasuring(_ name: String) {
        os_signpost(.begin, log: log, name: "measure", "%{public}s start", name)
    }
    
    func stopMeasuring(_ name: String) {
        os_signpost(.end, log: log, name: "measure", "%{public}s end", name)
    }
    
    func measure(_ name: String, block: () -> Void) {
        startMeasuring(name)
        block()
        stopMeasuring(name)
    }
    
    func measureAsync(_ name: String) -> () -> Void {
        startMeasuring(name)
        return { [weak self] in
            self?.stopMeasuring(name)
        }
    }
}

#if DEBUG
extension View {
    func measurePerformance(name: String) -> some View {
        let start = DispatchTime.now()
        return self.onAppear {
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            debugLog("\(name) took \(timeInterval) seconds to appear")
        }
    }
}
#endif 

// Simple app environment detection
extension Bundle {
    var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
} 
