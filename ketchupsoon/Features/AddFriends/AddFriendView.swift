import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SwiftData
import OSLog
import Combine
import Contacts
import MessageUI

struct AddFriendView: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Firebase sync service
    @EnvironmentObject private var firebaseSyncService: FirebaseSyncService
    
    // Contact matching manager
    @StateObject private var contactMatchingManager = ContactMatchingManager.shared
    
    // Simple state properties - kept for UI display only
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var selectedTab = 0
    @State private var showComingSoonPopup = false
    @State private var popupMessage = ""
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Firebase search results
    @State private var searchResults: [UserModel] = []
    @State private var addedFriendIds: Set<String> = []
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.ketchupsoon", category: "AddFriendView")
    
    // Tab options
    let tabs = ["contacts", "qr code", "invite via text"]
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            AddFriendViewColors.backgroundGradient
                .ignoresSafeArea()
            
            // Decorative background elements
            Circle()
                .fill(AddFriendViewColors.purple.opacity(0.3))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .position(x: 350, y: 150)
            
            Circle()
                .fill(AddFriendViewColors.pinkRed.opacity(0.2))
                .frame(width: 360, height: 360)
                .blur(radius: 50)
                .position(x: 50, y: 650)
            
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    // Back button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            dismiss()
                        }
                    }) {
                        Circle()
                            .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("←")
                                    .font(.system(size: 22))
                                    .foregroundColor(AddFriendViewColors.textPrimary)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
                
                // Method selection tabs
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Button(action: {
                            if index == 0 || index == 1 || index == 2 {
                                // For all tabs, just update the selected tab with animation
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedTab = index
                                }
                                showComingSoonPopup = false
                            }
                        }) {
                            Text(tabs[index])
                                .font(.system(size: 14, weight: index == selectedTab ? .semibold : .regular))
                                .foregroundColor(index == selectedTab ? AddFriendViewColors.textPrimary : AddFriendViewColors.textPrimary.opacity(0.6))
                                .frame(height: 40)
                                .frame(maxWidth: .infinity)
                                .background(
                                    AddFriendViewColors.tabButton(isSelected: index == selectedTab)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Search bar (only show for contacts tab)
                if selectedTab == 0 {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AddFriendViewColors.textPrimary.opacity(0.6))
                            .padding(.leading, 15)
                        
                        TextField("", text: $searchQuery)
                            .placeholder(when: searchQuery.isEmpty) {
                                Text("search ketchupsoon users...")
                                    .foregroundColor(AddFriendViewColors.textTertiary)
                            }
                            .foregroundColor(AddFriendViewColors.textPrimary)
                            .padding(.vertical, 15)
                            .onSubmit {
                                searchUsers()
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(AddFriendViewColors.separator, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Content based on selected tab
                ScrollView {
                    if selectedTab == 0 {
                        // CONTACTS TAB CONTENT
                        contactsTabContent
                    } else if selectedTab == 1 {
                        // QR CODE TAB CONTENT - Use the dedicated component from QRCodeScreen.swift
                        QRCodeContent()
                    } else if selectedTab == 2 {
                        // INVITE VIA TEXT TAB CONTENT - Use the dedicated component from InviteViaTextContent.swift
                        InviteViaTextContent()
                    }
                }
                .padding(.top, selectedTab == 0 ? 0 : 20)
                .padding(.bottom, 80)

            }
            
            // Coming soon popup
            if showComingSoonPopup {
                ComingSoonPopupView(message: popupMessage, isShowing: $showComingSoonPopup)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showComingSoonPopup)
            }
            
            // Tab bar at bottom
            VStack {
                Spacer()
                BottomTabBar(selectedTab: 0)
            }
        }
        .navigationBarHidden(true)
        .task {
            // Set the Firebase sync service in the contact matching manager
            contactMatchingManager.setFirebaseSyncService(firebaseSyncService)
            
            // Load contact matches when the view appears
            if selectedTab == 0 && !contactMatchingManager.hasLoadedContacts {
                await contactMatchingManager.loadAndMatchContacts()
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 0 && !contactMatchingManager.hasLoadedContacts {
                Task {
                    await contactMatchingManager.loadAndMatchContacts()
                }
            }
        }
    }
    
    // MARK: - Contacts Tab Content
    private var contactsTabContent: some View {
        VStack(spacing: 20) {
            // Manual search results section (only shown when search is active)
            if !searchQuery.isEmpty {
                manualSearchResultsSection
            } else {
                // Only show matched contacts section when not actively searching
                // Contacts already on KetchupSoon
                MatchedContactsList(
                    contactMatchingManager: contactMatchingManager,
                    onAddFriend: { user in
                        addFriend(user)
                    }
                )
                
                // Invite to KetchupSoon section
                NonMatchedContactsList(
                    contactMatchingManager: contactMatchingManager,
                    onInvite: { contact in
                        // Handle invitation for a single contact
                        inviteContact(contact)
                    }
                )
            }
            
            // Success message
            if showSuccessMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AddFriendViewColors.mint)
                    
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                )
                .padding(.top, 20)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Manual Search Results Section
    private var manualSearchResultsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Section Title
            Text("search results")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AddFriendViewColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            if isSearching {
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AddFriendViewColors.textPrimary))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if let error = errorMessage {
                // Error message
                Text(error)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AddFriendViewColors.pinkRed)
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if searchResults.isEmpty && !searchQuery.isEmpty {
                // No results
                Text("No users found matching '\(searchQuery)'")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AddFriendViewColors.textSecondary)
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if !searchResults.isEmpty {
                // Search results
                ForEach(searchResults) { user in
                    ContactRow(
                        name: user.name ?? "",
                        phone: user.phoneNumber ?? "",
                        email: user.email ?? "",
                        emoji: "🌟",
                        gradientColors: getGradientForUser(user),
                        buttonType: addedFriendIds.contains(user.id) ? .added : .add,
                        onButtonTap: {
                            addFriend(user)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Contact and Friend Management Functions
extension AddFriendView {
    // Search for users using FirebaseSyncService
    private func searchUsers() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        searchResults = []
        
        Task {
            do {
                let results = try await firebaseSyncService.searchUsers(query: searchQuery)
                
                // Filter out current user from results
                let filteredResults = results.filter { user in
                    user.id != Auth.auth().currentUser?.uid
                }
                
                await MainActor.run {
                    searchResults = filteredResults
                    isSearching = false
                }
                
                logger.info("Found \(filteredResults.count) users matching '\(searchQuery)'")
            } catch {
                await MainActor.run {
                    errorMessage = "Error searching: \(error.localizedDescription)"
                    isSearching = false
                }
                
                logger.error("Error searching users: \(error.localizedDescription)")
            }
        }
    }
    
    // Add a friend
    @MainActor
    private func addFriend(_ user: UserModel) {
        guard !addedFriendIds.contains(user.id) else { return }
        
        Task<Void, Never> {
            do {
                // Create friendship with the selected user
                try await firebaseSyncService.createFriendship(with: user.id, notes: nil as String?)
                
                // Update UI directly since we're already on the MainActor
                addedFriendIds.insert(user.id)
                successMessage = "Added \(user.name ?? "User") as a friend!"
                showSuccessMessage = true
                
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    showSuccessMessage = false
                }
            } catch {
                errorMessage = "Error adding friend: \(error)"
            }
        }
    }
    
    // Invite a contact
    private func inviteContact(_ contact: CNContact) {
        // Switch to the invite tab with the contact pre-selected
        withAnimation {
            selectedTab = 2
        }
        
        // Show success message
        successMessage = "Switched to invite tab"
        showSuccessMessage = true
        
        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showSuccessMessage = false
            }
        }
        
        // In a full implementation, you'd pass the selected contact to the invite tab
    }
    
    // Get gradient colors for a user based on their gradient index
    private func getGradientForUser(_ user: UserModel) -> [Color] {
        let index = user.gradientIndex
        
        switch index % 5 {
        case 0: return [AddFriendViewColors.mint, AddFriendViewColors.purple]
        case 1: return [AddFriendViewColors.bluePurple, AddFriendViewColors.mint]
        case 2: return [AddFriendViewColors.pinkRed, AddFriendViewColors.purple]
        case 3: return [AddFriendViewColors.mint, AddFriendViewColors.pinkRed]
        case 4: return [AddFriendViewColors.purple, AddFriendViewColors.bluePurple]
        default: return [AddFriendViewColors.mint, AddFriendViewColors.purple]
        }
    }
}

// MARK: - Contact Row Component
struct ContactRow: View {
    let name: String
    let phone: String
    var email: String = ""
    var emoji: String?
    var initials: String?
    var gradientColors: [Color]?
    @State private var buttonType: AddFriendViewColors.ButtonType
    @State private var showToast = false
    @State private var toastMessage = ""
    var onButtonTap: (() -> Void)?
    
    init(name: String, phone: String, email: String = "", emoji: String? = nil, initials: String? = nil, gradientColors: [Color]? = nil, buttonType: AddFriendViewColors.ButtonType, onButtonTap: (() -> Void)? = nil) {
        self.name = name
        self.phone = phone
        self.email = email
        self.emoji = emoji
        self.initials = initials
        self.gradientColors = gradientColors
        self._buttonType = State(initialValue: buttonType)
        self.onButtonTap = onButtonTap
    }
    
    var body: some View {
        ZStack {
            HStack {
                // Profile circle
                ZStack {
                    if let emoji = emoji, let gradientColors = gradientColors {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .fill(AddFriendViewColors.cardBackground.opacity(0.7))
                            .frame(width: 40, height: 40)
                        
                        Text(emoji)
                            .font(.system(size: 18))
                    } else if let initials = initials {
                        Circle()
                            .stroke(AddFriendViewColors.outline, lineWidth: 1)
                            .background(Circle().fill(AddFriendViewColors.cardBackground.opacity(0.7)))
                            .frame(width: 50, height: 50)
                        
                        Text(initials)
                            .font(.system(size: 16))
                            .foregroundColor(AddFriendViewColors.textPrimary)
                    }
                }
                
                // Contact info
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                    
                    Text(phone)
                        .font(.system(size: 12))
                        .foregroundColor(AddFriendViewColors.textSecondary)
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // Action button
                Button(action: {
                    handleButtonTap()
                }) {
                    AnyView(AddFriendViewColors.actionButton(type: buttonType))
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 20)
            .background(
                AddFriendViewColors.contactCard()
            )
            
            // Toast notification
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(AddFriendViewColors.cardBackground)
                                .overlay(
                                    Capsule()
                                        .stroke(AddFriendViewColors.separator, lineWidth: 1)
                                )
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(.bottom, 5)
            }
        }
    }
    
    private func handleButtonTap() {
        switch buttonType {
        case .add:
            // Call the provided callback
            onButtonTap?()
            showSuccessToast("\(name) added to your friends!")
            
            // Here you would typically make an API call to add the friend
            
        case .invite:
            // When "Invite" is tapped, show invitation sent toast
            // In a full implementation, this would change to "Invited" state
            showSuccessToast("Invitation sent to \(name)!")
            
            // Here you would typically make an API call to send the invitation
            
        case .added:
            // Already added, do nothing or show already added toast
            showSuccessToast("\(name) is already your friend!")
        }
    }
    
    private func showSuccessToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showToast = true
        }
        
        // Auto-hide toast after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.5)) {
                showToast = false
            }
        }
    }
}

// MARK: - Bottom Tab Bar
struct BottomTabBar: View {
    let selectedTab: Int
    
    var body: some View {
        HStack {
            ForEach(0..<4) { index in
                VStack(spacing: 2) {
                    if index == selectedTab {
                        Rectangle()
                            .fill(
                                AddFriendViewColors.pinkOrangeGradient
                            )
                            .frame(width: 36, height: 5)
                            .cornerRadius(2.5)
                            .padding(.bottom, 4)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 36, height: 5)
                            .padding(.bottom, 4)
                    }
                    
                    Text(getTabIcon(for: index))
                        .font(.system(size: 24))
                        .foregroundColor(index == selectedTab ? AddFriendViewColors.textPrimary : AddFriendViewColors.textPrimary.opacity(0.5))
                    
                    Text(getTabName(for: index))
                        .font(.system(size: 11))
                        .foregroundColor(index == selectedTab ? AddFriendViewColors.textPrimary : AddFriendViewColors.textPrimary.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .background(AddFriendViewColors.backgroundDark.opacity(0.9))
    }
    
    func getTabIcon(for index: Int) -> String {
        switch index {
        case 0: return "🏠"
        case 1: return "📅"
        case 2: return "✨"
        case 3: return "😎"
        default: return ""
        }
    }
    
    func getTabName(for index: Int) -> String {
        switch index {
        case 0: return "home"
        case 1: return "hangouts"
        case 2: return "create"
        case 3: return "profile"
        default: return ""
        }
    }
}

// MARK: - Models
struct SimpleFriend: Identifiable {
    let id: String
    let name: String
    let email: String
    let phoneNumber: String
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

// MARK: - Helper Extensions
// Helper extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Coming Soon Popup
struct ComingSoonPopupView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
            // Popup card
            VStack(spacing: 20) {
                // Title
                HStack {
                    Text("🚀")
                        .font(.system(size: 24))
                    
                    Text("Coming Soon!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AddFriendViewColors.textSecondary)
                    }
                }
                
                // Message
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(AddFriendViewColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                // Got it button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowing = false
                    }
                }) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AddFriendViewColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            AddFriendViewColors.purplePinkGradient
                                .cornerRadius(25)
                        )
                        .glow(color: AddFriendViewColors.purple, radius: 8, opacity: 0.5)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(AddFriendViewColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(AddFriendViewColors.separator, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
        .zIndex(100) // Ensure popup appears above everything else
    }
}

// MARK: - Previews
#Preview {
    NavigationStack {
        AddFriendView()
    }
}
