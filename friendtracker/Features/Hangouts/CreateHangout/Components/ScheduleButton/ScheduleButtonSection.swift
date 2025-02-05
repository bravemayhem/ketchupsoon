import SwiftUI
import SwiftData

// MARK: - ScheduleButtonSection
struct ScheduleButtonSection: View {
    @ObservedObject var viewModel: CreateHangoutViewModel
    
    var body: some View {
        Section {
            Button(action: {
                Task {
                    await viewModel.scheduleHangout()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Schedule Hangout")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(viewModel.isScheduleButtonDisabled || viewModel.isLoading)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Previews
#Preview("Schedule Button (Normal)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    
    return Form {
        ScheduleButtonSection(viewModel: viewModel)
    }
}

#Preview("Schedule Button (Loading)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    viewModel.isLoading = true
    
    return Form {
        ScheduleButtonSection(viewModel: viewModel)
    }
}

#Preview("Schedule Button (Error)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    viewModel.errorMessage = "Failed to schedule hangout"
    
    return Form {
        ScheduleButtonSection(viewModel: viewModel)
    }
} 
