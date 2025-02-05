//
//  FriendsSection.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/5/25.
//


import SwiftUI
import SwiftData

// MARK: - FriendsSection
struct FriendsSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    @Binding var showingFriendPicker: Bool
    
    var body: some View {
        Section {
            if viewModel.selectedFriends.isEmpty {
                HangoutAttendeeAddButton(action: { showingFriendPicker = true }, title: "Add Friends")
            } else {
                ForEach(viewModel.selectedFriends) { friend in
                    HangoutAttendeeRow(friend: friend, viewModel: viewModel)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.removeFriend(viewModel.selectedFriends[index])
                    }
                }
                
                HangoutAttendeeAddButton(action: { showingFriendPicker = true }, title: "Add More Friends")
            }
        } header: {
            Text("Friends")
        } footer: {
            if !viewModel.selectedFriends.isEmpty {
                let missingEmails = viewModel.selectedFriends.filter { $0.email?.isEmpty ?? true }.count
                if missingEmails > 0 {
                    Text("\(missingEmails) friend\(missingEmails > 1 ? "s" : "") missing email address\(missingEmails > 1 ? "es" : "") - they won't receive calendar invites")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Friends Section") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    
    // Create sample friends
    let friend1 = Friend(name: "John Smith", email: "john@example.com")
    let friend2 = Friend(name: "Jane Doe", email: "")  // Missing email to show warning
    viewModel.selectedFriends = [friend1, friend2]
    
    return Form {
        FriendsSection(viewModel: viewModel, showingFriendPicker: .constant(false))
    }
}
