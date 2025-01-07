import SwiftUI

struct FrequencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var friend: Friend
    @State private var customDays: Int = 30
    @State private var showingCustomDaysPicker = false
    
    private func updateFrequency(_ frequency: CatchUpFrequency?) {
        if let frequency = frequency {
            friend.catchUpFrequency = frequency
            if frequency != .custom {
                friend.customCatchUpDays = nil
            }
        }
    }
    
    private func handleFrequencySelection(_ frequency: CatchUpFrequency) {
        if frequency == .custom {
            showingCustomDaysPicker = true
        } else {
            updateFrequency(frequency)
            dismiss()
        }
    }
    
    private func handleCustomFrequencySave() {
        friend.catchUpFrequency = .custom
        friend.customCatchUpDays = customDays
        showingCustomDaysPicker = false
        dismiss()
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
                Text("You'll only be reminded to connect when you manually add this friend to the To Connect list.")
                    .foregroundColor(AppColors.secondaryLabel)
            }
            
            Section {
                ForEach(CatchUpFrequency.allCases, id: \.self) { frequency in
                    Button {
                        handleFrequencySelection(frequency)
                    } label: {
                        HStack {
                            Text(frequency.rawValue)
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
                Text("You'll be automatically reminded to connect 3 weeks before the next catch-up is due.")
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
        .sheet(isPresented: $showingCustomDaysPicker) {
            NavigationStack {
                Form {
                    Section {
                        Stepper("Every \(customDays) days", value: $customDays, in: 1...365)
                    }
                }
                .navigationTitle("Custom Frequency")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingCustomDaysPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            handleCustomFrequencySave()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
} 