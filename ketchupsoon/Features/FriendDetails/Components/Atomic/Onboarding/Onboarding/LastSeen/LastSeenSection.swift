//
//  LastSeenSection.swift
//  ketchupsoon
//
//  Created by Amineh Beltran on 2/5/25.
//
import SwiftUI
import SwiftData

//USED FOR SETTING UP LAST SEEN DATE FOR THE FIRST TIME
struct FriendLastSeenSection: View {
    @Binding var hasLastSeen: Bool
    @Binding var lastSeenDate: Date
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        Section("Last Seen") {
            Toggle("Add last seen date?", isOn: $hasLastSeen)
                .foregroundColor(AppColors.label)
                .onChange(of: hasLastSeen) { _, newValue in
                    print("DEBUG: Last seen toggle changed to \(newValue)")
                }
            
            if hasLastSeen {
                Button {
                    print("DEBUG: Last seen date button tapped")
                    showingDatePicker = true
                } label: {
                    HStack {
                        Text("Last Seen Date")
                            .foregroundColor(AppColors.label)
                        Spacer()
                        Text(lastSeenDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(AppColors.secondaryLabel)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
        .onChange(of: showingDatePicker) { _, newValue in
            print("DEBUG: showingDatePicker changed to \(newValue)")
        }
        .onChange(of: lastSeenDate) { oldValue, newValue in
            print("DEBUG: lastSeenDate changed from \(oldValue) to \(newValue)")
        }
        .onAppear {
            print("DEBUG: FriendLastSeenSection appeared")
        }
        .onDisappear {
            print("DEBUG: FriendLastSeenSection disappeared")
        }
    }
}
