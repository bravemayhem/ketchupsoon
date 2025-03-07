import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var onboardingManager = OnboardingManager.shared
    @State private var selectedTab = 0
    @State private var showingContactPicker = false
    @State private var showingDebugAlert = false
    @State private var showingImportOptions = false
    @State private var showConfetti = false {
        didSet {
            print("DEBUG: ContentView - showConfetti changed to \(showConfetti)")
        }
    }
    
    // Added state to control which design to use
    @State private var useNewDesign = true
    
    var body: some View {
        ZStack {
            // Content based on selected tab - replacing TabView with our custom implementation
            ZStack {
                // Background
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                // Tab content based on selection
                Group {
                    if selectedTab == 0 {
                        // Home tab (emoji: 🏠)
                        NavigationTab(
                            title: "Home",
                            subtitle: "Development version with SVG design",
                            icon: "house.fill",
                            subtitleAlwaysVisible: false,
                            showImportOptions: $showingImportOptions,
                            showingDebugAlert: $showingDebugAlert,
                            clearData: clearAllData,
                            useNewDesign: useNewDesign
                        ) {
                            HomeView()
                        }
                        .transition(.opacity)
                    }
                    else if selectedTab == 1 {
                        // Pulse tab (emoji: 📅)
                        NavigationTab(
                            title: "Ketchups",
                            subtitle: "Schedule time with the people who matter",
                            icon: "calendar",
                            subtitleAlwaysVisible: false,
                            showImportOptions: $showingImportOptions,
                            showingDebugAlert: $showingDebugAlert,
                            clearData: clearAllData,
                            useNewDesign: useNewDesign
                        ) {
                            KetchupsView(showConfetti: $showConfetti)
                        }
                        .transition(.opacity)
                    }
                    else if selectedTab == 2 {
                        // Wishlist tab (emoji: ⭐)
                        NavigationTab(
                            title: "Wishlist",
                            subtitle: "Keep track of friends you want to see soon",
                            icon: "star",
                            subtitleAlwaysVisible: false,
                            showImportOptions: $showingImportOptions,
                            showingDebugAlert: $showingDebugAlert,
                            clearData: clearAllData,
                            useNewDesign: useNewDesign
                        ) {
                            WishlistView(showConfetti: $showConfetti)
                        }
                        .transition(.opacity)
                    }
                    else if selectedTab == 3 {
                        // Profile tab (emoji: 😎)
                        NavigationTab(
                            title: "Friends",
                            subtitle: "Keep track of the details that matter to you",
                            icon: "person.2",
                            subtitleAlwaysVisible: true,
                            showImportOptions: $showingImportOptions,
                            showingDebugAlert: $showingDebugAlert,
                            clearData: clearAllData,
                            useNewDesign: useNewDesign
                        ) {
                            FriendsListView()
                        }
                        .transition(.opacity)
                    }
                }
            }
            // Apply our custom tab bar
            .withCustomTabBar(selectedTab: selectedTab) { tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            }
            .sheet(isPresented: $showingImportOptions) {
                ImportOptionsView(showingContactPicker: $showingContactPicker, showingImportOptions: $showingImportOptions)
            }
            .fullScreenCover(isPresented: $onboardingManager.isShowingOnboarding) {
                OnboardingView()
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
            .displayConfetti(isActive: $showConfetti)
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
    let useNewDesign: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        subtitleAlwaysVisible: Bool = false,
        showImportOptions: Binding<Bool>,
        showingDebugAlert: Binding<Bool>,
        clearData: @escaping () async -> Void,
        useNewDesign: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self._showImportOptions = showImportOptions
        self._showingDebugAlert = showingDebugAlert
        self.clearData = clearData
        self.useNewDesign = useNewDesign
        self.content = content()
    }
    
    var body: some View {
        if useNewDesign {
            // New design using CustomNavigationBarContainer
            CustomNavigationBarContainer(
                title: title,
                subtitle: subtitle,
                leadingIcon: "gear",
                trailingIcon: "plus",
                leadingButtonAction: {
                    showingSettings = true
                },
                trailingButtonAction: {
                    showImportOptions = true
                },
                useNewDesign: true,
                enableDebugMode: true,
                debugModeAction: {
                    showingDebugAlert = true
                },
                content: {
                    content
                }
            )
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .tabItem {
                Label(title, systemImage: icon)
            }
        } else {
            // Original design using standard NavigationStack
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
        .modelContainer(for: [Friend.self, Hangout.self, Tag.self, ketchupsoon.Milestone.self], inMemory: true)
}
