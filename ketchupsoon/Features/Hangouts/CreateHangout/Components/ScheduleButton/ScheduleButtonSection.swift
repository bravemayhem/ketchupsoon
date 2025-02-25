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
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.white)
                        Spacer()
                    }
                } else {
                    Text("Schedule Hangout")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if viewModel.isScheduleButtonDisabled || viewModel.isLoading {
                        AppColors.accent.opacity(0.3)
                    } else {
                        AppColors.accent
                    }
                }
            )
            .cornerRadius(8)
            .disabled(viewModel.isScheduleButtonDisabled || viewModel.isLoading)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
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
    viewModel.hangoutTitle = "Coffee Chat"
    viewModel.selectedFriends = [Friend(name: "John")]
    
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

#Preview("Schedule Button (Disabled - No Title)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    viewModel.hangoutTitle = ""  // Empty title
    viewModel.selectedFriends = [Friend(name: "John")]  // Has friends selected
    
    return Form {
        ScheduleButtonSection(viewModel: viewModel)
    }
}

#Preview("Schedule Button (Disabled - No Friends)") {
    let modelContext = ModelContext(try! ModelContainer(for: Friend.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    let viewModel = CreateHangoutViewModel(modelContext: modelContext)
    viewModel.hangoutTitle = "Coffee Chat"  // Has title
    viewModel.selectedFriends = []  // No friends selected
    
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
