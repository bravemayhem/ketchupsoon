import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @State private var showingClearDataAlert = false
    @State private var showingComingSoonAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    Button {
                        showingComingSoonAlert = true
                    } label: {
                        Label {
                            Text("Profile Settings")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "person.circle")
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
                
                Section("App Settings") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        CalendarIntegrationView()
                    } label: {
                        Label("Calendar Integration", systemImage: "calendar")
                    }
                    
                    Picker(selection: $colorSchemeManager.currentAppearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
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
                    Task { @MainActor in
                        await clearAllData()
                    }
                }
            } message: {
                Text("This will delete all friends and hangouts. This action cannot be undone.")
            }
            .alert("Coming soon!", isPresented: $showingComingSoonAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Profile settings are coming in a future update.")
            }
        }
    }
    
    @MainActor
    private func clearAllData() async {
        // Delete all hangouts
        let hangoutDescriptor = FetchDescriptor<Hangout>()
        if let hangouts = try? modelContext.fetch(hangoutDescriptor) {
            for hangout in hangouts {
                modelContext.delete(hangout)
            }
        }
        
        // Delete all friends
        let friendDescriptor = FetchDescriptor<Friend>()
        if let friends = try? modelContext.fetch(friendDescriptor) {
            for friend in friends {
                modelContext.delete(friend)
            }
        }
        
        // Delete all tags
        let tagDescriptor = FetchDescriptor<Tag>()
        if let tags = try? modelContext.fetch(tagDescriptor) {
            for tag in tags {
                modelContext.delete(tag)
            }
        }
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Friend.self, Hangout.self, Tag.self], inMemory: true)
} 