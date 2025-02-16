import SwiftUI

struct PollResponse {
    let respondentName: String
    let respondentEmail: String
    let selectedSlots: [TimeRange]
    let responseDate: Date
}

struct TimeSlotResponse {
    let timeRange: TimeRange
    let respondents: [PollResponse]
    
    var respondentCount: Int {
        respondents.count
    }
}

@MainActor
class PollResponsesViewModel: ObservableObject {
    @Published var responses: [TimeSlotResponse] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    let eventName: String
    let selectionType: SelectionType
    
    init(eventName: String, selectionType: SelectionType) {
        self.eventName = eventName
        self.selectionType = selectionType
    }
    
    func fetchResponses() async {
        isLoading = true
        
        // TODO: Implement API call to fetch responses
        // try {
        //     responses = try await fetchPollResponses()
        // } catch {
        //     self.error = error
        // }
        
        isLoading = false
    }
}

struct PollResponsesView: View {
    @StateObject private var viewModel: PollResponsesViewModel
    
    init(eventName: String, selectionType: SelectionType) {
        _viewModel = StateObject(wrappedValue: PollResponsesViewModel(eventName: eventName, selectionType: selectionType))
    }
    
    var body: some View {
        List {
            Section {
                Text(viewModel.eventName)
                    .font(.headline)
            } header: {
                Text("Event")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Section {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.responses.isEmpty {
                    Text("No responses yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.responses, id: \.timeRange.id) { response in
                        TimeSlotResponseRow(response: response)
                    }
                }
            } header: {
                Text("Responses")
                    .textCase(nil)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .navigationTitle("Poll Responses")
        .task {
            await viewModel.fetchResponses()
        }
    }
}

struct TimeSlotResponseRow: View {
    let response: TimeSlotResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(response.timeRange.formattedDate)
                .font(.headline)
            Text(response.timeRange.formattedTimeRange)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                Text("\(response.respondentCount) \(response.respondentCount == 1 ? "response" : "responses")")
                    .foregroundColor(.secondary)
            }
            
            if !response.respondents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(response.respondents, id: \.respondentEmail) { respondent in
                        Text(respondent.respondentName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PollResponsesView(eventName: "Team Meeting", selectionType: .poll)
    }
} 