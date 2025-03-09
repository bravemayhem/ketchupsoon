import SwiftUI
import FirebaseFirestore
import SwiftData

struct AddFriendViewOne: View {
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Simple state properties - kept for UI display only
    @State private var searchQuery = ""
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var selectedTab = 0
    @State private var showComingSoonPopup = false
    @State private var popupMessage = ""
    
    // Static mock data for UI display
    @State private var searchResults: [SimpleFriend] = [
        SimpleFriend(id: "1", name: "Jamie Smith", email: "jamie@example.com", phoneNumber: "123-456-7890"),
        SimpleFriend(id: "2", name: "Alex Johnson", email: "alex@example.com", phoneNumber: "555-123-4567")
    ]
    
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
                                Text("search contacts...")
                                    .foregroundColor(AddFriendViewColors.textTertiary)
                            }
                            .foregroundColor(AddFriendViewColors.textPrimary)
                            .padding(.vertical, 15)
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
    }
    
    // MARK: - Contacts Tab Content
    private var contactsTabContent: some View {
        VStack(spacing: 10) {
            // Section Title - On KetchupSoon
            Text("on ketchupsoon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AddFriendViewColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 30)
            
            // Contacts on app - using example data
            ContactRow(
                name: "Jamie Smith",
                phone: "123-456-7890",
                emoji: "🦋",
                gradientColors: [AddFriendViewColors.mint, AddFriendViewColors.purple],
                buttonType: .add
            )
            
            ContactRow(
                name: "Alex Johnson",
                phone: "555-123-4567",
                emoji: "🔮",
                gradientColors: [AddFriendViewColors.bluePurple, AddFriendViewColors.mint],
                buttonType: .add
            )
            
            // Section Title - Invite to KetchupSoon
            Text("invite to ketchupsoon")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AddFriendViewColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
            
            // Contacts not on app - using example data
            ContactRow(
                name: "Avery Singh",
                phone: "555-6789",
                initials: "AS",
                buttonType: .invite
            )
            
            ContactRow(
                name: "Jordan Lee",
                phone: "555-4321",
                initials: "JL",
                buttonType: .invite
            )
            
            ContactRow(
                name: "Morgan Park",
                phone: "555-9876",
                initials: "MP",
                buttonType: .invite
            )
            
            // Multi-invite button
            Button(action: {}) {
                Text("invite multiple")
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
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Contact Row Component
struct ContactRow: View {
    let name: String
    let phone: String
    var emoji: String?
    var initials: String?
    var gradientColors: [Color]?
    @State private var buttonType: AddFriendViewColors.ButtonType
    @State private var showToast = false
    @State private var toastMessage = ""
    
    init(name: String, phone: String, emoji: String? = nil, initials: String? = nil, gradientColors: [Color]? = nil, buttonType: AddFriendViewColors.ButtonType) {
        self.name = name
        self.phone = phone
        self.emoji = emoji
        self.initials = initials
        self.gradientColors = gradientColors
        self._buttonType = State(initialValue: buttonType)
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
                    AddFriendViewColors.actionButton(type: buttonType)
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
            // When "Add" is tapped, change to "Added" and show success toast
            buttonType = .added
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
        AddFriendViewOne()
    }
}
