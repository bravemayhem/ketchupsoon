// FriendSheetPresenter: Handles all sheet presentations and state management -  STATE and LOGIC
// This is a modifier that allows us to present different sheets for a friend
// It is used in the FriendsListView and FriendDetailView

import SwiftUI
import SwiftData

struct FriendSheetPresenter: ViewModifier {
    @Binding var selectedFriend: Friend?
    @State private var showingFriendSheet = false
    @State private var showingScheduler = false
    @State private var showingMessageSheet = false
    @State private var showingFrequencyPicker = false
    @State private var showingActionSheet = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingFriendSheet) {
                if let friend = selectedFriend {
                    NavigationStack {
                        FriendDetailView(
                            friend: friend,
                            presentationMode: .sheet($showingFriendSheet)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingScheduler) {
                if let friend = selectedFriend {
                    NavigationStack {
                        SchedulerView(initialFriend: friend)
                    }
                }
            }
            .sheet(isPresented: $showingMessageSheet) {
                if let friend = selectedFriend {
                    MessageComposeView(recipient: friend.phoneNumber ?? "")
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
                
                if let _ = friend.phoneNumber {
                    Button("Send Message") {
                        showingMessageSheet = true
                    }
                }
                
                Button("Schedule Hangout") {
                    showingScheduler = true
                }
                
                Button("Set Frequency") {
                    showingFrequencyPicker = true
                }
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

extension View {
    func friendSheetPresenter(selectedFriend: Binding<Friend?>) -> some View {
        modifier(FriendSheetPresenter(selectedFriend: selectedFriend))
    }
} 