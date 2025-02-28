import SwiftUI

struct FrequencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    
    private func updateFrequency(_ frequency: CatchUpFrequency?) {
        friend.catchUpFrequency = frequency
    }
    
    var body: some View {
        List {
            Section {
                Button("No Automatic Reminders") {
                    updateFrequency(nil)
                    dismiss()
                }
                .foregroundColor(friend.catchUpFrequency == nil ? AppColors.accent : AppColors.label)
            } header: {
                Text("Manual Mode")
                    .foregroundColor(AppColors.secondaryLabel)
            } footer: {
                Text("You'll only be reminded to connect when you manually add this friend to the wishlist.")
                    .foregroundColor(AppColors.secondaryLabel)
            }
            
            Section {
                ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                    Button {
                        updateFrequency(frequency)
                        dismiss()
                    } label: {
                        HStack {
                            Text(frequency.displayText)
                            Spacer()
                            if friend.catchUpFrequency == frequency {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                    }
                    .foregroundColor(AppColors.label)
                }
            } header: {
                Text("Automatic Reminders")
                    .foregroundColor(AppColors.secondaryLabel)
            } footer: {
                Text("You'll be automatically reminded to connect when the next catch up is due.")
                    .foregroundColor(AppColors.secondaryLabel)
            }
        }
        .navigationTitle("Catch Up Frequency")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppColors.accent)
            }
        }
        .background(AppColors.systemBackground)
    }
} 
