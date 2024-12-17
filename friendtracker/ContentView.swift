import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ScheduledView()
                    .navigationTitle("Friends")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showingContactPicker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Scheduled", systemImage: "calendar")
            }
            .tag(0)
            
            NavigationStack {
                ToConnectView()
                    .navigationTitle("Friends")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showingContactPicker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                    }
            }
            .tabItem {
                Label("To Connect", systemImage: "clock")
            }
            .tag(1)
            
            NavigationStack {
                FriendsListView()
                    .navigationTitle("Friends")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showingContactPicker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Friends", systemImage: "person.2")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPickerView()
        }
        .tint(.black)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Friend.self)
} 