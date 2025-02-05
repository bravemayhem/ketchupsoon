//
//  NewFriendConnectSection.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/5/25.
//
import SwiftUI
import SwiftData


//USED FOR SETTING UP ADDING SOMEONE TO THE "WISH LIST" FOR THE FIRST TIME
struct FriendConnectSection: View {
    @Binding var wantToConnectSoon: Bool
    
    var body: some View {
        Section("Connect Soon") {
            Toggle("Want to connect soon?", isOn: $wantToConnectSoon)
                .foregroundColor(AppColors.label)
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}
