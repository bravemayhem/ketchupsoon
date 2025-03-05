import Foundation
import os.signpost
import SwiftUI

func debugLog(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function): \(message)")
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
