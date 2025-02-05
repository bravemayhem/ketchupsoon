import SwiftUI

struct DateTimeSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    private let durations: [(String, TimeInterval)] = [
        ("30 minutes", 1800),
        ("1 hour", 3600),
        ("1.5 hours", 5400),
        ("2 hours", 7200),
        ("Custom", 0)
    ]
    
    var body: some View {
        Section("Date & Time") {
            DatePicker(
                "Date",
                selection: $viewModel.selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            
            Menu {
                ForEach(durations, id: \.0) { duration in
                    Button(action: {
                        if duration.0 == "Custom" {
                            viewModel.showingCustomDurationInput = true
                        } else {
                            viewModel.selectedDuration = duration.1
                        }
                    }) {
                        if let selectedDuration = viewModel.selectedDuration,
                           selectedDuration == duration.1 {
                            Label(duration.0, systemImage: "checkmark")
                        } else {
                            Text(duration.0)
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Duration")
                    Spacer()
                    if let duration = viewModel.selectedDuration {
                        Text(viewModel.formatDuration(duration))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
} 