//
//  FriendNameSection.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/5/25.
//

import SwiftUI
import SwiftData
import ContactsUI

// MARK: - CURRENTLY USED FOR NEW FRIENDS
//USED FOR IMPORTING NEW CONTACTS NAMES FROM THE CONTACT LIST OR MANUALLY FOR THE FIRST TIME
struct FriendNameSection: View {
    let isFromContacts: Bool
    let contactName: String?
    @Binding var manualName: String
    
    var body: some View {
        Section("Name") {
            if isFromContacts {
                HStack {
                    Text("Name")
                        .foregroundColor(AppColors.label)
                    Spacer()
                    Text(contactName ?? "")
                        .foregroundColor(AppColors.secondaryLabel)
                }
            } else {
                TextField("Name", text: $manualName)
                    .foregroundColor(AppColors.label)
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}
