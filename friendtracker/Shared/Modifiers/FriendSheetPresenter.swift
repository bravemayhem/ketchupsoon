// FriendSheetPresenter: Handles all sheet presentations and state management -  STATE and LOGIC
// This is a modifier that allows us to present different sheets for a friend
// It is used in the FriendsListView and FriendExistingView

import SwiftUI
import SwiftData
import MessageUI

// FriendSheetPresenter: Handles all sheet presentations and state management -  STATE and LOGIC
// This is a modifier that allows us to present different sheets for a friend
// It is used in the FriendsListView and FriendExistingView

struct FriendSheetPresenter: ViewModifier {
    @Binding var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    @State private var showingActionSheet = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingFriendSheet, onDismiss: {
                selectedFriend = nil
            }) {
                if let friend = selectedFriend {
                    NavigationStack {
                        FriendExistingView(
                            friend: friend,
                            presentationStyle: .sheet($showingFriendSheet)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingScheduler) {
                if let friend = selectedFriend {
                    NavigationStack {
                        CreateHangoutView(initialSelectedFriends: [friend])
                    }
                }
            }
            .sheet(isPresented: $showingMessageSheet) {
                Group {
                    if let friend = selectedFriend {
                        let _ = print("DEBUG: Attempting to show message sheet for friend: \(friend.name)")
                        let _ = print("DEBUG: Friend's phone number: \(String(describing: friend.phoneNumber))")
                        if let phoneNumber = friend.phoneNumber {
                            let _ = print("DEBUG: Opening MessageComposeView with number: \(phoneNumber)")
                            NavigationStack {
                                MessageComposeView(recipient: phoneNumber)
                            }
                        } else {
                            let _ = print("DEBUG: No phone number available, dismissing sheet")
                            Text("")
                                .onAppear {
                                    showingMessageSheet = false
                                }
                        }
                    } else {
                        let _ = print("DEBUG: No friend selected, dismissing sheet")
                        Text("")
                            .onAppear {
                                showingMessageSheet = false
                            }
                    }
                }
            }
            .sheet(isPresented: $showingFrequencyPicker) {
                if let friend = selectedFriend {
                    NavigationStack {
                        FrequencyPickerView(friend: friend)
                    }
                }
            }
            .confirmationDialog("Actions", isPresented: $showingActionSheet, presenting: selectedFriend) { friend in
                Button("View Details") {
                    showingFriendSheet = true
                }
                
                Button("Send Message") {
                    let _ = print("DEBUG: Send Message button tapped for friend: \(friend.name)")
                    showingMessageSheet = true
                }
                
                Button("Schedule Hangout") {
                    showingScheduler = true
                }
                
                Button("Set Frequency") {
                    showingFrequencyPicker = true
                }
            }
            .onChange(of: selectedFriend) { _, newValue in
                showingFriendSheet = newValue != nil
            }
    }
    
    // Public methods to show different sheets
    func showFriendDetails(for friend: Friend) {
        selectedFriend = friend
        showingFriendSheet = true
    }
    
    func showScheduler(for friend: Friend) {
        selectedFriend = friend
        showingScheduler = true
    }
    
    func showMessage(for friend: Friend) {
        selectedFriend = friend
        showingMessageSheet = true
    }
    
    func showFrequencyPicker(for friend: Friend) {
        selectedFriend = friend
        showingFrequencyPicker = true
    }
    
    func showActionSheet(for friend: Friend) {
        selectedFriend = friend
        showingActionSheet = true
    }
}

private struct FriendSheetPresenterKey: EnvironmentKey {
    static let defaultValue: FriendSheetPresenter? = nil
}

extension EnvironmentValues {
    var friendSheetPresenter: FriendSheetPresenter? {
        get { self[FriendSheetPresenterKey.self] }
        set { self[FriendSheetPresenterKey.self] = newValue }
    }
}

extension View {
    func friendSheetPresenter(selectedFriend: Binding<Friend?>) -> some View {
        let presenter = FriendSheetPresenter(selectedFriend: selectedFriend)
        return modifier(presenter)
            .environment(\.friendSheetPresenter, presenter)
    }
}

struct FriendSheetPresenterPreview: View {
    @State private var selectedFriend: Friend?
    @Environment(\.friendSheetPresenter) private var presenter
    
    // Sample friend for preview
    private let previewFriend = Friend(
        name: "John Doe",
        phoneNumber: "123-456-7890"
    )
    
    var body: some View {
        VStack(spacing: AppTheme.spacingLarge) {
            Text("Friend Sheet Presenter")
                .font(AppTheme.titleFont)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Direct Actions")
                    .font(AppTheme.headlineFont)
                
                VStack(spacing: AppTheme.spacingSmall) {
                    Button("Show Friend Details") {
                        presenter?.showFriendDetails(for: previewFriend)
                    }
                    .cardButton(style: .primary)
                    
                    Button("Show Scheduler") {
                        presenter?.showScheduler(for: previewFriend)
                    }
                    .cardButton(style: .primary)
                    
                    Button("Show Message Composer") {
                        presenter?.showMessage(for: previewFriend)
                    }
                    .cardButton(style: .primary)
                    
                    Button("Show Frequency Picker") {
                        presenter?.showFrequencyPicker(for: previewFriend)
                    }
                    .cardButton(style: .primary)
                }
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacingMedium) {
                Text("Action Sheet")
                    .font(AppTheme.headlineFont)
                
                Button("Show Action Sheet") {
                    presenter?.showActionSheet(for: previewFriend)
                }
                .cardButton(style: .primary)
            }
        }
        .padding()
        .background(AppColors.systemBackground)
        .friendSheetPresenter(selectedFriend: $selectedFriend)
    }
}

#Preview("Friend Sheet Presenter") {
    NavigationStack {
        FriendSheetPresenterPreview()
    }
} 