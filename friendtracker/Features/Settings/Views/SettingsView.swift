import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    NavigationLink {
                        Text("Profile Settings")
                    } label: {
                        Label("Profile Settings", systemImage: "person.circle")
                    }
                }
                
                Section("App Settings") {
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Calendar Integration")
                    } label: {
                        Label("Calendar Integration", systemImage: "calendar")
                    }
                }
                
                Section("Data") {
                    Button(role: .destructive) {
                        showingClearDataAlert = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    // TODO: Implement clear data functionality
                }
            } message: {
                Text("This will delete all your friends and hangouts data. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Friend.self, Hangout.self, Tag.self], inMemory: true)
} 