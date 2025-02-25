//
//  HangoutAttendeeAddButton.swift
//  ketchupsoon
//
//  Created by Amineh Beltran on 2/5/25.
//

import SwiftUI

struct HangoutAttendeeAddButton: View {
    let action: () -> Void
    let title: String
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.accentColor)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

#Preview("Add Friends Button") {
    Form {
        HangoutAttendeeAddButton(action: {}, title: "Add Friends")
    }
}

#Preview("Add More Friends Button") {
    Form {
        HangoutAttendeeAddButton(action: {}, title: "Add More Friends")
    }
} 
