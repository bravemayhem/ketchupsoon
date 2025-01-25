import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    @State private var showingDebugAlert = false
    @State private var showingImportOptions = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationTab(
                title: "Ketchups",
                subtitle: "Your social calendar at your finger tips",
                icon: "calendar",
                subtitleAlwaysVisible: false,
                showImportOptions: $showingImportOptions,
                showingDebugAlert: $showingDebugAlert,
                clearData: clearAllData
            ) {
                KetchupsView()
            }
            .tag(0)
            
            NavigationTab(
                title: "Wishlist",
                subtitle: "Keep track of friends you want to see soon",
                icon: "star",
                subtitleAlwaysVisible: false,
                showImportOptions: $showingImportOptions,
                showingDebugAlert: $showingDebugAlert,
                clearData: clearAllData
            ) {
                WishlistView()
            }
            .tag(1)
            
            NavigationTab(
                title: "Friends",
                subtitle: "Friends you've added to Ketchup Soon",
                icon: "person.2",
                subtitleAlwaysVisible: true,
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
        .tint(AppColors.accent)
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
    let title: String
    let subtitle: String?
    let icon: String
    @Binding var showImportOptions: Bool
    @Binding var showingDebugAlert: Bool
    @State private var showingSettings = false
    let clearData: () async -> Void
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        subtitleAlwaysVisible: Bool = false,
        showImportOptions: Binding<Bool>,
        showingDebugAlert: Binding<Bool>,
        clearData: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._showImportOptions = showImportOptions
        self._showingDebugAlert = showingDebugAlert
        self.clearData = clearData
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryLabel)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(AppColors.label)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImportOptions = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(AppColors.label)
                    }
                    #if DEBUG
                    .onLongPressGesture {
                        showingDebugAlert = true
                    }
                    #endif
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tabItem {
            Label(title, systemImage: icon)
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ImportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
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
                        .foregroundColor(AppColors.label)
                }
                .listRowBackground(AppColors.systemBackground)
                
                NavigationLink(destination: FriendOnboardingView(contact: (name: "", identifier: nil, phoneNumber: nil, email: nil, imageData: nil, city: nil))) {
                    Label("Add Manually", systemImage: "brain")
                        .foregroundColor(AppColors.label)
                }
                .listRowBackground(AppColors.systemBackground)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }
            }
            .background(AppColors.systemBackground)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Friend.self, Hangout.self, Tag.self], inMemory: true)
}
