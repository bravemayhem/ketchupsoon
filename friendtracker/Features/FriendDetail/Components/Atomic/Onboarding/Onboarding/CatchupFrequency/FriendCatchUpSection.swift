//
//  FriendCatchUpSection.swift
//  friendtracker
//
//  Created by Amineh Beltran on 2/5/25.
//

import SwiftUI


//USED FOR SETTING UP CATCH UP FREQUENCY FOR THE FIRST TIME
struct FriendCatchUpSection: View {
    @Binding var hasCatchUpFrequency: Bool
    @Binding var selectedFrequency: CatchUpFrequency
    
    var body: some View {
        Section("Catch Up Frequency") {
            Toggle("Set catch up goal?", isOn: $hasCatchUpFrequency)
                .foregroundColor(AppColors.label)
            
            if hasCatchUpFrequency {
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayText)
                            .foregroundColor(AppColors.label)
                            .tag(frequency)
                    }
                }
            }
        }
        .listRowBackground(AppColors.secondarySystemBackground)
    }
}
