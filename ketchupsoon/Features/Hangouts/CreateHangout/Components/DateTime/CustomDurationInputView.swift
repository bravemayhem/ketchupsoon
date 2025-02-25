import SwiftUI

struct CustomDurationInputView: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Hours: \(viewModel.customHours)", value: $viewModel.customHours, in: 0...12)
                    Stepper("Minutes: \(viewModel.customMinutes)", value: $viewModel.customMinutes, in: 0...59)
                } footer: {
                    Text("Total duration: \(viewModel.formatDuration(TimeInterval(viewModel.customHours * 3600 + viewModel.customMinutes * 60)))")
                }
            }
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let duration = TimeInterval(viewModel.customHours * 3600 + viewModel.customMinutes * 60)
                        viewModel.selectedDuration = duration
                        dismiss()
                    }
                    .disabled(viewModel.customHours == 0 && viewModel.customMinutes == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
} 