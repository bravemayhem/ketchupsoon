import SwiftUI
import SwiftData

@main
struct friendtrackerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // First try to create the container normally
            let schema = Schema([Friend.self, Tag.self, Hangout.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            do {
                container = try ModelContainer(for: schema, configurations: modelConfiguration)
            } catch {
                print("Failed to load store, attempting to delete and recreate: \(error)")
                
                // Get the store URL
                let storeURL = try ModelContainer.urlForStore(with: nil)
                
                // Delete the store file
                try? FileManager.default.removeItem(at: storeURL)
                
                // Try to create the container again
                container = try ModelContainer(for: schema, configurations: modelConfiguration)
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
} 