import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    @State private var showingDebugAlert = false
    @State private var showingImportOptions = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationTab(
                title: "Scheduled",
                icon: "calendar",
                showImportOptions: $showingImportOptions,
                showingDebugAlert: $showingDebugAlert,
                clearData: clearAllData
            ) {
                ScheduledView()
            }
            .tag(0)
            
            NavigationTab(
                title: "To Connect",
                icon: "clock",
                showImportOptions: $showingImportOptions,
                showingDebugAlert: $showingDebugAlert,
                clearData: clearAllData
            ) {
                ToConnectView()
            }
            .tag(1)
            
            NavigationTab(
                title: "Friends",
                icon: "person.2",
                showImportOptions: $showingImportOptions,
                showingDebugAlert: $showingDebugAlert,
                clearData: clearAllData
            ) {
                FriendsListView()
            }
            .tag(2)
        }
        .sheet(isPresented: $showingImportOptions) {
            ImportOptionsView(showingContactPicker: $showingContactPicker, showingImportOptions: $showingImportOptions)
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView()
        }
        .alert("Debug Mode", isPresented: $showingDebugAlert) {
            Button("Clear All Data", role: .destructive) {
                Task { @MainActor in
                    await clearAllData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all friends and hangouts. This action cannot be undone.")
        }
        .tint(theme.primary)
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
    }
}

private struct NavigationTab<Content: View>: View {
    @EnvironmentObject private var theme: Theme
    
    let title: String
    let icon: String
    @Binding var showImportOptions: Bool
    @Binding var showingDebugAlert: Bool
    let clearData: () async -> Void
    let content: Content
    
    init(
        title: String,
        icon: String,
        showImportOptions: Binding<Bool>,
        showingDebugAlert: Binding<Bool>,
        clearData: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self._showImportOptions = showImportOptions
        self._showingDebugAlert = showingDebugAlert
        self.clearData = clearData
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showImportOptions = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(theme.primaryText)
                        }
                        #if DEBUG
                        .onLongPressGesture {
                            showingDebugAlert = true
                        }
                        #endif
                    }
                }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: Theme
    @Binding var showingContactPicker: Bool
    @Binding var showingImportOptions: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    showingImportOptions = false
                    showingContactPicker = true
                }) {
                    Label("Import from Contacts", systemImage: "person.crop.circle")
                }
                
                NavigationLink(destination: FriendOnboardingView(contact: ("", nil, nil, nil))) {
                    Label("Add from Memory", systemImage: "brain")
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
        .environmentObject(Theme.shared)
} 
