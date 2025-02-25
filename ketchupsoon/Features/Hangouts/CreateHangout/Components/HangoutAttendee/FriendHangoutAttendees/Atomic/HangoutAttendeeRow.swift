//
//  HangoutAttendeeRow.swift
//  ketchupsoon
//
//  Created by Amineh Beltran on 2/5/25.
//


import SwiftUI
import SwiftData

struct HangoutAttendeeRow: View {
    let friend: Friend
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(friend.name)
            EmailDropdownMenu(friend: friend, viewModel: viewModel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

#Preview("HangoutAttendeeRow") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    
    // Create a sample friend
    let friend = Friend(name: "John Smith", email: "john@example.com")
    friend.additionalEmails = ["john.smith@work.com", "john.smith@personal.com"]
    
    return Form {
        HangoutAttendeeRow(friend: friend, viewModel: viewModel)
    }
}
