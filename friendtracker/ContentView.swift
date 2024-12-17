import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var theme: Theme
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationTab(title: "Scheduled", icon: "calendar") {
                ScheduledView()
            }
            .tag(0)
            
            NavigationTab(title: "To Connect", icon: "clock") {
                ToConnectView()
            }
            .tag(1)
            
            NavigationTab(title: "Friends", icon: "person.2") {
                FriendsListView()
            }
            .tag(2)
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView()
        }
        .tint(theme.primary)
    }
}

private struct NavigationTab<Content: View>: View {
    @EnvironmentObject private var theme: Theme
    @Environment(\.showContactPicker) private var showContactPicker
    
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Friends")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showContactPicker?()
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

private struct ShowContactPickerKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var showContactPicker: (() -> Void)? {
        get { self[ShowContactPickerKey.self] }
        set { self[ShowContactPickerKey.self] = newValue }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Hangout.self], inMemory: true)
        .environmentObject(Theme.shared)
} 
